"""Domain exception raised by handlers — caught by `sharedlib.base_handler.BaseHandler`
and turned into a `ServiceResponse` instead of every handler building one on
each error path.
"""


class ServiceException(Exception):
    def __init__(
        self,
        code: int,
        message: str,
        errors: list | None = None,
        params: dict | None = None,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.errors = errors
        self.params = params
