SHELL := /bin/bash
include ../.env
export

COMPOSE := docker compose -f ../docker-compose.yml
ALEMBIC := uv run alembic -c alembic.ini

.PHONY: env infra run test lint migrations migrate downgrade init_db check_db history heads

env:
	uv sync

infra:
	@echo "Starting required Docker services (rabbit, postgres)..."
	$(COMPOSE) up -d --wait rabbit postgres

migrations:
	@echo "Generating migrations ..."
	$(ALEMBIC) revision --autogenerate -m "${message}"

migrate:
	@echo "Running migrations ..."
	$(ALEMBIC) ensure_version
	$(ALEMBIC) upgrade head
	@echo "Migrations finished."

downgrade:
	@echo "Running downgrade ..."
	$(ALEMBIC) downgrade ${level}
	@echo "Downgrade finished."

init_db:
	@echo "Initing database ..."
	$(ALEMBIC) ensure_version
	@echo "Version table ready."

check_db:
	@echo "Checking migrations ..."
	$(ALEMBIC) check
	@echo "Check finished."

history:
	$(ALEMBIC) history --verbose

heads:
	$(ALEMBIC) heads --verbose

run: infra migrate
	@echo "Running __SVC__ worker..."
	uv run __SVC__

test:
	@echo "Running unit tests..."
	env DATABASE_URL=$(TEST_DATABASE_URL) uv run coverage run -m pytest ${module} && \
	uv run coverage html && \
	uv run coverage report
	@echo
	@echo "Ruff errors in code ----------------"
	uvx ruff check
	@echo "OK, no ruff errors in code"

lint:
	uvx ruff check
