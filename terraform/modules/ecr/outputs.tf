output "backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "frontend_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

# Registry URI (without the repo name suffix) - what the pipeline
# substitutes into __ECR_REPOSITORY_URI__ in the k8s manifests.
output "registry_uri" {
  value = split("/", aws_ecr_repository.backend.repository_url)[0]
}
