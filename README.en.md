# Diacritics – remove diacritics from file names in Total Commander

[Česky](README.cs.md) | English | [Summary](README.md)

Version 0.4.0

A content plugin (WDX) for Total Commander. It removes diacritics from file
and folder names. You use it in the **Multi-Rename Tool** (Ctrl+M), which
shows a preview before renaming and can undo the change.

| Original name | Without diacritics |
|---|---|
| `Žlutý kůň.jpg` | `Zluty kun.jpg` |
| `ŠKOLA_dítě_2024.pdf` | `SKOLA_dite_2024.pdf` |
| `Łódź, Straße, Đoković.txt` | `Lodz, Strasse, Dokovic.txt` |

It works for Latin letters of all languages (details in
[docs/stripping.en.md](docs/stripping.en.md)).

## 1. Installation

1. In Total Commander, move the cursor to `wdx_diacritics.zip` and press Enter.
2. Total Commander detects that the archive contains a plugin and asks
   "Do you want to install it?". Answer **Yes**.
3. Confirm the suggested folder, usually `…\plugins\wdx\Diacritics`.
4. If Total Commander is installed in `C:\Program Files`, writing there needs
   administrator rights. An "Access denied" message appears. Choose
   **As Administrator** and confirm the Windows prompt.

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
| Pripona bez diakritiky | extension without diacritics | extension, diacritics removed |
| Cely nazev bez diakritiky | full name without diacritics | name with extension, diacritics removed |

**"Error loading plugin file! The plugin probably needs some DLLs missing
on your system."** The plugin needs no extra libraries. Most often it is
blocked by group policy set by the computer's administrator, typically on
company computers. How to check it and what to do is described in
[docs/diagnostics.en.md](docs/diagnostics.en.md).

## 2. Saved setting in the Multi-Rename Tool

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
7. Close the window with **Close**. Do not press **Start!**, or the files
   will be renamed.

The setting is stored in `wincmd.ini` (usually
`%APPDATA%\GHISLER\wincmd.ini`) in the `[rename]` section. To add it by
hand, first close Total Commander (it rewrites the file on exit), then add
to the `[rename]` section:

```ini
Remove diacritics_name=[=diacritics.Nazev bez diakritiky]
Remove diacritics_ext=[E]
Remove diacritics_params=0|1|1|1
```

## 3. Usage

1. Select files or folders and press **Ctrl+M**.
2. In the list in the top right corner (or after F2), choose
   **Remove diacritics**.
3. Check the **New name** column and press **Start!**.
4. If you don't like the result, the **Undo** button reverts the renaming.

You can combine the mask with other elements, e.g. replace spaces with
underscores in the **Search for** field.

## 4. Things to watch out for

- **Write the plugin name in lowercase:** `[=diacritics.…]`. With
  `[=Diacritics.…]` the preview shows `<Error>` for every file.
- **The "Cely nazev bez diakritiky" field already includes the extension.**
  If you use it in the name mask, leave the extension mask empty, or you
  get `name.flac.flac`. For renaming, use "Nazev bez diakritiky" with `[E]`
  as the extension.
- **The Plugin button inserts the field at the cursor.** The old text of the
  mask (`[N]` or a field inserted before) stays. Clear the mask first, or
  the name repeats several times in the preview.

## 5. Building from source

### Prerequisites

| What | Note |
|---|---|
| Windows 10 or later | PowerShell, which comes with the system, creates the install archive |
| Visual Studio 2022 or later with the **Desktop development with C++** workload | Community or Build Tools is enough. You need the MSVC compilers for x64 and x86 (default for this workload) and the Windows SDK. Tested with Visual Studio 2026 Community (MSVC 14.52, Windows SDK 10.0.26100). |

The script finds Visual Studio by itself (via `vswhere.exe`). If it is
installed elsewhere, or you want a specific version, set the `VCVARS`
variable to the path of `vcvarsall.bat` beforehand. If Visual Studio is
missing, the script reports it at the start (the messages are in Czech).

### Build

```bash
build.cmd
```

The script builds the 32-bit `diacritics.wdx`, the 64-bit
`diacritics.wdx64`, test programs and the install archive
`out\wdx_diacritics.zip`.

Test:

```bash
out\test64.exe out\diacritics.wdx64
```
