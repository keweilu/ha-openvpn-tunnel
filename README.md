# HA OpenVPN Tunnel
Highly Available OpenVPN Tunnel (HAOT) facilitates creating a secure highly available network bridge between AWS and services running in other cloud providers.

## Usage

### Push Images to Docker Registry

#### Push Server Docker Image to Amazon EC2 Container Registry

Suppose the Amazon ECR is created in us-west-1 with name `openvpn-server`, we can use the following commands to push the openvpn server docker image to the ECR repo:

1. Create a `client-config-dir` folder
    ```
    $ mkdir server/ccd
    ```
1. Edit [server.conf](server/server.conf) and add files under `client-config-dir` to add your internal network subnet CIDR blocks. For details, please refer [this](server/server.conf#L118-L130)

1. Retrieve the docker login command that you can use to authenticate your Docker client to your registry:
    ```
    $ $(aws ecr get-login --no-include-email --region us-west-1)
    ```
1. Switch to server folder and build your Docker image using the following command.
    ```
    $ docker build -t openvpn-server .
    ```
1. After the build completes, tag your image so you can push the image to Amazon ECR repository:
    ```
    $ docker tag openvpn-server:latest xxxxxxxxxxxx.dkr.ecr.us-west-1.amazonaws.com/openvpn-server:latest
    ```
1. Run the following command to push this image to the AWS repository:
    ```
    $ docker push xxxxxxxxxxxx.dkr.ecr.us-west-1.amazonaws.com/openvpn-server:latest
    ```

#### Build and Push Client Docker Image to Your Client-side Docker registry

### Server Setup

#### Option 1: Create an EC2 instance and run the docker image by yourself

1. Log in to the AWS EC2 instance on which you want to set up the OpenVPN server, then pull image from your repository on [Amazon ECR](http://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-pull-ecr-image.html):
    ```
    $ $(aws ecr get-login --no-include-email --region us-west-1)
    $ docker pull xxxxxxxxxxxx.dkr.ecr.us-west-1.amazonaws.com/openvpn-server:latest
    ```
1. Start the OpenVPN server
    ```
    $ docker run -it -v {Path-to-certs-directory}:/etc/openvpn/certs:ro --rm --privileged -p 1194:1194/udp --net=host --dns-search=ca-central-1.compute.internal --dns-opt=timeout:2 --dns-opt=attempts:5 xxxxxxxxxxxx.dkr.ecr.us-west-1.amazonaws.com/openvpn-server:latest
    ```
    `Path-to-certs-directory` is the folder which stores the [ca, server certs and diffie hellman parameters](server/server.conf#L64-L88). The `--dns-search` option depends on the region that the EC2 instance is in. If you have your own nameserver, add `--dns=<YOUR OWN NAMESERVER>` to the docker command.

1. Open port 1194 on the EC2 instance

1. Disable `Source/dest.` check

    In order to disable `Source/dest.` check, select the EC2 instance, go to `Actions -> Networking -> Change Source/Dest. Check`, and then disable it

#### Option 2: High-Availability Server Setup

If you want to set up a HA OpenVPN server with monitoring, please refer to this [README](./server/high-availability/README.md) to set up your OpenVPN server instead of using the above option.

### Client Setup
We set up OpenVPN clients on our internal OpenStack VM. You can also run your OpenVPN clients in your internal VMs:

1. Start the OpenVPN client
    ```
    $ docker run -d -v {Path-to-certs-directory}:/etc/openvpn/certs:ro -e SERVER_IP=xxx.xxx.xxx.xxx -e CLIENT_NAME=client1 --rm --privileged --net=host <OpenVPN-client-docker-image>
    ```
    `Path-to-certs-directory` is the folder which stores the [ca and client certs](client/openvpn.conf#L82-L90). The `SERVER_IP` is the IP address of the EC2 instance on which we will deploy the OpenVPN server. The `CLIENT_NAME` is the name of the OpenVPN clients. Your client certs are in the format of `${CLIENT_NAME}.crt` and `${CLIENT_NAME}.key`.

### Configure Routing Table on AWS
In order to make the configuration easier, make sure your EC2 instance which has OpenVPN server deployed and EC2 instances from which you want connect to your internal services are in the same Amazon Virtual Private Cloud(VPC). If they are in the same VPC, make the following changes to the routing table associated with this VPC:

* Add your internal CIDR subnet entries to the route table. Use the instance id of the EC2 instance which runs the OpenVPN server service as the target.

### Add Nameserver

If you have your own Nameserver for you internal services, then:

#### EC2 instances
If you want to allow a EC2 instance to access your internal network, then log in to the EC2 instance, edit `/etc/resolv.conf` file to add your nameserver near the top.

#### Kubernetes Pods
If you want to access internal services from kubernetes pods, in order to do that, simply add a [upstreamNameservers](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/) to the kube-dns configmap:
```
$ kubectl --context cluster-context edit configmap kube-dns --namespace kube-system
```
Then, add upstreamNameservers <YOUR_NAMESERVER> to the configmap.
