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
  tags                      = merge(var.tags, {"Region" = var.region}, {"Tenant-Prefix" = var.tenant}, {"Env" = var.environment}, {"Stage" = var.stage})
  # Select the first 3 availability zones from the available list of AWS AZs. If <3 are available, select them all
  azs                       = slice(data.aws_availability_zones.available.names, 0, min(length(data.aws_availability_zones.available.names), 3))
  # Generate a list of subnets off the VPC CIDR with one public subnet generated per AZ 
  public_subnets            = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]    
  # Generate a list of subnets off the VPC CIDR with one private subnet per AZ with an offset
  private_subnets           = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 10)]
  # AWS Route 53 Resolver VPC+2 IP 
  vpc_plus_2_ip             = "${join(".", slice(split(".", var.vpc_cidr), 0, 3))}.2"
  # Merge EKS private subnets CIDRs, AWS Route 53 Resolver IP, and any user-defined routes and advertise them from the subnet router
  advertise_routes          = distinct(concat(local.private_subnets, coalesce(var.advertise_routes, []), ["${local.vpc_plus_2_ip}/32"]))
}