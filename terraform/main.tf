module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 18.0"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id

  # Use the correct attribute name for subnets
  subnet_ids = var.subnets

  # Do not specify managed node group settings if you don't need them.
  # This module version will not create any node groups unless you define them.
  
  enable_irsa = true

  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  cluster_security_group_additional_rules = {
    ingress_nodes_karpenter_ports_tcp = {
      description                = "Karpenter readiness"
      protocol                   = "tcp"
      from_port                  = 8443
      to_port                    = 8443
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    ingress_allow_alb_webhook_access_from_control_plane = {
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_allow_karpenter_webhook_access_from_control_plane = {
      description                   = "Allow access from control plane to webhook port of karpenter"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
}

  # Creates a minimal node group to bootstrap Karpenter
  # Eventually removed in make automation
  eks_managed_node_groups = {
    bootstrap = {
      desired_capacity = 2
      min_size        = 1
      max_size        = 10
      instance_types  = ["m5.large"]
    }
  }
}
