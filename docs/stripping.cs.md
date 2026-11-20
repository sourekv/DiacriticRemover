# Odstraňování diakritiky – podrobnosti

Česky | [English](stripping.en.md)

Doplňkový popis k [návodu](../README.cs.md): co přesně plugin převádí.

## Co plugin převádí

Odstraňování není omezené na češtinu. Plugin projde všechna písmena
z bloků Unicode:

- U+00C0 až U+024F (Latin-1 Supplement, Latin Extended-A a B),
- U+1E00 až U+1EFF (Latin Extended Additional).

Každé písmeno, které Windows rozloží (normalizace NFD) na základní písmeno
bez diakritiky a diakritická znaménka, nahradí tím základním písmenem.
Velikost písmen zůstává. Spolu se zvláštními případy níže se převede 515 písmen, mimo jiné pro tyto
jazyky:

| Jazyk | Příklady |
|---|---|
| čeština, slovenština | á č ď é ě í ĺ ľ ň ó ô ŕ ř š ť ú ů ý ž |
| polština | ą ć ę ń ó ś ź ż (ł viz níže) |
| maďarština | á é í ó ö ő ú ü ű |
| němčina | ä ö ü (ß viz níže) |
| francouzština, španělština, portugalština, italština | à â ç è ê ë î ï ñ ô ù û ã õ |
| rumunština | ă â î ș ț ş ţ |
| turečtina | ç ğ İ ö ş ü (ı viz níže) |
| pobaltské jazyky, chorvatština, slovinština | ā ē ģ ī ķ ļ ņ ū ą ė į ų č ć š ž |
| vietnamština | ă â ê ô ơ ư a všechny tóny (ạ ả ấ ầ ẩ ẫ ậ …) |

## Zvláštní případy

Některá písmena se na základní písmeno nerozkládají. Plugin je proto
převádí podle vlastní tabulky:

| Znak | Výsledek |
|---|---|
| Đ đ | D d |
| Ł ł | L l |
| Ø ø | O o |
| Ħ ħ (maltština) | H h |
| Ŀ ŀ (katalánština) | L l |
| Ŧ ŧ (sámské jazyky) | T t |
| Ǿ ǿ | O o |
| ı (turecké i bez tečky) | i |
| Ǆ ǅ ǆ (dž jako jeden znak) | DZ Dz dz |
| ß | ss |
| Æ æ, Ǣ ǣ, Ǽ ǽ | AE ae |
| Œ œ | OE oe |

Spřežky a samostatná písmena bez diakritiky (ĳ, lj, nj, þ, ð a další) plugin
nemění, protože nejde o diakritiku. Výjimkou jsou ß, æ a œ, které plugin
převádí odjakživa.

Samostatná diakritická znaménka (U+0300 až U+036F) plugin vynechá. Objevují
se v názvech souborů zkopírovaných z macOS, kde se písmeno ukládá jako
základní písmeno a za ním znaménko.

## Co plugin nemění

- **Jiná písma** (azbuka, řečtina a další). Nejde o diakritiku, ale
  o přepis do latinky, a ten plugin záměrně nedělá. Pro Total Commander
  už existuje plugin [Translit_wdx](https://totalcmd.net/plugring/Translit2.html)
  (32 i 64 bit), který přepisuje cyrilici, řečtinu a další písma
  v Hromadném přejmenování, například maskou `[=wdx_translit.(INT) Rus2lat]`.
  Diacritics se proto drží jen diakritiky.
- **Číslice, interpunkce a symboly** (–, „“, ©, € a podobně).
- **Latinková písmena, která se nerozkládají a nejsou v tabulce výše.** Je
  jich 139, většinou jde o fonetické nebo historické znaky. Z písmen
  živých jazyků sem patří samostatná písmena a spřežky bez diakritiky:

| Znak | Jazyk | Poznámka |
|---|---|---|
| Ð ð, Þ þ | islandština, faerština | samostatná písmena; Ð se v chorvatštině někdy píše místo Đ |
| Ĳ ĳ | nizozemština | spřežka |
| Ŋ ŋ | sámské jazyky | samostatné písmeno |
| Ǉ ǈ ǉ, Ǌ ǋ ǌ, Ǳ ǲ ǳ | chorvatština, srbština (latinka) | spřežky lj, nj, dz v jednom znaku |
| ẞ | němčina | velké ß |

## Srovnání s ClipDiac

Program ClipDiac (Radim Tkačík, 2003, freeware) odstraňuje
diakritiku podle čtyř převodních tabulek pro kódování Kamenický, CP852,
ISO-8859-2 a Windows-1250. Skript `tools/compare_clipdiac.py` porovná jeho
tabulky s pluginem znak po znaku. Liší se jen tři znaky:

| Znak | ClipDiac | Plugin |
|---|---|---|
| Ó (Kamenický) | o | O |
| ¬ (CP852) | a | ¬ |
| ß | s (v Kamenickém beze změny) | ss |

U prvních dvou jde o chyby v tabulkách ClipDiac. Plugin navíc pracuje
s Unicode, takže není omezený na jednobajtová kódování.

## Ověření

Skript `tools/compare_clipdiac.py` volá plugin přímo (64bitový Python):

```
python tools/compare_clipdiac.py C:\cesta\ClipDiac.exe out\diacritics.wdx64
```
