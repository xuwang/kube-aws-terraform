# Building Kubernetes Cluster on AWS 

This is a Kubernetes implementation using [CoreOS cluster architecture] 
(https://coreos.com/os/docs/latest/cluster-architectures.html) on AWS platform. The goals of this implementation are:

* Automate Kubernetes cluster build process
* Design with production quality (.e.g., HA, security) in mind
* Provide flexibility to allow each cluster component to be changed, expanded, and updated after build

## Table of Contents ##

- [Features](#features)
- [Prerequisite](#rerequisite)
- [Quick Start](#quick-start)
- [Test the Cluster](#test-cluster)
- [Cluster Guide](#guide)
- [Major References](#major-references)

## Features

* Kubernetes 1.5.2, Docker engine 1.12.6
* AWS provider integration (ELB)
* Terraform 0.8.4, with remote state on S3 storage
* Etcd2 cluster for Kubernetes controllers
* All instances are created in autoscaling group
* CoreOS image for self-upgrade/patching management
* [Hashicorp Vault 6.4](https://www.vaultproject.io/) service with PKI mount to manage Kubernetes certificates
* Separated CA/Certs for secure communications between Kubernetes components

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

**envs.sh** and **tokens.csv** files are ignored in .gitignore. A minimum cluster configuration must contain **AWS_ROFILE**, unique **CLUSTER_NAME**,  **ROUTE53_ZONE_NAME**, as shown in the example below:

```
###############################
# Environments for the cluster.
###############################

export AWS_PROFILE=kube-cluster
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

The default EC2 instance type (t2.medium) is **not** covered by AWS Free Tier (https://aws.amazon.com/free/) service. Please review resources before proceed.

```
$ make cluster | tee /tmp/build.log
```

This build will create following nodes, S3 buckets, necessary iam roles, polices, keypairs, and keys. See [AWS Resources](docs/01-AWS-resources.md) for resource details.  Run `more -R /tmp/build.log` to review build events.

* 1 vault node: PKI service
* 1 etcd node: controller backend
* 1 controller node: kube controller
* 2 worker node: Kubernetes workers

## Test the cluster

### Setup public api server DNS

In order to test using Kube API server DNS name, we need to get the kube api server's public ELB IP. Here we 
will use /etc/hosts file for testing purpose.

```
$ make get-apiserver-elb

Please add 54.186.177.19 kube-api.example.com to /etc/hosts file.
``` 

You may need update the /etc/hosts file if you are not able to connect to the api server after a while because ELB IP can change. You should setup domain delegation properly to kube-cluster.example.com for production.

### Setup kubectl

```
$ make add-ons
$ kubectl proxy --port=0
127.1.1.0:<localport>
```

Point your browser to 127.1.1.0:<localport>/ui to bring up Kubernetes dashboard.

### Start a gitlab application

There is a gitlab deployment example that contains redis, postgres, and gitlab container. To start it:
```
$ cd apps/gitlab
$ ./deploy.sh
$ ./get-load-balancer.sh
Waiting for loadBanlancer...
Conntect to GitLab at: http://af47deebaefef11e6b21c069e4a1413d-1227612122.us-west-2.elb.amazonaws.com
```
Now you should be able to connet Gitlab service at the above load-balancer address.

Tear down:
```
$ cd apps/gitlab
$ ./teardown
```
## Cluster Guide

- [AWS Resourses](docs/01-AWS-resources.md)
- [Kubernetes PKI vault backend](docs/02-vault-pki.md)
- [Cluster configuration](docs/03-configuration.md)
- [Code structure](docs/04-files.md)
- [Manage individual platform resources](docs/05-manage-individual-platform-resources.md)
- [Run book](docs/06-run-book.md)
- [Clean up](docs/07-cleanup.md)

## The Team

- Xueshan Feng <xueshan.feng@gmail.com>
- Xu Wang <xuwang@gmail.com>

## Major references

* [kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
* [vault-and-kubernetes](https://www.digitalocean.com/company/blog/vault-and-kubernetes/)
* [hashicorp-terraform-aws](https://github.com/hashicorp/vault/tree/master/terraform/aws)
* [aws-under-the-hood](https://github.com/kubernetes/kubernetes/blob/release-1.5/docs/design/aws_under_the_hood.md)
