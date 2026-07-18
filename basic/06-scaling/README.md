# Exercise 06 — Scaling

## Objective

Scale a Deployment manually, then let a HorizontalPodAutoscaler (HPA) do it automatically based on observed CPU load.

## Background

- **Manual scaling** — `kubectl scale` (or editing `spec.replicas`) directly sets the desired replica count.
- **Autoscaling** — a HorizontalPodAutoscaler watches a metric (commonly CPU utilization %) and adjusts `spec.replicas` on your Deployment for you, within `minReplicas`/`maxReplicas` bounds. It requires the `metrics-server` addon and CPU `requests` set on the container.

## Steps

### 1. Create a namespace and deploy

```bash
kubectl create namespace basic-06-scaling
kubectl apply -f manifests/deployment.yaml -n basic-06-scaling
kubectl apply -f manifests/service.yaml -n basic-06-scaling
kubectl get pods -n basic-06-scaling
```

### 2. Manual scaling

```bash
kubectl scale deployment/scaling-demo --replicas=4 -n basic-06-scaling
kubectl get pods -n basic-06-scaling -w
```

Press `Ctrl+C` once 4 Pods are Running. Scale back down:

```bash
kubectl scale deployment/scaling-demo --replicas=2 -n basic-06-scaling
```

### 3. Enable metrics-server for the HPA bonus

```bash
microk8s enable metrics-server
kubectl top pods -n basic-06-scaling   # may take ~30-60s to start returning data
```

### 4. Create the HPA

Fill in the three `# TODO`s in `manifests/hpa.yaml`, then:

```bash
kubectl apply -f manifests/hpa.yaml -n basic-06-scaling
kubectl get hpa -n basic-06-scaling
```

### 5. Generate load and watch it scale

In one terminal, watch the HPA and Pods:

```bash
kubectl get hpa scaling-demo -n basic-06-scaling -w
```

In another terminal, generate sustained load against the Service:

```bash
kubectl run load-generator -n basic-06-scaling --image=busybox:1.36 --restart=Never -it --rm -- \
  /bin/sh -c "while true; do wget -q -O- http://scaling-demo > /dev/null; done"
```

Within a couple of minutes you should see `TARGETS` (current CPU%) rise and `REPLICAS` increase towards `maxReplicas`. Stop the load generator (`Ctrl+C`, it auto-deletes due to `--rm`) and watch replicas scale back down after a few minutes (HPA has a built-in cooldown/stabilization window).

## Verification checklist

- [ ] Manual `kubectl scale` changed the Pod count immediately in both directions.
- [ ] `kubectl top pods` returned real CPU/memory numbers.
- [ ] The HPA increased replicas under load and scaled back down once load stopped.

## Cleanup

```bash
kubectl delete namespace basic-06-scaling
```

## Bonus challenge

Change the HPA's `averageUtilization` to a very low value (e.g. `5`) and re-apply, forcing it to scale up almost immediately even under light load — a good way to see the scaling behavior quickly without needing much load.
