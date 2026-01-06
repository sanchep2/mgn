terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Region is usually set via environment variable or CLI, 
  # but defaults to us-east-1 if not specified
  region = "us-east-2" 
  profile = "wrk"
}
