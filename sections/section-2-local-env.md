# Section 2 - Local Environment Setup

## Prerequisites

The following are the basic requirements to get going:

- AWS Account with [access/secret key/session token created](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) for an [appropriate IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/access-keys-admin-managed.html)
> [!NOTE]
> Best practice is to set the key duration to be short-lived during creation and only for the purpose of playing with this lab. Please do not use it for long-term/prod programmatic access to AWS
  Once created, the [credentials](https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-files.html) should be saved to ```~/.aws/credentials``` as a file or running ```aws configure``` from your terminal to generate that file.
- [SSH Key created via AWS CLI generated or created locally and uploaded to the desired region in AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html)
- [Git](https://github.com/git-guides/install-git)
- Terminal ([bash](https://www.gnu.org/software/bash/),[zsh](https://ohmyz.sh/),[fish](https://fishshell.com/),any other ish)

## Setup

Ensure your environment has these tools:

- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Either [EKS](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html) or [native](https://kubernetes.io/docs/tasks/tools/#kubectl) ```kubectl```
- ```kubectl``` [autocompletion setup](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_completion/) (Optional)
- [k9s](https://k9scli.io/topics/install/) (Optional)

## Clone this repo

```bash
git clone https://github.com/kbpersonal/ts-eks-subnet-router.git
```

[:arrow_right: Section 3 - Terraform Setup and Deploy](section-3-terraform-setup.md)  
[:arrow_left: Section 1 - Tailscale Admin Portal Setup](section-1-ts-admin-portal.md)

[:leftwards_arrow_with_hook: Back to Main](../README.md)
