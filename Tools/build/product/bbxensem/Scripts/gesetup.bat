@echo off
rem GESETUP.BAT
rem Install/enable from SP_TOP (current working directory).
rem
rem Usage:
rem   GESETUP INSTALL
rem   GESETUP INSTALL -F
rem   GESETUP ENABLE

set FORCE=
set PHASE=
set SETUP_ROOT=freegeos\60beta\setup
set INSTALL_SOURCE=%SETUP_ROOT%\install
set ENABLE_SOURCE=%SETUP_ROOT%\enable

if "%1"=="" goto USAGE
if "%1"=="install" goto PARSEINSTALL
if "%1"=="INSTALL" goto PARSEINSTALL
if "%1"=="enable" goto PARSEENABLE
if "%1"=="ENABLE" goto PARSEENABLE
goto USAGE

:PARSEINSTALL
if "%2"=="" goto CHECKINSTALL
if "%2"=="-f" goto FORCEINSTALL
if "%2"=="-F" goto FORCEINSTALL
goto USAGE

:FORCEINSTALL
if not "%3"=="" goto USAGE
set FORCE=1
goto CHECKINSTALL

:PARSEENABLE
if not "%2"=="" goto USAGE
goto CHECKENABLE

:CHECKINSTALL
if exist %INSTALL_SOURCE%\NUL goto CHECKINSTALL2
goto BADDIR

:CHECKINSTALL2
if exist %ENABLE_SOURCE%\NUL goto CHECKINI
goto BADDIR

:CHECKENABLE
if exist %ENABLE_SOURCE%\NUL goto DOENABLE
goto BADDIR

:CHECKINI
if exist geos.ini goto INIEXISTS
if exist geosec.ini goto INIEXISTS
goto DOINSTALL

:INIEXISTS
if "%FORCE%"=="1" goto FORCEWARN
echo NOTICE: Existing GEOS configuration found in current SP_TOP (GEOS.INI or GEOSEC.INI).
echo NOTICE: Installation aborted. Use GESETUP INSTALL -F to force install.
goto END

:FORCEWARN
echo WARNING: Existing GEOS configuration found in current SP_TOP (GEOS.INI or GEOSEC.INI).
echo WARNING: Forced install will continue and may overwrite existing files.
echo.
echo Press CTRL+C now to cancel, or press any key to continue.
pause

:DOINSTALL
echo Installing from %INSTALL_SOURCE% to current SP_TOP ...
xcopy %INSTALL_SOURCE%\*.* .\ /S /E /Y

rem Ensure bootstrap INI is present in SP_TOP even if XCOPY omits it.
if exist %INSTALL_SOURCE%\geosec.ini copy %INSTALL_SOURCE%\geosec.ini .\
if exist %INSTALL_SOURCE%\geos.ini copy %INSTALL_SOURCE%\geos.ini .\

echo.
echo Running enable phase ...
set PHASE=INSTALL
goto DOENABLE

:DOENABLE
echo Enabling from %ENABLE_SOURCE% to current SP_TOP ...
xcopy %ENABLE_SOURCE%\*.* .\ /S /E /Y
echo.

if "%PHASE%"=="INSTALL" goto INSTALLDONE
echo Enable complete.
goto END

:INSTALLDONE
echo Install complete.
goto END

:BADDIR
echo NOTICE: GESETUP must be called from SP_TOP.
echo NOTICE: Current directory must contain FREEGEOS\60BETA\SETUP\INSTALL and ...\ENABLE.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GESETUP INSTALL
echo   FREEGEOS\60BETA\GESETUP INSTALL -F
echo   FREEGEOS\60BETA\GESETUP ENABLE
goto END

:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GESETUP INSTALL
echo   FREEGEOS\60BETA\GESETUP INSTALL -F
echo   FREEGEOS\60BETA\GESETUP ENABLE

:END
set FORCE=
set PHASE=
set SETUP_ROOT=
set INSTALL_SOURCE=
set ENABLE_SOURCE=
