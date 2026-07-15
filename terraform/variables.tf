# variable "environment" {
#   description = "Deployment environment: dev, staging, or prod"
#   type        = string
#   default     = "dev"

#   validation {
#     condition     = contains(["dev", "staging", "prod"], var.environment)
#     error_message = "environment must be one of: dev, staging, prod."
#   }
# }

# variable "region" {
#   description = "AWS region"
#   type        = string
#   default     = "ap-southeast-1"
# }

# variable "tags" {
#   description = "Common tags applied to all resources"
#   type        = map(string)
#   default = {
#     project = "devops-assessment"
#   }
# }

locals {
  project = "logicmatrix"
  env     = terraform.workspace
  region  = "ap-southeast-1"
  tags = {
    project = local.project
    env     = local.env
  }
}

variable "project_name" {
  description = "Short project name used as a prefix for resource names"
  type        = string
  default     = "devopsassess"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "devops-assessment-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane and managed node group"
  type        = string
  default     = "1.33"
}

variable "node_instance_type" {
  description = "EC2 instance type for the EKS managed node group"
  type        = string
  default     = "t3.micro"
}

variable "node_count" {
  description = "Desired number of nodes in the managed node group"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Minimum nodes when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum nodes when autoscaling is enabled"
  type        = number
  default     = 3
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_admin_username" {
  description = "Administrator username for the RDS MySQL instance"
  type        = string
  default     = "dbadmin"
}

variable "db_admin_password" {
  description = "Administrator password for RDS MySQL. Pass via TF_VAR_db_admin_password env var or a pipeline secret - never commit a real value."
  type        = string
  sensitive   = true
}
