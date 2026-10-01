# sharedlib

Local editable package shared by every __PROJECT_TITLE__ service — **not** a
replacement for [`mrkutil`](https://pypi.org/project/mrkutil/), which already
provides `BaseHandler`, `ServiceResponse`, `listen`, `call_service` /
`acall_service` / `atrigger_service`. This package only holds the bits that
would otherwise be copy-pasted across services:

- `base_handler.py` — `BaseHandler` that turns `ServiceException` into a
  `ServiceResponse` and ends the DB session after every message
- `exceptions.py` — `ServiceException`
- `db_config.py` — sync SQLAlchemy engine, `Session`, `Base`, id/created mixins
- `service_client.py` — sync service → service RPC
- `exchanges.py` — RabbitMQ exchange name constants
- `results.py` — `ok_result` / `error_result` for fire-and-forget `*_result`
  messages
- `testing.py` — throwaway `test_db` for DB-backed tests

## Usage

Consuming services add it via `uv`:

```toml
[project]
dependencies = ["sharedlib"]

[tool.uv.sources]
sharedlib = { path = "../shared", editable = true }
```

## Tests / lint

```bash
uv sync
uv run pytest
uvx ruff check
```
