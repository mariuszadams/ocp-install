#!/bin/bash
#https://github.com/mariuszadams/ocp-install
#OCP install prep do322-4.6/pages/ch01s05
VER="4.6.4"
mirror="https://mirror.openshift.com/pub/openshift-v4/clients"
NEXUS=nexus-registry-int.apps.tools-emea160.prod.ole.redhat.com
#NEXUS_NA=nexus-registry-int.apps.tools-na150.prod.ole.redhat.com

### 1. Download and install the oc and openshift-install binaries for the $VER OpenShift version.
curl -O ${mirror}/ocp/4.6.4/openshift-client-linux-${VER}.tar.gz
curl -O ${mirror}/ocp/4.6.4/openshift-install-linux-${VER}.tar.gz
sudo tar -xvf openshift-client-linux-${VER}.tar.gz -C /usr/bin/
sudo tar -xvf openshift-install-linux-${VER}.tar.gz -C /usr/bin/

### 2. set completion and verify version
oc completion bash | sudo tee /etc/bash_completion.d/openshift
openshift-install completion bash | sudo tee /etc/bash_completion.d/openshift-install
source /etc/bash_completion.d/openshift
source /etc/bash_completion.d/openshift-install
oc version
openshift-install version

### 3. Create the SSH key for the installation.
ssh-keygen -t rsa -b 4096 -N '' -f .ssh/ocp4upi

### 4. Find the local registry FQDN for the region of your environment - should be 0
curl -s https://$NEXUS -o /dev/null; echo $?

### 5. Obtain a pull secret from console.redhat.com. Replace the credentials for the quay.io registry with the credentials for your local registry.
if [ ! -f ~/pull-secret-oneline.json ]; then 
  echo '[ERROR] Missing ~/pull-secret-oneline.json file!'
  echo Go to https://console.redhat.com/openshift/install/metal/user-provisioned. 
  echo Download pull secret. Then run:
  echo 'python3 -m json.tool Downloads/pull-secret.txt > pull-secret.json'
  echo Edit the pull-secret.json file to replace the credentials for quay.io with the credentials for your local registry.
  echo Check and compact the json:
  echo 'cat pull-secret.json | jq . -c > pull-secret-oneline.json'
  echo You must use the pull-secret-oneline.json file later on to complete the install-config.yaml file.
  exit
fi

### 6. Verify that the credentials stored in the ~/pull-secret-oneline.json file are valid to pull images from the local registry and the registry.redhat.io registry.
sudo yum install podman
sudo podman pull --authfile ~/pull-secret-oneline.json $NEXUS/openshift/ocp4:4.6.4-x86_64
sudo podman pull --authfile ~/pull-secret-oneline.json registry.redhat.io/ubi8/ubi:latest
### Verify that you have pulled the test images correctly.
sudo podman images

### 7. Check DNS config
# Verify that the DNS record of the OpenShift API load balancer is configured to use the environment load balancer IP address
dig api.ocp4.example.com
dig api-int.ocp4.example.com
# Verify that the wildcard DNS record of the OpenShift APP Ingress load balancer is configured to use the LB
dig test.apps.ocp4.example.com
