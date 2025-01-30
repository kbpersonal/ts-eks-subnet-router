# Secure ClusterIP Service Access via Tailscale Subnet Router in EKS

## Disclaimers
> [!WARNING]
> This repo is intended to be used for educational purposes only. Conscious decisions have been taken to enable a quick setup with opinionated architecture choices over security (like best practices around handling secret keys for example) to get up and running as a proof-of-concept/learning-lab environment. Please do not attempt to use this for a production setup or anything serious 

## Problem Statement

Normally when non-cluster workloads need to access cluster microservices, those microservices need to be exposed as a ```LoadBalancer``` service publically. This both incurs costs due to AWS spinning up a network load-balancer and charging you for it as well as the traffic that passes through it, and in addition is a security risk if any bad actors are in the VPC up to no good to try and intercept traffic.

Tailscale allows us to both solve the connectivity problem and offer defense-in-depth by connecting both sides via Wireguard while also allowing the non-cluster workloads to access all the ```ClusterIP``` services in the cluster that would normally not be accessible to it and bypass the need for a cloud load-balancer.

## Overview

In this EKS-focused PoC, we will use everyone's favourite IaC tool Terraform to:

1. Spin up a private EKS cluster with VPC CNI, then:
   - Install the Tailscale Operator and add it to our tailnet
   - Create a Tailscale pod as a subnet router via the ```Connector``` Custom Resource, add it to our tailnet and advertise the cluster's pod & service CIDR routes
   - Deploy a simple ```nginx``` pod with a ```ClusterIP``` service to act as our test server
2. Spin up an EC2 instance in the same VPC but different subnet/availability zone, then:
   - Run Tailscale on it to add it to our tailnet, accepting the advertised routes from the subnet router
   - Use it as our test client to query the ```ClusterIP``` ```nginx``` service in the EKS cluster
3. Configure our tailnet with the following:
   - SplitDNS to the ```kube-dns``` service to resolve and access the ```nginx``` ```ClusterIP``` service by its cluster FQDN for the search domain ```svc.cluster.local``` from the EC2 client instance

## Architecture Diagram

![ts-k8s-sr drawio](https://github.com/user-attachments/assets/c8dc008e-b5ad-44bb-9fab-823125ba6deb)

### Packet path (as per my currently limited understanding)

1. The client EC2 instance first makes a DNS request to the `nginx` (server) pod to resolve the FQDN `nginx.default.svc.cluster.local`, the client's DNS request will first be directed to the split-DNS resolver that is the `kube-dns` `ClusterIP` service that is reachable through the subnet router pod that is advertising that entire prefix
2. `kube-dns` returns a response to the client with the IP of the `nginx` `ClusterIP` service which is also in the same advertised prefix
3. Now for the actual HTTP request via `curl`, the source IP is the internal interface IP of the client and the destination IP is the `ClusterIP` of the `nginx` service that is routed through the subnet router pod as next-hop through the Tailscale overlay tunnel
4. The subnet router pod receives the request, SNATs the source IP to its own pod IP and sends off the request to `kube-proxy` as this is a service `ClusterIP`
5. `kube-proxy` routes to the appropriate `nginx` endpoint (normal K8s business)
6. `nginx` responds to the subnet router as destination and from there the subnet router knows to send the packet back to the client over the Tailscale overlay tunnel

*Disclaimer: I may be way off here but I need to collect do some packet captures to fully understand the packet path when I get some more time to play with this*

## Setup Instructions

This repo is organized in sequential sections. Each step will build on top of the other so please follow the order as proposed below. You can start by clicking on `Step 1 - Tailscale Admin Portal Setup` here. 

[Step 1 - Tailscale Admin Portal Setup](sections/section-1-ts-admin-portal.md)  
[Step 2 - Local Environment Setup](sections/section-2-local-env.md)  
[Step 3 - Terraform Setup and Deploy](sections/section-3-terraform-setup.md)  
[Step 4 - Validation/Testing](sections/section-4-validation.md)  
[Step 5 - Clean-up](sections/section-5-cleanup.md)  

## Learnings

1. The Tailscale docs don't seem to have a full .spec of how to define the options under `subnetRouter` , I can guess but it doesn't need to be like that. I wanted to play with 'no-snat-subnet-router' but unsure how to define the key under the spec and left it for now.
2. It is unclear whether `tags` and `autoApprovers` can be injected into the ACL configuration via the tailscale Terraform provider. The description and docs there again need some love.
3. Same as #2 for creating Oauth client dynamically - maybe this one is locked down to the UI for security but I don't know. With that automation it would help properly create/revoke short-lived oAuth tokens with specific scopes for specific machines (subnet router vs regular Tailscale client)
4. Ephemeral authkey support for the tailscale-operator pod would be nice, see [this issue](https://github.com/tailscale/tailscale/issues/10166)
5. There is probably something happening with the NAT Gateway endpoint making DERP happen again on new packet because the tailnet doesn't know of its existence. I think there was some experimental flag to do something about that but I will explore it when I have more time.

## TODO

1. EC2 instance needs to have the public-IP removed and switch to Tailscale SSH and use with a 'jumphost' that is also on the Tailnet. Make it fully private.
2. More complex network scenarios/topologies closer to real deployments across VPCs and regions. Testing w/VPC peering and doing multi-cluster stuff with connectors for Ingress/Egress gateway functionality would be cool to setup. See how far we can get before it's all DERP.
3. Test with real apps/databases. See how Wireguard throughput/performance is. Try to do some `Locust` testing for maximizing throughput w/multiple client streams.
4. Add more meaningful screenshots to this repo but I also don't want it to get too bloated. TBD what the solution is.

## Credits

>"If I have seen a little further today than yesterday, it is only because I stood on the shoulders of giants" - *Isaac Newton (paraphrased)*  
[Tailscale+K8s Docs](https://tailscale.com/kb/1185/kubernetes)  
[Terraform Tailscale Provider](https://registry.terraform.io/providers/tailscale/tailscale/latest)  
[Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)  
[Terraform AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)  
[Terraform-CloudInit-Tailscale Module](https://github.com/lbrlabs/terraform-cloudinit-tailscale)  
[Terraform Kubectl Provider](https://registry.terraform.io/providers/gavinbunney/kubectl/latest)  
[Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

## Final Words

>"To err is human, to forgive is divine" - *Latin proverb*
  
There are probably a lot of mistakes, a lot of jank, and gaps in documenting and explaining this repo. I am always happy to listen and act on constructive feedback given with kind intent to continuously improve. Thank you!
