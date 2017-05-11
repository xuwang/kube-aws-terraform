#
# ELB for Kubernet API server

resource "aws_elb" "kube_apiserver_public" {
  subnets = ["${data.terraform_remote_state.vpc.elb_zone_ids}"]
  security_groups = [ "${aws_security_group.kubernetes.id}" ]

  listener {
    lb_port = 6443
    lb_protocol = "tcp"
    instance_port = 6443
    instance_protocol = "tcp"
  }
  listener {
    lb_port = 22
    lb_protocol = "tcp"
    instance_port = 22
    instance_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:6443"
    interval = 30
  }

  tags {
      Name = "${var.cluster_name}-kube-apiserver-pub"
  }
}

resource "aws_elb" "kube_apiserver_private" {
    internal = true
    subnets = ["${data.terraform_remote_state.vpc.elb_zone_ids}"]
    security_groups = [ "${aws_security_group.kubernetes.id}" ]

    listener {
      lb_port = 6443
      lb_protocol = "tcp"
      instance_port = 6443
      instance_protocol = "tcp"
    }

    health_check {
      healthy_threshold = 5
      unhealthy_threshold = 2
      timeout = 3
      target = "TCP:6443"
      interval = 30
    }

    tags {
        Name = "${var.cluster_name}-kube-apiserver-pri"
    }
}

# DNS registration
resource "aws_route53_record" "private-apiserver" {
  zone_id = "${data.terraform_remote_state.route53.route53_private_zone_id}"
  name = "api-server"
  type = "A"

  alias {
    name = "${aws_elb.kube_apiserver_private.dns_name}"
    zone_id = "${aws_elb.kube_apiserver_private.zone_id}"
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "public-apiserver" {
  zone_id = "${var.route53_public_zone_id}"
  name = "${var.kube_api_dnsname}"
  type = "A"

  alias {
    name = "${aws_elb.kube_apiserver_public.dns_name}"
    zone_id = "${aws_elb.kube_apiserver_public.zone_id}"
    evaluate_target_health = true
  }
}

output "elb_apiserver_public_id" {
    value = "${aws_elb.kube_apiserver_public.id}"
}

output "elb_kube_apiserver_public_dns_name" {
    value = "${aws_elb.kube_apiserver_public.dns_name}"
}

output "elb_apiserver_private_id" {
    value = "${aws_elb.kube_apiserver_private.id}"
}

output "elb_kube_apiserver_private_dns_name" {
    value = "${aws_elb.kube_apiserver_private.dns_name}"
}

