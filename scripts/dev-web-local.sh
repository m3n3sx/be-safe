#!/usr/bin/env bash
# Local Next.js against production API (no Docker rebuilds).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/web"

if [[ ! -f .env.local ]]; then
  cat > .env.local <<'EOF'
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=
NEXT_PUBLIC_API_URL=https://besafe.org.pl/api/v1
NEXT_PUBLIC_SOCKET_URL=https://besafe.org.pl
EOF
  echo "Created web/.env.local — uzupełnij NEXT_PUBLIC_GOOGLE_MAPS_API_KEY"
  echo "Klucz Maps: docs/INFRASTRUCTURE.md lub konsola GCP"
fi

if [[ ! -d node_modules ]]; then
  npm install
fi

exec npm run dev -- --hostname 127.0.0.1 --port 3000
