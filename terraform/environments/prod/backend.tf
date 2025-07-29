terraform {
    backend "s3" {
        bucket = "fsl-terraform-state-bucket-demo"
        key = "prod/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-locks"
        encrypt = true
    }
}
