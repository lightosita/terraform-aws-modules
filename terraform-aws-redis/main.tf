# --- Locals ---
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Use caller-supplied ingress rules if provided, otherwise default to
  # VPC-only access on 6379. Computed here so var.vpc_cidr is in scope.
  redis_ingress_rules = var.redis_ingress_rules != null ? var.redis_ingress_rules : {
    redis_from_vpc = {
      description = "Allow Redis from within VPC"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }
}

# --- Subnet Group ---
# Redis must always be in private subnets - never public!
resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_prefix}-redis-subnet"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis-subnet"
  })
}

# --- Security Group ---
# Shell only — rules managed as separate resources below
resource "aws_security_group" "redis" {
  name_prefix = "${local.name_prefix}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# --- Ingress Rules ---
resource "aws_vpc_security_group_ingress_rule" "redis" {
  for_each = local.redis_ingress_rules

  security_group_id = aws_security_group.redis.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks != null ? each.value.cidr_blocks[0] : null

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis-ingress-${each.key}"
  })
}

# --- Egress Rule ---
resource "aws_vpc_security_group_egress_rule" "redis_all" {
  security_group_id = aws_security_group.redis.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis-egress-all"
  })
}

# --- ElastiCache Redis Cluster ---
resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis"
  })
}