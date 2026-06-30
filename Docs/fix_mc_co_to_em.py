import csv, re
from pathlib import Path

DTL_DIR = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\TimeLines")
DIALOGIC_CSV = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv")

# Step 1: Find event IDs where MC addresses Reina in DTL files
# MC lines start with "- " prefix (dialogue/choices)
mc_to_reina_ids = set()

for dtl_file in sorted(DTL_DIR.glob("*.dtl")):
    with open(dtl_file, encoding="utf-8") as f:
        content = f.read()
    # Find MC lines (starting with "- ") that mention Reina
    for m in re.finditer(r'^- (.+?)\s*#id:([0-9a-f]+)', content, re.MULTILINE):
        text = m.group(1).lower()
        eid = m.group(2).lower()
        if 'reina' in text or '레이나' in text:
            mc_to_reina_ids.add(eid)

    # Find choice lines that mention Reina
    for m in re.finditer(r'^-\s+(.+?)\s*#id:([0-9a-f]+)$', content, re.MULTILINE):
        # already captured above
        pass

print(f"Found {len(mc_to_reina_ids)} MC-to-Reina event IDs")

# Step 2: Check dialogic CSV for "Cô" in these MC lines
with open(DIALOGIC_CSV, encoding="utf-8", newline="") as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = list(reader)

changes = []
for row in rows:
    if len(row) < 3:
        continue
    key = row[0]
    vi = row[2]
    eid = key.split('/')[1].lower() if '/' in key else ''
    
    if eid in mc_to_reina_ids:
        # Check if vi starts with "Cô" or contains "Cô" referring to Reina
        if vi.startswith('Cô ') or vi.startswith('Cô,'):
            changes.append((key, vi[:80]))
            row[2] = re.sub(r'^Cô\b', 'Em', vi)

print(f"MC lines addressing Reina with 'Cô': {len(changes)}")
for k, v in changes[:10]:
    print(f"  {k}: [{v}] -> Em")

if changes:
    with open(DIALOGIC_CSV, mode="w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)
    print(f"Fixed {len(changes)} lines")
else:
    print("No fixes needed")
