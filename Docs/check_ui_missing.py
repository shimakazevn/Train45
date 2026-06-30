import csv

# Check UI_Text_Translations.csv
with open(r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\Ui\UI_Text_Translations.csv', encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    print('Headers:', header)
    missing = []
    total = 0
    for row in reader:
        total += 1
        if len(row) >= 4:
            vi = row[3]
            if vi == '' or vi.startswith('<!'):
                missing.append((row[0], vi[:40]))
    
    print(f'Total UI rows: {total}')
    print(f'MissingKey entries: {len(missing)}')
    for k, v in missing[:10]:
        print(f'  {k}: [{v}]')
