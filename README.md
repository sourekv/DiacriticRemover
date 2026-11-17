# TcAccents

A Total Commander content plugin (WDX) that removes diacritics from file and
folder names, or adds Czech diacritics back using a dictionary of about
300,000 words. It is used in the Multi-Rename Tool (Ctrl+M), with a preview
before renaming and Undo afterwards.

- `Žlutý kůň.jpg` becomes `Zluty kun.jpg`
- `Cesky Krumlov - zluty kun.jpg` becomes `Český Krumlov - žlutý kůň.jpg`

Install: download `TcAccents.zip` from
[Releases](https://github.com/sourekv/TcAccents/releases), press Enter on it
in Total Commander and confirm. The dictionary (`TcAccents.dic`) is part of the plugin, nothing
else is downloaded. Then use the mask
`[=tcaccents.Nazev bez diakritiky]` or `[=tcaccents.Nazev s diakritikou]`
in Ctrl+M.

The dictionary is derived from the Czech word list of
[FrequencyWords](https://github.com/hermitdave/FrequencyWords) by Hermit Dave,
built from the OpenSubtitles2018 corpus ([OPUS](https://opus.nlpl.eu/)).
Thanks to them. The dictionary is licensed CC BY-SA 4.0.

Full guide in English: [README.en.md](README.en.md)

---

Obsahový plugin (WDX) pro Total Commander, který odstraní diakritiku z názvů
souborů a složek, nebo doplní českou diakritiku podle slovníku s asi
300 000 slovy. Používá se v Hromadném přejmenování (Ctrl+M), s náhledem
před přejmenováním a možností vrátit změnu tlačítkem Undo.

- `Žlutý kůň.jpg` se změní na `Zluty kun.jpg`
- `Cesky Krumlov - zluty kun.jpg` se změní na `Český Krumlov - žlutý kůň.jpg`

Instalace: stáhněte `TcAccents.zip` z
[Releases](https://github.com/sourekv/TcAccents/releases), v Total Commanderu
na něm stiskněte Enter a potvrďte. Slovník (`TcAccents.dic`) je součástí pluginu, nic dalšího
se nestahuje. Pak v Ctrl+M použijte masku
`[=tcaccents.Nazev bez diakritiky]` nebo `[=tcaccents.Nazev s diakritikou]`.

Slovník je odvozený z českého seznamu slov projektu
[FrequencyWords](https://github.com/hermitdave/FrequencyWords) (Hermit Dave),
sestaveného z korpusu OpenSubtitles2018 ([OPUS](https://opus.nlpl.eu/)).
Děkujeme. Slovník je pod licencí CC BY-SA 4.0.

Podrobný návod česky: [README.cs.md](README.cs.md)
