@echo off
rem GSETUP.BAT
rem Install/enable from current target directory.
rem
rem Internal launcher contract:
rem   GSETUP.BAT <GEOS_DIST_DIR> INSTALL
rem   GSETUP.BAT <GEOS_DIST_DIR> INSTALL -F
rem   GSETUP.BAT <GEOS_DIST_DIR> ENABLE
rem
rem Usage:
rem   GSETUP INSTALL
rem   GSETUP INSTALL -F
rem   GSETUP ENABLE

if "%1"=="" goto NOENTRY
if "%2"=="" goto NOENTRY

rem Keep variable footprint small for COMMAND.COM environment space limits.
set PINST=setup\install
set PENAB=setup\enable

if "%2"=="install" goto PARSEINSTALL
if "%2"=="INSTALL" goto PARSEINSTALL
if "%2"=="enable" goto PARSEENABLE
if "%2"=="ENABLE" goto PARSEENABLE
goto USAGE

:PARSEINSTALL
if "%3"=="" goto CHECKINSTALL
if "%3"=="-f" goto CHECKINSTALLFORCE
if "%3"=="-F" goto CHECKINSTALLFORCE
goto USAGE

:CHECKINSTALLFORCE
if not "%4"=="" goto USAGE
goto CHECKINSTALL2

:CHECKINSTALL
if not "%3"=="" goto USAGE

:CHECKINSTALL2
if exist %1\%PINST%\NUL goto CHECKINSTALL3
goto BADDIR

:CHECKINSTALL3
if exist %1\%PENAB%\NUL goto CHECKINI
goto BADDIR

:CHECKINI
if exist geos.ini goto INIEXISTS
if exist geosec.ini goto INIEXISTS
goto DOINSTALL

:INIEXISTS
if "%3"=="-f" goto FORCEWARN
if "%3"=="-F" goto FORCEWARN
echo NOTICE: Existing GEOS configuration found in current target directory (GEOS.INI or GEOSEC.INI).
echo NOTICE: Installation aborted. Use GSETUP INSTALL -F to force install.
goto END

:FORCEWARN
echo WARNING: Existing GEOS configuration found in current target directory (GEOS.INI or GEOSEC.INI).
echo WARNING: Forced install will continue and may overwrite existing files.
echo.
echo Press CTRL+C now to cancel, or press any key to continue.
pause

:DOINSTALL
echo Installing from %1\%PINST% to current target directory ...
xcopy %1\%PINST%\*.* .\ /S /E /Y

rem Ensure bootstrap INI is present in target directory even if XCOPY omits it.
if exist %1\%PINST%\geosec.ini copy %1\%PINST%\geosec.ini .\
if exist %1\%PINST%\geos.ini copy %1\%PINST%\geos.ini .\

echo.
echo Running enable phase ...
goto DOENABLEINSTALL

:PARSEENABLE
if not "%3"=="" goto USAGE
if exist %1\%PENAB%\NUL goto DOENABLE
goto BADDIR

:DOENABLE
echo Enabling from %1\%PENAB% to current target directory ...
xcopy %1\%PENAB%\*.* .\ /S /E /Y
echo.

echo Regenerating GFS bootstrap INI for %1 ...
call %1\writegfs.bat %1
if exist gfsec.ini goto ENABLEDONE
if exist gfs.ini goto ENABLEDONE
goto GFSGENFAIL

:DOENABLEINSTALL
echo Enabling from %1\%PENAB% to current target directory ...
xcopy %1\%PENAB%\*.* .\ /S /E /Y
echo.

echo Regenerating GFS bootstrap INI for %1 ...
call %1\writegfs.bat %1
if exist gfsec.ini goto INSTALLDONE
if exist gfs.ini goto INSTALLDONE
goto GFSGENFAIL

:ENABLEDONE
echo Enable complete.
goto END

:INSTALLDONE
echo Install complete.
goto END

:GFSGENFAIL
echo ERROR: Failed to generate GFSEC.INI or GFS.INI for current GEOS_DIST_DIR.
goto END

:NOENTRY
echo NOTICE: GSETUP.BAT is launcher-only and needs GEOS_DIST_DIR as first argument.
echo NOTICE: Use FREEGEOS\60BETA\GSETUP from the target root directory.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP INSTALL -F
echo   FREEGEOS\60BETA\GSETUP ENABLE
goto END

:BADDIR
echo NOTICE: GSETUP must be called from target root directory.
echo NOTICE: Current directory must contain FREEGEOS\60BETA\SETUP\INSTALL and FREEGEOS\60BETA\SETUP\ENABLE.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP INSTALL -F
echo   FREEGEOS\60BETA\GSETUP ENABLE
goto END

:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP INSTALL -F
echo   FREEGEOS\60BETA\GSETUP ENABLE

:END
