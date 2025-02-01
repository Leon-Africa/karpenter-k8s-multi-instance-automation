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
}
