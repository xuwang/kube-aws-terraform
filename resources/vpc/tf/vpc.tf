
resource "aws_vpc" "cluster_vpc" {
    cidr_block = "${var.vpc_prefix}.0.0/16"

    enable_dns_support = true
    enable_dns_hostnames = true
    lifecycle {
        ignore_changes = ["tags"]
    }

    tags {
         KubernetesCluster = "${var.cluster_name}"
    }
    tags {
        Name = "${var.cluster_name}"
    }
    tags {
        Modified = "${var.timestamp}-terraform"
    }
}

resource "aws_internet_gateway" "cluster_vpc" {
    vpc_id = "${aws_vpc.cluster_vpc.id}"

    tags {
         KubernetesCluster = "${var.cluster_name}"
    }
    tags {
        Name = "${var.cluster_name}"
    }
}

resource "aws_route_table" "cluster_vpc" {
    vpc_id = "${aws_vpc.cluster_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.cluster_vpc.id}"
    }

    # Ignore routing table changes because we will add Kubernetes PodCIDR routing outside of Terraform
    lifecycle {
        ignore_changes = ["route"]
    }

    tags {
         KubernetesCluster = "${var.cluster_name}"
    }
    tags {
        Name = "${var.cluster_name}"
    }
}

resource "aws_vpc_dhcp_options" "cluster_dhcp" {
    domain_name = "${var.aws_account["default_region"] == "us-east-1" ? "ec2.internal" :
          "${var.aws_account["default_region"]}.compute.internal" }"
    domain_name_servers = ["AmazonProvidedDNS"]

    tags {
         KubernetesCluster = "${var.cluster_name}"
    }
    tags {
        Name = "${var.cluster_name}"
    }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
    vpc_id = "${aws_vpc.cluster_vpc.id}"
    dhcp_options_id = "${aws_vpc_dhcp_options.cluster_dhcp.id}"
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id = "${aws_vpc.cluster_vpc.id}"
    service_name = "com.amazonaws.${var.aws_account["default_region"]}.s3"
    route_table_ids = ["${aws_route_table.cluster_vpc.id}"]
}

output "cluster_vpc_id" { value = "${aws_vpc.cluster_vpc.id}" }
output "cluster_vpc_cidr" { value = "${aws_vpc.cluster_vpc.cidr_block}" }
