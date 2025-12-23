resource "aws_dynamodb_table" "whatsapp_messages" {
  name           = "${var.env}-${var.project}-wpp-dynamodb"
  billing_mode   = "PAY_PER_REQUEST" # on-demand, no capacity planning
  hash_key       = "phone_number"
  range_key      = "timestamp"

  attribute {
    name = "phone_number"
    type = "S" # string
  }

  attribute {
    name = "timestamp"
    type = "S" # ISO8601 datetime string
  }

  tags = {
    Environment = var.env
  }
}


resource "aws_dynamodb_table" "client_lifecycle" {
  name           = "${var.env}-${var.project}-client-lifecycle-dynamodb"
  billing_mode   = "PAY_PER_REQUEST" # on-demand, no capacity planning
  hash_key       = "phone_number"

  attribute {
    name = "phone_number"
    type = "S"
  }

  # Attribute for the GSI
  attribute {
    name = "client_token"
    type = "S"
  }

  # Global Secondary Index for token lookup
  global_secondary_index {
    name               = "token-index"
    hash_key           = "client_token"
    projection_type    = "ALL"
  }

  tags = {
    Environment = var.env
  }
}