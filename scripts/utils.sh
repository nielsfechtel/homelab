#!/bin/bash
set -euo pipefail

# Common utility functions for homelab scripts

declare -g config_content

# Gets the repository root directory
get_repo_root() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  echo "$(cd "${script_dir}/.." && pwd)"
}

# Parse and decrypt the cluster config file
load_cluster_config() {
  local repo_root="$(get_repo_root)"
  local config_file="${repo_root}/config/cluster_config.yaml"
  
  # Set the global config_content variable
  config_content=$(sops --decrypt "$config_file")

  # Parse configuration from content
  export CLUSTER_NAME=$(echo "$config_content" | yq -r '.clusterName')
  export TALOS_VERSION=$(echo "$config_content" | yq -r '.talosVersion')
  export ENVIRONMENT=$(echo "$config_content" | yq -r '.environment')
  export CONTROL_PLANE_COUNT=$(echo "$config_content" | yq -r '.controlPlanes.count')
  export WORKER_COUNT=$(echo "$config_content" | yq -r '.workers.count')
  export GIT_REPO_OWNER=$(echo "$config_content" | yq -r '.gitRepo.owner')
  export GIT_REPO_REPOSITORY=$(echo "$config_content" | yq -r '.gitRepo.repository')

  export INSTALL_ISO_PATH=$(echo "$config_content" | yq -r '.installIsoPath')
  local nfs_user=$(echo "$config_content" | yq -r '.physicalHosts[1].username')
  local nfs_ip=$(echo "$config_content" | yq -r '.physicalHosts[1].ip')
  # The ':' in the NFS-format-path Proxmox expects needs to be substituted with a '/'
  local nfs_folder_path="/mnt/pve/$(echo "${INSTALL_ISO_PATH}" | sed 's/:/\/template\//')"
  export SCP_CONNECTION_STRING="${nfs_user}@${nfs_ip}"
  
  # Parse node IPs
  CONTROLPLANE_IPS=()
  for i in $(seq 0 $(($CONTROL_PLANE_COUNT-1))); do
    CONTROLPLANE_IPS+=($(echo "$config_content" | yq -r ".controlPlanes.ips[$i]"))
  done
  export CONTROLPLANE_IPS
  
  WORKER_IPS=()
  for i in $(seq 0 $(($WORKER_COUNT-1))); do
    WORKER_IPS+=($(echo "$config_content" | yq -r ".workers.ips[$i]"))
  done
  export WORKER_IPS
  
  # Set derived variables
  export ENDPOINT="${CONTROLPLANE_IPS[0]}"
}
