terraform {
  backend "s3" {
    bucket         = "etl-job-st-file-20112023" 
    key            = "terraform.tfstate" 
    region         = "eu-central-1" 
    encrypt        = true              
    dynamodb_table = "terraform_locks"
  }
}