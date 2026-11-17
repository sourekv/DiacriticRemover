@echo off
rem Builds TcAccents.wdx (32-bit), TcAccents.wdx64 (64-bit), the dictionary,
rem the test program and the install zip into out\.
setlocal
cd /d "%~dp0"
set VCVARS="C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat"
set CFLAGS=/nologo /O2 /MT /EHsc /std:c++17 /W3 /DUNICODE /D_UNICODE /utf-8
if not exist out mkdir out
if not exist out\obj32 mkdir out\obj32
if not exist out\obj64 mkdir out\obj64

rem The word list is not in git; download it when missing.
if not exist data\src mkdir data\src
if not exist data\src\cs_full.txt curl -sSL -o data\src\cs_full.txt https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/cs/cs_full.txt || exit /b 1
rem Words seen fewer than 3 times in the subtitles are mostly typos.
python tools\build_dict.py data\src\cs_full.txt out\TcAccents.dic 3 || exit /b 1

call %VCVARS% x64 >nul || exit /b 1
cl %CFLAGS% /LD /Foout\obj64\ src\TcAccents.cpp /link /DEF:src\TcAccents.def /OUT:out\TcAccents.wdx64 /IMPLIB:out\obj64\TcAccents.lib user32.lib || exit /b 1
cl %CFLAGS% /Foout\obj64\ test\test.cpp /link /OUT:out\test64.exe || exit /b 1
endlocal & setlocal
cd /d "%~dp0"
set VCVARS="C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat"
set CFLAGS=/nologo /O2 /MT /EHsc /std:c++17 /W3 /DUNICODE /D_UNICODE /utf-8
call %VCVARS% x86 >nul || exit /b 1
cl %CFLAGS% /LD /Foout\obj32\ src\TcAccents.cpp /link /DEF:src\TcAccents.def /OUT:out\TcAccents.wdx /IMPLIB:out\obj32\TcAccents.lib user32.lib || exit /b 1
cl %CFLAGS% /Foout\obj32\ test\test.cpp /link /OUT:out\test32.exe || exit /b 1

if not exist out\TcAccents.user.txt copy /y dist\TcAccents.user.txt out\ >nul
copy /y dist\pluginst.inf out\ >nul
copy /y README.md out\readme.txt >nul
if exist out\TcAccents.zip del out\TcAccents.zip
powershell -NoProfile -Command "Compress-Archive -Path out\TcAccents.wdx,out\TcAccents.wdx64,out\TcAccents.dic,dist\TcAccents.user.txt,out\pluginst.inf,out\readme.txt -DestinationPath out\TcAccents.zip" || exit /b 1
echo Build OK: out\TcAccents.zip
