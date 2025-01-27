# Section 1 - Tailscale Admin Portal Setup

## Access Controls Configuration

1. Decide what VPC/pod CIDR as well as cluster service CIDR ranges you want to use
   - In the example below, we use ```10.0.0.0/16``` for the VPC/pod CIDR and ```10.40.0.0/16``` for the cluster CIDR
2. Login to the Tailscale Admin Portal
3. Click on ```Access Controls``` on the top to edit the configuration file
4. Ensure you have added the following configuration and ```Save``` the configuration:

> [!WARNING]
> If you already have existing ACL config, please ADD the below config it as needed and do not REPLACE unless you know what you are doing. At this point, the assumption is that you are comfortable with JSON and editing a [HuJSON](https://github.com/tailscale/hujson) file

   ```json
   {
      "tagOwners": {
          "tag:k8s-operator": [],
          "tag:k8s":          ["tag:k8s-operator"],
      },
      "acls": [
          {"action": "accept", "src": ["*"], "dst": ["*:*"]},
      ],
      "autoApprovers": {
          "routes": {
              "10.0.0.0/16":  ["tag:k8s-operator"],
              "10.40.0.0/16": ["tag:k8s-operator"],
          },
      },
   }
   ```

## [OAuth Client Configuration](https://tailscale.com/kb/1215/oauth-clients#setting-up-an-oauth-client)

1. Click on ```Settings``` at the top, then ```OAuth Clients``` on the left
2. Click on ```Generate OAuth client...``` on the right to open up the window to create a new Oauth client
3. Add a meaningful description(optional), then check the following boxes:
   - The ```Write``` box for ```DNS```
   - The ```Write``` box for ```Core``` under the ```Devices``` section, then click on ```Add tags``` and select ```tag:k8s-operator```
   - The ```Write``` box for ```Routes```
   - The ```Write``` box for ```Auth Keys``` under the ```Keys``` section, then make sure the ```tag:k8s-operator``` has been added again

> [!IMPORTANT]
> Before clicking on ```Generate client``` please ensure you are **READY** to copy/save the credentials securely because once you close that window you **cannot** view the secret key again!!! You'll need to revoke the old client and create a new one if so.

4. You are done for now, you will use the saved OAuth credentials soon for the Terraform setup.

[:arrow_right: Section 2 - Local Environment Setup](section-2-local-env.md)

[:leftwards_arrow_with_hook: Back to Main](../README.md)
