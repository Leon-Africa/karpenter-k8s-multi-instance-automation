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

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_1" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_2" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_3" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_4" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_5" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# SQS Queue for Karpenter Interruption Handling
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                      = "${var.cluster_name}-karpenter-interruption-queue"
  message_retention_seconds = 300
}

# IAM Policy for Interruption Queue
data "aws_iam_policy_document" "karpenter_interruption_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:ListQueues",
      "sqs:DeleteMessage"
    ]
    resources = [aws_sqs_queue.karpenter_interruption_queue.arn]
  }
}

resource "aws_iam_policy" "karpenter_interruption" {
  name   = "${var.cluster_name}-karpenter-interruption-policy"
  policy = data.aws_iam_policy_document.karpenter_interruption_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_interruption_policy_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_interruption.arn
}

# IAM Policy for Karpenter Autoscaling Permissions
data "aws_iam_policy_document" "karpenter_autoscaling_policy" {
  statement {
    actions = [
      # Existing permissions
      "iam:PassRole",
      "ec2:DescribeInstances",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeAutoScalingGroups",
      "pricing:GetProducts",                        
      "ec2:DescribeSpotPriceHistory",               
      "ec2:DescribeInstanceTypes",                  
      "ec2:DescribeRegions",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSpotInstanceRequests",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:SendMessage",
      "sqs:ListQueues",
      "sqs:GetQueueAttributes"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "karpenter_autoscaling" {
  name   = "${var.cluster_name}-karpenter-autoscaling-policy"
  policy = data.aws_iam_policy_document.karpenter_autoscaling_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_autoscaling_policy_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_autoscaling.arn
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

# IAM Role for Karpenter ServiceAccount (IRSA)
resource "aws_iam_role" "karpenter_irsa" {
  name               = "${var.cluster_name}-karpenter"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_irsa_policy_1" {
  role       = aws_iam_role.karpenter_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_irsa_policy_2" {
  role       = aws_iam_role.karpenter_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_irsa_policy_3" {
  role       = aws_iam_role.karpenter_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "karpenter_irsa_policy_4" {
  role       = aws_iam_role.karpenter_irsa.name
  policy_arn = aws_iam_policy.karpenter_autoscaling.arn
}
