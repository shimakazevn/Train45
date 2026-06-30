#!/usr/bin/env python3
"""Rewrite all Mai dialogue lines with Vietnamese Gyaru girl style.

Gyaru markers (context-aware by progression):
- Prologue/early: minimal markers
- Mid game: some markers (nè, ~ occasionally)
- Late game: more markers (+hong, +nà/nha)
- H-scenes: playful flirty markers

Usage: python gyaru_mai_rewrite.py
"""

import csv
import re
from pathlib import Path

DIALOGIC_CSV = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\dialogic_timeline_translations.csv")
EXPORT_CSV = Path(r"E:\Train45_Project\Train45_extracted\Gameplay\Dialog\Translation\mai_dialogue_export.csv")

# ---------- load Mai keys from export ----------
mai_keys = {}  # {key: (ko_text, vi_text, source_file)}
with open(EXPORT_CSV, encoding="utf-8") as f:
    reader = csv.reader(f)
    header = next(reader)
    for row in reader:
        if len(row) < 5: continue
        typ, id_, ko, vi, source_file = row[0], row[1], row[2], row[3], row[4]
        key = f"Choice/{id_}/text" if typ == "choice" else f"Text/{id_}/text"
        mai_keys[key] = (ko, vi, source_file)

print(f"Loaded {len(mai_keys)} Mai keys from export")

# ---------- read dialogic CSV ----------
with open(DIALOGIC_CSV, encoding="utf-8") as f:
    reader = csv.reader(f)
    header_row = next(reader)
    rows = list(reader)

print(f"Read {len(rows)} rows from dialogic CSV")

# ---------- intensity by source file ----------

def get_intensity(source_file):
    """Return 0.0-1.0 Gyaru intensity based on game progression."""
    f = (source_file or "").lower()
    
    # Prologue / early: strangers, minimal Gyaru
    if any(x in f for x in ["prologue", "stage_clear", "chapter2"]):
        return 0.1
    
    # Early-mid game: getting acquainted
    if any(x in f for x in ["stage_complete", "stage_talk",
                            "small_talk_reina"]):
        return 0.2
    
    # Mid game: established companions
    if any(x in f for x in ["chapter3", "small_talk_mai",
                            "basetalk", "konial_talk"]):
        return 0.4
    
    # Late-mid: closer
    if any(x in f for x in ["chapter4", "chapter5", "chapter6"]):
        return 0.5
    
    # Endgame / epilogue: intimate
    if any(x in f for x in ["ending_0", "epilogue_0"]):
        return 0.55
    
    # H-scenes: playful and flirty
    if f.startswith("e_"):
        return 0.65
    
    return 0.25  # default


# ---------- Gyaru transformation rules ----------

