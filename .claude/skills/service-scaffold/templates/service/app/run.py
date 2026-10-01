import logging
import os
import sys

from mrkutil.communication import listen
from sharedlib.base_handler import BaseHandler

from app import handlers  # noqa: F401 — register handler subclasses
from app.settings import settings

logging.basicConfig(level=settings.LOG_LEVEL.upper())
logger = logging.getLogger("__SVC__")


def _pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def main() -> None:
    """RabbitMQ worker entry point."""
    try:
        if not os.path.isdir("/tmp/service"):
            os.makedirs("/tmp/service")
        pidfile = "/tmp/service/service___SVC__.pid"
        if os.path.isfile(pidfile):
            try:
                with open(pidfile, encoding="utf-8") as f:
                    old_pid = int(f.read().strip())
            except (OSError, ValueError):
                old_pid = None
            # Stale pidfiles survive watchfiles/docker kill — only bail if alive.
            if old_pid and _pid_alive(old_pid):
                logger.warning("__SVC__ is already running (pid=%s)", old_pid)
                sys.exit(1)
            try:
                os.unlink(pidfile)
            except OSError:
                pass
        with open(pidfile, "w", encoding="utf-8") as file:
            file.write(str(os.getpid()))
            file.write("\n")
        try:
            logger.info(
                "Starting __SVC__ worker on exchange=%s queue=%s",
                settings.EXCHANGE___SVC_UPPER__,
                settings.QUEUE___SVC_UPPER__,
            )
            listen(
                exchange=settings.EXCHANGE___SVC_UPPER__,
                exchange_type=settings.EXCHANGE_TYPE___SVC_UPPER__,
                queue=settings.QUEUE___SVC_UPPER__,
                max_threads=settings.MAX_THREADS,
                base_handler=BaseHandler,
            )
            sys.exit(0)
        finally:
            if os.path.isfile(pidfile):
                os.unlink(pidfile)
    except KeyboardInterrupt:
        logger.info("Shutting down __SVC__ worker …")


if __name__ == "__main__":
    if settings.DEVELOP:
        from watchfiles import run_process

        logger.info("Develop mode: watching ./app for changes")
        run_process("./app", target=main)
    else:
        main()
