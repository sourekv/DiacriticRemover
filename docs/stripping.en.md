# Removing diacritics – details

[Česky](stripping.cs.md) | English

A companion to the [guide](../README.en.md). It covers the
"… bez diakritiky" (without diacritics) fields. Adding diacritics (the
"… s diakritikou" fields) works for Czech only, because it uses a Czech
dictionary.

## What the plugin converts

Removal is not limited to Czech. The plugin goes through every letter in
these Unicode blocks:

- U+00C0 to U+024F (Latin-1 Supplement, Latin Extended-A and B),
- U+1E00 to U+1EFF (Latin Extended Additional).

Every letter that Windows decomposes (NFD normalization) into a base letter
without diacritics plus combining marks is replaced by that base letter.
Upper and lower case is kept. This covers 500 letters, among others for
these languages:

| Language | Examples |
|---|---|
| Czech, Slovak | á č ď é ě í ĺ ľ ň ó ô ŕ ř š ť ú ů ý ž |
| Polish | ą ć ę ń ó ś ź ż (ł see below) |
| Hungarian | á é í ó ö ő ú ü ű |
| German | ä ö ü (ß see below) |
| French, Spanish, Portuguese, Italian | à â ç è ê ë î ï ñ ô ù û ã õ |
| Romanian | ă â î ș ț ş ţ |
| Turkish | ç ğ İ ö ş ü (ı see below) |
| Baltic languages, Croatian, Slovenian | ā ē ģ ī ķ ļ ņ ū ą ė į ų č ć š ž |
| Vietnamese | ă â ê ô ơ ư and all tone marks (ạ ả ấ ầ ẩ ẫ ậ …) |

## Special cases

Some letters do not decompose into a base letter, so the plugin converts
them with its own table:

| Character | Result |
|---|---|
| Đ đ | D d |
| Ł ł | L l |
| Ø ø | O o |
| ı (Turkish dotless i) | i |
| ß | ss |
| Æ æ | AE ae |
| Œ œ | OE oe |

Stand-alone combining marks (U+0300 to U+036F) are dropped. They appear in
file names copied from macOS, which stores a letter as the base letter
followed by the mark.

## What the plugin leaves unchanged

- **Other scripts** (Cyrillic, Greek and others). That is not diacritics but
  transliteration to Latin, which the plugin does not do.
- **Digits, punctuation and symbols** (–, „“, ©, € and so on).
- **Latin letters that do not decompose and are not in the table above.**
  There are 154 of them, mostly phonetic or historic characters. Letters of
  living languages among them:

| Character | Language | Note |
|---|---|---|
| Ð ð | Icelandic, Faroese | Ð is sometimes used in Croatian instead of Đ |
| Þ þ | Icelandic | |
| Ħ ħ | Maltese | |
| Ĳ ĳ | Dutch | digraph |
| Ŀ ŀ | Catalan | |
| Ŋ ŋ, Ŧ ŧ | Sámi languages | |
| Ǆ ǅ ǆ, Ǉ ǈ ǉ, Ǌ ǋ ǌ | Croatian, Serbian (Latin) | dž, lj, nj digraphs as single characters, rare in normal text |
| Ǽ ǽ, Ǿ ǿ | Danish, Norwegian (historic) | |
| ẞ | German | capital ß |

## Comparison with ClipDiac

The ClipDiac program (Radim Tkačík, 2003, freeware) removes diacritics
using four conversion tables for the Kamenický, CP852, ISO-8859-2 and
Windows-1250 encodings. The script `tools/compare_clipdiac.py` compares its
tables with the plugin character by character. Only three characters
differ:

| Character | ClipDiac | Plugin |
|---|---|---|
| Ó (Kamenický) | o | O |
| ¬ (CP852) | a | ¬ |
| ß | s (unchanged in Kamenický) | ss |

The first two are errors in ClipDiac's tables. The plugin also works with
Unicode, so it is not limited to single-byte encodings.

## Checking

The script `tools/compare_clipdiac.py` calls the plugin directly (64-bit
Python):

```
python tools/compare_clipdiac.py C:\path\ClipDiac.exe out\diacritics.wdx64
```
