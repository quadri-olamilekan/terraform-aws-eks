module "eks-iam-roles" {
  source  = "quadri-olamilekan/eks-iam-roles/aws"
  version = "1.0.5"
  region  = var.region
  pgp_key = var.pgp_key
}

module "eks-vpc" {
  source             = "quadri-olamilekan/eks-vpc/aws"
  version            = "1.0.2"
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
      [for i in range(length(module.eks-vpc.public)) : module.eks-vpc.public[i]],
      [for i in range(length(module.eks-vpc.private)) : module.eks-vpc.private[i]]
    ])
  }
}

resource "null_resource" "eks_kubeconfig_updater" {
  depends_on = [aws_eks_cluster.cluster]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.region} --name ${var.project}"
  }
}

resource "null_resource" "rm_aws_node" {
  depends_on = [null_resource.eks_kubeconfig_updater]

  provisioner "local-exec" {
    command = "kubectl delete daemonset -n kube-system aws-node"
  }
}

resource "null_resource" "install_calico" {
  depends_on = [null_resource.rm_aws_node]

  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico-vxlan.yaml"
  }
}


resource "null_resource" "aws_src_dst_checks" {
  depends_on = [null_resource.install_calico]

  provisioner "local-exec" {
    command = "kubectl -n kube-system set env daemonset/calico-node FELIX_AWSSRCDSTCHECK=Disable"
  }
}


resource "aws_eks_node_group" "private-nodes" {
  depends_on      = [null_resource.aws_src_dst_checks]
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "private-nodes"
  node_role_arn   = module.eks-iam-roles.node_role

  subnet_ids = [
    for i in range(length(module.eks-vpc.private)) : module.eks-vpc.private[i]
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.medium"]


  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "devops"
  }

  tags = {
    "k8s.io/cluster-autoscaler/demo"    = "owned"
    "k8s.io/cluster-autoscaler/enabled" = true
  }

}

resource "aws_eks_node_group" "public-nodes" {
  depends_on      = [null_resource.aws_src_dst_checks]
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "public-nodes"
  node_role_arn   = module.eks-iam-roles.node_role

  subnet_ids = [
    for i in range(length(module.eks-vpc.public)) : module.eks-vpc.public[i]]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.medium"]


  scaling_config {
    desired_size = 0
    max_size     = 10
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "devops"
  }

  tags = {
    "k8s.io/cluster-autoscaler/demo"    = "owned"
    "k8s.io/cluster-autoscaler/enabled" = true
  }

}