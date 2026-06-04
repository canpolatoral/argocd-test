# Deployment Guide — hello-world via ArgoCD

This document records the exact, reproducible steps used to deploy the demo
`hello-world` app to a local Kubernetes cluster using ArgoCD. Every step below
was executed and verified.

## Overview

| Component | Value |
|---|---|
| Source app | `src/` (Node.js HTTP server, listens on `8080`, `/` + `/healthz`) |
| Image | `canpolatoral/argocd-test:latest` (multi-arch: `linux/amd64`, `linux/arm64`) |
| Helm chart | `charts/hello-world-chart` |
| Git repo (chart source for ArgoCD) | https://github.com/canpolatoral/argocd-test |
| ArgoCD Application | `argocd/hello-world-application.yaml` |
| Target cluster | local `kind` cluster `argo-test` |
| App namespace | `hello-world` (auto-created by ArgoCD) |

ArgoCD pulls the **chart from Git** and the **image from Docker Hub**, then
deploys into the `hello-world` namespace with auto-sync (`prune` + `selfHeal`).

---

## Prerequisites

Tools used: `docker`, `kind`, `kubectl`, `helm`, `git`/`gh`. The image is public
on Docker Hub, so the cluster pulls it directly — no local image load needed.

### Build & push the image (already done)

```bash
# Login (use a Docker Hub Personal Access Token, not a password)
echo "<DOCKERHUB_PAT>" | docker login -u canpolatoral --password-stdin

# Multi-arch build so it runs on both amd64 and arm64 clusters
docker buildx build --platform linux/amd64,linux/arm64 \
  -t canpolatoral/argocd-test:latest \
  --push src/
```

### Push the chart to Git (already done)

```bash
git init && git add -A && git commit -m "..."
gh repo create canpolatoral/argocd-test --public --source=. --remote=origin --push
```

> The `repoURL` in `argocd/hello-world-application.yaml` must match this repo.

---

## Step 1 — Create the cluster

```bash
kind create cluster --name argo-test
kubectl wait --for=condition=Ready node --all --timeout=120s
```

## Step 2 — Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

> **Gotcha:** plain `kubectl apply` fails with
> `CustomResourceDefinition "applicationsets.argoproj.io" is invalid:
> metadata.annotations: Too long`. The CRD exceeds the client-side apply
> annotation limit. Use `--server-side`. If you already ran a plain apply first
> and hit field-manager conflicts, add `--force-conflicts`:
>
> ```bash
> kubectl apply -n argocd --server-side --force-conflicts -f \
>   https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
> ```

Wait for the core components:

```bash
kubectl -n argocd rollout status deploy/argocd-server
kubectl -n argocd rollout status deploy/argocd-repo-server
```

### (Optional) Access the ArgoCD UI

```bash
# admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo

# UI at https://localhost:8080 (user: admin)
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

## Step 3 — Deploy the Application

```bash
kubectl apply -f argocd/hello-world-application.yaml
```

> A warning about `metadata.finalizers` preferring a domain-qualified name is
> cosmetic and safe to ignore.

## Step 4 — Wait for sync

```bash
kubectl -n argocd get application hello-world -w
```

Observed progression:

```
sync=Synced health=Progressing
sync=Synced health=Progressing
sync=Synced health=Healthy   <-- done
```

## Step 5 — Verify

```bash
kubectl get ns hello-world
kubectl -n hello-world get deploy,svc,pods
```

Result:

```
deployment.apps/hello-world-hello-world-chart   1/1   ...   canpolatoral/argocd-test:latest
service/hello-world-hello-world-chart           ClusterIP   80/TCP
pod/hello-world-hello-world-chart-...           1/1   Running
```

Hit the app:

```bash
kubectl -n hello-world port-forward svc/hello-world-hello-world-chart 8080:80
curl localhost:8080         # -> Hello, World!
curl localhost:8080/healthz # -> ok
```

---

## Test the GitOps loop (optional)

Because auto-sync + self-heal are on, ArgoCD will revert manual drift and apply
Git changes automatically:

```bash
# drift test: scale manually -> ArgoCD heals it back to replicaCount in values.yaml
kubectl -n hello-world scale deploy/hello-world-hello-world-chart --replicas=3
# watch it return to 1

# change test: edit charts/hello-world-chart/values.yaml (e.g. greeting or replicaCount),
# commit & push -> ArgoCD syncs the new state within a few minutes
# (or force it: argocd app sync hello-world)
```

---

## Teardown

```bash
kubectl delete -f argocd/hello-world-application.yaml   # removes the app (finalizer prunes workload)
kind delete cluster --name argo-test                    # removes the whole cluster
```

---

## Security note

The Docker Hub PAT used for login is stored in `~/.docker/config.json`. Run
`docker logout` to clear it, and rotate the token if it was ever shared in
plaintext.
