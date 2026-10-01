# __PROJECT_TITLE__ — __SVC__

RabbitMQ worker — __DESCRIPTION__. Handlers subclass
`sharedlib.base_handler.BaseHandler` and are served by
`mrkutil.communication.listen`; the service has its own tables and Alembic
migrations (`version_table = "migration___SVC__"`, since the database is shared
across every service).

## Local development

```bash
uv sync
uv run alembic -c alembic.ini upgrade head
uv run __SVC__
```

With `DEVELOP=true`, the process reloads on `./app` changes via watchfiles.

## Tests / lint

```bash
uv run pytest
uvx ruff check
```
