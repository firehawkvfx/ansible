#variable "name" {}
# resource "aws_cloudformation_stack" "SoftNASRole" {
#   name         = "${var.cloudformation_role_stack_name}"
#   capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
#   template_url = "https://s3-ap-southeast-2.amazonaws.com/aws-softnas-cloudformation/softnas-role.json"
# }

resource "aws_iam_role" "softnas_role" {
  name = "SoftNAS_HA_IAM"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "sts:AssumeRole"
          ],
          "Principal": {
              "Service": [
                  "ec2.amazonaws.com"
              ]
          },
          "Effect": "Allow"
      }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "softnas_profile" {
  name = "SoftNAS_HA_IAM"
  role = aws_iam_role.softnas_role.name
}

resource "aws_iam_role_policy_attachment" "softnas_ssm_attach" {
  role       = aws_iam_role.softnas_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy" "softnas_policy" {
  name = "SoftNAS_HA_IAM"
  role = aws_iam_role.softnas_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "Stmt1444200186000",
          "Effect": "Allow",
          "Action": [
              "ec2:ModifyInstanceAttribute",
              "ec2:DescribeInstances",
              "ec2:CreateVolume",
              "ec2:DeleteVolume",
              "ec2:CreateSnapshot",
              "ec2:DeleteSnapshot",
              "ec2:CreateTags",
              "ec2:DeleteTags",
              "ec2:AttachVolume",
              "ec2:DetachVolume",
              "ec2:DescribeInstances",
              "ec2:DescribeVolumes",
              "ec2:DescribeSnapshots",
              "aws-marketplace:MeterUsage",
              "ec2:DescribeRouteTables",
              "ec2:DescribeAddresses",
              "ec2:DescribeTags",
              "ec2:DescribeInstances",
              "ec2:ModifyNetworkInterfaceAttribute",
              "ec2:ReplaceRoute",
              "ec2:CreateRoute",
              "ec2:DeleteRoute",
              "ec2:AssociateAddress",
              "ec2:DisassociateAddress",
              "s3:CreateBucket",
              "s3:Delete*",
              "s3:Get*",
              "s3:List*",
              "s3:Put*"
          ],
          "Resource": [
              "*"
          ]
      }
  ]
}
EOF

}

locals {
  softnas_mode_ami = "${var.softnas_mode}_${var.aws_region}"
}

resource "random_uuid" "test" {
}

