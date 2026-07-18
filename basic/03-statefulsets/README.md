# Exercise 03 — StatefulSets

## Objective

Deploy a StatefulSet backed by per-Pod persistent storage and a headless Service, and observe the properties that distinguish it from a Deployment: stable network identity, ordered creation, and stable storage.

## Background

Deployments treat Pods as interchangeable. StatefulSets are for workloads that need:

- **Stable, unique Pod names** (`web-0`, `web-1`, ... instead of random suffixes) that persist across rescheduling.
- **Stable per-Pod storage** via `volumeClaimTemplates` — each Pod gets its own PersistentVolumeClaim that follows it.
- **Ordered, sequential deployment and scaling** (`web-0` becomes Ready before `web-1` is created).
- **Stable DNS names** via a headless Service (`clusterIP: None`), e.g. `web-0.web-headless.<namespace>.svc.cluster.local`.

## Prerequisites

Enable the hostpath storage addon so PersistentVolumeClaims can be dynamically provisioned:

```bash
microk8s enable hostpath-storage
kubectl get storageclass
```

Note the StorageClass name (typically `microk8s-hostpath`) — you'll need it below.

## Steps

### 1. Create a namespace

```bash
kubectl create namespace basic-03-statefulsets
```

### 2. Create the headless Service

```bash
kubectl apply -f manifests/headless-service.yaml -n basic-03-statefulsets
```

### 3. Create the StatefulSet

Fill in the `# TODO`s in `manifests/statefulset.yaml` (replica count, storage class name from step 0), then:

```bash
kubectl apply -f manifests/statefulset.yaml -n basic-03-statefulsets
```

### 4. Watch ordered creation

```bash
kubectl get pods -n basic-03-statefulsets -w
```

You should see `web-0` reach `Running`/`Ready` before `web-1` is even created. Press `Ctrl+C` once both are up.

### 5. Inspect storage

```bash
kubectl get pvc -n basic-03-statefulsets
kubectl get pv
```

Each Pod (`web-0`, `web-1`, ...) has its own PVC named `www-web-0`, `www-web-1`, etc.

### 6. Verify stable DNS names

Run a temporary debug Pod in the same namespace:

```bash
kubectl run dnsutils -n basic-03-statefulsets --image=busybox:1.36 --restart=Never -it --rm -- sh -c \
  "wget -qO- web-0.web-headless.basic-03-statefulsets.svc.cluster.local"
```

You should see `Hello from web-0`. Try `web-1.web-headless...` too.

### 7. Delete a Pod and confirm identity is preserved

```bash
kubectl delete pod web-0 -n basic-03-statefulsets
kubectl get pods -n basic-03-statefulsets -w
```

`web-0` is recreated with the same name and re-attaches to the same PVC (`www-web-0`) — content written in step 6 is still there if you curl it again.

### 8. Scale down and observe PVC retention

```bash
kubectl scale statefulset web --replicas=1 -n basic-03-statefulsets
kubectl get pods,pvc -n basic-03-statefulsets
```

`web-1`'s Pod is removed, but its PVC `www-web-1` is **not** deleted automatically — StatefulSets never delete storage for you, by design.

## Verification checklist

- [ ] Pods were created in strict order (`web-0` before `web-1`).
- [ ] Each Pod had its own PVC.
- [ ] DNS names of the form `<pod>.<headless-svc>.<namespace>.svc.cluster.local` resolved correctly.
- [ ] Deleting a Pod preserved its identity and data on recreation.
- [ ] Scaling down left the orphaned PVC behind.

## Cleanup

```bash
kubectl delete namespace basic-03-statefulsets
kubectl get pv | grep basic-03-statefulsets   # confirm no leftover PVs, delete manually if a Retain policy left any
```

## Bonus challenge

Scale the StatefulSet back up to 3 replicas and confirm `web-2` reuses (or gets a fresh) PVC named `www-web-2`. Then try deleting the StatefulSet with `--cascade=orphan` and observe that the Pods keep running independently.
