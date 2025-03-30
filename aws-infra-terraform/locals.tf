#########################################################################################
# All vars declared as locals for consistency in referencing in the resources (cuz OCD) #
#########################################################################################

locals {

  region_providers = distinct(var.regions)

  cluster_config = [
    for idx in range(length(var.name)) : {
      name                      = var.name[idx]
      region                    = var.regions[idx]
      vpc_cidr                  = var.vpc_cidrs[idx]
      cluster_service_ipv4_cidr = var.cluster_service_ipv4_cidr[idx]
      desired_size              = var.desired_size
      key_name                  = var.ssh_keyname[idx]
      cluster_version           = var.cluster_version
      tags                      = merge(var.tags, {"Region" = var.regions[idx]})
    }
  ]

  # Generate subnet configurations per cluster
  subnet_configs = {
    for c in local.cluster_config :
    c.name => {
      azs              = slice(data.aws_availability_zones.available[c.region].names, 0, min(length(data.aws_availability_zones.available[c.region].names), 3))
      public_subnets   = [for k, v in local.azs : cidrsubnet(c.vpc_cidr, 4, k)]
      private_subnets  = [for k, v in local.azs : cidrsubnet(c.vpc_cidr, 4, k + 10)]
      vpc_plus_2_ip    = "${join(".", slice(split(".", c.vpc_cidr), 0, 3))}.2"
      advertise_routes = distinct(concat(c.private_subnets, coalesce(var.advertise_routes, []), ["${c.vpc_plus_2_ip}/32"]))
    }
  }
}