module "eks-iam-roles" {
  source    = "quadri-olamilekan/eks-iam-roles/aws"
  version   = "1.0.5"
  region    = var.region
  admin     = var.admin
  developer = var.developer
  pgp_key   = var.pgp_key
}

module "eks-vpc" {
  source             = "quadri-olamilekan/eks-vpc/aws"
  version            = "1.0.4"
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  project            = var.project
  availability_zones = var.availability_zones
  private_cidr       = var.private_cidr
  public_cidr        = var.public_cidr
}

locals {
  vpc_id   = module.eks-vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  private_subnet_count = length([module.eks-vpc.private, module.eks-vpc.public])
  public_subnet_count = length([module.eks-vpc.private, module.eks-vpc.public])
  cluster_security_group_rules = {
    ingress_nodes_all = {
      description = "Node groups to cluster API"
      protocol    = "-1"
      from_port   = 1
      to_port     = 65535
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress_node_all = {
      description = "Cluster API to node groups"
      protocol    = "-1"
      from_port   = 1
      to_port     = 65535
      type        = "egress"
      self        = true
    }
  }

  tags = {
    "kubernetes.io/cluster/${var.project}" = "owned"
    Name                                   = "${var.project}-sg"
  }
}

# Cluster Security Group
# Defaults follow https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html

resource "aws_security_group_rule" "cluster" {
  depends_on = [aws_eks_cluster.cluster]
  for_each   = { for k, v in local.cluster_security_group_rules : k => v }

  security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type

  description = try(each.value.description, null)
  cidr_blocks = try(each.value.cidr_blocks, null)
  self        = try(each.value.self, null)

}

resource "aws_security_group" "allow_nfs" {
  depends_on  = [aws_eks_cluster.cluster]
  name        = "allow nfs for efs"
  description = "Allow NFS inbound traffic"
  vpc_id      = local.vpc_id

  # Ingress rule 1
  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  # Ingress rule 2 (to allow traffic from the security group defined in the cluster)
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_efs_file_system" "stw_node_efs_private" {
  creation_token = "${var.project}-efs-for-stw-node-private"

  tags = {
    Name = "${var.project}--file-system-private"
  }
}

resource "aws_efs_file_system" "stw_node_efs_public" {
  creation_token = "${var.project}-efs-for-stw-node-public"

  tags = {
    Name = "${var.project}--file-system-public"
  }
}

resource "aws_efs_mount_target" "stw_node_efs_mt_private" {
  count           = local.private_subnet_count
  file_system_id  = aws_efs_file_system.stw_node_efs_private.id
  subnet_id       = module.eks-vpc.private[count.index]
  security_groups = [aws_security_group.allow_nfs.id]
}

resource "aws_efs_mount_target" "stw_node_efs_mt_public" {
  count           = local.private_subnet_count
  file_system_id  = aws_efs_file_system.stw_node_efs_public.id
  subnet_id       = module.eks-vpc.public[count.index]
  security_groups = [aws_security_group.allow_nfs.id]
}

resource "aws_eks_cluster" "cluster" {
  name     = var.project
  version  = 1.29
  role_arn = module.eks-iam-roles.cluster_role

  vpc_config {
    subnet_ids = flatten([
      [for i in range(length(module.eks-vpc.public)) : module.eks-vpc.public[i]],
      [for i in range(length(module.eks-vpc.private)) : module.eks-vpc.private[i]]
    ])
  }
}

data "external" "thumbprint" {
  program = ["${path.module}/thumbprint.sh", var.region, "eks", "oidc-thumbprint", "--issuer-url", aws_eks_cluster.cluster.identity[0].oidc[0].issuer]
}

data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:eks"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "oidc" {
  depends_on         = [aws_iam_openid_connect_provider.eks]
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role_policy.json
  name               = "${var.project}-pod-oidc"
}

resource "aws_iam_policy" "oidc-policy" {
  name = "eks-oidc-policy"

  policy = jsonencode({
    Statement = [{
      Action = ["*"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "oidc_attach" {
  depends_on = [aws_iam_role.oidc]
  role       = aws_iam_role.oidc.name
  policy_arn = aws_iam_policy.oidc-policy.arn
}

resource "aws_iam_openid_connect_provider" "eks" {
  depends_on      = [aws_eks_cluster.cluster]
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumbprint.result.thumbprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}


data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_cluster_autoscaler" {
  depends_on         = [aws_iam_role.oidc]
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_autoscaler_assume_role_policy.json
  name               = "${var.project}-cluster-autoscaler"
}

resource "aws_iam_policy" "eks_cluster_autoscaler" {
  name = "${var.project}-cluster-autoscaler"

  policy = jsonencode({
    Statement = [{
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DescribeInstanceTypes"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_autoscaler_attach" {
  depends_on = [aws_iam_role.eks_cluster_autoscaler]
  role       = aws_iam_role.eks_cluster_autoscaler.name
  policy_arn = aws_iam_policy.eks_cluster_autoscaler.arn
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
    command = "kubectl apply -f ./manifests/calico-vxlan.yaml  --server=${aws_eks_cluster.cluster.endpoint}"
  }
}

resource "null_resource" "aws_src_dst_checks" {
  depends_on = [null_resource.install_calico]

  provisioner "local-exec" {
    command = "kubectl -n kube-system set env daemonset/calico-node FELIX_AWSSRCDSTCHECK=Disable  --server=${aws_eks_cluster.cluster.endpoint}"
  }
}
