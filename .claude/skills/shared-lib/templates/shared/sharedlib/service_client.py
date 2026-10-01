"""Sync service → service RPC for domain handlers: a service may call a
service on a lower level of the dependency graph, never the other way around — a cycle
means both sides block until timeout.

Handlers run in listener threads (MAX_THREADS), so blocking on
`call_service` here is fine.
"""

import logging
from typing import Any

from mrkutil.communication import call_service

from sharedlib.exceptions import ServiceException

logger = logging.getLogger(__name__)


class ServiceClient:
    def __init__(self, source: str) -> None:
        # Replies go to the caller's own exchange (same as rest_api); the
        # listener ignores them since they carry no `method`. Every call gets
        # a fresh uuid4 corr_id (none is passed) — replies are matched only by
        # corr_id, so never reuse one across calls (e.g. for tracing).
        self._source = source

    def call(
        self,
        *,
        method: str,
        destination: str,
        request: dict | None = None,
        timeout: int = 30,
    ) -> Any:
        """Returns the callee's `response` on 200; otherwise raises
        `ServiceException` with the callee's code/message, so the calling
        handler's `BaseHandler` passes the error through unchanged."""
        try:
            result = call_service(
                request_data={"method": method, "request": request or {}},
                destination=destination,
                source=self._source,
                timeout=timeout,
            )
        except Exception as exc:
            logger.exception("Call %s.%s failed", destination, method)
            raise ServiceException(503, f"Service {destination} unavailable") from exc

        if result.get("code") != 200:
            response = result.get("response")
            if isinstance(response, dict):
                raise ServiceException(
                    result.get("code", 500),
                    response.get("message") or "Request failed",
                    errors=response.get("errors"),
                    params=response.get("params"),
                )
            raise ServiceException(
                result.get("code", 500), str(response or "Request failed")
            )
        return result.get("response")
