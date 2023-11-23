provider "aws" {
  region                   = "us-east-1" # Replace with your desired AWS region
  shared_credentials_files = ["/mnt/c/Users/andrei.mihai/.aws/credentials"]
  profile                  = "DSCO"
}
variable "instance_count" {
  type        = number
  default     = 3
}
variable "ebs_volume_count" {
  type        = number
  default     = 3
}
variable "subnet_count" {
  type        = number
  default     = 2
}
variable "ec2_ebs_volume_size_common" {
  type        = list(any)
  default = [
    1,
    10,
    100
  ]
}

#variable "ec2_ebs_volume_size_catalog" {
#  type        = list(any)
#  default = [
#    1,
#    10,
#    50
#  ]
#}
#variable "ec2_ebs_volume_size_jobs" {
#  type        = list(any)
#  default = [
#    1,
#    10,
#    50
#  ]
#}

variable "ec2_ebs_volume_availability_zones" {
 type         = list(any)
 default  = [
   "us-east-1a",
   "us-east-1c"
]
}



variable "ec2_device_names" {
  type = list(any)
  default = [
    "/dev/sdd",
    "/dev/sdc",
    "/dev/sdb"
  ]
}
variable "volume_tag_names" {
  type = list(any)
  default = [
    "log",
    "journal",
    "data"
        ]
}
variable "subnet_ids" {
  type        = list(any)
 default = [
  "subnet-7a14b127",
  "subnet-48288767"
]
}

resource "aws_instance" "Common" {
  count         = var.instance_count
  ami           = "ami-04cb4ca688797756f"
  instance_type        = "t3a.large"
  key_name             = "CoreRootKey"
  subnet_id           =  var.subnet_ids[count.index % length(var.subnet_ids)]
#subnet_id            = "{element(var.subnet_ids, count.index -1)}"
  iam_instance_profile = "EC2_Instance_Role_For_SSM"
  vpc_security_group_ids = [
    "sg-57f28422", # Mongo Ports
    "sg-0a7f1842", # SSH Internal
  ]
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/xvda" #/
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }
  tags = {
    Name            = "CommonDb0${count.index + 3}"
    "chub:tech:app" = "mongodb"
    Type            = "Staging"
    Group           = "Database"
    "chub:tech:env" = "staging"
    Cluster         = "Common"

  }
  lifecycle {
    ignore_changes = [
      # Ignore changes within the ebs_block_device block
      ebs_block_device,
    ]
  }
}

resource "aws_ebs_volume" "CommonDB" {
  count             = var.instance_count * var.ebs_volume_count
  availability_zone = aws_instance.Common[floor(count.index / var.ebs_volume_count) % length(aws_instance.Common)].availability_zone
#  availability_zone = element(var.ec2_ebs_volume_availability_zones, count.index % length(var.ec2_ebs_volume_availability_zones))
  type = "gp3"
  size              = var.ec2_ebs_volume_size_common[count.index%var.ebs_volume_count]
          tags = {
      Name = "commondb0${floor (count.index / var.ebs_volume_count + 3)}_${var.volume_tag_names[count.index%var.ebs_volume_count]}"
  }
}

resource "aws_volume_attachment" "common_volume_attachment" {
  count         = var.instance_count * var.ebs_volume_count

  volume_id   = aws_ebs_volume.CommonDB[count.index].id
  device_name = var.ec2_device_names[count.index % var.ebs_volume_count]
  instance_id = aws_instance.Common[floor(count.index / var.ebs_volume_count)].id

#  volume_id     = aws_ebs_volume.CommonDB[floor(count.index / var.ebs_volume_count) % var.instance_count].id
#  device_name   = var.ec2_device_names[count.index % var.ebs_volume_count]
#  instance_id   = aws_instance.Common[floor(count.index  % var.instance_count)].id
  # Optional: You can include lifecycle configurations as needed
  lifecycle {
    ignore_changes = [
      instance_id,
    ]
  }
}
