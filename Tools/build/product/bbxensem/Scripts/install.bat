@echo off
rem INSTALL.BAT
rem Install from USER\INSTALL into ..\.. (ensemble root), then call UPDATE.BAT.
rem
rem Usage:
rem   INSTALL.BAT
rem   INSTALL.BAT -F
rem   INSTALL.BAT DRIVE DIR
rem   INSTALL.BAT DRIVE DIR -F

set FORCE=

if "%1"=="" goto CHECKDIR
if "%1"=="-f" goto FORCELOCAL
if "%1"=="-F" goto FORCELOCAL
if "%2"=="" goto USAGE
if not "%4"=="" goto USAGE

%1
cd %2
if errorlevel 1 goto BADDIR

if "%3"=="" goto CHECKDIR
if "%3"=="-f" goto FORCEREMOTE
if "%3"=="-F" goto FORCEREMOTE
goto USAGE

:FORCELOCAL
if not "%2"=="" goto USAGE
set FORCE=1
goto CHECKDIR

:FORCEREMOTE
set FORCE=1
goto CHECKDIR

:CHECKDIR
if exist user\install\NUL goto CHECKINI
goto BADDIR

:CHECKINI
if exist ..\..\geos.ini goto INIEXISTS
if exist ..\..\geosec.ini goto INIEXISTS
goto DOINSTALL

:INIEXISTS
if "%FORCE%"=="1" goto FORCEWARN
echo NOTICE: Existing GEOS configuration found in ..\..\ (GEOS.INI or GEOSEC.INI).
echo NOTICE: Installation aborted. Use INSTALL.BAT -F to force install.
goto END

:FORCEWARN
echo WARNING: Existing GEOS configuration found in ..\..\ (GEOS.INI or GEOSEC.INI).
echo WARNING: Forced install will continue and may overwrite existing files.
echo.
echo Press CTRL+C now to cancel, or press any key to continue.
pause

:DOINSTALL
echo Installing from USER\INSTALL to ..\..\ ...
xcopy user\install\*.* ..\..\ /S /E /Y

echo.
echo Running UPDATE.BAT ...
call update.bat

echo.
echo Install complete.
goto END

:BADDIR
echo NOTICE: INSTALL.BAT must run from ...\FREEGEOS\6*
echo NOTICE: or be called with DRIVE and DIR arguments.
echo.
echo Usage:
echo   INSTALL.BAT
echo   INSTALL.BAT -F
echo   INSTALL.BAT DRIVE DIR
echo   INSTALL.BAT DRIVE DIR -F

goto END

:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   INSTALL.BAT
echo   INSTALL.BAT -F
echo   INSTALL.BAT DRIVE DIR
echo   INSTALL.BAT DRIVE DIR -F

:END
set FORCE=
