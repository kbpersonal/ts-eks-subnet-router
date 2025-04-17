data "azurerm_kubernetes_cluster" "credentials" {
  name                = local.cluster_name
  resource_group_name = local.resource_group_name
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

# Create a ProxyClass to standardize configs applied to operator resources
resource "kubectl_manifest" "proxyclass" {
    wait      = true
    yaml_body = <<YAML
apiVersion: tailscale.com/v1alpha1
kind: ProxyClass
metadata:
  name: ${local.stage}
spec:
  statefulSet:
    pod:
      labels:
        tenant: ${local.tenant}
        environment: ${local.environment}
        stage: ${local.stage}
      nodeSelector:
        beta.kubernetes.io/os: "linux"
YAML
    depends_on = [
    helm_release.tailscale_operator
    ]
}

# Create the Connector CR for subnet router w/the proxy class
resource "kubectl_manifest" "connector" {
    wait      = true
    yaml_body = <<YAML
apiVersion: tailscale.com/v1alpha1
kind: Connector
metadata:
  name: ${local.cluster_name}-cluster-cidrs
spec:
  proxyClass: ${local.stage}
  hostname: ${local.cluster_name}-cluster-cidrs
  subnetRouter:
    advertiseRoutes:
      - "${local.vnet_cidr}"
      - "${local.aks_service_ipv4_cidr}"
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

# Create a ProxyGroup for egress proxies in each cluster
resource "kubectl_manifest" "egressproxygroup" {
    wait      = true
    yaml_body = <<YAML
apiVersion: tailscale.com/v1alpha1
kind: ProxyGroup
metadata:
  name: ${local.tenant}-${local.environment}-${local.stage}-egressproxy
spec:
  type: egress
  replicas: ${local.proxy_replicas}
  proxyClass: ${local.stage}
YAML
    depends_on = [
    helm_release.tailscale_operator
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
    tailscale.com/proxy-group: ${local.tenant}-${local.environment}-${local.stage}-egressproxy
  labels:
    tailscale.com/proxy-class: ${local.stage}
  name: ${local.hostname}-nginx-egress-svc
spec:
  externalName: placeholder
  type: ExternalName
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: nginx
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
        rewrite name substring ${local.environment}.svc.cluster.local svc.cluster.local answer auto
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

####################################################################
# TS Split-DNS setup for K8s service FQDN resolution from Azure VM #
####################################################################

data "kubernetes_service" "kubedns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }
}

resource "tailscale_dns_split_nameservers" "coredns_split_nameservers" {
  domain      = "${local.environment}.svc.cluster.local"
  nameservers = [data.kubernetes_service.kubedns.spec[0].cluster_ip]
}