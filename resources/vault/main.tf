
# Reference: https://github.com/hashicorp/vault/tree/master/terraform/aws
module "vault" {
  source = "../modules/cluster"

  # cluster varaiables
  asg_name = "${var.cluster_name}-vault"
  cluster_name = "${var.cluster_name}"
  # A list of subnet IDs to launch resources in.
  cluster_vpc_zone_identifiers = ["${data.terraform_remote_state.vpc.vault_zone_ids}"]
  # for vault, cluster_min_size = cluster_max_size = cluster_desired_capacity = <odd number>
  cluster_min_size = 1
  cluster_max_size = 1
  cluster_desired_capacity = 1
  cluster_security_groups = "${aws_security_group.vault.id}"

  # Instance specifications
  ami = "${data.aws_ami.coreos_ami.id}"
  image_type = "m3.medium"
  keypair = "${var.cluster_name}-vault"

  # Note: currently vault launch_configuration devices can NOT be changed after vault cluster is up
  # See https://github.com/hashicorp/terraform/issues/2910
  # Instance disks
  root_volume_type = "gp2"
  root_volume_size = 12
  docker_volume_type = "gp2"
  docker_volume_size = 12 
  data_volume_type = "gp2"
  data_volume_size = 100

  user_data = "${data.template_file.user_data.rendered}"
  iam_role_policy = "${data.template_file.vault_policy_json.rendered}"
}

# Create a load balancer attachment
resource "aws_autoscaling_attachment" "asg_attachment_vault" {
  autoscaling_group_name = "${module.vault.aws_autoscaling_group_instance_pool_id}"
  elb                    = "${aws_elb.vault.id}"
}

data "template_file" "user_data" {
    template = "${file("${var.artifacts_dir}/cloud-config/s3-cloudconfig-bootstrap.sh.tmpl")}"
    vars {
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

# Upload CoreOS cloud-config to a s3 bucket; s3-cloudconfig-bootstrap script in user-data will download 
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when 
# changing cloud-config.
resource "aws_s3_bucket_object" "vault_cloud_config" {
  bucket = "${data.terraform_remote_state.s3.s3_cloudinit_bucket}"
  key = "${var.cluster_name}-vault/cloud-config.yaml"
  content = "${data.template_file.vault_cloud_config.rendered}"
}

# Create pki-tokens path to store issued pki tokens
resource "aws_s3_bucket_object" "vault_pki_tokens" {
  bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
  key = "pki-tokens/created-timestamp"
  content = "place-holder"
}

data "template_file" "vault_cloud_config" {
    template = "${file("./artifacts/cloud-config.yaml.tmpl")}"
    vars {
        "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
        "AWS_USER" = "${data.terraform_remote_state.iam.deployment_user}"
        "AWS_ACCESS_KEY_ID" = "${data.terraform_remote_state.iam.deployment_key_id}"
        "AWS_SECRET_ACCESS_KEY" =  "${data.terraform_remote_state.iam.deployment_key_secret}"
        "AWS_DEFAULT_REGION" = "${var.aws_account["default_region"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "APP_REPOSITORY" = "${var.app_repository}"
        "GIT_SSH_COMMAND" = "\"${var.git_ssh_command}\""
        "VAULT_RELEASE" = "${var.vault_release}"
        "VAULT_AUTO_UNSEAL" = "${var.vault_auto_unseal}"
        "VAULT_ROOTCA_CN" = "${var.vault_rootca_cn}"
        "ROUTE53_ZONE_NAME" = "${var.route53_zone_name}"
        "MODULE_NAME" = "${var.module_name}" 
        "VAULT_TOKEN_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
    }
}

data "template_file" "vault_policy_json" {
    template = "${file("./artifacts/policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

// Security group for Vault allows SSH and HTTP access (via "tcp" in
// case TLS is used)
resource "aws_security_group" "vault" {
    name = "vault"
    description = "Vault servers"
    vpc_id = "${data.terraform_remote_state.vpc.cluster_vpc_id}"
    tags {
        Name = "${var.cluster_name}-vault"
    }
}

resource "aws_security_group_rule" "vault-ssh" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${split(",", var.allow_ssh_cidr)}"]
}

# Allow etcd client to communicate
resource "aws_security_group_rule" "vault-etcd" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 2380
    to_port = 2380
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.cluster_vpc_cidr}"]
}

# Allow etcd peers to communicate
resource "aws_security_group_rule" "vault-etcd-peer" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 2379
    to_port = 2379
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.cluster_vpc_cidr}"]
}

// This rule allows Vault HTTP API access to individual node, since each will
// need to be addressed individually for unsealing.
resource "aws_security_group_rule" "vault-http-api" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8200
    to_port = 8200
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-egress" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

output "vault_security_group" { value = "${aws_security_group.vault.id}" }
