

#########################################################################################
# All vars declared as locals for consistency in referencing in the resources (cuz OCD) #
#########################################################################################
locals {
  name                      = var.name
  region                    = var.region
  vpc_cidr                  = var.vpc_cidr
  cluster_service_ipv4_cidr = var.cluster_service_ipv4_cidr
  desired_size              = var.desired_size
  key_name                  = var.ssh_keyname
  cluster_version           = var.cluster_version
  oauth_client_id           = var.oauth_client_id
  oauth_client_secret       = var.oauth_client_secret
  manifest_files            = fileset("${path.module}/../manifests", "*.yaml")
  tags                      = var.tags
  # Not too happy w/the logic below on slicing the subnets, but c'est la vie.
  azs                       = slice(data.aws_availability_zones.available.names, 0, min(length(data.aws_availability_zones.available.names), 3))
  public_subnets            = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]    
  private_subnets           = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 10)]
}