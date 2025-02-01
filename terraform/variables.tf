variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.32"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs (at least two)"
  type        = list(string)
}
