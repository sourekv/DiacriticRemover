# Chyba při načítání pluginu – diagnostika

Česky | [English](diagnostics.en.md)

Doplňkový popis k [návodu](../README.cs.md) pro hlášku Total Commanderu
„Error loading plugin file! The plugin probably needs some DLLs missing on
your system.“

## Příčina

Plugin žádné další knihovny nepotřebuje, závisí jen na systémových
knihovnách Windows. Nejčastější příčinou je, že soubory pluginu
(`diacritics.wdx`, `diacritics.wdx64`) blokují **zásady skupiny** nastavené
správcem počítače (AppLocker, zásady omezení softwaru SRP). Typicky jde
o firemní počítače, které povolují jen schválené programy a knihovny.

## Ověření

Spusťte `diagnose.cmd`. Je v příloze `diacritics-diag.zip` u každého
releasu a ve složce `tools` ve zdrojích. Používá jen příkazy Windows,
nepotřebuje PowerShell ani žádné další programy a nic nemění.

1. Rozbalte `diagnose.cmd` do libovolné složky a spusťte ho. Bez parametru
   najde složku pluginu ve `wincmd.ini`, jinak ji zadejte:
   `diagnose.cmd "C:\cesta\ke\slozce\pluginu"`.
2. Skript vypíše nastavení zásad (AppLocker, SRP, WDAC, Smart App Control),
   otisky SHA256 souborů pluginu a záznamy o blokování z protokolů Windows.
3. Pak zkusí plugin dvakrát načíst systémovým `rundll32` (64 a 32 bit)
   a zeptá se, co ukázalo okno:
   - „Chybějící položka: DiacriticsLoadTest“ (anglicky „Missing entry“)
     znamená, že se plugin načetl v pořádku,
   - „Tento program je blokován zásadami skupiny“ (anglicky „This program
     is blocked by group policy“) potvrzuje blokaci zásadami.
4. Výsledek uloží do `diacritics-diag.txt` vedle skriptu.

## Řešení

Takovou blokaci plugin obejít neumí a ani nemá. Požádejte správce
o výjimku:

- povolení složky pluginu (pravidlo podle cesty), nebo
- povolení obou souborů pluginu podle otisku SHA256 (vypíše ho
  `diagnose.cmd`; po každé nové verzi je potřeba pravidlo obnovit).

Další možností je, aby správce plugin nainstaloval do složky, kterou
zásady povolují, obvykle `C:\Program Files`.

## Sestavení

`build.cmd` vytvoří vedle instalačního archivu i `out\diacritics-diag.zip`,
který obsahuje jen `tools\diagnose.cmd`.
