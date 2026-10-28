terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.70.0"
    }
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "pa-abhradip"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}
