import csv

with open(r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv', encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    missing = []
    for row in reader:
        if len(row) >= 3 and 'MissingKey' in row[2]:
            missing.append((row[0], row[2][:80]))

print(f'Total MissingKey: {len(missing)}')
for k, v in missing[:10]:
    print(f'  {k}: {v}')
