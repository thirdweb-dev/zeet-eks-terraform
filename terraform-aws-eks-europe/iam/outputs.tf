output "iam_roles" {
  value = {
    aws-lb-controller: {
      name: module.iam_aws-lb-controller.this_iam_role_name,
      arn: module.iam_aws-lb-controller.this_iam_role_arn,
    }
    cert-manager: {
      name: module.iam_cert-manager.this_iam_role_name,
      arn: module.iam_cert-manager.this_iam_role_arn,
    }
    cluster-autoscaler: {
      name: module.iam_cluster-autoscaler.this_iam_role_name,
      arn: module.iam_cluster-autoscaler.this_iam_role_arn,
    }
    external-dns: {
      name: module.iam_external-dns.this_iam_role_name,
      arn: module.iam_external-dns.this_iam_role_arn,
    }
    fluent-bit: {
      name: module.iam_fluent-bit.this_iam_role_name,
      arn: module.iam_fluent-bit.this_iam_role_arn,
    }
    ebs-csi: {
      name: module.iam_ebs-csi.this_iam_role_name,
      arn: module.iam_ebs-csi.this_iam_role_arn
    }
  }
}
