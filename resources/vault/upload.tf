#
# Save vault configurations to s3 config bucket
#

resource "aws_s3_bucket_object" "vault-cnf" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "vault/vault.cnf"
    content = "${data.template_file.vault-cnf.rendered}"
}

resource "aws_s3_bucket_object" "vault-hcl" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "vault/vault.hcl"
    content = "${data.template_file.vault-hcl.rendered}"
}

resource "aws_s3_bucket_object" "vault-sh" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "vault/vault.sh"
    content = "${data.template_file.vault-sh.rendered}"
}

resource "aws_s3_bucket_object" "envvars" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    key = "vault/envvars"
    content = "${data.template_file.envvars.rendered}"
}

#
# Generate conf files from templates
#
data "template_file" "vault-cnf" {
    template = "${file("./artifacts/upload-templates/vault.cnf")}"
    vars {
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
    }
}

data "template_file" "vault-hcl" {
    template = "${file("./artifacts/upload-templates/vault.hcl")}"
    vars {
        "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
        "AWS_DEFAULT_REGION" = "${var.aws_account["default_region"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}

data "template_file" "vault-sh" {
    template = "${file("./artifacts/upload-templates/vault.sh")}"
    vars {
        "ROUTE53_ZONE_NAME" = "${var.route53_zone_name}"
        "CLUSTER_NAME" = "${var.cluster_name}"
        "CLUSTER_INTERNAL_ZONE" = "${var.cluster_internal_zone}"
        "VAULT_AUTO_UNSEAL" = "${var.vault_auto_unseal}"
        "VAULT_ROOTCA_CN" = "${var.vault_rootca_cn}"
        "VAULT_TOKEN_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
    }
}

data "template_file" "vault-sh" {
    template = "${file("./artifacts/upload-templates/vault.sh")}"
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
        "VAULT_AUTO_UNSEAL" = "${var.vault_auto_unseal}"
        "VAULT_ROOTCA_CN" = "${var.vault_rootca_cn}"
        "ROUTE53_ZONE_NAME" = "${var.route53_zone_name}"
        "MODULE_NAME" = "${var.module_name}"
        "VAULT_TOKEN_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
    }
}
data "template_file" "envvars" {
    template = "${file("./artifacts/upload-templates/envvars")}"
    vars {
        "VAULT_RELEASE" = "${var.vault_release}"
    }
}

data "template_file" "vault-sh" {
    template = "${file("./artifacts/upload-templates/vault.sh")}"
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
        "VAULT_AUTO_UNSEAL" = "${var.vault_auto_unseal}"
        "VAULT_ROOTCA_CN" = "${var.vault_rootca_cn}"
        "ROUTE53_ZONE_NAME" = "${var.route53_zone_name}"
        "MODULE_NAME" = "${var.module_name}"
        "VAULT_TOKEN_BUCKET" = "${var.aws_account["id"]}-${var.cluster_name}-config"
    }
}
