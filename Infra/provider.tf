terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        #do I need to put version here? 
    }
  }
}

provider "aws" {
  region = var.region 
 # profile = "terraform_user"
}