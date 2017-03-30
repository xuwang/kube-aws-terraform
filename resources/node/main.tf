module "node" {
  source = "../modules/cluster"

  # cluster varaiables
  cluster_name = "${var.cluster_name}"
  asg_name = "${var.cluster_name}-node"
  # a list of subnet IDs to launch resources in.
  cluster_vpc_zone_identifiers =
    ["${data.terraform_remote_state.vpc.node_zone_ids}"]
  cluster_min_size = "${var.cluster_min_size}"
  cluster_max_size = "${var.cluster_max_size}"
  cluster_desired_capacity = "${var.cluster_desired_capacity}"
  cluster_security_groups = "${aws_security_group.node.id}"

  # Instance specifications
  ami = "${data.aws_ami.coreos_ami.id}"
  image_type = "${var.instance_type}"
  keypair = "${var.cluster_name}-node"

  # Note: currently node launch_configuration devices can NOT be changed after node cluster is up
  # See https://github.com/hashicorp/terraform/issues/2910
  # Instance disks
  root_volume_type = "gp2"
  root_volume_size = 12
  docker_volume_type = "gp2"
  docker_volume_size = 12
  data_volume_type = "gp2"
  data_volume_size = 100

  user_data = "${data.template_file.user_data.rendered}"
  iam_role_policy = "${data.template_file.node_policy_json.rendered}"
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
resource "aws_s3_bucket_object" "node_cloud_config" {
  bucket = "${data.terraform_remote_state.s3.s3_cloudinit_bucket}"
  key = "${var.cluster_name}-node/cloud-config.yaml"
  content = "${data.template_file.node_cloud_config.rendered}"
}
data "template_file" "node_cloud_config" {
    template = "${file("./artifacts/cloud-config.yaml.tmpl")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "AWS_USER" =
          "${data.terraform_remote_state.iam.deployment_user}"
        "AWS_ACCESS_KEY_ID" =
          "${data.terraform_remote_state.iam.deployment_key_id}"
        "AWS_SECRET_ACCESS_KEY" =
          "${data.terraform_remote_state.iam.deployment_key_secret}"
        "AWS_DEFAULT_REGION" = "${var.aws_account["default_region"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "APP_REPOSITORY" = "${var.app_repository}"
        "GIT_SSH_COMMAND" = "\"${var.git_ssh_command}\""
        "CNI_PLUGIN_URL" = "${var.cni_plugin_url}"
        "MODULE_NAME" = "${var.module_name}"
        "CUSTOM_TAG" = "${var.module_name}"
        "VAULT_RELEASE" = "${var.vault_release}"
        "KUBE_API_SERVICE" = "${var.kube_api_service}"
        "KUBE_DNS_SERVICE" = "${var.kube_dns_service}"
        "KUBE_CLUSTER_CIDR" = "${var.kube_cluster_cidr}"
        "KUBE_VERSION" = "${var.kube_version}"
        "KUBELET_TOKEN" = "${var.kubelet_token}"
    }
}

data "template_file" "node_policy_json" {
    template = "${file("./artifacts/policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

resource "aws_security_group" "node"  {
  name = "${var.cluster_name}-node"
  vpc_id = "${data.terraform_remote_state.vpc.cluster_vpc_id}"
  description = "node"
  # Hacker's note: the cloud_config has to be uploaded to s3 before instances fireup
  # but module can't have 'depends_on', so we have to make
  # this indrect dependency through security group
  depends_on = ["aws_s3_bucket_object.node_cloud_config"]

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access from vpc
  ingress {
    from_port = 10
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.cluster_vpc_cidr}"]
  }

  # Allow access from vpc
  ingress {
    from_port = 10
    to_port = 65535
    protocol = "udp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.cluster_vpc_cidr}"]
  }

  # Allow SSH from my hosts
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${split(",", var.allow_ssh_cidr)}"]
    self = true
  }

  # Allow PodCIDR so containers can communicate. E.g. kube-dns is very slow or intermittent not working
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.kube_cluster_cidr}"]
    self = true
  }

  tags {
    KubernetesCluster = "${var.cluster_name}"
  }
  tags {
    Name = "${var.cluster_name}-node"
  }
}

output "node_security_group" { value = "${aws_security_group.node.id}" }
