# Only keep variables that aren't in cluster_config.yaml

variable "install_iso" {
  description = "The ISO file to use (Talos OS bare-metal)"
  type        = string
  default     = "local:iso/metal-amd64.iso"
}
