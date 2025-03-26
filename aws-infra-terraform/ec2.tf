# Initialize the tailscale provider 
provider "tailscale" {
  oauth_client_id     = local.oauth_client_id
  oauth_client_secret = local.oauth_client_secret
}

# Use the module to add the EC2 instance into our tailnet
module "ubuntu-tailscale-client" {
  source           = "./modules/cloudinit-ts"
  hostname         = var.hostname
  accept_routes    = true
  advertise_routes = local.advertise_routes
  ephemeral        = false
  primary_tag      = "subnet-router"
  additional_parts = [
    {
      filename     = "install_docker.sh"
      content_type = "text/x-shellscript"
      content      = file("${path.module}/files/install_docker.sh")
    }
  ]
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
    description = "Allow SSH access"
  }

  ingress {
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Tailscale WG direct connection access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# Provision the EC2 instance,pass in templatized base64-encoded cloudinit data from the module that sets up Tailscale client and Docker
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

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/nginx_docker"  # Ensure the directory is created
    ]
  }
  
  provisioner "file" {
    source      = "${path.module}/files/nginx.conf"  # Local file path
    destination = "/home/ubuntu/nginx_docker/nginx.conf"  # Target path
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/${local.key_name}")
    host        = self.public_ip
  }
}