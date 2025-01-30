# Initialize the tailscale provider 
provider "tailscale" {
  oauth_client_id     = local.oauth_client_id
  oauth_client_secret = local.oauth_client_secret
}

# Use the module to add the EC2 instance into our tailnet
module "ubuntu-tailscale-client" {
  source         = "./modules/cloudinit-ts"
  hostname       = var.hostname
  accept_routes  = true
  primary_tag    = "k8s-operator"
}

# Pick the latest Ubuntu 22.04 AMI in the region for our EC2 instance
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Allow SSH access via public IP because we're not exploring Tailscale SSH yet (TBD in the future)
resource "aws_security_group" "main" {
  vpc_id      = module.vpc.vpc_id
  description = "Required access traffic"
    
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access" # Using key-based access anyway, but again we don't do this in prod.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# Provision the EC2 instance,pass in templatized base64-encoded cloudinit data from the module that sets up TS, and install nginx container
resource "aws_instance" "client" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.main.id]
  source_dest_check      = false
  key_name               = local.key_name 
  ebs_optimized          = true

  user_data_base64       = module.ubuntu-tailscale-client.rendered

  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(
    local.tags,
    {
      "Name" = var.hostname
    }
  )

  # Add Docker installation with remote-exec provisioner
  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com | sh",        
      "systemctl start docker",                         
      "systemctl enable docker",
      "while ! systemctl is-active --quiet docker; do sleep 2; done",                         
      "mkdir -p /home/ubuntu/nginx_docker",            
      "cp ${path.module}/files/nginx.conf /home/ubuntu/nginx_docker/nginx.conf"  # Copy nginx.conf
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/${local.key_name}.pem") # User needs put their private key in ~/.ssh (for now)
      host        = aws_instance.client.public_ip
    }
  }
}

# # Docker provider configuration using SSH to the EC2 instance
# provider "docker" {
#   host     = "ssh://ubuntu@${aws_instance.client.public_ip}"
#   ssh_opts = ["-i", "~/.ssh/${local.key_name}.pem"]
# }

# # Grab the latest nginx image digest
# resource "docker_image" "nginx" {
#   name = "nginx:latest"
#   depends_on = [aws_instance.client]
# }

# # NGINX Docker container setup (using the nginx.conf copied by remote-exec-provisioner)
# resource "docker_container" "nginx" {
#   name  = "nginx_server"
#   image = docker_image.nginx.image_id
#   ports {
#     internal = 80
#     external = 80
#   }
#   volumes {
#     container_path = "/etc/nginx/nginx.conf"
#     host_path      = "/home/ubuntu/nginx_docker/nginx.conf" 
#   }
#   restart = "unless-stopped"
#   lifecycle {
#     # This provider hates reconciling state so this is the hack workaround to not make it recreate the container on subsequent terraform applies
#     ignore_changes = [env, dns, dns_search, domainname, network_mode, working_dir, labels, cpu_shares, memory, memory_swap]
#   }
#   depends_on = [aws_instance.client]
# }