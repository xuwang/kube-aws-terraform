resource "aws_subnet" "vault_subnet" {
    /* If need multi-az
    count = "${ min(var.cluster_az_max_size, length(data.aws_availability_zones.available.names))}"
    */
    count = 1
    vpc_id = "${aws_vpc.cluster_vpc.id}"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    # Allow 16 vault nodes in each subnet
    cidr_block = "${var.vpc_prefix}.1.${16 * count.index}/28"
    map_public_ip_on_launch = "true"
    tags {
         KubernetesCluster = "${var.cluster_name}"
    }
    tags {
        Name = "${var.cluster_name}-vault-${count.index}"
    }
}

resource "aws_route_table_association" "vault_rt" {
    /* If need multi-az
    count = "${ min(var.cluster_az_max_size, length(data.aws_availability_zones.available.names))}"
    */
    count = 1
    subnet_id = "${aws_subnet.vault_subnet.*.id[count.index]}"
    route_table_id = "${aws_route_table.cluster_vpc.id}"
}

output "vault_zone_ids" {
  value = [ "${aws_subnet.vault_subnet.*.id}"]
}

output "vault_zone_names" {
  value = [ "${aws_subnet.vault_subnet.*.az}"]
}
