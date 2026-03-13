# --- EKS Cluster Name ---
# Referenced by kubectl and other tools to identify the cluster
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

# --- Cluster API Endpoint ---
# The URL your kubectl uses to communicate with Kubernetes
output "cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

# --- Certificate Authority ---
# Security certificate that verifies you're talking to the right cluster
output "cluster_certificate_authority" {
  description = "Certificate authority data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

# --- Cluster Security Group ID ---
# Shared with other modules that need to talk to the control plane
output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = aws_security_group.cluster.id
}

# --- Node Security Group ID ---
# Shared with RDS and Redis so they can allow traffic from worker nodes
output "node_security_group_id" {
  description = "Security group ID for the EKS worker nodes"
  value       = aws_security_group.node.id
}

# --- ALB DNS Name ---
# The public web address customers use to reach your application
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

# --- ALB Security Group ID ---
# Referenced when configuring listener rules and target groups
output "alb_security_group_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}