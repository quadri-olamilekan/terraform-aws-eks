variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for subnet"
}

variable "private_cidr" {
  type        = list(string)
  description = "Private subnet cidr"
}

variable "public_cidr" {
  type        = list(string)
  description = "Public subnet cidr"
}

variable "node_group_name" {
  type        = string
  default     = "eks-node-group-nodes"
  description = "The name of the node role policy. If omitted, Terraform will assign a random, unique name."
}

variable "cluster_role_name" {
  type        = string
  default     = "eks-cluster"
  description = "The name of the cluster role policy. If omitted, Terraform will assign a random, unique name."
}

variable "pgp_key" {
  type        = string
  description = "PGP key used for encrypting user login profiles"
}


variable "developer" {
  type        = list(string)
  default     = []
  description = "List  developer users"
}

variable "admin" {
  type        = list(string)
  default     = []
  description = "List of  admin users"
}

variable "developer_eks_user_tags" {
  type        = map(string)
  default     = { Department = "developer_eks_user" }
  description = "Tags for developer EKS users"
}

variable "admin_eks_user_tags" {
  type        = map(string)
  default     = { Department = "admin_eks_user" }
  description = "Tags for admin EKS users"
}

variable "eks_developer_group" {
  type        = string
  default     = "developer"
  description = "Name of the EKS developer group"
}

variable "dev_aws_iam_group_membership_name" {
  type        = string
  default     = "dev-group-membership"
  description = "Name of the developer AWS IAM group membership"
}

variable "admin_aws_iam_group_membership_name" {
  type        = string
  default     = "masters-group-membership"
  description = "Name of the admin AWS IAM group membership"
}

variable "eks_masters_group" {
  type        = string
  default     = "masters"
  description = "Name of the EKS masters group"
}

variable "developer_actions" {
  type = list(string)
  default = [
    "eks:DescribeNodegroup",
    "eks:ListNodegroups",
    "eks:DescribeCluster",
    "eks:ListClusters",
    "eks:AccessKubernetesApi",
    "ssm:GetParameter",
    "eks:ListUpdates",
    "eks:ListFargateProfiles",
  ]
  description = "Actions permitted for developers"
}

variable "masters_iam_policy_name" {
  type        = string
  default     = "eks-admin"
  description = "Masters policy name"
}

variable "masters_iam_role_name" {
  type        = string
  default     = "admin-eks-Role"
  description = "Masters iam role name"
}

variable "pass_len" {
  type        = number
  default     = 14
  description = "length of password"
}

variable "max_pass_age" {
  type        = number
  default     = 89
  description = "maximum password age"
}

variable "pass_reuse" {
  type        = number
  default     = 24
  description = "password reuse prevention"
}

variable "low_cha" {
  type        = bool
  default     = true
  description = "require lowercase characters for password"
}

variable "num_cha" {
  type        = bool
  default     = true
  description = "require numbers for password"
}

variable "sym_cha" {
  type        = bool
  default     = true
  description = "require symbols for password"
}

variable "up_cha" {
  type        = bool
  default     = true
  description = "require uppercase characters for password"
}

variable "pass_chge" {
  type        = bool
  default     = true
  description = "allow users to change password "
}