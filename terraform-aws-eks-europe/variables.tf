variable "region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.30" # TODO: anchor integration
}

variable "cluster_domain" {
  type = string
}

variable "user_id" {
  type = string
}

variable "enable_nat" {
  type = bool
}

variable "enable_gpu" {
  type = bool
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  type    = list(string)
  default = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

variable "vpc_private_subnets" {
  type    = list(string)
  default = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
}
