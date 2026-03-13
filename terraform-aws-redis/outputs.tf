
# --- Redis Primary Endpoint ---
# Address application uses to connect to Redis

output "endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

# --- Redis Port ---
output "port" {
  description = "Redis port"
  value       = aws_elasticache_cluster.this.port
}

# --- Security Group ID ---
# Shared with EKS and EC2 so they can access Redis
output "security_group_id" {
  description = "Security group ID for the Redis cluster"
  value       = aws_security_group.redis.id
}