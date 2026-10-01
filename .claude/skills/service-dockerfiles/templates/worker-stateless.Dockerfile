# Build context is the repo root (docker-compose sets `dockerfile: __SVC__/Dockerfile`)
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

# ---- dev: editable install, live reload via watchfiles when DEVELOP=true ----
FROM base AS dev
COPY __SVC__/pyproject.toml __SVC__/uv.lock __SVC__/README.md ./
RUN uv sync --frozen
COPY __SVC__/app ./app
ENV PATH="/app/.venv/bin:$PATH"
CMD ["uv", "run", "__SVC__"]

# ---- builder: production dependency install ----
FROM base AS builder
COPY __SVC__/pyproject.toml __SVC__/uv.lock __SVC__/README.md ./
RUN uv sync --frozen --no-install-project --no-dev --no-cache --no-editable
COPY __SVC__/app ./app
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

CMD ["__SVC__"]

FROM ${TARGET}
