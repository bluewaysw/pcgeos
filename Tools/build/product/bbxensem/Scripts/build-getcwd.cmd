@echo off
setlocal

set SCRIPT_DIR=%~dp0
set ASM_FILE=%SCRIPT_DIR%getcwd.asm
set OBJ_FILE=%SCRIPT_DIR%getcwd.obj
set COM_FILE=%SCRIPT_DIR%getcwd.com

set WASM_EXE=
set WLINK_EXE=

if not "%WATCOM%"=="" (
    if exist "%WATCOM%\binnt64\wasm.exe" set WASM_EXE=%WATCOM%\binnt64\wasm.exe
    if exist "%WATCOM%\binnt\wasm.exe" set WASM_EXE=%WATCOM%\binnt\wasm.exe
    if exist "%WATCOM%\binnt64\wlink.exe" set WLINK_EXE=%WATCOM%\binnt64\wlink.exe
    if exist "%WATCOM%\binnt\wlink.exe" set WLINK_EXE=%WATCOM%\binnt\wlink.exe
)

if "%WASM_EXE%"=="" (
    for %%I in (wasm.exe) do set WASM_EXE=%%~$PATH:I
)
if "%WLINK_EXE%"=="" (
    for %%I in (wlink.exe) do set WLINK_EXE=%%~$PATH:I
)

if "%WASM_EXE%"=="" goto TOOLERROR
if "%WLINK_EXE%"=="" goto TOOLERROR

"%WASM_EXE%" -zq -fo="%OBJ_FILE%" "%ASM_FILE%"
if errorlevel 1 goto BUILDERROR

"%WLINK_EXE%" option quiet format dos com option nodefault option start=_start file "%OBJ_FILE%" name "%COM_FILE%"
if errorlevel 1 goto BUILDERROR

if exist "%OBJ_FILE%" del /f /q "%OBJ_FILE%" >nul 2>&1
echo Built %COM_FILE%
exit /b 0

:TOOLERROR
echo ERROR: Could not find OpenWatcom wasm/wlink.
echo ERROR: Put tools in PATH or set WATCOM.
exit /b 1

:BUILDERROR
echo ERROR: Failed to build getcwd.com
exit /b 1
