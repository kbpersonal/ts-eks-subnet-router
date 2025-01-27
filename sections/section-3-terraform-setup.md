# Section 3 - Terraform Setup and Deploy

1. Ensure you can invoke ```terraform``` from your terminal properly:

   ```bash
   terraform version
   ```

   You should get a valid Terraform version as output (that you installed):

   ```bash
     Terraform v1.10.5
   ```

2. Go into the ```terraform``` folder in the repo and initialize it:

   ```bash
   cd terraform
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

3. Copy the ```terraform.tfvars.example``` to ```terraform.tfvars```

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

4. Open up ```terraform.tfvars``` in your favourite text editor and plug in the required and optional (if desired) input variables
> [!IMPORTANT]
> [CLICK HERE](section-3.1-inputs.md) for an explanation of all user input variables that can be configured  

5. (Optional) Plan the deployment with ```terraform plan``` , save it to a human-readable `txt` file and review the plan fully

   ```bash
   terraform plan -out=myplan.out
   tf show plan.out > plan.txt
   ```

6. If you are satisfied with the output of ```terraform plan``` and want to start deployment, do:

   ```bash
   terraform apply -auto-approve
   ```

   or type in ```terraform apply```, review the plan that gets dumped to `stdout` and confirm the user input with `yes` to start deployment

7. After what will seem like an eternity (might want to get yourself a bevvy) but is closer to ~25m (thanks AWS deployment times!), you should see something like this (with your environment's pertinent information of course):

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

> [!TIP]
> If you get errors, you may debug it yourself, open a Github issue,or curse at the sky (and also at the author of this repo) for wasting your valuable time that you'd rather have spent doomscrolling anyway.

[:arrow_right: Section 4 - Validation/Testing](section-4-validation.md)  
[:arrow_left: Section 2 - Local Environment Setup](section-2-local-env.md)

[:leftwards_arrow_with_hook: Back to Main](../README.md)
