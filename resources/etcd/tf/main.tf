module "etcd" {
  source = "/build/modules/cluster-no-opt-data"

  # cluster variables
  asg_name = "${var.cluster_name}-etcd"
  cluster_name = "${var.cluster_name}"

  # a list of subnet IDs to launch resources in.
  cluster_vpc_zone_identifiers =
    [ "${data.terraform_remote_state.vpc.etcd_zone_ids}" ]

  # for etcd, cluster_min_size = cluster_max_size = cluster_desired_capacity = <odd number>
  cluster_min_size = "${var.cluster_min_size}"
  cluster_max_size = "${var.cluster_max_size}"
  cluster_desired_capacity = "${var.cluster_desired_capacity}"
  cluster_security_groups = "${aws_security_group.etcd.id}"

  # Instance specifications
  ami = "${data.aws_ami.coreos_ami.id}"
  image_type = "${var.instance_type}"
  keypair = "${var.cluster_name}-etcd"

  # Note: currently etcd launch_configuration devices can NOT be changed after etcd cluster is up
  # See https://github.com/hashicorp/terraform/issues/2910
  # Instance disks
  root_volume_type = "gp2"
  root_volume_size = 100
  docker_volume_type = "gp2"
  docker_volume_size = 12

  user_data = "${data.template_file.user_data.rendered}"
  iam_role_policy = "${data.template_file.etcd_policy_json.rendered}"
}


data "template_file" "user_data" {
    template = "${file("${var.artifacts_dir}/user-data-s3-bootstrap.sh")}"

    # explicitly wait for these configurations to be uploaded to s3 buckets
    depends_on = [ "aws_s3_bucket_object.etcd_cloud_config" ]

    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CONFIG_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
        "MODULE_NAME" = "${var.module_name}"
        "CUSTOM_TAG" = "${var.module_name}"
    }
}

data "template_file" "etcd_policy_json" {
    template = "${file("${var.artifacts_dir}/policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

resource "aws_security_group" "etcd"  {
  name = "${var.cluster_name}-etcd"
  vpc_id = "${data.terraform_remote_state.vpc.cluster_vpc_id}"
  description = "etcd"
  # Hacker's note: the cloud_config has to be uploaded to s3 before instances fireup
  # but module can't have 'depends_on', so we have to make
  # this indrect dependency through security group
  #depends_on = ["aws_s3_bucket_object.etcd_cloud_config"]
  lifecycle { create_before_destroy = true }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow etcd peers to communicate, include etcd proxies
  ingress {
    from_port = 2380
    to_port = 2380
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.cluster_vpc_cidr}"]
  }

  # Allow etcd clients to communicate
  ingress {
    from_port = 2379
    to_port = 2379
    protocol = "tcp"
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

  tags {
    KubernetesCluster = "${var.cluster_name}"
  }
  tags {
    Name = "${var.cluster_name}-etcd"
  }
}

output "etcd_security_group" { value = "${aws_security_group.etcd.id}" }
