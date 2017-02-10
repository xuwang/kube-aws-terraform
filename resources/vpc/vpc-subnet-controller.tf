module "controller_subnet_0" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-controller_0"
  subnet_cidr = "${var.vpc_prefix}.10.0/26"
  subnet_az = "${data.aws_availability_zones.available.names[0]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

module "controller_subnet_1" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-controller_1"
  subnet_cidr = "${var.vpc_prefix}.10.64/26"
  subnet_az = "${data.aws_availability_zones.available.names[1]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

module "controller_subnet_2" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-controller_2"
  subnet_cidr = "${var.vpc_prefix}.10.128/26"
  subnet_az = "${data.aws_availability_zones.available.names[2]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}


/*
output "controller_subnet_a_id" { value = "${module.controller_subnet_0.id}" }
output "controller_subnet_a_az" { value = "${module.controller_subnet_0.az}" }
output "controller_subnet_b_id" { value = "${module.controller_subnet_1.id}" }
output "controller_subnet_b_az" { value = "${module.controller_subnet_1.az}" }
output "controller_subnet_c_id" { value = "${module.controller_subnet_2.id}" }
output "controller_subnet_c_az" { value = "${module.controller_subnet_2.az}" }
*/

output "controller_zone_ids" {
  value = [ 
    "${module.controller_subnet_0.id}", 
    "${module.controller_subnet_1.id}", 
    "${module.controller_subnet_2.id}"
    ]
}
output "controller_zone_names" {
  value = [ 
    "${module.controller_subnet_0.az}", 
    "${module.controller_subnet_1.az}", 
    "${module.controller_subnet_2.az}"
    ]
}