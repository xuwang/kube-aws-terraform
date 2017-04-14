# s3 bucket for application configuration, code, units etcd. Shared by all cluster nodes
resource "aws_s3_bucket" "config" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-config"
    force_destroy = true
    acl = "private"
    tags {
        Name = "Config"
    }
}

# s3 bucket for vault s3 backend
resource "aws_s3_bucket" "vault-s3-backend" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-vault-s3-backend"
    force_destroy = true
    acl = "private"
    tags {
        Name = "Vault-s3-backend"
    }
}

# s3 bucket for log data backup
resource "aws_s3_bucket" "logs" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-logs"
    force_destroy = true
    acl = "private"
    tags {
        Name = "Logs"
    }
}

output "s3_config_bucket" { value = "${aws_s3_bucket.config.id}" }
output "s3_vault_bucket" { value = "${aws_s3_bucket.vault-s3-backend.id}" }
output "s3_logs_bucket" { value = "${aws_s3_bucket.logs.id}" }
