#!/bin/bash
set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Get repository root
REPO_ROOT="$(get_repo_root)"

# Load configuration
load_cluster_config

# Set paths
TALOSCONFIG="${REPO_ROOT}/talos/configs/talosconfig"
KUBECONFIG="${REPO_ROOT}/talos/configs/kubeconfig"

# First control plane is the bootstrap node
CONTROL_PLANE_1="${CONTROLPLANE_IPS[0]}"

echo "Bootstrapping the first control plane-node"
talosctl --talosconfig $TALOSCONFIG bootstrap --nodes $CONTROL_PLANE_1 --endpoints $CONTROL_PLANE_1 

echo "Checking that all nodes are ready"

for ip in "${CONTROLPLANE_IPS[@]}"; do
  echo "Waiting for control plane ${ip} to be ready..."
  timeout 600 bash -c "until talosctl --talosconfig $TALOSCONFIG health --nodes ${ip} --endpoints ${CONTROLPLANE_IPS[0]} | grep -q 'ready'; do echo -n '.'; sleep 10; done"
  echo "Control plane ${ip} is ready"
done

for ip in "${WORKER_IPS[@]}"; do
  echo "Waiting for worker ${ip} to be ready..."
  timeout 600 bash -c "until talosctl --talosconfig $TALOSCONFIG health --nodes ${ip} --endpoints ${CONTROLPLANE_IPS[0]} | grep -q 'ready'; do echo -n '.'; sleep 10; done"
  echo "Worker ${ip} is ready"
done

echo "All nodes are ready"

echo "Using Talos version: ${TALOS_VERSION}"
echo "Bootstrapping control plane at ${CONTROL_PLANE_1}..."



echo "Waiting for the Kubernetes API server to be available..."
timeout 300 bash -c "until talosctl --talosconfig $TALOSCONFIG health --nodes $CONTROL_PLANE_1 | grep -q 'ready' || talosctl --talosconfig $TALOSCONFIG service kube-apiserver --nodes $CONTROL_PLANE_1 | grep -q 'Running'; do echo -n '.'; sleep 10; done"
echo -e "\nKubernetes API server is available!"

# Get kubeconfig
echo "Retrieving kubeconfig..."
talosctl --talosconfig $TALOSCONFIG kubeconfig --nodes $CONTROL_PLANE_1 "${KUBECONFIG}"

# Install and configure Flux (if applicable)
if [[ -n "${GIT_REPO_OWNER:-}" && -n "${GIT_REPO_REPOSITORY:-}" ]]; then
  echo "Installing Flux..."
  export KUBECONFIG="${KUBECONFIG}"
  flux bootstrap github \
    --personal \
    --token-auth \
    --owner="${GIT_REPO_OWNER}" \
    --repository="${GIT_REPO_REPOSITORY}" \
    --path=kubernetes/clusters/${ENVIRONMENT} 
fi

echo "Cluster setup complete!"
echo "You can now use kubectl with: export KUBECONFIG=${KUBECONFIG}"
