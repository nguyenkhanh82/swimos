#!/usr/bin/env python3
"""
Generate a Supabase migration that INSERTs national time standards from
national_time_standard.json into time_standards (Sectional, Futures, Junior National, National).
Run from repo root: python3 scripts/generate_national_time_standards_migration.py
Output: supabase/migrations/YYYYMMDDHHMMSS_sync_national_time_standards.sql

Requires: migration 20260129000000_time_standards_national_levels_and_age_groups.sql applied first.
"""

import json
import re
from pathlib import Path
from datetime import datetime, timezone

REPO_ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = REPO_ROOT / "national_time_standard.json"
MIGRATIONS_DIR = REPO_ROOT / "supabase" / "migrations"

STROKE_MAP = {"FR": "Free", "BK": "Back", "BR": "Breast", "FL": "Fly", "IM": "IM"}

# Combined events: "400/500 FR" -> SCY uses 500 Free, LCM uses 400 Free
COMBINED_FREE = {
    "400/500 FR": (500, 400),   # SCY 500, LCM 400
    "800/1000 FR": (1000, 800),
    "1500/1650 FR": (1650, 1500),
}


def time_to_seconds(s: str) -> float | None:
    """Convert '1:48.19' or '22.99' to seconds."""
    if not s or not isinstance(s, str):
        return None
    s = s.strip()
    parts = s.split(":")
    if len(parts) == 2:
        try:
            return float(parts[0]) * 60 + float(parts[1])
        except ValueError:
            return None
    try:
        return float(s)
    except ValueError:
        return None


def parse_event_for_course(event_code: str, course: str) -> tuple[str, str, int] | None:
    """
    Return (event_name, stroke, distance) for the given event code and course (SCY or LCM).
    E.g. '50 FR' -> ('50 Free', 'Free', 50); '400/500 FR' + SCY -> ('500 Free', 'Free', 500).
    """
    event_code = event_code.strip()
    if not event_code:
        return None
    parts = event_code.split()
    if len(parts) < 2:
        return None
    abbrev = parts[-1].upper()
    stroke = STROKE_MAP.get(abbrev, abbrev)
    if abbrev != "FR" and "/" not in event_code:
        dist_part = parts[0]
        if dist_part.isdigit():
            d = int(dist_part)
            return (f"{d} {stroke}", stroke, d)
        return None
    if "/" in event_code:
        # e.g. "400/500 FR" -> SCY 500, LCM 400
        pair = COMBINED_FREE.get(event_code)
        if pair:
            scy_d, lcm_d = pair
            d = scy_d if course == "SCY" else lcm_d
            return (f"{d} Free", "Free", d)
    # Simple "50 FR", "100 BK", etc.
    dist_part = parts[0]
    if dist_part.isdigit():
        d = int(dist_part)
        return (f"{d} {stroke}", stroke, d)
    return None


def normalize_age_group(ag: str) -> str:
    if not ag:
        return ag
    a = ag.strip()
    if a.lower() == "19 and over":
        return "19 & Over"
    if a.lower() == "18 and under":
        return "18 & Under"
    if a.lower() == "all age":
        return "All Age"
    return a


def sql_escape(s: str) -> str:
    return s.replace("'", "''")


def main() -> None:
    raw = JSON_PATH.read_text(encoding="utf-8")
    # File may be invalid: "[ { doc1 } ]  { doc2 }  { doc3 }" — normalize to "[ { doc1 }, { doc2 }, { doc3 } ]"
    try:
        docs = json.loads(raw)
    except json.JSONDecodeError:
        raw_fixed = raw.replace("  ]\n  {", "  ,  {")   # first array close then next doc
        raw_fixed = raw_fixed.replace("  }\n  {", "  },  {")  # doc boundary: } then {
        raw_fixed = raw_fixed.replace("  ]  ,  ", "  ,  ", 1).strip()  # remove stray ] after first doc
        if raw_fixed.endswith("}"):
            raw_fixed = raw_fixed + "\n  ]"
        try:
            docs = json.loads(raw_fixed)
        except json.JSONDecodeError as e:
            # Fallback: split by doc boundaries and parse each object
            parts = re.split(r"\n  \}\s*\n\s*\{", raw.strip())
            docs = []
            for part in parts:
                part = part.strip()
                if part.startswith("["):
                    part = part[1:].strip()
                if part.startswith("]"):
                    continue
                if not part.startswith("{"):
                    idx = part.find("{")
                    part = part[idx:] if idx >= 0 else part
                if part.endswith("]"):
                    part = part.rsplit("]", 1)[0].strip().rstrip(",").strip()
                if not part.endswith("}"):
                    idx = part.rfind("}")
                    part = part[: idx + 1] if idx >= 0 else part
                try:
                    docs.append(json.loads(part))
                except json.JSONDecodeError:
                    pass
    if not isinstance(docs, list):
        docs = [docs]

    rows: list[tuple[str, str, str, str, str, int, str, float]] = []
    for doc in docs:
        standard_type = (doc.get("standard_type") or "").strip()
        if not standard_type:
            continue
        groups = doc.get("groups") or []
        for g in groups:
            gender = (g.get("gender") or "").strip() or "F"
            age_group = normalize_age_group(g.get("age_group") or "")
            event_code = (g.get("event") or "").strip()
            scy_str = g.get("scy")
            lcm_str = g.get("lcm")
            if scy_str is not None and scy_str != "":
                secs = time_to_seconds(str(scy_str))
                if secs is not None:
                    parsed = parse_event_for_course(event_code, "SCY")
                    if parsed:
                        event_name, stroke, distance = parsed
                        rows.append((gender, age_group, "SCY", event_name, stroke, distance, standard_type, round(secs, 2)))
            if lcm_str is not None and lcm_str != "":
                secs = time_to_seconds(str(lcm_str))
                if secs is not None:
                    parsed = parse_event_for_course(event_code, "LCM")
                    if parsed:
                        event_name, stroke, distance = parsed
                        rows.append((gender, age_group, "LCM", event_name, stroke, distance, standard_type, round(secs, 2)))

    ts = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    migration_name = f"{ts}_sync_national_time_standards"
    out_path = MIGRATIONS_DIR / f"{migration_name}.sql"

    # Exclude Futures Bonus: time_standards_standard_level_check does not allow it (see 20260207000000_remove_futures_bonus.sql)
    rows = [r for r in rows if r[6] != "Futures Bonus"]

    lines = [
        "-- Insert national time standards from national_time_standard.json",
        "-- Sectional, Futures, Junior National, Junior National Bonus, National (Futures Bonus excluded per constraint)",
        "-- Generated by scripts/generate_national_time_standards_migration.py",
        "-- Requires: 20260129000000_time_standards_national_levels_and_age_groups.sql applied first.",
        "",
        "INSERT INTO public.time_standards (gender, age_group, course, event, stroke, distance, standard_level, time_seconds) VALUES",
    ]
    values = []
    for (gender, age_group, course, event_name, stroke, distance, standard_level, time_seconds) in rows:
        values.append(
            f"('{sql_escape(gender)}', '{sql_escape(age_group)}', '{sql_escape(course)}', "
            f"'{sql_escape(event_name)}', '{sql_escape(stroke)}', {distance}, "
            f"'{sql_escape(standard_level)}', {time_seconds})"
        )
    lines.append(",\n".join(values))
    lines.append(";")
    lines.append("")

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {len(rows)} national time standard rows to {out_path}")


if __name__ == "__main__":
    main()
