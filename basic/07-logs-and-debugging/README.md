# Exercise 07 — Logs & debugging

## Objective

Practice the everyday toolkit for finding out why something isn't working: `logs`, `exec`, `describe`, and `events`, across both a healthy multi-container Pod and a deliberately broken one.

## Steps

### 1. Create a namespace

```bash
kubectl create namespace basic-07-logs-and-debugging
```

### 2. Multi-container logs

Fill in the two `# TODO`s in `manifests/multi-container-pod.yaml` (container names), then:

```bash
kubectl apply -f manifests/multi-container-pod.yaml -n basic-07-logs-and-debugging
kubectl wait --for=condition=Ready pod/multi-log-pod -n basic-07-logs-and-debugging --timeout=60s
```

View logs for a specific container (required when a Pod has more than one):

```bash
kubectl logs multi-log-pod -c app -n basic-07-logs-and-debugging
kubectl logs multi-log-pod -c sidecar -n basic-07-logs-and-debugging
```

Follow logs live, and view logs from all containers at once:

```bash
kubectl logs multi-log-pod -c app -n basic-07-logs-and-debugging -f    # Ctrl+C to stop
kubectl logs multi-log-pod --all-containers=true -n basic-07-logs-and-debugging --prefix
```

Show only the last few lines, or logs from the last minute:

```bash
kubectl logs multi-log-pod -c app -n basic-07-logs-and-debugging --tail=5
kubectl logs multi-log-pod -c app -n basic-07-logs-and-debugging --since=1m
```

### 3. Exec and describe

```bash
kubectl exec -it multi-log-pod -c app -n basic-07-logs-and-debugging -- sh
# inside: ps aux ; exit
kubectl describe pod multi-log-pod -n basic-07-logs-and-debugging
```

Read through the `Events` section at the bottom of `describe` — this is often where scheduling failures, image pull errors, and probe failures show up first.

### 4. Diagnose a crashing Pod

Fill in the `# TODO` in `manifests/crashloop-pod.yaml` (a sleep duration), then:

```bash
kubectl apply -f manifests/crashloop-pod.yaml -n basic-07-logs-and-debugging
kubectl get pods -n basic-07-logs-and-debugging -w
```

Watch the `RESTARTS` count climb and the status cycle through `Error` → `CrashLoopBackOff`. Press `Ctrl+C` once you've seen a couple of cycles.

Now debug it:

```bash
kubectl describe pod crashloop-pod -n basic-07-logs-and-debugging   # check Last State, Reason, Exit Code
kubectl logs crashloop-pod -n basic-07-logs-and-debugging            # current attempt's logs
kubectl logs crashloop-pod -n basic-07-logs-and-debugging --previous # logs from the PREVIOUS crashed attempt
```

### 5. Cluster-wide events

```bash
kubectl get events -n basic-07-logs-and-debugging --sort-by='.lastTimestamp'
```

## Verification checklist

- [ ] You could isolate logs to a single container in a multi-container Pod.
- [ ] `kubectl describe` showed a clear `Events` history.
- [ ] `--previous` logs showed output from a crashed attempt, distinct from the current one.
- [ ] `Last State` / `Exit Code` in `describe` matched the `exit 1` in the container command.

## Cleanup

```bash
kubectl delete namespace basic-07-logs-and-debugging
```

## Bonus challenge

Add a `livenessProbe` to `crashloop-pod.yaml` that would never pass (e.g. an HTTP GET on a port nothing listens on), apply a fresh copy under a new name, and use `kubectl describe` to see liveness probe failures drive restarts even when the process itself hasn't crashed.
