---
name: qa-repo
description: Create or update a project's QA repository (`<project>-qa`) - a docker-compose.yml derived from the project's own compose that runs the published images instead of building, a complete `.env.example` with every variable filled in except real secrets, plus Makefile, README and `init_db/`. Use when the user asks for a QA repo, QA environment, local QA deployment, or to add a service or variable to an existing QA repo ("QA repo", "qa repository", "napravi qa", "qa okruzenje", "dodaj servis u qa").
---

# QA repository

A QA repo lets a tester run any issue branch of a project from published
Docker images, with no source code. It contains only:

```
<project>-qa/
├── docker-compose.yml   # the project's compose, with images instead of builds
├── .env.example         # every variable; real secrets empty
├── Makefile             # start issue=..., stop, logs, reset_db, ...
├── README.md
├── .gitignore           # .env, sql/*
└── init_db/             # starting database dump, mounted into the DB container
```

Reference files are in `templates/` next to this file. `Makefile`, `README.md`
and `gitignore` are copied and filled in. `docker-compose.yml` and
`env.example` there only show the shape; their real content is derived from
the project.

## Workflow

1. Find the sources: the project's compose file(s) and `.env.example` in the
   backend repo, the frontend repo if separate, and the CI config
   (`.gitlab-ci.yml`, `docker-bake.hcl`) for the image names that get pushed.
   Read `.env.example` files only. Do not open the project's `.env`,
   `.docker.env`, Kubernetes secrets or any other file holding real values.
2. Write `docker-compose.yml` (rules below).
3. Write `.env.example` (rules below).
4. Copy `Makefile`, `README.md`, `gitignore` (as `.gitignore`) from the
   templates and fill the placeholders. Create `init_db/.gitkeep`.
5. Check the result (last section) and tell the user which variables were
   left empty and why.

If the QA repo already exists, keep its structure and only add what is
missing.

## docker-compose.yml

Start from the project's compose and change only what the list says, so the QA
stack stays the same as development.

- **Built services become images.** Remove `build:` and set
  `image: ${REGISTRY}/<name>:${APP_VERSION}`. `<name>` must be the image name
  CI pushes (the `SERVICE` matrix / bake target), which is not always the
  compose service name.
- **Frontend apps** from a separate repo use
  `${FRONT_APP_VERSION:-$APP_VERSION}` so they can run another tag.
- **A service built from outside the repo** (`context: ../something`) has no
  image from this project's CI. Find its published image; if there is none,
  ask the user instead of inventing a name.
- **Infrastructure** (database, RabbitMQ, Redis, MinIO and its bucket job, mail
  catcher) is copied unchanged, including healthchecks, commands and ports.
- **Remove development-only parts:** source bind mounts, `target: dev`, build
  args, reload commands, extra env files such as `.docker.env`.
