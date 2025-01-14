locals {
  domain = var.cluster_domain
}

resource "aws_route53_zone" "zeet" {
  name    = local.domain
  comment = "Managed by Zeet"
}
