#!/usr/bin/env bash

# Manually authenticate to Bitwarden Secrets Manager first 
# set +o history
# export BWS_ACCESS_TOKEN=<MACHINE_TOKEN>
# set -o history

set -e

# This value is the Bitwarden GUID of the secret containing your Talos secrets yaml. This can be found by running `bws secret list`.
TALOS_SECRETS_YAML=99cafebf-6d45-4193-b02e-b27b01756a48
# If you don't already have one, you can generate a secrets file and then manually upload it as a secret to Bitwarden
# talosctl gen secrets -o secrets.yaml

# This value is the name of the talos cluster
TALOS_CLUSTER_NAME=talos-gpu

# This value is the fixed endpoint for your k8s cluster - you'll need to create DNS records to match
K8S_ENDPOINT=https://talos-gpu.rockyroad.rocks:6443

if [ ! -f "secrets.yaml" ]; then
  echo "=== Pulling secrets from Bitwarden Secrets Manager"

  # op read "op://Infrastructure/Talos Secrets/secrets.yaml" > secrets.yaml
  bws secret get $TALOS_SECRETS_YAML | jq -r .value | sed 's/\\n/\n/g' > secrets.yaml

fi

if [ ! -f "./talosconfig" ]; then
  echo "=== Generating configuration"

  patch_args=""
  for patch in ./patches/*.yaml; do
    echo "Detecting patch file $patch"
    patch_args+=" --config-patch @$patch"
  done

  talosctl gen config $TALOS_CLUSTER_NAME $K8S_ENDPOINT \
    $patch_args \
    --with-secrets secrets.yaml \
    --force

  for patch in ./patches-controlplane/*.yaml; do
    echo "Detecting controlplane patch file $patch"
    talosctl machineconfig patch ./controlplane.yaml --patch @$patch --output controlplane.yaml
  done
fi



echo "=== Copying local talos configuration to primary storage"

cp ./talosconfig ~/.talos/config
