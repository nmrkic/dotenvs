from sharedlib.base_handler import BaseHandler
from sharedlib.exceptions import ServiceException


class _RaisesServiceException(BaseHandler):
    @staticmethod
    def name():
        return "test_raise_service_exception"

    def process(self, data: dict, corr_id: str) -> dict:
        raise ServiceException(400, "bad input", errors=["email is required"])


class _RaisesGenericException(BaseHandler):
    @staticmethod
    def name():
        return "test_raise_generic_exception"

    def process(self, data: dict, corr_id: str) -> dict:
        raise RuntimeError("boom")


def test_service_exception_becomes_service_response():
    result = BaseHandler.process_data(
        {"method": "test_raise_service_exception"}, "corr-1"
    )
    assert result["code"] == 400
    assert result["response"]["message"] == "bad input"
    assert result["response"]["errors"] == ["email is required"]


def test_generic_exception_becomes_500_without_crashing_worker():
    result = BaseHandler.process_data(
        {"method": "test_raise_generic_exception"}, "corr-2"
    )
    assert result["code"] == 500


def test_unknown_method_falls_through_to_mrkutil_404():
    result = BaseHandler.process_data({"method": "no_such_method"}, "corr-3")
    assert result["code"] == 404


def test_db_session_is_ended_after_every_message(monkeypatch):
    import sys
    from types import SimpleNamespace
    from unittest.mock import MagicMock

    session = MagicMock()
    monkeypatch.setitem(sys.modules, "sharedlib.db_config", SimpleNamespace(Session=session))

    BaseHandler.process_data({"method": "test_raise_generic_exception"}, "corr-4")
    BaseHandler.process_data({"method": "test_raise_service_exception"}, "corr-5")
    assert session.remove.call_count == 2


def test_failing_session_cleanup_does_not_change_the_response(monkeypatch):
    import sys
    from types import SimpleNamespace
    from unittest.mock import MagicMock

    session = MagicMock()
    session.remove.side_effect = RuntimeError("db gone")
    monkeypatch.setitem(sys.modules, "sharedlib.db_config", SimpleNamespace(Session=session))

    result = BaseHandler.process_data({"method": "test_raise_service_exception"}, "corr-6")
    assert result["code"] == 400
