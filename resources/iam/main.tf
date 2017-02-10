# deployment user for elb registrations, s3 access etc.

resource "aws_iam_user" "deployment" {
    name = "${var.cluster_name}-deployment"
    path = "/system/"   
}
resource "aws_iam_user_policy" "deployment" {
    name = "${aws_iam_user.deployment.name}"
    user = "${aws_iam_user.deployment.name}"
    policy = "${file("${var.artifacts_dir}/policies/deployment_policy.json")}"
}

# Save deployment credetials to config bucket
# TODO: add encryption
resource "aws_s3_bucket_object" "aws_deployment_id" {
    bucket = "${data.terraform_remote_state.s3.s3_config_bucket}"
    key = "credentials/deployment/id"
    content = "${aws_iam_access_key.deployment.id}"
}

resource "aws_s3_bucket_object" "aws_deployment_key" {
    bucket = "${data.terraform_remote_state.s3.s3_config_bucket}"
    key = "credentials/deployment/key"
    content = "${aws_iam_access_key.deployment.secret}"
}

resource "aws_iam_access_key" "deployment" {
    user = "${aws_iam_user.deployment.name}"
}

output "deployment_user" { 
    value = "${aws_iam_user.deployment.name}"
}
output "deployment_key_id" {
    sensitive = true
    value = "${aws_iam_access_key.deployment.id}"
}
output "deployment_key_secret" {
    sensitive = true
    value = "${aws_iam_access_key.deployment.secret}" 
}

output "s3_config_bucket" {
    value = "${data.terraform_remote_state.s3.s3_config_bucket}"
}
