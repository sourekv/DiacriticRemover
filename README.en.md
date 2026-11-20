# Diacritics – diacritics in file names for Total Commander

[Česky](README.cs.md) | English | [Summary](README.md)

A content plugin (WDX) for Total Commander. It removes diacritics from file
and folder names, or adds Czech diacritics back. You use it in the
**Multi-Rename Tool** (Ctrl+M), which shows a preview before renaming and
can undo the change.

| Original name | Without diacritics | With diacritics |
|---|---|---|
| `Žlutý kůň.jpg` | `Zluty kun.jpg` | – |
| `Cesky Krumlov - zluty kun.jpg` | – | `Český Krumlov - žlutý kůň.jpg` |
| `SKOLA_dite_2024.pdf` | – | `ŠKOLA_dítě_2024.pdf` |

Removing diacritics works for Latin letters of all languages (also ł, ø, ß
and others, details in [docs/stripping.en.md](docs/stripping.en.md)).
Adding them uses a Czech dictionary, so it only makes sense for Czech names.

## 1. Installation

1. In Total Commander, move the cursor to `wdx_diacritics.zip` and press Enter.
2. Total Commander detects that the archive contains a plugin and asks
   "Do you want to install it?". Answer **Yes**.
3. Confirm the suggested folder, usually `…\plugins\wdx\Diacritics`.
4. If Total Commander is installed in `C:\Program Files`, writing there needs
   administrator rights. An "Access denied" message appears. Choose
   **As Administrator** and confirm the Windows prompt.

**The dictionary is part of the plugin.** The file `diacritics.dic` is in
the install archive and is copied into the plugin folder next to
`diacritics.wdx` and `diacritics.wdx64`. Nothing else is downloaded. The
plugin always looks for the dictionary and the user dictionary
`diacritics.user.txt` in its own folder.

**Updating to a new version:** same steps. When asked whether to overwrite
the existing plugin, answer **Yes**. If overwriting fails because the plugin
is loaded, close Total Commander and copy the files from the archive into
the plugin folder by hand (as administrator).

**Check:** press Ctrl+M and click the **Plugin** button (`[=?]`).
The left list must contain `diacritics`, and the right list its fields.
The field names are Czech:

| Field | Meaning | Returns |
|---|---|---|
| Nazev bez diakritiky | name without diacritics | name without extension, diacritics removed |
| Nazev s diakritikou | name with diacritics | name without extension, diacritics added |
| Pripona bez diakritiky | extension without diacritics | extension, diacritics removed |
| Cely nazev bez diakritiky | full name without diacritics | name with extension, diacritics removed |
| Cely nazev s diakritikou | full name with diacritics | name with extension, diacritics added |

**"Error loading plugin file! The plugin probably needs some DLLs missing
on your system."** The plugin needs no extra libraries (it depends only on
the system `KERNEL32.dll` and `USER32.dll`). The most common cause is that
the plugin files (`diacritics.wdx`, `diacritics.wdx64`) are blocked by
**group policy** set by the computer's administrator (AppLocker, Software
Restriction Policies), typically on company computers that allow only
approved programs and libraries. The dictionary `diacritics.dic` is a plain
data file and is not affected by these policies.

