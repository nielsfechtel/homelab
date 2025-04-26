#!/bin/bash
set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Get repository root and load configuration
REPO_ROOT="$(get_repo_root)"
load_cluster_config

CONFIGS_DIR="${REPO_ROOT}/talos/configs"

echo "Using Talos version: ${TALOS_VERSION}"

# Apply configurations to control planes
for i in "${!CONTROLPLANE_IPS[@]}"; do
  NODE_IP="${CONTROLPLANE_IPS[$i]}"
  CONFIG_FILE="${CONFIGS_DIR}/controlplane.yaml"
  
  echo -n "Waiting for Talos on ${NODE_IP}:50000"
  timeout 300 bash -c "until nc -z ${NODE_IP} 50000; do echo -n '.'; sleep 5; done"
  echo -e "\nTalos API is reachable on ${NODE_IP}"

  echo -e "\nApplying configuration to control plane $((i + 1)) (${NODE_IP})..."
  
  # Apply the configuration without patch
  talosctl apply-config \
    --insecure \
    --nodes ${NODE_IP} \
    --file ${CONFIG_FILE}
    
  echo "Configuration applied to control plane $((i + 1))"
done

# Apply configurations to workers
for i in "${!WORKER_IPS[@]}"; do
  NODE_IP="${WORKER_IPS[$i]}"
  CONFIG_FILE="${CONFIGS_DIR}/worker.yaml"
  
  echo -n "Waiting for Talos on ${NODE_IP}:50000"
  timeout 300 bash -c "until nc -z ${NODE_IP} 50000; do echo -n '.'; sleep 5; done"
  echo -e "\nTalos API is reachable on ${NODE_IP}"

  echo -e "\nApplying configuration to worker $((i + 1)) (${NODE_IP})..."
  
  # Apply the configuration without patch
  talosctl apply-config \
    --insecure \
    --nodes ${NODE_IP} \
    --file ${CONFIG_FILE}
    
  echo "Configuration applied to worker $((i + 1))"
done

echo "All configurations applied!"
echo "Next, run bootstrap-cluster.sh to initialize the Kubernetes cluster"
