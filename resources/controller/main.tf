module "controller" {
  source = "../modules/cluster"

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
  root_volume_size = 12
  docker_volume_type = "gp2"
  docker_volume_size = 12 
  data_volume_type = "gp2"
  data_volume_size = 100

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
    template = "${file("${var.artifacts_dir}/cloud-config/s3-cloudconfig-bootstrap.sh.tmpl")}"
    vars {
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

data "template_file" "controller_policy_json" {
    template = "${file("./artifacts/policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

# Upload CoreOS cloud-config to a s3 bucket; s3-cloudconfig-bootstrap script in user-data will download 
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when 
# changing cloud-config.
resource "aws_s3_bucket_object" "controller_cloud_config" {
  bucket = "${data.terraform_remote_state.s3.s3_cloudinit_bucket}"
  key = "${var.cluster_name}-controller/cloud-config.yaml"
  content = "${data.template_file.controller_cloud_config.rendered}"
}

data "template_file" "controller_cloud_config" {
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
        "ROUTE53_ZONE_NAME" = "${var.route53_zone_name}"
        "MODULE_NAME" = "${var.module_name}"
        "KUBE_CLUSTER_CIDR" = "${var.kube_cluster_cidr}"
        "KUBE_SERVICE_CIDR" = "${var.kube_service_cidr}"
        "KUBE_SERVICE_NODE_PORTS" = "${var.kube_service_node_ports}"
        "KUBE_API_DNSNAME" = "${var.kube_api_dnsname}"   
        "KUBE_API_SERVICE" = "${var.kube_api_service}"
        "KUBE_VERSION" = "${var.kube_version}"
    }
}

