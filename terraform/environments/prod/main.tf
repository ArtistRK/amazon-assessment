provider "aws" {
  region = "us-east-1"
}

module "static_site" {
  source      = "../../modules/static_site"
  bucket_name = "fsl-deploy-develop-prod-bucket"
  build_dir   = "../../build"
  tags = {
    Environment = "prod"
    Project     = "FSL"
  }
}
