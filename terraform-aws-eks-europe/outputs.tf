output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "self_managed_node_groups_role_arns" {
  value = values(module.eks.self_managed_node_groups)[*].iam_role_arn
}

output "region" {
  description = "AWS region."
  value       = var.aws_region
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "zeet_cluster_id" {
  value = var.zeet_cluster_id
}

output "cluster_name" {
  value = var.cluster_name
}

output "ssh_public" {
  value = tls_private_key.ssh.public_key_openssh
}

output "ssh_private" {
  sensitive = true
  value     = tls_private_key.ssh.private_key_pem
}

output "cluster_cloudwatch_log_group" {
  value = {
    name: module.eks.cloudwatch_log_group_name
    arn: module.eks.cloudwatch_log_group_arn
  }
}

output "iam_roles" {
  description = "Map of all iam roles to their {name, arn}."
  value = module.iam_roles.iam_roles
}

output "ecr_repository" {
  value = {
    url: aws_ecr_repository.zeet.repository_url
    name: aws_ecr_repository.zeet.name
    arn: aws_ecr_repository.zeet.arn
  }
}

output "route53_zone" {
  value = {
    zone_id: aws_route53_zone.zeet.zone_id,
    arn: aws_route53_zone.zeet.arn,
    name: aws_route53_zone.zeet.name,
    name_servers: aws_route53_zone.zeet.name_servers
  }
}