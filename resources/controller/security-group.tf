resource "aws_security_group" "kubernetes"  {
  name = "${var.cluster_name}-kubernetes"
  vpc_id = "${data.terraform_remote_state.vpc.cluster_vpc_id}"
  description = "${var.cluster_name} Kubernetes Security Group"
  # Hacker's note: the cloud_config has to be uploaded to s3 before instances fireup
  # but module can't have 'depends_on', so we have to make
  # this indrect dependency through security group
  #depends_on = ["aws_s3_bucket_object.etcd_cloud_config"]
  lifecycle { create_before_destroy = true }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow vpc clients to communicate
  # (https://github.com/kelseyhightower/kubernetes-the-hard-way/issues/33)
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "${var.kube_cluster_cidr}",
      "${var.kube_service_cidr}",
      #should be "${data.terraform_remote_state.vpc.cluster_vpc_cidr}"
      # see https://github.com/hashicorp/terraform/issues/12817
      "${var.vpc_prefix}.0.0/16"
      #"${data.terraform_remote_state.vpc.cluster_vpc_cidr}"
    ]
  }

  # Allow SSH from my hosts
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${split(",", var.allow_ssh_cidr)}"]
    self = true
  }

  # Allow secure api port from my hosts
  ingress {
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    cidr_blocks = ["${split(",", var.allow_ssh_cidr)}"]
    self = true
  }

  tags {
    KubernetesCluster = "${var.cluster_name}"
  }
  tags {
    Name = "${var.cluster_name}-kubernetes"
  }
}
output "security_group_kubernetes" { value = "${aws_security_group.kubernetes.id}" }
