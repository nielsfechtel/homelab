```
  _    _                      _       _
 | |  | |                    | |     | |
 | |__| | ___  _ __ ___   ___| | __ _| |__
 |  __  |/ _ \| '_ ` _ \ / _ \ |/ _` | '_ \
 | |  | | (_) | | | | | |  __/ | (_| | |_) |
 |_|  |_|\___/|_| |_| |_|\___|_|\__,_|_.__/
```

My homelab setup using Infrastructure-as-Code principles to deploy a Kubernetes cluster on Talos VMs, provisioned with Terraform on a local Proxmox-cluster.

## Applications
Current applications running in the homelab:

- [GenIma webapp](https://github.com/nielsfechtel/genima) - AI image generation application
- Monitoring stack with [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Linkding](https://github.com/sissbruecker/linkding) - Bookmark management system
- [Audiobookshelf](https://github.com/advplyr/audiobookshelf) - Self-hosted audiobook library
- Automatic updates via [Renovate](https://github.com/renovatebot/renovate) and GitHub Actions

## Roadmap/Todo
- [ ] Add highly available storage so the services relying on it can actually start (looking at Longhorn)
- [ ] Upgrade to [Talos 1.10](https://github.com/siderolabs/talos/releases/tag/v1.10.0)
- [ ] Add monitoring and alerts for cluster, applications and in Proxmox for the VMs
- [ ] Implement proper backup solution for cluster state and application data - via Longhorn
- [ ] Add CI/CD pipeline for infrastructure validation
- [ ] Implement (=> document) disaster recovery procedures

## Hardware Configuration
The cluster runs on a mix of old repurposed hardware with essentially minimum values, because the machines are rather old:
| Node           | VMs                    | CPU     | RAM    | Disk      |
| -------------- | ---------------------- | ------- | ------ | --------- |
| machine 1      | Control Plane + Worker | 1 core  | 1536MB | 20G + 30G |
| machine 2      | Control Plane + Worker | 2 cores | 2048MB | 20G + 60G |
| machine 3      | Worker                 | 1 core  | 1024MB | 30G       |
| machine 4      | Control Plane          | 1 core  | 1536MB | 20G       |

## Setup and Deployment
The devcontainer needs to be used, ensuring all required cli-tools are available. 

The `scripts/utils.sh`-script is used to decrypt and extract values required from the config.

### Steps to deploy:
- Check/update `config/cluster_config.yaml` - contains specific network and VM configuration
    - To decrypt, make sure the private age-key is in the location defined in the devcontainer-mount, so sops can automatically pick it up, then `sops <file>` to open file in defined editor or `sops --decrypt --in-place <file>` (remember to encrypt again)
    - Add metal-Talos OS-iso to Proxmox storage (defined in config)
    - Add static DHCP-addresses in router-interface for the MAC-addresses defined in the config
- Use `scripts/create-talos-configs.sh` to create talos-related files
- Go into `terraform/proxmox` and use `terraform init` and `terraform plan` to init & check changes, then `terraform apply` to create the VMs
- Use `scripts/apply-talos-configs.sh` to apply the configs to the machines
- For Flux bootstrapping: have a GitHub Fine-grained access token with the permissions Read in Administration and Metadata, as well as Read and Write in Code and Secrets, ready to paste (alternatively add value in GITHUB_TOKEN-env-var)
- Use `scripts/bootstrap-cluster.sh` to bootstrap the first control plane, then setup Flux
- Add private age-key as a secret in the cluster: `kubectl create secret generic --namespace flux-system sops-age --from-literal=age.agekey=<VALUE>`

### Steps to tear down:
- Go into `terraform/proxmox` and use `terraform destroy` to delete the VMs

## Security
This repository uses [SOPS](https://github.com/mozilla/sops) with [Age](https://github.com/FiloSottile/age) for encrypting sensitive configuration values while allowing them to be checked into git. Right now, the age-key needs to be added manually again if the whole kubernetes-cluster goes down.

External access to the services is secured via Cloudflare tunnels and Cloudflare Zero Trust Access policies.

### What is encrypted
- Config-file in `config/cluster_config.yaml`
- Terraform-secrets
- Kubernetes-secrets

## Acknowledgments
- Created with and inspired by [Mischa van den Burg's homelab-repo and -course](https://github.com/mischavandenburg/homelab)
