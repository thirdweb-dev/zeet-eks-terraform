output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "self_managed_node_groups_role" {
  value = values(module.eks.self_managed_node_groups)[*].iam_role_arn
}

output "region" {
  description = "AWS region."
  value       = var.region
}

output "dns_zone" {
  value = aws_route53_zone.zeet.zone_id
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "cluster_id" {
  value = var.cluster_id
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

output "cluster_ns_records" {
  value = aws_route53_zone.zeet.name_servers
}