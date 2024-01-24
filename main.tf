module "eks-iam-roles" {
  source  = "quadri-olamilekan/eks-iam-roles/aws"
  version = "1.0.5"
  region  = "us-east-1"
  pgp_key = ""
}

module "eks-vpc" {
  source             = "quadri-olamilekan/eks-vpc/aws"
  version            = "1.0.1"
  region             = "us-east-1"
  vpc_cidr           = "10.0.0.0/16"
  project            = "vpc_eks"
  availability_zones = ["us-east-1a", "us-east-1b"]
  private_cidr       = ["10.0.1.0/24", "10.0.2.0/24"]
  public_cidr        = ["10.0.101.0/24", "10.0.102.0/24"]
}

resource "aws_eks_cluster" "demo" {
  name     = "demo"
  role_arn = module.eks-iam-roles.cluster_role

  vpc_config {
    subnet_ids = [
      module.eks-vpc.public[0], module.eks-vpc.public[1],
      module.eks-vpc.private[0], module.eks-vpc.private[1]
    ]
  }
}