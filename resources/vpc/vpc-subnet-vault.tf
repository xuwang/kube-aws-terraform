module "vault_subnet_0" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-vault_0"
  subnet_cidr = "${var.vpc_prefix}.6.0/26"
  subnet_az = "${data.aws_availability_zones.available.names[0]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

output "vault_zone_ids" {
  value = [ 
    "${module.vault_subnet_0.id}"
    ]
}

output "vault_zone_names" {
  value = [ 
    "${module.vault_subnet_0.az}"
    ]
}

/* If need multi-az
module "vault_subnet_1" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-vault_1"
  subnet_cidr = "${var.vpc_prefix}.6.64/26"
  subnet_az = "${data.aws_availability_zones.available.names[1]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

module "vault_subnet_2" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-vault_2"
  subnet_cidr = "${var.vpc_prefix}.6.128/26"
  subnet_az = "${data.aws_availability_zones.available.names[2]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

output "vault_zone_ids" {
  value = [ 
    "${module.vault_subnet_0.id}", 
    "${module.vault_subnet_1.id}", 
    "${module.vault_subnet_2.id}"
    ]
}
output "vault_zone_names" {
  value = [ 
    "${module.vault_subnet_0.az}", 
    "${module.vault_subnet_1.az}", 
    "${module.vault_subnet_2.az}"
    ]
}
*/
