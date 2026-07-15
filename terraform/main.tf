module "resource_group" {
  source = "./modules/resource-group"

  project_name = var.project_name
  environment  = local.env
  tags         = local.tags
}

module "network" {
  source = "./modules/network"

  project_name = var.project_name
  environment  = local.env
  region       = local.region
  tags         = local.tags
  cluster_name = var.cluster_name
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = local.env
  tags         = local.tags
}

module "eks" {
  source = "./modules/eks"

  project_name                = var.project_name
  environment                 = local.env
  cluster_name                = var.cluster_name
  kubernetes_version          = var.kubernetes_version
  vpc_id                      = module.network.vpc_id
  private_subnet_ids          = module.network.private_subnet_ids
  public_subnet_ids           = module.network.public_subnet_ids
  eks_nodes_security_group_id = module.network.eks_nodes_security_group_id
  node_instance_type          = var.node_instance_type
  node_count                  = var.node_count
  node_min_count              = var.node_min_count
  node_max_count              = var.node_max_count
  ecr_repository_arns = [
    "arn:aws:ecr:${local.region}:*:repository/${var.project_name}-backend",
    "arn:aws:ecr:${local.region}:*:repository/${var.project_name}-frontend",
  ]
  tags = local.tags
}

module "database" {
  source = "./modules/database"

  project_name               = var.project_name
  environment                = local.env
  database_subnet_ids        = module.network.database_subnet_ids
  database_security_group_id = module.network.database_security_group_id
  instance_class             = var.db_instance_class
  admin_username             = var.db_admin_username
  admin_password             = var.db_admin_password
  tags                       = local.tags
}

# module "monitoring" {
#   source = "./modules/monitoring"

#   project_name = var.project_name
#   environment  = local.env
#   cluster_name = module.eks.cluster_name
#   tags         = local.tags
# }
