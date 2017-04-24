resource "aws_subnet" "etcd_subnet" {
    count = "${ min(var.cluster_az_max_size, length(data.aws_availability_zones.available.names))}"
    vpc_id = "${aws_vpc.cluster_vpc.id}"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    # Allow 16 etcd nodes in each subnet
    cidr_block = "${var.vpc_prefix}.2.${16 * count.index}/28"
    map_public_ip_on_launch = "true"
    tags {
         KubernetesCluster = "${var.cluster_name}"
    }
    tags {
        Name = "${var.cluster_name}-etcd-${count.index}"
    }
}

resource "aws_route_table_association" "etcd_rt" {
    count = "${ min(var.cluster_az_max_size, length(data.aws_availability_zones.available.names))}"
    subnet_id = "${aws_subnet.etcd_subnet.*.id[count.index]}"
    route_table_id = "${aws_route_table.cluster_vpc.id}"
}

output "etcd_zone_ids" {
  value = [ "${aws_subnet.etcd_subnet.*.id}" ]
}

output "etcd_zone_names" {
  value = [ "${aws_subnet.etcd_subnet.*.availability_zone}" ]
}
