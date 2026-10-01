"""Build fire-and-forget result messages for the rest_api worker consumer.

Every stateless/async worker replies with one of these instead of a
synchronous ServiceResponse.
"""


def ok_result(
    method: str,
    *,
    task_id: str,
    payload: dict,
    **extra,
) -> dict:
    return {
        "method": method,
        "request": {
            "task_id": task_id,
            "code": 200,
            "payload": payload,
            **extra,
        },
    }


def error_result(
    method: str,
    *,
    task_id: str,
    code: int,
    error: str,
    **extra,
) -> dict:
    return {
        "method": method,
        "request": {
            "task_id": task_id,
            "code": code,
            "error": error,
            **extra,
        },
    }
