## Images

Image targets are in `docker-bake.hcl`. The registry is not stored in the
repository; set it locally by renaming `docker-bake.override.hcl.example` to
`docker-bake.override.hcl` (ignored by git, loaded by bake automatically) and
filling in `REGISTRY`.

```bash
docker login <host>
APP_VERSION=1.0.0 docker buildx bake --push               # every service, amd64 + arm64
APP_VERSION=1.0.0 docker buildx bake __SERVICE__ --push   # one service
docker buildx bake __SERVICE__-amd64                      # single architecture (CI)
```

Each service is pushed as one manifest tagged `$APP_VERSION` and `latest`.
`REGISTRY` can also be passed from the environment:
`REGISTRY=<host>/<project> docker buildx bake --push`.
