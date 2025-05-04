terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.12"
    }
    sops = {
      source = "carlpett/sops"
      version = "1.2.0"
    }
  }
}
