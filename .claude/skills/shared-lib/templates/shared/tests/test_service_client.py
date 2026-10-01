from unittest.mock import patch

import pytest

from sharedlib.exceptions import ServiceException
from sharedlib.service_client import ServiceClient


def test_call_returns_response_and_uses_own_exchange():
    with patch(
        "sharedlib.service_client.call_service",
        return_value={"code": 200, "response": [{"id": 1}]},
    ) as mock_call:
        result = ServiceClient("expense").call(
            method="employee_get_by_ids",
            destination="employee",
            request={"tenant_id": 1},
        )

    assert result == [{"id": 1}]
    mock_call.assert_called_once_with(
        request_data={"method": "employee_get_by_ids", "request": {"tenant_id": 1}},
        destination="employee",
        source="expense",
        timeout=30,
    )


def test_error_response_becomes_service_exception():
    with (
        patch(
            "sharedlib.service_client.call_service",
            return_value={
                "code": 404,
                "response": {
                    "message": "Not found",
                    "errors": ["x"],
                    "params": {"id": 1},
                },
            },
        ),
        pytest.raises(ServiceException) as exc_info,
    ):
        ServiceClient("expense").call(method="m", destination="employee")

    assert exc_info.value.code == 404
    assert exc_info.value.message == "Not found"
    assert exc_info.value.errors == ["x"]
    assert exc_info.value.params == {"id": 1}


def test_timeout_becomes_503():
    with (
        patch(
            "sharedlib.service_client.call_service",
            side_effect=Exception("Timeout occured waiting for response."),
        ),
        pytest.raises(ServiceException) as exc_info,
    ):
        ServiceClient("expense").call(method="m", destination="employee")

    assert exc_info.value.code == 503
