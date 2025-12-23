data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Tier = "Private"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = ["${var.aws_region}a"]
  }

  tags = {
    Tier = "Public"
  }
}

  ##alb_subnets_ids                    = data.aws_subnets.public.ids
  ##service_subnets_ids                = data.aws_subnets.private.ids