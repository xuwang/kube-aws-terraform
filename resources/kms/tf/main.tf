module "tf_remote_state_kms_test" {
    source = "../../../modules/kms"
    kms_key_description = "${var.cluster_name} Terraform remote state test"
    kms_key_deletion_window_in_days = "7"
    kms_key_alias = "${var.cluster_name}-terraform-remote-state-test"
    kms_key_is_enabled = true
    #kms_key_policy = "${data.template_file.tf_remote_kms_key_policy.rendered}"
}

output "tf_kms_key_id" { value = "${module.tf_remote_state_kms_test.kms_key_id}" }
output "tf_kms_key_arn" { value = "${module.tf_remote_state_kms_test.kms_key_arn}" }
output "tf_kms_key_alias_arn" { value = "${module.tf_remote_state_kms_test.kms_key_alias_arn}" }

/*
data "template_file" "tf_remote_kms_key_policy" {
    template = "${file("../policies/tf_remote_kms_key_policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${data.aws_caller_identity.current.account_id}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}
*/

