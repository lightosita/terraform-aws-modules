# --- Redis Primary Endpoint ---
output "endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

# --- Redis Port ---
output "port" {
  description = "Redis port"
  value       = aws_elasticache_cluster.this.port
}

# --- Redis Connection String ---
# Ready-to-use string for app config — avoids assembling it in the root module
output "connection_string" {
  description = "Redis connection string in redis://host:port format"
  value       = "redis://${aws_elasticache_cluster.this.cache_nodes[0].address}:${aws_elasticache_cluster.this.port}"
}

# --- Security Group ID ---
output "security_group_id" {
  description = "Security group ID for the Redis cluster"
  value       = aws_security_group.redis.id
}

# --- Ingress Rule IDs ---
# Mirrors the for_each in main.tf — keyed by rule name
output "ingress_rule_ids" {
  description = "Map of Redis ingress rule IDs keyed by rule name"
  value       = { for k, v in aws_vpc_security_group_ingress_rule.redis : k => v.id }
}

# --- Cluster ID ---
# Referenced by monitoring, parameter group changes, and snapshot policies
output "cluster_id" {
  description = "ElastiCache cluster ID"
  value       = aws_elasticache_cluster.this.cluster_id
}

# --- Engine Version ---
# Useful for downstream modules or pipelines that need to verify compatibility
output "engine_version" {
  description = "Redis engine version in use"
  value       = aws_elasticache_cluster.this.engine_version
}

# --- Subnet Group Name ---
# Referenced when adding read replicas or a replication group later
output "subnet_group_name" {
  description = "ElastiCache subnet group name"
  value       = aws_elasticache_subnet_group.this.name
}