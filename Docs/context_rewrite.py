#!/usr/bin/env python3
"""
Context-aware Gyaru rewrite for Mai, using per-line relationship stage analysis.
Sources context from mai_dialogue_export.csv (key → source_file → stage).
"""
import csv, re
from pathlib import Path

DIALOGIC_CSV = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv")
EXPORT_CSV = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\mai_dialogue_export.csv")

# ── Stage by source file (from full DTL analysis) ──

def get_intensity(source_file, event_id=0):
    """Return Gyaru intensity 0.0-1.0 based on relationship stage."""
    f = (source_file or "").lower()

    # PROLOGUE — strangers, no relationship
    if f.startswith("prologue") or f.startswith("stage_clear"):
        return 0.0

    # CHAPTER 2 — acquaintance
    if f.startswith("chapter2"):
        return 0.1

    # CHAPTER 3 — first emotional/sexual bonding
    if f.startswith("chapter3_talk2"):
        return 0.25
    if f.startswith("chapter3_ch_talk"):
        return 0.25
    if f.startswith("chapter3_talk"):
        return 0.25
    if f.startswith("chapter3_start"):
        return 0.3

    # CHAPTER 4 — trust building, teamwork
    if f.startswith("chapter4_butler4") or f.startswith("chapter4_butler3"):
        return 0.3
    if f.startswith("chapter4_butler") or f.startswith("chapter4_complete"):
        return 0.35
    if f.startswith("chapter4_kankannavi"):
        return 0.35

    # CHAPTER 5 — deep trust, rescue
    if f.startswith("chapter5"):
        return 0.45

    # CHAPTER 6 — lovers, facing death together
    if f.startswith("chapter6"):
        return 0.5

    # ENDING/EPILOGUE — climax, reunion
    if f.startswith("ending"):
        return 0.55
    if f.startswith("epilogue"):
        return 0.55

    # SMALL TALK MAI — per-event intensity
    if f == "small_talk_mai.dtl":
        return get_mai_st_event(event_id)

    # STAGE FILES — mid game
    if f.startswith("stage_complete"):
        return 0.25
    if f.startswith("stage_talk"):
        return 0.3

    # BASETALK — hub
    if f.startswith("basetalk"):
        return 0.3

    # KONIAL LOVE — late game
    if f.startswith("konial"):
        return 0.5

    # H-SCENES — maximum
    if f.startswith("e_"):
        return 0.65

    return 0.2


def get_mai_st_event(event_id):
    """Small talk per-event intensity based on actual relationship progression."""
    e = event_id
    # t_mai (first meeting chat): acquaintance level
    if 0x1452 <= e <= 0x1462:
        return {0x1452: 0.15, 0x1453: 0.15, 0x1454: 0.15, 0x1455: 0.15,
                0x1457: 0.15, 0x1458: 0.2, 0x145b: 0.2, 0x145c: 0.2,
                0x145e: 0.2, 0x145f: 0.15, 0x1460: 0.25, 0x1461: 0.25,
                0x1462: 0.25}.get(e, 0.2)
    # t_mai_rest (lap pillow): mid-level intimacy
    if 0x1464 <= e <= 0x146d:
        return {0x1464: 0.3, 0x1465: 0.3, 0x1466: 0.35, 0x1468: 0.35,
                0x1469: 0.4, 0x146a: 0.4, 0x146c: 0.4, 0x146d: 0.35}.get(e, 0.35)
    # t_mai_camera (selfie): mid-late, playful
    if 0x1471 <= e <= 0x148c:
        if 0x1471 <= e <= 0x1477: return 0.4
        if 0x1478 <= e <= 0x1482: return 0.45
        if 0x1484 <= e <= 0x148c: return 0.5
        return 0.45
    # t_mai_cat (animals): mid
    if 0x148f <= e <= 0x1499:
        return 0.35
    # t_mai_roullete (intuition/gacha): late game
    if 0x149b <= e <= 0x14cd:
        if 0x149b <= e <= 0x14a6: return 0.45
        if 0x14a9 <= e <= 0x14b7: return 0.5
        if 0x14ba <= e <= 0x14cd: return 0.55
        return 0.5
    return 0.3


# ── Load export ──

