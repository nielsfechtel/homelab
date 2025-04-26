#!/bin/bash
set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Get repository root and load configuration
REPO_ROOT="$(get_repo_root)"
load_cluster_config

# API endpoint is the IP of the first control plane node
ENDPOINT="${CONTROLPLANE_IPS[0]}"

echo "Generating Talos configurations for ${CLUSTER_NAME} with Talos ${TALOS_VERSION}..."
echo "API endpoint: https://${ENDPOINT}:6443"

# Generate the Talos config files for control plane and worker nodes
# Patch to use /dev/vda instead of default /dev/sda, see
# https://www.talos.dev/v1.9/talos-guides/configuration/patching/#configuration-patching-with-talosctl-cli
talosctl gen config "$CLUSTER_NAME" "https://${ENDPOINT}:6443" \
  --output-dir "${REPO_ROOT}/talos/configs" \
  --config-patch '[{"op": "replace", "path": "/machine/install/disk", "value": "/dev/vda"}]' 

echo "Configuration files created"
echo "Run 'terraform apply' to create VMs, then 'apply-talos-configs.sh' to configure them"
