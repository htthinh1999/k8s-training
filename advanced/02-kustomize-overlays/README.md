# Advanced 02 — Kustomize overlays

## Objective

Layer environment-specific overlays (`dev`, `prod`) on top of a shared `base`, changing replica counts, resource limits, and config values per environment without duplicating manifests.

## Background

The standard Kustomize layout is a `base/` (the common definition) plus one `overlays/<env>/` per environment. Each overlay's `kustomization.yaml` references the base as a `resources` entry and layers transformations on top: `namePrefix`, patches (JSON6902 or strategic-merge), and generator `behavior: merge` to override individual keys of a base-defined ConfigMap/Secret.

## Steps

### 1. Create namespaces

```bash
kubectl create namespace adv-02-dev
kubectl create namespace adv-02-prod
```

### 2. Preview the base alone

```bash
kubectl kustomize base/
```

This is the "default" — 1 replica, `ENVIRONMENT=base`.

### 3. Fill in the dev overlay

Open `overlays/dev/kustomization.yaml` and fill in the `# TODO`s (base reference, name prefix, environment value, replica count), then:

```bash
kubectl kustomize overlays/dev/
```

Compare the output to the base: note the `dev-` prefix, `ENVIRONMENT=development`, and the patched replica count.

### 4. Fill in the prod overlay

Do the same in `overlays/prod/kustomization.yaml`, including the extra resources patch.

```bash
kubectl kustomize overlays/prod/
```

### 5. Apply both overlays side by side

```bash
kubectl apply -k overlays/dev/ -n adv-02-dev
kubectl apply -k overlays/prod/ -n adv-02-prod

kubectl get deployments,configmaps -n adv-02-dev
kubectl get deployments,configmaps -n adv-02-prod
```

### 6. Confirm the merged config per environment

```bash
kubectl exec -n adv-02-dev deploy/dev-nginx -- printenv ENVIRONMENT
kubectl exec -n adv-02-prod deploy/prod-nginx -- printenv ENVIRONMENT
```

### 7. Confirm prod has resource limits and dev doesn't

```bash
kubectl get deployment dev-nginx -n adv-02-dev -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
kubectl get deployment prod-nginx -n adv-02-prod -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```

## Verification checklist

- [ ] Dev and prod each rendered with a different name prefix, replica count, and `ENVIRONMENT` value from the same base.
- [ ] Only the prod overlay's Deployment had CPU/memory requests and limits.
- [ ] Neither overlay required editing anything under `base/`.

## Cleanup

```bash
kubectl delete -k overlays/dev/ -n adv-02-dev
kubectl delete -k overlays/prod/ -n adv-02-prod
kubectl delete namespace adv-02-dev adv-02-prod
```

## Bonus challenge

Add a third overlay, `overlays/staging/`, that reuses the `dev` overlay's replica count but `prod`'s resource limits — think about whether it's cleaner to base it on `../../base` directly (re-declaring both patches) or to have it reference `../dev` and patch resources on top (overlay-of-an-overlay).
