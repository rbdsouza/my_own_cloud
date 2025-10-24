#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
fi

if ! command -v docker compose >/dev/null 2>&1; then
  echo "Installing docker compose plugin..."
  mkdir -p ~/.docker/cli-plugins
  curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-$(uname -m) -o ~/.docker/cli-plugins/docker-compose
  chmod +x ~/.docker/cli-plugins/docker-compose
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created default .env file. Update secrets ASAP."
fi

echo "Starting core services..."
docker compose --profile core up -d

if [[ "${1:-}" != "--no-wifi" ]]; then
  echo "Starting Wi-Fi onboarding..."
  docker compose --profile wifi up -d
fi

echo "Starting application services..."
docker compose --profile apps up -d

echo "EdgeBox is up!"
cat <<INFO
Accessible services (update LAN_HOST if customized):
  - http://portainer.${LAN_HOST}
  - http://files.${LAN_HOST}
  - http://sign.${LAN_HOST}
  - http://grafana.${LAN_HOST}
  - http://counter.${LAN_HOST}/metrics
  - http://api.${LAN_HOST}
INFO
