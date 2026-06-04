# hello-world

Minimal Node.js HTTP server used as the demo app for ArgoCD.

- `GET /` returns the greeting (configurable via `GREETING`)
- `GET /healthz` returns `ok` (used for liveness/readiness probes)

## Run locally

```bash
cd src
npm start
# open http://localhost:8080
```

## Build the image

```bash
docker build -t hello-world:latest src/
docker run -p 8080:8080 hello-world:latest
```
