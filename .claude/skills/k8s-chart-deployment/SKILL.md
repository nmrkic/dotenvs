---
name: k8s-chart-deployment
description: Scaffold or extend the `kubernetes/charts/<env>/` Helm deployment layout (one self-contained chart per environment - stage, demo, prod) for a frontend or backend repo, plus the GitLab CI helm deploy jobs. Use when the user asks to add Kubernetes/Helm deployment to a project, create the kubernetes folder or charts, add a new environment, or add a service, cron job, config value, secret, host or ingress route to existing charts ("kubernetes chart", "helm chart", "k8s deployment", "deploy na kubernetes", "napravi kubernetes folder", "dodaj servis u chart").
---

# Kubernetes chart deployment

The user's house layout for deploying an app with Helm. Reference files are in
`templates/` next to this file; they are the source of truth for structure and
style. Copy them and adapt, do not invent a different layout (no `_helpers.tpl`,
no umbrella chart, no per-env values files on a shared chart).

## Layout

```
kubernetes/
├── charts/
│   ├── stage/                  # one complete chart per environment
│   │   ├── .helmignore
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── config/         # ConfigMaps and Ingresses
│   │       └── containers/     # Deployments, Services, CronJobs, infra
│   ├── demo/                   # same shape as stage
│   └── prod/
├── secret.yaml                 # backend only, git-ignored, applied by hand
└── prod-secret.yaml            # optional, git-ignored
```

Environments are separate copies of the chart, not one chart with several
values files. Differences between environments (hosts, DB, storage, ingress
class) are written straight into that environment's templates. When changing
something that applies everywhere, edit every environment's chart.

## Templates in this skill

| Path | Use for |
|---|---|
| `templates/backend/stage/` | backend chart for stage and demo (in-cluster MySQL, MinIO, RabbitMQ, Redis; nginx ingress + cert-manager; env secrets from the `secret-config` ConfigMap) |
| `templates/backend/prod/` | backend chart for prod on AWS EKS (ALB ingress + ACM cert, RDS/S3 instead of MySQL/MinIO, secrets via External Secrets from AWS Secrets Manager) |
| `templates/backend/secret.yaml` | shape of `kubernetes/secret.yaml` |
| `templates/frontend/chart/` | frontend chart, same for every environment |
| `gitlab-cicd` skill | the pipeline and its deploy job per environment |

Placeholders to replace after copying:

| Placeholder | Meaning | Example |
|---|---|---|
| `__PROJECT__` | short project slug, also the registry project and API prefix | `bzr` |
| `__ENV__` | `stage`, `demo` or `prod` | `stage` |
| `__HOST__` | public host of that environment | `bzr.bwl.rs` |
| `__NODE__` | node hostname that holds hostPath volumes (stage/demo) | `bzr` |
| `__DB_HOST__`, `__AWS_ACCOUNT_ID__`, `__AWS_REGION__`, `__ACM_CERT_ARN__`, `__EXTERNAL_SECRETS_ROLE_ARN__` | prod AWS values | ask the user |

Leave no `__...__` placeholder behind. If a value is unknown (AWS ARNs, hosts,
agent names), ask the user instead of guessing.

## Workflow

1. Look at the repo first: is it frontend or backend, which services/apps are
   built (`docker-bake.hcl`, `docker-compose`, CI `SERVICE` matrix), which ports,
   which env vars (`.env.example`), and whether `kubernetes/` already exists.
   If it exists, follow what is there and only add to it.
2. Settle the inputs: project slug, environments wanted, host per environment,
   list of services. Derive what the repo answers; ask only for the rest.
3. Copy the matching template chart into `kubernetes/charts/<env>/` for each
   environment (include `.helmignore`) and replace placeholders.
4. Fill in `values.yaml` (`services`, `crons`, `secrets`), the ConfigMaps and
   the ingress rules from what step 1 found. Delete infra files the project does
   not use (for example `minio*.y*ml`, `mysql.yaml`, `rabbit.yaml`, `cronjob.yaml`
   together with the `crons` values).
5. Add the deploy jobs to `.gitlab-ci.yml` when the repo uses GitLab CI,
   following the `gitlab-cicd` skill.
6. Validate every chart:
   ```
   helm lint kubernetes/charts/<env>
   helm template test kubernetes/charts/<env> --set app_version=0.0.1 > /dev/null
   ```
