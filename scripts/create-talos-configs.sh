#!/bin/bash
set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Get repository root and load configuration
REPO_ROOT="$(get_repo_root)"
load_cluster_config

echo "Generating Talos configurations for ${CLUSTER_NAME}..."
echo "API endpoint: https://${ENDPOINT}:6443"

# Generate the Talos config files for control plane and worker nodes
# As specified in https://longhorn.io/docs/1.8.1/advanced-resources/os-distro-specific/talos-linux-support/#data-path-mounts
patch_longhorn='{"op": "replace", "path": "/machine/kubelet/extraMounts", "value": [ { "destination": "/var/lib/longhorn", "type": "bind", "source": "/var/lib/longhorn", "options": [ "bind", "rshared", "rw" ] } ] }'
# get install-image-URL from user
read -p "Paste install-image-url:" install_image_url

# Disk needs to be vda as it's a VM
talosctl gen config "$CLUSTER_NAME-${ENVIRONMENT}" "https://${ENDPOINT}:6443" \
  --output-dir "${REPO_ROOT}/talos/configs" \
  --install-disk "/dev/vda" \
  --config-patch "[${patch_longhorn}]" \
  --install-image="${install_image_url}"

# Adjust local talosconfig to include endpoint- and node-IPs (array to whitespace-separated list)
talosctl config endpoints $(IFS=" "; echo "${CONTROLPLANE_IPS[*]}")
talosctl config nodes $(IFS=" "; echo "${WORKER_IPS[*]}")

echo "Configuration files created"
echo "Run 'terraform apply' to create VMs, then 'apply-talos-configs.sh' to configure them"
