@echo off
rem TcAccents - diagnostika nacitani pluginu (issue #1). Nic nemeni.
rem Pouziva jen prikazy Windows, zadne dalsi programy.
rem Pouziti:  diagnose.cmd ["slozka s pluginem"]
rem Bez parametru vezme slozku z wincmd.ini. Vysledek ulozi do
rem tcaccents-diag.txt vedle tohoto souboru a zobrazi ho.
setlocal
set "OUT=%~dp0tcaccents-diag.txt"
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
for /f "tokens=1,* delims==" %%a in ('findstr /i /r "tcaccents\.wdx" "%INI%"') do set "PLUGIN=%%b"
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
if exist "%INI%" findstr /n /i /c:"tcaccents.wdx" /c:"[=tcaccents." "%INI%"
echo.
if not defined DIR goto no_dir
echo === Slozka pluginu: %DIR% ===
rem dir /r ukaze i skryte proudy; :Zone.Identifier znamena soubor stazeny z internetu
dir /r "%DIR%"
call :file TcAccents.wdx
call :file TcAccents.wdx64
goto events
:no_dir
echo Slozka pluginu neni zadana ani ve wincmd.ini.
echo Spustte: diagnose.cmd "C:\cesta\ke\slozce\pluginu"
:events
echo.
echo === Protokol AppLocker (EXE a DLL) ===
wevtutil qe "Microsoft-Windows-AppLocker/EXE and DLL" /c:500 /rd:true /f:text | findstr /i "tcaccents test32 test64"
echo.
echo === Protokol Code Integrity / Smart App Control ===
wevtutil qe "Microsoft-Windows-CodeIntegrity/Operational" /c:500 /rd:true /f:text | findstr /i "tcaccents test32 test64"
echo.
echo === Protokol Windows Defender ===
wevtutil qe "Microsoft-Windows-Windows Defender/Operational" /c:500 /rd:true /f:text | findstr /i "tcaccents test32 test64"
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
rem Test nacteni pluginu systemovym rundll32. Vola neexistujici funkci, takze
rem se plugin jen nacte a nic se nespusti. Vysledek ukaze rundll32 v okne.
:load_tests
set "RUN64=%SystemRoot%\System32\rundll32.exe"
if defined PROCESSOR_ARCHITEW6432 set "RUN64=%SystemRoot%\Sysnative\rundll32.exe"
set "RUN32=%SystemRoot%\SysWOW64\rundll32.exe"
echo.
echo === Test nacteni pluginu ===
echo Ted se dvakrat objevi okno rundll32. Precte si jeho text a zavrete ho.
echo   "Chybejici polozka: TcAccentsLoadTest" (anglicky "Missing entry")
echo       = plugin se nacetl v poradku.
echo   "Pri spousteni souboru ... doslo k problemu" a dalsi text
echo       = plugin se nenacetl, opiste prosim ten dalsi text.
echo.
>> "%OUT%" echo.
>> "%OUT%" echo === Test nacteni pluginu (rundll32) ===
if exist "%RUN64%" call :load_one "%RUN64%" "%DIR%\TcAccents.wdx64" 64
if exist "%RUN32%" call :load_one "%RUN32%" "%DIR%\TcAccents.wdx" 32
exit /b

:load_one
echo Test %3 bit: %~2
"%~1" "%~2",TcAccentsLoadTest
choice /c 12 /n /m "Co okno ukazalo? 1 = Chybejici polozka (nacteno), 2 = jiny text: "
if errorlevel 2 goto load_fail
>> "%OUT%" echo %3 bit: nacteno v poradku (Chybejici polozka)
exit /b
:load_fail
set "MSG="
set /p "MSG=Opiste text z okna: "
>> "%OUT%" echo %3 bit: CHYBA: %MSG%
exit /b