resource "aws_security_group" "softnas" {
  name        = "softnas"
  vpc_id      = var.vpc_id
  description = "SoftNAS security group"

  tags = {
    Name = "softnas"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, "10.0.0.0/16", var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "all incoming traffic"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "DNS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "DNS"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "icmp"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "ssh"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.public_subnets_cidr_blocks[0], var.vpn_cidr]
    description = "https"
  }

  # ingress {
  #   protocol    = "udp"
  #   from_port   = 1194
  #   to_port     = 1194
  #   cidr_blocks = ["${var.remote_subnet_cidr}", "${var.all_private_subnets_cidr_range}", "${var.public_subnets_cidr_blocks[0]}", "${var.vpn_cidr}"]
  #   description = "from softnas default template"
  # }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "all incoming traffic from remote vpn"
  }

  ingress {
    protocol    = "udp"
    from_port   = 49152
    to_port     = 65535
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = ""
  }

  ingress {
    protocol    = "tcp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "NFS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "NFS"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [var.remote_subnet_cidr, var.all_private_subnets_cidr_range, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

resource "aws_network_interface" "nas1eth0" {
  subnet_id       = var.private_subnets[0]
  private_ips     = [var.softnas1_private_ip1]
  security_groups = [aws_security_group.softnas.id]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "nas1eth1" {
  subnet_id       = var.private_subnets[0]
  private_ips     = [var.softnas1_private_ip2]
  security_groups = [aws_security_group.softnas.id]

  tags = {
    Name = "secondary_network_interface"
  }
}

variable "softnas_use_custom_ami" {
}

variable "softnas_custom_ami" {
}

resource "aws_instance" "softnas1" {
  count = var.softnas_storage ? 1 : 0
  ami   = var.softnas_use_custom_ami ? var.softnas_custom_ami : var.selected_ami[local.softnas_mode_ami]

  instance_type = var.instance_type[var.softnas_mode]

  ebs_optimized = true

  iam_instance_profile = aws_iam_instance_profile.softnas_profile.name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nas1eth0.id
    #delete_on_termination = true
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.nas1eth1.id
    #delete_on_termination = true
  }

  root_block_device {
    volume_size = "100"
    volume_type = "gp2"

    #device_name = "/dev/sda1"
    delete_on_termination = true
    # if specifying a snapshot, do not specify encryption.
    #encryption = false
  }

  key_name = var.key_name

  #subnet_id              = "${var.private_subnets[0]}"
  #vpc_security_group_ids = ["${aws_security_group.node_centos.id}"]

  #user_data = "${file("${path.module}/user_data.yml")}"
  user_data = <<USERDATA
#cloud-config
hostname: nas1.${var.public_domain}
fqdn: nas1.${var.public_domain}
manage_etc_hosts: false
USERDATA


  tags = {
    Name  = "SoftNAS1_PlatinumConsumption${var.softnas_mode}Compute"
    Route = "private"
    Role  = "softnas"
  }
}

# When using ssd tiering, you must manually create the ebs volumes and specify the ebs id's in your secrets.  Then they can be locally restored automatically and attached to the instance.

resource "null_resource" "provision_softnas" {
  count      = var.softnas_storage ? 1 : 0
  depends_on = [aws_instance.softnas1]

  triggers = {
    instanceid = aws_instance.softnas1[0].id
  }

  # some time is required before the ecdsa key file exists.
  # some time is required before the ecdsa key file exists.
  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # sleep 300 is required because ecdsa key wont exist for a while, and you can't continue without it.
    inline = [
      "set -x",
      "sleep 300",
      "sudo yum install -y python",
      "while [ ! -f /etc/ssh/ssh_host_ecdsa_key.pub ]",
      "do",
      "  sleep 2",
      "done",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "cat /etc/ssh/ssh_host_rsa_key.pub",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "ssh-keyscan ${aws_instance.softnas1[0].private_ip}",
    ]
  }
  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.softnas1[0].private_ip} bastion_ip=${var.bastion_ip}"
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=softnas0 host_ip=${aws_instance.softnas1[0].private_ip} group_name=role_softnas"
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-init.yaml -v
      ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-init-users.yaml -v --extra-vars "variable_host=role_softnas init_ssh=false"
      # ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-update.yaml -v
      # hotfix script to speed up instance start and shutdown
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-install-acpid.yaml -v

      # cli is only needed if sync operations with s3 will be run on this instance.
      # #ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli.yaml -v --extra-vars "variable_user=centos variable_host=role_softnas"
      # #ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2.yaml -v --extra-vars "variable_user=centos variable_host=role_softnas"
  
EOT

  }
}

resource "random_id" "ami_unique_name" {
  count = var.softnas_storage ? 1 : 0
  keepers = {
    # Generate a new id each time we switch to a new instance id
    ami_id = aws_instance.softnas1[0].id
  }

  byte_length = 8
}

variable "testing" {
  default = false
}

# when testing, the local can be set to disable ami creation in a dev environment only - for faster iteration.
locals {
  testing            = var.envtier == "prod" ? false : var.testing
  create_ami_testing = local.testing ? false : true
  create_ami         = var.softnas_use_custom_ami ? false : local.create_ami_testing
}

# At this point in time, AMI's created by terraform are destroyed with terraform destroy.  we desire the ami to be persistant for faster future redeployment, so we create the ami with ansible instead.
resource "null_resource" "create_ami" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.provision_softnas,
  ]

  triggers = {
    instanceid = aws_instance.softnas1[0].id
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["set -x && echo 'booted'"]
  }
  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      # ami creation is unnecesary since softnas ami update.  will be needed in future again if softnas updates slow down deployment.
      # ansible-playbook -i "$TF_VAR_inventory" ansible/aws-ami.yaml -v --extra-vars "instance_id=${aws_instance.softnas1[0].id} ami_name=softnas_ami description=softnas1_${aws_instance.softnas1[0].id}_${random_id.ami_unique_name[0].hex}"
      # aws ec2 start-instances --instance-ids ${aws_instance.softnas1[0].id}
  
