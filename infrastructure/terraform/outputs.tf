
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.voting_app_cluster.name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.voting_app_cluster.endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version running on EKS"
  value       = aws_eks_cluster.voting_app_cluster.version
}

output "default_vpc_id" {
  description = "Default VPC used by the cluster"
  value       = data.aws_vpc.default_vpc.id
}

output "worker_node_group_name" {
  description = "Name of the managed worker node group"
  value       = aws_eks_node_group.voting_app_workers.node_group_name
}
