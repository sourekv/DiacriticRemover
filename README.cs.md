# Diacritics – odstranění diakritiky z názvů souborů pro Total Commander

Česky | [English](README.en.md) | [Shrnutí](README.md)

Verze 0.4.0

Obsahový plugin (WDX) pro Total Commander. Odstraní diakritiku z názvů
souborů a složek. Používá se v nástroji **Hromadné přejmenování** (Ctrl+M),
kde před přejmenováním uvidíte náhled a změnu můžete vrátit.

| Původní název | Bez diakritiky |
|---|---|
| `Žlutý kůň.jpg` | `Zluty kun.jpg` |
| `ŠKOLA_dítě_2024.pdf` | `SKOLA_dite_2024.pdf` |
| `Łódź, Straße, Đoković.txt` | `Lodz, Strasse, Dokovic.txt` |

Diakritiku odstraní z latinkových písmen všech jazyků (podrobnosti
v [docs/stripping.cs.md](docs/stripping.cs.md)).

## 1. Instalace

1. V Total Commanderu najeďte na soubor `wdx_diacritics.zip` a stiskněte Enter.
2. Total Commander pozná, že archiv obsahuje plugin, a zeptá se
   „Do you want to install it?“. Odpovězte **Yes**.
3. Potvrďte navrženou složku, obvykle `…\plugins\wdx\Diacritics`.
4. Pokud je Total Commander v `C:\Program Files`, vyžaduje zápis práva
   správce. Objeví se hláška „Access denied“. Zvolte **As Administrator**
   a potvrďte dotaz Windows.

**Aktualizace na novou verzi:** stejný postup. Na dotaz, zda přepsat
existující plugin, odpovězte **Yes**. Pokud přepsání selže, protože je
plugin načtený, zavřete Total Commander a soubory z archivu nakopírujte do
složky pluginu ručně (jako správce).

**Kontrola:** stiskněte Ctrl+M, klikněte na tlačítko **Plugin** (`[=?]`).
V levém seznamu musí být `diacritics` a vpravo jeho pole:

| Pole | Co vrací |
|---|---|
| Nazev bez diakritiky | název bez přípony, diakritika odstraněna |
| Pripona bez diakritiky | přípona, diakritika odstraněna |
| Cely nazev bez diakritiky | název i s příponou, diakritika odstraněna |

**Hláška „Error loading plugin file! The plugin probably needs some DLLs
missing on your system.“** Plugin žádné další knihovny nepotřebuje.
Nejčastěji ho blokují zásady skupiny nastavené správcem počítače, typicky
na firemních počítačích. Jak to ověřit a co s tím, popisuje
[docs/diagnostics.cs.md](docs/diagnostics.cs.md).

## 2. Uložené nastavení v Hromadném přejmenování

Abyste masku nemuseli pokaždé vypisovat, uložte si ji jednou jako
pojmenované nastavení.

1. V panelu označte libovolný soubor a stiskněte **Ctrl+M**.
2. Do pole **Rename mask: file name** (Maska pro jméno) napište:

   ```
   [=diacritics.Nazev bez diakritiky]
   ```

   Nebo pole smažte a vložte ho tlačítkem **Plugin** > `diacritics` >
   *Nazev bez diakritiky* > OK.
3. V poli **Extension** (přípona) nechte `[E]`.
4. Ve sloupci **New name** zkontrolujte náhled, např. `Časné Ráno.flac`
   na `Casne Rano.flac`.
5. Stiskněte **F2** (nebo rozbalte seznam vpravo nahoře) a zvolte
   **Save settings**.
6. Napište název `Bez diakritiky` a potvrďte Enterem.
7. Okno zavřete tlačítkem **Close**. Tlačítko **Start!** nemačkejte, jinak
   se soubory přejmenují.

Nastavení se uloží do `wincmd.ini` (obvykle
`%APPDATA%\GHISLER\wincmd.ini`) do sekce `[rename]`. Pokud ho chcete zapsat
ručně, zavřete nejdřív Total Commander (při ukončení by soubor přepsal)
a do sekce `[rename]` přidejte:

```ini
Bez diakritiky_name=[=diacritics.Nazev bez diakritiky]
Bez diakritiky_ext=[E]
Bez diakritiky_params=0|1|1|1
```

## 3. Použití

1. Označte soubory nebo složky a stiskněte **Ctrl+M**.
2. V seznamu vpravo nahoře (nebo po F2) vyberte **Bez diakritiky**.
3. Zkontrolujte sloupec **New name** a stiskněte **Start!**.
4. Když se výsledek nelíbí, tlačítko **Undo** přejmenování vrátí.

Masku lze kombinovat s dalšími prvky, např. v poli **Search for** nahradit
mezery podtržítkem.

## 4. Na co si dát pozor

- **Název pluginu pište malými písmeny:** `[=diacritics.…]`. Se zápisem
  `[=Diacritics.…]` ukazuje náhled u všech souborů `<Error>`.
- **Pole „Cely nazev bez diakritiky“ už obsahuje příponu.** Pokud ho
  použijete v masce jména, nechte masku přípony prázdnou, jinak vznikne
  `nazev.flac.flac`. Pro přejmenování proto používejte pole „Nazev bez
  diakritiky“ a v příponě `[E]`.
- **Pole vkládané tlačítkem Plugin se přidá na místo kurzoru.** Původní
  text masky (`[N]` nebo dříve vložené pole) zůstane. Před vložením masku
  smažte, jinak se název v náhledu zopakuje několikrát.

## 5. Sestavení ze zdrojů

### Předpoklady

| Co | Poznámka |
|---|---|
| Windows 10 nebo novější | PowerShell, který je součástí systému, vytvoří instalační archiv |
| Visual Studio 2022 nebo novější s úlohou **Vývoj desktopových aplikací v C++** | stačí Community nebo Build Tools. Potřeba jsou překladače MSVC pro x64 i x86 (u této úlohy výchozí) a Windows SDK. Ověřeno s Visual Studiem 2026 Community (MSVC 14.52, Windows SDK 10.0.26100). |

Visual Studio skript najde sám (přes `vswhere.exe`). Je-li nainstalované
jinde nebo chcete použít konkrétní verzi, nastavte předem proměnnou
`VCVARS` na cestu k `vcvarsall.bat`. Když Visual Studio chybí, skript to
na začátku ohlásí.

### Sestavení

```bash
build.cmd
```

Skript sestaví 32bitový `diacritics.wdx`, 64bitový `diacritics.wdx64`,
testovací programy a instalační archiv `out\wdx_diacritics.zip`.

Test:

```bash
out\test64.exe out\diacritics.wdx64
```
