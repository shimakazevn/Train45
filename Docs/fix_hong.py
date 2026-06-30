import csv, re, sys

sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

csv_path = 'Gameplay/Dialog/Translation/dialogic_timeline_translations.csv'

# Build Mai ID set
mai_ids = set()
with open('Gameplay/Dialog/Translation/mai_dialogue_export.csv', 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if len(row) >= 2 and row[0].strip() == 'mai':
            mai_ids.add(row[1].strip().lower())

print(f'Mai event IDs: {len(mai_ids)}')

# Compound words to always fix
compounds = {
    'hong khí': 'không khí',
    'hong gian': 'không gian',
}

rows = []
fix_non_mai = 0
fix_compound = 0
mai_kept = 0

with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    for row in reader:
        if len(row) < 3:
            rows.append(row)
            continue
        key = row[0].strip()
        vi = row[2]
        orig = vi

        # 1. Fix compound words globally
        prev = None
        while prev != vi:
            prev = vi
            for wrong, correct in compounds.items():
                vi = vi.replace(wrong, correct)

        # 2. Determine speaker and fix negation 'hong' if non-Mai
        m = re.match(r'\w+/([0-9a-f]+)/text', key, re.I)
        if m:
            hex_id = m.group(1).lower()
            is_mai = hex_id in mai_ids
            if not is_mai:
                vi = re.sub(r'\bhong\b', 'không', vi, flags=re.IGNORECASE)
                if vi != orig:
                    fix_non_mai += 1
            else:
                if vi != orig:
                    fix_compound += 1
        else:
            # Fallback: treat as non-Mai
            vi = re.sub(r'\bhong\b', 'không', vi, flags=re.IGNORECASE)
            if vi != orig:
                fix_non_mai += 1

        row[2] = vi
        rows.append(row)

with open(csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(rows)

print(f'Non-Mai hong→không: {fix_non_mai}')
print(f'Compound fixes (Mai): {fix_compound}')
print(f'Done!')
