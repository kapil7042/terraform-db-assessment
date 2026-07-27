# DevOps Assessment: Terraform + Database Reliability

## Prerequisites
Git, Terraform >= 1.0, Docker Desktop, PostgreSQL client

## Quick Start
- Database: `cd database && docker-compose up -d`
- Backup: `cd scripts && ./backup.sh`
- Restore: `./restore.sh ./backups/backup_bookings_*.sql.gz`
- Terraform: `cd infra/envs/dev && terraform init -backend=false && terraform validate && terraform plan -refresh=false`

## Architecture
Internet → ALB → ECS/Fargate → RDS

## Repository
https://github.com/kapil7042/terraform-db-assessment
