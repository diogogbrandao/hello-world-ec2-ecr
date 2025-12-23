variable "env" {
  description = "Deployment environment name (e.g., dev or prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC id where the resources will be deployed. vpc_id should be set when target type is ip."
  default = "vpc-03dc75b6337a7883d"
}

variable "opentofu_state_bucket" {
  description = "S3 bucket to store OpenTofu state"
  type        = string
  default     = "codecast-opentofu-states-bucket"
}

variable "opentofu_state_dynamodb_table" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "codecast-opentofu-locks-table"
}