# --- Locals ---
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Resolve AMI: prefer explicit var, fall back to data source
  # for_each on the data source uses a set — stable, no index shifting
  ami = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux["latest"].id

  # Resource types to tag in the launch template
  tag_resource_types = toset(["instance", "volume"])
}

# --- Get Latest Amazon Linux 2023 AMI ---
# for_each with a single-item set is preferred over count = 0/1
# because it avoids index-based references like [0] which break on plan/apply
data "aws_ami" "amazon_linux" {
  for_each    = var.ami_id == "" ? toset(["latest"]) : toset([])
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Security Group ---
# Shell only — rules are managed as separate resources below
# This avoids the "in-place update deletes all rules" problem with inline blocks
resource "aws_security_group" "ec2" {
  name_prefix = "${local.name_prefix}-ec2-"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ec2-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# --- Ingress Rules (for_each over var.ingress_rules) ---
# Each rule is an independent resource keyed by name (e.g. "http", "ssh")
# You can add/remove a single rule without touching the security group or other rules
resource "aws_vpc_security_group_ingress_rule" "ec2" {
  for_each = var.ingress_rules

  security_group_id = aws_security_group.ec2.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks[0]

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ingress-${each.key}"
  })
}

# --- Egress Rule ---
# Single egress rule as its own resource — consistent with ingress approach
resource "aws_vpc_security_group_egress_rule" "ec2_all" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-egress-all"
  })
}

# --- Launch Template ---
resource "aws_launch_template" "this" {
  name_prefix   = "${local.name_prefix}-web-"
  image_id      = local.ami
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # for_each via dynamic block — iterate over instance/volume tag resource types
  # Makes it trivial to add "spot-instance-request", "network-interface", etc. later
  dynamic "tag_specifications" {
    for_each = local.tag_resource_types
    content {
      resource_type = tag_specifications.value
      tags = merge(var.tags, {
        Name = "${local.name_prefix}-web"
      })
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>${local.name_prefix} Web Server</h1>" > /var/www/html/index.html
  EOF
  )

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-launch-template"
  })
}

# --- Auto Scaling Group ---
resource "aws_autoscaling_group" "this" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-web"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}