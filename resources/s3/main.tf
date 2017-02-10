# s3 bucket for initial-cluster etcd proxy discovery
# and two-stage cloudinit user-data files
resource "aws_s3_bucket" "cloudinit" {
    bucket = "${var.aws_account["id"]}-${var.cluster_name}-cloudinit"
    acl = "private"
    force_destroy = true
    tags {
        Name = "Cloudinit"
    }
}
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

output "s3_cloudinit_bucket" { value = "${aws_s3_bucket.cloudinit.id}" }
output "s3_config_bucket" { value = "${aws_s3_bucket.config.id}" }
output "s3_vault_bucket" { value = "${aws_s3_bucket.vault-s3-backend.id}" }
output "s3_logs_bucket" { value = "${aws_s3_bucket.logs.id}" }