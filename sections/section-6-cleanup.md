# Section 6 - Cleanup

To cleanup, we will go in reverse order - first we'll destroy the resources created in Phase 2 followed by the resources in Phase 1

1. Go into the `docker-terraform` folder from the root of the repo and run ```terraform destroy``` to remove the created Docker containers: 
   
   ```bash
   cd docker-terraform
   terraform destroy
   ```

2. Go into the ```aws-k8s-terraform``` folder from the root of the repo and run ```terraform destroy``` to remove the rest of the resources: 

    ```bash
    cd aws-k8s-terraform
    terraform destroy
    ```
    
3. Cleanup the machine entries in the Tailscale Admin portal

[:arrow_left: Section 5 - Egress Service Validation/Testing](section-5-eg-svc-validation.md)

[:leftwards_arrow_with_hook: Back to Main](../README.md)
