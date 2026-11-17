# TcAccents – diakritika v názvech souborů pro Total Commander

Obsahový plugin (WDX) pro Total Commander. Odstraní nebo doplní českou
diakritiku v názvech souborů a složek. Používá se v nástroji
**Hromadné přejmenování** (Ctrl+M), kde před přejmenováním uvidíte náhled
a změnu můžete vrátit.

| Původní název | Bez diakritiky | S diakritikou |
|---|---|---|
| `Žlutý kůň.jpg` | `Zluty kun.jpg` | – |
| `Cesky Krumlov - zluty kun.jpg` | – | `Český Krumlov - žlutý kůň.jpg` |
| `SKOLA_dite_2024.pdf` | – | `ŠKOLA_dítě_2024.pdf` |

## 1. Instalace

1. V Total Commanderu najeďte na soubor `TcAccents.zip` a stiskněte Enter.
2. Total Commander pozná, že archiv obsahuje plugin, a zeptá se
   „Do you want to install it?“. Odpovězte **Yes**.
3. Potvrďte navrženou složku, obvykle `…\plugins\wdx\TcAccents`.
4. Pokud je Total Commander v `C:\Program Files`, vyžaduje zápis práva
   správce. Objeví se hláška „Access denied“. Zvolte **As Administrator**
   a potvrďte dotaz Windows.

**Aktualizace na novou verzi:** stejný postup. Na dotaz, zda přepsat
existující plugin, odpovězte **Yes**. Pokud přepsání selže, protože je
plugin načtený, zavřete Total Commander a soubory z archivu nakopírujte do
složky pluginu ručně (jako správce).

**Kontrola:** stiskněte Ctrl+M, klikněte na tlačítko **Plugin** (`[=?]`).
V levém seznamu musí být `tcaccents` a vpravo jeho pole:

| Pole | Co vrací |
|---|---|
| Nazev bez diakritiky | název bez přípony, diakritika odstraněna |
| Nazev s diakritikou | název bez přípony, diakritika doplněna |
| Pripona bez diakritiky | přípona, diakritika odstraněna |
| Cely nazev bez diakritiky | název i s příponou, diakritika odstraněna |
| Cely nazev s diakritikou | název i s příponou, diakritika doplněna |

## 2. Uložená nastavení v Hromadném přejmenování

Abyste masku nemuseli pokaždé vypisovat, uložte si ji jednou jako
pojmenované nastavení.

1. V panelu označte libovolný soubor a stiskněte **Ctrl+M**.
2. Do pole **Rename mask: file name** (Maska pro jméno) napište:

   ```
   [=tcaccents.Nazev bez diakritiky]
   ```

   Nebo pole smažte a vložte ho tlačítkem **Plugin** > `tcaccents` >
   *Nazev bez diakritiky* > OK.
3. V poli **Extension** (přípona) nechte `[E]`.
4. Ve sloupci **New name** zkontrolujte náhled, např. `Časné Ráno.flac`
   na `Casne Rano.flac`.
5. Stiskněte **F2** (nebo rozbalte seznam vpravo nahoře) a zvolte
   **Save settings**.
6. Napište název `Bez diakritiky` a potvrďte Enterem.
7. Opakujte body 2 až 6 s maskou

   ```
   [=tcaccents.Nazev s diakritikou]
   ```

   a názvem `S diakritikou`.
8. Okno zavřete tlačítkem **Close**. Tlačítko **Start!** nemačkejte, jinak
   se soubory přejmenují.

Nastavení se uloží do `wincmd.ini` (obvykle
`%APPDATA%\GHISLER\wincmd.ini`) do sekce `[rename]`. Pokud je chcete zapsat
ručně, zavřete nejdřív Total Commander (při ukončení by soubor přepsal)
a do sekce `[rename]` přidejte:

```ini
Bez diakritiky_name=[=tcaccents.Nazev bez diakritiky]
Bez diakritiky_ext=[E]
Bez diakritiky_params=0|1|1|1
S diakritikou_name=[=tcaccents.Nazev s diakritikou]
S diakritikou_ext=[E]
S diakritikou_params=0|1|1|1
```

## 3. Použití

1. Označte soubory nebo složky a stiskněte **Ctrl+M**.
2. V seznamu vpravo nahoře (nebo po F2) vyberte **Bez diakritiky** nebo
   **S diakritikou**.
3. Zkontrolujte sloupec **New name** a stiskněte **Start!**.
4. Když se výsledek nelíbí, tlačítko **Undo** přejmenování vrátí.

Masku lze kombinovat s dalšími prvky, např. v poli **Search for** nahradit
mezery podtržítkem.

## 4. Na co si dát pozor

- **Název pluginu pište malými písmeny:** `[=tcaccents.…]`. Se zápisem
  `[=TcAccents.…]` ukazuje náhled u všech souborů `<Error>`.
- **Pole „Cely nazev …“ už obsahují příponu.** Pokud je použijete
  v masce jména, nechte masku přípony prázdnou, jinak vznikne
  `nazev.flac.flac`. Pro přejmenování proto používejte pole „Nazev …“
  a v příponě `[E]`.
- **Doplňování diakritiky nezná kontext.** Každé slovo dostane svůj
  nejčastější tvar, takže např. „ze“ se vždy změní na „že“. Slova, která
  už nějakou diakritiku mají, se nemění. Velká a malá písmena zůstanou
  zachována a slova psaná CamelCase se zpracují po částech
  (`CeskyKrumlov` na `ČeskýKrumlov`).

## 5. Vlastní slovník

Ve složce pluginu je soubor `TcAccents.user.txt` (UTF-8). Jeho položky mají
přednost před hlavním slovníkem. Formáty řádků:

```
kůň        slovo s diakritikou, klíč „kun“ se odvodí sám
ze=ze      pevný překlad: „ze“ nechat bez diakritiky
# komentář
```

Ve složce v `C:\Program Files` jde soubor uložit jen s právy správce. Změna se
projeví po restartu Total Commanderu.

## 6. Sestavení ze zdrojů

Potřeba je Visual Studio 2026 (C++) a Python 3.

```bash
build.cmd
```

Skript stáhne seznam slov `data\src\cs_full.txt` (21 MB, není v gitu),
pokud ještě chybí, sestaví z něj slovník (slova s aspoň 3 výskyty),
32bitový `TcAccents.wdx`, 64bitový `TcAccents.wdx64`, testovací programy
a instalační archiv `out\TcAccents.zip`. Test:

```bash
out\test64.exe out\TcAccents.wdx64
```

Slovník vychází z [FrequencyWords](https://github.com/hermitdave/FrequencyWords)
(Hermit Dave), licence CC BY-SA 4.0.
