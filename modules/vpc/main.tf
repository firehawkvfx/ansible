provider "aws" {
  #  if you haven't installed and configured the aws cli, you will need to provide your aws access key and secret key.
  #  access_key = "${var.aws_access_key}"
  #  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

module "vpc" {
  source     = "terraform-aws-modules/vpc/aws"
  create_vpc = true

  name = "firehawk-compute"
  cidr = "${var.vpc_cidr}"

  azs             = "${var.azs}"
  private_subnets = "${var.private_subnets}"
  public_subnets  = "${var.public_subnets}"

  # if sleep is true, then nat is disabled to save costs during idle time.
  enable_nat_gateway     = "${(var.sleep || !var.enable_nat_gateway) ? false : true}"
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  #not sure if this is actually required - it seems mroe realted to aws type vpn gateway as a paid service
  #enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "vpn" {
  source = "../vpn"

  #create_openvpn = "${var.create_openvpn}"

  vpc_id   = "${module.vpc.vpc_id}"
  vpc_cidr = "${module.vpc.vpc_cidr_block}"
  #the cidr range that the vpn will assign to remote addresses within the vpc if routing.
  vpn_cidr = "${var.vpn_cidr}"
  #the remote public address that will connect to the openvpn instance
  remote_vpn_ip_cidr = "${var.remote_ip_cidr}"
  public_subnet_ids  = "${module.vpc.public_subnets}"
  #a provided route 53 zone id will be modified to have a subdomain to access vpn.  you will need to manually setup a route 53 zone for a domain with an ssl certificate.
  route_zone_id      = "${var.route_zone_id}"
  key_name           = "${var.key_name}"
  private_key        = "${file("${var.local_key_path}")}"
  local_key_path     = "${var.local_key_path}"
  cert_arn           = "${var.cert_arn}"
  public_domain_name = "${var.public_domain_name}"
  openvpn_user       = "${var.openvpn_user}"
  openvpn_admin_user = "${var.openvpn_admin_user}"
  openvpn_admin_pw   = "${var.openvpn_admin_pw}"
  #sleep will stop instances to save cost during idle time.
  sleep = "${var.sleep}"
}

locals {
  max_subnet_length = "${length(var.private_subnets)}"
  nat_gateway_count = "${length(module.vpc.natgw_ids)}"
}

resource "aws_route_table" "openvpn" {
  count = "${length(var.private_subnets)}"

  vpc_id = "${module.vpc.vpc_id}"

  tags = "${merge(map("Name", "OpenVPN_Route"))}"
}

resource "aws_route" "private_openvpn_gateway" {
  count = "${length(var.private_subnets)}"

  route_table_id         = "${element(aws_route_table.openvpn.*.id, count.index)}"
  destination_cidr_block = "${var.vpn_cidr}"
  instance_id            = "${module.vpn.id}"

  timeouts {
    create = "5m"
  }
}
