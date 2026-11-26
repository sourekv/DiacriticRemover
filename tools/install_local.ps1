# Installs out\ build of the diacritics plugin into the local Total Commander
# and migrates from the old TcAccents plugin. Run from the project folder:
#   powershell -ExecutionPolicy Bypass -File tools\install_local.ps1
# Steps: close TC (it rewrites wincmd.ini on exit), copy files as administrator
# (UAC prompt), switch [ContentPlugins] and the rename masks in wincmd.ini to
# diacritics, rewrite masks to the English field names, add the "Opravit
# diakritiku" preset, drop the "S diakritikou" preset, start TC again.
# A backup of wincmd.ini is kept next to it.
param(
    [string]$PluginRoot = 'C:\Program Files\TotalCommander\plugins\wdx',
    [string]$TcExe = 'C:\Program Files\TotalCommander\TOTALCMD64.EXE'
)
$ErrorActionPreference = 'Stop'
$proj = Split-Path $PSScriptRoot
$out = Join-Path $proj 'out'
$ini = "$env:APPDATA\GHISLER\wincmd.ini"
$newDir = Join-Path $PluginRoot 'Diacritics'
$oldDir = Join-Path $PluginRoot 'TcAccents'

# 1. Close Total Commander gracefully
$tc = Get-Process TOTALCMD* -ErrorAction SilentlyContinue
foreach ($p in $tc) { [void]$p.CloseMainWindow() }
foreach ($p in $tc) {
    if (-not $p.WaitForExit(15000)) { throw 'Total Commander se nezavrel, zavrete ho rucne a spustte skript znovu.' }
}

# 2. Copy files as administrator, remove the old plugin folder and the
#    dictionary files of versions up to 0.3.1
$files = 'diacritics.wdx', 'diacritics.wdx64', 'readme_cs.txt', 'readme_en.txt', 'license.txt' |
    ForEach-Object { Join-Path $out $_ }
$list = ($files | ForEach-Object { "'$_'" }) -join ','
$cmd = "`$ErrorActionPreference='Stop'; New-Item -ItemType Directory -Force '$newDir' | Out-Null; " +
       "Copy-Item $list '$newDir' -Force; " +
       "Remove-Item '$newDir\diacritics.dic','$newDir\diacritics.user.txt' -Force -ErrorAction SilentlyContinue; " +
       "if (Test-Path '$oldDir') { Remove-Item '$oldDir' -Recurse -Force }"
$p = Start-Process powershell -Verb RunAs -Wait -PassThru -ArgumentList '-NoProfile', '-Command', $cmd
if ($p.ExitCode -ne 0) { throw "Kopirovani jako spravce selhalo (kod $($p.ExitCode))." }

# 3. wincmd.ini: plugin path and masks
Copy-Item $ini "$ini.bak-diacritics" -Force
$enc = [Text.Encoding]::GetEncoding(28591)  # byte-preserving, ini is ANSI
$text = [IO.File]::ReadAllText($ini, $enc)
$text = $text -replace '(?im)^(\d+)=[^\r\n]*\\TcAccents\\TcAccents\.wdx(?=[ \t]*\r?$)', "`$1=$newDir\diacritics.wdx"
$text = $text -replace '(?i)\[=tcaccents\.', '[=diacritics.'
# Field names are English since 0.5.0: rewrite masks with the Czech ones.
$text = $text -replace '(?i)\[=diacritics\.Nazev bez diakritiky\]', '[=diacritics.Name without diacritics]'
$text = $text -replace '(?i)\[=diacritics\.Pripona bez diakritiky\]', '[=diacritics.Extension without diacritics]'
$text = $text -replace '(?i)\[=diacritics\.Cely nazev bez diakritiky\]', '[=diacritics.Full name without diacritics]'
# The "with diacritics" fields were removed after 0.3.1: drop their preset.
$text = $text -replace '(?im)^S diakritikou_(name|ext|params)=[^\r\n]*\r?\n', ''
# Second preset "Opravit diakritiku" (0.6.0), added after "Bez diakritiky".
if ($text -notmatch '(?im)^Opravit diakritiku_name=') {
    $preset = "Opravit diakritiku_name=[=diacritics.Name with fixed diacritics]`r`n" +
              "Opravit diakritiku_ext=[E]`r`nOpravit diakritiku_params=0|1|1|1`r`n"
    $text = $text -replace '(?im)(^Bez diakritiky_params=[^\r\n]*\r?\n)', "`$1$preset"
}
[IO.File]::WriteAllText($ini, $text, $enc)

# 4. Start Total Commander again
Start-Process $TcExe
Write-Host "Hotovo: $newDir"
