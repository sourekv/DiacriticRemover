# TcAccents – diacritics in file names for Total Commander

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

Removing diacritics works for all Latin letters (also ł, ø, ß and others).
Adding them uses a Czech dictionary, so it only makes sense for Czech names.

## 1. Installation

1. In Total Commander, move the cursor to `TcAccents.zip` and press Enter.
2. Total Commander detects that the archive contains a plugin and asks
   "Do you want to install it?". Answer **Yes**.
3. Confirm the suggested folder, usually `…\plugins\wdx\TcAccents`.
4. If Total Commander is installed in `C:\Program Files`, writing there needs
   administrator rights. An "Access denied" message appears. Choose
   **As Administrator** and confirm the Windows prompt.

**Updating to a new version:** same steps. When asked whether to overwrite
the existing plugin, answer **Yes**. If overwriting fails because the plugin
is loaded, close Total Commander and copy the files from the archive into
the plugin folder by hand (as administrator).

**Check:** press Ctrl+M and click the **Plugin** button (`[=?]`).
The left list must contain `tcaccents`, and the right list its fields.
The field names are Czech:

| Field | Meaning | Returns |
|---|---|---|
| Nazev bez diakritiky | name without diacritics | name without extension, diacritics removed |
| Nazev s diakritikou | name with diacritics | name without extension, diacritics added |
| Pripona bez diakritiky | extension without diacritics | extension, diacritics removed |
| Cely nazev bez diakritiky | full name without diacritics | name with extension, diacritics removed |
| Cely nazev s diakritikou | full name with diacritics | name with extension, diacritics added |

## 2. Saved settings in the Multi-Rename Tool

To avoid typing the mask every time, save it once as a named setting.

1. Select any file in a panel and press **Ctrl+M**.
2. In the **Rename mask: file name** field, type:

   ```
   [=tcaccents.Nazev bez diakritiky]
   ```

   Or clear the field and insert it with **Plugin** > `tcaccents` >
   *Nazev bez diakritiky* > OK.
3. Leave `[E]` in the **Extension** field.
4. Check the preview in the **New name** column, e.g. `Časné Ráno.flac`
   becomes `Casne Rano.flac`.
5. Press **F2** (or open the list in the top right corner) and choose
   **Save settings**.
6. Type the name `Remove diacritics` and press Enter.
7. Repeat steps 2 to 6 with the mask

   ```
   [=tcaccents.Nazev s diakritikou]
   ```

   and the name `Add diacritics`.
8. Close the window with **Close**. Do not press **Start!**, or the files
   will be renamed.

The settings are stored in `wincmd.ini` (usually
`%APPDATA%\GHISLER\wincmd.ini`) in the `[rename]` section. To add them by
hand, first close Total Commander (it rewrites the file on exit), then add
to the `[rename]` section:

```ini
Remove diacritics_name=[=tcaccents.Nazev bez diakritiky]
Remove diacritics_ext=[E]
Remove diacritics_params=0|1|1|1
Add diacritics_name=[=tcaccents.Nazev s diakritikou]
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

- **Write the plugin name in lowercase:** `[=tcaccents.…]`. With
  `[=TcAccents.…]` the preview shows `<Error>` for every file.
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

The plugin folder contains `TcAccents.user.txt` (UTF-8). Its entries take
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
3 times), the 32-bit `TcAccents.wdx`, the 64-bit `TcAccents.wdx64`, test
programs and the install archive `out\TcAccents.zip`. Test:

```bash
out\test64.exe out\TcAccents.wdx64
```

The dictionary is based on
[FrequencyWords](https://github.com/hermitdave/FrequencyWords)
(Hermit Dave), licensed CC BY-SA 4.0.
