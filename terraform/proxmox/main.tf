 data "sops_file" "cluster_config" {
  source_file = "${path.module}/../../config/cluster_config.yaml"
}

locals {
  cluster_config = yamldecode(data.sops_file.cluster_config.raw) 

  # Extract values from configuration
  control_plane_count = local.cluster_config.controlPlanes.count
  worker_count = local.cluster_config.workers.count
  talos_version = local.cluster_config.talosVersion

  # Ensure profiles are correctly processed as a list of objects
  control_plane_profiles = local.cluster_config.controlPlanes.profiles
  worker_profiles = local.cluster_config.workers.profiles

  # MAC address base
  base_mac = "DE:AD:BE:EF"

  # Generate control plane MACs
  control_plane_macs = [
    for idx in range(local.control_plane_count) :
    format("${local.base_mac}:%02X:%02X", 0, idx)
  ]

  # Generate worker MACs
  worker_macs = [
    for idx in range(local.worker_count) :
    format("${local.base_mac}:%02X:%02X", 1, idx)
  ]
}

resource "proxmox_vm_qemu" "talos_control_plane" {
  count = local.control_plane_count

  # VM name and node assignment
  name = "talos-control-plane-${count.index + 1}"
  target_node = local.control_plane_profiles[count.index].node
  tags = "kubernetes,talos_control-plane"
  desc = "Control plane node for the kubernetes cluster"

  # Installation media
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = var.install_iso
        }
      }
      scsi1 {
        # Storage configuration
        disk {
          size = local.control_plane_profiles[count.index].disk_size
          storage = local.cluster_config.storage.vmDiskStorage
        }
      }
    }
  }

  # use specific cpu-features of the machine
  cpu_type = "host"

  # auto-boot
  onboot = true

  # Allow reclaiming of some memory if unused
  balloon = 512

  # Set OS type to allow Proxmox to optimize
  os_type = "linux"

  # Set boot-order - first the scsi-disk 0, then net0 (PXE boot)
  boot = "order=scsi0;net0"

  # Resource allocation based on the profile
  cores = local.control_plane_profiles[count.index].cores
  sockets = 1
  memory = local.control_plane_profiles[count.index].memory

  # Network configuration
  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }
}

resource "proxmox_vm_qemu" "talos_worker" {
  count = local.worker_count

  # VM name and node assignment
  name = "talos-worker-${count.index + 1}"
  target_node = local.worker_profiles[count.index].node
  tags = "kubernetes,talos_worker"
  desc = "Worker node for the Kubernetes cluster"

  # Installation media
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = var.install_iso
        }
      }
      scsi1 {
        # Storage configuration
        disk {
          size = local.worker_profiles[count.index].disk_size
          storage = local.cluster_config.storage.vmDiskStorage
        }
      }
    }
  }

  # use specific cpu-features of the machine
  cpu_type = "host"

  # auto-boot
  onboot = true

  # Allow reclaiming of some memory if unused
  balloon = 512

  # Set OS type to allow Proxmox to optimize
  os_type = "linux"

  # Set boot-order - first the scsi-disk 0, then net0 (PXE boot)
  boot = "order=scsi0;net0"

  # Resource allocation based on the profile
  cores = local.worker_profiles[count.index].cores
  sockets = 1
  memory = local.worker_profiles[count.index].memory

  # Network configuration
  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }
}

# After the VMs have been created, execute the apply-configs and bootstrap scripts
resource "null_resource" "bootstrap_talos" {
  depends_on = [
    proxmox_vm_qemu.talos_control_plane,
    proxmox_vm_qemu.talos_worker
  ]
  
  # The provisioner will run the required scripts in sequence
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting 60 seconds for VMs to boot completely..."
      sleep 60
      ${path.root}/../../scripts/apply-talos-configs.sh && ${path.root}/../../scripts/bootstrap-cluster.sh
    EOT
    working_dir = path.root
  }
}
