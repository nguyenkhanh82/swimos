#!/usr/bin/env python3
"""Merge duplicate 'Junior National' documents in national_time_standard.json into one."""
import json
import sys
from pathlib import Path

def main():
    repo = Path(__file__).resolve().parent.parent
    path = repo / "national_time_standard.json"
    data = json.loads(path.read_text())

    seen_key = set()
    merged_groups = []
    junior_national_meta = None
    out = []

    for doc in data:
        if doc.get("standard_type") != "Junior National":
            out.append(doc)
            continue
        if junior_national_meta is None:
            junior_national_meta = {
                "document_title": doc["document_title"],
                "effective_date": doc["effective_date"],
                "standard_type": doc["standard_type"],
            }
        for g in doc["groups"]:
            key = (g["age_group"], g["gender"], g["event"])
            if key in seen_key:
                continue
            seen_key.add(key)
            merged_groups.append(g)

    if junior_national_meta is not None:
        merged_doc = {**junior_national_meta, "groups": merged_groups}
        out.insert(0, merged_doc)

    path.write_text(json.dumps(out, indent=2) + "\n")
    print("Deduped Junior National: one document with", len(merged_groups), "groups", file=sys.stderr)

if __name__ == "__main__":
    main()
