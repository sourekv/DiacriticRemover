@echo off
rem Diacritics - diagnostics for plugin load errors (issue #1). Changes nothing.
rem Uses only Windows commands, no other programs.
rem Usage:  diagnose.cmd ["plugin folder"]
rem Without a parameter it takes the folder from wincmd.ini. The result is
rem saved to diacritics-diag.txt next to this file and shown.
setlocal
set "OUT=%~dp0diacritics-diag.txt"
set "INI=%APPDATA%\GHISLER\wincmd.ini"
set "DIR=%~1"
call :find_dir
call :main > "%OUT%" 2>&1
type "%OUT%"
if defined DIR call :load_tests
echo.
echo The result is saved in: %OUT%
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
echo Architecture: %PROCESSOR_ARCHITECTURE% %PROCESSOR_ARCHITEW6432%
echo.
echo === Smart App Control (0 off, 1 on, 2 evaluation) ===
reg query "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v VerifiedAndReputablePolicyState
echo.
echo === AppLocker (EnforcementMode 1 = enforced, 0 = audit only) ===
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\SrpV2" /s | findstr /i "HKEY EnforcementMode"
sc query AppIDSvc | findstr /i "STATE"
echo.
echo === Software Restriction Policies SRP (DefaultLevel 0 = disallowed; TransparentEnabled 2 = DLLs too) ===
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v TransparentEnabled
reg query "HKCU\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel
echo.
echo === WDAC, active Code Integrity policies (every Windows has a few) ===
dir /b "%SystemRoot%\System32\CodeIntegrity\CiPolicies\Active"
if exist "%SystemRoot%\System32\CodeIntegrity\SIPolicy.p7b" echo SIPolicy.p7b exists
echo.
echo === Total Commander ===
tasklist /fi "imagename eq TOTALCMD*"
echo wincmd.ini: %INI%
if not exist "%INI%" echo wincmd.ini does not exist
if exist "%INI%" findstr /n /i /c:"diacritics.wdx" /c:"[=diacritics." "%INI%"
echo.
if not defined DIR goto no_dir
echo === Plugin folder: %DIR% ===
rem dir /r also lists alternate streams; :Zone.Identifier marks a file downloaded from the internet
dir /r "%DIR%"
call :file diacritics.wdx
call :file diacritics.wdx64
goto events
:no_dir
echo The plugin folder was not given and is not in wincmd.ini.
echo Run: diagnose.cmd "C:\path\to\plugin\folder"
:events
echo.
echo === AppLocker log (EXE and DLL) ===
wevtutil qe "Microsoft-Windows-AppLocker/EXE and DLL" /c:500 /rd:true /f:text | findstr /i "diacritics test32 test64"
echo.
echo === Code Integrity / Smart App Control log ===
wevtutil qe "Microsoft-Windows-CodeIntegrity/Operational" /c:500 /rd:true /f:text | findstr /i "diacritics test32 test64"
echo.
echo === Windows Defender log ===
wevtutil qe "Microsoft-Windows-Windows Defender/Operational" /c:500 /rd:true /f:text | findstr /i "diacritics test32 test64"
echo.
echo === End of the automatic part ===
exit /b

:file
echo --- %1
if not exist "%DIR%\%1" echo MISSING
if not exist "%DIR%\%1" exit /b
certutil -hashfile "%DIR%\%1" SHA256 | findstr /v /i "certutil"
echo Zone.Identifier ("cannot find the file" = not marked as downloaded from the internet):
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
echo === Plugin load test ===
echo A rundll32 window appears twice. Read its text and close it.
echo   "Missing entry: DiacriticsLoadTest" (Czech "Chybejici polozka")
echo       = the plugin loaded fine.
echo   "There was a problem starting ..." followed by more text
echo       = the plugin did not load, please copy that text.
echo.
>> "%OUT%" echo.
>> "%OUT%" echo === Plugin load test (rundll32) ===
if exist "%RUN64%" call :load_one "%RUN64%" "%DIR%\diacritics.wdx64" 64
if exist "%RUN32%" call :load_one "%RUN32%" "%DIR%\diacritics.wdx" 32
exit /b

:load_one
echo Test %3 bit: %~2
"%~1" "%~2",DiacriticsLoadTest
choice /c 12 /n /m "What did the window show? 1 = Missing entry (loaded), 2 = other text: "
if errorlevel 2 goto load_fail
>> "%OUT%" echo %3 bit: loaded fine (Missing entry)
exit /b
:load_fail
set "MSG="
set /p "MSG=Copy the text from the window: "
>> "%OUT%" echo %3 bit: ERROR: %MSG%
exit /b
