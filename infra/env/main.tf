terraform {
  required_version = "= 1.1.3"
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      course      = "building-modern-java-applications-on-aws"
      application = "dragons-app"
    }
  }

}

module "dragons-app" {
  source = "../modules/dragons-app"
}

output "dragons-app-url" {
  value       = module.dragons-app
  description = "The url where dragons app is hosted"
}
