```
  _    _                      _       _     
 | |  | |                    | |     | |    
 | |__| | ___  _ __ ___   ___| | __ _| |__  
 |  __  |/ _ \| '_ ` _ \ / _ \ |/ _` | '_ \ 
 | |  | | (_) | | | | | |  __/ | (_| | |_) |
 |_|  |_|\___/|_| |_| |_|\___|_|\__,_|_.__/ 
```                                         
# Homelab                              
My basic homelab-setup. 
Utilizes Kubernetes on [k3s](https://github.com/k3s-io/k3s) with a [Flux](https://fluxcd.io/)-GitOps-flow. 

Current applications are:
- Monitoring via [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- Bookmark manager via [Linkding](https://github.com/sissbruecker/linkding)
- Audiobook-library via [Audiobookshelf](https://github.com/advplyr/audiobookshelf)
- Automatic update-pull requests for
  - app-updates via [renovate](https://github.com/renovatebot/renovate)
  - flux-updates via [this action](https://github.com/nielsfechtel/homelab/blob/a5527e38c8f55acba4f6c6ef422981d7bd0633ed/.github/workflows/update-flux.yaml)
- Cloudflare tunnels

## Hardware
Currently running on one old laptop. 

## Todo
- [ ] Add backup-procedures
- [ ] Add website(s)
- [ ] Understand and configure Prometheus, Grafana, etc.
- [ ] Add certificates

## Credits
- created with and inspired by [Mischa van den Burg's homelab-repo and -course](https://github.com/mischavandenburg/homelab)
