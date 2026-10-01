from mrkutil.responses import ServiceResponse
from sharedlib.base_handler import BaseHandler


class HealthHandler(BaseHandler):
    @staticmethod
    def name() -> str:
        return "__SVC___health"

    def process(self, data: dict, corr_id: str) -> dict:
        return ServiceResponse(code=200, message="__SVC__ is healthy")
