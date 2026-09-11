#!/usr/bin/env python3
"""
Reformat time_standard.json into valid JSON with consistent structure.
- Single root object with document_title, effective_date, groups
- Each group: age_group, course, gender (M/F), events
- Times as seconds (number); event codes normalized (e.g. 50 FR)
"""

import json
import re
import sys
from pathlib import Path

# Normalize age_group to DB format
AGE_GROUP_MAP = {
    "10 & under": "10 & Under",
    "10 & Under": "10 & Under",
    "11-12": "11-12",
    "13-14": "13-14",
    "15-16": "15-16",
    "17-18": "17-18",
    "Open": "Open",
}

def time_to_seconds(s):
    """Convert '1:01.79' or '28.29' to float seconds."""
    if s is None:
        return None
    if isinstance(s, (int, float)):
        return float(s)
    s = str(s).strip()
    parts = s.split(":")
    if len(parts) == 2:
        return float(parts[0]) * 60 + float(parts[1])
    return float(s)

def parse_event_times(ev):
    """Return { B, BB, A, AA, AAA, AAAA } as seconds (numbers)."""
    out = {}
    for level in ["B", "BB", "A", "AA", "AAA", "AAAA"]:
        if level in ev:
            out[level] = round(time_to_seconds(ev[level]), 2)
    return out

def normalize_event_code(event_str):
    """Strip course suffix if present: '50 FR LCM' -> '50 FR'."""
    if not event_str:
        return event_str
    s = str(event_str).strip()
    for suffix in [" LCM", " SCY", " SCM"]:
        if s.endswith(suffix):
            s = s[: -len(suffix)]
    return s

def extract_groups_from_obj(obj, course_override=None, age_override=None):
    """Yield (age_group, course, gender, events) from one of the various block formats."""
    doc_title = obj.get("document_title", "")
    effective = obj.get("effective_date", "2025-10-10")
    course = course_override or obj.get("course", "SCY")

    # Format 1: standards array with age_group, gender, course per item
    if "standards" in obj and isinstance(obj["standards"], list):
        for item in obj["standards"]:
            age = age_override or item.get("age_group") or obj.get("age_group")
            gender_raw = item.get("gender") or obj.get("gender")
            events = item.get("events", [])
            if age and gender_raw and events:
                gender = "F" if str(gender_raw).lower() == "girls" else "M"
                age = AGE_GROUP_MAP.get(age, age)
                yield (age, course, gender, events, effective)

    # Format 2: gender_data with keys "Girls", "Boys"
    if "gender_data" in obj:
        age = age_override or obj.get("age_group")
        age = AGE_GROUP_MAP.get(age, age)
        gd = obj["gender_data"]
        if isinstance(gd, dict):
            for gender_key, events in gd.items():
                if isinstance(events, list):
                    gender = "F" if str(gender_key).lower() == "girls" else "M"
                    yield (age, course, gender, events, effective)
        elif isinstance(gd, list):
            for item in gd:
                gender_raw = item.get("gender")
                events = item.get("events", [])
                if gender_raw and events:
                    gender = "F" if str(gender_raw).lower() == "girls" else "M"
                    yield (age, course, gender, events, effective)

    # Format 3: age_groups array
    if "age_groups" in obj:
        for ag_item in obj["age_groups"]:
            age = ag_item.get("age_group") or obj.get("age_group")
            age = AGE_GROUP_MAP.get(age, age)
            gd = ag_item.get("gender_data", ag_item)
            if isinstance(gd, list):
                for item in gd:
                    gender_raw = item.get("gender")
                    events = item.get("events", [])
                    if gender_raw and events:
                        gender = "F" if str(gender_raw).lower() == "girls" else "M"
                        yield (age, course, gender, events, effective)

def main():
    repo = Path(__file__).resolve().parent.parent
    input_path = repo / "time_standard.json"
    output_path = repo / "time_standard.json"

    raw = input_path.read_text(encoding="utf-8")

    # Split by "}\n  {" to get separate JSON objects (with possible trailing comma)
    parts = re.split(r"\}\s*\n\s*\{", raw)
    objects = []
    for i, part in enumerate(parts):
        s = part.strip()
        if not s:
            continue
        if i == 0 and s.startswith("{"):
            s = s
        else:
            s = "{" + s
        if i == len(parts) - 1 and s.endswith("}"):
            s = s
        else:
            s = s + "}"
        # Remove trailing comma before } if present
        s = re.sub(r",\s*}", "}", s)
        try:
            objects.append(json.loads(s))
        except json.JSONDecodeError as e:
            print(f"Parse error in part {i}: {e}", file=sys.stderr)
            continue

    groups_out = []
    seen = set()
    for obj in objects:
        for age, course, gender, events, effective in extract_groups_from_obj(obj):
            for ev in events:
                event_code = normalize_event_code(ev.get("event", ""))
                if not event_code:
                    continue
                times = parse_event_times(ev)
                if not times:
                    continue
                key = (age, course, gender, event_code)
                if key in seen:
                    continue
                seen.add(key)
                groups_out.append({
                    "age_group": age,
                    "course": course,
                    "gender": gender,
                    "event": event_code,
                    **times,
                })

    # Sort for stable output
    groups_out.sort(key=lambda g: (g["age_group"], g["course"], g["gender"], g["event"]))

    root = {
        "document_title": "USA Swimming 2024-2028 Motivational Standards",
        "effective_date": "2025-10-10",
        "groups": groups_out,
    }

    output_path.write_text(
        json.dumps(root, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"Wrote {len(groups_out)} standard rows to {output_path}")

if __name__ == "__main__":
    main()
