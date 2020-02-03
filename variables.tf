
variable "bucket_name" {
  type = string
  default = ""
}

variable "domain_name" {
  type = string
  default = ""
}

variable "internal_domain_name" {
  type = string
  default = ""
}

variable "local_public_key" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "subnet_id" {
  type = string
}

variable "hostname" {
  type = string
  default = "bastion"
}
