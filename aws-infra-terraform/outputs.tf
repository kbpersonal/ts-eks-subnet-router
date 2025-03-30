output "name" {
  value     = { for c in local.cluster_config : c.name => c.name }
  sensitive = true
}

output "hostname" {
  value     = { for idx, hostname in var.hostname : idx => hostname }
  sensitive = true
}

output "vpc_cidr" {
  value = { for c in local.cluster_config : c.name => c.vpc_cidr }
  sensitive = true
}

output "cluster_service_ipv4_cidr" {
  value = { for c in local.cluster_config : c.name => c.cluster_service_ipv4_cidr }
  sensitive = true
}

output "ssh_keyname" {
  value = { for idx, keyname in var.ssh_keyname : idx => keyname }
  sensitive = true
}

output "client_public_ip" {
  value = { for c in local.cluster_config : c.name => aws_instance.client[c.key].public_ip }
  sensitive = true
}

output "eks_cluster_endpoint" {
  value = { for c in local.cluster_config : c.name => module.eks[c.key].cluster_endpoint }
  sensitive = true
}

output "eks_cluster_ca_certificate" {
  value = { for c in local.cluster_config : c.name => module.eks[c.key].cluster_certificate_authority_data }
  sensitive = true
}

output "cluster_name" {
  value = { for c in local.cluster_config : c.name => module.eks[c.key].cluster_name }
  sensitive = true
}

output "eks_cluster_auth_token" {
  value = { for c in local.cluster_config : c.name => data.aws_eks_cluster_auth.this[c.key].token }
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
%{ for c in local.cluster_config ~}
1. Configure your kubeconfig for kubectl by running:
   aws eks --region ${c.region} update-kubeconfig --name ${module.eks[c.key].cluster_name} --alias ${module.eks[c.key].cluster_name}

2. Test SSH to the EC2 instance's public IP for cluster "${c.name}":
   ssh -i ~/.ssh/${local.key_name} ubuntu@${aws_instance.client[c.key].public_ip}

%{ endfor ~}

Happy deploying <3
EOT
}