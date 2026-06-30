import csv

CSV = r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv'
EXPORT = r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\mai_dialogue_export.csv'

exp = {}
with open(EXPORT, encoding='utf-8') as f:
    reader = csv.reader(f)
    h = next(reader)
    for row in reader:
        typ, id_, ko, vi, sf = row[0], row[1], row[2], row[3], row[4]
        key = f"Choice/{id_}/text" if typ == "choice" else f"Text/{id_}/text"
        exp[key] = (ko, vi, sf)

samples = {}
with open(CSV, encoding='utf-8') as f:
    reader = csv.reader(f)
    h = next(reader)
    for row in reader:
        key = row[0]
        if key not in exp:
            continue
        vi = row[2]
        _, _, sf = exp[key]
        label = sf
        if sf.startswith('small_talk_mai.dtl'):
            try:
                eid = int(key.split('/')[1], 16)
            except:
                eid = 0
            if 0x1464 <= eid <= 0x146d:
                label = 'small_talk_mai (rest - 0.35)'
            elif 0x149b <= eid <= 0x14cd:
                label = 'small_talk_mai (roullete - 0.55)'
            else:
                continue
        samples.setdefault(label, []).append((key, vi[:90]))
        if len(samples[label]) > 2:
            continue

for label, lines in sorted(samples.items()):
    print(f'\n--- {label} ---')
    for key, vi in lines:
        print(f'  {key}: {vi}')
