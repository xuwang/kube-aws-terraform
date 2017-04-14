/*
data "template_file" "kubernetes_policy_json" {
    template = "${file("${var.artifacts_dir}/policies/kubernetes_policy.json")}"
    vars {
        "AWS_ACCOUNT" = "${var.aws_account["id"]}"
        "CLUSTER_NAME" = "${var.cluster_name}"
    }
}
*/
