"""Throwaway Postgres database for DB-backed manager tests.

`make test` points DATABASE_URL at
TEST_DATABASE_URL, and a session fixture calls `create_test_database()` to
recreate it and run the calling service's migrations. Anything not named
`test_db` is refused, so a bare `uv run pytest` can never wipe the shared
dev database.
"""

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.pool import NullPool

from sharedlib.db_config import DATABASE_URL, engine

TEST_DATABASE = "test_db"


def create_test_database(alembic_ini: str = "alembic.ini") -> None:
    url = make_url(DATABASE_URL)
    if url.database != TEST_DATABASE:
        raise RuntimeError(
            f"DB tests need DATABASE_URL pointing at '{TEST_DATABASE}', got "
            f"'{url.database}' — run them through `make test`"
        )

    server = create_engine(
        url.set(database="postgres"),
        isolation_level="AUTOCOMMIT",
        poolclass=NullPool,
    )
    with server.connect() as conn:
        conn.execute(text(f"DROP DATABASE IF EXISTS {TEST_DATABASE} WITH (FORCE)"))
        conn.execute(text(f"CREATE DATABASE {TEST_DATABASE}"))
    server.dispose()
    engine.dispose()  # pooled connections point at the dropped database

    command.upgrade(Config(alembic_ini), "head")
