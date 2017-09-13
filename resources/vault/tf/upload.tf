#
# Save vault configurations to s3 config bucket
#
resource "aws_s3_bucket_object" "vault_cnf" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "vault/vault.cnf"
    content = "${data.template_file.vault_cnf.rendered}"
}
data "template_file" "vault_cnf" {
    template = "${file("${var.artifacts_dir}/upload-templates/vault.cnf")}"
    vars {
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
    }
}

resource "aws_s3_bucket_object" "vault_hcl" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "vault/vault.hcl"
    content = "${data.template_file.vault_hcl.rendered}"
}
data "template_file" "vault_hcl" {
    template = "${file("${var.artifacts_dir}/upload-templates/vault.hcl")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "AWS_DEFAULT_REGION" = "${var.aws_account["default_region"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

resource "aws_s3_bucket_object" "vault_sh" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "vault/vault.sh"
    content = "${data.template_file.vault_sh.rendered}"
}
data "template_file" "vault_sh" {
    template = "${file("${var.artifacts_dir}/upload-templates/vault.sh")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "ROUTE53_ZONE_NAME" = "${var.route53_public_zone_name}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "VAULT_AUTO_UNSEAL" = "${var.vault_auto_unseal}"
        "VAULT_ROOTCA_CN" = "${var.vault_rootca_cn}"
        "VAULT_TOKEN_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
        "CONFIG_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
    }
}

resource "aws_s3_bucket_object" "envvars" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "vault/envvars"
    content = "${data.template_file.envvars.rendered}"
}
data "template_file" "envvars" {
    template = "${file("${var.artifacts_dir}/upload-templates/envvars")}"
    vars {
        "VAULT_IMAGE" = "${var.vault_image}"
    }
}

# Upload CoreOS cloud-config to a s3 bucket; s3-cloudconfig-bootstrap script in user-data will download
# the cloud-config upon reboot to configure the system. This avoids rebuilding machines when
# changing cloud-config.
resource "aws_s3_bucket_object" "vault_cloud_config" {
  bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
  key = "vault/cloud-config.yaml"
  content = "${data.template_file.vault_cloud_config.rendered}"
}
data "template_file" "vault_cloud_config" {
    template = "${file("${var.artifacts_dir}/cloud-config.yaml.tmpl")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "AWS_DEFAULT_REGION" = "${var.aws_account["default_region"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "CONFIG_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
        "MODULE_NAME" = "${var.module_name}"
    }
}

# Create pki-tokens path to store issued pki tokens
resource "aws_s3_bucket_object" "vault_pki_tokens" {
  bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
  key = "pki-tokens/created-timestamp"
  content = "place-holder"
}
data "template_file" "vault_policy_json" {
    template = "${file("${var.artifacts_dir}/policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}
