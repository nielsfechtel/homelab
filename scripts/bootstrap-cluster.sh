#!/bin/bash
set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Get repository root
REPO_ROOT="$(get_repo_root)"

# Load configuration
load_cluster_config

# First control plane is the bootstrap node
CONTROL_PLANE_1="${CONTROLPLANE_IPS[0]}"

echo -n "Waiting for machine to be reachable on port 50000 (reboot complete)"
timeout 300 bash -c "until nc -z ${CONTROL_PLANE_1} 50000; do echo -n '.'; sleep 5; done"
sleep 5
echo -e "\nTalos API is reachable on ${CONTROL_PLANE_1}"

echo "Bootstrapping the first control plane-node"
talosctl bootstrap --nodes $CONTROL_PLANE_1 --endpoints $CONTROL_PLANE_1 
echo "Sleeping 1 minute, giving node time to configure"
sleep 30

echo "Retrieving kubeconfig..."
talosctl kubeconfig --nodes $CONTROL_PLANE_1 "${REPO_ROOT}/talos/configs/kubeconfig"

echo "Installing Flux..."
flux bootstrap github \
  --personal \
  --token-auth \
  --owner="${GIT_REPO_OWNER}" \
  --repository="${GIT_REPO_REPOSITORY}" \
  --path=kubernetes/clusters/${ENVIRONMENT}

echo "Cluster setup complete!"
