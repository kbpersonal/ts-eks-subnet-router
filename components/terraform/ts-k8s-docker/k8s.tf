# Use tfstate values from phase-1 for the providers defined in locals.tf
provider "tailscale" {
  oauth_client_id        = local.oauth_client_id
  oauth_client_secret    = local.oauth_client_secret
}

provider "kubernetes" {
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = local.eks_cluster_ca_certificate
  token                  = local.eks_cluster_auth_token
}

provider "kubectl" {
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = local.eks_cluster_ca_certificate
  token                  = local.eks_cluster_auth_token
}

provider "helm" {
  kubernetes {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = local.eks_cluster_ca_certificate
    token                  = local.eks_cluster_auth_token
  }
}

# Get EKS cluster auth token for use
data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

################################################################################
# Tailscale Kubernetes Operator Setup
################################################################################
resource "helm_release" "tailscale_operator" {
  name             = "tailscale-operator-${local.environment}-${local.stage}"
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
      apiServerProxyConfig = {
        mode = "true"
      }
      operatorConfig = {
        hostname = "tailscale-operator-${local.environment}-${local.stage}"
      }
    })
  ] 
}

######################################################################
# Apply manifests and CRs                                            #
######################################################################
data "kubectl_path_documents" "docs" {
  pattern = "manifests/*.yaml"
}

# Deploy all manifests into the cluster 
resource "kubectl_manifest" "app_manifests" {
  for_each  = data.kubectl_path_documents.docs.manifests
  yaml_body = each.value
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
  hostname = local.hostname
  wait_for = "60s"
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
  name: ${local.hostname}-egress-svc
spec:
  externalName: placeholder
  type: ExternalName
YAML
    depends_on = [
    helm_release.tailscale_operator
    ]
}

# Rewrite the domain for unique ones for split-DNS across clusters
resource "kubectl_manifest" "coredns" {
    wait      = true
    yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
          }
        ready
        rewrite name substring svc.${local.environment}.cluster.local svc.cluster.local
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
YAML
}


########################################################################
# TS Split-DNS setup for K8s service FQDN resolution from EC2 instance #
########################################################################

data "kubernetes_service" "kubedns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }
}

resource "tailscale_dns_split_nameservers" "coredns_split_nameservers" {
  domain      = "svc.${local.environment}.cluster.local"
  nameservers = [data.kubernetes_service.kubedns.spec[0].cluster_ip]
}