EOT

  }
}

# While instance is stopped, we attach ebs volumes.
# resource "aws_volume_attachment" "softnas1_ebs_att" {
#   depends_on         = ["aws_instance.softnas1", "null_resource.create_ami"]
#   count       = "${length(local.softnas1_volumes)}"
#   device_name = "${element(local.softnas1_mounts, count.index)}"
#   volume_id   = "${element(local.softnas1_volumes, count.index)}"
#   instance_id = "${aws_instance.softnas1.id}"
# }

# Start instance so that s3 disks can be attached
resource "null_resource" "start-softnas-after-create_ami" {
  count = local.create_ami && var.softnas_storage ? 1 : 0

  #depends_on         = ["aws_volume_attachment.softnas1_ebs_att"]
  depends_on = [
    null_resource.provision_softnas,
    null_resource.create_ami,
  ]
  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_instance.softnas1[0].id}"
  }
}

# If ebs volumes are attached, don't automatically import the pool. manual intervention may be required.
locals {
  import_pool = true
  #"${length(local.softnas1_volumes) > 0 ? false : true}"
}

# Once an AMI is built above, then we test the connection to the instance via a bastion below.
# When connection to softnas is established, we know the instance has booted.  We continue to provision an s3 extender disk below.
# this creates an s3 bucket if it doesn't already exist.  if there is a bucket with the same disk_device number, same nas name, and same domain,
# then the existing bucket will be mounted instead and existing data wil be available.  you may need to login to the softnas web ui to import the existing pool and volume,
# but the disk should be mounted correctly.
# Domains can be used to differentiate dev environments from production.
# for example, dev.example.com vs prod.example.com are different namespaces for two different buckets with otherwise identical properties to coexist in the same aws account.
# if an existing bucket is detected, s3_disk_size_max_value and encrypt_s3 are overidden by the settings on the bucket, and commandline variables ignored.
# the s3 encryption password is stored in your encrypted vault in ansible/host_vars/all/vault

# IMPORTANT: if creating a new disk, the disk_device should be the next number available to the instance.
# eg if these are already moujnted, /dev/s3-0, /dev/s3-1, /dev/s3-2, then the disk_device for the next bucket should be "3".

output "softnas1_instanceid" {
  value = aws_instance.softnas1.*.id
}

output "softnas1_private_ip" {
  value = aws_instance.softnas1.*.private_ip
}

# there is currently too much activity here, but due to the way dependencies work in tf 0.11 its better to keep it in one block.
# in tf .12 we should split these up and handle dependencies properly.
resource "null_resource" "provision_softnas_volumes" {
  count = var.softnas_storage ? 1 : 0
  depends_on = [
    null_resource.provision_softnas,
    null_resource.start-softnas-after-create_ami,
    null_resource.create_ami,
  ]

  # "null_resource.start-softnas-after-ebs-attach"
  triggers = {
    instanceid = aws_instance.softnas1[0].id
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["set -x && echo 'booted'"]
  }

  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      # ensure all old mounts onsite are removed if they exist.
      if [[ $TF_VAR_remote_mounts_on_local ]] ; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser hostname=workstation.firehawkvfx.com ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'
      fi
      # mount all ebs disks before s3
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-check-able-to-stop.yaml -v --extra-vars "instance_id=${aws_instance.softnas1[0].id}"
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk.yaml -v --extra-vars "instance_id=${aws_instance.softnas1[0].id} stop_softnas_instance=true mode=attach"
      # Although we start the instance in ansible, the aws cli can be more reliable to ensure this.
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1[0].id}
  
EOT

  }

  # connect to the instance again to ensure it has booted.
  # connect to the instance again to ensure it has booted.
  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["set -x && echo 'booted'"]
  }
  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      # ensure volumes and pools exist after disks are ensured to exist.
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-pool.yaml -v
      # ensure s3 disks exist and are mounted
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-s3-disk.yaml -v --extra-vars "pool_name=pool0 volume_name=volume0 disk_device=0 s3_disk_size_max_value=${var.s3_disk_size} encrypt_s3=true import_pool=${local.import_pool}"
      # ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-s3-disk.yaml -v --extra-vars "pool_name=pool1 volume_name=volume1 disk_device=1 s3_disk_size_max_value=${var.s3_disk_size} encrypt_s3=true import_pool=${local.import_pool}"

      # exports should be updated here.
      # if btier.json exists in /secrets/${var.envtier}/ebs-volumes/ then the tiers will be imported.
      
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-backup-btier.yaml -v --extra-vars "restore=true"
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk-update-exports.yaml -v --extra-vars "instance_id=${aws_instance.softnas1[0].id}"
  
