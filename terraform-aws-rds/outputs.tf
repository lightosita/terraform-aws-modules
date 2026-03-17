# --- Connection Endpoint (hostname:port) ---
output "endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = aws_db_instance.this.endpoint
}

# --- Hostname Only ---
output "address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.this.address
}

# --- Port ---
output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

# --- Database Name ---
output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.this.db_name
}

# --- Security Group ID ---
output "security_group_id" {
  description = "Security group ID for the RDS instance"
  value       = aws_security_group.rds.id
}

# --- Ingress Rule IDs ---
# Mirrors the for_each in main.tf — keyed by rule name
output "ingress_rule_ids" {
  description = "Map of RDS ingress rule IDs keyed by rule name"
  value       = { for k, v in aws_vpc_security_group_ingress_rule.rds : k => v.id }
}

# --- DB Subnet Group Name ---
# Referenced when promoting to Multi-AZ or adding read replicas
output "subnet_group_name" {
  description = "RDS DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

# --- Instance ID ---
# Used for CloudWatch alarms, snapshots and maintenance operations
output "instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

# --- Engine Version ---
# Useful for verifying client library compatibility in CI pipelines
output "engine_version" {
  description = "PostgreSQL engine version in use"
  value       = aws_db_instance.this.engine_version
}