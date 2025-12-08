<h1 align="center">
  Infrastructure
</h1>

<p align="center">
  <img height="200" src="./docs/images/talos.svg" alt="Talos">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img height="200" src="./docs/images/kubernetes.svg" alt="Kubernetes">
</p>

This repository includes all of the configuration and documentation for my home lab cluster.

This was taken and customised from https://github.com/btkostner/infrastructure (https://infrastructure.btkostner.io/)


## Features

- [Talos Linux](https://www.talos.dev) cluster with NVMe as a boot drive and SSD for data
- [Talos Backup](https://github.com/siderolabs/talos-backup) a dead simple backup tool for Talos Linux-based Kubernetes clusters to push to s3
- [Argo CD](https://argo-cd.readthedocs.io/en/stable/) for cluster bootstrapping
- [Metallb](https://metallb.io/) for L2 loadbalancing
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx) for ingress (yeah I still need to learn about the gateway-api). Also not to be confused with `nginx-ingress` a similar but different ingress extension
- [cert-manager](https://cert-manager.io/) to manage certificates, in particular provision valid HTTPS certificates.
- [external-secrets](https://external-secrets.io/latest/) and [bitwarden-sdk-server](https://github.com/external-secrets/bitwarden-sdk-server)to connect to the cloud instance of Bitwarden Secrets Manager for secrets storage and dynamic sync into the cluster. Only needs to be unlocked once at the start. Relies on cert-manager to create a self-signed certificate in order to allow the bitwarden-sdk-server to function.
- [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) to allow for basic storage provisioning
- [Talos NVIDIA GPU Extensions](https://www.talos.dev/v1.9/talos-guides/configuration/nvidia-gpu/) Kernel modules and everything required to run GPU workloads within the cluster
- [NVIDIA k8s-device-plugin](https://github.com/NVIDIA/k8s-device-plugin) - advertises GPU stats on nodes that have GPUs
  - [gpu-feature-discovery](https://github.com/NVIDIA/k8s-device-plugin?tab=readme-ov-file#deploying-with-gpu-feature-discovery-for-automatic-node-labels) Installed automatically with the NVIDIA k8s-device-plugin, advertises basic k8s node features.
  - [node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery) Installed automatically with the NVIDIA k8s-device-plugin, advertises basic k8s node features.
- [KubeVirt](https://kubevirt.io/) - Ability to run VMs ontop of K8s in Talos (special guide [here](https://github.com/NVIDIA/k8s-device-plugin)).  Steps included: 
  - [local-path-provisioner](https://www.talos.dev/v1.9/kubernetes-guides/configuration/local-storage/)
  - A NFS-CSI - I believe the nfs-subdir-external-provisioner above is sufficient for this, skipped
- Cilium CNI

## High Level Concepts

1. Setup Talos configuration and form a Talos Cluster
1. Bootstrap k8s cluster (disabling default CNI)
1. Add BitWarden Secrets Manager key to k8s cluster
1. Deploy once the `core` Kustomize manifests.  Deploys the core services the cluster requires, and Argo-cd
1. Install [Cilium](https://cilium.io) as CNI for sidecar-less networking and L2-L7 policy enforcement
1. Argo-cd then automatically deploys the following app deployments
    1. The same `core` manifests from above, ensuring compliance and declarative git-ops from then on of the core cluster services.
    1. "root" found in the `./cluster/apps/root` folder of this repo, and sets up some example apps and shows how an app of apps can be deployed in Argocd
    1. "root-private" points at a personal repo that is setup the same as "root" 
1. NOTE - because there are some operators installed within this cluster, Argo-cd has been told what to ignore, otherwise the Operators and Argo have a fight over state.

Disabled from the original repository
-  as a kube proxy replacement and sidecar-less networking
- [Rook Ceph](https://rook.io) for stateful replicated storage for all nodes
- [Velero](https://velero.io) for offsite cluster backup


## Management Client

``` bash
brew install siderolabs/tap/talosctl
```

see wsl.md for details on how to install the management client within Windows Subsystem for Linux (Ubuntu 24.04)

## DNS

Set up a dns record for talos-gpu.rockyroad.rocks

## Steps to Form Cluster and Bootstrap Argo-CD 

Boot the control pane machine with the specific Talos Linux image (i.e. via USB boot disk)

Make sure it has a statically defined IP address (best with a static DHCP reservation)

``` bash
set +o history
export BWS_ACCESS_TOKEN=<MACHINE_TOKEN>
set -o history

cd ~
git clone https://github.com/ugoogalizer/kubernetes-talos.git
cd ~/kubernetes-talos/provision/talos
./generate.sh

# Now apply the patched configuration file (first time):
talosctl apply-config --insecure -n 10.20.8.62 --file ./controlplane.yaml 

# To apply the patched configuration file (all subsequent times, to update configuration):
talosctl apply-config -e 10.20.8.62 -n 10.20.8.62 --file ./controlplane.yaml --talosconfig=./talosconfig
# To apply the patched configuration file and reboot (all subsequent times, to update configuration):
talosctl apply-config -e 10.20.8.62 -n 10.20.8.62 --file ./controlplane.yaml --talosconfig=./talosconfig --mode=reboot

# Bootstrap the cluster - DO THIS ONLY ONCE
talosctl bootstrap -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig

# Download the kubeconfig (merging in to defaults)
talosctl kubeconfig ~/.kube/config -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig

# Configure BitWarden Token to allow sm-operator to pull from cloud secrets
kubectl create namespace external-secrets
kubectl create secret generic bitwarden-access-token -n external-secrets --from-literal=token="$BWS_ACCESS_TOKEN"
# kubectl get secret bitwarden-access-token -o jsonpath="{.data.token}" -n external-secrets | base64 -d

# Install Core resources
cd ~/kubernetes-talos/provision/core
./install.sh
# NOTE - sometimes cert-manager isn't online fast enough to apply the lot, try again after a few minutes if errors occur.



kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

# Optional steps
Create keys for talos-backup

``` bash
# sudo apt install age -y # https://github.com/FiloSottile/age#installation
age-keygen

```


# Adding Worker Node/s

Boot the machine with the specific Talos Linux image (i.e. via USB boot disk).

Make sure it has a statically defined IP address (best with a static DHCP reservation)

On the management client:
``` bash
cd ~/kubernetes-talos/provision/talos
git pull
# if not already setup on this client, run: 
  # set +o history
  # export BWS_ACCESS_TOKEN=<MACHINE_TOKEN>
  # set -o history
  # ./generate.sh

# some steps to explore the node before configuration is applied: 
talosctl get disk  --insecure  -n 10.20.8.61  # Get disks topology, useful to confirm you're installing to the right disk

# Add node to the cluster:
talosctl apply-config --insecure -n 10.20.8.61 --file ./worker.yaml --talosconfig=./talosconfig # for a generic worker
talosctl apply-config --insecure -n 10.20.8.61 --file ./worker-largeworkload.yaml --talosconfig=./talosconfig # for a worker reserved for large workloads

# Alternatively, if config already applied and you need to update
talosctl apply-config -e 10.20.8.62 -n 10.20.8.61 --file ./worker-largeworkload.yaml --talosconfig=./talosconfig --mode=reboot

# To apply a taint and label: 

kubectl taint nodes maurice workload=LargeWorkload:NoSchedule
kubectl label nodes maurice workload=LargeWorkload
```


# Troubleshooting

If you have issues with argocd, and need to downgrade it / uninstall it, this guide was good to remove the finalizers:  https://phalanx.lsst.io/applications/argocd/upgrade.html#recovering-from-a-botched-upgrade

# Upgrading and/or Installing Extensions

If you need to upgrade the Talos Linux cluster, either in version or adding extensions (such as the NVIDIA extensions) you are supposed to do it via API.  I think this is **really stupid**, because the whole point of Talos was to declaratively define it's state in a configuration file.  Running an API command moves your Talos Configuration out of sync with your configuration files.  So in my case, I tried to ensure my process ensured they stayed in sync by: 
1. go to https://factory.talos.dev/ and select what you want (i.e. newer version / new extensions)
1. Copy the image link (i.e. factory.talos.dev/installer/6698d6f136c5bb37ca8bb8482c9084305084da0a5ead1f4dcae760796f8ab3a2:v1.9.3)
1. Patch it into the machine config at machine.install.image.  
1. commit/pull the patch to your control server with talosctl then run:

``` bash
# Upgrade the configuration file (which seems meaningless)
cd ~/kubernetes-talos/provision/talos
rm talosconfig # the config file doesn't generate if this still exists
./generate.sh
talosctl apply-config -e 10.20.8.62 -n 10.20.8.62 --file ./controlplane.yaml --talosconfig=./talosconfig
# Now actually upgrade the node/s: 
talosctl upgrade -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig --image factory.talos.dev/installer/bf15920e4fb61a67819ed5311e240dde640765ae84840c2c82f71cd6b36b3075:v1.9.3
# Note this actually takes a few minutes before it starts to apply for some reason, be patient (I almost sent a follow up command to tell it to reboot, but then it did reboot all on it's own)
```

# View GPU Workload and stats

``` bash
kubectl create ns temp
kubectl run \
  nvidia-test \
  --restart=Never \
  -ti --rm \
  --namespace temp \
  --image nvcr.io/nvidia/cuda:12.5.0-base-ubuntu22.04 \
  --overrides '{"spec": {"runtimeClassName": "nvidia"}}' \
  nvidia-smi

# kubectl delete ns temp

```

# Useful Talos Commands

``` bash
cd ~/kubernetes-talos/provision/talos
# Stats about the talos cluster itself (can be done before k8s bootstrapping):
talosctl -e 10.20.8.62 -n 10.20.8.62 containers --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get rd
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get disk
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get namespace
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get extensions
 talosctl -e 10.20.8.62 -n 10.20.8.62 read /proc/cpuinfo --talosconfig=./talosconfig

# Explore the cluster: 
talosctl -e 10.20.8.62 -n 10.20.8.62 health --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 dashboard --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 containers -k --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 get securitystate --talosconfig=./talosconfig

# Explore NVIDIA Setup
talosctl -e 10.20.8.62 -n 10.20.8.62 read /proc/modules --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 get pcidevices -n gpu --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 get pcidevices -n gpu 0000:01:00.0 -o yaml --talosconfig=./talosconfig # Change `0000:01:00.0` with the id of your device from the above command
talosctl -e 10.20.8.62 -n 10.20.8.62 get extensions --talosconfig=./talosconfig
talosctl -e 10.20.8.62 -n 10.20.8.62 read /proc/driver/nvidia/version --talosconfig=./talosconfig

# Explore Network
talosctl  -e 10.20.8.62 -n 10.20.8.62 get links  --talosconfig=./talosconfig
talosctl  -e 10.20.8.62 -n 10.20.8.62 get machineconfig -o yaml
talosctl  -e 10.20.8.62 -n 10.20.8.62  exec ip link

# Manually Edit Config
talosctl -e 10.20.8.62  -n 10.20.8.61 edit machineconfig

# Safely power down the Node
talosctl  -e 10.20.8.62 -n 10.20.8.62 shutdown --force # The force skips cordon/drain step, useful in a single node cluster
```

# Basic Containers to test things with: 
``` bash
kubectl create ns temp
kubectl run \
  hello-world \
  --restart=Never \
  -ti --rm \
  --namespace temp \
  --image hello-world:latest 

kubectl run  ubuntu --restart=Never -ti --rm --namespace temp --image ubuntu:latest bash
kubectl run busybox --restart=Never -ti --rm --namespace temp --image busybox:latest sh
kubectl run curl --restart=Never -ti --rm --namespace temp --image curlimages/curl:latest sh
# kubectl delete ns temp
```
