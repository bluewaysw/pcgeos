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
rem
rem Behavior summary:
rem - INSTALL:
rem     no GEOS.INI/GEOSEC.INI results in install user files / folder stubs, then "activate".
rem     existing INI and UPDATE.TXT results in "activate" only (UPDATE.TXT deleted afterwards).
rem     existing INI and no UPDATE.TXT results in abort, unless -F.
rem - ACTIVATE: always runs "activate"; UPDATE.TXT is ignored.


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

rem Parse INSTALL arguments and optional -F flag.
:PARSEINSTALL
if "%3"=="" goto CHECKINSTALL
if "%3"=="-f" goto CHECKINSTALLFORCE
if "%3"=="-F" goto CHECKINSTALLFORCE
goto USAGE

rem Validate forced INSTALL argument count.
:CHECKINSTALLFORCE
if not "%4"=="" goto USAGE
goto CHECKINSTALL2

rem Validate non-forced INSTALL argument count.
:CHECKINSTALL
if not "%3"=="" goto USAGE

rem Verify install payload directory exists.
:CHECKINSTALL2
if exist %1\%PINST%\NUL goto CHECKINSTALL3
goto BADDIR

rem Verify activate payload directory exists.
:CHECKINSTALL3
if exist %1\%PACT%\NUL goto CHECKINI
goto BADDIR

rem Detect existing GEOS configuration in target root.
:CHECKINI
if exist geos.ini goto INIEXISTS
if exist geosec.ini goto INIEXISTS
goto DOINSTALL

rem Handle pre-existing configuration for INSTALL mode.
:INIEXISTS
if exist update.txt goto UPDATEMARKER
if "%3"=="-f" goto FORCEWARN
if "%3"=="-F" goto FORCEWARN
echo NOTICE: Existing GEOS configuration found in current target directory (GEOS.INI or GEOSEC.INI).
echo NOTICE: Installation aborted. Use GSETUP INSTALL -F to force install.
goto END

rem Update marker forces activate-only and is then cleared.
:UPDATEMARKER
echo NOTICE: Update marker found (UPDATE.TXT). Running activate phase only.
if exist update.txt del update.txt
goto DOACTIVATE

rem Warn before forced INSTALL over existing configuration.
:FORCEWARN
echo WARNING: Existing GEOS configuration found in current target directory (GEOS.INI or GEOSEC.INI).
echo WARNING: Forced install will continue and may overwrite existing files.
echo.
echo Press CTRL+C now to cancel, or press any key to continue.
pause

rem Copy setup\\install payload into current target root.
:DOINSTALL
echo Installing from %1\%PINST% to current target directory ...
subst k: %1\%PINST%\
xcopy k:*.* .\ /S /E /Y
subst k: /D

echo.
echo Running activate phase ...
goto DOACTIVATEINSTALL

rem Parse ACTIVATE arguments.
:PARSEACTIVATE
if not "%3"=="" goto USAGE
if exist %1\%PACT%\NUL goto DOACTIVATE
goto BADDIR

rem Copy setup\\activate payload and regenerate GFS bootstrap INI.
:DOACTIVATE
echo Activating from %1\%PACT% to current target directory ...
xcopy %1\%PACT%\*.* .\ /S /E /Y
echo.

echo Regenerating GFS bootstrap INI for %1 ...
call %1\writegfs.bat %1
if exist gfsec.ini goto ACTIVATEDONE
if exist gfs.ini goto ACTIVATEDONE
goto GFSGENFAIL

rem Run activate phase after INSTALL and clear update marker if present.
:DOACTIVATEINSTALL
echo Activating from %1\%PACT% to current target directory ...
xcopy %1\%PACT%\*.* .\ /S /E /Y
if exist update.txt del update.txt
echo.

echo Regenerating GFS bootstrap INI for %1 ...
call %1\writegfs.bat %1
if exist gfsec.ini goto INSTALLDONE
if exist gfs.ini goto INSTALLDONE
goto GFSGENFAIL

rem Finish pure ACTIVATE flow.
:ACTIVATEDONE
echo Activate complete.
goto END

rem Finish combined INSTALL plus activate flow.
:INSTALLDONE
echo Install complete.
goto END

rem Abort when GFS bootstrap INI generation fails.
:GFSGENFAIL
echo ERROR: Failed to generate GFSEC.INI or GFS.INI for current GEOS_DIST_DIR.
goto END

rem Show launcher-only usage when GEOS_DIST_DIR is missing.
:NOENTRY
echo NOTICE: GSETUP.BAT is launcher-only and needs GEOS_DIST_DIR as first argument.
echo NOTICE: Use FREEGEOS\60BETA\GSETUP from the target root directory.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP INSTALL -F
echo   FREEGEOS\60BETA\GSETUP ACTIVATE
goto END

rem Show usage when current directory layout is invalid.
:BADDIR
echo NOTICE: GSETUP must be called from target root directory.
echo NOTICE: Current directory must contain FREEGEOS\60BETA\SETUP\INSTALL and FREEGEOS\60BETA\SETUP\ACTIVATE.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP INSTALL -F
echo   FREEGEOS\60BETA\GSETUP ACTIVATE
goto END

rem Show usage for invalid argument combinations.
:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP INSTALL -F
echo   FREEGEOS\60BETA\GSETUP ACTIVATE

rem Shared script exit label.
:END
