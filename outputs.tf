output "cluster_endpoint" {
  value       = aws_eks_cluster.cluster.endpoint
  description = "The endpoint for the EKS cluster"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.cluster.certificate_authority.0.data
  description = "The base64-encoded certificate data required to communicate with the EKS cluster securely"
}

output "test_policy_arn" {
  value = aws_iam_role.oidc.arn
}

output "oidc-url" {
  value = aws_iam_openid_connect_provider.eks.url
}

output "oidc-arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "eks_cluster_autoscaler_arn" {
  value = aws_iam_role.eks_cluster_autoscaler.arn
}