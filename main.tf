# Call the 'ec2-system' as a local module
module "message_system" {
  source = "./system"
}

# --- Backend Configuration ---
# Partial backend for the top-level dev resources
terraform {
  backend "s3" {}
}