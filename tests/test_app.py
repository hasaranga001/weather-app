
from unittest.mock import patch, Mock

from app import app


def test_weather_homepage():
    app.config["TESTING"] = True

    geo_response = Mock()
    geo_response.json.return_value = {
        "results": [
            {
                "name": "London",
                "country": "United Kingdom",
                "latitude": 51.5,
                "longitude": -0.12,
            }
        ]
    }

    weather_response = Mock()
    weather_response.json.return_value = {
        "current": {
            "temperature_2m": 18,
            "relative_humidity_2m": 65,
            "apparent_temperature": 18,
            "precipitation": 0,
            "weather_code": 1,
            "wind_speed_10m": 12,
            "time": "2026-10-09T12:00",
        }
    }

    with patch(
        "app.requests.get",
        side_effect=[geo_response, weather_response],
    ):
        client = app.test_client()
        response = client.get("/?city=London")

    assert response.status_code == 200
    assert b"London" in response.data
    assert b"18" in response.data

