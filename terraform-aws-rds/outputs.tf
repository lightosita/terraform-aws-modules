
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
# (Shared with EKS and EC2 so they can access the database)

output "security_group_id" {
  description = "Security group ID for the RDS instance"
  value       = aws_security_group.rds.id
}