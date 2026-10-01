from app.handlers.health import HealthHandler


def test_health_handler():
    result = HealthHandler().process({}, corr_id="test-corr")
    assert result["code"] == 200
