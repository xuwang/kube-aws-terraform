
# Upload CoreOS cloud-config to a s3 bucket; user-data-s3-bootstrap.sh in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "node_cloud_config" {
  bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
  key = "node/cloud-config.yaml"
  content = "${data.template_file.node_cloud_config.rendered}"
}
data "template_file" "node_cloud_config" {
    template = "${file("./artifacts/cloud-config.yaml.tmpl")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "CNI_PLUGIN_URL" = "${var.cni_plugin_url}"
        "KUBE_CLUSTER_CIDR" = "${var.kube_cluster_cidr}"
        "KUBE_API_SERVICE" = "${var.kube_api_service}"
        "KUBE_DNS_SERVICE" = "${var.kube_dns_service}"
        "KUBE_VERSION" = "${var.kube_version}"
    }
}

resource "aws_s3_bucket_object" "envvars" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "node/envvars"
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
        "CNI_PLUGIN_URL" = "${var.cni_plugin_url}"
        "KUBE_VERSION" = "${var.kube_version}"
        "KUBE_API_DNSNAME" = "${var.kube_api_dnsname}"
        "KUBE_API_SERVICE" = "${var.kube_api_service}"
        "VAULT_RELEASE" = "${var.vault_release}"
    }
}

# Generate /var/lib/kubelet/kubeconfig
resource "aws_s3_bucket_object" "kubeconfig" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "node/kubeconfig"
    content = "${data.template_file.kubeconfig.rendered}"
}
data "template_file" "kubeconfig" {
    template = "${file("./artifacts/upload-templates/kubeconfig")}"
    vars {
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "KUBELET_TOKEN" = "${var.kubelet_token}"
    }
}
