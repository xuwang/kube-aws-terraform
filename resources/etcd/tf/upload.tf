# Upload CoreOS cloud-config to a s3 bucket;
# s3-cloudconfig-bootstrap script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "etcd_cloud_config" {
  bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
  key = "etcd/cloud-config.yaml"
  content = "${data.template_file.etcd_cloud_config.rendered}"
}

data "template_file" "etcd_cloud_config" {
    template = "${file("${var.artifacts_dir}/cloud-config.yaml.tmpl")}"
    vars {
      "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
      "AWS_DEFAULT_REGION" = "${var.aws_account["default_region"]}"
      "CLUSTER_NAME" = "${var.cluster_name}"
      "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
      "CONFIG_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
      "APP_REPOSITORY" = "${var.app_repository}"
      "VAULT_RELEASE" = "${var.vault_release}"
      "MODULE_NAME" = "${var.module_name}"
      "CLUSTER_NAME" = "${var.cluster_name}"
      "ROUTE53_ZONE_NAME" = "${var.route53_zone_name}"
    }
}
