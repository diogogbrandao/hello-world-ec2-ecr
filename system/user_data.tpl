#!/bin/bash
# Update packages
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Install unzip
sudo apt install unzip

# Install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Login to AWS ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

# Pull the docker image to the machine and runs it
docker pull ${ecr_repository_url}:latest
docker run -d -p 8080:8080 ${ecr_repository_url}:latest

# Add public SSH key for ubuntu user
echo -e ${public_key} >> /home/ubuntu/.ssh/authorized_keys