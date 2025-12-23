resource "aws_security_group" "ec2_sg" {
  name        = "${var.env}-${var.project}-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = var.vpc_id

  # Inbound (Ingress) Rules
  ingress {
    description = "Allow HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_own_ip]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_own_ip]
  }

  # Outbound (Egress) Rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}