# --- Locals (Reusable computed names) ---
# DRY principle - define once, use everywhere
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- Get Latest Amazon Linux 2023 AMI ---
# Only fetches if no AMI ID is provided - dynamic and always up to date
data "aws_ami" "amazon_linux" {
  count       = var.ami_id == "" ? 1 : 0
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

# --- AMI Selection ---
# Uses provided AMI ID or falls back to latest Amazon Linux 2023
locals {
  ami = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux[0].id
}

# --- Security Group (EC2 Firewall) ---
# Controls who can talk to the EC2 instances
resource "aws_security_group" "ec2" {
  name_prefix = "${local.name_prefix}-ec2-"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic from anywhere
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH for direct server access
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "${local.name_prefix}-ec2-sg"
  })

  # Create new before destroying old - zero downtime
  lifecycle {
    create_before_destroy = true
  }
}

# --- Launch Template ---
# Blueprint for every EC2 instance the ASG creates
resource "aws_launch_template" "this" {
  name_prefix   = "${local.name_prefix}-web-"
  image_id      = local.ami
  instance_type = var.instance_type

  # Only attach key pair if provided
  key_name = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.ec2.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${local.name_prefix}-web"
    })
  }

  # --- User Data (Startup Script) ---
  # Runs automatically when each server starts
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
# Automatically manages the number of EC2 instances based on demand
resource "aws_autoscaling_group" "this" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  # Always use latest version of launch template
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # Tag every instance the ASG creates
  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-web"
    propagate_at_launch = true
  }

  # Dynamically apply all extra tags to instances
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}