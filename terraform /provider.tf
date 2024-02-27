provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Managed_by = "Terraform"
      Project = "Zantac Inc Cloud Migration POC"
      Owner = "Deepank Verma"
    }

  }
}
