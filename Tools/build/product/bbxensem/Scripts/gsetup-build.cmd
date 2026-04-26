@echo off
setlocal

set SCRIPT_DIR=%~dp0
set SRC_FILE=%SCRIPT_DIR%gsetup.c
set EXE_FILE=%SCRIPT_DIR%gsetup.exe

set WCL_EXE=
set WATCOM_ROOT=

if not "%WATCOM%"=="" (
    if exist "%WATCOM%\binnt64\wcl.exe" set WCL_EXE=%WATCOM%\binnt64\wcl.exe
    if exist "%WATCOM%\binnt\wcl.exe" set WCL_EXE=%WATCOM%\binnt\wcl.exe
)

if "%WCL_EXE%"=="" (
    for %%I in (wcl.exe) do set WCL_EXE=%%~$PATH:I
)
if "%WCL_EXE%"=="" goto TOOLERROR

for %%I in ("%WCL_EXE%") do set WATCOM_ROOT=%%~dpI..
for %%I in ("%WATCOM_ROOT%") do set WATCOM_ROOT=%%~fI

set WATCOM=%WATCOM_ROOT%
"%WCL_EXE%" -bt=dos -ms -zq -i="%WATCOM_ROOT%\h" -fe="%EXE_FILE%" "%SRC_FILE%"
if errorlevel 1 goto BUILDERROR
echo Built %EXE_FILE%
exit /b 0

:TOOLERROR
echo ERROR: Could not find OpenWatcom wcl.
echo ERROR: Put tools in PATH or set WATCOM.
exit /b 1

:BUILDERROR
echo ERROR: Failed to build gsetup.exe
exit /b 1
