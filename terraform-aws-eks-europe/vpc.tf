module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name                 = var.cluster_name
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  private_subnets      = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
  enable_dns_hostnames = true

  enable_nat_gateway  = var.enable_nat
  single_nat_gateway  = var.enable_nat
  reuse_nat_ips       = var.enable_nat
  external_nat_ip_ids = var.enable_nat ? aws_eip.nat[*].id : []

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  tags = {
    ZeetClusterId = var.zeet_cluster_id
    ZeetUserId    = var.zeet_user_id
  }
}

data "aws_availability_zones" "available" {}

resource "aws_eip" "nat" {
  count = var.enable_nat ? 1 : 0
  vpc   = true
  tags = {
    ZeetClusterId = var.zeet_cluster_id
    ZeetUserId    = var.zeet_user_id
  }
}
