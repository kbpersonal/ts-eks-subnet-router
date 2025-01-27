# Section 4 - Validation/Testing

## Post-Deployment Checks

1. Add the `kubeconfig` credentials of the EKS cluster to your `~/.kube/config` file by running the command that the final output of Terraform generated:

   ```bash
   aws eks --region <region> update-kubeconfig --name <my-cluster-name> --alias <my-cluster-name>
   ```

   - Run `kubectl get nodes` and `kubectl get pods -A` to ensure you can see the nodes are `Ready` and the list of all pods are showing:

     ```bash
     kubectl get nodes
     ```

     You should get something like:

     ```bash
     NAME                                            STATUS   ROLES    AGE     VERSION
     ip-10-0-173-255.ca-central-1.compute.internal   Ready    <none>   7h57m   v1.31.4-eks-aeac579
     ip-10-0-199-14.ca-central-1.compute.internal    Ready    <none>   7h57m   v1.31.4-eks-aeac579
     ```

     ```bash
     kubectl get pods -A
     ```

     You should get something like:

     ```bash
     NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
     default       nginx-56856bc749-dx6ch             1/1     Running   0          7h56m
     kube-system   aws-node-qgdfx                     2/2     Running   0          7h57m
     kube-system   aws-node-qj8lq                     2/2     Running   0          7h57m
     kube-system   coredns-57d9dcc947-lpnx6           1/1     Running   0          8h
     kube-system   coredns-57d9dcc947-xt7qj           1/1     Running   0          8h
     kube-system   kube-proxy-5r6xk                   1/1     Running   0          7h58m
     kube-system   kube-proxy-9wgcq                   1/1     Running   0          7h58m
     kube-system   metrics-server-75dd96c4f5-7z9fs    1/1     Running   0          7h57m
     kube-system   metrics-server-75dd96c4f5-j9889    1/1     Running   0          7h57m
     tailscale     operator-6999975fd7-2wg78          1/1     Running   0          7h56m
     tailscale     ts-kb-demo-cluster-cidrs-xmwmd-0   1/1     Running   0          6h23m
     ```

   - Check the `nginx` service in the `default` namespace:

     ```bash
     kubectl get svc nginx -ndefault
     ```

     You should see something like:

     ```bash
     NAME    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
     nginx   ClusterIP   10.40.160.130   <none>        80/TCP    8h
     ```

2. Open up the Tailscale Admin portal:
   - Click on `Machines` at the top. You should see a machine entry for `tailscale-operator`, one for `<clustername>-cluster-cidrs` and finally one for the EC2 client instance `<hostname>`. All should have the `tag: k8s-operator` and say that they are `Connected` under the `Last Seen` column indicating they have all successfully joined the tailnet.

   - Furthermore, the `<clustername>-cluster-cidrs` should show that it is advertising subnets with the `Subnets` label under the machine name  in blue.

   - Click on each machine and check their characteristics. Check the `<clustername>-cluster-cidrs` machine reflects the routes that you intended to advertise (10.0.0.0/16 and 10.40.0.0/16 in this example).

   - Go to `DNS` at the top, and scroll to find under `Nameservers` that there is a SplitDNS entry for the search domain `svc.cluster.local` to the `ClusterIP` of the `kube-dns` service of the cluster.

