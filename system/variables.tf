variable "project" {
  type        = string
  default     = "messages-system"
}

variable "ecr_repository_url" {
  type        = string
  default     = "814756984544.dkr.ecr.us-east-1.amazonaws.com/dev-messages-system-ecr-repository"
}

variable "ec2_instance_type" {
  type        = string
  default     = "t2.nano"
}

variable "ec2_ami" {
  type        = string
  default     = "ami-0360c520857e3138f"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  type = string
  default = "us-east-1a"
}

variable "ebs_volume" {
  type = number
  default = 10
}

variable "env" {
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "VPC id where the resources will be deployed. vpc_id should be set when target type is ip."
  default = "vpc-03dc75b6337a7883d"
}

variable "dynamodb_messages_table_name" {
  type        = string
  description = "Dynamodb table"
  default = "messages-history"
}