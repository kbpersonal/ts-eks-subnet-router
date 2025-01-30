# Section 5 - Egress Service Validation/Testing

## Post-Deployment Checks

1. Check that the ```nginx``` Docker container in the EC2 client instance is running:
   
   ```bash
   docker ps
   ```

   You should get an output like this showing the `nginx` container exposed on port `80`:

   ```bash
   CONTAINER ID   IMAGE          COMMAND                  CREATED             STATUS             PORTS                NAMES
   412c66c67d81   nginx:latest   "/docker-entrypoint.…"   About an hour ago   Up About an hour   0.0.0.0:80->80/tcp   nginx_server
   ```
   
2. Check in the EKS cluster that the `External` `Service` got created by Terraform that is pointing to the Tailscale IPv4 address of the EC2 client instance. You can verify the Tailscale IPv4 address of the instance by either running an `ip a` in the instance or by checking the Tailscale Admin UI under `Machines` > Click on your client instance machine entry > `Tailscale IPv4` under `Addresses`. You can also check that there is a new `Machine` entry for the egress pod in the Admin UI. For example:

   ```bash
   kubectl get svc ubuntu-client-nginx-svc -oyaml
   ```

   ```bash
   apiVersion: v1
   kind: Service
   metadata:
   annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
         {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{"tailscale.com/tailnet-ip":"100.126.233.38"},"name":"ubuntu-client-nginx-svc","namespace":"default"},"spec":{"externalName":"placeholder","type":"ExternalName"}}
      tailscale.com/tailnet-ip: 100.126.233.38
   creationTimestamp: "2025-01-30T02:03:04Z"
   finalizers:
   - tailscale.com/finalizer
   name: ubuntu-client-nginx-svc
   namespace: default
   resourceVersion: "701109"
   uid: 2b27df39-96f1-432c-b1fd-367106bdd123
   spec:
   externalName: ts-ubuntu-client-nginx-svc-q56ph.tailscale.svc.cluster.local
   sessionAffinity: None
   type: ExternalName
   status:
   conditions:
   - lastTransitionTime: "2025-01-30T02:03:05Z"
      message: ProxyCreated
      reason: ProxyCreated
      status: "True"
      type: TailscaleProxyReady
   loadBalancer: {}
   ```

   Note that the `tailscale.com/tailnet-ip` is populated with the correct Tailscale IPv4 IP and that the `externalName` has been populated by the operator as something like `ts-ubuntu-client-nginx-svc-q56ph.tailscale.svc.cluster.local`

3. Now there is a `netshoot` pod on the EKS cluster that can be used to test access to this service FQDN in the `default` namespace of the cluster. Open a shell to this pod, and query the `externalName` via `curl`:
   
   ```bash
   kubectl exec -it $(kubectl get pods -n default -l app=netshoot -o jsonpath='{.items[0].metadata.name}') -- /bin/bash
   ```

   ```bash
   curl -I -m2 ts-ubuntu-client-nginx-svc-q56ph.tailscale.svc.cluster.local
   ```

   You should get a `200 OK` response from the nginx Docker container on the client EC2 instance:

   ```bash
   HTTP/1.1 200 OK
   Server: nginx/1.27.3
   Date: Thu, 30 Jan 2025 05:21:56 GMT
   Content-Type: text/plain
   Content-Length: 10
   Connection: keep-alive
   ```

4. SSH into the EC2 client instance and check out the logs of the `nginx` container to see what it sees as the source IP from the cluster:

   SSH command: `ssh -i ~/.ssh/<my-key-name>.pem ubuntu@<public-ip>`
   
   ```bash
   docker logs nginx_server
   ```

   You will see something like:

   ```bash
   172.17.0.1 - - [30/Jan/2025:03:45:32 +0000] "GET / HTTP/1.1" 200 10 "-" "curl/8.7.1"
   ```

   Now the reason is because the container is running in `bridge` mode and thus the IP gets NAT'd to the `docker0` bridge interface of the EC2 client instance. If we want to see a 'real IP' of the source pod from the cluster we can either run the `nginx` Docker container in the EC2 client instance in `host` mode or we can try to simulate a `curl` request again from the `netshoot` pod where we pass a custom header, like so:

5. From the `netshoot` pod shell, run:

   ```bash
   curl -H "X-Forwarded-For: 10.0.189.100" -m2 ts-ubuntu-client-nginx-svc-q56ph.tailscale.svc.cluster.local
   ```

   Here we are simulating the `X-Forwarded-For` header in the `curl` request so that the `nginx` server reports a 'real' client IP which has been set to the Tailscale IPv4 address of the `Egress` proxy pod (can be retrieved from the Tailscale Admin UI again). 

   > [!NOTE]
   > In a future update to this repo, we will use the host mode of launching the nginx container on the client EC2 instance to hopefully not have to manually simulate this

   If we check the `docker logs`  once again on the EC2 client instance of the `nginx` container, we should see a line like this:

   ```bash
   10.0.189.100 - - [30/Jan/2025:05:31:52 +0000] "GET / HTTP/1.1" 200 10 "-" "curl/8.7.1"
   ```

6. Now we can delete the `ExternalName` service, and see that the proxy pod as well as the `Machine` entry for it on the Tailscale Admin UI gets cleaned up.
   From the `netshoot` pod, we can attempt to query the `nginx` Docker container now via the EC2 instance node-IP but that will fail due to no open port 80 in the security groups as we have also lost the proxy and the `externalName` FQDN we had to query the `nginx` server via it's Tailscale IP (that doesn't exist anymore) .

   ```bash
   netshoot-5c78fdfc4-8667d:~# curl -I -m2 10.0.8.218
   curl: (28) Connection timed out after 2002 milliseconds
   ```

[:arrow_right: Section 6 - Cleanup](section-6-cleanup.md)  
[:arrow_left: Section 4 - Subnet Router Validation/Testing](section-4-sr-validation.md)

[:leftwards_arrow_with_hook: Back to Main](../README.md)