3. SSH to the EC2 instance using the public-IP shown in the completed output of the `terraform apply` command:

   ```bash
   ssh -i /path/to/my-private-keypair ubuntu@<public-IP>
   ```

   - Try to do a `tailscale status` to show the devices connected to the tailnet and do a `tailscale ping` to the subnet router pod in the cluster.

     ```bash
     tailscale status
     ```

     gives us something like:

     ```bash
     100.126.233.38  ubuntu-client        ubuntu-client.tailabc79e.ts.net linux   -
     100.113.238.21  kb-demo-cluster-cidrs tagged-devices linux   idle, tx 3884 rx 3684
     100.100.42.81   tailscale-operator   tagged-devices linux   -
     ```
     Now do a ```tailscale ping``` to the cluster from the EC2 instance     
     
     ```bash
     tailscale ping kb-demo-cluster-cidrs
     ```

     ```bash
     pong from kb-demo-cluster-cidrs (100.113.238.21) via DERP(tor) in 17ms
     pong from kb-demo-cluster-cidrs (100.113.238.21) via DERP(tor) in 18ms
     pong from kb-demo-cluster-cidrs (100.113.238.21) via DERP(tor) in 17ms
     pong from kb-demo-cluster-cidrs (100.113.238.21) via DERP(tor) in 18ms
     pong from kb-demo-cluster-cidrs (100.113.238.21) via 10.0.202.15:35792 in 1ms
     ```

     Here we should see a few ```pongs``` from the DERP servers before a direct connection is established. This is because even though the EKS cluster is going through a NAT gateway, we opened up the security group within the VPC which is also where the EC2 instance is residing, and the EC2 instance can effectively present itself on `UDP 41641` as `No-NAT` thus leading to an `Easy NAT` situation where the EKS side is a `Hard NAT` but the EC2 instance side is `No-NAT`.

## Connectivity Testing

1. While in the SSH session of the EC2 client instance:
   - Make a curl request to the `nginx` `ClusterIP` service by its Kubernetes service FQDN `nginx.default.svc.cluster.local` . This should succeed with a `HTTP1.1 200 OK` showing connectivity to the service.

     ```bash
     curl -I -m2 http://nginx.default.svc.cluster.local
     ```

     gives us something like:

     ```bash
     HTTP/1.1 200 OK
     Server: nginx/1.27.3
     Date: Mon, 27 Jan 2025 09:39:22 GMT
     Content-Type: text/plain
     Content-Length: 12
     Connection: keep-alive
     ```
  
   - The `nginx` pod's logs can also be checked as it currently logs the client source-IP of the incoming request. Here we see that the source-IP of the request is actually getting SNAT'd to the subnet router pod's IP, which is expected behaviour from a subnet router.

     ```bash
     kubectl get pods -ntailscale -owide | grep cluster-cidrs
     ```

     gives something like:

     ```bash
     ts-kb-demo-cluster-cidrs-xmwmd-0   1/1     Running   0          7h5m   10.0.202.15    ip-10-0-199-14.ca-central-1.compute.internal   <none>           <none>
     ```

     Now dump the logs of the `nginx` pod:

     ```bash
     kubectl logs $(kubectl get pods -o jsonpath='{.items[?(@.metadata.labels.app=="nginx")].metadata.name}')
     ```

     This gives us some pod logs like:

     ```bash
     10.0.202.15 - - [27/Jan/2025:02:48:50 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.81.0"
     10.0.202.15 - - [27/Jan/2025:09:39:22 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.81.0
     ```

     which matches the pod IP of the subnet router pod.

2. We can also modify the `Connector` Custom Resource object that governs the subnet routes and delete the cluster service CIDR prefix from it to make it stop advertising that service CIDR (10.40.0.0/16 in our example):

   - Once we do that, we can see that the ```curl``` request can no longer even resolve to the service FQDN as it cannot reach the `kube-dns` service on the cluster svc CIDR address that we just deleted and thus the request fails to resolve DNS

     ```bash
     curl -v -I -m2 http://nginx.default.svc.cluster.local
     ```

     now gives us something like:

     ```bash
     * Resolving timed out after 2000 milliseconds
     * Closing connection 0
     curl: (28) Resolving timed out after 2000 milliseconds
     ```

[:arrow_right: Section 5 - Cleanup](section-5-cleanup.md)  
[:arrow_left: Section 3 - Terraform Setup and Deploy](section-3-terraform-setup.md)

[:leftwards_arrow_with_hook: Back to Main](../README.md)
