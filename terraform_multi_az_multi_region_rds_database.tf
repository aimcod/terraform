# main.tf

provider "aws" {
  region = var.primary_region
}

resource "aws_db_instance" "primary" {
  allocated_storage    = var.allocated_storage
  max_allocated_storage= var.max_allocated_storage
  backup_retention_period = 7
  identifier           = var.db_identifier
  storage_type         = var.storage_type
  engine               = var.engine 
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  multi_az             = true
  publicly_accessible  = false
  skip_final_snapshot   = true

  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = var.subnet_group_name
 
  tags = {
    Name = var.tag_name 
  }
}

resource "aws_db_instance" "replica" {
  count               = var.replica_count  # You can adjust the count or add more replicas as needed
  replicate_source_db  = aws_db_instance.primary.arn
  backup_retention_period = 7
  instance_class       = var.instance_class
  engine               = var.engine
  engine_version       = var.engine_version
  publicly_accessible  = false
  skip_final_snapshot  = true
  identifier           = "${var.db_name}-replica-${count.index}"
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "${var.db_name}-replica-${count.index}"
  }
  depends_on    = [aws_db_instance.primary]
 

}

provider "aws" {
 alias      = "secondary_region" 
 region     = var.secondary_region
}
resource "aws_db_instance" "replica_secondary_region" {
  #provider = aws.${var.secondary_region}
  count = var.replica_count # Adjust count or add more replicas as needed
  identifier = "zabbix-replica-${var.secondary_region}-${count.index}"
  replicate_source_db = aws_db_instance.primary.arn
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class = var.instance_class
  publicly_accessible = false
  skip_final_snapshot = true
  vpc_security_group_ids = [var.secondary_region_security_group_id]

  tags = {
    Name = "${var.db_name}-replica-${var.secondary_region}-${count.index}"
  }
  depends_on    = [aws_db_instance.primary]
}
