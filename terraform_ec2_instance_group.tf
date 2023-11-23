# AWS Provider Configuration
provider "aws" {
  region                   = "us-east-1" # Desired AWS region
  shared_credentials_files = ["/mnt/c/Users/aimcod.aws/credentials"] # Path to AWS credentials file
  profile                  = "default" # AWS profile name from the credentials file
}

# Variables to Define Counts and Configurations

# Number of Instances
variable "instance_count" {
  type        = number
  default     = 3
}

# Number of EBS Volumes per Instance
variable "ebs_volume_count" {
  type        = number
  default     = 3
}

# Count of Subnets
variable "subnet_count" {
  type        = number
  default     = 2
}

# List of EBS Volume Sizes
variable "ec2_ebs_volume_size" {
  type        = list(any)
  default = [
    1,
    10,
    100
  ]
}

# List of Availability Zones for EBS Volumes
variable "ec2_ebs_volume_availability_zones" {
 type         = list(any)
 default  = [
   "us-east-1a",
   "us-east-1c"
 ]
}

# List of Device Names for EBS Volumes
variable "ec2_device_names" {
  type = list(any)
  default = [
    "/dev/sdd",
    "/dev/sdc",
    "/dev/sdb"
  ]
}

# List of Tag Names for Volumes
variable "volume_tag_names" {
  type = list(any)
  default = [
    "log",
    "journal",
    "data"
  ]
}

# List of Subnet IDs
variable "subnet_ids" {
  type        = list(any)
  default = [
    "subnet-xxxxxxxx",
    "subnet-yyyyyyyy"
  ]
}

# Creates AWS Instances
resource "aws_instance" "group1" {
  count         = var.instance_count
  ami           = "ami-04cb4ca688797756f" #AL2023
  instance_type        = "t3a.large"
  key_name             = "key_name"
  subnet_id           =  var.subnet_ids[count.index % length(var.subnet_ids)]
  iam_instance_profile = "IAM_Instance_profile_name"
  vpc_security_group_ids = [
    "sg-xxxxxxxx",
    "sg-yyyyyyyy"
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
    Name            = "Instance_Name0${count.index + 1}"
    Type            = "Staging"
    Group           = "Database"
    Cluster         = "Common"

  }
  lifecycle {
    ignore_changes = [
      ebs_block_device,
    ]
  }
}

}

# Creates EBS Volumes
resource "aws_ebs_volume" "group1DB" {
  count             = var.instance_count * var.ebs_volume_count
  availability_zone = aws_instance.group1[floor(count.index / var.ebs_volume_count) % length(aws_instance.group1)].availability_zone
  type = "gp3"
  size              = var.ec2_ebs_volume_size[count.index%var.ebs_volume_count]
  
  tags = {
      Name = "instance_name0${floor (count.index / var.ebs_volume_count + 3)}_${var.volume_tag_names[count.index%var.ebs_volume_count]}"
  }
}

# Attaches EBS Volumes to Instances
resource "aws_volume_attachment" "group1_volume_attachment" {
  count         = var.instance_count * var.ebs_volume_count

  volume_id   = aws_ebs_volume.group1DB[count.index].id
  device_name = var.ec2_device_names[count.index % var.ebs_volume_count]
  instance_id = aws_instance.group1[floor(count.index / var.ebs_volume_count)].id

  lifecycle {
    ignore_changes = [
      instance_id,
    ]
  }
}
