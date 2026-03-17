# --- Locals ---
locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"
}

# ============================================================
# CLUSTER IAM
# ============================================================

resource "aws_iam_role" "cluster" {
  name = "${local.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = var.tags
}

# for_each replaces two hardcoded aws_iam_role_policy_attachment blocks
# Adding a new policy = one new map entry in var.cluster_iam_policies, nothing else
resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = var.cluster_iam_policies

  policy_arn = each.value
  role       = aws_iam_role.cluster.name
}

# ============================================================
# CLUSTER SECURITY GROUP
# ============================================================

resource "aws_security_group" "cluster" {
  name_prefix = "${local.name_prefix}-eks-cluster-"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eks-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Each ingress rule is an independent resource keyed by name
# Changing "https" rule won't affect any other rule or the SG itself
resource "aws_vpc_security_group_ingress_rule" "cluster" {
  for_each = var.cluster_ingress_rules

  security_group_id = aws_security_group.cluster.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks != null ? each.value.cidr_blocks[0] : null

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cluster-ingress-${each.key}"
  })
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cluster-egress-all"
  })
}

# ============================================================
# EKS CLUSTER
# ============================================================

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = merge(var.tags, {
    Name = local.cluster_name
  })

  # Wait for ALL cluster policy attachments (for_each map) to complete
  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# ============================================================
# NODE IAM
# ============================================================

resource "aws_iam_role" "node" {
  name = "${local.name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

# for_each replaces three hardcoded aws_iam_role_policy_attachment blocks
# Add SSM, CloudWatch, or custom policies via var.node_iam_policies alone
resource "aws_iam_role_policy_attachment" "node" {
  for_each = var.node_iam_policies

  policy_arn = each.value
  role       = aws_iam_role.node.name
}

# ============================================================
# NODE SECURITY GROUP
# ============================================================

resource "aws_security_group" "node" {
  name_prefix = "${local.name_prefix}-eks-node-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name                                          = "${local.name_prefix}-eks-node-sg"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Control plane → nodes (source = cluster SG, not a cidr_blocks rule)
resource "aws_vpc_security_group_ingress_rule" "node_from_cluster" {
  security_group_id            = aws_security_group.node.id
  description                  = "Allow traffic from cluster control plane"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.cluster.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-node-ingress-from-cluster"
  })
}

# Node-to-node (self-referencing rule stays as a standalone resource)
resource "aws_vpc_security_group_ingress_rule" "node_self" {
  security_group_id            = aws_security_group.node.id
  description                  = "Allow nodes to communicate with each other"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.node.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-node-ingress-self"
  })
}

resource "aws_vpc_security_group_egress_rule" "node_all" {
  security_group_id = aws_security_group.node.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-node-egress-all"
  })
}


# MANAGED NODE GROUP

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.name_prefix}-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-node-group"
  })

  # Wait for ALL node policy attachments (for_each map) to complete
  depends_on = [aws_iam_role_policy_attachment.node]
}

# ============================================================
# ALB SECURITY GROUP
# ============================================================

resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# for_each over var.alb_ingress_rules — add/remove ALB ports without editing resources
resource "aws_vpc_security_group_ingress_rule" "alb" {
  for_each = var.alb_ingress_rules

  security_group_id = aws_security_group.alb.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks != null ? each.value.cidr_blocks[0] : null

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb-ingress-${each.key}"
  })
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb-egress-all"
  })
}

# ============================================================
# APPLICATION LOAD BALANCER
# ============================================================

resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb"
  })
}