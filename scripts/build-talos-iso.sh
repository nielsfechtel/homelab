#!/bin/bash
set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Get repository root
REPO_ROOT="$(get_repo_root)"

# Load configuration
load_cluster_config

OUT_PATH="${REPO_ROOT}/talos/iso"

VERBOSE=""
while getopts "v" opt; do
  case $opt in
    v)
      VERBOSE="-v"
      ;;
    *)
      echo "Usage: $0 [-v]"
      exit 1
      ;;
  esac
done

# Build the iso with system extensions required by Longhorn,
# see https://longhorn.io/docs/1.8.1/advanced-resources/os-distro-specific/talos-linux-support
# Get system extension URLs for Talos Version X
ISCSI_TOOLS_URL=$(crane export ghcr.io/siderolabs/extensions:v${TALOS_VERSION} | tar x -O image-digests | grep -E 'siderolabs/iscsi-tools')
UTIL_LINUX_TOOLS_URL=$(crane export ghcr.io/siderolabs/extensions:v${TALOS_VERSION} | tar x -O image-digests | grep -E 'siderolabs/util-linux-tools')

echo "For Talos version ${TALOS_VERSION}, found extension URLs:"
echo ${ISCSI_TOOLS_URL}
echo ${UTIL_LINUX_TOOLS_URL}

docker run --rm \
  --volume "${OUT_PATH}:/out" \
  --privileged ghcr.io/siderolabs/imager:v1.10.0 iso \
  --system-extension-image "${ISCSI_TOOLS_URL}" \
  --system-extension-image "${UTIL_LINUX_TOOLS_URL}"

echo "Uploading custom Talos ISO to Proxmox NFS storage...Have sudo-password ready"

# Disable host key checking - this is a trusted network environment
# Otherwise scp might hold up the script by asking if the host key should
# be added, if it's the first time connecting from this devcontainer
scp $VERBOSE -o StrictHostKeyChecking=no -o BatchMode=yes "${OUT_PATH}/metal-amd64.iso" "${SCP_CONNECTION_STRING}:/tmp/"
# Use -tt to force SSH to allocate a TTY, so it can ask for sudo-password
ssh -tt $VERBOSE "${SCP_CONNECTION_STRING}" "sudo mv /tmp/metal-amd64.iso /mnt/pve/iso-nfs/template/iso/"

if [ $? -eq 0 ]; then
  echo "Upload complete."
elif [ $? -eq 124 ]; then
  echo "Upload timed out! Check connectivity to the destination host."
  exit 1
else
  echo "Upload failed!"
  exit 1
fi
