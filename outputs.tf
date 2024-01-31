output "cluster_endpoint" {
  value       = aws_eks_cluster.cluster.endpoint
  description = "The endpoint for the EKS cluster"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.cluster.certificate_authority.0.data
  description = "The base64-encoded certificate data required to communicate with the EKS cluster securely"
}

output "cluster_name" {
  value = aws_eks_cluster.cluster.name
  description = "Cluster name"
}

output "cluster_url" {
  value = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
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