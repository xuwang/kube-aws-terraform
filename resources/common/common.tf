# Shared terraforms for all modules
data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" { } 

data "aws_ami" "coreos_ami" {
 most_recent = true
  name_regex = "^CoreOS-${var.coreos_update_channel}-\\d{4}.\\d{1}.\\d{1}-hvm$"
}

variable "cluster_name" {
    default = "NODEFAULT"
}

# Default cluster size. Each cluster is in an autoscaling group, e.g. worker, etcd, controller.
# You can overide for each autoscaling group under etcd, worker, controller resource with envs.sh.
variable "instance_type" {
}
variable "cluster_az_max_size" {
    default = 4
}
variable "cluster_min_size" {
}
variable "cluster_max_size" {
}
variable "cluster_desired_capacity" {
}
variable "coreos_update_channel" {
    default = "NODEFAULT"
}

variable "allow_ssh_cidr" {
    default = "0.0.0.0/0"
}
variable "cluster_internal_zone" {
    default = "cluster.internal"
}

/* 
Well, module source can't be var: see https://github.com/hashicorp/terraform/issues/1439
variable "module_dir" {
    default = "../modules"
}
*/

variable "module_name" {
    default = "undefined"
}

variable "app_repository"  {
    default = "undefined"
}

variable "artifacts_dir" {
    default = "../artifacts"
}

# Default vpc prefix
variable "vpc_prefix" {
    default = "10.240"
}

variable "timestamp" {
    default = "undefined"
}

variable "git_ssh_command" {
    default = "undefined"
}

variable "route53_zone_name" { 
    default = "example.com"
}

variable "vault_release" { 
    default = "0.6.4"
}

variable "vault_auto_unseal" { 
    default = "false"
}

variable "vault_rootca_cn" { 
    default = "vault.example.com"
}

# Kubernetes
variable "kube_api_dnsname" { 
    default = "kube-api.example.com"
}
variable "kube_cluster_cidr" {
    default = "10.200.0.0/16"
}
variable "kube_service_cidr" {
    default = "10.32.0.0/24"
}
# This is the default kube_api_service endpoint
variable "kube_api_service" {
    default = "10.32.0.1"
}
# This is the default dns addon endpoint
variable "kube_dns_service" {
    default = "10.32.0.10"
}
variable "kube_service_node_ports" {
    default = "30000-32767"
}
# Kubernetes network plugin binary path 
variable "cni_plugin_url" {
  default = "https://storage.googleapis.com/kubernetes-release/network-plugins/cni-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz"
}
# Kubelet/apiserver ABAC token.
variable "kubelet_token" {
    default = "NODEFAULT"
}
# Kubernetes version
variable "kube_version" {
    default = "v1.5.2"
}

# Sensitive data
variable "secrets_path" { 
    default = "../artifacts/secrets"
}

variable "vault_ca" {
    default = {
        country = "US"
        province = "California"
        organization = "IT Department"
        common_name = "example.com"
    }
}

# 10 years TTL
variable "vault_ca_cert_ttl_hours" { 
    default = "87600"
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}
#
# setup remote state data source
#

data "terraform_remote_state" "etcd" {
    backend = "s3"
    config {
        bucket = "${var.remote_state_bucket}"
        key = "etcd.tfstate"
        region = "${var.remote_state_region}"
    }
}

data "terraform_remote_state" "iam" {
    backend = "s3"
    config {
        bucket = "${var.remote_state_bucket}"
        key = "iam.tfstate"
        region = "${var.remote_state_region}"
    }
}

data "terraform_remote_state" "pki" {
    backend = "s3"
    config {
        bucket = "${var.remote_state_bucket}"
        key = "pki.tfstate"
        region = "${var.remote_state_region}"
    }
}

data "terraform_remote_state" "route53" {
    backend = "s3"
    config {
        bucket = "${var.remote_state_bucket}"
        key = "route53.tfstate"
        region = "${var.remote_state_region}"
    }
}

data "terraform_remote_state" "s3" {
    backend = "s3"
    config {
        bucket = "${var.remote_state_bucket}"
        key = "s3.tfstate"
        region = "${var.remote_state_region}"
    }
}

data "terraform_remote_state" "worker" {
    backend = "s3"
    config {
        bucket = "${var.remote_state_bucket}"
        key = "worker.tfstate"
        region = "${var.remote_state_region}"
    }
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "${var.remote_state_bucket}"
        key = "vpc.tfstate"
        region = "${var.remote_state_region}"
    }
}
