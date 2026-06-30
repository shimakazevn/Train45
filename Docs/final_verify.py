import csv

CSV = r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv'

with open(CSV, encoding='utf-8') as f:
    reader = csv.reader(f)
    h = next(reader)
    total = 0
    leaks = []
    for row in reader:
        total += 1
        if len(row) < 3:
            continue
        vi = row[2]
        for tag in ['reina:', 'mai:', 'mc:', 'konia:']:
            if vi.lower().startswith(tag):
                leaks.append((tag, row[0], vi[:60]))

print(f'Total rows: {total}')
print(f'Remaining tag leaks: {len(leaks)}')
for tag, key, vi in leaks[:3]:
    print(f'  [{tag}] {key}: {vi}')
