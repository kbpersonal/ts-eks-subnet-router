# Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the EKS cluster | `string` | N/A | Yes |
| region | Desired AWS Region | `string` | N/A | Yes |
| oauth_client_id | OAuth application's ID when using OAuth client credentials | `string` | N/A | Yes |
| oauth_client_secret | OAuth application's secret when using OAuth client credentials | `string` | N/A | Yes |
| hostname | Tailscale Machine hostname of the EC2 instance | `string` | N/A | Yes |
| key_name | SSH Keypair name that already exists in your region in AWS, used to access EKS worker nodes and EC2 instance | `string` | N/A | Yes |
| cluster_version | Kubernetes version | `string` | "1.31" | No |
| cluster_pod_ipv4_cidr | Kubernetes `Pod` CIDR range | `string` | "10.100.0.0/18" | No |
| cluster_service_ipv4_cidr | Kubernetes `Service` CIDR range | `string` | "10.40.0.0/16" | No |
| desired_size | Desired no. of EKS worker nodes | `string` | "2" | No |
| vpc_cidr | AWS VPC CIDR for EKS cluster and EC2 instance | `string` | "10.0.0.0/16" | No |
| tags | Map of common user tags to assign to all resources | `map(string)` | {} | No |

> [!NOTE]
> Please make sure to enter valid values for the required variables as indicated in the appropriate areas of the various sections and optional ones if you want to customize the defaults
  
[:arrow_left: Section 3 - Terraform Setup and Deploy](section-3-terraform-setup.md)