def apply_gyaru(text: str, source_file: str) -> str:
    """Apply moderate Gyaru Vietnamese style. Never changes meaning."""
    if not text or text.startswith("<!MissingKey:"):
        return text

    intensity = get_intensity(source_file)
    original = text

    # # # SENTENCE-FINAL RULES (highest priority, last in text) # # #

    # Rule A: "nhỉ..." at end → "nhỉ~" (drawl replaces the dots)
    if intensity >= 0.3:
        text = re.sub(r'nhỉ(\.\.+)$', 'nhỉ~', text)
        text = re.sub(r'nhỉ\.$', 'nhỉ~', text)

    # Rule B: "à?" at end → "á?" (question particle)
    if intensity >= 0.4:
        text = re.sub(r'\bà\?$', 'á?', text)

    # Rule C: "đấy chứ" → "á" (anywhere)
    if intensity >= 0.3:
        text = re.sub(r'\bđấy chứ\b', 'á', text)
        # "thật đấy" → "thật á"
        text = re.sub(r'thật đấy(\.\.\.?|!|,|\.|$)', r'thật á\1', text)

    # Rule D: "được rồi!" at end → "được rồi nà!"
    if intensity >= 0.4:
        text = re.sub(r'\bđược rồi(!)', r'được rồi nà\1', text)

    # Rule E: "nhé" at end → "nhé~" (always safe)
    if intensity >= 0.3:
        text = re.sub(r'\bnhé(!)?$', r'nhé~\1', text)

    # Rule F: "nào!" at end → "nà!"
    if intensity >= 0.5:
        text = re.sub(r'\bnào(!)?$', r'nà\1', text)

    # # # MID-SENTENCE RULES # # #

    # Rule G: "không" → "hong" in casual contexts (max 1 per sentence)
    if intensity >= 0.4:
        # Split into sentences to limit to one "hong" per sentence
        sentences = re.split(r'(?<=[.!?]) +', text)
        processed = []
        for sent in sentences:
            state = {'count': 0}
            def replace_khong(m):
                if state['count'] >= 1:
                    return m.group(0)
                state['count'] += 1
                if m.group(1) == '?':
                    return 'hong?'
                else:
                    return 'hong' + m.group(1)
            sent = re.sub(r'\bkhông(\?|[,.\s])', replace_khong, sent)
            processed.append(sent)
        text = ' '.join(processed)

    # Rule H: "Cái đó!" → "Cái đó nè!"
    if intensity >= 0.3:
        text = re.sub(r'\bCái đó(!)', r'Cái đó nè\1', text)

    # Rule I: "Đi thôi" → "Đi thôi~" (check no existing ~)
    if intensity >= 0.3:
        text = re.sub(r'\bĐi thôi\b(?!~)', 'Đi thôi~', text)
        text = re.sub(r'\bđi thôi\b(?!~)', 'đi thôi~', text)

    # Rule J: exclamation at end → add ~ before !
    if intensity >= 0.45:
        text = re.sub(r'(?<!~)(!)$', r'~!', text)

    # Rule K: "Ừ" → "Ừ ừ" (playful doubling)
    if intensity >= 0.45:
        text = re.sub(r'^Ừ\b', 'Ừ ừ', text)

    # Rule L: "quá" at end → "quá đi mất~" (but not for neutral statements)
    if intensity >= 0.6:
        text = re.sub(r'\b(giỏi|vui|tốt|ngon) quá\b', r'\1 quá đi mất~', text)

    # Rule M: "rồi" at sentence end → "rồi nè" (not "được rồi" — handled above)
    if intensity >= 0.4:
        text = re.sub(r'\b(về|đến|xong) rồi(!)?$', r'\1 rồi nè\2', text)

    # Rule N: "tuỳ cậu đấy" → "tùy cậu nha~"
    if intensity >= 0.4:
        text = re.sub(r'\btuỳ cậu đấy\b', 'tùy cậu nha~', text)

    # Rule O: "đúng không?" → "đúng hong?"
    if intensity >= 0.4:
        text = re.sub(r'\bđúng không\?', 'đúng hong?', text)

    # Rule P: "sao thế" → "sao thế~"  
    if intensity >= 0.4:
        text = re.sub(r'\bSao thế\?', 'Sao thế~?', text)
        text = re.sub(r'\bsao thế\?', 'sao thế~?', text)

    # Handle choice blocks: "<.../.../...>"
    # Apply end-of-text rules ($) per segment instead of per full text
    if '<' in text and '>' in text:
        def process_choice_block(m):
            inner = m.group(1)
            segments = inner.split('/')
            processed = []
            for seg in segments:
                seg = seg.strip()
                # Apply final-sentence rules per segment
                # Rule F: "nào!" at end → "nà!"
                if intensity >= 0.5:
                    seg = re.sub(r'\bnào(!)?$', r'nà\1', seg)
                # Rule E: "nhé" → "nhé~"
                if intensity >= 0.3:
                    seg = re.sub(r'\bnhé(!)?$', r'nhé~\1', seg)
                # Rule J: "!" at end → "~!" (no existing ~)
                if intensity >= 0.45:
                    seg = re.sub(r'(?<!~)(!)$', r'~!', seg)
                processed.append(seg)
            return '<' + '/'.join(processed) + '>'
        text = re.sub(r'<(.*?)>', process_choice_block, text)

    return text


# ---------- process rows ----------
changed = 0
skipped = 0
not_mai = 0

for row in rows:
    if len(row) < 3:
        not_mai += 1
        continue
    
    key = row[0]
    if key in mai_keys:
        _, old_vi, source_file = mai_keys[key]
        new_vi = apply_gyaru(row[2], source_file)
        if new_vi != row[2]:
            row[2] = new_vi
            changed += 1
        else:
            skipped += 1
    else:
        not_mai += 1

# ---------- write back ----------
with open(DIALOGIC_CSV, mode="w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(header_row)
    writer.writerows(rows)

# Stats
from collections import Counter
file_counts = Counter()
intensity_counts = Counter()
for key in mai_keys:
    if key in {r[0] for r in rows}:
        _, _, sf = mai_keys[key]
        file_counts[sf] += 1
        intensity_counts[f"{get_intensity(sf):.2f}"] += 1

print(f"\nDone! Changed: {changed}, Skipped: {skipped}, Not Mai: {not_mai}")
print(f"Mai by intensity:")
for k in sorted(intensity_counts.keys()):
    print(f"  intensity {k}: {intensity_counts[k]} entries")
