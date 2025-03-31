output "name" {
  value     = local.name
  sensitive = true
}

output "hostname" {
  value     = var.hostname
  sensitive = true
}

output "vpc_cidr" {
  value     = local.vpc_cidr
  sensitive = true
}

output "cluster_service_ipv4_cidr" {
  value     = local.cluster_service_ipv4_cidr
  sensitive = true
}

output "ssh_keyname" {
  value = var.ssh_keyname
  sensitive = true
}

output "client_public_ip" {
  value = aws_instance.client.public_ip
  sensitive = true
}

output "eks_cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "eks_cluster_ca_certificate" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "cluster_name" {
  value     = module.eks.cluster_name
  sensitive = true
}

output "eks_cluster_auth_token" {
  value     = data.aws_eks_cluster_auth.this.token
  sensitive = true
}

output "oauth_client_id" {
  value     = local.oauth_client_id
  sensitive = true
}

output "oauth_client_secret" {
  value     = local.oauth_client_secret
  sensitive = true
}

output "Message" {
  description = "Instructions for configuring your environment after Terraform apply."
  value = <<-EOT
Next Steps:
1. Configure your kubeconfig for kubectl by running:
   aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}

2. Test SSH to the EC2 instance's public IP:
   ssh -i ~/.ssh/${local.key_name} ubuntu@${aws_instance.client.public_ip}

Happy deploying <3
EOT
}