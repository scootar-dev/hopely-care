#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ! -f .env ]]; then
  echo "Missing .env in the deployment directory." >&2
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  compose=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  compose=(docker-compose)
else
  echo "Docker Compose is not installed (docker compose or docker-compose)." >&2
  exit 1
fi

"${compose[@]}" up -d --build --remove-orphans

for attempt in $(seq 1 60); do
  if curl --fail --silent --show-error --max-time 5 http://127.0.0.1:8000/up >/dev/null; then
    "${compose[@]}" ps
    exit 0
  fi
  sleep 5
done

"${compose[@]}" ps
"${compose[@]}" logs --tail=120 backend ai-service || true
echo "The production stack did not become ready within five minutes." >&2
exit 1
