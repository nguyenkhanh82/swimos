#!/usr/bin/env bash
# Deploy motivational time standards from time_standard.json to the linked Supabase DB.
# Loads .env from repo root (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY) and runs the sync script.
set -e
cd "$(dirname "$0")/.."
if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi
python3 scripts/sync_time_standards_to_db.py
