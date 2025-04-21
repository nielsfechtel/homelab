# Configure the Proxmox provider
provider "proxmox" {
  pm_api_url = local.proxmox_api_url
  pm_api_token_id = local.proxmox_token_id
  pm_api_token_secret = local.proxmox_api_token

  # Skip TLS verification
  # remove this in production environments
  pm_tls_insecure = true
}
