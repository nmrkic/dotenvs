"""Shared SQLAlchemy setup — one engine/Session for every domain service.

Synchronous SQLAlchemy (`create_engine` + `scoped_session`), not async.
Domain services here are RabbitMQ workers with a synchronous `BaseHandler.process()` entry
point (see mrkutil.base.BaseHandler) — sync SQLAlchemy is the natural fit,
no `asyncio.run()` wrapping needed around every DB call.

All services share one Postgres database, so a single module-level engine/Session
here is safe: every service process reads the same DATABASE_URL and gets
its own engine/pool, but they all point at the same database.
"""

import datetime as dt
import logging
import os

from sqlalchemy import BigInteger, create_engine, func
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    MappedAsDataclass,
    mapped_column,
    scoped_session,
    sessionmaker,
)
from sqlalchemy.schema import MetaData

logger = logging.getLogger(__name__)

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "__DATABASE_URL__",
)


class CreatedMixin(MappedAsDataclass):
    created_at: Mapped[dt.datetime] = mapped_column(
        default=None, server_default=func.now(), kw_only=True
    )


class CreatedUpdatedMixin(CreatedMixin):
    updated_at: Mapped[dt.datetime] = mapped_column(
        default=None,
        onupdate=func.now(),
        server_onupdate=func.now(),
        nullable=True,
        kw_only=True,
    )


class IdMixin(MappedAsDataclass):
    id: Mapped[int] = mapped_column(
        BigInteger,
        init=False,
        primary_key=True,
        autoincrement=True,
    )


class Base(MappedAsDataclass, DeclarativeBase):
    """subclasses are converted to dataclasses (see MappedAsDataclass)."""

    metadata = MetaData(
        naming_convention={
            "ix": "ix_%(column_0_label)s",
            "uq": "uq_%(table_name)s_%(column_0_name)s",
            "ck": "ck_%(table_name)s_%(constraint_name)s",
            "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
            "pk": "pk_%(table_name)s",
        }
    )


engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=int(os.environ.get("MAX_THREADS", "5")),
    pool_recycle=3600,
)
session_maker = sessionmaker(autocommit=False, autoflush=True, bind=engine)
Session = scoped_session(session_maker)
