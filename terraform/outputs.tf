output "Message" {
  description = "Instructions for configuring your environment after Terraform apply."
  value = <<-EOT
Next Steps:
1. Configure your kubeconfig for kubectl by running:
   aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}

2. Test SSH to the EC2 instance's public IP:
   ssh -i /path/to/${local.key_name} ubuntu@${aws_instance.client.public_ip}

Happy deploying <3
EOT
}
