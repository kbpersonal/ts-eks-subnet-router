# output "configure_kubectl" {
#   description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
#   value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}"
# }

# output "ec2_instance_public_ip" {
#   description = "The public IP of the client EC2 instance"
#   value = aws_instance.client.public_ip
# }

# output "Message" {
#   description = "Instructions for configuring your environment after Terraform apply."
#   value = "Next Steps:\n1. Configure your kubectl by running:\n   aws eks --region ca-central-1 update-kubeconfig --name kb-demo --alias kb-demo\n\n2. SSH to the EC2 instance's public IP:\n   ssh -i /path/to/kb-calico-egw-key ubuntu@3.99.171.234\n\nHappy deploying!"
# }

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