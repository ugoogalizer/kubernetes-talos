#!/usr/bin/env bash

set -e

KUBE_CONTEXT="admin@talos-gpu"

echo "=== Installing CRDs"

kubectl kustomize "$(dirname "$0")/../../cluster/crds/" --enable-helm | kubectl --context "$KUBE_CONTEXT" apply -f -

echo "=== Installing Core Resources"

kubectl kustomize "$(dirname "$0")/../../cluster/core/" --enable-helm | kubectl --context "$KUBE_CONTEXT" apply -f -

# To delete something 
# kubectl kustomize "../../cluster/core/bitwarden/sm-operator" --enable-helm | kubectl --context "$KUBE_CONTEXT" delete -f -
