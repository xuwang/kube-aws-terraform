resource "aws_route53_zone" "private" {
    name = "${var.cluster_internal_zone}"
    vpc_id = "${data.terraform_remote_state.vpc.cluster_vpc_id}"

    tags {
        Name = "${var.cluster_name}.local"
    }
    tags {
         KubernetesCluster = "${var.cluster_name}"
    }
}
output "route53_private_zone_id" { value = "${aws_route53_zone.private.id}" }
