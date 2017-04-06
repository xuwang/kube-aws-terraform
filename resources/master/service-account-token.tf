# Generate a shared secret for service-account-private-key-file flag
resource "tls_private_key" "service_account_private_key" {
    algorithm = "RSA"
    rsa_bits = "4096"
}

# Save token key to config bucket
resource "aws_s3_bucket_object" "service_account_private_key" {
    bucket = "${data.terraform_remote_state.s3.s3_config_bucket}"
    key = "master/service-account-private-key.pem"
    content = "${tls_private_key.service_account_private_key.private_key_pem}"
}
