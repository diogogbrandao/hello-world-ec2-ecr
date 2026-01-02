# Call the 'ec2-system' as a local module
module "message_system" {
  source = "./system"
}

# --- Backend Configuration ---
# Partial backend for the top-level dev resources
terraform {
  backend "s3" {}
}

output "ec2_ip" {
  value = message_system.message_processor_ec2.public_ip
}