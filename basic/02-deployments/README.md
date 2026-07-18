# Exercise 02 — Deployments

## Objective

Create, inspect, update, and delete a Deployment, and understand how it manages ReplicaSets and Pods on your behalf.

## Background

A Deployment describes a desired state (which container image, how many replicas) and a controller continuously reconciles the cluster towards it. Under the hood, a Deployment creates a ReplicaSet, which creates Pods. You almost always manage workloads through Deployments (or StatefulSets, see exercise 03) rather than bare Pods.

## Prerequisites

None beyond a running MicroK8s cluster.

## Steps

### 1. Create a namespace

```bash
kubectl create namespace basic-02-deployments
```

### 2. Create the Deployment

Fill in the two `# TODO` fields in `manifests/deployment.yaml` (replica count and image), then:

```bash
kubectl apply -f manifests/deployment.yaml -n basic-02-deployments
```

### 3. Watch it roll out

```bash
kubectl rollout status deployment/nginx-deployment -n basic-02-deployments
kubectl get deployments,replicasets,pods -n basic-02-deployments
```

Notice the naming pattern: `nginx-deployment` → `nginx-deployment-<hash>` (ReplicaSet) → `nginx-deployment-<hash>-<random>` (Pods).

### 4. Inspect

```bash
kubectl describe deployment nginx-deployment -n basic-02-deployments
```

Look at `Replicas`, `StrategyType` (default is `RollingUpdate`), and the `Events` section.

### 5. Update the Deployment

Change the replica count directly:

```bash
kubectl scale deployment/nginx-deployment --replicas=5 -n basic-02-deployments
kubectl get pods -n basic-02-deployments -w
```

Press `Ctrl+C` once you see 5 Pods running. (Dedicated scaling scenarios, including autoscaling, are covered in exercise 06; image updates and rollback history are covered in exercise 08.)

### 6. Delete a Pod and watch self-healing

```bash
kubectl delete pod -n basic-02-deployments -l app=nginx --field-selector=status.phase=Running --wait=false 2>/dev/null || \
POD=$(kubectl get pods -n basic-02-deployments -l app=nginx -o jsonpath='{.items[0].metadata.name}') && kubectl delete pod "$POD" -n basic-02-deployments
kubectl get pods -n basic-02-deployments
```

A replacement Pod appears automatically — the Deployment's ReplicaSet controller is doing its job.

### 7. Delete the Deployment

```bash
kubectl delete deployment nginx-deployment -n basic-02-deployments
```

## Verification checklist

- [ ] `kubectl get replicasets` showed exactly one ReplicaSet owned by the Deployment.
- [ ] Scaling to 5 replicas resulted in 5 Running Pods.
- [ ] Deleting a Pod triggered automatic recreation.

## Cleanup

```bash
kubectl delete namespace basic-02-deployments
```

## Bonus challenge

Add `resources.requests` and `resources.limits` (CPU/memory) to the container spec and re-apply. Then run `kubectl describe node` and find where your Pods' resource requests show up under "Allocated resources".
