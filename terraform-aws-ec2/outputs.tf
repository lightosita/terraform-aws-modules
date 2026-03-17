# --- Security Group ID ---
# Shared with other modules that need access to EC2 instances
output "security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}

# --- Launch Template ID ---
# Referenced to create additional instances outside the ASG
output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.this.id
}

# --- Launch Template Latest Version ---
# Useful when referencing the template outside this module
output "launch_template_latest_version" {
  description = "Latest version number of the launch template"
  value       = aws_launch_template.this.latest_version
}

# --- Auto Scaling Group Name ---
# Used for monitoring and scaling policies
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

# --- Ingress Rule IDs ---
# Exposes each named ingress rule ID, keyed by rule name (e.g. "http", "ssh")
# Useful for cross-module references or debugging specific rules
output "ingress_rule_ids" {
  description = "Map of ingress rule IDs keyed by rule name"
  value       = { for k, v in aws_vpc_security_group_ingress_rule.ec2 : k => v.id }
}