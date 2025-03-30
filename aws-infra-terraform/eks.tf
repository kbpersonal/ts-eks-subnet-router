################################################################################
# Data sources and Provider Initialization                                     #
################################################################################


# Get list of available AZs in each region, reference provider for each cluster
data "aws_availability_zones" "available" {
  for_each = { for c in local.cluster_config : c.name => c }
  provider = aws.${each.value.region}
}

# Cluster auth datasource for each cluster
data "aws_eks_cluster_auth" "this" {
  for_each = { for c in local.cluster_config : c.name => c }
  name      = module.eks[each.key].cluster_name
  provider  = aws.${each.value.region}  
}

################################################################################
# EKS Cluster                                                                  #
################################################################################

module "eks" {
  for_each = { for c in local.cluster_config : c.name => c }

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  providers = {
    aws = aws.${each.value.region}
  }

  cluster_name                    = each.value.name
  cluster_version                 = each.value.cluster_version
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

  vpc_id                    = module.vpc[each.key].vpc_id
  subnet_ids                = slice(module.vpc[each.key].private_subnets, 0, length(data.aws_availability_zones.available[each.key].names))
  cluster_service_ipv4_cidr = each.value.cluster_service_ipv4_cidr

  eks_managed_node_groups = {
    worker-node = {
      instance_types = ["t3.2xlarge"]
      node_group_name_prefix = "${each.value.name}-worker-"

      min_size     = 0
      max_size     = 3
      desired_size = each.value.desired_size
      
      disk_size = 100

      key_name = each.value.key_name

      pre_bootstrap_user_data = <<-EOT
        yum install -y amazon-ssm-agent kernel-devel-`uname -r`
        systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
      EOT

      tags = merge(
        each.value.tags,
        { 
          "Name" = "${each.value.name}-worker"
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

  tags = each.value.tags
}

#########################################################################################
# EC2 to EKS control plane security group access to private kubeapiserver               #
#########################################################################################

resource "aws_security_group_rule" "eks_control_plane_ingress" {
  for_each = { for c in local.cluster_config : c.name => c }

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main.id
  security_group_id        = module.eks[each.key].cluster_primary_security_group_id
  description              = "Allow traffic from each EC2 SR instance SG to respective EKS control plane SG on port 443"
}

#########################################################################################
# TS Split-DNS setup for EKS private-only kube-apiserver FQDN resolution in the tailnet #
#########################################################################################

resource "tailscale_dns_split_nameservers" "aws_route53_resolver" {
  for_each = { for c in local.cluster_config : c.name => c }

  domain      = "eks.amazonaws.com"
  nameservers = [module.vpc[each.key].vpc_plus_2_ip]
}

resource "tailscale_dns_search_paths" "eks_search_paths" {
  search_paths = [
    "eks.amazonaws.com",
    "svc.cluster.local"
  ]
}