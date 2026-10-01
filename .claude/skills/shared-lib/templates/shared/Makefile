SHELL := /bin/bash

.PHONY: env test lint

env:
	uv sync

test:
	@echo "Running unit tests..."
	uv run coverage run -m pytest ${module} && \
	uv run coverage html && \
	uv run coverage report
	@echo
	@echo "Ruff errors in code ----------------"
	uvx ruff check
	@echo "OK, no ruff errors in code"

lint:
	uvx ruff check
