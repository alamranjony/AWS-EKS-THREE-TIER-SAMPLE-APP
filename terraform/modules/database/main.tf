# DB subnet group scopes RDS to the dedicated database subnets only
# (see modules/network) - both private, no route to an Internet Gateway.
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.database_subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-${var.environment}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = 20
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = "appdb"
  username = var.admin_username
  password = var.admin_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.database_security_group_id]

  # This is what guarantees "database must not be publicly exposed" -
  # RDS never gets a public IP/endpoint at all when this is false and
  # the DB subnet group's subnets have no Internet Gateway route.
  publicly_accessible = false

  multi_az                = false # set true for prod - see terraform/README.md environment separation section
  backup_retention_period = 1
  skip_final_snapshot     = true # set false for prod
  deletion_protection     = false # set true for prod

  tags = var.tags

  lifecycle {
    # Password rotation should never trigger a destroy/recreate of the
    # whole instance - see docs/troubleshooting.md Q14.
    ignore_changes = [password]
  }
}

# No public-facing security group rule or publicly_accessible = true
# exists anywhere in this module - there is no public firewall surface
# to open in the first place. Access is controlled purely by the
# database security group (modules/network), which only allows 3306
# from the EKS node security group.
