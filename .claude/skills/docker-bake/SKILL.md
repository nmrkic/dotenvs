---
name: docker-bake
description: Write or fix `docker-bake.hcl` so that a plain `docker buildx bake --push` pushes ONE multi-arch (amd64 + arm64) manifest per service to the registry (Harbor), with the registry kept out of the repo in `docker-bake.override.hcl`. Use when the user asks for docker bake scripts or targets, wants to push images to Harbor or another registry by hand, adds a service to an existing bake file, or sees separate `latest-amd64` / `latest-arm64` artifacts in the registry instead of a manifest ("docker bake", "bake skripte", "bake file", "push na harbor", "pushuj slike", "napravi bake", "multi-arch", "manifest", "vidim amd i arm umesto manifesta").
---

# docker-bake.hcl

The user's house layout for `docker-bake.hcl`, first set up in the `mrksocket`
repo. The files in `templates/` next to this file are the source of truth;
copy them and fill in the placeholders.

| Template | Becomes |
|---|---|
| `templates/docker-bake.hcl` | `docker-bake.hcl` in the repo root |
| `templates/docker-bake.override.hcl.example` | same name in the repo root, committed |
| `templates/README-section.md` | an "Images" section in the repo's `README.md` |

## The layout

Three targets per service:

| Target | Platforms | Tags | In `default` group | Pushes |
|---|---|---|---|---|
| `<service>` | amd64 + arm64 | `$APP_VERSION`, `latest` | **yes** | with `--push` |
| `<service>-amd64` | amd64 | `latest-amd64` | no | `push = true` |
| `<service>-arm64` | arm64 | `latest-arm64` | no | `push = true` |

- **The `default` group holds only the multi-arch targets.** A plain
  `docker buildx bake --push` must give one manifest per service. Never put
  the `-amd64` / `-arm64` targets in `default`: the registry then shows two
  separate artifacts tagged `latest-amd64` and `latest-arm64` and no `latest`
  at all. That mistake is what this skill exists to prevent.
- **The multi-arch target has `attest = ["type=provenance,disabled=true"]`**
  and no `push = true`. Without the `attest` line buildx adds a provenance
  attestation and the registry shows an extra `unknown/unknown` entry inside
  the manifest. The user pushes with `--push`.
- **The per-arch targets exist only for the GitLab pipeline** (`gitlab-cicd`
  skill), which runs `docker buildx bake $SERVICE-<arch>` on an amd and an arm
  runner and joins the two images into a manifest itself. Keep their names
  and tags exactly `<service>-<arch>` / `<registry>/<service>:latest-<arch>`.
  Write them even when the repo has no pipeline yet.
- **No `inherits`, no matrix.** Every target is written out in full, like the
  template.
- **The registry is not in the repo.** `REGISTRY` in `docker-bake.hcl`
  defaults to the placeholder `registry.example.com/project`. The real value
  goes into `docker-bake.override.hcl`, which bake loads automatically and
  git ignores. Commit `docker-bake.override.hcl.example` with the placeholder.
- **Nothing environment-specific is baked in.** No build args for API
  addresses or other per-environment values: one image must serve every
  environment. If a Dockerfile needs such an arg (Vite `VITE_*`, Flutter
  `--dart-define`), say so and propose reading the value at container start
  instead (an entrypoint script writing `config.js`), rather than adding
  `args` to the bake file.

## Placeholders

| Placeholder | Meaning | Example |
|---|---|---|
| `__SERVICE__` | image name = target name = CI matrix value = chart `services[].name` | `rest_api` |
| `__CONTEXT__` | build context | `./` for services that COPY the sibling `shared` package, `./frontend` for a self-contained app |
| `__DOCKERFILE__` | Dockerfile path relative to the context | `rest_api/Dockerfile`, `Dockerfile` |

Take context and Dockerfile from the repo's `docker-compose.yml` `build:`
blocks, so bake builds exactly what compose builds. A compose service that
only reuses another service's image with a different command (a simulator, a
scheduler) gets no target of its own.

## Workflow

1. Read the repo: `docker-compose.yml` build blocks, the Dockerfiles, an
   existing `docker-bake.hcl` and `.gitlab-ci.yml`. If a bake file exists in
   another layout, bring it to this one and tell the user what changed.
2. Write `docker-bake.hcl`: the variables, the `default` group with one entry
   per service, then the three targets per service.
3. Write `docker-bake.override.hcl.example` (placeholder) and
   `docker-bake.override.hcl` (the real registry, if the user gave it; ask
   otherwise). Add to `.gitignore`:

   ```
   # Local registry for docker bake
   docker-bake.override.hcl
   ```

4. Add the "Images" section to `README.md`.
5. Check Dockerfiles for cross-building: a build stage that downloads an
   x64-only toolchain (Flutter SDK) needs `FROM --platform=$BUILDPLATFORM`,
   otherwise the arm64 build fails.
6. Validate:
   - `docker buildx bake --print` succeeds; the `default` group lists only the
     multi-arch targets; each has both platforms, both tags and the `attest`
     line; tags start with the real registry (the override is picked up).
   - `docker buildx bake <service>-amd64 <service>-arm64 --print` succeeds.
   - `docker buildx ls` shows a `docker-container` builder with
     `linux/amd64` and `linux/arm64`; the default `docker` driver cannot push
     a multi-platform image. If there is none, tell the user:
     `docker buildx create --name multiarch-builder --driver docker-container --use`.
7. Do not build or push unless asked. Building all services for two
   architectures is slow; if asked to test, build one service with
   `--set '*.output=type=cacheonly'`.

## Commands to give the user

```
docker login <host>
APP_VERSION=1.0.0 docker buildx bake --push             # every service
APP_VERSION=1.0.0 docker buildx bake <service> --push   # one service
```

Without `--push` nothing reaches the registry. Without `APP_VERSION` only
`latest` is pushed.

## Repairing a registry that has only per-arch images

When `latest-amd64` and `latest-arm64` were pushed and the manifest is
missing, join them without rebuilding:

```
docker buildx imagetools create \
    -t <registry>/<service>:latest -t <registry>/<service>:<version> \
    <registry>/<service>:latest-amd64 <registry>/<service>:latest-arm64
```

The user's shell is fish: loops are `for s in a b c ... end`, not
`for ...; do ...; done`.

## Adding a service later

Add its name to the `default` group and its three targets; add it to the CI
`SERVICE` matrices and the chart's `values.yaml` if those exist.
