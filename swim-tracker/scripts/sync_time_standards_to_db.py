#!/usr/bin/env python3
"""
Sync motivational time standards from time_standard.json into the linked Supabase
time_standards table. Inserts all age groups (10 & Under, 11-12, 13-14, 15-16, 17-18)
and all events/courses from the JSON.

Requires: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or ANON key with insert permission).
Usage:
  export SUPABASE_URL=https://xxx.supabase.co
  export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
  python3 scripts/sync_time_standards_to_db.py

Or run the generated migration SQL in Supabase Dashboard > SQL Editor:
  python3 scripts/generate_time_standards_migration.py
  Then run the new migration file in chunks (each INSERT block).
"""

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = REPO_ROOT / "time_standard.json"

# Load .env from repo root if present (so deploy script can use env vars)
def _load_dotenv() -> None:
    env_file = REPO_ROOT / ".env"
    if not env_file.exists():
        return
    try:
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, _, value = line.partition("=")
                key = key.strip()
                value = value.strip().strip("'\"")
                if key and key not in os.environ:
                    os.environ[key] = value
    except Exception:
        pass

EVENT_ABBREV = {
    "FR": ("Free", "Free"),
    "BK": ("Back", "Back"),
    "BR": ("Breast", "Breast"),
    "FL": ("Fly", "Fly"),
    "IM": ("IM", "IM"),
}


def parse_event(code: str) -> tuple[str, str, int]:
    """Return (event_name, stroke, distance). E.g. '50 FR' -> ('50 Free', 'Free', 50)."""
    parts = code.strip().split()
    if not parts:
        return ("", "", 0)
    distance = int(parts[0]) if parts[0].isdigit() else 0
    abbrev = parts[1].upper() if len(parts) > 1 else ""
    stroke = EVENT_ABBREV.get(abbrev, (abbrev, abbrev))[0]
    event_name = f"{distance} {stroke}"
    return (event_name, stroke, distance)


def main() -> None:
    _load_dotenv()
    if not JSON_PATH.exists():
        print(f"Error: {JSON_PATH} not found", file=sys.stderr)
        sys.exit(1)

    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    groups = data.get("groups") or []

    rows: list[dict] = []
    for g in groups:
        age_group = g.get("age_group") or ""
        course = g.get("course") or ""
        gender = g.get("gender") or ""
        event_code = g.get("event") or ""
        event_name, stroke, distance = parse_event(event_code)
        if not stroke:
            continue
        for level in ["B", "BB", "A", "AA", "AAA", "AAAA"]:
            t = g.get(level)
            if t is None:
                continue
            try:
                time_seconds = float(t)
            except (TypeError, ValueError):
                continue
            rows.append({
                "gender": gender,
                "age_group": age_group,
                "course": course,
                "event": event_name,
                "stroke": stroke,
                "distance": distance,
                "standard_level": level,
                "time_seconds": time_seconds,
            })

    url = os.environ.get("SUPABASE_URL") or os.environ.get("VITE_SUPABASE_URL")
    key = (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        or os.environ.get("SUPABASE_ANON_KEY")
        or os.environ.get("VITE_SUPABASE_KEY")
    )
    if not url or not key:
        print("To sync via API, set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or VITE_SUPABASE_URL / VITE_SUPABASE_KEY).", file=sys.stderr)
        print(f"Otherwise run the SQL migration. Generated {len(rows)} rows from JSON.", file=sys.stderr)
        print("Run: python3 scripts/generate_time_standards_migration.py", file=sys.stderr)
        print("Then run the new migration file in Supabase Dashboard > SQL Editor (in chunks if needed).", file=sys.stderr)
        sys.exit(0)

    # Prefer venv site-packages so project's supabase/ folder doesn't shadow the package
    venv_site = REPO_ROOT / ".venv" / "lib" / f"python{sys.version_info.major}.{sys.version_info.minor}" / "site-packages"
    if venv_site.exists():
        sys.path.insert(0, str(venv_site))
    try:
        from supabase import create_client
    except ImportError:
        print("Install supabase: pip install supabase (e.g. in .venv)", file=sys.stderr)
        sys.exit(1)

    client = create_client(url, key)

    # Delete only motivational levels so national tiers are preserved
    client.table("time_standards").delete().in_(
        "standard_level", ["B", "BB", "A", "AA", "AAA", "AAAA"]
    ).execute()

    chunk_size = 100
    inserted = 0
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i : i + chunk_size]
        client.table("time_standards").insert(chunk).execute()
        inserted += len(chunk)
        print(f"Inserted {inserted}/{len(rows)} rows...")

    print(f"Done. Inserted {len(rows)} motivational time standards.")


if __name__ == "__main__":
    main()
