# Plugin load error – diagnostics

[Česky](diagnostics.cs.md) | English

A companion to the [guide](../README.en.md) for the Total Commander message
"Error loading plugin file! The plugin probably needs some DLLs missing on
your system."

## Cause

The plugin needs no extra libraries; it depends only on system libraries of
Windows. The most common cause is that the plugin files (`diacritics.wdx`,
`diacritics.wdx64`) are blocked by **group policy** set by the computer's
administrator (AppLocker, Software Restriction Policies). This is typical
for company computers that allow only approved programs and libraries.

## Checking

Run `diagnose.cmd`. It is attached to every release as
`diacritics-diag.zip` and is in the `tools` folder of the sources. It uses
only Windows commands, needs neither PowerShell nor any other program, and
changes nothing. Its messages are in English.

1. Extract `diagnose.cmd` to any folder and run it. Without a parameter it
   finds the plugin folder in `wincmd.ini`; otherwise pass it:
   `diagnose.cmd "C:\path\to\plugin\folder"`.
2. The script prints the policy settings (AppLocker, SRP, WDAC, Smart App
   Control), SHA256 hashes of the plugin files and blocking entries from
   the Windows event logs.
3. Then it tries to load the plugin twice with the system `rundll32` (64
   and 32 bit) and asks what the window showed:
   - "Missing entry: DiacriticsLoadTest" (Czech "Chybějící položka") means
     the plugin loaded fine,
   - "This program is blocked by group policy" (Czech "Tento program je
     blokován zásadami skupiny") confirms a policy block.
4. The result is saved to `diacritics-diag.txt` next to the script.

## Solution

The plugin cannot and should not work around such a block. Ask the
administrator for an exception:

- allow the plugin folder (path rule), or
- allow both plugin files by their SHA256 hash (`diagnose.cmd` prints it;
  the rule has to be renewed for every new version).

Alternatively, the administrator can install the plugin into a folder the
policy allows, usually `C:\Program Files`.

## Build

Besides the install archive, `build.cmd` creates `out\diacritics-diag.zip`,
which contains only `tools\diagnose.cmd`.
