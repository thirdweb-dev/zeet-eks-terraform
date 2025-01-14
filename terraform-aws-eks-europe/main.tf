terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.56.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_route53_zone" "zeet" {
  name    = var.cluster_domain
  comment = "Managed by Zeet"

  tags = {
    ZeetClusterId = var.zeet_cluster_id
    ZeetUserId    = var.zeet_user_id
  }
}

resource "aws_ecr_repository" "zeet" {
  name                 = "zeet/${var.zeet_cluster_id}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    ZeetClusterId = var.zeet_cluster_id
    ZeetUserId    = var.zeet_user_id
  }
}

module "iam_roles" {
  source = "./iam"

  cluster_name = var.cluster_name
  eks_cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  route_53_hosted_zone_id = aws_route53_zone.zeet.zone_id
}
