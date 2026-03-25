# --- Locals ---
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Default to VPC-only PostgreSQL access when no rules are supplied
  rds_ingress_rules = var.rds_ingress_rules != null ? var.rds_ingress_rules : {
    postgres_from_vpc = {
      description = "Allow PostgreSQL from within VPC"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }
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

# --- Security Group ---
# Shell only — rules managed as separate resources below
resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# --- Ingress Rules ---
resource "aws_vpc_security_group_ingress_rule" "rds" {
  for_each = local.rds_ingress_rules

  security_group_id = aws_security_group.rds.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks != null ? each.value.cidr_blocks[0] : null

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-ingress-${each.key}"
  })
}

# --- Egress Rule ---
resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-egress-all"
  })
}

# --- RDS Instance ---
# PostgreSQL 15.4 with encryption, backups and monitoring
resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-rds"
  engine         = "postgres"
  engine_version = "15.10"
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