To check: run `diagnose.cmd` (from `diacritics-diag.zip` or the `tools`
folder). It uses only Windows commands and tries to load the plugin. The
message "This program is blocked by group policy" (Czech: "Tento program
je blokován zásadami skupiny") confirms a policy block.

The plugin cannot and should not work around such a block. Ask the
administrator for an exception: allow the plugin folder (path rule), or
both plugin files by their SHA256 hash (`diagnose.cmd` prints it; the rule
has to be renewed for every new version). Alternatively, the administrator
can install the plugin into a folder the policy allows, usually
`C:\Program Files`.

## 2. Saved settings in the Multi-Rename Tool

To avoid typing the mask every time, save it once as a named setting.

1. Select any file in a panel and press **Ctrl+M**.
2. In the **Rename mask: file name** field, type:

   ```
   [=diacritics.Nazev bez diakritiky]
   ```

   Or clear the field and insert it with **Plugin** > `diacritics` >
   *Nazev bez diakritiky* > OK.
3. Leave `[E]` in the **Extension** field.
4. Check the preview in the **New name** column, e.g. `Časné Ráno.flac`
   becomes `Casne Rano.flac`.
5. Press **F2** (or open the list in the top right corner) and choose
   **Save settings**.
6. Type the name `Remove diacritics` and press Enter.
7. Repeat steps 2 to 6 with the mask

   ```
   [=diacritics.Nazev s diakritikou]
   ```

   and the name `Add diacritics`.
8. Close the window with **Close**. Do not press **Start!**, or the files
   will be renamed.

The settings are stored in `wincmd.ini` (usually
`%APPDATA%\GHISLER\wincmd.ini`) in the `[rename]` section. To add them by
hand, first close Total Commander (it rewrites the file on exit), then add
to the `[rename]` section:

```ini
Remove diacritics_name=[=diacritics.Nazev bez diakritiky]
Remove diacritics_ext=[E]
Remove diacritics_params=0|1|1|1
Add diacritics_name=[=diacritics.Nazev s diakritikou]
Add diacritics_ext=[E]
Add diacritics_params=0|1|1|1
```

## 3. Usage

1. Select files or folders and press **Ctrl+M**.
2. In the list in the top right corner (or after F2), choose
   **Remove diacritics** or **Add diacritics**.
3. Check the **New name** column and press **Start!**.
4. If you don't like the result, the **Undo** button reverts the renaming.

You can combine the mask with other elements, e.g. replace spaces with
underscores in the **Search for** field.

## 4. Things to watch out for

- **Write the plugin name in lowercase:** `[=diacritics.…]`. With
  `[=Diacritics.…]` the preview shows `<Error>` for every file.
- **The "Cely nazev …" fields already include the extension.** If you use
  them in the name mask, leave the extension mask empty, or you get
  `name.flac.flac`. For renaming, use the "Nazev …" fields with `[E]` as
  the extension.
- **Adding diacritics ignores context.** Each word gets its most frequent
  form, so for example "ze" always becomes "že". Words that already contain
  any diacritics are left alone. Upper and lower case is kept, and
  CamelCase words are processed part by part
  (`CeskyKrumlov` becomes `ČeskýKrumlov`).

## 5. Your own dictionary

The plugin folder contains `diacritics.user.txt` (UTF-8). Its entries take
precedence over the main dictionary. Line formats:

```
kůň        word with diacritics, the key "kun" is derived automatically
ze=ze      fixed mapping: leave "ze" without diacritics
# comment
```

In a folder under `C:\Program Files`, the file can only be saved with
administrator rights. Changes take effect after restarting Total Commander.

## 6. Building from source

### Prerequisites

| What | Note |
|---|---|
| Windows 10 (1803) or later | for `curl` and PowerShell, which come with the system |
| Visual Studio 2022 or later with the **Desktop development with C++** workload | Community or Build Tools is enough. You need the MSVC compilers for x64 and x86 (default for this workload) and the Windows SDK. Tested with Visual Studio 2026 Community (MSVC 14.52, Windows SDK 10.0.26100). |
| Python 3.9 or later | the `python` command must be on PATH. Only the standard library is used, nothing else to install. |
| Internet connection | only for the first build, to download the word list (21 MB) |
| About 60 MB of disk space | word list, dictionary and outputs in `out\` |

The script finds Visual Studio by itself (via `vswhere.exe`). If it is
installed elsewhere, or you want a specific version, set the `VCVARS`
variable to the path of `vcvarsall.bat` beforehand. If a prerequisite is
missing, the script reports it at the start (the messages are in Czech).

### Build

```bash
build.cmd
```

The script downloads the word list `data\src\cs_full.txt` (21 MB, not in
git) if it is missing, builds the dictionary from it (words seen at least
3 times), the 32-bit `diacritics.wdx`, the 64-bit `diacritics.wdx64`, test
programs, the install archive `out\wdx_diacritics.zip` and the diagnostic archive
`out\diacritics-diag.zip` (`diagnose.cmd`, for tracking down plugin load
errors on another computer).

The dictionary holds only the forms with diacritics; the plugin derives the
form without diacritics itself. Words are sorted and prefix-coded: each line
starts with a character giving how many letters the word shares with the
previous one, followed by the rest of the word. Only the header with the
source and license is human-readable. Interjections from subtitles with
three equal letters in a row ("aaa", "nooo") are left out. The format is
described in `tools/build_dict.py`.

Test:

```bash
out\test64.exe out\diacritics.wdx64
```

## 7. Credits

Adding diacritics would not be possible without the work of:

- **Hermit Dave** and the
  [FrequencyWords](https://github.com/hermitdave/FrequencyWords) project,
  the source of the Czech word frequency list `cs_full.txt`. The content is
  licensed under
  [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
- **The OpenSubtitles2018 corpus** from the [OPUS](https://opus.nlpl.eu/)
  project (Pierre Lison, Jörg Tiedemann, Milen Kouylekov), from which the
  word list was computed, and
  [OpenSubtitles.org](https://www.opensubtitles.org/), where the subtitles
  come from.

Thank you.

The dictionary `diacritics.dic` is derived from this list (words seen at
least 3 times, keeping only the most frequent form with diacritics for each
word), so like its source it is distributed under CC BY-SA 4.0.
