# Building Kubernetes Cluster on AWS

This is a Kubernetes implementation using [CoreOS](https://coreos.com/os/docs/latest/cluster-architectures.html#production-cluster-with-central-services) on AWS platform. The goals of this implementation are:

* Automate Kubernetes cluster build process
* Design with production quality (.e.g., HA, secure communications) in mind
* Provide flexibility to allow each cluster component to be changed, expanded, and updated after build

## Table of Contents ##

- [Features](#features)
- [Prerequisite](#prerequisite)
- [Quick Start](#quick-start)
- [Test Cluster](#test-cluster)
- [Teardown](#teardown)
- [Cluster Guide](#cluster-guide)
- [Limitations](#limitations)
- [Major References](#major-references)

## Features

* Kubernetes 1.5.4, Docker engine 1.12.6
* AWS provider integration (ELB,EBS)
* Terraform 0.9, with remote state on S3 storage
* Autoscaling group for each etcd2, controller, worker, and vault cluster
* CoreOS for self-upgrade/patching management
* [Hashicorp Vault 0.6.5](https://www.vaultproject.io/) service with PKI mount to manage Kubernetes certificates, i.e. create and renew automatically.
* Separated CA/Certs for secure communications between Kubernetes components
* Add-ons installed:
  * kubedns
  * kubernetes-dashboard
  * monitoring-grafana

## Prerequisite

### Setup AWS credentials

You can use an exiting account profile (then skip this section), or create a new one. We will use `kube-user` as a new AWS account to authenticate to AWS.  Go to [AWS Console](https://console.aws.amazon.com/).

* Create an admin group `kube-admin` with `AdministratorAccess` policy.
* Create a user `kube-user` and __Download__ the user credentials.
* Add user `kube-user` to group `kube-admin`.

To configure AWS profile with `kube-user` credential:

```
$ aws configure --profile kube-user
```
Input AWS access key id and secret at the prompt. The build process bellow will configure Terraform AWS provider to use `kube-user` profile stored in ~/.aws/credentials.

### Install tools

Install [Terraform](http://www.terraform.io/downloads.html), [Jq](http://stedolan.github.io/jq/), [graphviz](http://www.graphviz.org/), [AWS CLI](https://github.com/aws/aws-cli) on MacOS:

```
$ brew update
$ brew install terraform jq graphviz awscli gettext
$ brew link --force gettext
```
__NOTE:__ Make sure the installed Terraform version is matching the required Terraform version defined in env.sh.sample by `TF_VERSION`.


[Install kubectl](https://kubernetes.io/docs/user-guide/prereqs/)

Remember to periodically update these packages.

## Quick Start

### Clone the repository

```
$ git clone https://github.com/xuwang/kube-aws-terraform.git
$ cd kube-aws-terraform
```

### Minimum cluster configuration

There are two files you want to make change:

* Copy **envs.sh.sample** to **envs.sh** and customize environment variables to match your setup.
* Copy **artifacts/secrets/api-server/token.csv.sample** to **artifacts/secrets/api-server/token.csv**, change the token value. This is used for kubelet and API server ABAC token-based authentication.

**envs.sh** and **tokens.csv** files are ignored in .gitignore.

A minimum cluster configuration must contain **AWS_ROFILE**, unique **CLUSTER_NAME**,  **ROUTE53_ZONE_NAME**, as shown in the example below:

```
###############################
# Environments for the cluster.
###############################

export AWS_PROFILE=kube-user
export AWS_REGION=us-west-2
export CLUSTER_NAME=kube-cluster
export COREOS_UPDATE_CHANNEL=beta
export ROUTE53_ZONE_NAME=example.com
export ENABLE_REMOTE_VERSIONING=false

# Kubernetes API server DNS name
export KUBE_API_DNSNAME=kube-api.example.com

export SCRIPTS=../scripts
export SEC_PATH=../artifacts/secrets
export SSHKEY_DIR=${HOME}/.ssh
```
NOTE: AWS route53 zone will be created. If you use an existing Route53 zone, you need to change Terraform configuration under *resources/route53* directory.

### Build default cluster

The default EC2 instance type (t2.medium) is **not** covered by AWS Free Tier (https://aws.amazon.com/free/) service. Estimated cost with the default infrastructure build is about $16.00/day. Please review resources before proceed.

```
$ make cluster | tee /tmp/build.log
```
It takes about 15 minutes for the cluster to be ready.

This build will create following nodes, S3 buckets, necessary iam roles, polices, keypairs, and keys. See [AWS Resources](docs/01-AWS-resources.md) for resource details.  Run `more -R /tmp/build.log` to review build events.

At AWS console, you should see you should have the following compute instances:

![EC2 Console](./images/ec2-instances.png)

## Test Cluster

### Setup public api server DNS

In order to test using Kube API server DNS name, we need to get the kube api server's public ELB IP. Here we
will use /etc/hosts file for testing purpose.

```
$ make get-apiserver-elb
Please add "54.186.177.19 kube-api.example.com" to /etc/hosts file.
```

You may need update the /etc/hosts file if you are not able to connect to the api server after a while because ELB IP can change. You should setup example.com domain delegation properly for production.

### Config kubectl and deploy add-ons

To setup kubectl config and deploy add-ons, i.e. kubedns, dashboard, and monitor:

```
$ make add-ons

$ kubectl cluster-info
Kubernetes master is running at https://kube-api.example.com:6443
Heapster is running at https://kube-api.example.com:6443/api/v1/proxy/namespaces/kube-system/services/heapster
KubeDNS is running at https://kube-api.example.com:6443/api/v1/proxy/namespaces/kube-system/services/kube-dns
monitoring-grafana is running at https://kube-api.example.com:6443/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana
monitoring-influxdb is running at https://kube-api.example.com:6443/api/v1/proxy/namespaces/kube-system/services/monitoring-influxdb

$ kubectl proxy --port=8001
127.0.0.1:8001
```
#### To access the kubernetes dashboard, point your browser to 127.0.0.1:80011/ui

![Dashboard](./images/dashboard.png)

#### To access the Grafana monitoring via proxy: point your browser to 127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana

![Monitor](./images/kube-monitor.png)

### Start a GitLab application

There is a GitLab deployment example that contains redis, postgres, and gitlab container. To start it:
```
$ cd apps/gitlab
$ ./deploy.sh
$ ./get-load-balancer.sh
Waiting for loadBanlancer...
Conntect to GitLab at: http://af47deebaefef11e6b21c069e4a1413d-1227612122.us-west-2.elb.amazonaws.com
```
Now you should be able to connect GitLab service at the above load-balancer address. Default login info is in **gitlab-rc.yml**.

## Teardown

This will delete all Kubernetes deployments provisioned and destroy all AWS resources. You will be asked to confirm when
AWS resources are to be destroyed. This includes vault data, remote terraform state. You rarely do this unless you are doing development work.

```
$ make teardown
```
## Cluster Guide

- [Run book](docs/00-run-book.md)
- [AWS Resourses](docs/01-aws-resources.md)
- [Kubernetes PKI vault backend](docs/02-vault-pki.md)
- [Cluster configuration](docs/03-configuration.md)
- [Code structure](docs/04-files.md)
- [Manage individual platform resources](docs/05-manage-resources.md)
- [Clean up](docs/07-cleanup.md)

## The Team

- Xueshan Feng <xueshan.feng@gmail.com>
- Xu Wang <xuwang@gmail.com>

## Limitations

* Route53 zone will be created as new. You  can change Route53 Terraform to use existing route53 data.

All of these will be further automated in future release.

## Major references

* [kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
* [vault-and-kubernetes](https://www.digitalocean.com/company/blog/vault-and-kubernetes/)
* [hashicorp-terraform-aws](https://github.com/hashicorp/vault/tree/master/terraform/aws)
* [aws-under-the-hood](https://github.com/kubernetes/kubernetes/blob/release-1.5/docs/design/aws_under_the_hood.md)
