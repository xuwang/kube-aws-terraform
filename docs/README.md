
# Building a Kubernetes Cluster on CoreOS with [Terraform](https://www.terraform.io/intro/index.html)

## Table of Contents ##

- [Features](#features)
- [AWS Resourses](#resouces)
- [Prerequisite](#rerequisite)
- [Kubernetes PKI vault backend](#kubernetes-pki-vault-backend)
- [Code structure](#code-structure)
- [Cluster customization](#cluster-customization)
- [Build the cluster](#build-the-cluster)
- [Test the cluster](#test-the-cluster)
- [Manage individual platform resources](#manage-individual-platform-resources)
- [Major references](#major-references)

## Features

This is a Kubernetes implementation using [CoreOS cluster architecture] 
(https://coreos.com/os/docs/latest/cluster-architectures.html) on AWS platform. 

The Terraform structure is moduled after [aws-terraform](https://github.com/xuwang/aws-terraform.git), and Kubernetes cluster is an attempt to automate [kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way) model. At high level:

- A [Vault](https://www.vaultproject.io/) service with S3 storage backend is used to dynamically manage Kubernetes certificates
- A dedicated Etcd cluster as Kubernetes controller backend, which is configured in multi-AZ to achieve HA.
- A Kubernetes cluster (controller, worker), which is configured in multi-AZ to achieve HA.
- CoreOS auto-upgrade, except etcd. Manual upgrade etcd is required.
- Vault self-init, self-unsealing process; You can disable auto-unsealing in production. 
- AWS resources managed by Terraform with S3 remote state
- A Vault PKI backend to facilitate automated Kubernetes certs generation. 
- Separated CA/Certs for secure communications between Kubernetes components. 

The goal of this implementation is not only to automate everything, but also to make it a flexible tool to allow learning, easy change and expend. 

## Prerequisite 

* Setup AWS credentials

We will use `kube-cluster` as AWS account profile for this walk-through. You can change it whatever you like.
This name will be used as AWS-PROFILE environment variable to authentiate to AWS. Unless you want to use an exiting
account profile, make sure you do not already have a `kube-cluster` credential section in $HOME/.aws/credentials. 

Go to [AWS Console](https://console.aws.amazon.com/).

1. Signup AWS account if you don't already have one. The default EC2 instances created by this tool may not be all covered by AWS Free Tier (https://aws.amazon.com/free/) service. Please review resources before proceed.
1. Create a admin group `kube-cluster` with `AdministratorAccess` policy.
1. Create a user `kube-cluster` and __Download__ the user credentials.
1. Add user `kube-cluster` to group `kube-cluster`.

To configure AWS profile with `kube-cluster` credentials

```
$ aws configure --profile kube-cluster
```

Use the [downloaded aws user credentials](#setup-aws-credentials)
when prompted. 

The above command will create a __kube-cluster__ profile authentication section in ~/.aws/config and ~/.aws/credentials files. The build process bellow will automatically configure Terraform AWS provider credentials using this profile. 

* Install tools

We need [Terraform](http://www.terraform.io/downloads.html), [Jq](http://stedolan.github.io/jq/), [graphviz](http://www.graphviz.org/), [AWS CLI](https://github.com/aws/aws-cli). To install tools on MacOS:

    ```
    $ brew update
    $ brew install terraform jq graphviz awscli
    ```

For other platforms, follow the tool links and instructions on these tools's site. Remeber to peirodically update these packages. 

* Clone the repo:

```
$ git clone https://github.com/xuwang/kube-aws-terraform.git
$ cd kube-aws-terraform
```

## AWS Resources

All resources are managed by [Terraform](https://github.com/hashicorp/terraform) whenever possible. The following table shows the default build and where to change the configurations.

### EC2(ASG), ELB

| Service           | m:m:d| Default Size | Description                                                   | Resource   |   
|-------------------|------|--------------|---------------------------------------------------------------|------------|
| Etcd              | 3:3:3| t2.medium    | Etcd storage backend for Kubernetes                           | etcd       |
| Master controller | 3:3:3| t2.medium    | Kubernetes master(api, scheduler, controller)                 | controller |
| Vault             | 1:1  | t2.medium    | Support Kubernetes PKI needs, S3 storage backend              | vault      |
| Worker            | 1:5:2| t2.medium    | Run Pods, default 2 machines                                  | worker     |
| Vault ELB         | N/A  | t2.medium    | Internal vault service endpoint, https://vault.cluster.local  | vault      |
| API ELB, public   | N/A  | N/A          | Public API server endpoint, https://api-server.example.com    | controller |
| API ELB, private  | N/A  | N/A          | Private API server endpoint, https://api-server.cluster.local | controller |

The default capacity is defined in envs.sh:
```
###################
# Env for Terraform
###################
# Default asg parameters: you can override in each resource's own envs.sh.
export TF_VAR_cluster_min_size=1
export TF_VAR_cluster_max_size=5
export TF_VAR_cluster_desired_capacity=3
export TF_VAR_instance_type=t2.medium
...
```

To override, for example, worker nodes:
```
$cd resources/worker
$cat envs.sh
# Env for Worker

export MODULE=worker

# Workers ASG override
export TF_VAR_instance_type="t2.medium"
export TF_VAR_cluster_min_size=1
export TF_VAR_cluster_max_size=5
export TF_VAR_cluster_desired_capacity=3

```

###  Networking

Default VPC prefix __10.240__ is defined in top level envs.sh. You can change this before build. 

| Network          | CIDR                    | Resource                     |
|------------------|-------------------------|------------------------------|
| VPC              | 10.240.0.0/16           | vpc/vpc.tf                   |
| Etcd             | 10.240.1.0/[subs in 3AZ]| vpc/vpc-subnet-etcd.tf       |
| Controller       | 10.240.2.0/[subs in 3AZ]| vpc/vpc-subnet-controller.tf |
| Loadbalancer     | 10.240.3.0/[subs in 3AZ]| vpc/vpc-subnet-elb.tf        |
| Vault            | 10.240.4.0/[subs in 3AZ]| vpc/vpc-subnet-vault.tf      |
| Worker           | 10.240.5.0/[subs in 3AZ}| vpc/vpc-subnet-worker.tf     |
| Kube Service     | 10.32.0.0/24            | variables.tf                 |
| Kube API Service | 10.32.0.1               | variales.tf                  |
| Containers Net   | 10.200.0.0/16           | variables.tf                 |
| Kube DNS Service | 10.32.0.10              | variables.tf                 |

###  Storage - AWS S3 buckets

S3 Buckets are used to store various cluster data. All buckets are prefixed with ${AWS-ACCOUNT}-${CLUSTER_NAME}-.

| Bucket s3://${AWS-ACCOUNT}-${CLUSTER_NAME}-|  Description (* required bucket)                    | Resource        | 
|--------------------------------------------|-----------------------------------------------------|-----------------|
| cloud-init                                 | * Etc member IPs; machine's cloud-config yaml file  | s3              |
| config                                     | * All cluster related configurations                | s3              | 
| logs                                       | Logs bucket                                         | s3              |   
| terraform/${MODULE}.tfstat                 | * Terraform remote state                            | common/common.mk|
| vault-s3-backend                           | * Kubernetes PKI management                         |                 |
| pki                                        | * ca to sign vault root ca/crt; tls for vault client| pki             |     
| pki-token                                  | * auth token to request kubernets's cert dynamically| vault           | 

###  Storage - EBS disks

/var/lib/docker and /opt are on their own partitions and can be tuned in each resource's main.tf file. For exampe,
worker node has this as default:

```
# Instance disks
  root_volume_type = "gp2"
  root_volume_size = 12
  docker_volume_type = "gp2"
  docker_volume_size = 12 
  data_volume_type = "gp2"
  data_volume_size = 100
```

### Other resources

| Resource         | Naming                                        | Description                                      |
|------------------|-----------------------------------------------|--------------------------------------------------|
| Keypairs         | ${CLUSTER_NAME}-[etcd,controller,worker,vault]| Saved in SSHKEY_DIR, ${HOME}/.ssh by default     |
| Profiles         | instances profile, with polices               |                                                  |
| Roles            |                                               | vpc/vpc-subnet-controller.tf                     |
| Route53          | TF_VAR_route53_zone=example.com                 | api server endpoint: api-server.example.com      | 

## Kubernetes PKI vault backend

* Kubernetes Certificate Management

There are two certificate authorities for secure communicate between Kubernetes components:

- etcd-member: for etcd and kubernetes controller (api-server,scheduler, and kubectl). 
- kube-apiserver:  for kubernetes controller and workers (kubelet, kube-proxy).

Vault server will be the first one to build. To verify Vault server readiness, e.g. if CLUSTER_NAME environment is _kubecluster_, you should see _etcd_ and _kube_ PKI backend. 

```
$ cd resources/vault
$ make get-ips
$ ssh core@52.32.98.244
Last login: Thu Jan 26 19:02:40 UTC 2017 from xx.xx.xx.xx on pts/0
Container Linux by CoreOS beta (1248.4.0)
core@ip-10-240-6-26-kubecluster-vault ~ $ sudo su -
root@ip-10-240-6-26-kubecluster-vault ~ $ vault mounts
Path                            Type       Default TTL  Max TTL    Description
cubbyhole/                      cubbyhole  n/a          n/a        per-token private secret storage
kubecluster/pki/etcd-member/     pki        system       315360000  kubecluster/pki/etcd-member Root CA
kubecluster/pki/kube-apiserver/  pki        system       315360000  kubecluster/pki/kube-apiserver Root CA
secret/                         generic    system       system     generic secret storage
sys/                            system     n/a          n/a        system endpoints used for control, policy and debugging
$ sudo su  -
$ vault status
$ vault mounts
Path               Type       Default TTL  Max TTL    Description
cubbyhole/         cubbyhole  n/a          n/a        per-token private secret storage
kubecluster/pki/etcd/  pki        system       315360000  kubecluster/pki/etcd Root CA
kubecluster/pki/kube/  pki        system       315360000  kubecluster/pki/kube Root CA
secret/            generic    system       system     generic secret storage
sys/               system     n/a          n/a        system endpoints used for control, policy and debugging

```
As you can see, there are two PKI mounts for kubernetes cluster.

* Vault audit log

Vault runs as container, and the audit log is enabled:
```
$ vault audit-list
Path   Type  Description  Options
file/  file               path=/vault/logs/vault_audit.log
```
The log is mounted on host as /var/log/vault/vault_audit.log.

* Kubernetes certificates

On etcd servers, controllers, and workers, certificates are dynamically generated by __install_cert__ system unit on every reboot. 

etcd has one cert:
```
$ cd resources/etcd
$ make get-ips
$ ssh core@35.166.72.13
core@ip-10-240-1-22-etcd ~ $ ls -1 /etc/etcd/certs
etcd-member-ca.pem
etcd-member-key.pem
etcd-member.pem
kube-bundle.certs
```

Controller have two certificates:

```
core@ip-10-240-10-136-controller /etc/etcd/certs $ ls -1
etcd-member-ca.pem
etcd-member-key.pem
etcd-member.pem
kube-apiserver-ca.pem
kube-apiserver-key.pem
kube-apiserver.pem
```

Worker has one cert:

```
core@ip-10-240-5-79-worker ~ $ ls -1 /var/lib/kubernetes/
kube-apiserver-ca.pem
kube-apiserver-key.pem
kube-apiserver.pem
```

* Vault PKI server

Vault server self-signed CA is managed by Terraform. The certificate authority is used to sign Vault server cert and validate vault client. 

To re-generate CA:
- Run make pki
- On vault server `systemctl stop vault; systemctl start vault; /opt/bin/vault-init-unseal.sh
- On each vault client servers (etcd, controller, worker), `systemctl start s3sync`

This implementation has internal AWS ELB for vault service, the Route53 DNS name is https://vault.cluster.local.
Vault server rquire TLS connections from clients. The self-signed CA is generated with Terraform. 

To view certificate information:

```
$ cd resources/pki
$ make output
```

## Code Structure

* File tree resource/module

```
.
├── CHANGELOG.md
├── LICENSE
├── Makefile
├── README.md
├── Vagrantfile
├── artifacts
│   └── secrets
│       └── api-server
│           ├── policy.jsonl
│           ├── token.csv
│           └── token.csv.sample
├── envs.sh
├── envs.sh.sample
├── resources
│   ├── artifacts
│   │   ├── cloud-config
│   │   │   ├── common-files.yaml.tmpl
│   │   │   ├── controller.yaml.tmpl
│   │   │   ├── files-vault.yaml
│   │   │   ├── s3-cloudconfig-bootstrap.sh
│   │   │   ├── s3-cloudconfig-bootstrap.sh.tmpl
│   │   │   ├── systemd-units-flannel.yaml
│   │   │   └── systemd-units.yaml
│   │   ├── kubedns-deployment.yaml
│   │   ├── kubedns-service.yaml
│   │   ├── kubernetes-dashboard.yaml
│   │   └── policies
│   │       ├── assume_role_policy.json
│   │       ├── deployment_policy.json
│   │       ├── kubernetes_policy.json
│   │       └── s3_remote_policy.json
│   ├── cloudtrail
│   │   └── cloudtrail.tf
│   ├── common
│   │   ├── common.mk
│   │   └── common.tf
│   ├── controller
│   │   ├── Makefile
│   │   ├── artifacts
│   │   │   ├── cloud-config.yaml.tmpl
│   │   │   ├── policy.json
│   │   │   └── upload
│   │   │       ├── install.sh
│   │   │       ├── policy.jsonl -> ../../../../artifacts/secrets/api-server/policy.jsonl
│   │   │       └── token.csv -> ../../../../artifacts/secrets/api-server/token.csv
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── elb.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   └── security-group.tf
│   ├── etcd
│   │   ├── Makefile
│   │   ├── artifacts
│   │   │   ├── cloud-config.yaml.tmpl
│   │   │   └── policy.json
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   └── provider.tf
│   ├── iam
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── kubernetes.tf
│   │   ├── main.tf
│   │   └── provider.tf
│   ├── kubectl
│   │   ├── Makefile
│   │   ├── envs.sh
│   │   └── provider.tf
│   ├── modules
│   │   ├── cloudtrail
│   │   │   ├── main.tf
│   │   │   └── variables.tf
│   │   ├── cluster
│   │   │   ├── main.tf
│   │   │   └── variables.tf
│   │   ├── efs-target
│   │   │   └── efs-target.tf
│   │   └── subnet
│   │       └── subnet.tf
│   ├── pki
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── pki.tf
│   │   └── provider.tf
│   ├── route53
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   └── provider.tf
│   ├── s3
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   └── provider.tf
│   ├── scripts
│   │   ├── allow-myip.sh
│   │   ├── aws-keypair.sh
│   │   ├── delete-all-object-versions.sh
│   │   ├── gen-provider.sh
│   │   ├── gen-rds-password.sh
│   │   ├── get-ami.sh
│   │   ├── get-dns-name.sh
│   │   ├── get-ec2-public-id.sh
│   │   ├── get-vpc-id.sh
│   │   ├── kube-aws-route.sh
│   │   ├── session-lock.sh
│   │   ├── tf-apply-confirm.sh
│   │   └── turn-off-source-dest-check.sh
│   ├── security-groups
│   │   └── kubernetes.tf
│   ├── vault
│   │   ├── Makefile
│   │   ├── artifacts
│   │   │   ├── cloud-config.yaml.tmpl
│   │   │   ├── policy.json
│   │   │   └── upload
│   │   │       ├── install.sh
│   │   │       └── scripts
│   │   │           ├── create_ca.sh
│   │   │           ├── create_kube_ca.sh
│   │   │           ├── init-unseal.sh
│   │   │           ├── s3get.sh
│   │   │           ├── s3put.sh
│   │   │           └── utils
│   │   │               ├── env_defaults
│   │   │               └── functions
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── elb.tf
│   │   ├── envs.sh
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   └── variables.tf
│   ├── vpc
│   │   ├── Makefile -> ../common/common.mk
│   │   ├── common.tf -> ../common/common.tf
│   │   ├── envs.sh
│   │   ├── provider.tf
│   │   ├── vpc-subnet-controller.tf
│   │   ├── vpc-subnet-elb.tf
│   │   ├── vpc-subnet-etcd.tf
│   │   ├── vpc-subnet-vault.tf
│   │   ├── vpc-subnet-worker.tf
│   │   └── vpc.tf
│   └── worker
│       ├── Makefile
│       ├── artifacts
│       │   ├── cloud-config.yaml.tmpl
│       │   └── policy.json
│       ├── common.tf -> ../common/common.tf
│       ├── envs.sh
│       ├── main.tf
│       └── provider.tf
└── tmp

```
* Add new module

    - mkdir -p resource/\<module\>
    - cd resource/\<module\>; ln -sf ../common/common.tf common.tf
    - cd resource/\<module\>; ln -sf ../common/common.mk Makefile, or include ../common/common.mk in module's customized Makefile
    - Add envs.sh to define module name, override auto-configuration parameters
    - Add a target and its dependencies in top level Makefile
    - Add "terraform_remote_state" in common.tf if the module output will be referened by other modules


## Cluster customization

There are three things you want to take change:

* Copy envs.sh.sample to envs.sh and customize environment variables to match your setup.
* If necessary, override *TF_VAR_cluster_min_size*, *TF_VAR_cluster_max_size*, *TF_VAR_cluster_desired_capacity*, *TF_VAR_instance_type* for etcd, worker, controller, or vault. 
* Copy *artifacts/secrets/api-server/token.csv.sample* to *artifacts/secrets/api-server/token.csv, change the token value. This is used for kubelet and api server ABAC token-based authentication. 

Your customzied envs.sh and tokens.csv files are ignored in .gitignore.

## Build the cluster

* To build default cluster

This default build will create 1 vault node, 1 etcd node, and 2 worker node cluster in a VPC, 
with application buckets for data, necessary iam roles, polices, keypairs and keys. You can review the configuration and 
make changes if needed. See [AWS Resources](#aws-resources) for details. 

The AWS keypairs are stored in SSHKEY_DIR directory. By default, it's in $HOME/.ssh.

```
$ make
... build steps info ...
... at last, shows the worker's ip:
worker public ips: 52.27.156.202
...
```
The code will try to add keypairs to the ssh-agent on your laptop. If you run `ssh-add -l`, you should see the keypairs. You can also find them in $HOME/.ssh  directory. When you destroy the cluster, the keys will be removed too. 

Now you shouild be able to login:
```
$ ssh core@52.27.156.202
```

Although the above quick start will help to understand what the code will do, the common development work flow is to build in steps, for example, you will build VPC first, then etcd, then worker. This is what we usually do for a new environment is to plan and apply for each resources: vpc, vault, etcd, controller, work in that order. By doing this step-by-step, you can avoid unpredictable issues caused by timing - many AWS resources take time to get ready. Rember you can always re-run make command without any harm. The underneath Terraform is able to pick up from where it fails. 

```
$ make plan-core
$ make core
$ make plan-controller
$ make controller
$ make plan-worker
$ make worker
```

#### To see the list of resources created

```
$ cd resources/<module>
$ make show
```

#### Login to cluster node:

By default ssh port 22 is open to your local machine's IP. You should be able to login. You should
modify TF_VAR_allow_ssh_cidr in envs.sh to open to machines you want to allow login.

Here is an example:

```
$ cd resources/etcd
$ make get-ips
etcd public ips:  50.112.218.23
$ ssh core@35.166.72.13
Last login: Thu Jan 26 19:24:09 UTC 2017 from 171.66.208.145 on pts/0
Container Linux by CoreOS beta (1248.4.0)
core@ip-10-240-1-22-etcd ~ $ etcdctl cluster-health
member 543a12bcfd4ac068 is healthy: got healthy result from https://10.240.1.22:2379
cluster is healthy
```

#### Destroy all resources

```
$ make destroy-all
```

This will destroy ALL resources created by this project. You will be asked to confirm before proceed.


## Manage individual platform resources

You can create individual resources and the automated-scripts will create resources automatically based on dependencies. 

Some resources have special make (e.g. EC2 needs create-keys, update-user-data), but in general, you can manage
resources like this:

```
$ cd resources/<resourcename>
$ make plan
$ make
$ make output
$ make show
$ make plan-destroy
$ make destroy
```

## Test the cluster

* Get the Kube api server's public ELB IP. Note the IP can change overtime, this is only for testing. You should setup proper domain delegation for production. 

```
$ cd resources/controller
$ make show | grep elb_kube_apiserver_public_dns_name
$ host <elb A record>
```
* add one of the IPs to /etc/hosts - find KUBE_API_DNSNAME value in envs.sh:

```
52.10.44.234 kube-api.example.com
```
* Setup kubeclt

```
$ cd resources/kubectl
$ make
$ cd resources/worker
$ make smoke-test
```

## Major references

* [kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
* [aws-terraform](https://github.com/xuwang/aws-terraform)
* [vault-and-kubernetes](https://www.digitalocean.com/company/blog/vault-and-kubernetes/)
* [hashicorp-terraform-aws](https://github.com/hashicorp/vault/tree/master/terraform/aws)


