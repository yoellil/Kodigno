"""Builds Kulay's word-meaning dictionary from Open English WordNet (CC BY 4.0).

  python tool/build_dictionary.py <folder with the extracted english-wordnet-2025-json.zip> assets/kulay/dict

Output: one gzipped JSON file per first letter, {word: [[pos, meaning, example, synonym], ...]}.
At most 2 meanings per part of speech and 5 in all, most common first (the order WordNet uses).
"""
import glob
import gzip
import json
import os
import re
import sys
from collections import defaultdict

src, out = sys.argv[1], sys.argv[2]
POS = {'n': 'noun', 'v': 'verb', 'a': 'adjective', 's': 'adjective', 'r': 'adverb'}
WORD = re.compile(r"^[a-z][a-z'-]*$")
# Kulay is a children's reading app: meanings about sex, slurs and the like are left out, so a word that only has
# such meanings is simply not in the book (the AI is asked instead).
ADULT = re.compile(
    r"\b(sex|sexes|sexual|sexually|sexuality|erotic|penis|vagina|genital\w*|intercourse|prostitut\w*|rape|raped|masturbat\w*|orgasm\w*|"
    r"porn\w*|testicle\w*|semen|vulgar|obscene|ethnic slur|offensive (term|name|slang|word)|disparaging (term|name)|"
    r"derogatory (term|name)|whore|slut|lust\w*|aphrodisiac|fornicat\w*|adulter\w*|incest\w*|pedophil\w*|molest\w*)\b", re.I)

synsets = {}
for path in glob.glob(os.path.join(src, '*.json')):
    name = os.path.basename(path)
    if name.startswith('entries-') or name == 'frames.json':
        continue
    for sid, s in json.load(open(path, encoding='utf-8')).items():
        synsets[sid] = s

entries = {}
for path in glob.glob(os.path.join(src, 'entries-*.json')):
    for lemma, by_pos in json.load(open(path, encoding='utf-8')).items():
        if WORD.match(lemma):
            entries[lemma] = by_pos

# How many meanings a word has is a good stand-in for how common it is.
polysemy = {w: sum(len(p.get('sense', [])) for p in by_pos.values()) for w, by_pos in entries.items()}


def tidy(text, limit):
    if isinstance(text, dict):  # an example can carry its source: {"text": ..., "source": ...}
        text = text.get('text', '')
    text = re.sub(r'\s+', ' ', text).strip()
    if len(text) <= limit:
        return text
    cut = max(text.rfind(';', 0, limit), text.rfind(',', 0, limit))
    return text[:cut].strip() if cut > 40 else ''


def synonym(word, members):
    best = ''
    for m in members:
        if m != word and WORD.match(m) and len(m) <= 9 and polysemy.get(m, 0) >= 2:
            if not best or polysemy[m] > polysemy[best]:
                best = m
    return best


shards = defaultdict(dict)
kept = 0
for word, by_pos in entries.items():
    options = []
    for pos, body in by_pos.items():
        picked = []
        for sense in body.get('sense', []):
            syn = synsets.get(sense['synset'])
            if not syn or not syn.get('definition'):
                continue
            meaning = tidy(syn['definition'][0], 200)
            if not meaning or ADULT.search(meaning):
                continue
            example = tidy(syn['example'][0], 110) if syn.get('example') else ''
            picked.append([POS.get(pos, pos), meaning, example, synonym(word, syn.get('members', []))])
            if len(picked) == 2:
                break
        options.append(picked)
    options.sort(key=lambda p: -len(p))  # the part of speech with the most meanings first
    senses = [s for p in options for s in p][:5]
    if senses:
        shards[word[0]][word] = senses
        kept += 1

os.makedirs(out, exist_ok=True)
total = 0
for letter, words in sorted(shards.items()):
    data = json.dumps(words, ensure_ascii=False, separators=(',', ':'), sort_keys=True).encode('utf-8')
    with gzip.GzipFile(os.path.join(out, letter + '.json.gz'), 'wb', mtime=0) as f:  # mtime=0: the same input gives the same file
        f.write(data)
    total += os.path.getsize(os.path.join(out, letter + '.json.gz'))
print(f'{kept} words in {len(shards)} files, {total / 1e6:.1f} MB')
