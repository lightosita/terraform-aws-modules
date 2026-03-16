# --- VPC ID ---
# Used by all other modules to deploy into this VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

# --- VPC CIDR ---
# Used by RDS and Redis security groups to allow VPC internal traffic
output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

# --- Public Subnet IDs ---
# for_each returns a map - values() converts it to a list
# Used by EKS ALB and NAT Gateway
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = values(aws_subnet.public)[*].id
}

# --- Private Subnet IDs ---
# for_each returns a map - values() converts it to a list
# Used by EKS nodes, RDS, Redis and EC2
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = values(aws_subnet.private)[*].id
}

# --- Internet Gateway ID ---
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

# --- NAT Gateway IDs ---
# for_each returns a map - values() converts it to a list
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = values(aws_nat_gateway.this)[*].id
}