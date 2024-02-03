output "cluster_endpoint" {
  value       = aws_eks_cluster.cluster.endpoint
  description = "The endpoint for the EKS cluster"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.cluster.certificate_authority.0.data
  description = "The base64-encoded certificate data required to communicate with the EKS cluster securely"
}

output "cluster_name" {
  value       = aws_eks_cluster.cluster.name
  description = "Cluster name"
}

output "cluster_url" {
  value       = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  description = "cluster url"
}

output "node_role" {
  value       = module.eks-iam-roles.node_role
  description = "The ARN of the EKS node role"
}

output "private" {
  value = module.eks-vpc.private
}

output "public" {
  value = module.eks-vpc.public

}

output "vpc_id" {
  value = module.eks-vpc.vpc_id
}

output "efs_sg" {
  value = aws_security_group.allow_nfs.id
}

output "eks-oidc_arn" {
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

output "efs_id_private" {
  value = aws_efs_file_system.stw_node_efs_private.id
}

output "efs_id_public" {
  value = aws_efs_file_system.stw_node_efs_public.id
}