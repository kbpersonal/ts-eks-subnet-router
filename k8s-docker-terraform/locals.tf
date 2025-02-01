# Grab tfstate information from phase-1
data "terraform_remote_state" "aws_tfstate" {
  backend = "local"
  config = {
    path = "${path.root}/../aws-infra-terraform/terraform.tfstate"
  }
}

#######################################################################
# Define locals from outputs of the state file to be used in this run #
#######################################################################

locals {
  name                          = data.terraform_remote_state.aws_tfstate.outputs.name
  hostname                      = data.terraform_remote_state.aws_tfstate.outputs.hostname
  vpc_cidr                      = data.terraform_remote_state.aws_tfstate.outputs.vpc_cidr
  cluster_service_ipv4_cidr     = data.terraform_remote_state.aws_tfstate.outputs.cluster_service_ipv4_cidr
  cluster_name                  = data.terraform_remote_state.aws_tfstate.outputs.cluster_name
  key_name                      = data.terraform_remote_state.aws_tfstate.outputs.ssh_keyname
  aws_instance_client_public_ip = data.terraform_remote_state.aws_tfstate.outputs.client_public_ip
  eks_cluster_endpoint          = data.terraform_remote_state.aws_tfstate.outputs.eks_cluster_endpoint
  eks_cluster_ca_certificate    = base64decode(data.terraform_remote_state.aws_tfstate.outputs.eks_cluster_ca_certificate)
  eks_cluster_auth_token        = data.aws_eks_cluster_auth.this.token
  oauth_client_id               = data.terraform_remote_state.aws_tfstate.outputs.oauth_client_id
  oauth_client_secret           = data.terraform_remote_state.aws_tfstate.outputs.oauth_client_secret
}