EOT

  }
}

output "provision_softnas_volumes" {
  value = null_resource.provision_softnas_volumes.*.id
}

# todo : need to report success at correct time after it has started.  see email from steven melnikov at softnas to check how to do this.

# wakeup a node after sleep
resource "null_resource" "start-softnas" {
  count      =  !var.sleep && var.softnas_storage ? 1 : 0
  depends_on = [null_resource.provision_softnas_volumes]

  #,"null_resource.mount_volumes_onsite"]

  triggers = {
    instanceid = aws_instance.softnas1[0].id
  }

  provisioner "local-exec" {
    command = <<EOT
      # create volatile storage
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk.yaml --extra-vars "instance_id=${aws_instance.softnas1[0].id} stop_softnas_instance=true mode=attach"
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1[0].id}
  
EOT

  }
}

resource "null_resource" "shutdown-softnas" {
  count = var.sleep && var.softnas_storage ? 1 : 0

  triggers = {
    instanceid = aws_instance.softnas1[0].id
  }

  provisioner "local-exec" {
    #command = "aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.id}"

    command = <<EOT
      aws ec2 stop-instances --instance-ids ${aws_instance.softnas1[0].id}
      # delete volatile storage
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk.yaml --extra-vars "instance_id=${aws_instance.softnas1[0].id} stop_softnas_instance=true mode=destroy"
  
EOT

  }
}

resource "null_resource" "attach-local-mounts-after-start" {
  count      =  !var.sleep && var.softnas_storage ? 1 : 0
  depends_on = [null_resource.start-softnas]

  #,"null_resource.mount_volumes_onsite"]

  triggers = {
    instanceid   = aws_instance.softnas1[0].id
    startsoftnas = null_resource.start-softnas[0].id
  }
  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = [
      "set -x",
      "echo 'connection established'",
    ]
  }
  provisioner "local-exec" {
    command = <<EOT
      set -x
      echo "TF_VAR_remote_mounts_on_local= $TF_VAR_remote_mounts_on_local"
      # ensure routes on workstation exist
      if [ $TF_VAR_remote_mounts_on_local ] ; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-routes.yaml -v -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser hostname=workstation.firehawkvfx.com ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key"
      fi
      # ensure volumes and pools exist after the disks were ensured to exist - this was done before starting instance.
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-pool.yaml -v
      #ensure exports are correct
      ansible-playbook -i "$TF_VAR_inventory" ansible/softnas-ebs-disk-update-exports.yaml -v --extra-vars "instance_id=${aws_instance.softnas1[0].id}"
      # mount volumes to local site when softnas is started
      if [ $TF_VAR_remote_mounts_on_local ] ; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml -v -v --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'
      fi
      # ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml -v -v --extra-vars "variable_host=localhost variable_user=vagrant" --skip-tags 'cloud_install local_install_onsite_mounts'
  
EOT

  }
}

resource "null_resource" "detach-local-mounts-after-stop" {
  count      = var.sleep && var.softnas_storage ? 1 : 0
  depends_on = [null_resource.shutdown-softnas]

  #,"null_resource.mount_volumes_onsite"]

  triggers = {
    instanceid   = aws_instance.softnas1[0].id
    startsoftnas = null_resource.shutdown-softnas[0].id
  }
  provisioner "local-exec" {
    command = <<EOT
      set -x
      # unmount volumes from local site when softnas is shutdown.
      if [ $TF_VAR_remote_mounts_on_local ] ; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml --extra-vars "variable_host=workstation.firehawkvfx.com variable_user=deadlineuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'
      fi
      # ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-mounts.yaml --extra-vars "variable_host=localhost variable_user=vagrant destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'
  
EOT

  }
}

