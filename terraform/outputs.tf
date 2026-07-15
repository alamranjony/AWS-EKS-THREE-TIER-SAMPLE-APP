output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "registry_name" {
  description = "ECR registry URI (used by CI/CD to push images and by k8s manifests)"
  value       = module.ecr.registry_uri
}

output "backend_repository_url" {
  value = module.ecr.backend_repository_url
}

output "frontend_repository_url" {
  value = module.ecr.frontend_repository_url
}

output "network_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "database_endpoint" {
  description = "Private RDS MySQL endpoint"
  value       = module.database.db_endpoint
}

# output "grafana_url" {
#   value = module.monitoring.grafana_workspace_endpoint
# }
