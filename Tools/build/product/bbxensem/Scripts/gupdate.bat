@echo off
rem GUPDATE.BAT
rem Copy USER\UPDATE contents into ..\.. (ensemble root), overwriting existing files.
rem
rem Usage:
rem   GUPDATE.BAT
rem   GUPDATE.BAT DRIVE DIR

set UPDATE_SOURCE=setup\update
set UPDATE_TARGET=..\..\

if "%1"=="" goto CHECKDIR
if "%2"=="" goto USAGE
if not "%3"=="" goto USAGE

%1
cd %2
if errorlevel 1 goto BADDIR

goto CHECKDIR

:CHECKDIR
if exist %UPDATE_SOURCE%\NUL goto DOUPDATE
goto BADDIR

:DOUPDATE
echo Updating from %UPDATE_SOURCE% to %UPDATE_TARGET% ...
xcopy %UPDATE_SOURCE%\*.* %UPDATE_TARGET% /S /E /Y

echo.
echo Update complete.
goto END

:BADDIR
echo NOTICE: GUPDATE.BAT must run from ...\FREEGEOS\6*
echo NOTICE: or be called with DRIVE and DIR arguments.
echo.
echo Usage:
echo   GUPDATE.BAT
echo   GUPDATE.BAT DRIVE DIR
goto END

:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   GUPDATE.BAT
echo   GUPDATE.BAT DRIVE DIR

:END
