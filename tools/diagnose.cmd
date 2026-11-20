@echo off
rem Diacritics - diagnostics for plugin load errors (issue #1). Changes nothing.
rem Uses only Windows commands, no other programs.
rem Usage:  diagnose.cmd ["plugin folder"]
rem Without a parameter it takes the folder from wincmd.ini. The result is
rem saved to diacritics-diag.txt next to this file and shown.
rem Messages for the user are in Czech.
setlocal
set "OUT=%~dp0diacritics-diag.txt"
set "INI=%APPDATA%\GHISLER\wincmd.ini"
set "DIR=%~1"
call :find_dir
call :main > "%OUT%" 2>&1
type "%OUT%"
if defined DIR call :load_tests
echo.
echo Vysledek je ulozen v: %OUT%
pause
exit /b

rem ---------------------------------------------------------------------------
:find_dir
if defined DIR goto dir_trim
if not exist "%INI%" exit /b
for /f "tokens=1,* delims==" %%a in ('findstr /i /r "diacritics\.wdx" "%INI%"') do set "PLUGIN=%%b"
if defined PLUGIN for %%x in ("%PLUGIN%") do set "DIR=%%~dpx"
:dir_trim
if defined DIR if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"
exit /b

rem ---------------------------------------------------------------------------
:main
echo === System ===
ver
echo Architektura: %PROCESSOR_ARCHITECTURE% %PROCESSOR_ARCHITEW6432%
echo.
echo === Smart App Control (0 vypnuto, 1 zapnuto, 2 zkusebni) ===
reg query "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v VerifiedAndReputablePolicyState
echo.
echo === AppLocker (EnforcementMode 1 = vynucovano, 0 = jen audit) ===
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\SrpV2" /s | findstr /i "HKEY EnforcementMode"
sc query AppIDSvc | findstr /i "STATE"
echo.
echo === Zasady omezeni softwaru SRP (DefaultLevel 0 = zakazano; TransparentEnabled 2 = i DLL) ===
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v TransparentEnabled
reg query "HKCU\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel
echo.
echo === WDAC, aktivni zasady Code Integrity (nekolik zasad ma kazdy Windows) ===
dir /b "%SystemRoot%\System32\CodeIntegrity\CiPolicies\Active"
if exist "%SystemRoot%\System32\CodeIntegrity\SIPolicy.p7b" echo SIPolicy.p7b existuje
echo.
echo === Total Commander ===
tasklist /fi "imagename eq TOTALCMD*"
echo wincmd.ini: %INI%
if not exist "%INI%" echo wincmd.ini neexistuje
if exist "%INI%" findstr /n /i /c:"diacritics.wdx" /c:"[=diacritics." "%INI%"
echo.
if not defined DIR goto no_dir
echo === Slozka pluginu: %DIR% ===
rem dir /r also lists alternate streams; :Zone.Identifier marks a file downloaded from the internet
dir /r "%DIR%"
call :file diacritics.wdx
call :file diacritics.wdx64
goto events
:no_dir
echo Slozka pluginu neni zadana ani ve wincmd.ini.
echo Spustte: diagnose.cmd "C:\cesta\ke\slozce\pluginu"
:events
echo.
echo === Protokol AppLocker (EXE a DLL) ===
wevtutil qe "Microsoft-Windows-AppLocker/EXE and DLL" /c:500 /rd:true /f:text | findstr /i "diacritics test32 test64"
echo.
echo === Protokol Code Integrity / Smart App Control ===
wevtutil qe "Microsoft-Windows-CodeIntegrity/Operational" /c:500 /rd:true /f:text | findstr /i "diacritics test32 test64"
echo.
echo === Protokol Windows Defender ===
wevtutil qe "Microsoft-Windows-Windows Defender/Operational" /c:500 /rd:true /f:text | findstr /i "diacritics test32 test64"
echo.
echo === Konec automaticke casti ===
exit /b

:file
echo --- %1
if not exist "%DIR%\%1" echo CHYBI
if not exist "%DIR%\%1" exit /b
certutil -hashfile "%DIR%\%1" SHA256 | findstr /v /i "certutil"
echo Zone.Identifier (hlaska "nelze nalezt soubor" = neni oznacen jako stazeny z internetu):
more < "%DIR%\%1:Zone.Identifier"
exit /b

rem ---------------------------------------------------------------------------
rem Load test with the system rundll32. It calls a function that does not exist,
rem so the plugin is only loaded and nothing runs. rundll32 shows the result
rem in a window.
:load_tests
set "RUN64=%SystemRoot%\System32\rundll32.exe"
if defined PROCESSOR_ARCHITEW6432 set "RUN64=%SystemRoot%\Sysnative\rundll32.exe"
set "RUN32=%SystemRoot%\SysWOW64\rundll32.exe"
echo.
echo === Test nacteni pluginu ===
echo Ted se dvakrat objevi okno rundll32. Precte si jeho text a zavrete ho.
echo   "Chybejici polozka: DiacriticsLoadTest" (anglicky "Missing entry")
echo       = plugin se nacetl v poradku.
echo   "Pri spousteni souboru ... doslo k problemu" a dalsi text
echo       = plugin se nenacetl, opiste prosim ten dalsi text.
echo.
>> "%OUT%" echo.
>> "%OUT%" echo === Test nacteni pluginu (rundll32) ===
if exist "%RUN64%" call :load_one "%RUN64%" "%DIR%\diacritics.wdx64" 64
if exist "%RUN32%" call :load_one "%RUN32%" "%DIR%\diacritics.wdx" 32
exit /b

:load_one
echo Test %3 bit: %~2
"%~1" "%~2",DiacriticsLoadTest
choice /c 12 /n /m "Co okno ukazalo? 1 = Chybejici polozka (nacteno), 2 = jiny text: "
if errorlevel 2 goto load_fail
>> "%OUT%" echo %3 bit: nacteno v poradku (Chybejici polozka)
exit /b
:load_fail
set "MSG="
set /p "MSG=Opiste text z okna: "
>> "%OUT%" echo %3 bit: CHYBA: %MSG%
exit /b
