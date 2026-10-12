
#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="ghcr.io/hasaranga001/weather-app:latest"
CONTAINER="weather-app"
PORT="5000"

echo "Pulling latest image..."
sudo docker pull "$IMAGE"

echo "Saving current image for rollback..."
OLD_IMAGE=$(sudo docker inspect --format='{{.Image}}' "$CONTAINER" 2>/dev/null || true)

echo "Stopping old container..."
sudo docker rm -f "$CONTAINER" 2>/dev/null || true

echo "Starting new container..."
sudo docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p "$PORT:5000" \
  "$IMAGE"

echo "Waiting for health check..."
for i in {1..15}; do
  HEALTH=$(sudo docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$CONTAINER")
  if [[ "$HEALTH" == "healthy" ]]; then
    echo "Deployment successful: container is healthy."
    exit 0
  fi
  sleep 2
done

echo "Health check failed. Showing logs:"
sudo docker logs --tail 50 "$CONTAINER"
echo "Deployment failed. Previous image ID: ${OLD_IMAGE:-unknown}"
exit 1

