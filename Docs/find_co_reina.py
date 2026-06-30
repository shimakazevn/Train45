import csv

CSV = r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv'

with open(CSV, encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    co_reina = []
    for row in reader:
        vi = row[2]
        # Find "Cô" used as address for Reina (not "cô Mai", not "cô ấy" for third person)
        # Context: "cô" at start of sentence = addressing Reina
        # Also: ", cô" = calling her
        # But NOT: "cô Mai", "cô ấy", "cô Konial"
        if any(x in vi.lower() for x in ['cô reina', 'cô ạ', 'cô!', 'cô?', 'cô,' , 'cô .']):
            co_reina.append((row[0], vi[:90]))
        elif vi.lower().startswith('cô ') and 'cô mai' not in vi.lower() and 'cô konial' not in vi.lower():
            co_reina.append((row[0], vi[:90]))

print(f'Found {len(co_reina)} lines with Cô > Reina')
for k, v in co_reina[:15]:
    print(f'  {k}: {v}')
if len(co_reina) > 15:
    print(f'  ... and {len(co_reina)-15} more')
