@echo off
rem GSETUP.BAT
rem Install from USER\INSTALL into ..\.. (ensemble root), then call GUPDATE.BAT.
rem
rem Usage:
rem   GSETUP.BAT
rem   GSETUP.BAT -F
rem   GSETUP.BAT DRIVE DIR
rem   GSETUP.BAT DRIVE DIR -F

set FORCE=
set INSTALL_SOURCE=setup\install
set ENSEMBLE_ROOT=..\..\
set UPDATE_SCRIPT=gupdate.bat

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
if exist %INSTALL_SOURCE%\NUL goto CHECKINI
goto BADDIR

:CHECKINI
if exist %ENSEMBLE_ROOT%geos.ini goto INIEXISTS
if exist %ENSEMBLE_ROOT%geosec.ini goto INIEXISTS
goto DOINSTALL

:INIEXISTS
if "%FORCE%"=="1" goto FORCEWARN
echo NOTICE: Existing GEOS configuration found in %ENSEMBLE_ROOT% (GEOS.INI or GEOSEC.INI).
echo NOTICE: Installation aborted. Use GSETUP.BAT -F to force install.
goto END

:FORCEWARN
echo WARNING: Existing GEOS configuration found in %ENSEMBLE_ROOT% (GEOS.INI or GEOSEC.INI).
echo WARNING: Forced install will continue and may overwrite existing files.
echo.
echo Press CTRL+C now to cancel, or press any key to continue.
pause

:DOINSTALL
echo Installing from %INSTALL_SOURCE% to %ENSEMBLE_ROOT% ...
xcopy %INSTALL_SOURCE%\*.* %ENSEMBLE_ROOT% /S /E /Y

rem Ensure bootstrap INI is present in ensemble root even if XCOPY omits it.
if exist %INSTALL_SOURCE%\geosec.ini copy %INSTALL_SOURCE%\geosec.ini %ENSEMBLE_ROOT%
if exist %INSTALL_SOURCE%\geos.ini copy %INSTALL_SOURCE%\geos.ini %ENSEMBLE_ROOT%

echo.
echo Running GUPDATE.BAT ...
call %UPDATE_SCRIPT%

echo.
echo Install complete.
goto END

:BADDIR
echo NOTICE: GSETUP.BAT must run from ...\FREEGEOS\6*
echo NOTICE: or be called with DRIVE and DIR arguments.
echo.
echo Usage:
echo   GSETUP.BAT
echo   GSETUP.BAT -F
echo   GSETUP.BAT DRIVE DIR
echo   GSETUP.BAT DRIVE DIR -F

goto END

:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   GSETUP.BAT
echo   GSETUP.BAT -F
echo   GSETUP.BAT DRIVE DIR
echo   GSETUP.BAT DRIVE DIR -F

:END
set FORCE=
