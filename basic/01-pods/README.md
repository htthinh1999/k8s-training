# Exercise 01 — Pods

## Objective

Learn the smallest deployable unit in Kubernetes: the Pod. Create one imperatively, then declaratively, inspect it, get a shell inside it, and clean it up.

## Background

A Pod wraps one or more containers that share network and storage. In practice you'll rarely create bare Pods for real workloads (Deployments do that for you), but understanding Pods directly is the foundation for everything else.

## Prerequisites

None beyond a running MicroK8s cluster.

## Steps

### 1. Create a namespace for this exercise

```bash
kubectl create namespace basic-01-pods
```

### 2. Create a Pod imperatively

```bash
kubectl run nginx-quick --image=nginx:1.27-alpine --port=80 -n basic-01-pods
```

Check it came up:

```bash
kubectl get pods -n basic-01-pods
kubectl get pods -n basic-01-pods -o wide
```

### 3. Create a Pod declaratively

Open `manifests/pod.yaml` and fill in the two `# TODO` fields (a label value and an image). Then apply it:

```bash
kubectl apply -f manifests/pod.yaml -n basic-01-pods
```

### 4. Inspect the Pod

```bash
kubectl describe pod nginx-pod -n basic-01-pods
kubectl get pod nginx-pod -n basic-01-pods -o yaml
```

Look at the `status.phase`, `status.podIP`, and the `events` section at the bottom of `describe`.

### 5. Get a shell inside the container

```bash
kubectl exec -it nginx-pod -n basic-01-pods -- sh
# inside the container:
curl -s localhost:80 | head -n 5
exit
```

### 6. Reach it from your machine

```bash
kubectl port-forward pod/nginx-pod 8080:80 -n basic-01-pods
# in another terminal:
curl localhost:8080
```

Stop the port-forward with `Ctrl+C`.

### 7. Delete the Pods

```bash
kubectl delete pod nginx-quick nginx-pod -n basic-01-pods
```

## Verification checklist

- [ ] Both Pods reached `Running` status.
- [ ] `kubectl describe` showed a `Scheduled` → `Pulled` → `Created` → `Started` event sequence.
- [ ] You could `curl` the nginx welcome page both from inside the container and via `port-forward`.

## Cleanup

```bash
kubectl delete namespace basic-01-pods
```

## Bonus challenge

Edit `manifests/pod.yaml` to add a second container (e.g. `busybox` running `sh -c "sleep 3600"`) in the same Pod, apply it, and use `kubectl logs <pod> -c <container>` and `kubectl exec -it <pod> -c <container> -- sh` to target each container individually.
