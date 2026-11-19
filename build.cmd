@echo off
rem Builds TcAccents.wdx (32-bit), TcAccents.wdx64 (64-bit), the dictionary,
rem the test programs and the install zip into out\.
rem Prerequisites: see README.en.md, section "Building from source".
setlocal
cd /d "%~dp0"

rem ---- Prerequisites -----------------------------------------------------
set "VSINSTALLER=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
rem vcvarsall.bat calls vswhere.exe; without this it prints a harmless error.
set "PATH=%PATH%;%VSINSTALLER%"
if defined VCVARS goto have_vcvars
if not exist "%VSINSTALLER%\vswhere.exe" goto no_vs
for /f "usebackq delims=" %%i in (`"%VSINSTALLER%\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH goto no_vs
set "VCVARS=%VSPATH%\VC\Auxiliary\Build\vcvarsall.bat"
:have_vcvars
if not exist "%VCVARS%" goto no_vs
where python >nul 2>nul || goto no_python
where curl >nul 2>nul || goto no_curl

set CFLAGS=/nologo /O2 /MT /EHsc /std:c++17 /W3 /DUNICODE /D_UNICODE /utf-8
if not exist out mkdir out
if not exist out\obj32 mkdir out\obj32
if not exist out\obj64 mkdir out\obj64

rem ---- Dictionary --------------------------------------------------------
rem The word list is not in git; download it when missing.
if not exist data\src mkdir data\src
if not exist data\src\cs_full.txt curl -sSL -f -o data\src\cs_full.txt https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/cs/cs_full.txt || exit /b 1
rem Words seen fewer than 3 times in the subtitles are mostly typos.
python tools\build_dict.py data\src\cs_full.txt out\TcAccents.dic 3 || exit /b 1

rem ---- Plugin, 64-bit and 32-bit (each in its own environment) ------------
setlocal
call "%VCVARS%" x64 >nul || exit /b 1
cl %CFLAGS% /LD /Foout\obj64\ src\TcAccents.cpp /link /DEF:src\TcAccents.def /OUT:out\TcAccents.wdx64 /IMPLIB:out\obj64\TcAccents.lib user32.lib || exit /b 1
cl %CFLAGS% /Foout\obj64\ test\test.cpp /link /OUT:out\test64.exe || exit /b 1
endlocal

setlocal
call "%VCVARS%" x86 >nul || exit /b 1
cl %CFLAGS% /LD /Foout\obj32\ src\TcAccents.cpp /link /DEF:src\TcAccents.def /OUT:out\TcAccents.wdx /IMPLIB:out\obj32\TcAccents.lib user32.lib || exit /b 1
cl %CFLAGS% /Foout\obj32\ test\test.cpp /link /OUT:out\test32.exe || exit /b 1
endlocal

rem ---- Install zip -------------------------------------------------------
copy /y dist\pluginst.inf out\ >nul
copy /y README.cs.md out\readme_cs.txt >nul
copy /y README.en.md out\readme_en.txt >nul
if exist out\TcAccents.zip del out\TcAccents.zip
powershell -NoProfile -Command "Compress-Archive -Path out\TcAccents.wdx,out\TcAccents.wdx64,out\TcAccents.dic,dist\TcAccents.user.txt,out\pluginst.inf,out\readme_cs.txt,out\readme_en.txt -DestinationPath out\TcAccents.zip" || exit /b 1

rem ---- Diagnostic zip (issue #1): batch + test programs, no PowerShell needed
if exist out\TcAccents-diag.zip del out\TcAccents-diag.zip
powershell -NoProfile -Command "Compress-Archive -Path tools\diagnose.cmd -DestinationPath out\TcAccents-diag.zip" || exit /b 1
echo Build OK: out\TcAccents.zip, out\TcAccents-diag.zip
exit /b 0

:no_vs
echo CHYBA: nenalezeno Visual Studio s nastroji C++ (MSVC x86/x64).
echo Nainstalujte Visual Studio (staci Community nebo Build Tools) s ulohou
echo "Vyvoj desktopovych aplikaci v C++", nebo nastavte promennou VCVARS
echo na cestu k vcvarsall.bat.
exit /b 1
:no_python
echo CHYBA: v PATH neni python (Python 3.9 nebo novejsi).
exit /b 1
:no_curl
echo CHYBA: v PATH neni curl (soucast Windows 10 1803 a novejsich).
exit /b 1
