"""Build diacritics.dic from a frequency word list.

Input:  lines "word count" (UTF-8), e.g. FrequencyWords cs_full.txt
Output: UTF-8, readable "#" header (source, credits, license), then the
        prefix-coded list of words with diacritics:
          - only the form with diacritics is stored; the plugin derives the
            form without diacritics itself,
          - only words whose most frequent form has diacritics,
          - words with 3+ equal letters in a row ("aaa", "nooo") are left out,
            they are interjections from subtitles,
          - words are sorted; each line starts with one character
            chr(ord('0') + n), n = number of leading characters shared with
            the previous word (max 60), followed by the rest of the word.

Usage: python tools/build_dict.py <wordlist> <output.dic> [min_count]
       min_count: ignore words seen fewer times (filters typos), default 1
"""
import re
import sys
import unicodedata

SPECIAL = {"đ": "d", "ł": "l", "ø": "o", "ß": "ss", "æ": "ae", "œ": "oe", "ı": "i"}
FORMAT = "prefix-coded v1"
MAX_SHARED = 60
REPEATED = re.compile(r"(.)\1\1")


def strip(word: str) -> str:
    out = []
    for ch in word:
        if ch in SPECIAL:
            out.append(SPECIAL[ch])
            continue
        dec = unicodedata.normalize("NFD", ch)
        out.append("".join(c for c in dec if not unicodedata.combining(c)))
    return "".join(out)


def shared_prefix(a: str, b: str) -> int:
    n = 0
    limit = min(len(a), len(b), MAX_SHARED)
    while n < limit and a[n] == b[n]:
        n += 1
    return n


def main(src: str, dst: str, min_count: int = 1) -> None:
    best: dict[str, tuple[int, str]] = {}
    with open(src, encoding="utf-8") as f:
        for line in f:
            parts = line.split()
            if len(parts) != 2 or not parts[1].isdigit():
                continue
            word, count = parts[0].lower(), int(parts[1])
            if count < min_count or not word.isalpha():
                continue
            key = strip(word)
            if not key.isascii():
                continue  # letters outside Latin, skip
            prev = best.get(key)
            if prev is None or count > prev[0]:
                best[key] = (count, word)

    words = sorted(
        w for k, (_, w) in best.items()
        if k != w and len(k) == len(w) and not REPEATED.search(k)
    )
    with open(dst, "w", encoding="utf-8", newline="\n") as f:
        f.write("# Diacritics dictionary, generated from %s\n" % src.replace("\\", "/").split("/")[-1])
        f.write("# Source: FrequencyWords by Hermit Dave (https://github.com/hermitdave/FrequencyWords),\n")
        f.write("# computed from the OpenSubtitles2018 corpus (OPUS, https://opus.nlpl.eu/).\n")
        f.write("# Thanks to the authors. License: CC BY-SA 4.0,\n")
        f.write("# https://creativecommons.org/licenses/by-sa/4.0/\n")
        f.write(f"# format: {FORMAT}\n")
        prev = ""
        for w in words:
            n = shared_prefix(prev, w)
            f.write(chr(ord("0") + n) + w[n:] + "\n")
            prev = w
    print(f"{len(best)} words, {len(words)} entries with diacritics -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 1)
