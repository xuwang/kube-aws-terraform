
# Upload CoreOS cloud-config to a s3 bucket; s3-cloudconfig-bootstrap script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "master_cloud_config" {
  bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
  key = "master/cloud-config.yaml"
  content = "${data.template_file.master_cloud_config.rendered}"
}
data "template_file" "master_cloud_config" {
    template = "${file("./artifacts/cloud-config.yaml.tmpl")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "KUBE_CLUSTER_CIDR" = "${var.kube_cluster_cidr}"
        "KUBE_SERVICE_CIDR" = "${var.kube_service_cidr}"
        "KUBE_SERVICE_NODE_PORTS" = "${var.kube_service_node_ports}"
        "KUBE_APISERVER-COUNT" = "${var.cluster_desired_capacity}"
    }
}

resource "aws_s3_bucket_object" "envvars" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "master/envvars"
    content = "${data.template_file.envvars.rendered}"
}
data "template_file" "envvars" {
    template = "${file("./artifacts/upload-templates/envvars")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "MODULE_NAME" = "${var.module_name}"
        "ROUTE53_ZONE_NAME" = "${var.route53_zone_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "KUBE_VERSION" = "${var.kube_version}"
        "KUBE_API_DNSNAME" = "${var.kube_api_dnsname}"
        "KUBE_API_SERVICE" = "${var.kube_api_service}"
        "VAULT_RELEASE" = "${var.vault_release}"
    }
}
