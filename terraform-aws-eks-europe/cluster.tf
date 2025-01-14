module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = flatten([module.vpc.private_subnets, module.vpc.public_subnets])

  tags = {
    ZeetClusterId = var.zeet_cluster_id
    ZeetUserId    = var.zeet_user_id
  }

  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 365

  eks_managed_node_groups = local.worker_templates_cpu

  self_managed_node_groups = local.worker_templates_gpu

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}

resource "aws_security_group" "worker_public" {
  name_prefix = "worker_public"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  key_name   = "ssh_key_${var.zeet_cluster_id}"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_autoscaling_group_tag" "eks_managed_node_groups" {
  for_each = { for t in local.eks_managed_node_groups_tags : t.id => t }

  autoscaling_group_name = module.eks.eks_managed_node_groups[each.value.name].node_group_resources[0].autoscaling_groups[0].name

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = each.value.propagate_at_launch
  }
}

resource "aws_autoscaling_group_tag" "self_managed_node_groups" {
  for_each = { for t in local.self_managed_node_groups_tags : t.id => t }

  autoscaling_group_name = module.eks.self_managed_node_groups[each.value.name].autoscaling_group_name

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = each.value.propagate_at_launch
  }
}

locals {
  iam_ebs-csi_role_arn = module.iam_roles.iam_roles["ebs-csi"]["arn"]
}

resource "aws_eks_addon" "eks_addon_csi" {
  cluster_name = module.eks.cluster_id
  service_account_role_arn = local.iam_ebs-csi_role_arn
  addon_name   = "aws-ebs-csi-driver"
}

