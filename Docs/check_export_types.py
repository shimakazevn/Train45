import csv

with open(r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\mai_dialogue_export.csv', encoding='utf-8') as f:
    reader = csv.reader(f)
    h = next(reader)
    types = {}
    for row in reader:
        t = row[0]
        types[t] = types.get(t, 0) + 1

print('Types in export CSV:')
for t, c in sorted(types.items()):
    print(f'  {t}: {c}')

print(f'\nTotal: {sum(types.values())}')
