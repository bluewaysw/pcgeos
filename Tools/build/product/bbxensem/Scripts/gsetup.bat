@echo off
rem GSETUP.BAT
rem Install/activate from current target directory.
rem
rem Internal launcher contract:
rem   GSETUP.BAT <GEOS_DIST_DIR> INSTALL
rem   GSETUP.BAT <GEOS_DIST_DIR> INSTALL -F
rem   GSETUP.BAT <GEOS_DIST_DIR> ACTIVATE
rem
rem Usage:
rem   GSETUP INSTALL
rem   GSETUP INSTALL -F
rem   GSETUP ACTIVATE

if "%1"=="" goto NOENTRY
if "%2"=="" goto NOENTRY

rem Keep variable footprint small for COMMAND.COM environment space limits.
set PINST=setup\install
set PACT=setup\activate

if "%2"=="install" goto PARSEINSTALL
if "%2"=="INSTALL" goto PARSEINSTALL
if "%2"=="activate" goto PARSEACTIVATE
if "%2"=="ACTIVATE" goto PARSEACTIVATE
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
if exist %1\%PACT%\NUL goto CHECKINI
goto BADDIR

:CHECKINI
if exist geos.ini goto INIEXISTS
if exist geosec.ini goto INIEXISTS
goto DOINSTALL

:INIEXISTS
if exist update.txt goto UPDATEMARKER
if "%3"=="-f" goto FORCEWARN
if "%3"=="-F" goto FORCEWARN
echo NOTICE: Existing GEOS configuration found in current target directory (GEOS.INI or GEOSEC.INI).
echo NOTICE: Installation aborted. Use GSETUP INSTALL -F to force install.
goto END

:UPDATEMARKER
echo NOTICE: Update marker found (UPDATE.TXT). Running activate phase only.
if exist update.txt del update.txt
goto DOACTIVATE

:FORCEWARN
echo WARNING: Existing GEOS configuration found in current target directory (GEOS.INI or GEOSEC.INI).
echo WARNING: Forced install will continue and may overwrite existing files.
echo.
echo Press CTRL+C now to cancel, or press any key to continue.
pause

:DOINSTALL
echo Installing from %1\%PINST% to current target directory ...
subst k: %1\%PINST%\
xcopy k:*.* .\ /S /E /Y
subst k: /D

echo.
echo Running activate phase ...
goto DOACTIVATEINSTALL

:PARSEACTIVATE
if not "%3"=="" goto USAGE
if exist %1\%PACT%\NUL goto DOACTIVATE
goto BADDIR

:DOACTIVATE
echo Activating from %1\%PACT% to current target directory ...
xcopy %1\%PACT%\*.* .\ /S /E /Y
echo.

echo Regenerating GFS bootstrap INI for %1 ...
call %1\writegfs.bat %1
if exist gfsec.ini goto ACTIVATEDONE
if exist gfs.ini goto ACTIVATEDONE
goto GFSGENFAIL

:DOACTIVATEINSTALL
echo Activating from %1\%PACT% to current target directory ...
xcopy %1\%PACT%\*.* .\ /S /E /Y
echo.

echo Regenerating GFS bootstrap INI for %1 ...
call %1\writegfs.bat %1
if exist gfsec.ini goto INSTALLDONE
if exist gfs.ini goto INSTALLDONE
goto GFSGENFAIL

:ACTIVATEDONE
echo Activate complete.
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
echo   FREEGEOS\60BETA\GSETUP ACTIVATE
goto END

:BADDIR
echo NOTICE: GSETUP must be called from target root directory.
echo NOTICE: Current directory must contain FREEGEOS\60BETA\SETUP\INSTALL and FREEGEOS\60BETA\SETUP\ACTIVATE.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP INSTALL -F
echo   FREEGEOS\60BETA\GSETUP ACTIVATE
goto END

:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP INSTALL -F
echo   FREEGEOS\60BETA\GSETUP ACTIVATE

:END