locals {
  worker_templates_cpu = { for k, v in {
    "m5-large-system" : {
      instance_types = ["m5.large"]
      desired_size   = 1

      labels = {
        "zeet.co/dedicated" = "system"
      }
    }
    "r6a-2xlarge-system" : {
      instance_types = ["r6a.2xlarge"]
      desired_size   = 1

      labels = {
        "zeet.co/dedicated": "system"
      }
    }
    "c5-4xlarge-dedi" : {
      instance_types = ["c5.4xlarge"]

      labels = {
        "zeet.co/dedicated" = "dedicated"
      }

      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "dedicated"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    "c5-2xlarge-dedi" : {
      instance_types = ["c5.2xlarge"]

      labels = {
        "zeet.co/dedicated" = "dedicated"
      }

      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "dedicated"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    "c5-xlarge-dedi" : {
      instance_types = ["c5.xlarge"]

      labels = {
        "zeet.co/dedicated" = "dedicated"
      }

      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "dedicated"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    "m5-large-dedi" : {
      instance_types = ["m5.large"]

      labels = {
        "zeet.co/dedicated" = "dedicated"
      }

      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "dedicated"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    "c5-xlarge-guran" : {
      instance_types = ["c5.xlarge"]
      capacity_type  = "SPOT"

      labels = {
        "zeet.co/dedicated" = "guaranteed"
      }

      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "guaranteed"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    "m5-large-shared" : {
      instance_types = ["m5.large"]
      capacity_type  = "SPOT"

      labels = {
        "zeet.co/dedicated" = "shared"
      }

      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "shared"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    "m5-large-dedi-private" : {
      instance_types      = ["m5.large"]
      autoscaling_enabled = var.enable_nat

      subnet_ids = [sort(module.vpc.private_subnets)[0]]

      labels = {
        "zeet.co/dedicated" = "dedicated"
        "zeet.co/static-ip" = "true"
      }

      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "dedicated"
          effect = "NO_SCHEDULE"
        },
        {
          key    = "zeet.co/static-ip"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    "c5-xlarge-guran-priv" : {
      instance_types      = ["c5.xlarge"]
      capacity_type       = "SPOT"
      autoscaling_enabled = var.enable_nat

      subnet_ids = [sort(module.vpc.private_subnets)[0]]

      labels = {
        "zeet.co/dedicated" = "guaranteed"
        "zeet.co/static-ip" = "true"
      }

      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "guaranteed"
          effect = "NO_SCHEDULE"
        },

        {
          key    = "zeet.co/static-ip"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  } : k => merge({
    name                = k
    key_name            = aws_key_pair.ssh.key_name
    desired_size        = 0
    min_size            = 0
    max_size            = 20
    autoscaling_enabled = true

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 50
          volume_type           = "gp2"
          delete_on_termination = true
        }
      }
    }

    subnet_ids             = [sort(module.vpc.public_subnets)[0]]
    vpc_security_group_ids = [aws_security_group.worker_public.id]
  }, v)
  }

  worker_templates_gpu = var.enable_gpu ? {
    "g4dn-xlarge-dedi" : merge({
      key_name     = aws_key_pair.ssh.key_name
      desired_size = 0
      min_size     = 0
      max_size     = 10

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp2"
            delete_on_termination = true
          }
        }
      }

      subnet_ids             = [sort(module.vpc.public_subnets)[0]]
      vpc_security_group_ids = [aws_security_group.worker_public.id]
    }, {
      name          = "g4dn-xlarge-dedicated"
      instance_type = "g4dn.xlarge"
      ami_id        = data.aws_ami.eks_gpu.id

      subnet_ids = [sort(module.vpc.public_subnets)[0]]

      bootstrap_extra_args = "--kubelet-extra-args '${
        join(" ", [
          "--node-labels=zeet.co/dedicated=dedicated,zeet.co/gpu=\"true\"",
          "--register-with-taints nvidia.com/gpu=present:NoSchedule",
        ])
      }'"

      // not used just for reference
      labels = {
        "zeet.co/dedicated" = "dedicated"
        "zeet.co/gpu"       = "true"
      }
      taints = [
        {
          key    = "zeet.co/dedicated"
          value  = "dedicated"
          effect = "NO_SCHEDULE"
        },

        {
          key    = "zeet.co/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    })
  } : {}
}

locals {
  eks_gpu_ami_name_pattern = "amazon-eks-gpu-node-${var.cluster_version}*"
}

data "aws_ami" "eks_gpu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [local.eks_gpu_ami_name_pattern]
  }
}

locals {
  eks_managed_node_groups_tags = flatten([
    for n, i in local.worker_templates_cpu : concat([
      for k, v in i.labels : {
        id                  = join("-", [n, k])
        name                = n
        key                 = "k8s.io/cluster-autoscaler/node-template/label/${k}"
        propagate_at_launch = false
        value               = v
      }], [{
      id                  = join("-", [n, "autoscaling-storage"])
      name                = n
      key                 = "k8s.io/cluster-autoscaler/node-template/resources/ephemeral-storage"
      propagate_at_launch = false
      value               = "50Gi"
    }, {
      id                  = join("-", [n, "autoscaling-enabled"])
      name                = n
      key                 = "k8s.io/cluster-autoscaler/enabled"
      propagate_at_launch = true
      value               = tostring(i.autoscaling_enabled)
    }]
    )
  ])

  self_managed_node_groups_tags = flatten([
    for n, i in local.worker_templates_gpu : concat([
      for k, v in i.labels : {
        id                  = join("-", [n, k])
        name                = n
        key                 = "k8s.io/cluster-autoscaler/node-template/label/${k}"
        propagate_at_launch = false
        value               = v
      }], [{
      id                  = join("-", [n, "autoscaling-enabled"])
      name                = n
      key                 = "k8s.io/cluster-autoscaler/enabled"
      propagate_at_launch = true
      value               = "true"
    },
      {
        id                  = join("-", [n, "autoscaling-owner"])
        name                = n
        key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
        propagate_at_launch = true
        value               = "true"
      },
      {
        id                  = join("-", [n, "autoscaling-storage"])
        name                = n
        key                 = "k8s.io/cluster-autoscaler/node-template/resources/ephemeral-storage"
        propagate_at_launch = false
        value               = "50Gi"
      }]
    )
  ])
}
