---
name: service-dockerfiles
description: Write the Dockerfile for a Python RabbitMQ worker service, the FastAPI `rest_api` gateway, or the Vite/React frontend in the user's uv monorepo layout (multi-stage base/dev/builder/prod, shared `sharedlib` package, non-root runtime), plus `.dockerignore`, nginx config and the docker-compose block. Use when the user asks for a Dockerfile, to dockerize a service, rest_api or frontend, or to add a service to docker-compose ("dockerfile", "dockerize", "napravi dockerfile", "dodaj u docker-compose").
---

# Service Dockerfiles

Reference Dockerfiles for the monorepo layout where every service is a folder
in the repo root next to `shared/`. Copy the matching template from
`templates/` next to this file and replace `__SVC__` with the service folder
name (snake_case, same as its `[project.scripts]` entry).

| Template | For |
|---|---|
| `templates/worker.Dockerfile` | worker service with a database (has `alembic.ini` and `scripts/run.sh`) |
| `templates/worker-stateless.Dockerfile` | worker without a database (no Alembic, no `scripts/`) |
| `templates/rest_api.Dockerfile` | FastAPI gateway served by uvicorn on 8100 |
| `templates/frontend/Dockerfile`, `nginx.conf`, `dockerignore` | Vite/React app built with Node and served by nginx |
| `templates/root.dockerignore` | `.dockerignore` in the repo root |

Save each as `<service>/Dockerfile`; `templates/frontend/dockerignore` becomes
`frontend/.dockerignore` and `templates/root.dockerignore` becomes `.dockerignore`.

## Rules the templates follow

**Python services (worker, rest_api)**
- Build context is the repo root, not the service folder, because the image
  needs the sibling `shared/` package. Every `COPY` path therefore starts with
  the service folder name, and compose sets `context: .` with
  `dockerfile: <service>/Dockerfile`.
- Stages: `base` (Python slim + uv + `COPY shared /shared`) → `dev` (full
  `uv sync --frozen`, reload) and `builder` (prod dependencies) → `prod`
  (fresh slim image with only `.venv` and the app copied in). The last line
  `FROM ${TARGET}` selects the stage; default `prod`.
- `builder` runs `uv sync` twice: first `--no-install-project` with only
  `pyproject.toml`, `uv.lock` and `README.md` copied, so the dependency layer
  is cached; then again after the source is copied.
- Prod flags are always `--frozen --no-dev --no-cache --no-editable`.
  `--no-editable` is what lets `prod` work without `/shared`.
- `uv.lock` must exist and be current, otherwise `--frozen` fails. Run
  `uv lock` in the service after changing dependencies.
- Runtime runs as `appuser`, with `/app/.venv/bin` on `PATH`, and the command
  is the service's console script.
- A worker with a database starts through `scripts/run.sh`, which runs
  `alembic ensure_version` and `upgrade head` before `exec "$@"`.
- System libraries a service needs at runtime (for example pango/cairo for
  WeasyPrint) are installed with `apt-get` in both `base` and `prod`, because
  `prod` starts from a fresh image.
- Extra folders the service reads at runtime (templates, prompts, assets) that
  live outside `app/` need their own `COPY` in `dev`, `builder` and `prod`.

**rest_api**
- Same stages; no Alembic and no `scripts/`. `dev` runs uvicorn with
  `--reload`, `prod` runs it without. Port 8100 is exposed; if the project uses
  another port, change `EXPOSE` and both `CMD` lines together.
- The result worker reuses this image with a different command
  (`command: ["rest-api-worker"]` in compose).

**frontend**
- Build context is `frontend/`. Stage 0 runs `npm ci` and `npm run build`;
  stage 1 is `nginx:alpine` serving `/usr/share/nginx/html` with SPA fallback
  to `index.html`.
- Vite reads env at build time, so every `VITE_*` value is an `ARG` + `ENV`
  before `npm run build` and is passed from compose under `build.args`. Add one
  `ARG`/`ENV` pair per `VITE_*` variable the app uses.
- If the frontend is not Vite (for example Next.js), do not force this
  template; say so and write a Dockerfile for that framework.
- nginx listens on 80 as root. If this image is deployed with the
  `k8s-chart-deployment` frontend chart, set the service `port` to 80 and
  adjust the chart's `securityContext`, which assumes a Node server running as
  uid 1001.

## docker-compose block

Add one block per service to the root `docker-compose.yml`, following the
blocks already there. Names: image and container are
`<project>-<service-with-dashes>`.

```yaml
  __SVC__:
    build:
      context: .
      dockerfile: __SVC__/Dockerfile
      target: prod
    image: __PROJECT__-__SVC_DASH__
    container_name: __PROJECT__-__SVC_DASH__
    env_file:
      - .env
    environment:
      DEVELOP: "false"
      RABBIT_URL: amqp://rabbit:rabbit@rabbit:5672/rabbit
      DATABASE_URL: <same URL as the other services, with the compose host name>
    depends_on:
      rabbit:
        condition: service_healthy
      postgres:
        condition: service_healthy
```

- `environment` overrides the `.env` values that point at `localhost` with the
  compose service names (`rabbit`, `postgres`, `redis`, `minio`). Copy the
  exact values from a sibling service block.
- Stateless worker: drop `DATABASE_URL` and the `postgres` dependency.
- `rest_api`: add `REDIS_URL`, `ports: ["8100:8100"]`, depend on `rabbit` and
  `redis`.
- Frontend: `context: ./frontend`, `args` with the `VITE_*` values,
  `ports: ["<host>:80"]`, `depends_on: [rest_api]`.

## Check

Build the image from the repo root and report the result:

```bash
docker compose build <service>
```

If Docker is not available, say that the Dockerfile was not built.
