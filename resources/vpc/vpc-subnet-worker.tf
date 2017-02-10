module "worker_subnet_0" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-worker_0"
  subnet_cidr = "${var.vpc_prefix}.5.0/26"
  subnet_az = "${data.aws_availability_zones.available.names[0]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

module "worker_subnet_1" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-worker_1"
  subnet_cidr = "${var.vpc_prefix}.5.64/26"
  subnet_az = "${data.aws_availability_zones.available.names[1]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

module "worker_subnet_2" {
  source = "../modules/subnet"

  subnet_name = "${var.cluster_name}-worker_2"
  subnet_cidr = "${var.vpc_prefix}.5.128/26"
  subnet_az = "${data.aws_availability_zones.available.names[2]}"
  cluster_name ="${var.cluster_name}"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  route_table_id = "${aws_route_table.cluster_vpc.id}"
}

output "worker_zone_ids" {
  value = [ 
    "${module.worker_subnet_0.id}", 
    "${module.worker_subnet_1.id}", 
    "${module.worker_subnet_2.id}"
    ]
}
output "worker_zone_names" {
  value = [ 
    "${module.worker_subnet_0.az}", 
    "${module.worker_subnet_1.az}", 
    "${module.worker_subnet_2.az}"
    ]
}