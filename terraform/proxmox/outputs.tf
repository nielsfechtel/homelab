output "control_plane_info" {
  value = [
    for i, node in proxmox_vm_qemu.talos_control_plane : {
      name      = node.name
      node_host = node.target_node
      ip        = local.cluster_config.controlPlanes.ips[i]
    }
  ]
  sensitive = true
}

output "worker_info" {
  value = [
    for i, node in proxmox_vm_qemu.talos_worker : {
      name      = node.name
      node_host = node.target_node
      ip        = local.cluster_config.workers.ips[i]
    }
  ]
  sensitive = true
}

output "cluster_endpoint" {
  value = "https://${local.cluster_config.controlPlanes.ips[0]}:6443"
  sensitive = true
}

output "environment" {
  value = local.cluster_config.environment
  sensitive = true
}
