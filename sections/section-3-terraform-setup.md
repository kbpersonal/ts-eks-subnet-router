# Section 3 - Terraform Setup and Deploy

1. Ensure you can invoke ```terraform``` from your terminal properly:

   ```bash
   terraform version
   ```

   You should get a valid Terraform version as output (that you installed):

   ```bash
     Terraform v1.10.5
   ```

2. The Terraform setup is to be invoked in 2 phases:
   - Phase 1: Spin up the AWS infra with the EKS cluster, EC2 instance and accompanying supporting resources including the Tailscale-related configs for the Tailnet
   - Phase 2: Install the application K8s manifests, Tailscale K8s resources on the EKS cluster and also the `nginx` Docker container on the EC2 instance

## Phase 1 Setup

1. Go into the ```aws-infra-terraform``` folder from the root of the repo and initialize it:

   ```bash
   cd aws-infra-terraform
   terraform init
   ```

   The output should look something like this without errors:

   ```bash
    Initializing the backend...
    Initializing modules...
    Initializing provider plugins...
    - Reusing previous version of hashicorp/null from the dependency lock file
    - Reusing previous version of hashicorp/cloudinit from the dependency lock file
    - Reusing previous version of tailscale/tailscale from the dependency lock file
    - Reusing previous version of gavinbunney/kubectl from the dependency lock file
    - Reusing previous version of hashicorp/helm from the dependency lock file
    - Reusing previous version of hashicorp/time from the dependency lock file
    - Reusing previous version of hashicorp/tls from the dependency lock file
    - Reusing previous version of hashicorp/kubernetes from the dependency lock file
    - Reusing previous version of hashicorp/aws from the dependency lock file
    - Using previously-installed hashicorp/helm v2.17.0
    - Using previously-installed hashicorp/aws v5.84.0
    - Using previously-installed hashicorp/cloudinit v2.3.5
    - Using previously-installed tailscale/tailscale v0.17.2
    - Using previously-installed gavinbunney/kubectl v1.19.0
    - Using previously-installed hashicorp/kubernetes v2.35.1
    - Using previously-installed hashicorp/null v3.2.3
    - Using previously-installed hashicorp/time v0.12.1
    - Using previously-installed hashicorp/tls v4.0.6

    Terraform has been successfully initialized!

    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.

    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary
   ```

2. Copy the ```terraform.tfvars.example``` to ```terraform.tfvars```

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Open up ```terraform.tfvars``` in your favourite text editor and plug in the required and optional (if desired) input variables

   > [!IMPORTANT]
   > [CLICK HERE](section-3.1-inputs.md) for an explanation of all user input variables that can be configured

4. (Optional) Plan the deployment with ```terraform plan``` , save it to a human-readable `txt` file and review the plan fully

   ```bash
   terraform plan -out=myplan-phase1.out
   tf show myplan-phase1.out > phase1-plan.txt
   ```

5. If you are satisfied with the output of ```terraform plan``` and want to start deployment, do:

   ```bash
   terraform apply -auto-approve
   ```

   or type in ```terraform apply```, review the plan that gets dumped to `stdout` and confirm the user input with `yes` to start deployment

6. After what will seem like an eternity (might want to get yourself a bevvy) but is closer to ~25m (thanks AWS deployment times!), you should see something like this (with your environment's pertinent information of course):

   ```bash
   Apply complete! Resources: 80 added, 0 changed, 0 destroyed.

   Outputs:

   Message = <<EOT
   Next Steps:
   1. Configure your kubeconfig for kubectl by running:
      aws eks --region hell-on-earth-1 update-kubeconfig --name my-cluster-name --alias my-cluster-name

   2. SSH to the EC2 instance's public IP:
      ssh -i /path/to/my-private-keypair ubuntu@<public-IP>

   Happy deploying <3

   EOT
   ```

## Phase 2 Setup

1. Go into the `k8s-docker-terraform` folder from the root of the repo and initialize it:

   ```bash
   cd k8s-docker-terraform
   terraform init
   ```

   The output should look something like this without errors:

   ```bash
   Initializing the backend...
   Initializing provider plugins...
   - terraform.io/builtin/terraform is built in to Terraform
   - Finding kreuzwerker/docker versions matching ">= 3.0.2"...
   - Installing kreuzwerker/docker v3.0.2...
   - Installed kreuzwerker/docker v3.0.2 (self-signed, key ID BD080C4571C6104C)
   
   Terraform has created a lock file .terraform.lock.hcl to record the provider
   selections it made above. Include this file in your version control repository
   so that Terraform can guarantee to make the same selections by default when
   you run "terraform init" in the future.

   Terraform has been successfully initialized!

   You may now begin working with Terraform. Try running "terraform plan" to see
   any changes that are required for your infrastructure. All Terraform commands
   should now work.

   If you ever set or change modules or backend configuration for Terraform,
   rerun this command to reinitialize your working directory. If you forget, other
   commands will detect it and remind you to do so if necessary.
   ```

2. (Optional) Plan the deployment with ```terraform plan``` , save it to a human-readable `txt` file and review the plan fully

   ```bash
   terraform plan -out=myplan-phase2.out
   tf show myplan-phase2.out > phase2-plan.txt
   ```

3. If you are satisfied with the output of ```terraform plan``` and want to start deployment, do:

   ```bash
   terraform apply -auto-approve
   ```

   or type in ```terraform apply```, review the plan that gets dumped to `stdout` and confirm the user input with `yes` to start deployment

4. This one should go quicker, you should see something like this:

   ```bash
   docker_image.nginx: Creating...
   docker_image.nginx: Creation complete after 6s [id=sha256:9bea9f2796e236cb18c2b3ad561ff29f655d1001f9ec7247a0bc5e08d25652a1nginx:latest]
   docker_container.nginx: Creating...
   docker_container.nginx: Creation complete after 2s [id=3c60ffd9ededec15fd4454ecd05683d9cbf436e15f336ac8728f6828f0e22422]

   Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
   ```

You're done! If provisioning went well, you should now have:

- A working EKS cluster you can `kubectl` into
- An EC2 instance you can SSH into

You can now move on to the next section, which is testing and validation of the scenarios.

> [!TIP]
> If you get errors, please feel to debug it yourself, open a Github issue so I can address it,or curse at the sky (and also at me) for wasting your valuable time.

[:arrow_right: Section 4 - Subnet Router Validation/Testing](section-4-sr-validation.md)  
[:arrow_left: Section 2 - Local Environment Setup](section-2-local-env.md)

[:leftwards_arrow_with_hook: Back to Main](../README.md)
