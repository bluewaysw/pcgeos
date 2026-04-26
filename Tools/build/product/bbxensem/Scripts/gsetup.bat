@echo off
rem GSETUP.BAT
rem Install/activate a (new) GEOS version from the target directory.
rem So it is usually something like this, standing in C:\ENSEMBLE:
rem    freegeos\60\gsetup
rem    freegeos\60\gsetup install
rem    freegeos\60\gsetup activate
rem Behavior summary:
rem - DEFAULT (no mode parameter):
rem     if no GEOS.INI/GEOSEC.INI exists, "install" user files / folder stubs, then "activate".
rem     if an UPDATE.TXT is present, run "activate" only (UPDATE.TXT deleted afterwards).
rem     if a GEOS.INI/GEOSEC.INI exists, along with a GFS.INI, does nothing.
rem - INSTALL: always runs "install" plus "activate" after warning and confirmation.
rem - ACTIVATE: "activate"s the version for which it is called; UPDATE.TXT is ignored.
rem - GFS.INI uses paths relative to the Ensemble root, so moving or
rem   renaming the Ensemble folder does not require rerunning setup.


if "%1"=="" goto NOENTRY

rem Keep variable footprint small for COMMAND.COM environment space limits.
set PINST=setup\install
set PACT=setup\activate

if "%2"=="" goto PARSEDEFAULT
if "%2"=="install" goto PARSEINSTALL
if "%2"=="INSTALL" goto PARSEINSTALL
if "%2"=="activate" goto PARSEACTIVATE
if "%2"=="ACTIVATE" goto PARSEACTIVATE
goto USAGE

rem Parse INSTALL arguments.
:PARSEINSTALL
if not "%3"=="" goto USAGE
if exist %1\%PINST%\NUL goto CHECKINSTALL2
goto BADDIR

rem Verify activate payload directory exists for INSTALL flow.
:CHECKINSTALL2
if exist %1\%PACT%\NUL goto INSTALLCONFIRM
goto BADDIR

rem Confirm explicit forced INSTALL before continuing.
:INSTALLCONFIRM
echo WARNING: Explicit install requested.
echo WARNING: Install will overwrite existing files in the current target directory.
echo.
echo Press CTRL+C now to cancel, or press any key to continue.
pause
goto DOINSTALL

rem Parse default mode.
:PARSEDEFAULT
if not "%3"=="" goto USAGE
if exist %1\%PINST%\NUL goto CHECKDEFAULT2
goto BADDIR

rem Verify activate payload directory exists.
:CHECKDEFAULT2
if exist %1\%PACT%\NUL goto CHECKDEFAULTINI
goto BADDIR

rem Detect GEOS configuration in target root.
:CHECKDEFAULTINI
if exist geosec.ini goto DEFAULTCHECK
if exist geos.ini goto DEFAULTCHECK
goto DOINSTALL

rem Shared default path.
:DEFAULTCHECK
if exist update.txt goto UPDATEMARKER
if not exist gfs.ini goto DEFAULTNEEDACTIVATE
goto DEFAULTDONE

rem Default path when bootstrap INI is missing or stale.
:DEFAULTNEEDACTIVATE
echo NOTICE: Missing bootstrap INI detected. Running activate phase.
goto DOACTIVATE

rem Default path when no work is needed.
:DEFAULTDONE
echo Startup check complete.
goto END

rem Parse ACTIVATE arguments.
:PARSEACTIVATE
if not "%3"=="" goto USAGE
if exist %1\%PACT%\NUL goto DOACTIVATE
goto BADDIR

rem Update marker forces activate-only and is then cleared.
:UPDATEMARKER
echo NOTICE: Update marker found (UPDATE.TXT). Running activate phase only.
if exist update.txt del update.txt
goto DOACTIVATE

rem Copy setup\\install payload into current target root.
:DOINSTALL
echo Installing from %1\%PINST% to current target directory ...
subst k: %1\%PINST%\
xcopy k:*.* .\ /S /E /Y
subst k: /D

echo.
echo Running activate phase ...
goto DOACTIVATEINSTALL

rem Copy setup\\activate payload. The payload provides GFS.INI.
:DOACTIVATE
echo Activating from %1\%PACT% to current target directory ...
xcopy %1\%PACT%\*.* .\ /S /E /Y
echo.

if exist gfs.ini goto ACTIVATEDONE
goto GFSINIFAIL

rem Run activate phase after INSTALL and clear update marker if present.
:DOACTIVATEINSTALL
echo Activating from %1\%PACT% to current target directory ...
xcopy %1\%PACT%\*.* .\ /S /E /Y
if exist update.txt del update.txt
echo.

if exist gfs.ini goto INSTALLDONE
goto GFSINIFAIL

rem Finish pure ACTIVATE flow.
:ACTIVATEDONE
echo Activate complete.
goto END

rem Finish combined INSTALL plus activate flow.
:INSTALLDONE
echo Install complete.
goto END

rem Abort when activate payload did not provide GFS.INI.
:GFSINIFAIL
echo ERROR: Activate payload did not provide GFS.INI.
goto END

rem Show launcher-only usage when GEOS_DIST_DIR is missing.
:NOENTRY
echo NOTICE: GSETUP.BAT needs GEOS_DIST_DIR as first argument.
echo NOTICE: Use GSETUP from the target root directory (usually "Ensemble").
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP ACTIVATE
goto END

rem Show usage when current directory layout is invalid.
:BADDIR
echo NOTICE: GSETUP must be called from target root directory (usually "Ensemble").
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP ACTIVATE
goto END

rem Show usage for invalid argument combinations.
:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   FREEGEOS\60BETA\GSETUP
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP ACTIVATE

rem Shared script exit label.
:END
set PINST=
set PACT=
