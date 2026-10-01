---
name: service-scaffold
description: Create a new empty Python RabbitMQ worker service in the user's microservice monorepo layout (uv project with `app/handlers`, `app/managers`, `app/models`, `app/schemas`, Alembic, `scripts/run.sh`, tests, Makefile) and wire it into the repo (root Makefile, docker-compose, .env.example, shared exchanges, rest_api settings, docs). Use when the user asks for a new service, an empty service, a service skeleton, or asks where handlers, managers, models or schemas go ("novi servis", "prazan servis", "napravi servis", "new service", "scaffold service", "struktura servisa").
---

# Service scaffold

Every domain service is a folder in the repo root with the same shape. The
empty skeleton is in `templates/service/` next to this file.

## Layout and what goes where

```
<service>/
├── Dockerfile               # from the service-dockerfiles skill
├── Makefile                 # env, infra, run, test, lint, migrations, migrate, ...
├── pyproject.toml           # uv project; script `<service> = "app.run:main"`
├── uv.lock                  # generated
├── .python-version
├── README.md
├── alembic.ini
├── scripts/
│   └── run.sh               # container entrypoint: migrate, then exec the worker
├── app/
│   ├── __init__.py          # empty
│   ├── run.py               # pidfile + mrkutil `listen(...)`; do not add logic here
│   ├── settings.py          # pydantic-settings, reads the root .env
│   ├── handlers/            # one file per RPC method
│   ├── managers/            # database access and business logic
│   ├── models/              # one file per SQLAlchemy model
│   ├── schemas/             # pydantic models for payloads, when needed
│   └── alembic/
│       ├── env.py           # version_table = "migration_<service>"
│       ├── script.py.mako
│       └── versions/        # 0001.py, 0002.py, ...
└── tests/
    ├── __init__.py
    └── test_handlers.py
```

| Folder | Rule |
|---|---|
| `handlers/` | One file and one class per method. File `<service>_<action>.py`, class `<Entity><Action>Handler(BaseHandler)` from `sharedlib.base_handler`, `name()` returns the method string (`employee_get_all`). `process(self, data, corr_id)` reads `data.get("request") or {}`, validates, calls a manager and returns `ServiceResponse(code=200, message=...)`. Expected errors are raised as `ServiceException(code, message)`. No SQL here. Helpers shared by several handlers go in a file starting with `_` (`_common.py`). Every handler is imported and listed in `handlers/__init__.py`, otherwise it is never registered. |
| `managers/` | One class per entity (`EmployeeManager` in `employee.py`), `self.session = Session()` in `__init__`, methods do the queries and commits. Clients for other services and storage wrappers also live here (`service_client.py`, `file_storage.py`). Exported from `managers/__init__.py`. |
| `models/` | One file per table, class `<Entity>Model(IdMixin, CreatedMixin, Base)` with `Mapped[...]` columns and a `to_dict()`. `models/__init__.py` imports `Base, Session` from `sharedlib.db_config` first, then every model, and lists them in `__all__` (Alembic autogenerate sees only what is imported there). Business tables carry `tenant_id` when the project is multi-tenant; references to other services' rows are plain ids, no foreign keys. |
| `schemas/` | Pydantic models for structured payloads. Empty `__init__.py` until needed. |
| `tests/` | Handler tests with the manager patched (`@patch("app.handlers.<file>.<Manager>")`); they must not need a database. DB-backed manager tests opt in through a `test_database` fixture in `conftest.py` that calls `sharedlib.testing.create_test_database()`. |

## Creating a service

Inputs: service name in snake_case (`feature_flags`), a one-line description,
and whether it has a database. Take the rest from the repo.

1. Read a sibling service and the root `Makefile`, `docker-compose.yml` and
   `.env.example` first. If the repo differs from the template (Python version,
   dependency pins, database URL, extra infra), follow the repo.
2. Copy `templates/service/` to `<repo>/<service>/`, including `.python-version`
   and `app/alembic/versions/.gitkeep`. Keep `scripts/run.sh` executable.
3. Replace the placeholders in every file:

   | Placeholder | Value | Example |
   |---|---|---|
   | `__SVC__` | service name, snake_case | `feature_flags` |
   | `__SVC_UPPER__` | upper case | `FEATURE_FLAGS` |
   | `__SVC_DASH__` | dashes instead of underscores | `feature-flags` |
   | `__PROJECT__` | project slug with dashes | `agency-helper` |
   | `__PROJECT_TITLE__` | human project name | `Agency Helper` |
   | `__DESCRIPTION__` | what the service owns | `employees` |
   | `__DATABASE_URL__` | local default, same as `.env.example` | |

   In `settings.py` make `APP_NAME` read naturally
   (`"Agency Helper Feature Flags"`). Use the dependency versions of the sibling
   services if they are newer than the template's.
4. Add the Dockerfile with the `service-dockerfiles` skill
   (`worker.Dockerfile`, or `worker-stateless.Dockerfile` without a database).
5. Wire the service into the repo (next section).
6. In the service folder run `uv sync`, then `uv run pytest` and
   `uvx ruff check`. Report the results. `uv.lock` must be committed, the
   Dockerfile needs it.

The skeleton ships with only `HealthHandler` (`<service>_health`), no models
and no migrations. Add the first model, then `make migrations message="..."`
to create `versions/0001.py`.

### Service without a database

Remove `alembic.ini`, `app/alembic/`, `app/models/`, `scripts/`; remove
`sqlalchemy`, `psycopg` and `alembic` from `pyproject.toml` and
`"app/alembic/*"` from the coverage `omit`; remove `DATABASE_URL` and the two
`os.environ.setdefault` lines for it from `settings.py`; in the `Makefile`
remove `ALEMBIC`, the migration targets, `postgres` from `infra`, and change
`run: infra migrate` to `run: infra`.

## Wiring into the repo

Do all of these, following the entries of the sibling services:

- **Root `Makefile`**: add the name to `SERVICES` and `.PHONY`, add
  `$(MAKE) -C <service> env|test|lint` lines, a `run-<service>` target, and the
  name in the `help` text.
- **`docker-compose.yml`**: service block from the `service-dockerfiles` skill.
- **`.env.example`** (and the local `.env`, without printing its contents):

  ```
  # =============================================================================
  # <service> (RabbitMQ worker — <description>)
  # =============================================================================
  EXCHANGE_<SERVICE>=<service>
  EXCHANGE_TYPE_<SERVICE>=direct
  QUEUE_<SERVICE>=<service>_queue
  ```
- **`shared/sharedlib/exchanges.py`**: `EXCHANGE_<SERVICE> = "<service>"`.
- **`rest_api/app/settings.py`**: `EXCHANGE_<SERVICE>: str = "<service>"` in the
  destination exchanges, if the gateway will call the service.
- **Docs**: the services table in `README.md` and, when present,
  `docs/architecture.md` (table row, and the service's place in the
  communication graph: which services it may call).
- **Deployment**, when the repo has them: `kubernetes/charts/*/values.yaml`
  `services` list and the CI build matrix plus `docker-bake.hcl`
  (`k8s-chart-deployment` and `gitlab-cicd` skills).

Exposing the service over HTTP is separate work in `rest_api` (a router in
`app/api/`, schemas in `app/schemas/`, permission checks); do it only when the
user asks for endpoints.
