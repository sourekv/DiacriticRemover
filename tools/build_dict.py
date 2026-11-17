"""Build TcAccents.dic from a frequency word list.

Input:  lines "word count" (UTF-8), e.g. FrequencyWords cs_50k.txt
Output: lines "plain<TAB>accented" (UTF-8, sorted), only for words whose most
        frequent form differs from the form without diacritics.

Usage: python tools/build_dict.py <wordlist> <output.dic> [min_count]
       min_count: ignore words seen fewer times (filters typos), default 1
"""
import sys
import unicodedata

SPECIAL = {"đ": "d", "ł": "l", "ø": "o", "ß": "ss", "æ": "ae", "œ": "oe", "ı": "i"}


def strip(word: str) -> str:
    out = []
    for ch in word:
        if ch in SPECIAL:
            out.append(SPECIAL[ch])
            continue
        dec = unicodedata.normalize("NFD", ch)
        out.append("".join(c for c in dec if not unicodedata.combining(c)))
    return "".join(out)


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

    rows = sorted((k, w) for k, (_, w) in best.items() if k != w)
    with open(dst, "w", encoding="utf-8", newline="\n") as f:
        f.write("# TcAccents dictionary, generated from %s\n" % src.replace("\\", "/").split("/")[-1])
        f.write("# Source: FrequencyWords by Hermit Dave, CC BY-SA 4.0\n")
        for k, w in rows:
            f.write(f"{k}\t{w}\n")
    print(f"{len(best)} words, {len(rows)} entries with diacritics -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 1)
