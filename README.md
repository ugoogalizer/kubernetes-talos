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
- [Argo CD ](https://argo-cd.readthedocs.io/en/stable/) for cluster bootstrapping
- [Metallb](https://metallb.io/) for L2 loadbalancing
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx) for ingress (yeah I still need to learn about the gateway-api). Also not to be confused with `nginx-ingress` a similar but different ingress extension
- [cert-manager](https://cert-manager.io/) to manage certificates, in particular provision valid HTTPS certificates.
- [external-secrets](https://external-secrets.io/latest/) and [bitwarden-sdk-server](https://github.com/external-secrets/bitwarden-sdk-server)to connect to the cloud instance of Bitwarden Secrets Manager for secrets storage and dynamic sync into the cluster. Only needs to be unlocked once at the start. Relies on cert-manager to create a self-signed certificate in order to allow the bitwarden-sdk-server to function.
- [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) to allow for basic storage provisioning

App deployments: 
- "root" sets up some example apps and shows how an app of apps can be deployed in Argocd
- "root-private" points at a personal repo that is setup the same as "root"

Disabled from the original repository
- [Cilium](https://cilium.io) as a kube proxy replacement and sidecar-less networking
- [Rook Ceph](https://rook.io) for stateful replicated storage for all nodes
- [Velero](https://velero.io) for offsite cluster backup


## Basic steps: 

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


# Troubleshooting

If you have issues with argocd, and need to downgrade it / uninstall it, this guide was good to remove the finalizers:  https://phalanx.lsst.io/applications/argocd/upgrade.html#recovering-from-a-botched-upgrade
