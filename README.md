# argo-test

Demo repository for testing ArgoCD with a Helm-packaged hello-world app.

## Layout

```
.
├── src/                          # the demo hello-world app (Node.js HTTP server + Dockerfile)
├── charts/
│   └── hello-world-chart/        # Helm chart that deploys the app
└── argocd/
    └── hello-world-application.yaml   # ArgoCD Application pointing at the chart
```

## How it fits together

1. `src/` contains the app and a `Dockerfile` to build the `hello-world` image.
2. `charts/hello-world-chart/` is a Helm chart that renders a Deployment + Service for that image.
3. `argocd/hello-world-application.yaml` is an ArgoCD `Application` whose `source.path`
   points at `charts/hello-world-chart`, so ArgoCD syncs the chart into the cluster.

## Deploy with ArgoCD

> Update `spec.source.repoURL` in `argocd/hello-world-application.yaml` to your repo first.

```bash
kubectl apply -f argocd/hello-world-application.yaml
```

ArgoCD will create the `hello-world` namespace and sync the chart automatically
(`prune` + `selfHeal` are enabled).

## Validate the chart locally

```bash
helm template hello-world charts/hello-world-chart
```
