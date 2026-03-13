# --- Locals (Reusable computed names) ---

# DRY principle - define once, use everywhere
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- DB Subnet Group ---
# RDS must be in private subnets - never public!

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-rds-subnet"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-subnet"
  })
}

# --- Security Group (Database Firewall) ---
# Only VPC internal traffic allowed on port 5432

resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL from within VPC only
  ingress {
    description = "Allow PostgreSQL from within VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-sg"
  })

  # Create new before destroying old - zero downtime
  lifecycle {
    create_before_destroy = true
  }
}

# --- RDS Instance (The Actual Database) ---
# PostgreSQL 15.4 with encryption, backups and monitoring
resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-rds"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.instance_class

  # --- Storage ---
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_encrypted     = true

  # --- Database Credentials ---
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # --- Network & Security ---
  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # --- Backup & Maintenance ---

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # --- Deletion Safety ---
  skip_final_snapshot       = true
  final_snapshot_identifier = "${local.name_prefix}-rds-final"
  deletion_protection       = var.deletion_protection

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds"
  })
}