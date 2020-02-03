data "aws_region" "current" {}

locals {
  name = "bastion"

  public_dns = join(".", [
    var.hostname,
    data.aws_region.current.name])

  private_dns = join(".", [
    var.hostname,
    data.aws_region.current.name])

  bucket_name = var.bucket_name == "" ? "public-keys-${data.aws_caller_identity.this.account_id}" : var.bucket_name
}

resource "aws_eip" "this" {

  vpc = true

  tags = {
    Name = local.name
    Region = data.aws_region.current.name
  }

  lifecycle {
    prevent_destroy = false
  }
}

data "aws_caller_identity" "this" {}

module "bucket" {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket"

  bucket = local.bucket_name
  acl    = "private"

  force_destroy = true
  region = data.aws_region.current.name

  versioning = {
    enabled = true
  }
}

module "user_data" {
  source = "github.com/insight-infrastructure/terraform-aws-icon-user-data"
  type = "bastion_s3"

  prometheus_enabled = true
  consul_enabled = true

  s3_bucket_name = module.bucket.this_s3_bucket_bucket_domain_name
  ssh_user = "ubuntu"
  keys_update_frequency = "5,20,35,50 * * * *"
}

module "bastion" {
  source = "github.com/insight-infrastructure/terraform-aws-ec2-basic"
  name = local.name

  ebs_volume_size = 0
  root_volume_size = 8

  instance_type = "t2.micro"
  volume_path = "/dev/sdf"

  local_public_key = var.local_public_key

  user_data = module.user_data.user_data

  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id = var.subnet_id

  json_policy_name = "S3KeysBucketRead"
  json_policy = <<-EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${module.bucket.this_s3_bucket_bucket_domain_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${module.bucket.this_s3_bucket_bucket_domain_name}/*"
    }
  ]
}
EOT

  tags = {}
}

data "aws_route53_zone" "public_root_zone" {
  count = var.domain_name == "" ? 0 : 1
  name = "${var.domain_name}."
}

data "aws_route53_zone" "private_root_zone" {
  count = var.internal_domain_name == "" ? 0 : 1
  name = "${var.internal_domain_name}."
  private_zone = true
}

resource "aws_route53_record" "public" {
  count = var.domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.public_root_zone.*.id[0]

  name = local.public_dns
  type = "A"

  ttl = "30"
  records = [module.bastion.public_ip]
}

resource "aws_route53_record" "private" {
  count = var.internal_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.private_root_zone.*.id[0]

  name = local.private_dns
  type = "A"

  ttl = "30"
  records = [module.bastion.private_ip]
}
