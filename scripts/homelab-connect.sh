#!/bin/bash
set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

# Get repository root
REPO_ROOT="$(get_repo_root)"

# Load configuration
load_cluster_config

# Get count of hosts
HOST_COUNT=$(get_physical_host_count)

# Check if we're already in a tmux session
if [ -n "$TMUX" ]; then
  # We're in a tmux session, create a new window
  tmux new-window -n homelab
else
  # We're not in tmux, create a new session
  tmux new-session -d -s homelab
fi

# Create panes for each host (except the first one, which already has a pane)
for ((i=1; i<HOST_COUNT; i++)); do
  if [ $((i % 2)) -eq 1 ]; then
    tmux split-window -h
  else
    tmux split-window -v
  fi
done

# Connect to each host in its own pane
for ((i=0; i<HOST_COUNT; i++)); do
  tmux select-pane -t $i
  CONNECTION=$(get_host_connection $i)
  tmux send-keys "ssh $CONNECTION" C-m
done

# If we created a new session, attach to it
if [ -z "$TMUX" ]; then
  tmux attach-session -t homelab
fi
