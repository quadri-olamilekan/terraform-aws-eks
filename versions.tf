terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.32.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.13.11"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform" #replace
    }
  }
}

provider "kubernetes" {
  host                   = local.host
  cluster_ca_certificate = local.certificate
  token                  = local.token
}

provider "kubectl" {
  host                   = local.host
  cluster_ca_certificate = local.certificate
  token                  = local.token
  load_config_file       = false
  
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.project
}

locals {
  host        = aws_eks_cluster.cluster.endpoint
  certificate = base64decode(aws_eks_cluster.cluster.certificate_authority.0.data)
  token       = data.aws_eks_cluster_auth.cluster.token
}