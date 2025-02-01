# Data source for AWS Account ID
data "aws_caller_identity" "current" {}

# Locals to derive the OIDC Provider ARN
locals {
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
}

# IAM Role for Karpenter Controller (IRSA)
data "aws_iam_policy_document" "karpenter_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  name               = "${var.cluster_name}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role and Instance Profile for Karpenter-launched Nodes
data "aws_iam_policy_document" "karpenter_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_node" {
  name               = "${var.cluster_name}-karpenter-node"
  assume_role_policy = data.aws_iam_policy_document.karpenter_instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policy1" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policy2" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policy3" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "${var.cluster_name}-karpenter-node-profile"
  role = aws_iam_role.karpenter_node.name
}
