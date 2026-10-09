
from flask import Flask, render_template, request
import requests

app = Flask(__name__)

WEATHER_CODES = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Fog",
    51: "Light drizzle",
    53: "Drizzle",
    55: "Heavy drizzle",
    61: "Light rain",
    63: "Moderate rain",
    65: "Heavy rain",
    71: "Light snow",
    73: "Snow",
    75: "Heavy snow",
    80: "Rain showers",
    81: "Rain showers",
    82: "Heavy rain showers",
    95: "Thunderstorm",
}


@app.route("/")
def home():
    city = request.args.get("city", "London").strip()[:100]
    weather = None
    error = None

    if not city:
        city = "London"

    try:
        geo = requests.get(
            "https://geocoding-api.open-meteo.com/v1/search",
            params={"name": city, "count": 1, "language": "en"},
            timeout=10,
        )
        geo.raise_for_status()
        locations = geo.json().get("results", [])

        if not locations:
            error = f"No location found for '{city}'."
        else:
            location = locations[0]

            response = requests.get(
                "https://api.open-meteo.com/v1/forecast",
                params={
                    "latitude": location["latitude"],
                    "longitude": location["longitude"],
                    "current": (
                        "temperature_2m,relative_humidity_2m,"
                        "apparent_temperature,precipitation,"
                        "weather_code,wind_speed_10m"
                    ),
                    "timezone": "auto",
                },
                timeout=10,
            )
            response.raise_for_status()
            current = response.json()["current"]

            weather = {
                "city": location["name"],
                "country": location.get("country", ""),
                "temperature": current["temperature_2m"],
                "feels_like": current["apparent_temperature"],
                "humidity": current["relative_humidity_2m"],
                "wind": current["wind_speed_10m"],
                "precipitation": current["precipitation"],
                "condition": WEATHER_CODES.get(
                    current["weather_code"], "Other conditions"
                ),
                "time": current["time"],
            }

    except (requests.RequestException, ValueError, KeyError):
        error = "Weather data is temporarily unavailable. Please try again."

    return render_template(
        "index.html", weather=weather, error=error, city=city
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

