#!/usr/bin/env bash
set -e

echo "🧹 Stopping and removing existing containers..."
docker compose down --remove-orphans

echo "🗑 Removing old project images (if any)..."
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "passivbot|pbgui" || true)
if [ -n "$IMAGES" ]; then
  docker rmi -f $IMAGES || true
else
  echo "No project images found."
fi

echo "🧼 Pruning Docker builder cache..."
docker builder prune -f

echo "🔨 Building docker-compose (no cache)..."
docker compose build --no-cache

echo "🚀 Starting containers..."
docker compose up -d

echo "✅ Done!"
echo "📌 Use: docker compose logs -f pbgui"
