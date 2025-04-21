data "sops_file" "secrets" {
  source_file = "tfsecrets.yaml"
}

locals {
  proxmox_api_url = data.sops_file.secrets.data["proxmox.api_url"]
  proxmox_token_id = data.sops_file.secrets.data["proxmox.token_id"]
  proxmox_api_token = data.sops_file.secrets.data["proxmox.api_token"]
}
