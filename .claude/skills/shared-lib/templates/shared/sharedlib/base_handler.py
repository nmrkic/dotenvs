"""Every domain-service handler subclasses this instead of `mrkutil.base.BaseHandler`
directly, so a raised `ServiceException` turns into a `ServiceResponse` without
each handler building one on every error path.

It also ends the thread's SQLAlchemy session after every message (see
`_end_db_session`).
"""

import logging
import sys

from mrkutil.base import BaseHandler as MrkutilBaseHandler
from mrkutil.responses import ServiceResponse

from sharedlib.exceptions import ServiceException

logger = logging.getLogger(__name__)


def _end_db_session() -> None:
    """`Session` is a per-thread `scoped_session` that would otherwise live
    as long as the worker thread: a handler whose commit failed would leave
    it in a failed transaction for the next message, and reads could return
    rows another thread changed since (stale identity map). `remove()`
    closes it — rolling back anything uncommitted — and the next message
    starts fresh. Services without a database never import `db_config`, so
    there is nothing to end (and importing it would create an engine)."""
    db_config = sys.modules.get("sharedlib.db_config")
    if db_config is None:
        return
    try:
        db_config.Session.remove()
    except Exception:
        logger.exception("Failed to end the database session")


class BaseHandler(MrkutilBaseHandler):
    @classmethod
    def process_data(cls, data: dict, corr_id: str) -> dict:
        try:
            return cls._process_data(data, corr_id)
        finally:
            _end_db_session()

    @classmethod
    def _process_data(cls, data: dict, corr_id: str) -> dict:
        try:
            return super().process_data(data, corr_id)
        except ServiceException as exc:
            logger.warning(
                "ServiceException in method=%s: %s", data.get("method"), exc.message
            )
            return ServiceResponse(
                code=exc.code,
                message=exc.message,
                errors=exc.errors,
                params=exc.params,
            )
        except Exception:
            logger.exception(
                "Unhandled exception processing method=%s", data.get("method")
            )
            return ServiceResponse(code=500, message="Internal error")
