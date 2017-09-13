
# Reference: https://github.com/hashicorp/vault/tree/master/terraform/aws
module "vault" {
  source = "/build/modules/cluster-no-opt-data"

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
  image_type = "${var.instance_type}"
  keypair = "${var.cluster_name}-vault"

  # Note: currently vault launch_configuration devices can NOT be changed after vault cluster is up
  # See https://github.com/hashicorp/terraform/issues/2910
  # Instance disks
  root_volume_type = "gp2"
  root_volume_size = 100
  docker_volume_type = "gp2"
  docker_volume_size = 12

  user_data = "${data.template_file.user_data.rendered}"
  iam_role_policy = "${data.template_file.vault_policy_json.rendered}"
}

# Create a load balancer attachment
resource "aws_autoscaling_attachment" "asg_attachment_vault" {
  autoscaling_group_name = "${module.vault.aws_autoscaling_group_instance_pool_id}"
  elb                    = "${aws_elb.vault.id}"
}

data "template_file" "user_data" {
    template = "${file("${var.artifacts_dir}/user-data-s3-bootstrap.sh")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CONFIG_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
        "MODULE_NAME" = "${var.module_name}"
        "CUSTOM_TAG" = "${var.module_name}"
        # Implicitly wait for the below buckets to be ready. Cannot use depends_on
        # See https://github.com/hashicorp/terraform/issues/15491
        "ENVVARS_BUCKET" = "${aws_s3_bucket_object.envvars.id}"
        "VAULT_CNF_BUCKET" = "${aws_s3_bucket_object.vault_cnf.id}"
        "VAULT_HCL_BUCKET" = "${aws_s3_bucket_object.vault_hcl.id}"
        "VAULT_SH" = "${aws_s3_bucket_object.vault_sh.id}"
        "VAULT_CLOUD_CONFIG" = "${aws_s3_bucket_object.vault_cloud_config.id}"
    }
}

// Security group for Vault allows SSH and HTTP access (via "tcp" in
// case TLS is used)
resource "aws_security_group" "vault" {
    name = "${var.cluster_name}-vault"
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
