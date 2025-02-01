output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

output "karpenter_controller_role_arn" {
  description = "IAM Role ARN for Karpenter Controller"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_node_instance_profile" {
  description = "Instance profile for nodes provisioned by Karpenter"
  value       = aws_iam_instance_profile.karpenter_node_instance_profile.name
}
