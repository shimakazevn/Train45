import csv

CSV = r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv'

# Check for remaining tag leaks
with open(CSV, encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    leaks = []
    for row in reader:
        if len(row) < 3:
            continue
        vi = row[2]
        for tag in ['reina:', 'mai:', 'mc:', 'konia:']:
            if vi.lower().startswith(tag):
                leaks.append((tag, row[0], vi[:50]))

if leaks:
    print(f'{len(leaks)} remaining tag leaks:')
    for tag, key, vi in leaks[:10]:
        print(f'  [{tag}] {key}: {vi}')
else:
    print('No remaining tag leaks in dialogic CSV!')

# Count total lines
with open(CSV, encoding='utf-8') as f:
    line_count = sum(1 for _ in f)
print(f'Total lines: {line_count}')

# Sample some lines to verify format
with open(CSV, encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    reina_lines = 0
    for row in reader:
        if 'reina' in row[2].lower():
            reina_lines += 1
    
print(f'Lines containing "reina" in translation: {reina_lines}')
