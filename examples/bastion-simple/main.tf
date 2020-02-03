resource "random_pet" "this" {
  length = 2
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "this" {
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "local_public_key" {}

module "bastion" {
  source = "../.."
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id = module.vpc.public_subnets[0]
  local_public_key = var.local_public_key
  bucket_name = "public-keys-${random_pet.this.id}"
}
