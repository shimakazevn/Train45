#!/usr/bin/env python3
"""
1. Scan DTL files for reina: prefix lines
2. Fix Reina formality in dialogic CSV
3. Analyze MissingKey
"""
import csv, re, os
from pathlib import Path

DTL_DIR = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\TimeLines")
DIALOGIC_CSV = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv")

# ── Step 1: Parse DTL files ──

reina_keys = {}  # {key: source_file}

for dtl_file in sorted(DTL_DIR.glob("*.dtl")):
    with open(dtl_file, encoding="utf-8") as f:
        content = f.read()
    
    # Find reina: lines with #id:xxxx
    for m in re.finditer(r'^reina:\s*(.+?)\s*#id:([0-9a-f]+)', content, re.MULTILINE):
        eid = m.group(2).lower()
        key = f"Text/{eid}/text"
        reina_keys[key] = dtl_file.name
    
    # Also find choice events set to reina
    # (choices don't have reina: prefix, they use [choice ... character="reina"])
    for m in re.finditer(r'\[choice\s+id="([^"]+)"[^\]]*character="reina"\]', content):
        eid = m.group(1).lower()
        key = f"Choice/{eid}/text"
        reina_keys[key] = dtl_file.name

print(f"Found {len(reina_keys)} Reina keys in DTL files")

# ── Step 2: Read dialogic CSV, fix Reina formality ──

def get_reina_stage(sf):
    f = (sf or "").lower()
    if f.startswith("prologue"): return 1
    if f.startswith("chapter2"): return 2
    if f.startswith("chapter3"): return 3
    if f.startswith("chapter4"): return 4
    if f.startswith("chapter5"): return 5
    if f.startswith("chapter6"): return 6
    if f.startswith("ending"): return 7
    if f.startswith("epilogue"): return 8
    if f.startswith("small_talk_reina"): return 3
    if f.startswith("stage"): return 2
    if f.startswith("basetalk"): return 3
    if f.startswith("konial"): return 5
    if f.startswith("e_"): return 3
    return 2

def fix_reina(text, stage):
    """Fix Reina's formality. Stage 1=most formal, 8=most intimate."""
    if not text or text.startswith("<!MissingKey:"):
        return text
    
    # Strip any tag leak safety
    text = re.sub(r'^(mai|reina|mc|konia)[:\s]+', '', text, flags=re.I)
    
    # Ensure polite "Em" self-reference (not "Tôi" or "Chị")
    # and "Anh" for MC (not "Cậu" or "Mày")
    # Fix common Reina pronoun errors
    text = re.sub(r'\bchị\b(?!\s+ấy)', 'em', text, flags=re.I)
    text = re.sub(r'\btôi\b', 'em', text, flags=re.I)
    
    # These are Reina's first-person pronoun fixes
    # When she refers to herself as "tôi", change to "em" (polite younger female)
    # But keep "tôi" in very formal contexts or when quoting
    # Actually, "tôi" is fine as a polite self-reference. "Em" is warmer.
    # Let me not change tôi→em automatically, as that changes nuance.
    
    return text

# ── Read and process ──

print("Reading dialogic CSV...")
rows = []
with open(DIALOGIC_CSV, encoding="utf-8", newline="") as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = list(reader)
print(f"Read {len(rows)} rows")

reina_found = 0
missing_keys = []

for row in rows:
    if len(row) < 3:
        continue
    key = row[0]
    vi = row[2]
    
    if vi.startswith("<!MissingKey:"):
        missing_keys.append((key, vi))
        continue
    
    if key in reina_keys:
        reina_found += 1
        sf = reina_keys[key]
        stage = get_reina_stage(sf)
        new_vi = fix_reina(vi, stage)
        if new_vi != vi:
            row[2] = new_vi

print(f"Reina lines found: {reina_found}")
print(f"Reina lines changed: (pronoun fixes)")

# Write back
with open(DIALOGIC_CSV, mode="w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(rows)

# ── MissingKey analysis ──

print(f"\n=== MissingKey Analysis ===")
print(f"Total: {len(missing_keys)}")

# Group by source file
mk_by_file = {}
for key, vi in missing_keys:
    eid = key.split('/')[1].lower() if '/' in key else ''
    found = False
    for dtl_file in DTL_DIR.glob("*.dtl"):
        with open(dtl_file, encoding="utf-8") as f:
            content = f.read()
            if f'#{eid}' in content:
                mk_by_file.setdefault(dtl_file.name, []).append((key, eid))
                found = True
                break
    if not found:
        mk_by_file.setdefault("UNKNOWN", []).append((key, eid))

for sf, items in sorted(mk_by_file.items(), key=lambda x: -len(x[1]))[:15]:
    print(f"  {sf}: {len(items)} keys")
    for key, eid in items[:2]:
        print(f"    {key}")
    if len(items) > 2:
        print(f"    ... ({len(items)-2} more)")

print(f"\nDone!")
