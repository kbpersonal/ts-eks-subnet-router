module "vpc" {
  for_each = { for c in local.cluster_config : c.name => c }

  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0.0"

  providers = {
    aws = aws.${each.value.region}
  }
  
  name = each.value.name
  cidr = each.value.vpc_cidr

  
  azs              = local.subnet_configs[each.key].azs
  public_subnets   = local.subnet_configs[each.key].public_subnets
  private_subnets  = local.subnet_configs[each.key].private_subnets

  # Manage ourselves so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${each.value.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${each.value.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${each.value.name}-default" }

  enable_nat_gateway     = true
  single_nat_gateway     = true

  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = each.value.tags
}
