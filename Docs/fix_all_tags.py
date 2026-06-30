import csv, re

CSV = r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv'

rows = []
with open(CSV, encoding='utf-8', newline='') as f:
    reader = csv.reader(f)
    h = next(reader)
    rows = list(reader)

changes = 0
for i, row in enumerate(rows):
    if len(row) < 3:
        continue
    vi = row[2]
    new_vi = re.sub(r'^(mai|reina|mc|konia)[:\s]*', '', vi, flags=re.I)
    new_vi = new_vi.replace('anh bè', 'bạn bè')
    new_vi = new_vi.replace('Anh không sao chứ', 'Em không sao chứ')
    if new_vi != vi:
        rows[i][2] = new_vi
        changes += 1

with open(CSV, encoding='utf-8', newline='', mode='w') as f:
    writer = csv.writer(f)
    writer.writerow(h)
    writer.writerows(rows)

print(f'Fixed {changes} more lines')

# Verify
with open(CSV, encoding='utf-8') as f:
    for line in f:
        for tag in ['mai:', 'reina:', 'mc:', 'konia:']:
            if line.lower().startswith(tag) or (',' in line and line.split(',')[2].lower().startswith(tag)):
                print(f'  STILL HAS: {line[:80]}')
                break

print('Verification done')
