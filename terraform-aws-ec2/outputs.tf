# --- Security Group ID ---
# Shared with other modules that need access to EC2 instances
output "security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}

# --- Launch Template ID ---
# referenced to create additional instances outside the ASG
output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.this.id
}

# --- Auto Scaling Group Name ---
# monitoring and scaling policies
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}