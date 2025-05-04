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
# Patch to use /dev/vda instead of default /dev/sda, see
# https://www.talos.dev/v1.9/talos-guides/configuration/patching/#configuration-patching-with-talosctl-cli
patch_disk='{"op": "replace", "path": "/machine/install/disk", "value": "/dev/vda"}'
# As specified in https://longhorn.io/docs/1.8.1/advanced-resources/os-distro-specific/talos-linux-support/#data-path-mounts
patch_longhorn='{"op": "replace", "path": "/machine/kubelet/extraMounts", "value": [ { "destination": "/var/lib/longhorn", "type": "bind", "source": "/var/lib/longhorn", "options": [ "bind", "rshared", "rw" ] } ] }'

talosctl gen config "$CLUSTER_NAME" "https://${ENDPOINT}:6443" \
  --output-dir "${REPO_ROOT}/talos/configs" \
  --config-patch "[${patch_disk}, ${patch_longhorn}]"

# Adjust local talosconfig to include endpoint- and node-IPs (array to whitespace-separated list)
talosctl config endpoints $(IFS=" "; echo "${CONTROLPLANE_IPS[*]}")
talosctl config nodes $(IFS=" "; echo "${WORKER_IPS[*]}")

echo "Configuration files created"
echo "Run 'terraform apply' to create VMs, then 'apply-talos-configs.sh' to configure them"
