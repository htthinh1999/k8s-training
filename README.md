# Kubernetes Training on MicroK8s

Hands-on exercises for learning Kubernetes on a local [MicroK8s](https://microk8s.io/) cluster, from basic object management through Kustomize and Helm.

## Prerequisites

- A working MicroK8s installation (`sudo snap install microk8s --classic`), with your user in the `microk8s` group so you can run commands without `sudo`.
- An alias so `kubectl` resolves to MicroK8s' bundled kubectl:

  ```bash
  alias kubectl='microk8s kubectl'
  ```

  All exercises use plain `kubectl` / `helm` in their examples for readability — substitute `microk8s kubectl` / `microk8s helm3` if you haven't set up the aliases.

- Required MicroK8s addons (enable as each exercise needs them; the exercise README will tell you which):

  | Addon | Command | Used for |
  |---|---|---|
  | dns | `microk8s enable dns` | Cluster-internal service discovery |
  | storage (hostpath) | `microk8s enable hostpath-storage` | Dynamic PersistentVolumes for StatefulSets |
  | ingress | `microk8s enable ingress` | Traefik ingress controller ([docs](https://canonical.com/microk8s/docs/addon-ingress)) |
  | metallb | `microk8s enable metallb:<ip-range>` | Real `LoadBalancer` Service IPs on bare metal ([docs](https://canonical.com/microk8s/docs/addon-metallb)) |
  | metrics-server | `microk8s enable metrics-server` | `kubectl top`, HPA bonus exercises |
  | helm3 | `microk8s enable helm3` | Helm exercises (or install standalone `helm` and point `KUBECONFIG` at MicroK8s) |
  | registry | `microk8s enable registry` | Pushing Helm charts / images to a local registry (`localhost:32000`) |

  Check what's enabled at any time with `microk8s status --wait-ready`.

## Repository layout

```
basic/       Core Kubernetes objects and day-to-day operations
advanced/    Kustomize and Helm workflows
```

Each exercise folder follows the same pattern:

```
NN-exercise-name/
  README.md        Objective, background, step-by-step instructions, cleanup
  <source files>    Starter manifests/charts, some with TODOs to fill in
  solution/         Completed, working version — check yourself, don't peek early
```

## Basic track

| # | Exercise | Covers |
|---|---|---|
| 01 | [Pods](basic/01-pods) | Create/inspect/exec/delete a Pod, imperative vs declarative |
| 02 | [Deployments](basic/02-deployments) | Create/update/delete a Deployment, ReplicaSets |
| 03 | [StatefulSets](basic/03-statefulsets) | Stable identity, headless Services, volumeClaimTemplates |
| 04 | [Services](basic/04-services) | ClusterIP, NodePort, and LoadBalancer (via MetalLB), service discovery |
| 05 | [ConfigMaps & Secrets](basic/05-configmaps-secrets) | Inject config/secrets as env vars and volumes |
| 06 | [Scaling](basic/06-scaling) | `kubectl scale`, manual scaling, HPA bonus |
| 07 | [Logs & debugging](basic/07-logs-and-debugging) | `kubectl logs`, `exec`, `describe`, events |
| 08 | [Updates & rollbacks](basic/08-updates-and-rollbacks) | Rolling updates, rollout history, `rollout undo` |
| 09 | [Ingress with Traefik](basic/09-ingress-traefik) | Local-domain routing via MicroK8s' Traefik ingress addon |

## Advanced track

| # | Exercise | Covers |
|---|---|---|
| 01 | [Kustomize basics](advanced/01-kustomize-basics) | `kustomization.yaml`, `kubectl apply -k` |
| 02 | [Kustomize overlays](advanced/02-kustomize-overlays) | base + dev/prod overlays, patches, generators |
| 03 | [Helm install/upgrade](advanced/03-helm-install-upgrade) | `helm repo`, `install`, `upgrade`, `rollback` |
| 04 | [Helm create chart](advanced/04-helm-create-chart) | `helm create`, templating, `helm template`/`--dry-run` |
| 05 | [Helm package & push](advanced/05-helm-package-push) | `helm package`, pushing to an OCI registry |

## Suggested order

Work through the basic track top to bottom, then the advanced track. Each exercise creates its own namespace (named after the exercise) so they don't collide with each other — delete the namespace when you're done with an exercise to clean up everything it created.
