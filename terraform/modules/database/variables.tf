variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "database_subnet_ids" {
  type = list(string)
}
variable "database_security_group_id" {
  type = string
}
variable "instance_class" {
  type = string
}
variable "admin_username" {
  type = string
}
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
