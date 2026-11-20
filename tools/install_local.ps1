# Installs out\ build of the diacritics plugin into the local Total Commander
# and migrates from the old TcAccents plugin. Run from the project folder:
#   powershell -ExecutionPolicy Bypass -File tools\install_local.ps1
# Steps: close TC (it rewrites wincmd.ini on exit), copy files as administrator
# (UAC prompt), switch [ContentPlugins] and the rename masks in wincmd.ini to
# diacritics, start TC again. A backup of wincmd.ini is kept next to it.
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

# 2. Copy files as administrator, remove the old plugin folder
$files = 'diacritics.wdx', 'diacritics.wdx64', 'diacritics.dic', 'readme_cs.txt', 'readme_en.txt' |
    ForEach-Object { Join-Path $out $_ }
$files += Join-Path $proj 'dist\diacritics.user.txt'
$list = ($files | ForEach-Object { "'$_'" }) -join ','
$cmd = "`$ErrorActionPreference='Stop'; New-Item -ItemType Directory -Force '$newDir' | Out-Null; " +
       "Copy-Item $list '$newDir' -Force; " +
       "if (Test-Path '$oldDir') { Remove-Item '$oldDir' -Recurse -Force }"
$p = Start-Process powershell -Verb RunAs -Wait -PassThru -ArgumentList '-NoProfile', '-Command', $cmd
if ($p.ExitCode -ne 0) { throw "Kopirovani jako spravce selhalo (kod $($p.ExitCode))." }

# 3. wincmd.ini: plugin path and masks
Copy-Item $ini "$ini.bak-diacritics" -Force
$enc = [Text.Encoding]::GetEncoding(28591)  # byte-preserving, ini is ANSI
$text = [IO.File]::ReadAllText($ini, $enc)
$text = $text -replace '(?im)^(\d+)=[^\r\n]*\\TcAccents\\TcAccents\.wdx(?=[ \t]*\r?$)', "`$1=$newDir\diacritics.wdx"
$text = $text -replace '(?i)\[=tcaccents\.', '[=diacritics.'
[IO.File]::WriteAllText($ini, $text, $enc)

# 4. Start Total Commander again
Start-Process $TcExe
Write-Host "Hotovo: $newDir"
