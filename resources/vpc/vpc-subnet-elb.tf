module "elb_subnet_0" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-elb_0"
  subnet_cidr = "${var.vpc_prefix}.3.0/26"
  subnet_az = "${data.aws_availability_zones.available.names[0]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

module "elb_subnet_1" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-elb_1"
  subnet_cidr = "${var.vpc_prefix}.3.64/26"
  subnet_az = "${data.aws_availability_zones.available.names[1]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

module "elb_subnet_2" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-elb_2"
  subnet_cidr = "${var.vpc_prefix}.3.128/26"
  subnet_az = "${data.aws_availability_zones.available.names[2]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

/*
output "elb_subnet_a_id" { value = "${module.elb_subnet_0.id}" }
output "elb_subnet_a_az" { value = "${module.elb_subnet_0.az}" }
output "elb_subnet_b_id" { value = "${module.elb_subnet_1.id}" }
output "elb_subnet_b_az" { value = "${module.elb_subnet_1.az}" }
output "elb_subnet_c_id" { value = "${module.elb_subnet_2.id}" }
output "elb_subnet_c_az" { value = "${module.elb_subnet_2.az}" }
*/

output "elb_zone_ids" {
  value = [ 
    "${module.elb_subnet_0.id}", 
    "${module.elb_subnet_1.id}", 
    "${module.elb_subnet_2.id}"
    ]
}
output "elb_zone_names" {
  value = [ 
    "${module.elb_subnet_0.az}", 
    "${module.elb_subnet_1.az}", 
    "${module.elb_subnet_2.az}"
    ]
}