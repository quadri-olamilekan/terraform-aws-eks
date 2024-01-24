module "eks-iam-roles" {
  source  = "quadri-olamilekan/eks-iam-roles/aws"
  version = "1.0.5"
  region  = var.region
  pgp_key = var.pgp_key
}

module "eks-vpc" {
  source             = "quadri-olamilekan/eks-vpc/aws"
  version            = "1.0.1"
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  project            = var.project
  availability_zones = var.availability_zones
  private_cidr       = var.private_cidr
  public_cidr        = var.public_cidr
}


resource "aws_eks_cluster" "cluster" {
  name     = var.project
  role_arn = module.eks-iam-roles.cluster_role

  vpc_config {
    subnet_ids = flatten([
      [for i in range(length(module.eks-vpc.public)): module.eks-vpc.public[i]],
      [for i in range(length(module.eks-vpc.private)): module.eks-vpc.private[i]]
    ])
  }
}


