#!/usr/bin/env bash
# Idempotent bootstrap for the SwimOS monorepo (Cloud Agent `install` phase).
# Prepares the Python scraper (SwimScraper) and the Flutter app (swim-tracker)
# after the repository has been checked out.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_VERSION="3.47.4"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

echo "==> SwimOS install: repo root = $REPO_ROOT"

# --- Ensure python venv support is present (no-op if already installed) ---
if ! python3 -c "import ensurepip" >/dev/null 2>&1; then
  echo "==> Installing python3-venv"
  sudo apt-get update -qq
  sudo apt-get install -y -qq python3-venv
fi

# --- Ensure the Flutter SDK is available (baked into the base image/snapshot;
#     downloaded here as a self-healing fallback) ---
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "==> Flutter SDK not found; downloading $FLUTTER_VERSION"
  tarball="/tmp/flutter_${FLUTTER_VERSION}.tar.xz"
  curl -fL -o "$tarball" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  rm -rf "$FLUTTER_HOME"
  tar xf "$tarball" -C "$(dirname "$FLUTTER_HOME")"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

# --- Put flutter/dart on PATH for every shell (agent terminals included) ---
sudo ln -sf "$FLUTTER_HOME/bin/flutter" /usr/local/bin/flutter
sudo ln -sf "$FLUTTER_HOME/bin/dart" /usr/local/bin/dart

# Flutter needs to trust the repo directory it operates in.
git config --global --add safe.directory "$REPO_ROOT" 2>/dev/null || true
flutter config --enable-web --no-analytics >/dev/null 2>&1 || true

# --- SwimScraper (Python scraping engine + FastAPI service) ---
echo "==> Setting up SwimScraper (Python)"
cd "$REPO_ROOT/SwimScraper"
if [ ! -d venv ]; then
  python3 -m venv venv
fi
# shellcheck disable=SC1091
source venv/bin/activate
pip install --upgrade pip -q
pip install -e . -q
# Dependencies required to run the FastAPI service under api/
pip install -q fastapi==0.104.1 "uvicorn[standard]==0.24.0"
deactivate

# --- swim-tracker (Flutter mobile/web app) ---
echo "==> Setting up swim-tracker (Flutter)"
cd "$REPO_ROOT/swim-tracker"
# The app loads a .env asset at runtime (Supabase creds are set in lib/main.dart;
# these AI keys are optional). Create a placeholder if the developer has none.
if [ ! -f .env ]; then
  cat > .env <<'ENVEOF'
# Optional AI provider keys for the goal-suggestions feature.
# Leave blank to disable AI suggestions. Supabase credentials live in lib/main.dart.
GROQ_API_KEY=
OPENAI_API_KEY=
GEMINI_API_KEY=
ENVEOF
  echo "==> Created placeholder swim-tracker/.env"
fi
flutter pub get

echo "==> SwimOS install complete."
