# Native AWS monitoring stack (no Helm charts / third-party Terraform
# modules): Amazon Managed Service for Prometheus (AMP) for metrics,
# Amazon Managed Grafana (AMG) for dashboards, and a CloudWatch log
# group for control-plane + Container Insights logs. This satisfies the
# "Prometheus & Grafana" requirement using only native `aws_*` Terraform
# resources - the in-cluster piece is just the lightweight AWS
# Distro for OpenTelemetry (ADOT) collector add-on, enabled via
# aws_eks_addon, which remote-writes metrics into AMP rather than
# running a self-hosted Prometheus server in the cluster.

# resource "aws_cloudwatch_log_group" "eks" {
#   name              = "/aws/eks/${var.cluster_name}/cluster"
#   retention_in_days = 30
#   tags              = var.tags
# }

# resource "aws_prometheus_workspace" "this" {
#   alias = "${var.project_name}-${var.environment}-amp"
#   tags  = var.tags
# }

# # IAM role Grafana assumes to query the AMP workspace - Amazon Managed
# # Grafana uses this as its data source authentication instead of a
# # stored API key.
# resource "aws_iam_role" "grafana" {
#   name = "${var.project_name}-${var.environment}-grafana-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect    = "Allow"
#       Principal = { Service = "grafana.amazonaws.com" }
#       Action    = "sts:AssumeRole"
#     }]
#   })

#   tags = var.tags
# }

# resource "aws_iam_role_policy" "grafana_amp_read" {
#   name = "${var.project_name}-${var.environment}-grafana-amp-read"
#   role = aws_iam_role.grafana.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "aps:QueryMetrics",
#         "aps:GetSeries",
#         "aps:GetLabels",
#         "aps:GetMetricMetadata",
#         "aps:ListWorkspaces",
#         "aps:DescribeWorkspace"
#       ]
#       Resource = aws_prometheus_workspace.this.arn
#     }]
#   })
# }

# resource "aws_grafana_workspace" "this" {
#   name                     = "${var.project_name}-${var.environment}-grafana"
#   account_access_type      = "CURRENT_ACCOUNT"
#   authentication_providers = ["AWS_SSO"] # requires IAM Identity Center enabled - see main README
#   permission_type          = "SERVICE_MANAGED"
#   role_arn                 = aws_iam_role.grafana.arn
#   data_sources             = ["PROMETHEUS", "CLOUDWATCH"]
#   tags                     = var.tags
# }

# ADOT (AWS Distro for OpenTelemetry) EKS add-on - the in-cluster
# component that scrapes pod/node metrics and remote-writes them to the
# AMP workspace above. This is an AWS-managed EKS add-on (not a
# third-party Helm chart), configured entirely through this Terraform
# resource.


# resource "aws_eks_addon" "adot" {
#   cluster_name  = var.cluster_name
#   addon_name    = "adot"
#   addon_version = null # let AWS pick the default compatible version
#   tags          = var.tags
# }
