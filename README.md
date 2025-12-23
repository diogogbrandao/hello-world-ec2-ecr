# EC2-ECR HELLO WORLD

Este projeto demonstra como é possível fazer o deploy de uma AWS EC2, através do Open Tofu e do Docker, e usando uma imagem armazenada no AWS ECR.

A vantagem desse método é que ele possibilita usar o poder do Docker e a diversidade de tipos instâncias EC2, evitando utilizar o AWS ECS, por ele ser mais caro e mais limitado na escolha das características de computação.

Assim, é possível utilizar o Docker na EC2 de uma maneira simples e barata. Além disso o deploy pelo Open Tofu torna o processo ainda mais fácil, pois não é preciso realizar passos manuais no console da AWS
e nem executar comandos de dentro da máquina.

## Pré-requisitos

Os pré-requisitos para usar o código desse repositório são:

1. Ter uma conta na AWS.
2. Ter uma VPC operante.
3. Ter um bucket do S3.
4. Ter uma tabela no DynamoDB.

## Open Tofu

Nesse projeto o Open Tofu automatiza a tarefa do deploy na AWS e foi construído um módulo interno localizado na pasta system.

As informações dos deploys do Open Tofu são guardadas no AWS S3 e no DynamoDB, possibilitando a leitura do estado atual de recursos na AWS e para state locking, respectivamente.

Na raiz do projeto existe o arquivo variables.tf que contém algumas variáveis importantes. Exemplos e explicação estão abaixo.

| Name                            | Type     | Default                           | Description                                                                                                                 |
| ------------------------------- | -------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `env`                           | `string` | `dev`                             | Deployment environment name (e.g., `dev`, `staging`, `prod`). Commonly used for resource naming and environment separation. |
| `aws_region`                    | `string` | `us-east-1`                       | AWS region where all resources will be deployed.                                                                            |
| `vpc_id`                        | `string` | `vpc-abcd`                        | VPC ID where resources will be created. Required when using IP-based target types.                                          |
| `opentofu_state_bucket`         | `string` | `code-opentofu-states-bucket`     | S3 bucket used to store the OpenTofu remote state file.                                                                     |
| `opentofu_state_dynamodb_table` | `string` | `codeopentofu-locks-table`        | DynamoDB table used for state locking to prevent concurrent state modifications.                                            |

Dentro da pasta system, mais variáveis devem ser configuradas no arquivo variables.tf:

| Name                 | Type     | Default                                                                           | Description                                                                                        |
| -------------------- | -------- | --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `project`            | `string` | `messages-system`                                                                 | Nome do projeto. Usado para identificar e nomear recursos da AWS de forma padronizada.             |
| `ecr_repository_url` | `string` | `abcd.dkr.ecr.us-east-1.amazonaws.com/dev-messages-system-ecr-repository`         | URL completa do repositório Amazon ECR que contém a imagem Docker da aplicação.                    |
| `ec2_instance_type`  | `string` | `t2.nano`                                                                         | Tipo da instância EC2 onde a aplicação será executada. Define CPU e memória disponíveis.           |
| `ec2_ami`            | `string` | `ami-0360c520857e3138f`                                                           | AMI utilizada para criar a instância EC2 (ex: Amazon Linux).                                       |
| `aws_region`         | `string` | `us-east-1`                                                                       | Região da AWS onde os recursos serão provisionados.                                                |
| `availability_zone`  | `string` | `us-east-1a`                                                                      | Zona de disponibilidade onde a instância EC2 será criada.                                          |
| `ebs_volume`         | `number` | `10`                                                                              | Tamanho do volume EBS da instância EC2, em GB.                                                     |
| `env`                | `string` | `dev`                                                                             | Ambiente de implantação (ex: `dev`, `staging`, `prod`). Usado para separar e identificar recursos. |
| `vpc_id`             | `string` | `vpc-abcd`                                                                        | ID da VPC onde os recursos serão criados. Necessário quando o target type é baseado em IP.         |


Além disso, na pasta system, é obrigatório criar um arquivo para conter mais duas variáveis:

1. public_key: chave pública para que seja possível acessar a máquina por SSH.
2. my_own_ip: o IP da sua máquina pessoal.

Dessa forma teremos nesse arquivo:

```hcl
variable "public_key" {
    type = string
    default = "
}

variable "my_own_ip" {
  type = string
  default = ""
}
```
Essas variáveis não devem ser armazenadas no repositório, pois elas permitem acessar a instância por SSH.

## Docker

Na pasta ec2_image está a aplicação Docker que será materializada na EC2, ela contém:

1. DockerFile declarando imagem que será armazenada no ECS.
2. Arquivo requirements.txt com as bibliotecas utilizadas pelo app.

O arquivo user_data.tpl contém:

```hcl
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

# Pull and run Docker image
docker pull ${ecr_repository_url}:latest
docker run -d -p 8080:8080 ${ecr_repository_url}:latest

# Add public SSH key for ubuntu user
echo -e ${public_key} >> /home/ubuntu/.ssh/authorized_keys
```
Como é possível perceber, são executado os passos:

1. Instalação do Docker
2. Instalação do utilitário unzip
3. Instalação do AWS CLI v2
4. Autenticação no Amazon ECR
5. Login no repositório Amazon ECR usando Docker.
6. Pull da imagem Docker da aplicação para o ECR.
7. Execução do container da aplicação
8. Mapeiamento da porta 8080 do container para a porta 8080 da instância EC2.
9. Configuração do acesso SSH




