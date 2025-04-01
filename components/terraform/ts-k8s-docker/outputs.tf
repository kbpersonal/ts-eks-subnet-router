output "Message" {
  description = "Instructions for configuring your environment after Terraform apply."
  value = <<-EOT
Next Steps:
1. Configure your kubeconfig for direct APIserver access by running:
   aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}

2. Test SSH to the EC2 instance's public IP:
   ssh -i ~/.ssh/${local.key_name} ubuntu@${aws_instance.client.public_ip}

3. Configure your kubeconfig for Tailscale Operator APIserver proxy access by running:
   tailscale configure kubeconfig tailscale-operator-${local.environment}-${local.stage}

Happy deploying <3
EOT
}