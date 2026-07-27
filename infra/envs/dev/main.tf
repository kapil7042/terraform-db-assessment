terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  access_key                  = "mock"
  secret_key                  = "mock"
}

module "network" {
  source = "../../modules/network"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = ["us-east-1a", "us-east-1b"]
}

# First create RDS security group separately
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = module.network.vpc_id

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = var.environment
  }
}

module "rds" {
  source = "../../modules/rds"

  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  sg_id              = aws_security_group.rds.id

  db_name               = "bookings"
  db_username           = var.db_username
  db_password           = var.db_password
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  backup_retention_days = var.db_backup_retention
  deletion_protection   = var.db_deletion_protection
}

# ECS module with RDS outputs
module "ecs" {
  source = "../../modules/ecs"

  environment        = var.environment
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  rds_sg_id          = aws_security_group.rds.id
  rds_endpoint       = module.rds.rds_endpoint
  container_image    = "nginx:alpine"
  container_port     = 80
  cpu                = var.ecs_cpu
  memory             = var.ecs_memory
  desired_count      = var.ecs_desired_count
}
