# EC2-ECR HELLO WORLD

Este projeto demonstra como é possível fazer o deploy de uma AWS EC2, através do Open Tofu e do Docker, usando uma imagem armazenada no AWS ECR.

A vantagem desse método é que ele possibilita usar o poder do Docker e a diversidade de tipos instâncias EC2, evitando utilizar o AWS ECS, por ele ser mais caro e mais limitado na escolha das características de computação.

Assim, é possível utilizar o Docker na EC2 de uma maneira simples e barata. Além disso o deploy pelo Open Tofu torna o processo ainda mais fácil, pois não é preciso realizar passos manuais no console da AWS e nem executar manualmente comandos de dentro da máquina.

## Pré-requisitos

Os pré-requisitos para usar o código desse repositório são:

1. Ter o Docker Desktop instalado e rodando.
2. Ter uma conta na AWS.
3. Ter as credenciais de acesso do AWS CLI configuradas na máquina.
4. Ter uma VPC operante.
5. Ter um bucket do S3.
6. Ter uma tabela no DynamoDB.
7. Ter uma imagem de container salva em um repositório do ECR (um exemplo de imagem para testes está na pasta ec2_image). 
8. Ter o Open Tofu instalado.

## Open Tofu

Nesse projeto o Open Tofu automatiza a tarefa do deploy na AWS e foi construído um módulo interno localizado na pasta system.

As informações dos deploys do Open Tofu são guardadas no AWS S3 e no DynamoDB, possibilitando a leitura do estado atual de recursos na AWS e para _state locking_, respectivamente.

Dentro da pasta system existem variáveis que devem ser configuradas no arquivo variables.tf:

| Name                 | Type     | Default                                                                           | Description                                                                                        |
| -------------------- | -------- | --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `project`            | `string` | `messages-system`                                                                 | Nome do projeto. Usado para identificar e nomear recursos da AWS de forma padronizada.             |
| `ecr_repository_url` | `string` | `abcd.dkr.ecr.us-east-1.amazonaws.com/dev-messages-system-ecr-repository`         | URL completa do repositório Amazon ECR que contem a imagem Docker da aplicação.                    |
| `ec2_instance_type`  | `string` | `t2.nano`                                                                         | Tipo da instância EC2 onde a aplicação será executada. Define CPU e memória disponíveis.           |
| `ec2_ami`            | `string` | `ami-0360c520857e3138f`                                                           | AMI utilizada para criar a instância EC2 (ex: Amazon Linux).                                       |
| `aws_region`         | `string` | `us-east-1`                                                                       | Região da AWS onde os recursos serão provisionados.                                                |
| `availability_zone`  | `string` | `us-east-1a`                                                                      | Zona de disponibilidade onde a instância EC2 será criada.                                          |
| `ebs_volume`         | `number` | `10`                                                                              | Tamanho do volume EBS da instância EC2, em GB.                                                     |
| `env`                | `string` | `dev`                                                                             | Ambiente de implantação (ex: `dev`, `staging`, `prod`). Usado para separar e identificar recursos. |
| `vpc_id`             | `string` | `vpc-abcd`                                                                        | ID da VPC onde os recursos serão criados. Necessário quando o target type é baseado em IP.         |

Além disso, nessa mesma pasta (system), é obrigatório criar um arquivo .tf para conter mais duas variáveis:

1. public_key: chave pública para que seja possível acessar a máquina por SSH.
2. my_own_ip: o IP da sua máquina pessoal.

Dessa forma teremos nesse arquivo:

```
variable "public_key" {
    type = string
    default = ""
}

variable "my_own_ip" {
  type = string
  default = ""
}
```

Essas variáveis não devem ser armazenadas no repositório, pois elas permitem acessar a instância por SSH e isso permitiria o acesso por qualquer pessoa com posse desses dados.

## Docker

Na pasta ec2_image está a aplicação Docker que será materializada na EC2, ela contém:

1. DockerFile declarando imagem que será armazenada no ECS.
2. Arquivo requirements.txt com as bibliotecas utilizadas pelo app.

Dentro de _app_ está o código declarando, principalmente, o endpoint ping em FastAPI, conforme:

```
...
# Optional health check
@app.get("/ping")
async def ping():
    return {"status": "ok"}
...
```

Além disso, o arquivo user_data.tpl (_pasta _system_) contém os comandos que serão executados automáticamente no deploy da EC2:

```
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
```

Como é possível perceber, são executado os passos:

1. Instalação do Docker.
2. Instalação do utilitário unzip.
3. Instalação do AWS CLI v2.
4. Autenticação no Amazon ECR.
5. Login no repositório Amazon ECR usando Docker.
6. Pull da imagem Docker do ECR para a máquina (EC2).
7. Execução do container da aplicação.
8. Mapeamento da porta 8080 do container para a porta 8080 da instância EC2.
9. Configuração do acesso SSH.

## Deploy

Primeiramente, configure o arquivo "backend_config.conf", ele é essencial para o Open Tofu saber onde armazenar o estado dos recursos e do deploy.

Em exemplo de configuração é:

```
bucket = "bootstrap-my-opentofu-states-bucket"
key    = "dev/terraform.tfstate"
dynamodb_table = "bootstrap-my-opentofu-locks-table"
region = "us-east-1"
encrypt = true
```

O _path_ no s3 é determinado por bucket + key. Além disso, configure o nome da tabela do Dynamo, além da região onde encontram-se esses recursos.

Após isso conforme descrito anteriormente, declare as variáveis no arquivo variables.tf.

Dentro da pasta raíz execute o comando:

```
tofu init -backend-config=backend_config.conf
```

E, depois:

```
tofu apply
```

A EC2 e seu serviço serão criados em alguns segundos.

## Teste

Para verificar se o Sistema está disponível e respondendo normalmente, execute esse comando no seu terminal:

```
curl DNS:8080/ping
```

Substituindo o "DNS" pelo DNS da sua EC2.

Caso tudo tenha dado certo, o retorno será

```
{"status":"ok"}
```