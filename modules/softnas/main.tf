variable "key_name" {}

variable "vpn_private_ip" {}

variable "vpc_id" {}

variable "private_subnets" {
  default = []
}

variable "private_subnets_cidr_blocks" {
  default = []
}

variable "public_subnets_cidr_blocks" {
  default = []
}

variable "bastion_private_ip" {}

#this role should be conditionally created if it doesn't exist

resource "aws_cloudformation_stack" "SoftNASRole" {
  name         = "FCB-SoftNASRole"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-role.json"
}

resource "aws_cloudformation_stack" "SoftNASStack" {
  depends_on = ["aws_cloudformation_stack.SoftNASRole"]

  name               = "FCB-SoftNASStack"
  capabilities       = ["CAPABILITY_IAM"]
  timeout_in_minutes = "60"

  parameters = {
    KeyName             = "${var.key_name}"
    SoftnasUserPassword = "tempLogin497"
    NasType             = "m4.xlarge"
    PrivateIPEth0NAS1   = "10.0.1.11"
    PrivateIPEth1NAS1   = "10.0.1.12"

    #security groups will open access to some public facing instances via their private ips. 
    #1st is the vpn
    ADBastion1PrivateIP = "${var.vpn_private_ip}"

    #2nd is likely some other bastion / gateway that you will use to access the softnas instance.  This provides an alternative if there are issues with the vpn.
    ADBastion2PrivateIP = "${var.bastion_private_ip}"
    PrivateSubnet1CIDR  = "${var.private_subnets_cidr_blocks[0]}"
    VPCID               = "${var.vpc_id}"
    PrivateSubnet1ID    = "${var.private_subnets[0]}"
    PrivateSubnet2CIDR  = "${var.private_subnets_cidr_blocks[1]}"
    PrivateSubnet2ID    = "${var.private_subnets[1]}"
    PublicSubnet1CIDR   = "${var.public_subnets_cidr_blocks[0]}"
    PublicSubnet2CIDR   = "${var.public_subnets_cidr_blocks[1]}"
  }

  template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-1az.json"
}

output "instanceid" {
  value = "${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
}

# Attach 4 identical existing ebs volumes to the softnas instance.  if a volume has been initialised previously, it will be detected by softnas.

resource "aws_volume_attachment" "ebs_att0" {
  device_name = "/dev/sdf"
  volume_id   = "${var.volumes[0]}"
  instance_id = "${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
}

resource "aws_volume_attachment" "ebs_att1" {
  device_name = "/dev/sdg"
  volume_id   = "${var.volumes[1]}"
  instance_id = "${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
}

resource "aws_volume_attachment" "ebs_att2" {
  device_name = "/dev/sdh"
  volume_id   = "${var.volumes[2]}"
  instance_id = "${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
}

resource "aws_volume_attachment" "ebs_att3" {
  device_name = "/dev/sdi"
  volume_id   = "${var.volumes[3]}"
  instance_id = "${aws_cloudformation_stack.SoftNASStack.outputs["InstanceID"]}"
}
