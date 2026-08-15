# Advanced 01 — Kustomize basics

## Objective

Manage a plain set of Kubernetes manifests through Kustomize instead of `kubectl apply -f`, and see how `kustomization.yaml` can rename, relabel, and generate resources without touching the underlying YAML.

## Background

Kustomize (built into `kubectl` as `kubectl apply -k` / `kubectl kustomize`) lets you compose and customize plain YAML manifests declaratively, without templating. A `kustomization.yaml` file lists `resources` and a set of transformers (prefixes, labels, generators, patches, ...) that get applied on top when you build.

## Steps

### 1. Create a namespace

```bash
kubectl create namespace adv-01-kustomize-basics
```

### 2. Fill in the kustomization

Open `base/kustomization.yaml` and fill in the three `# TODO`s: the `resources` list, `namePrefix`, and the `commonLabels` value, plus a `GREETING` value in the `configMapGenerator`.

### 3. Preview the rendered output

Before applying anything, look at exactly what Kustomize will send to the cluster:

```bash
kubectl kustomize base/
```

Notice:
- Every resource name now has your `namePrefix` (e.g. `kz-nginx`).
- `managed-by: <your value>` was added to every resource's labels.
- A ConfigMap named `nginx-config-<hash>` was generated, where `<hash>` is derived from its contents.

### 4. Apply it

```bash
kubectl apply -k base/ -n adv-01-kustomize-basics
kubectl get all,configmap -n adv-01-kustomize-basics
```

### 5. Confirm the generated ConfigMap is wired up

```bash
POD=$(kubectl get pods -n adv-01-kustomize-basics -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n adv-01-kustomize-basics "$POD" -- printenv GREETING
```

### 6. Change the generated ConfigMap's content and re-apply

Edit the `GREETING` literal in `base/kustomization.yaml`, then:

```bash
kubectl kustomize base/ | grep nginx-config   # note the hash suffix changed
kubectl apply -k base/ -n adv-01-kustomize-basicsku
kubectl get pods -n adv-01-kustomize-basics -w
```

Because the generated ConfigMap's name changes with its content, the Deployment (which references it by name) gets a new Pod template hash and rolls out automatically — this is Kustomize's built-in way of forcing a rollout on config change, without needing `kubectl rollout restart`.

## Verification checklist

- [ ] `kubectl kustomize base/` output showed prefixed names and the extra label before you applied anything.
- [ ] The Deployment's Pods had `GREETING` set from the generated ConfigMap.
- [ ] Changing the ConfigMap literal produced a new ConfigMap name and triggered a rolling update.

## Cleanup

```bash
kubectl delete -k base/ -n adv-01-kustomize-basics
kubectl delete namespace adv-01-kustomize-basics
```

## Bonus challenge

Add an `images:` transformer to `kustomization.yaml` (e.g. `images: [{name: nginx, newTag: 1.27-alpine}]`) and re-run `kubectl kustomize base/` to see the image tag overridden without editing `deployment.yaml` at all.
