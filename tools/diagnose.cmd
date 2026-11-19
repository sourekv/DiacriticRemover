@echo off
rem TcAccents - diagnostika nacitani pluginu (issue #1). Nic nemeni.
rem Pouziti:  diagnose.cmd ["slozka s pluginem"]
rem Bez parametru vezme slozku z wincmd.ini. Vysledek ulozi do
rem tcaccents-diag.txt vedle tohoto souboru a zobrazi ho.
setlocal
set "HERE=%~dp0"
set "OUT=%~dp0tcaccents-diag.txt"
set "INI=%APPDATA%\GHISLER\wincmd.ini"
set "DIR=%~1"
call :main > "%OUT%" 2>&1
type "%OUT%"
echo.
echo Vysledek je ulozen v: %OUT%
pause
exit /b

:main
echo === System ===
ver
echo Architektura: %PROCESSOR_ARCHITECTURE% %PROCESSOR_ARCHITEW6432%
echo Smart App Control (0 vypnuto, 1 zapnuto, 2 zkusebni):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v VerifiedAndReputablePolicyState
echo.
echo === Total Commander ===
tasklist /fi "imagename eq TOTALCMD*"
echo wincmd.ini: %INI%
if not exist "%INI%" echo wincmd.ini neexistuje
if exist "%INI%" findstr /n /i /c:"tcaccents.wdx" /c:"[=tcaccents." "%INI%"
if defined DIR goto have_dir
if not exist "%INI%" goto have_dir
for /f "tokens=1,* delims==" %%a in ('findstr /i /r "tcaccents\.wdx" "%INI%"') do set "PLUGIN=%%b"
if defined PLUGIN for %%x in ("%PLUGIN%") do set "DIR=%%~dpx"
:have_dir
echo.
if not defined DIR goto no_dir
if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"
echo === Slozka pluginu: %DIR% ===
rem dir /r ukaze i skryte proudy; :Zone.Identifier znamena soubor stazeny z internetu
dir /r "%DIR%"
call :file TcAccents.wdx
call :file TcAccents.wdx64
echo.
echo === Test nacteni 64bit ===
"%HERE%test64.exe" "%DIR%\TcAccents.wdx64" "C:\a\zluty kun.txt"
echo navratovy kod: %errorlevel%
echo.
echo === Test nacteni 32bit ===
"%HERE%test32.exe" "%DIR%\TcAccents.wdx" "C:\a\zluty kun.txt"
echo navratovy kod: %errorlevel%
goto events
:no_dir
echo Slozka pluginu neni zadana ani ve wincmd.ini.
echo Spustte: diagnose.cmd "C:\cesta\ke\slozce\pluginu"
:events
echo.
echo === Code Integrity / Smart App Control ===
wevtutil qe "Microsoft-Windows-CodeIntegrity/Operational" /c:300 /rd:true /f:text | findstr /i "tcaccents"
echo.
echo === Windows Defender ===
wevtutil qe "Microsoft-Windows-Windows Defender/Operational" /c:300 /rd:true /f:text | findstr /i "tcaccents"
echo.
echo === Konec ===
exit /b

:file
echo --- %1
if not exist "%DIR%\%1" echo CHYBI
if not exist "%DIR%\%1" exit /b
certutil -hashfile "%DIR%\%1" SHA256 | findstr /v /i "certutil"
echo Zone.Identifier (hlaska "nelze nalezt soubor" = neni oznacen jako stazeny z internetu):
more < "%DIR%\%1:Zone.Identifier"
exit /b
