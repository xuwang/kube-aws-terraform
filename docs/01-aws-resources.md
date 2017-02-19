## AWS Resources

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


All resources are managed by [Terraform](https://github.com/hashicorp/terraform) whenever possible. The following table shows the default build and you can override autoscaling configurations in each resource's envs.sh file.

### EC2(ASG), ELB

| Service           |# Node| Size         | Description                                                   | Resource   |   
|-------------------|------|--------------|---------------------------------------------------------------|------------|
| Etcd              | 1    | t2.medium    | Etcd storage backend for Kubernetes                           | etcd       |
| Master controller | 1    | t2.medium    | Kubernetes master(api, scheduler, controller)                 | controller |
| Vault             | 1    | t2.medium    | Support Kubernetes PKI needs, S3 storage backend              | vault      |
| Worker            | 2    | t2.medium    | Run Pods, default 2 machines                                  | worker     |
| Vault ELB         | N/A  | t2.medium    | Internal vault endpoint, https://vault.cluster.internal       | vault      |
| API ELB, public   | N/A  | N/A          | Public API server endpoint, https://api-server.example.com    | controller |
| API ELB, private  | N/A  | N/A          | Private API server endpoint, https://api-server.cluster.internal | controller |

The default capacity is defined in envs.sh:
```
###################
# Env for Terraform
###################
# Default asg parameters: you can override in each resource's own envs.sh.
export TF_VAR_cluster_min_size=1
export TF_VAR_cluster_max_size=5
export TF_VAR_cluster_desired_capacity=1
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
###  Storage - AWS S3 buckets

S3 Buckets are used to store various cluster data. All buckets are prefixed with ${AWS-ACCOUNT}-${CLUSTER_NAME}-.

| Bucket s3://${AWS-ACCOUNT}-${CLUSTER_NAME}-|  Description (* required bucket)                    | Resource       | 
|--------------------------------------------|-----------------------------------------------------|----------------|
| cloud-init                                 | * Etc member IPs; machine's cloud-config yaml file  | s3             |
| config                                     | * All cluster related configurations                | s3             | 
| logs                                       | Logs bucket                                         | s3             |   
| terraform/${MODULE}.tfstat                 | * Terraform remote state                            |common/common.mk|
| vault-s3-backend                           | * Kubernetes PKI management                         |                |
| pki                                        | * ca to sign vault root ca/crt; tls for vault client| pki            |
| pki-token                                  | * auth token to request kubernets's cert dynamically vault          | 

###  Storage - EBS disks

/var/lib/docker and /opt are on their own partitions and can be tuned in each resource's main.tf file. For example,
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
| Route53          | TF_VAR_route53_zone=example.com               | api server endpoint: api-server.example.com      | 


