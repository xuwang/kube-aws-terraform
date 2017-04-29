data "aws_caller_identity" "current" { }

variable "cluster_internal_zone" {
    default = "cluster.internal"
}

variable "module_name" {
    default = "undefined"
}

variable "route53_zone_name" {
    default = "example.com"
}
