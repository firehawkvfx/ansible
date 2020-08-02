# terraform {
#   required_providers {
#     aws = "~> 3.0"
#   }
# }

# TODO
# install lustre on nodes, packages, fstab.
# test if export back to identical path works?  why is it a different path by default?  danger? https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-fs-linked-data-repo.html
# change sync pull mode via cli.
# enable sync push events, check completion before destroy.
# tighten security groups.
# set a reasonable size for distribution over cluster.  100MB?


# fsx for lustre security group rules https://docs.aws.amazon.com/fsx/latest/LustreGuide/limit-access-security-groups.html

locals {
  name = "fsx_vpc_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  extra_tags = {
    role = "fsx"
    route = "private"
  }
}

resource "aws_security_group" "fsx_vpc" {
  count = var.fsx_storage ? 1 : 0

  name        = "fsx_vpc_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  vpc_id      = var.vpc_id
  description = "FSx security group"
  tags = merge(map("Name", format("%s", local.name)), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "all incoming traffic"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 988
    to_port     = 988
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  ingress {
    protocol    = "udp"
    from_port   = 1021
    to_port     = 1023
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "icmp"
  }

  egress {
    protocol    = "tcp"
    from_port   = 988
    to_port     = 988
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  egress {
    protocol    = "udp"
    from_port   = 1021
    to_port     = 1023
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  egress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "icmp"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

resource "aws_security_group" "fsx_vpn" {
  count = var.fsx_storage ? 1 : 0
  depends_on = [var.vpn_private_ip]

  name        = "fsx_vpn_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  vpc_id      = var.vpc_id
  description = "FSX VPN security group for remote subnet"

  tags = merge(map("Name", format("%s", local.name)), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "all incoming traffic"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 988
    to_port     = 988
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1021
    to_port     = 1023
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "icmp"
  }

  egress {
    protocol    = "tcp"
    from_port   = 988
    to_port     = 988
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  egress {
    protocol    = "tcp"
    from_port   = 1021
    to_port     = 1023
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  egress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "icmp"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}



resource "null_resource" "init_fsx" {
  count = var.fsx_storage ? 1 : 0
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/fsx/fsx_init.yaml; exit_test
EOT
  }
}

locals {
  fsx_import_path = "s3://${var.fsx_bucket_prefix}.${var.bucket_extension}"
}

resource "aws_fsx_lustre_file_system" "fsx_storage" {
  count = var.fsx_storage ? 1 : 0
  depends_on = [ null_resource.init_fsx ]
  
  import_path      = local.fsx_import_path
  storage_capacity = var.fsx_storage_capacity
  subnet_ids       = var.subnet_ids
  security_group_ids = concat( aws_security_group.fsx_vpc.*.id, aws_security_group.fsx_vpn.*.id, list("") )
  # deployment_type  = "SCRATCH_2" # aws provider v3.0 only

  tags = var.common_tags
}

output "id" {
  value = element( concat( aws_fsx_lustre_file_system.fsx_storage.*.id, list("") ), 0)
}

output "network_interface_ids" {
  value = aws_fsx_lustre_file_system.fsx_storage.*.network_interface_ids
}

data "external" "primary_interface_id" { # Terraform provider API does list the primary interface in the correct order to obtain it.  so we use a custom data source to aquire the primary interface
  program = ["/bin/bash", "${path.module}/primary_interface.sh"]

  query = { # arbitrary map from strings to strings, passed to the external program as the data query.
    id = "${element( concat( aws_fsx_lustre_file_system.fsx_storage.*.id, list("") ), 0)}"
  }
}

locals {
  primary_interface = data.external.primary_interface_id.result["primary_interface"]
}

output "primary_interface" {
  value = local.primary_interface
}

data "aws_network_interface" "fsx_primary_interface" {
  count = var.fsx_storage ? 1 : 0

  id = local.primary_interface
}

output "fsx_private_ip" {
  value = element( concat( data.aws_network_interface.fsx_primary_interface.*.private_ip, list("") ), 0 )
}