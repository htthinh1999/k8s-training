# Exercise 08 — Updates & rollbacks

## Objective

Perform a rolling update on a Deployment, inspect its revision history, deliberately roll out a broken image, and roll back.

## Background

Every change to `spec.template` in a Deployment creates a new ReplicaSet (a new "revision"). The `RollingUpdate` strategy replaces old Pods with new ones gradually, controlled by `maxUnavailable` (how many can be down at once) and `maxSurge` (how many extra can be created above the desired count) during the transition.

## Steps

### 1. Create a namespace and deploy v1

Fill in the `# TODO` in `manifests/deployment.yaml` (initial image, e.g. `nginx:1.25-alpine`), then:

```bash
kubectl create namespace basic-08-updates-and-rollbacks
kubectl apply -f manifests/deployment.yaml -n basic-08-updates-and-rollbacks
kubectl rollout status deployment/rollout-demo -n basic-08-updates-and-rollbacks
```

### 2. Roll out an update

```bash
kubectl set image deployment/rollout-demo nginx=nginx:1.27-alpine -n basic-08-updates-and-rollbacks
kubectl annotate deployment/rollout-demo kubernetes.io/change-cause="bump to 1.27-alpine" -n basic-08-updates-and-rollbacks --overwrite
```

Watch the rolling update happen Pod-by-Pod:

```bash
kubectl get pods -n basic-08-updates-and-rollbacks -w
```

Press `Ctrl+C` once all Pods show the new image. Confirm with:

```bash
kubectl get deployment rollout-demo -n basic-08-updates-and-rollbacks -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

### 3. Inspect revision history

```bash
kubectl rollout history deployment/rollout-demo -n basic-08-updates-and-rollbacks
kubectl rollout history deployment/rollout-demo -n basic-08-updates-and-rollbacks --revision=2
```

### 4. Roll out a broken image on purpose

```bash
kubectl set image deployment/rollout-demo nginx=nginx:this-tag-does-not-exist -n basic-08-updates-and-rollbacks
kubectl annotate deployment/rollout-demo kubernetes.io/change-cause="oops, bad tag" -n basic-08-updates-and-rollbacks --overwrite
kubectl rollout status deployment/rollout-demo -n basic-08-updates-and-rollbacks --timeout=30s
```

The status command will time out/stall. Diagnose:

```bash
kubectl get pods -n basic-08-updates-and-rollbacks
kubectl describe pod -n basic-08-updates-and-rollbacks -l app=rollout-demo | grep -A5 Events
```

You should see `ImagePullBackOff`/`ErrImagePull` on the new Pods, while enough old Pods are still running to keep the app available — this is the safety net `maxUnavailable` gives you.

### 5. Roll back

```bash
kubectl rollout undo deployment/rollout-demo -n basic-08-updates-and-rollbacks
kubectl rollout status deployment/rollout-demo -n basic-08-updates-and-rollbacks
```

Or roll back to a specific revision:

```bash
kubectl rollout undo deployment/rollout-demo -n basic-08-updates-and-rollbacks --to-revision=1
```

### 6. Pause/resume for batching changes

```bash
kubectl rollout pause deployment/rollout-demo -n basic-08-updates-and-rollbacks
kubectl set image deployment/rollout-demo nginx=nginx:1.26-alpine -n basic-08-updates-and-rollbacks
kubectl set resources deployment/rollout-demo -n basic-08-updates-and-rollbacks -c=nginx --limits=cpu=250m,memory=64Mi
kubectl rollout status deployment/rollout-demo -n basic-08-updates-and-rollbacks --timeout=5s || echo "no rollout in progress yet, as expected — it's paused"
kubectl rollout resume deployment/rollout-demo -n basic-08-updates-and-rollbacks
kubectl rollout status deployment/rollout-demo -n basic-08-updates-and-rollbacks
```

Both changes made while paused are applied together as a single rollout once resumed.

## Verification checklist

- [ ] `rollout history` showed at least 3 revisions with meaningful `change-cause` messages.
- [ ] The broken image rollout left the app available (old Pods kept serving) instead of taking it down.
- [ ] `rollout undo` restored a working image.
- [ ] Pausing prevented a rollout from starting until `resume` was called.

## Cleanup

```bash
kubectl delete namespace basic-08-updates-and-rollbacks
```

## Bonus challenge

Set `maxUnavailable: 0` and `maxSurge: 1` and re-run an update — this guarantees full capacity throughout the rollout at the cost of temporarily running more Pods than `replicas`. Compare the Pod count during rollout to step 2.
