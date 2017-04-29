resource "aws_route53_zone" "public" {
    name = "${var.route53_zone_name}"

    tags {
        Name = "${var.route53_zone_name}"
    }
}
output "route53_public_zone_id"  { value = "${aws_route53_zone.public.id}" }
