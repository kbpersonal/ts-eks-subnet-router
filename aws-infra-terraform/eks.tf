################################################################################
# Data sources and Provider Initialization                                     #
################################################################################

# Set AWS region
provider "aws" {
  region = local.region
}

# Get list of available AZs in our region
data "aws_availability_zones" "available" {}

# Cluster auth datasource
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

################################################################################
# EKS Cluster                                                                  #
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true
  
  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    metrics-server         = {}   
  }

  cluster_enabled_log_types   = []
  create_cloudwatch_log_group = false

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = slice(module.vpc.private_subnets, 0, length(local.azs))
  cluster_service_ipv4_cidr = local.cluster_service_ipv4_cidr

  eks_managed_node_groups = {
    worker-node = {
      instance_types = ["t3.2xlarge"]
      node_group_name_prefix = "${local.name}-worker-"

      min_size     = 0
      max_size     = 3
      desired_size = local.desired_size
      
      disk_size = 100

      key_name = local.key_name

      pre_bootstrap_user_data = <<-EOT
        yum install -y amazon-ssm-agent kernel-devel-`uname -r`
        systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
      EOT

      tags = merge(
        local.tags,
        { 
          "Name" = "${local.name}-worker"
        }
      )
    }
  }

  node_security_group_additional_rules = {
    ingress_to_metrics_server = {
      description                   = "Cluster API to metrics-server"
      protocol                      = "tcp"
      from_port                     = 30000
      to_port                       = 30000
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  tags = local.tags
}

#########################################################################################
# EC2 to EKS control plane security group access to private kubeapiserver               #
#########################################################################################

resource "aws_security_group_rule" "eks_control_plane_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main.id
  security_group_id        = module.eks.cluster_primary_security_group_id
  description              = "Allow traffic from EC2 SR instance SG to EKS control plane on port 443"
}

#########################################################################################
# TS Split-DNS setup for EKS private-only kube-apiserver FQDN resolution in the tailnet #
#########################################################################################

resource "tailscale_dns_split_nameservers" "aws_route53_resolver" {
  domain      = "eks.amazonaws.com"
  nameservers = [local.vpc_plus_2_ip]
}

resource "tailscale_dns_search_paths" "eks_search_paths" {
  search_paths = [
    "eks.amazonaws.com"
  ]
}