7. Never run `helm upgrade`, `helm install` or `kubectl apply` against a cluster
   unless the user asks for that deploy explicitly.

## Conventions

**Names**
- Chart name: `<project>-<env>-backend` / `<project>-<env>-frontend`
  (prod backend: `<project>-production-backend`).
- Helm release: `<project>-back-<env>` / `<project>-front-<env>`.
- Kubernetes object names use `-`; service names in `values.yaml` may contain
  `_` because they match image names, and templates convert them with
  `replace "_" "-"`.
- In-cluster infra Services are `mysql-service`, `redis-service`,
  `rabbit-service`, `minio-service`.

**values.yaml**
- `app_version` is the image tag; CI overrides it with
  `--set app_version=${APP_VERSION}`. Images are
  `{{ registry }}/{{ imageName | default name }}:{{ app_version }}`.
- `registry` is `reg.bwl.rs/<project>`, `sharedRegistry` is `reg.bwl.rs/shared`
  (third-party images and the `scheduler` cron image).
- `services` is a list of `name`, `replicas` and optional `imageName`,
  `command` (frontend adds `port`; prod backend adds `need_secrets`).
  Adding a worker service means adding one list entry, not a new template.
- `crons` is a list of `name`, `command`, `schedule` (prod adds `need_secrets`).
- `replicaCount` and `autoscaling` stay in the file as in the reference.

**Templates**
- `containers/service.yaml` ranges over `.Values.services` and renders one
  Deployment each; these are queue workers with no Service.
- The HTTP API gets its own file (`containers/rest_api.yaml`) with a Deployment,
  a readiness probe on `<api-root>/health` and a `NodePort` Service on 8080.
- Frontend `containers/front.yml` ranges over `.Values.services` and renders a
  Deployment plus a Service on port 80 targeting the app port.
- Deployments use `revisionHistoryLimit: 0`, `RollingUpdate` and
  `imagePullPolicy: Always` for project images; stateful infra uses `Recreate`.
- Security context is always set. Backend: user/group 1000,
  `readOnlyRootFilesystem: true`, all capabilities dropped, and every path the
  app writes to mounted as an `emptyDir`. Frontend: user/group 1001,
  `readOnlyRootFilesystem: false`.
- Pull secrets: `regcred` for the project registry, `regcred-shared` for
  shared images on stage/demo; prod uses `regcred` everywhere.

**Config and secrets**
- Non-secret env goes into `config/common.yaml` (ConfigMap `common-config`),
  loaded with `envFrom` by every backend container. Quote numbers and booleans.
- Frontend has one ConfigMap per app, `config/<app>.yaml` named `<app>-config`.
- Stage/demo secrets: a ConfigMap named `secret-config` kept in
  `kubernetes/secret.yaml`, outside the chart, applied by hand with
  `kubectl apply -f`. Make sure `.gitignore` contains `*secret.yaml`.
- Prod secrets: `containers/secret-manager.yaml` defines the ServiceAccount
  (IRSA role), the `SecretStore` and the DB certificate; each service with
  `need_secrets: true` gets an `ExternalSecret` named `<service>-secrets`
  built from the `secrets` list in `values.yaml` and loaded with `secretRef`.
  A new secret env var means a new entry in that list plus the value in AWS
  Secrets Manager under the listed key.
- Do not write real secret values into any file and do not print the contents
  of existing `*secret.yaml` files. Use `CHANGE_ME` and tell the user which
  values they need to fill in.

**Ingress**
- The ingress lives in the backend chart (`config/ingress.yml`) and routes both
  the API paths and `/` to the frontend Service, so frontend Service names
  there must match the frontend chart's `services[].name`.
- Stage/demo: nginx class, cert-manager `letsencrypt-prod`, one rule block per
  host with `/`, `<api-root>`, `/docs`, `/redoc`, `/openapi.json`.
- Prod: ALB class with the ACM certificate annotation and the `ssl-redirect`
  rule; only `/` and `<api-root>` are exposed.
- A new host needs an entry in `tls.hosts`, its own rule block, and matching
  URLs in the ConfigMaps of both charts.

**CI deploy**
- One manual job per environment in the `deploy` stage, run on tags, using
  `dtzar/helm-kubectl`, selecting the cluster through the GitLab agent context
  `<group>/<repo>:<agent>` and running
  `helm upgrade --install <release> ./kubernetes/charts/<env>/ --set app_version=${APP_VERSION}`.
