resource "aws_instance" "message_processor_ec2" {
  ami                   = var.ec2_ami
  instance_type         = var.ec2_instance_type
  vpc_security_group_ids  = [aws_security_group.ec2_sg.id]
  iam_instance_profile    = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id               = data.aws_subnets.public.ids[0]
  availability_zone       = var.availability_zone
  associate_public_ip_address  = false

  tags = {
    Name = "${var.env}-${var.project}-ec2"
  }

  root_block_device {
    volume_size           = var.ebs_volume
    volume_type           = "gp2"
    encrypted             = false
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = var.ebs_volume
    volume_type           = "gp2"
    encrypted             = false
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user_data.tpl", {
    aws_region = var.aws_region
    ecr_repository_url = var.ecr_repository_url
    public_key = var.public_key
  })
}

# Create a static Elastic IP
resource "aws_eip" "web_ip" {
  domain = "vpc"
}

# Attach the Elastic IP
resource "aws_eip_association" "web_ip_assoc" {
  instance_id   = aws_instance.message_processor_ec2.id
  allocation_id = aws_eip.web_ip.id
}

# Define the IAM Role
resource "aws_iam_role" "message_processor_ec2_role" {
  name = "${var.env}-${var.project}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# Attach AWS-Managed Policy for ECR Access
resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.message_processor_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach AWS-Managed Policy for CloudWatch Logs (Optional)
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.message_processor_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Create an Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.env}-${var.project}-instance-profile"
  role = aws_iam_role.message_processor_ec2_role.name
}