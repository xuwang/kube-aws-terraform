module "node" {
  source = "/build/modules/cluster"

  # cluster variables
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

  # Note: currently launch_configuration devices can NOT be changed after the ASG is up
  # See https://github.com/hashicorp/terraform/issues/2910
  # Instance disks
  root_volume_type = "gp2"
  root_volume_size = 50
  docker_volume_type = "gp2"
  docker_volume_size = 50
  data_volume_type = "gp2"
  data_volume_size = 100

  user_data = "${data.template_file.user_data.rendered}"
  iam_role_policy = "${data.template_file.node_policy_json.rendered}"
}

data "template_file" "user_data" {
    template = "${file("${var.artifacts_dir}/user-data-s3-bootstrap.sh")}"

    # explicitly wait for these configurations to be uploaded to s3 buckets
    depends_on = [ "aws_s3_bucket_object.envvars",
                   "aws_s3_bucket_object.node_cloud_config",
                   "aws_s3_bucket_object.kubelet-kubeconfig",
                   "aws_s3_bucket_object.kube-proxy-kubeconfig" ]
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CONFIG_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
        "MODULE_NAME" = "${var.module_name}"
        "CUSTOM_TAG" = "${var.module_name}"
    }
}

data "template_file" "node_policy_json" {
    template = "${file("${artifacts_dir}/policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

resource "aws_security_group" "node"  {
  name = "${var.cluster_name}-node"
  vpc_id = "${data.terraform_remote_state.vpc.cluster_vpc_id}"
  description = "node"
  lifecycle { create_before_destroy = true }

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

  # Allow SSH from pre-defined IP addresses
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
