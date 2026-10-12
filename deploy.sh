
#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="ghcr.io/hasaranga001/weather-app:latest"
CONTAINER="weather-app"
PORT="5000"

echo "Pulling latest image..."
sudo docker pull "$IMAGE"

echo "Saving current image for rollback..."
OLD_IMAGE=$(sudo docker inspect --format='{{.Image}}' "$CONTAINER" 2>/dev/null || true)

echo "Removing old container..."
sudo docker rm -f "$CONTAINER" 2>/dev/null || true

echo "Starting new container..."
sudo docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p "$PORT:5000" \
  "$IMAGE"

echo "Waiting for health check..."
HEALTHY=false

for i in {1..30}; do
  HEALTH=$(sudo docker inspect \
    --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
    "$CONTAINER")

  if [[ "$HEALTH" == "healthy" ]]; then
    HEALTHY=true
    break
  fi

  sleep 2
done

if [[ "$HEALTHY" == "true" ]]; then
  echo "Deployment successful: container is healthy."
  exit 0
fi

echo "New deployment failed. Showing logs..."
sudo docker logs --tail 50 "$CONTAINER"

if [[ -z "$OLD_IMAGE" ]]; then
  echo "No previous image available. Cannot roll back automatically."
  exit 1
fi

echo "Rolling back to previous image..."
sudo docker rm -f "$CONTAINER" 2>/dev/null || true

sudo docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p "$PORT:5000" \
  "$OLD_IMAGE"

echo "Rollback started. Checking health..."
for i in {1..30}; do
  HEALTH=$(sudo docker inspect \
    --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
    "$CONTAINER")

  if [[ "$HEALTH" == "healthy" ]]; then
    echo "Rollback successful: previous container is healthy."
    exit 1
  fi

  sleep 2
done

echo "CRITICAL: Rollback container is not healthy. Check Docker logs."
sudo docker logs --tail 50 "$CONTAINER"
exit 1

