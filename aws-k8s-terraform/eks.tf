################################################################################
# Data sources and Provider Initialization                                     #
################################################################################

# Set AWS region
provider "aws" {
  region = local.region
}

# Initialize kubernetes provider with cluster auth data
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# Initialize kubectl provider with cluster auth data
provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# Get EKS cluster auth information 
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Initialize helm provider with cluster auth data
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# Get list of available AZs in our region
data "aws_availability_zones" "available" {}


################################################################################
# EKS Cluster                                                                  #
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true # Just for this PoC, we never do this in prod. Right?
  
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


################################################################################
# Tailscale Kubernetes Operator Setup
################################################################################
resource "helm_release" "tailscale_operator" {
  name             = "tailscale-operator"
  chart            = "tailscale-operator"
  repository       = "https://pkgs.tailscale.com/helmcharts"
  namespace        = "tailscale"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  values = [
    yamlencode({
      oauth = {
        clientId     = local.oauth_client_id
        clientSecret = local.oauth_client_secret
      }
    })
  ]
  depends_on = [
    module.eks,
  ] 
}

######################################################################
# Apply manifests and CRs                                            #
######################################################################
data "kubectl_path_documents" "docs" {
  pattern = "../manifests/*.yaml"
}

# Deploy nginx in the cluster 
resource "kubectl_manifest" "app_manifests" {
  for_each  = data.kubectl_path_documents.docs.manifests
  yaml_body = each.value
  depends_on = [
    module.eks,
  ]
}

# Create the Connector CR for subnet router
resource "kubectl_manifest" "connector" {
    wait      = true
    yaml_body = <<YAML
apiVersion: tailscale.com/v1alpha1
kind: Connector
metadata:
  name: ${local.name}-cluster-cidrs
spec:
  hostname: ${local.name}-cluster-cidrs
  subnetRouter:
    advertiseRoutes:
      - "${local.vpc_cidr}"
      - "${local.cluster_service_ipv4_cidr}"
  tags:
    - "tag:k8s-operator"
YAML
    depends_on = [
    helm_release.tailscale_operator
    ]
}

# Grab the client EC2 instance's Tailscale device details
data "tailscale_device" "client_device" {
  hostname = var.hostname
  wait_for = "120s"
  depends_on = [
    aws_instance.client
  ]
}

# Create the Egress Service in the cluster to the nginx server running on the client EC2 instance
# Boldly assuming the first address from the Tailscale device is the IPv4 one for our annotation
resource "kubectl_manifest" "egress-svc" {
    wait      = true
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  annotations:
    tailscale.com/tailnet-ip: ${data.tailscale_device.client_device.addresses[0]} 
  name: ${var.hostname}-egress-svc
spec:
  externalName: placeholder
  type: ExternalName
YAML
    depends_on = [
    helm_release.tailscale_operator
    ]
}

########################################################################
# TS Split-DNS setup for K8s service FQDN resolution from EC2 instance #
########################################################################

data "kubernetes_service" "kubedns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }
  depends_on = [
    module.eks,
  ]
}

resource "tailscale_dns_split_nameservers" "coredns_split_nameservers" {
  domain      = "svc.cluster.local"
  nameservers = [data.kubernetes_service.kubedns.spec[0].cluster_ip]
  depends_on = [
    module.eks,
  ]
}
