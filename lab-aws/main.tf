provider "aws" {
  region = local.region
}

locals {
  name   = "aws-lab"
  region = "us-east-1"

  tags = {
    terraform = "true"
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

## Supporting Resources

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "vpc_${local.name}"
  cidr = "10.100.0.0/16"

  azs                = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets     = ["10.100.110.0/24"]
  private_subnets    = ["10.100.10.0/24", "10.100.20.0/24", "10.100.30.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = false

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "sg_${local.name}"
  description = "Lab Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  ingress_rules       = ["https-443-tcp", "ssh-tcp", "rdp-tcp", "all-icmp"]
  ingress_with_source_security_group_id = [
    {
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.security_group.security_group_id
    },
  ]
  egress_rules = ["all-all"]

  tags = local.tags
}

## EC2 Instances

resource "aws_instance" "ec2_bastion" {
  key_name = "terraform_key"

  ami                         = "ami-0f9fc25dd2506cf6d"
  instance_type               = "t2.micro"
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  tags = merge(
    local.tags,
    {
      Name = "bastion_${local.name}"
    },
  )
}

resource "aws_instance" "ec2_amazon_linux" {

  key_name               = "terraform_key"
  ami                    = "ami-0f9fc25dd2506cf6d"
  instance_type          = "t2.micro"
  availability_zone      = element(module.vpc.azs, 0)
  subnet_id              = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids = [module.security_group.security_group_id]


  tags = merge(
    local.tags,
    {
      Name = "AL_${local.name}"
    },
  )
}


resource "aws_instance" "ec2_rhel8" {

  key_name               = "terraform_key"
  ami                    = "ami-0b0af3577fe5e3532"
  instance_type          = "t2.micro"
  availability_zone      = element(module.vpc.azs, 0)
  subnet_id              = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids = [module.security_group.security_group_id]

  tags = merge(
    local.tags,
    {
      Name = "RHEL8_${local.name}"
    },
  )
}

resource "aws_instance" "ec2_server2019" {

  key_name               = "terraform_key"
  ami                    = "ami-08ed5c5dd62794ec0"
  instance_type          = "t2.micro"
  availability_zone      = element(module.vpc.azs, 0)
  subnet_id              = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids = [module.security_group.security_group_id]


  tags = merge(
    local.tags,
    {
      Name = "S2019_${local.name}"
    },
  )
}
