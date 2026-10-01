# Build context is the repo root (docker-compose sets `dockerfile: rest_api/Dockerfile`)
# so this stage can also COPY the sibling `shared` editable package.
ARG PYTHON_VERSION=3.13-slim-bookworm
ARG TARGET=prod

FROM python:${PYTHON_VERSION} AS base
ENV PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY shared /shared

# ---- dev: editable install, live reload, source is bind-mounted ----
FROM base AS dev
COPY rest_api/pyproject.toml rest_api/uv.lock rest_api/README.md ./
RUN uv sync --frozen
COPY rest_api/app ./app
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8100
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8100", "--reload"]

# ---- builder: production dependency install ----
FROM base AS builder
COPY rest_api/pyproject.toml rest_api/uv.lock rest_api/README.md ./
RUN uv sync --frozen --no-install-project --no-dev --no-cache --no-editable
COPY rest_api/app ./app
RUN uv sync --frozen --no-dev --no-cache --no-editable

# ---- prod: slim runtime image ----
FROM python:${PYTHON_VERSION} AS prod
ENV PYTHONUNBUFFERED=1
WORKDIR /app

COPY --from=builder /app/.venv .venv
COPY --from=builder /app/app ./app

ENV PATH="/app/.venv/bin:$PATH"

RUN useradd -m appuser && chown -R appuser /app
USER appuser

EXPOSE 8100
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8100"]

FROM ${TARGET}
