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
- [Argo CD autopilot](https://argocd-autopilot.readthedocs.io/en/stable/) for cluster bootstrapping
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


# Troubleshooting

If you have issues with argocd, and need to downgrade it / uninstall it, this guide was good to remove the finalizers:  https://phalanx.lsst.io/applications/argocd/upgrade.html#recovering-from-a-botched-upgrade
