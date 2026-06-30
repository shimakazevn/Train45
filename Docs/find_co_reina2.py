import csv, re
from pathlib import Path

DTL_DIR = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\TimeLines")
DIALOGIC_CSV = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv")

# Scan DTL files for ALL event IDs (not just MC dialogue)
# Classify each ID by speaker type
all_ids = {}  # eid -> speaker_type

for dtl_file in sorted(DTL_DIR.glob("*.dtl")):
    with open(dtl_file, encoding="utf-8") as f:
        content = f.read()
    # Dialogue lines
    for m in re.finditer(r'^(mai|reina|-)\s+(.+?)\s*#id:([0-9a-f]+)', content, re.MULTILINE):
        speaker = m.group(1)
        text = m.group(2)
        eid = m.group(3).lower()
        all_ids[eid] = speaker

print(f"Total classified IDs: {len(all_ids)}")
speakers = {}
for eid, sp in all_ids.items():
    speakers[sp] = speakers.get(sp, 0) + 1
print(f"By speaker: {speakers}")

# Now check dialogic CSV for "Cô" addressing Reina
with open(DIALOGIC_CSV, encoding="utf-8", newline="") as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = list(reader)
    for row in rows:
        if len(row) < 3: continue
        key, vi = row[0], row[2]
        eid = key.split('/')[1].lower() if '/' in key else ''
        speaker = all_ids.get(eid, 'unknown')
        
        # Check if this is MC addressing Reina as "Cô"
        mc_speaking = speaker in ('-', 'unknown')  # MC or narration
        addresses_reina_as_co = False
        
        # Pattern 1: "Cô " at start (addressing Reina directly)
        if vi.startswith('Cô ') or vi.startswith('Cô,'):
            addresses_reina_as_co = True
        
        # Pattern 2: contains "cô Reina" or similar
        if 'cô reina' in vi.lower():
            addresses_reina_as_co = True
        
        if addresses_reina_as_co and mc_speaking:
            print(f"  {key} [speaker={speaker}]: {vi[:80]}")
