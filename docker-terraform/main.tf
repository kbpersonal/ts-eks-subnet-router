# Grab state from first run
data "terraform_remote_state" "aws_tfstate" {
  backend = "local"
  config = {
    path = "${path.root}/../aws-k8s-terraform/terraform.tfstate"
  }
}

# Define vars from outputs of the state file to be used in this run
locals {
  key_name                      = data.terraform_remote_state.aws_tfstate.outputs.ssh_keyname
  aws_instance_client_public_ip = data.terraform_remote_state.aws_tfstate.outputs.client_public_ip
}

# Docker provider configuration using SSH to the EC2 instance
provider "docker" {
  host     = "ssh://ubuntu@${local.aws_instance_client_public_ip}"
  ssh_opts = ["-i", "~/.ssh/${local.key_name}.pem"]
}

# Grab the latest nginx image digest
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

# NGINX Docker container setup (using the nginx.conf copied by remote-exec-provisioner)
resource "docker_container" "nginx" {
  name  = "nginx_server"
  image = docker_image.nginx.image_id
  ports {
    internal = 80
    external = 80
  }
  volumes {
    container_path = "/etc/nginx/nginx.conf"
    host_path      = "/home/ubuntu/nginx_docker/nginx.conf" 
  }
  restart = "unless-stopped"
  lifecycle {
    # This provider hates reconciling state so this is the hack workaround to not make it recreate the container on subsequent terraform applies
    ignore_changes = [env, dns, dns_search, domainname, network_mode, working_dir, labels, cpu_shares, memory, memory_swap]
  }
}