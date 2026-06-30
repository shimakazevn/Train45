import csv

with open(r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\mai_dialogue_export.csv', encoding='utf-8') as f:
    reader = csv.reader(f)
    h = next(reader)
    print('Headers:', h)
    for i, row in enumerate(reader):
        if i < 5:
            print(f'Row {i}: key={row[0][:30]}, en={row[1][:30]}, kr={row[2][:30]}, vi={row[3][:50]}')
        if i == 5:
            # Check first mai: prefixed line
            if row[3].startswith('mai:'):
                print(f'Row {i}: kr starts with mai: {row[2].startswith("mai:")}, vi={row[3][:50]}')
            break

# Count tag leaks
tag_leaks = 0
with open(r'E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\mai_dialogue_export.csv', encoding='utf-8') as f:
    reader = csv.reader(f)
    h = next(reader)
    for row in reader:
        vi = row[3]
        if vi.startswith('mai:') or vi.startswith('reina:') or vi.startswith('narration:') or vi.startswith('choice:'):
            tag_leaks += 1

print(f'Total tag leaks in mai_dialogue_export: {tag_leaks}')
print('(This is an export file, not the working CSV)')
