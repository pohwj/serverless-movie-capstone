terraform {
  backend "s3" {
    bucket         = "movies-tf-state-bucket"
    key            = "infra/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "movies_tf_state_lock"
  }
}
