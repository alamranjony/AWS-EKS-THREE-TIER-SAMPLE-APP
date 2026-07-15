variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "kubernetes_version" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "eks_nodes_security_group_id" {
  type = string
}
variable "node_instance_type" {
  type = string
}
variable "node_count" {
  type = number
}
variable "node_min_count" {
  type = number
}
variable "node_max_count" {
  type = number
}
variable "ecr_repository_arns" {
  description = "ECR repo ARNs the node role is allowed to pull from"
  type        = list(string)
}
variable "tags" {
  type    = map(string)
  default = {}
}
