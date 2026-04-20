

Install some basics to be able to interact with container images etc
``` bash
sudo apt install bind9-dnsutils
sudo apt update
sudo apt install docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker ${USER}

```

``` bash
sudo apt install unzip jq

# Install the bitwarden secrets manager cli
# https://github.com/bitwarden/sdk-sm/tree/main/crates/bws
curl https://bws.bitwarden.com/install | sh

#Install Helm
cd ~
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
# curl -LO https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz #find the latest here: https://github.com/helm/helm/releases

```


Installing the talosctl and managing the cluster from an Ubuntu 24.04 instance running in Windows Subsystem for Linux (WSL)
Inside WSL
``` bash
#install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /home/green/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> /home/green/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
sudo apt-get install build-essential

#install talosctl if installing latest:
brew install siderolabs/tap/talosctl@v1.11.2 # ideally install v1.11.2 to match cluster version

# install talosctl if installing a specific version: 
curl -LO https://github.com/siderolabs/talos/releases/download/v1.11.2/talosctl-linux-amd64
chmod +x talosctl-linux-amd64
sudo mv talosctl-linux-amd64 /usr/local/bin/talosctl
talosctl version

#Check this resolves: 
nslookup talos-gpu.rockyroad.rocks

#Load the bitwarden access token (but not store it in history)
set +o history
export BWS_ACCESS_TOKEN=<MACHINE_TOKEN>
set -o history

cd ~
git clone https://github.com/ugoogalizer/kubernetes-talos.git
cd ~/kubernetes-talos/provision/talos
./generate.sh

#Test it works: 
talosctl -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig get rd

#Now get the kubeconfig: 
talosctl kubeconfig ~/.kube/config -e 10.20.8.62 -n 10.20.8.62 --talosconfig=./talosconfig
#talosctl -e 10.20.8.62 -n 10.20.8.62 dashboard --talosconfig=./talosconfig

# Install kubectl (you need to use the same version as the kubernetes cluster - this is shown from the above dashboard command)
cd ~
curl -LO "https://dl.k8s.io/release/v1.34.1/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
kubectl version

#Test the kubeconfig works
```