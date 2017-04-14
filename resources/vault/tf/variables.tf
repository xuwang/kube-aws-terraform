
variable "elb-health-check" {
    default = "HTTPS:8200/v1/sys/health"
    description = "Health check for Vault servers"
}