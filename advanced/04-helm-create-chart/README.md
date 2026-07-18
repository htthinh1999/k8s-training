# Advanced 04 — Creating your own Helm chart

## Objective

Scaffold a new Helm chart from scratch with `helm create`, replace the generated placeholders with your own templates and values, and preview/install it locally.

## Background

`helm create <name>` generates a standard chart skeleton (`Chart.yaml`, `values.yaml`, `templates/`, a NOTES.txt, and a `_helpers.tpl` with naming/label helper functions) wired up for a generic single-container app. In practice you almost always start from this scaffold and then adapt the templates to your actual application — which is exactly what this exercise walks through.

## Steps

### 1. Scaffold the chart

```bash
cd advanced/04-helm-create-chart
helm create mychart
```

This creates `mychart/` with a working (if generic) chart. Take a look:

```bash
find mychart -type f
cat mychart/Chart.yaml
cat mychart/values.yaml
```

### 2. Replace the values file

Fill in the `# TODO`s in `chart-src/values.yaml`, then replace the generated one:

```bash
cp chart-src/values.yaml mychart/values.yaml
```

### 3. Replace the Deployment and Service templates

Fill in the remaining `# TODO`s in `chart-src/templates/deployment.yaml` and `chart-src/templates/service.yaml` (they reuse the `mychart.fullname`/`mychart.labels`/`mychart.selectorLabels` helpers that `helm create` already generated in `_helpers.tpl` — don't touch that file), then:

```bash
cp chart-src/templates/deployment.yaml mychart/templates/deployment.yaml
cp chart-src/templates/service.yaml mychart/templates/service.yaml
cp chart-src/templates/configmap.yaml mychart/templates/configmap.yaml   # a new template, not in the default scaffold
```

Delete the parts of the default scaffold this exercise doesn't use, to keep things simple:

```bash
rm -f mychart/templates/hpa.yaml mychart/templates/ingress.yaml mychart/templates/serviceaccount.yaml mychart/templates/tests/test-connection.yaml
rmdir mychart/templates/tests 2>/dev/null || true
```

### 4. Render templates locally (no cluster needed)

```bash
helm template myrelease mychart/
```

Read through the output carefully — this is exactly what would be sent to the API server. Confirm your `message`, image, replica count, and ports all appear correctly.

### 5. Dry-run against the real cluster

```bash
kubectl create namespace adv-04-helm-create-chart
helm install myrelease mychart/ -n adv-04-helm-create-chart --dry-run --debug
```

This validates the manifests against the live API server (catching schema errors) without actually creating anything.

### 6. Install for real

```bash
helm install myrelease mychart/ -n adv-04-helm-create-chart
kubectl get all,configmap -n adv-04-helm-create-chart
```

### 7. Verify

```bash
kubectl port-forward -n adv-04-helm-create-chart svc/myrelease 8080:80
# in another terminal:
curl -s localhost:8080   # nginx welcome page confirms the container is up
kubectl exec -n adv-04-helm-create-chart deploy/myrelease -- printenv MESSAGE
```

### 8. Change a value and upgrade

```bash
helm upgrade myrelease mychart/ -n adv-04-helm-create-chart --set message="v2 of my chart" --set replicaCount=3
```

## Verification checklist

- [ ] `helm template` rendered clean YAML with no leftover `# TODO` text anywhere.
- [ ] `helm install --dry-run --debug` succeeded against the real cluster before the real install.
- [ ] The running Pods had the `MESSAGE` env var from your ConfigMap template.
- [ ] `helm upgrade` changed the message and replica count.

## Cleanup

```bash
helm uninstall myrelease -n adv-04-helm-create-chart
kubectl delete namespace adv-04-helm-create-chart
```

## Bonus challenge

Add a `{{- if .Values.autoscaling.enabled }}` guarded HPA template back in (model it on the one `helm create` originally scaffolded before you deleted it), driven by new `autoscaling.enabled`/`minReplicas`/`maxReplicas` values — practice writing a conditional template block.
