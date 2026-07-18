# Exercise 04 — Services

## Objective

Expose a Deployment inside the cluster with a `ClusterIP` Service, then outside the cluster with a `NodePort` Service, and observe load balancing across replicas.

## Background

Pods are ephemeral and get new IPs when recreated. A Service gives a stable virtual IP and DNS name in front of a set of Pods selected by label, and load-balances traffic across them.

- `ClusterIP` (default) — reachable only from inside the cluster.
- `NodePort` — additionally opens a port (30000-32767) on every node, reachable from outside.
- `LoadBalancer` — normally needs a cloud provider to hand out a real external IP. On a bare-metal MicroK8s install, the [`metallb` addon](https://canonical.com/microk8s/docs/addon-metallb) provides that instead, so `type: LoadBalancer` Services get a real IP on your local network rather than falling back to `<pending>`.

We'll use [`traefik/whoami`](https://github.com/traefik/whoami), a tiny HTTP server that echoes its own hostname — perfect for visibly demonstrating load balancing.

## Prerequisites (for step 6)

Enable MetalLB with a small range of **unused** IPs on the same subnet as your MicroK8s node. Find your node's subnet first:

```bash
kubectl get nodes -o wide   # note the INTERNAL-IP, e.g. 192.168.1.50
ip -4 addr show             # confirm the subnet, e.g. 192.168.1.0/24
```

Pick a handful of addresses in that subnet that nothing else on your network is using — ideally outside your router's DHCP range (check your router's settings, or just pick high addresses like `.240`-`.250` and be ready to change them if there's a conflict). Then enable the addon with that range:

```bash
microk8s enable metallb:192.168.1.240-192.168.1.250
```

(Omit the range and `microk8s enable metallb` will prompt you for it interactively instead.) Verify it's running:

```bash
kubectl get pods -n metallb-system
kubectl get ipaddresspool -n metallb-system
```

## Steps

### 1. Create a namespace and the Deployment

```bash
kubectl create namespace basic-04-services
kubectl apply -f manifests/deployment.yaml -n basic-04-services
kubectl get pods -n basic-04-services -o wide
```

### 2. Create the ClusterIP Service

Fill in the two `# TODO`s in `manifests/clusterip-service.yaml` (selector and port), then:

```bash
kubectl apply -f manifests/clusterip-service.yaml -n basic-04-services
kubectl get svc -n basic-04-services
```

### 3. Confirm service discovery and load balancing

From a temporary Pod in the same namespace:

```bash
kubectl run curler -n basic-04-services --image=busybox:1.36 --restart=Never -it --rm -- sh -c \
  "for i in 1 2 3 4 5; do wget -qO- whoami-clusterip; echo; done"
```

You should see different `Hostname:` values across the 5 requests as the Service load-balances across the 3 Pods.

### 4. Create the NodePort Service

Fill in the `# TODO` in `manifests/nodeport-service.yaml` (Service type), then:

```bash
kubectl apply -f manifests/nodeport-service.yaml -n basic-04-services
kubectl get svc whoami-nodeport -n basic-04-services
```

### 5. Reach it from outside the cluster

Find your MicroK8s node IP (on the machine running MicroK8s):

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl "$NODE_IP:30080"
```

Run it a few times and note the `Hostname:` field changes between the three whoami Pods.

### 6. Create the LoadBalancer Service (MetalLB)

With MetalLB enabled (see Prerequisites above), fill in the `# TODO` in `manifests/loadbalancer-service.yaml` (Service type), then:

```bash
kubectl apply -f manifests/loadbalancer-service.yaml -n basic-04-services
kubectl get svc whoami-loadbalancer -n basic-04-services -w
```

Unlike on a cloud provider, this doesn't take long — MetalLB assigns an `EXTERNAL-IP` from your pool almost immediately. Press `Ctrl+C` once it's no longer `<pending>`.

### 7. Reach it via the assigned IP

```bash
LB_IP=$(kubectl get svc whoami-loadbalancer -n basic-04-services -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl "http://$LB_IP"
```

No port number needed — `LoadBalancer` exposes the Service's `port` (80) directly on that IP, unlike `NodePort`'s 30000-32767 range.

## Verification checklist

- [ ] `whoami-clusterip` load-balanced across at least 2 different Pod hostnames.
- [ ] `whoami-nodeport` was reachable via `<node-ip>:30080` from outside the cluster.
- [ ] `whoami-loadbalancer` received a real `EXTERNAL-IP` from your MetalLB pool (not `<pending>`) and was reachable on port 80 directly.
- [ ] `kubectl get endpoints` for all three Services listed 3 Pod IPs.

## Cleanup

```bash
kubectl delete namespace basic-04-services
# optionally: microk8s disable metallb
```

## Bonus challenge

Run `kubectl get endpoints whoami-clusterip -n basic-04-services -o yaml` and compare the listed IPs with `kubectl get pods -n basic-04-services -o wide`. Then delete one Pod and immediately re-check `endpoints` — notice how quickly the Service's backend list updates.

For a second bonus, pin a specific address instead of letting MetalLB pick one: add `spec.loadBalancerIP: <an-ip-in-your-pool>` to `manifests/loadbalancer-service.yaml`, re-apply, and confirm `EXTERNAL-IP` matches exactly what you asked for.
