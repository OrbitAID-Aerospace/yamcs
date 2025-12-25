# Yamcs Docker Image (GHCR)

This repo includes:
- `Dockerfile` (build Yamcs from source into a runnable image)
- `.github/workflows/docker-image.yml` (build + publish to GHCR)

## What gets published

Images are published to:
- `ghcr.io/<owner>/<repo>` (e.g. `ghcr.io/ajnacloud-ksj/yamcs`)

Tags:
- `latest` on the default branch
- `v*` tags (e.g. `v5.12.4`)
- short SHA tags for traceability

## Notes
- The Docker build compiles the web UI with `npm run build` before running the Maven `distribution` packaging.
- The runtime image uses the Yamcs distribution wrapper `yamcsd`.


