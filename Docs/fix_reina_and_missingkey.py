#!/usr/bin/env python3
"""
1. Scan DTL files to build Reina key mapping
2. Fix Reina formality in dialogic CSV
3. Analyze MissingKey entries
"""
import csv, re, os
from pathlib import Path

DTL_DIR = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\TimeLines")
DIALOGIC_CSV = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv")

# ── Step 1: Scan DTL files for Reina lines ──

reina_map = {}  # {key: source_file}
choice_reina = {}  # {key: source_file} for choices by reina

print("Scanning DTL files for Reina character lines...")
for dtl_file in sorted(DTL_DIR.glob("*.dtl")):
    with open(dtl_file, encoding="utf-8") as f:
        content = f.read()

    # Find event IDs with character="reina"
    # Pattern: [event id="xxxx"] or [event id="xxxx" ... character="reina"]
    for m in re.finditer(r'\[event\s+id="([^"]+)"[^\]]*character="(reina)"[^\]]*\]', content):
        eid = m.group(1).lower()
        key = f"Text/{eid}/text"
        reina_map[key] = dtl_file.name
    
    # Also check choice events where character is reina
    for m in re.finditer(r'\[choice\s+id="([^"]+)"[^\]]*character="(reina)"[^\]]*\]', content):
        eid = m.group(1).lower()
        key = f"Choice/{eid}/text"
        choice_reina[key] = dtl_file.name

print(f"Found {len(reina_map)} Reina text keys + {len(choice_reina)} Reina choice keys")

# ── Step 2: Read dialogic CSV and apply fixes ──

# Reina formality rules by relationship stage
def get_reina_stage(source_file):
    f = (source_file or "").lower()
    if f.startswith("prologue"): return "stranger"
    if f.startswith("chapter2"): return "acquaintance"
    if f.startswith("chapter3"): return "intimate"
    if f.startswith("chapter4"): return "trust"
    if f.startswith("chapter5"): return "deep_trust"
    if f.startswith("chapter6"): return "lovers"
    if f.startswith("ending"): return "climax"
    if f.startswith("epilogue"): return "reunion"
    if f.startswith("small_talk_reina"): return "small_talk"
    if f.startswith("stage"): return "mid_game"
    if f.startswith("basetalk"): return "hub"
    if f.startswith("konial"): return "late_game"
    if f.startswith("e_"): return "h_scene"
    return "unknown"

def fix_reina_formality(text, stage):
    """Fix Reina's formality: ensure polite register, add ạ where missing."""
    if not text or text.startswith("<!MissingKey:"):
        return text
    
    # ─── Fixes for ALL stages ───
    
    # Pronoun fixes (MC addressing Reina → Em, Reina self → Em)
    # These fixes handle common mistranslations
    
    # 1. Remove any "mai:" or "reina:" prefix (tag leak safety)
    text = re.sub(r'^(mai|reina|mc|konia)[:\s]+', '', text, flags=re.I)
    
    # 2. Ensure she uses polite self-reference
    # Already should be "tôi" or "em" - verify common errors
    # (This is handled at translation level, hard to automate perfectly)
    
    # 3. Add "ạ" to sentences lacking it, based on stage
    if stage in ("stranger", "acquaintance", "mid_game"):
        # These stages should have ạ on most sentences
        if not text.rstrip().endswith(('ạ', 'ạ?', 'ạ!', 'ạ.', 'ạ~')):
            if len(text) > 3 and not text.startswith('...') and not text.startswith('('):
                ends = text.rstrip()
                if ends.endswith('?'):
                    if 'không' in text[-20:] or 'chứ' in text[-20:]:
                        pass  # questions without ạ are OK
                    elif not ends.rstrip().endswith('ạ?'):
                        text = ends.rstrip('?') + ' ạ?'
                elif ends.endswith('.'):
                    text = ends.rstrip('.') + ' ạ.'
                elif ends.endswith('!') or ends.endswith('~'):
                    text = ends.rstrip('!~') + ' ạ!'
    
    # 4. Soften strong emotional words with polite particles
    text = re.sub(r'\bquá trời\b', 'quá ạ', text)
    text = re.sub(r'\bghê luôn\b', 'ghê ạ', text)
    text = re.sub(r'\bhài vãi\b', 'quá ạ', text)
    text = re.sub(r'\bvãi\b', 'quá', text)
    
    # 5. Fix "ừ" → "vâng" for Reina (she's polite)
    text = re.sub(r'^Ừ\b', 'Vâng', text)
    text = re.sub(r'^Ừm\b', 'Vâng ạ', text)
    
    return text

# Read and process
print("Reading dialogic CSV...")
rows = []
with open(DIALOGIC_CSV, encoding="utf-8", newline="") as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = list(reader)
print(f"Read {len(rows)} rows")

reina_changed = 0
missing_keys = []

for row in rows:
    if len(row) < 3:
        continue
    key = row[0]
    vi = row[2]
    
    # ── MissingKey analysis ──
    if vi.startswith("<!MissingKey:"):
        missing_keys.append((key, vi))
        continue
    
    # ── Reina formality fix ──
    source_file = None
    if key in reina_map:
        source_file = reina_map[key]
    elif key in choice_reina:
        source_file = choice_reina[key]
    
    if source_file:
        stage = get_reina_stage(source_file)
        new_vi = fix_reina_formality(vi, stage)
        if new_vi != vi:
            row[2] = new_vi
            reina_changed += 1

# Write back
print(f"Writing back ({reina_changed} Reina lines changed)...")
with open(DIALOGIC_CSV, mode="w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(rows)

# ── Step 3: MissingKey analysis ──
print(f"\n=== MissingKey Analysis ===")
print(f"Total MissingKey: {len(missing_keys)}")
for key, vi in missing_keys[:20]:
    print(f"  {key}: {vi}")
if len(missing_keys) > 20:
    print(f"  ... and {len(missing_keys) - 20} more")

# Also check which DTL files these keys come from
mk_in_dtl = {}
for key, vi in missing_keys:
    eid = key.split('/')[1].lower() if '/' in key else ''
    for dtl_file in DTL_DIR.glob("*.dtl"):
        with open(dtl_file, encoding="utf-8") as f:
            if f'id="{eid}"' in f.read():
                mk_in_dtl[key] = dtl_file.name
                break

print(f"\nMissingKey found in DTL files: {len(mk_in_dtl)}")
for key, sf in list(mk_in_dtl.items())[:10]:
    print(f"  {key} → {sf}")

print(f"\nDone. Summary:")
print(f"  Reina lines changed: {reina_changed}")
print(f"  MissingKey entries: {len(missing_keys)}")
print(f"  MissingKey matched to DTL: {len(mk_in_dtl)}")
