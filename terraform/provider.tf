terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote backend for state storage + locking.
  # This S3 bucket must be created ONE TIME manually (or via a bootstrap
  # script) BEFORE running `terraform init`, since Terraform can't create
  # the backend it depends on:
  #
  #   aws s3api create-bucket --bucket devops-assessment-tfstate-<uniquesuffix> \
  #     --region us-east-1
  #   aws s3api put-bucket-versioning --bucket devops-assessment-tfstate-<uniquesuffix> \
  #     --versioning-configuration Status=Enabled
  #   aws s3api put-bucket-encryption --bucket devops-assessment-tfstate-<uniquesuffix> \
  #     --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  backend "s3" {
    bucket       = "logicmatrix-tfstate" # must be globally unique - replace before use
    key          = "devops.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true #S3 native locking
    
  }
}

provider "aws" {
  region = "ap-southeast-1"
}
