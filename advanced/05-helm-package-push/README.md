# Advanced 05 — Packaging and pushing Helm charts

## Objective

Package the chart you built in exercise 04 into a versioned `.tgz`, push it to a chart registry (MicroK8s' built-in OCI registry), and install it back from there — the release workflow you'd use to share a chart across a team or CI/CD pipeline.

## Background

Helm charts are distributed as `.tgz` packages, either via a traditional HTTP chart repository (an `index.yaml` plus packages on a static file server) or, the modern standard, an **OCI registry** — the same kind of registry Docker images live in. MicroK8s ships a built-in insecure (HTTP) registry you can use for this without any external accounts.

## Prerequisites

```bash
microk8s enable registry
microk8s enable helm3
alias helm='microk8s helm3'
kubectl get pods -n container-registry   # registry should be Running
```

The registry is reachable at `localhost:32000` from the machine running MicroK8s. Because it's plain HTTP (no TLS), every `helm`/`docker` command against it needs an "insecure/plain-http" flag.

You'll need the chart from [exercise 04](../04-helm-create-chart) — either the one you built there, or `../04-helm-create-chart/solution/mychart` if you skipped it.

## Steps

### 1. Bump the chart version

Edit `../04-helm-create-chart/mychart/Chart.yaml` (or the solution copy) and bump `version: 0.1.0` → `0.2.0` — every push needs a distinct version, chart registries don't allow overwriting an existing version+name pair.

### 2. Package the chart

```bash
cd advanced/05-helm-package-push
helm package ../04-helm-create-chart/mychart -d .
ls *.tgz
```

### 3. Push it to the local registry

Fill in the three `# TODO`s in `scripts/push-chart.sh`, make it executable, and run it:

```bash
chmod +x scripts/push-chart.sh
./scripts/push-chart.sh
```

Or run the equivalent commands directly:

```bash
helm push mychart-0.2.0.tgz oci://localhost:32000/helm-charts --plain-http
```

### 4. Verify it landed in the registry

```bash
helm show chart oci://localhost:32000/helm-charts/mychart --version 0.2.0 --plain-http
helm pull oci://localhost:32000/helm-charts/mychart --version 0.2.0 --plain-http -d /tmp
ls /tmp/mychart-0.2.0.tgz
```

### 5. Install directly from the registry

```bash
kubectl create namespace adv-05-helm-package-push
helm install from-registry oci://localhost:32000/helm-charts/mychart --version 0.2.0 --plain-http -n adv-05-helm-package-push
kubectl get all -n adv-05-helm-package-push
```

## Verification checklist

- [ ] `helm package` produced a `.tgz` named after the chart and its version.
- [ ] `helm push` succeeded against the local OCI registry.
- [ ] `helm pull`/`helm show chart` could retrieve the exact version you pushed.
- [ ] `helm install` from the `oci://` reference worked without needing the local chart directory at all.

## Cleanup

```bash
helm uninstall from-registry -n adv-05-helm-package-push
kubectl delete namespace adv-05-helm-package-push
rm -f *.tgz
```

## Bonus challenge

Push a second version (`0.3.0`) with a values change, then use `helm list -n adv-05-helm-package-push` and `helm upgrade from-registry oci://localhost:32000/helm-charts/mychart --version 0.3.0 --plain-http -n adv-05-helm-package-push` to upgrade a running release straight from the registry, without touching a local chart directory at all.
