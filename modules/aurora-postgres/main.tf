terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = var.cluster_name
  engine                  = "aurora-postgresql"
  engine_version          = var.engine_version
  database_name           = var.db_name
  master_username         = var.master_username
  master_password         = var.master_password
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = "07:00-09:00"
  
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name
  
  storage_encrypted = true
  
  # Safe to skip final snapshot for dev/test
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = "${var.cluster_name}-final"

  tags = var.tags
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${var.cluster_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  
  publicly_accessible = var.publicly_accessible
  
  tags = var.tags
}
