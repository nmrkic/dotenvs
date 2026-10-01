from logging.config import fileConfig

from alembic import context
from alembic.script import ScriptDirectory
from sharedlib.db_config import DATABASE_URL, Base
from sqlalchemy import engine_from_config, pool
from sqlalchemy.engine import Connection

from app import models  # noqa: F401 — import so autogenerate sees every model

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata
# Every service shares one Postgres database — a dedicated version table
# keeps each service's Alembic history from colliding with the others.
version_table = "migration___SVC__"


def include_object(object, name, type_, reflected, compare_to):
    _ = object
    skip_tables = ()
    return not (
        (type_ == "table" and reflected and compare_to is None)
        or name in skip_tables
    )


def process_revision_directives(context, revision, directives):
    _ = revision
    migration_script = directives[0]
    head_revision = ScriptDirectory.from_config(context.config).get_current_head()

    if head_revision is None:
        new_rev_id = 1
    else:
        last_rev_id = int(head_revision.lstrip("0") or "0")
        new_rev_id = last_rev_id + 1
    migration_script.rev_id = f"{new_rev_id:04}"


def run_migrations_offline() -> None:
    context.configure(
        url=DATABASE_URL,
        target_metadata=target_metadata,
        version_table=version_table,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        include_object=include_object,
        process_revision_directives=process_revision_directives,
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        version_table=version_table,
        target_metadata=target_metadata,
        include_object=include_object,
        process_revision_directives=process_revision_directives,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    configuration = config.get_section(config.config_ini_section)
    if configuration is None:
        raise ValueError("Configuration section not found in alembic.ini")
    configuration["sqlalchemy.url"] = DATABASE_URL
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        do_run_migrations(connection=connection)

    connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
