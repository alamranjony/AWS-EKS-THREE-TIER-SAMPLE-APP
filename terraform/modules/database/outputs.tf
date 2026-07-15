output "db_endpoint" {
  description = "Private endpoint (host:port) - only resolvable/reachable from inside the VPC"
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Private hostname only, no port"
  value       = aws_db_instance.this.address
}

output "db_name" {
  value = aws_db_instance.this.db_name
}