def load_export():
    mapping = {}
    with open(EXPORT_CSV, encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        for row in reader:
            if len(row) < 5:
                continue
            typ, id_, _, _, source_file = row[0], row[1], row[2], row[3], row[4]
            try:
                eid = int(id_, 16)
            except ValueError:
                eid = 0
            key = f"Choice/{id_}/text" if typ == "choice" else f"Text/{id_}/text"
            mapping[key] = (source_file, eid)
    return mapping


# ── Gyaru transformations ──

def apply_gyaru(text, intensity):
    if not text or intensity <= 0.0:
        return text
    if text.startswith("<!MissingKey:"):
        return text

    o = text  # original for comparison

    # Sentence ending particles
    if intensity >= 0.15:
        text = re.sub(r'\bđấy chứ\b', 'á', text)
        text = re.sub(r'thật đấy\b', 'thật á', text)
    if intensity >= 0.25:
        text = re.sub(r'nhỉ(\.\.+)$', 'nhỉ~', text)
        text = re.sub(r'nhỉ\.$', 'nhỉ~', text)
        text = re.sub(r'\bnhé(!)?$', r'nhé~\1', text)
    if intensity >= 0.3:
        text = re.sub(r'\bà\?$', 'á?', text)
        text = re.sub(r'\bđược rồi(!)', r'được rồi nà\1', text)
        text = re.sub(r'\bCái đó(!)', r'Cái đó nè\1', text)
        text = re.sub(r'(?<!\w)Đi thôi\b(?!~)', 'Đi thôi~', text)
        text = re.sub(r'\bđi thôi\b(?!~)', 'đi thôi~', text)
        text = re.sub(r'\bSao thế\?', 'Sao thế~?', text)
        text = re.sub(r'\bsao thế\?', 'sao thế~?', text)
        text = re.sub(r'\btuỳ cậu đấy\b', 'tùy cậu nha~', text)
        text = re.sub(r'\bđúng không\?', 'đúng hong?', text)
    if intensity >= 0.35:
        text = re.sub(r'\bnào(!)?$', r'nà\1', text)
        text = re.sub(r'\b(về|đến|xong) rồi(!)?$', r'\1 rồi nè\2', text)
    if intensity >= 0.4:
        text = re.sub(r'(?<!~)(!)$', r'~!', text)
        text = re.sub(r'^Ừ\b', 'Ừ ừ', text)
    if intensity >= 0.5:
        text = re.sub(r'\b(giỏi|vui|tốt|ngon) quá\b', r'\1 quá đi mất~', text)

    # không → hong (max 1 per sentence)
    if intensity >= 0.35:
        sentences = re.split(r'(?<=[.!?]) +', text)
        processed = []
        for sent in sentences:
            cnt = {'n': 0}
            def rep_h(m):
                if cnt['n'] >= 1: return m.group(0)
                cnt['n'] += 1
                return 'hong' + (m.group(1) or '')
            sent = re.sub(r'\bkhông(\?|[,.\s])', rep_h, sent)
            processed.append(sent)
        text = ' '.join(processed)

    # Choice blocks <.../.../...>
    if '<' in text and '>' in text:
        def pb(m):
            segs = m.group(1).split('/')
            out = []
            for s in segs:
                s = s.strip()
                if intensity >= 0.35:
                    s = re.sub(r'\bnào(!)?$', r'nà\1', s)
                if intensity >= 0.25:
                    s = re.sub(r'\bnhé(!)?$', r'nhé~\1', s)
                if intensity >= 0.4:
                    s = re.sub(r'(?<!~)(!)$', r'~!', s)
                out.append(s)
            return '<' + '/'.join(out) + '>'
        text = re.sub(r'<(.*?)>', pb, text)

    return text


# ── Run ──

print("Loading export...")
key_map = load_export()
print(f"  {len(key_map)} keys loaded")

print("Reading dialogic CSV...")
rows = []
with open(DIALOGIC_CSV, encoding="utf-8", newline="") as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = list(reader)
print(f"  {len(rows)} data rows")

changed = 0
skipped = 0
not_mai = 0
by_intensity = {}
by_file = {}

for row in rows:
    if len(row) < 3:
        not_mai += 1
        continue
    key = row[0]
    if key not in key_map:
        not_mai += 1
        continue

    source_file, event_id = key_map[key]
    intensity = get_intensity(source_file, event_id)
    new_vi = apply_gyaru(row[2], intensity)

    if new_vi != row[2]:
        row[2] = new_vi
        changed += 1
        i_key = f"{intensity:.2f}"
        by_intensity[i_key] = by_intensity.get(i_key, 0) + 1
        f_key = source_file
        by_file[f_key] = by_file.get(f_key, 0) + 1
    else:
        skipped += 1

print(f"Writing back...")
with open(DIALOGIC_CSV, mode="w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(rows)

print(f"\nChanged: {changed}, Skipped (already correct): {skipped}, Not Mai: {not_mai}")
print(f"\nBy intensity:")
for k in sorted(by_intensity.keys()):
    print(f"  {k}: {by_intensity[k]} lines")
print(f"\nBy file (top 10):")
for k, v in sorted(by_file.items(), key=lambda x: -x[1])[:10]:
    print(f"  {k}: {v} lines")
