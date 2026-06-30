import csv

CSV = r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv'
MAI_CSV = r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\mai_dialogue_export.csv'

rows = []
with open(CSV, encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = list(reader)

# Check for MC addressing Reina improperly
found = 0
for row in rows:
    key, jp, vi = row[0], row[1], row[2]
    # Look for 'cô ấy' which MC might use to refer to Reina
    # Also look for cases where someone addresses Reina
    if any(x in vi.lower() for x in ['cô ấy', 'cô reina', 'cô bạn này', 'bạn nữ']):
        if 'cô mai' not in vi.lower() and 'cô konial' not in vi.lower():
            # Skip Reina's own lines (where she refers to someone else)
            found += 1
            if found <= 10:
                print(f'  {key}: {vi[:90]}')

print(f'Found {found} potential Cô-to-Em issues')

# Also check mai_dialogue_export
print('\n=== Mai dialogue export checks ===')
with open(MAI_CSV, encoding='utf-8') as f:
    reader = csv.reader(f)
    h = next(reader)
    for row in reader:
        if len(row) >= 4:
            vi = row[3]
            for tag in ['reina:', 'mai:', 'mc:', 'konia:']:
                if vi.lower().startswith(tag):
                    print(f'TAG LEAK: {row[0]}: {vi[:60]}')
            if 'cô ấy' in vi.lower() and 'cô mai' not in vi.lower() and 'cô konial' not in vi.lower():
                print(f'CÔ ẤY: {row[0]}: {vi[:80]}')

print('\nDone checking')
