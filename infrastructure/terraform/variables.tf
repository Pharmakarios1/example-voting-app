variable "aws_region" {
  description = "AWS region where the EKS cluster will be deployed"
  type        = string
  default     = "us-east-1"

}

variable "aws_profile" {
  description = "AWS CLI profile used by the Terraform"
  type        = string
  default     = "terraform-dev"

}

variable "Kubernetes_version" {
  description = "Kubernetes"
  type        = string
  default     = "1.34"

}
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "voting-app-eks"
}


variable "node_instance_type" {
  description = "EC2 instance type for Kubernetes worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}




variable "cluster_endpoint_public_access_cidrs" {
  description = "Public IPv4 CIDRs allowed to reach the Kubernetes API"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}