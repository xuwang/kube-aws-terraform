# Upload CoreOS cloud-config to a s3 bucket; s3-cloudconfig-bootstrap script in user-data will download 
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when 
# changing cloud-config.
resource "aws_s3_bucket_object" "etcd_cloud_config" {
  bucket = "${data.terraform_remote_state.s3.s3_cloudinit_bucket}"
  key = "${var.cluster_name}-etcd/cloud-config.yaml"
  content = "${data.template_file.etcd_cloud_config.rendered}"
  #etag = "${md5(file("./artifacts/cloud-config.yaml.tmpl"))}"
}

data "template_file" "etcd_cloud_config" {
    template = "${file("./artifacts/cloud-config.yaml.tmpl")}"
    vars {
      "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
      "AWS_USER" = "${data.terraform_remote_state.iam.deployment_user}"
      "AWS_ACCESS_KEY_ID" = 
          "${data.terraform_remote_state.iam.deployment_key_id}"
      "AWS_SECRET_ACCESS_KEY" = 
          "${data.terraform_remote_state.iam.deployment_key_secret}"
      "AWS_DEFAULT_REGION" = "${var.aws_account["default_region"]}"
      "CLUSTER_NAME" = "${var.cluster_name}"
      "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
      "APP_REPOSITORY" = "${var.app_repository}"
      "GIT_SSH_COMMAND" = "\"${var.git_ssh_command}\""
      "VAULT_RELEASE" = "${var.vault_release}"
      "MODULE_NAME" = "${var.module_name}"
      "CLUSTER_NAME" = "${var.cluster_name}"     
      "ROUTE53_ZONE_NAME" = "${var.route53_zone_name}"
    }
}