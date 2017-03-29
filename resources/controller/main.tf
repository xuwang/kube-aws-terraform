module "controller" {
  source = "../modules/cluster-no-opt-data"

  # cluster varaiable
  asg_name = "${var.cluster_name}-controller"
  cluster_name = "${var.cluster_name}"

  # a list of subnet IDs to launch resources in.
  cluster_vpc_zone_identifiers =
    [ "${data.terraform_remote_state.vpc.controller_zone_ids}" ]

  # Cluster specifications
  cluster_min_size = "${var.cluster_min_size}"
  cluster_max_size = "${var.cluster_max_size}"
  cluster_desired_capacity = "${var.cluster_desired_capacity}"
  cluster_security_groups = "${aws_security_group.kubernetes.id}"

  # Instance specifications
  ami = "${data.aws_ami.coreos_ami.id}"
  image_type = "${var.instance_type}"
  keypair = "${var.cluster_name}-controller"

  # Note: currently controller launch_configuration devices can NOT be changed after controller cluster is up
  # See https://github.com/hashicorp/terraform/issues/2910
  # Instance disks
  root_volume_type = "gp2"
  root_volume_size = 100
  docker_volume_type = "gp2"
  docker_volume_size = 12

  user_data = "${data.template_file.user_data.rendered}"
  iam_role_policy = "${data.template_file.controller_policy_json.rendered}"
}

# Create a load balancer attachment for controller
resource "aws_autoscaling_attachment" "asg_attachment_controller_public" {
  autoscaling_group_name = "${module.controller.aws_autoscaling_group_instance_pool_id}"
  elb                    = "${aws_elb.kube_apiserver_public.id}"
}
# Create a load balancer attachment for controller
resource "aws_autoscaling_attachment" "asg_attachment_controller_private" {
  autoscaling_group_name = "${module.controller.aws_autoscaling_group_instance_pool_id}"
  elb                    = "${aws_elb.kube_apiserver_private.id}"
}

# First bootstrap script, same for all modules
data "template_file" "user_data" {
    template = "${file("${var.artifacts_dir}/cloud-config/user-data-s3-bootstrap.sh")}"

    # explicitly wait for these configurations to be uploaded to s3 buckets
    depends_on = ["aws_s3_bucket_object.envvars",
                  "aws_s3_bucket_object.controller_cloud_config"]
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CONFIG_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
        "MODULE_NAME" = "${var.module_name}"
    }
}

data "template_file" "controller_policy_json" {
    template = "${file("./artifacts/policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

