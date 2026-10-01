---
name: gitlab-cicd
description: Set up or extend the GitLab CI/CD pipeline (`.gitlab-ci.yml` plus `docker-bake.hcl`) for a backend or frontend repo - version from tag/branch, tests in Docker, multi-arch (amd64 + arm64) image build and manifest push to Harbor, paired-repo trigger, manual Helm deploy per environment. Use when the user asks for a GitLab pipeline, CI/CD, `.gitlab-ci.yml`, docker bake targets, or to add a service, environment or deploy job to an existing pipeline ("gitlab ci", "git cicd", "pipeline", "napravi cicd", "dodaj servis u pipeline", "deploy job").
---

# GitLab CI/CD

The user's house pipeline. The files in `templates/` next to this file are the
source of truth; copy them and adapt, keep job names, stages and rules as they
are.

| Template | Becomes |
|---|---|
| `templates/backend.gitlab-ci.yml` | `.gitlab-ci.yml` of a multi-service backend repo |
| `templates/frontend.gitlab-ci.yml` | `.gitlab-ci.yml` of a frontend repo (no test stage) |
| `templates/backend.docker-bake.hcl` | `docker-bake.hcl`, one target pair per backend service |
| `templates/frontend.docker-bake.hcl` | `docker-bake.hcl`, one target pair per frontend app |
| `templates/gitlab-runner.yml` | Helm values for a GitLab runner on an arm64 cluster (only when the user asks for a runner) |

## How the pipeline works

Stages: `init` → `test` → `build` → `deploy`.

**init - decide `APP_VERSION`.** Exactly one of these runs and writes
`APP_VERSION=<v>` into a `.env` artifact built from `.env.example`; every later
job reads it from there.

| Job | Runs on | `APP_VERSION` |
|---|---|---|
| `release-version` | git tag | tag without the leading `v` |
| `branch-version` | merge request | second path segment of the branch (`feature/ABC-12` → `ABC-12`) |
| `default-version` | default branch | `dev` |

`branch-version` also triggers the paired repo (backend ↔ frontend) with
`ISSUE_VERSION=<v>`, so both repos have an image tagged with the issue.

**test** (backend only). Matrix over services: starts `mysql` and `redisDB`
from the repo's compose file, builds the service image with
`--build-arg TARGET=builder` and runs `/opt/app/test.sh` in it.

**build.** Matrix over services, per architecture on tagged runners (`amd`,
`arm`): `docker buildx bake $SERVICE-<arch> --load`, retag
`latest-<arch>` to `$APP_VERSION` and `latest`, push, save the repo digest in
`$SERVICE-<arch>.env`. `build-manifest` then joins both digests into one
multi-arch manifest for `$APP_VERSION` and `latest`.

The `build-api-*` jobs are the same three jobs for a pipeline started by the
paired repo (`$ISSUE_VERSION` set). They exit early when that image tag already
exists, and the normal init/test/build jobs are skipped by their
`if: "$ISSUE_VERSION"` → `never` rule.

**deploy.** One manual job per environment, only on tags, with
`manual_confirmation`. Uses `dtzar/helm-kubectl`, picks the cluster through the
GitLab Kubernetes agent context and runs
`helm upgrade --install <project>-<back|front>-<env> ./kubernetes/charts/<env>/ --set app_version=${APP_VERSION}`.
The charts come from the `k8s-chart-deployment` skill.

## Placeholders

| Placeholder | Meaning | Example |
|---|---|---|
| `__PROJECT__` | project slug: Helm release prefix, registry project | `bzr` |
| `__BUILD_SERVICES__` | quoted, comma-separated services to build | `"rest_api", "user"` |
| `__TEST_SERVICES__` | services that have tests (backend) | `"rest_api", "user"` |
| `__GITLAB_GROUP__`, `__REPO__` | path of this repo, used in the agent context | `bzr`, `bzr-backend` |
| `__AGENT_STAGE__`, `__AGENT_DEMO__`, `__AGENT_PROD__` | GitLab agent name per cluster | `k8s-arm-agent` |
| `__GITLAB_HOST__`, `__PAIRED_PROJECT_ID__` | GitLab host and numeric project id of the paired repo | ask the user |
| `__SERVICE__`, `__APP_NAME__`, `__PORT__` | bake file only | `front-portal`, `portal`, `3000` |

Ask the user for agent names, GitLab host and the paired project id; do not
guess them. Leave no `__...__` behind.

## What the repo must provide

Check each of these before writing the pipeline, and say which are missing:

- `.env.example` in the repo root (the version jobs build `.env` from it).
- `docker-bake.hcl` with targets named `<service>-amd64` and `<service>-arm64`,
  each tagged `<registry>/<service>:latest-<arch>`. The matrix values, bake
  target names, image names and the chart's `services[].name` must all be the
  same string.
- Backend tests: a compose file with `mysql` and `redisDB` services, a
  Dockerfile whose `builder` stage can be selected with `TARGET=builder`, and
  `/opt/app/test.sh` inside it. If the repo's Dockerfile or compose differs
  (other database, other stage names, no test script), adapt the three lines of
  `.test_container_script` to what the repo has and tell the user what you
  changed. Do not drop the test stage silently.
- `kubernetes/charts/<env>/` for every deploy job.

CI/CD variables set in GitLab (never written into the file):

| Variable | Used for |
|---|---|
| `HARBOR_HOST`, `HARBOR_PROJECT`, `HARBOR_USERNAME`, `HARBOR_PASSWORD` | registry login; `REGISTRY` is `$HARBOR_HOST/$HARBOR_PROJECT` |
| `TRIGGER_TOKEN_FRONT` (backend) / `TRIGGER_TOKEN` (frontend) | pipeline trigger token of the paired repo |
| `CI_GIT_USER_EMAIL`, `CI_GIT_USER_USERNAME` | git identity in `release-version` |

Runners: one tagged `amd`, one tagged `arm`, both able to run Docker-in-Docker
(privileged). The repo needs a GitLab Kubernetes agent per cluster, with the
agent authorised for this project.

## Workflow

1. Read the repo: services and their Dockerfiles, compose file, `.env.example`,
   existing `.gitlab-ci.yml` and `docker-bake.hcl`. If a pipeline exists, extend
   it in its own style instead of replacing it.
2. Copy the matching template to `.gitlab-ci.yml` and fill the placeholders.
   Every `parallel.matrix` in the file gets the same build list.
3. Write `docker-bake.hcl` with one target pair per service in that list, and
   put every target in the `default` group.
4. Keep only the deploy jobs for environments that exist; delete the others.
5. Single repo with no paired frontend/backend: remove the `curl` trigger line
   and `TRIGGER_URL_*` from `branch-version`, and remove the three `build-api-*`
   jobs together with the `if: "$ISSUE_VERSION"` rules.
6. Validate: the file parses as YAML, every job's `stage` is in `stages`,
   `docker buildx bake --print` succeeds, and every matrix entry has both bake
   targets.
7. List for the user the CI/CD variables, runner tags and agents they need to
   set up in GitLab. Do not push, tag or start pipelines unless asked.

## Adding things later

- New service: add it to every `SERVICE` matrix (and the test matrix if it has
  tests), add its bake target pair, add it to the chart's `values.yaml`.
- New environment: copy a `deploy-<env>-arm` job, change the agent context,
  release name, chart path and confirmation text.