- **Every service** has `env_file: [.env]`. Keep an `environment:` block only
  for values that differ per container (for example each frontend's own URL).
- **Database container** also mounts `./init_db:/docker-entrypoint-initdb.d`.
- **Names:** network `<project>-qa-net`; `container_name:
  <service>_${DOCKER_CONTAINER_SUFFIX}`, so the QA stack does not collide with
  the development stack on the same machine.
- **On-demand jobs** (scheduler, one-off scripts) get `profiles: ["manual"]`
  and take their arguments from `${METHOD}` / `${SERVICE}`.
- Keep `depends_on` conditions and worker healthchecks as in the project.

## .env.example

One file with every variable, working as is after `cp .env.example .env`. Do
not split it into several env files.

**Which variables.** The union of:
- the project's `.env.example` (backend and frontend),
- every `${VAR}` used in the QA compose and Makefile: `REGISTRY`,
  `SHARED_REGISTRY` when used, `APP_VERSION`, `FRONT_APP_VERSION`,
  `DOCKER_CONTAINER_SUFFIX`, `METHOD`, `SERVICE`,
- variables the code reads but the project's example forgot. Check the
  settings classes (`app/settings.py`) and the frontend's env usage
  (`process.env.*`, `import.meta.env.*`).

Keep the project's section headers and comments, with a "QA deployment"
section first.

**Values.** Everything runs inside the compose network, so hosts that are
`localhost` in the project's example become the compose service name
(`postgres`, `mysql`, `rabbit`, `redis`, `minio`, `mail`) and ports become the
container ports, not the host-mapped ones. URLs opened by the browser stay
`localhost` with the published port. Set flags to what the production image
supports (for example `DEVELOP=false` when the reload tooling is a dev
dependency). Keep every value on one line, because the Makefile includes the
file.

**Secret or not.** Decide per variable with one question: would this value
give access to anything outside the containers on this machine?

| | Examples | In `.env.example` |
|---|---|---|
| No - local only | password of the local DB container, RabbitMQ user/password, MinIO root keys, local JWT / session signing keys, mail catcher settings | filled in with a plain local value |
| Yes - real secret | OpenAI / Anthropic API keys, OAuth client secrets, real SMTP user and password, Twilio / SMS tokens, payment keys, cloud (AWS, GCP) keys, Sentry tokens, Firebase credentials, keys that encrypt data shared with other environments | key present, value empty, with a comment |

- A real secret gets a comment line above it: `# SECRET - <what it is>, ask
  the team. Empty = <which feature is off>`.
- The stack must still start with those values empty. When a feature needs a
  real key, point the default at the local substitute where one exists (mail
  catcher instead of SMTP, `Local` SMS provider, MinIO instead of S3).
- A local-only key that must be non-empty (JWT secret, encryption key for
  local data) gets an obviously local value such as `local-qa-jwt-secret`, or
  a freshly generated one if a format is required. Never reuse a value from
  stage or production.
- If the project's `.env.example` contains something that looks like a real
  credential (provider key prefixes such as `sk-`, `AKIA`, long random
  strings for an external service), leave it empty in the QA file and tell
  the user it is exposed in the project repo.
- Public identifiers (OAuth client id, public site keys) are not secrets;
  copy them from the project's example, or leave empty with a comment if the
  example has none.

## Makefile and README placeholders

| Placeholder | Value |
|---|---|
| `__PROJECT__`, `__PROJECT_TITLE__` | slug and human name |
| `__REGISTRY_HOST__` | registry host for `docker login` |
| `__SERVICE_LIST__` | the compose service names a tester may pass as `app=` |
| `__ADDRESS_LIST__` | bullet list of local URLs: frontends, API, mail catcher, MinIO console, RabbitMQ management |
| `__DB_SERVICE__` | compose name of the database service |
| `__DB_DUMP_CMD__`, `__DB_SHELL_CMD__` | from the table below |

| Engine | `__DB_DUMP_CMD__` | `__DB_SHELL_CMD__` |
|---|---|---|
| PostgreSQL | `docker compose exec -T postgres pg_dump -U ${POSTGRES_USER} -d ${POSTGRES_DB}` | `docker compose exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}` |
| MySQL | `docker compose exec -T mysql mysqldump -u${DB_USERNAME} -p${DB_PASSWORD} ${DB_DATABASE}` | `docker compose exec mysql mysql -u${DB_USERNAME} -p${DB_PASSWORD} ${DB_DATABASE}` |

Use the variable names the project actually has. Remove the `run_scheduler`
target and the README section when the project has no scheduler.

## Check

- `docker compose --env-file .env.example config -q` passes with no "variable
  is not set" warning.
- No `build:` is left in the compose, and every image name matches one CI
  pushes.
- Every variable from the project's `.env.example` is in the QA one; list any
  you dropped on purpose.
- `.gitignore` contains `.env`, and no real secret value is in any committed
  file.
- Do not pull images, start the stack, or commit and push the repo unless the
  user asks.
