# Generate CA certificate and private key

resource "tls_private_key" "ca-key" {
    algorithm = "RSA"
    rsa_bits = "2048"
}
resource "tls_self_signed_cert" "ca-cert" {
    key_algorithm = "RSA"
    private_key_pem = "${tls_private_key.ca-key.private_key_pem}"
    is_ca_certificate = true
    validity_period_hours = "${var.vault_ca_cert_ttl_hours}"

    subject {
        country = "${var.vault_ca["country"]}"
        country = "${var.vault_ca["province"]}"
        organization = "${var.vault_ca["organization"]}"
        common_name = "${var.route53_public_zone_name}"
    }

    allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "server_auth",
        "client_auth",
        "cert_signing",
    ]
}

# Save pki credentials to config bucket
resource "aws_s3_bucket_object" "ca-key" {
    bucket = "${data.terraform_remote_state.s3.s3_config_bucket}"
    depends_on = ["tls_private_key.ca-key"]
    key = "pki/ca-key.pem"
    content = "${tls_private_key.ca-key.private_key_pem}"
}

# Save deployment credentials to config bucket
# TODO: add encryption
resource "aws_s3_bucket_object" "ca-cert" {
    bucket = "${data.terraform_remote_state.s3.s3_config_bucket}"
    depends_on = ["tls_self_signed_cert.ca-cert"]
    key = "pki/ca.pem"
    content = "${tls_self_signed_cert.ca-cert.cert_pem}"
}

output "ca_key" {
  sensitive = true
  value = "${tls_private_key.ca-key.private_key_pem}"
}
output "ca_cert" {
  value = "${tls_self_signed_cert.ca-cert.cert_pem}"
}
