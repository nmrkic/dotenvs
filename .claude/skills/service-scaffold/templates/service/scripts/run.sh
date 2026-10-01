#!/usr/bin/env bash
set -euo pipefail

echo "Ensuring Alembic version table..."
alembic -c alembic.ini ensure_version

echo "Running migrations..."
alembic -c alembic.ini upgrade head

echo "Starting worker..."
exec "$@"
