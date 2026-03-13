# --- Locals (Reusable computed names) ---
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- Subnet Group ---
# Tells ElastiCache which private subnets it can use
# Redis must always be in private subnets - never public!
resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_prefix}-redis-subnet"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis-subnet"
  })
}

# --- Security Group (Redis Firewall) ---
# Only VPC internal traffic allowed on port 6379
resource "aws_security_group" "redis" {
  name_prefix = "${local.name_prefix}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  # Allow Redis from within VPC only
  ingress {
    description = "Allow Redis from within VPC"
    from_port   = 6379
    to_port     = 6379
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
    Name = "${local.name_prefix}-redis-sg"
  })

  # Create new before destroying old - zero downtime
  lifecycle {
    create_before_destroy = true
  }
}

# --- ElastiCache Redis Cluster ---
# In-memory cache for sessions, cart data and frequently accessed data
resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = "default.redis7"
  port                 = 6379

  # --- Network & Security ---
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis"
  })
}