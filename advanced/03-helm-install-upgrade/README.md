# Advanced 03 — Helm install / upgrade / rollback

## Objective

Use Helm to install a real published chart from a repository, inspect a release, upgrade it with new values, view release history, and roll back — the everyday Helm consumer workflow (as opposed to authoring a chart, covered in exercise 04).

## Background

Helm packages Kubernetes manifests as versioned, parameterizable **charts**. Installing a chart creates a **release** — a named, tracked instance of that chart with a specific set of values. Every `helm upgrade` records a new revision, so you can view history and roll back, similar to `kubectl rollout` but at the whole-chart level.

We'll use [podinfo](https://github.com/stefanprodan/podinfo), a small, actively maintained demo app built specifically for exercising Helm/GitOps workflows — it exposes its own version and a configurable UI message over HTTP, which makes upgrades easy to observe.

## Prerequisites

```bash
microk8s enable helm3
alias helm='microk8s helm3'   # or install standalone helm and point KUBECONFIG at MicroK8s
```

## Steps

### 1. Add the chart repository

```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm search repo podinfo
```

### 2. Fill in a values file

Open `values/dev-values.yaml` and fill in the `# TODO`s (replica count and UI message).

### 3. Install the release

```bash
kubectl create namespace adv-03-helm-install-upgrade
helm install frontend podinfo/podinfo -n adv-03-helm-install-upgrade -f values/dev-values.yaml
```

### 4. Inspect the release

```bash
helm list -n adv-03-helm-install-upgrade
helm status frontend -n adv-03-helm-install-upgrade
helm get values frontend -n adv-03-helm-install-upgrade
```

### 5. Reach the app

```bash
kubectl port-forward -n adv-03-helm-install-upgrade svc/frontend 9898:9898
# in another terminal:
curl -s localhost:9898 | grep -E 'message|hostname'
```

You should see your configured `message` and the Pod hostname. Stop the port-forward with `Ctrl+C`.

### 6. Upgrade the release

```bash
helm upgrade frontend podinfo/podinfo -n adv-03-helm-install-upgrade \
  -f values/dev-values.yaml \
  --set replicaCount=4 \
  --set ui.message="upgraded via helm upgrade"
```

Repeat the port-forward/curl from step 5 — the message should reflect the change, and `kubectl get pods -n adv-03-helm-install-upgrade` should show 4 Pods.

### 7. View release history

```bash
helm history frontend -n adv-03-helm-install-upgrade
```

### 8. Roll back

```bash
helm rollback frontend 1 -n adv-03-helm-install-upgrade
helm list -n adv-03-helm-install-upgrade
kubectl get pods -n adv-03-helm-install-upgrade   # back to 2 replicas
```

### 9. Uninstall

```bash
helm uninstall frontend -n adv-03-helm-install-upgrade
```

## Verification checklist

- [ ] `helm list` showed the release with an incrementing `REVISION` after each upgrade.
- [ ] The app's response reflected the `ui.message` value from your values file, then the upgraded value.
- [ ] `helm rollback` restored both the replica count and the message from revision 1.
- [ ] `helm uninstall` removed all release resources (`kubectl get all -n adv-03-helm-install-upgrade` was empty).

## Cleanup

```bash
kubectl delete namespace adv-03-helm-install-upgrade
```

## Bonus challenge

Run `helm upgrade --install frontend podinfo/podinfo -n adv-03-helm-install-upgrade -f values/dev-values.yaml --dry-run --debug` before actually applying a change, and read through the fully rendered manifest it prints — this is the safe way to preview any Helm change before it touches the cluster.
