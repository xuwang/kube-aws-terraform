resource "aws_subnet" "worker_subnet" {
    count = "${ min(var.cluster_az_max_size, length(data.aws_availability_zones.available.names))}"
    vpc_id = "${aws_vpc.cluster_vpc.id}"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    # Allow 255 worker nodes in each subnet
    cidr_block = "${var.vpc_prefix}.${100+count.index}.0/24"
    map_public_ip_on_launch = "true"
    tags {
         KubernetesCluster = "${var.cluster_name}"
    }
    tags {
        Name = "${var.cluster_name}-worker-${count.index}"
    }
}

resource "aws_route_table_association" "worker_rt" {
    count = "${ min(var.cluster_az_max_size, length(data.aws_availability_zones.available.names))}"
    subnet_id = "${aws_subnet.worker_subnet.*.id[count.index]}"
    route_table_id = "${aws_route_table.cluster_vpc.id}"
}

output "worker_zone_ids" {
  value = [ "${aws_subnet.worker_subnet.*.id}"]
}

output "worker_zone_names" {
  value = [ "${aws_subnet.worker_subnet.*.az}"]
}
