@echo off
rem Builds diacritics.wdx (32-bit), diacritics.wdx64 (64-bit), the test
rem programs and the install zip into out\.
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

set CFLAGS=/nologo /O2 /MT /EHsc /std:c++17 /W3 /DUNICODE /D_UNICODE /utf-8
if not exist out mkdir out
if not exist out\obj32 mkdir out\obj32
if not exist out\obj64 mkdir out\obj64

rem ---- Plugin, 64-bit and 32-bit (each in its own environment) ------------
setlocal
call "%VCVARS%" x64 >nul || exit /b 1
cl %CFLAGS% /LD /Foout\obj64\ src\diacritics.cpp /link /DEF:src\diacritics.def /OUT:out\diacritics.wdx64 /IMPLIB:out\obj64\diacritics.lib user32.lib || exit /b 1
cl %CFLAGS% /Foout\obj64\ test\test.cpp /link /OUT:out\test64.exe || exit /b 1
endlocal

setlocal
call "%VCVARS%" x86 >nul || exit /b 1
cl %CFLAGS% /LD /Foout\obj32\ src\diacritics.cpp /link /DEF:src\diacritics.def /OUT:out\diacritics.wdx /IMPLIB:out\obj32\diacritics.lib user32.lib || exit /b 1
cl %CFLAGS% /Foout\obj32\ test\test.cpp /link /OUT:out\test32.exe || exit /b 1
endlocal

rem ---- Install zip -------------------------------------------------------
copy /y dist\pluginst.inf out\ >nul
copy /y README.cs.md out\readme_cs.txt >nul
copy /y README.en.md out\readme_en.txt >nul
copy /y LICENSE out\license.txt >nul
if exist out\wdx_diacritics.zip del out\wdx_diacritics.zip
powershell -NoProfile -Command "Compress-Archive -Path out\diacritics.wdx,out\diacritics.wdx64,out\pluginst.inf,out\readme_cs.txt,out\readme_en.txt,out\license.txt -DestinationPath out\wdx_diacritics.zip" || exit /b 1

rem ---- Diagnostic zip (issue #1): diagnose.cmd only, uses Windows commands
if exist out\diacritics-diag.zip del out\diacritics-diag.zip
powershell -NoProfile -Command "Compress-Archive -Path tools\diagnose.cmd -DestinationPath out\diacritics-diag.zip" || exit /b 1
echo Build OK: out\wdx_diacritics.zip, out\diacritics-diag.zip
exit /b 0

:no_vs
echo CHYBA: nenalezeno Visual Studio s nastroji C++ (MSVC x86/x64).
echo Nainstalujte Visual Studio (staci Community nebo Build Tools) s ulohou
echo "Vyvoj desktopovych aplikaci v C++", nebo nastavte promennou VCVARS
echo na cestu k vcvarsall.bat.
exit /b 1
