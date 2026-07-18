# Exercise 09 — Ingress routing with Traefik (local domains)

## Objective

Enable MicroK8s' Traefik-based ingress addon and route a local domain name to a Service, then extend it with path-based routing.

## Background

MicroK8s' `ingress` addon deploys a [Traefik](https://traefik.io/traefik/) ingress controller ([official docs](https://canonical.com/microk8s/docs/addon-ingress)). Since MicroK8s 1.35 it replaced the old NGINX-based addon, and it provides three `IngressClass` options:

- `public` (**default**) — kept for backward compatibility with the old NGINX-based setup.
- `traefik` — the standard/native Traefik ingress class.
- `nginx` — for migrating existing Ingress resources that use `ingressClassName: nginx` / NGINX-style annotations.

An `Ingress` resource maps a hostname (and optionally a path) to a Service — this is how you get friendly local domain names instead of remembering NodePorts.

## Prerequisites

```bash
microk8s enable ingress
microk8s enable dns
kubectl get pods -n ingress          # Traefik controller pods should be Running
kubectl get svc -n ingress           # note the Service exposing ports 80/443
```

## Steps

### 1. Create a namespace and the app

```bash
kubectl create namespace basic-09-ingress-traefik
kubectl apply -f manifests/deployment.yaml -n basic-09-ingress-traefik
kubectl apply -f manifests/service.yaml -n basic-09-ingress-traefik
```

### 2. Create the Ingress

Fill in the two `# TODO`s in `manifests/ingress.yaml` (ingress class and host), then:

```bash
kubectl apply -f manifests/ingress.yaml -n basic-09-ingress-traefik
kubectl get ingress -n basic-09-ingress-traefik
kubectl describe ingress whoami-ingress -n basic-09-ingress-traefik
```

### 3. Point your local domain at the cluster

Find the node's IP address:

```bash
kubectl get nodes -o wide
```

Add an entry to your machine's hosts file (`/etc/hosts` on Linux/macOS, `C:\Windows\System32\drivers\etc\hosts` on Windows — requires admin rights) pointing your chosen domain at that IP:

```
<node-ip>  whoami.microk8s.local
```

### 4. Test it

Traefik listens on ports 80/443 (check the actual exposed port with `kubectl get svc -n ingress` if your setup differs, e.g. a NodePort):

```bash
curl http://whoami.microk8s.local/
```

You should get a `whoami` response showing the Pod's hostname and the request headers, including `Host: whoami.microk8s.local`. Run it a few times to see it load-balance across the 2 replicas.

### 5. Bonus — path-based routing

Deploy a second copy of the app under a different name (`echo`) reusing `manifests/deployment.yaml`/`service.yaml` with `whoami` replaced by `echo`, then fill in the `# TODO`s in `manifests/echo-path-ingress.yaml` to route `/echo` to it while `/` still goes to the original:

```bash
kubectl apply -f manifests/echo-path-ingress.yaml -n basic-09-ingress-traefik
curl http://whoami.microk8s.local/
curl http://whoami.microk8s.local/echo
```

### 6. Bonus — give Traefik a stable IP with MetalLB

So far your hosts-file entry points at the node's own IP. That's fine for a single-node MicroK8s, but it's worth seeing the more general pattern: giving the ingress controller itself a dedicated `LoadBalancer` IP (via [MetalLB](https://canonical.com/microk8s/docs/addon-metallb), the same addon used in [exercise 04](../04-services)) instead of piggybacking on the node's address. This is the same approach the pre-Traefik NGINX ingress addon docs recommended, and it still applies here.

Enable MetalLB with an unused IP range on your local subnet (see [exercise 04](../04-services)'s Prerequisites section for how to pick one):

```bash
microk8s enable metallb:192.168.1.240-192.168.1.250
```

Find the Service Traefik's ingress addon created for itself, then patch it to `LoadBalancer` (rather than writing a brand-new Service — reuse the existing one so it stays wired to the actual Traefik Pods):

```bash
kubectl get svc -n ingress
kubectl patch svc <traefik-service-name> -n ingress -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n ingress -w   # wait for EXTERNAL-IP to move off <pending>
```

Update your hosts-file entry to point at that `EXTERNAL-IP` instead of the node IP, and re-test:

```bash
curl http://whoami.microk8s.local/
```

This IP stays stable and predictable even if you add more nodes later, unlike relying on any one node's address.

## Verification checklist

- [ ] `kubectl get pods -n ingress` showed Traefik controller Pods Running.
- [ ] `curl http://whoami.microk8s.local/` reached the app and showed the `Host` header matching your domain.
- [ ] Repeated requests load-balanced across both whoami replicas.
- [ ] (Bonus) `/` and `/echo` routed to two different Services on the same host.
- [ ] (Bonus) Traefik's Service received a MetalLB `EXTERNAL-IP` and remained reachable after switching the hosts-file entry to it.

## Cleanup

```bash
kubectl delete namespace basic-09-ingress-traefik
# remove the /etc/hosts entry you added
# if you patched Traefik's Service to LoadBalancer: kubectl patch svc <traefik-service-name> -n ingress -p '{"spec": {"type": "ClusterIP"}}'
```

## Bonus challenge

Add a second `host` rule to the Ingress for a completely different domain (e.g. `admin.microk8s.local`) pointing at a different Service, add a matching hosts-file entry, and confirm Traefik does virtual-host routing based on the `Host` header alone (same IP, same port, different domain → different backend).
