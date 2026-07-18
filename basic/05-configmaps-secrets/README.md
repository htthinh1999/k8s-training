# Exercise 05 — ConfigMaps & Secrets

## Objective

Externalize configuration and sensitive values from a container image using ConfigMaps and Secrets, and consume them both as environment variables and as mounted files.

## Background

- **ConfigMap** — non-sensitive key/value configuration, injectable as env vars or files.
- **Secret** — same idea, for sensitive data. Values are base64-encoded at rest (not encrypted by default in a stock MicroK8s install — treat Secrets as "obscured", not "secure", unless you've configured encryption at rest).
- Both can be consumed the same two ways: `envFrom`/`env.valueFrom` (environment variables) or as a mounted volume (each key becomes a file).

## Steps

### 1. Create a namespace

```bash
kubectl create namespace basic-05-configmaps-secrets
```

### 2. Create the ConfigMap and Secret

Fill in the `# TODO`s in `manifests/configmap.yaml` and `manifests/secret.yaml`, then:

```bash
kubectl apply -f manifests/configmap.yaml -n basic-05-configmaps-secrets
kubectl apply -f manifests/secret.yaml -n basic-05-configmaps-secrets
kubectl get configmap app-config -n basic-05-configmaps-secrets -o yaml
kubectl get secret app-secret -n basic-05-configmaps-secrets -o yaml   # note: values are base64, not plaintext
```

Decode a secret value manually to see the difference between "encoded" and "encrypted":

```bash
kubectl get secret app-secret -n basic-05-configmaps-secrets -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo
```

### 3. Create the Deployment that consumes both

Fill in the two `# TODO`s in `manifests/deployment.yaml` (the ConfigMap and Secret names), then:

```bash
kubectl apply -f manifests/deployment.yaml -n basic-05-configmaps-secrets
```

### 4. Verify via logs

```bash
kubectl logs deployment/config-demo -n basic-05-configmaps-secrets
```

You should see the env vars (`APP_COLOR`, `APP_MESSAGE`, `DB_PASSWORD`) and the contents of the mounted `app.conf` and `DB_PASSWORD` files printed out.

### 5. Confirm the mounted files directly

```bash
POD=$(kubectl get pods -n basic-05-configmaps-secrets -l app=config-demo -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n basic-05-configmaps-secrets "$POD" -- ls /etc/config /etc/secret
kubectl exec -n basic-05-configmaps-secrets "$POD" -- cat /etc/config/app.conf
```

### 6. Update the ConfigMap and observe (non-)propagation

```bash
kubectl patch configmap app-config -n basic-05-configmaps-secrets --type merge -p '{"data":{"APP_MESSAGE":"updated live"}}'
kubectl exec -n basic-05-configmaps-secrets "$POD" -- cat /etc/config/app.conf   # unchanged, app.conf wasn't touched
# the mounted volume is updated automatically (may take up to ~60s to sync), but env vars from envFrom are NOT
# re-injected into a running container without a Pod restart
kubectl rollout restart deployment/config-demo -n basic-05-configmaps-secrets
```

## Verification checklist

- [ ] Logs showed correct env var values and file contents.
- [ ] Secret values in `kubectl get secret -o yaml` were base64-encoded, not plaintext.
- [ ] Updating the ConfigMap eventually updated the mounted file's contents without a restart, but env vars needed a Pod restart.

## Cleanup

```bash
kubectl delete namespace basic-05-configmaps-secrets
```

## Bonus challenge

Recreate `app-secret` imperatively instead of via YAML: `kubectl create secret generic app-secret-cli --from-literal=DB_PASSWORD=anotherpw -n basic-05-configmaps-secrets`, and compare its `-o yaml` output to the declarative one.
