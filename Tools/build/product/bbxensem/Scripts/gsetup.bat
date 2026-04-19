@echo off
rem GSETUP.BAT
rem Install/activate from current target directory.
rem
rem Internal launcher contract:
rem   GSETUP.BAT GEOS_DIST_DIR
rem   GSETUP.BAT GEOS_DIST_DIR INSTALL
rem   GSETUP.BAT GEOS_DIST_DIR ACTIVATE
rem
rem Usage:
rem   GSETUP
rem   GSETUP INSTALL
rem   GSETUP ACTIVATE
rem
rem Behavior summary:
rem - DEFAULT (no mode parameter):
rem     no GEOS.INI/GEOSEC.INI results in install user files / folder stubs, then "activate".
rem     UPDATE.TXT present results in "activate" only (UPDATE.TXT deleted afterwards).
rem     existing INI with matching bootstrapPath in GFS.INI/GFSEC.INI results in no-op.
rem     missing/mismatched bootstrap INI results in "activate".
rem - INSTALL: always runs install plus activate after warning and confirmation.
rem - ACTIVATE: always runs "activate"; UPDATE.TXT is ignored.


if "%1"=="" goto NOENTRY

rem Keep variable footprint small for COMMAND.COM environment space limits.
set PINST=setup\install
set PACT=setup\activate
set PDM=GEOSDIR.GDM
set PDMB=GDMREAD.BAT
set GDD=

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

rem Parse default no-arg mode.
:PARSEDEFAULT
if not "%3"=="" goto USAGE
if exist %1\%PINST%\NUL goto CHECKDEFAULT2
goto BADDIR

rem Verify activate payload directory exists for default flow.
:CHECKDEFAULT2
if exist %1\%PACT%\NUL goto CHECKDEFAULTINI
goto BADDIR

rem Detect GEOS configuration in target root for default mode.
:CHECKDEFAULTINI
if exist geosec.ini goto DEFAULTEC
if exist geos.ini goto DEFAULTNC
goto DOINSTALL

rem Default path for non-EC configuration.
:DEFAULTNC
if exist update.txt goto UPDATEMARKER
if not exist gfs.ini goto DEFAULTNEEDACTIVATE
if not exist %PDM% goto DEFAULTNEEDACTIVATE
set GDD=
if exist %PDMB% del %PDMB% >NUL
copy %PDM% %PDMB% >NUL
if not exist %PDMB% goto DEFAULTNEEDACTIVATE
call %PDMB%
if exist %PDMB% del %PDMB% >NUL
if not "%GDD%"=="%1" goto DEFAULTNEEDACTIVATE
find "bootstrapPath = %1\BOOT" gfs.ini >NUL
if not errorlevel 1 goto DEFAULTDONE
goto DEFAULTNEEDACTIVATE

rem Default path for EC configuration.
:DEFAULTEC
if exist update.txt goto UPDATEMARKER
if not exist gfsec.ini goto DEFAULTNEEDACTIVATE
if not exist %PDM% goto DEFAULTNEEDACTIVATE
set GDD=
if exist %PDMB% del %PDMB% >NUL
copy %PDM% %PDMB% >NUL
if not exist %PDMB% goto DEFAULTNEEDACTIVATE
call %PDMB%
if exist %PDMB% del %PDMB% >NUL
if not "%GDD%"=="%1" goto DEFAULTNEEDACTIVATE
find "bootstrapPath = %1\BOOT" gfsec.ini >NUL
if not errorlevel 1 goto DEFAULTDONE
goto DEFAULTNEEDACTIVATE

rem Default path when bootstrap INI is missing or stale.
:DEFAULTNEEDACTIVATE
echo NOTICE: Path change or missing bootstrap INI detected. Running activate phase.
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

rem Copy setup\\activate payload and regenerate GFS bootstrap INI.
:DOACTIVATE
echo Activating from %1\%PACT% to current target directory ...
xcopy %1\%PACT%\*.* .\ /S /E /Y
echo.

echo Regenerating GFS bootstrap INI for %1 ...
call %1\writegfs.bat %1
if exist gfsec.ini goto ACTIVATEMARKER
if exist gfs.ini goto ACTIVATEMARKER
goto GFSGENFAIL

rem Run activate phase after INSTALL and clear update marker if present.
:DOACTIVATEINSTALL
echo Activating from %1\%PACT% to current target directory ...
xcopy %1\%PACT%\*.* .\ /S /E /Y
if exist update.txt del update.txt
echo.

echo Regenerating GFS bootstrap INI for %1 ...
call %1\writegfs.bat %1
if exist gfsec.ini goto INSTALLMARKER
if exist gfs.ini goto INSTALLMARKER
goto GFSGENFAIL

rem Write directory marker after successful ACTIVATE flow.
:ACTIVATEMARKER
>%PDM% echo set GDD=%1
if not exist %PDM% goto ACTIVATEMARKERWARN
set GDD=
if exist %PDMB% del %PDMB% >NUL
copy %PDM% %PDMB% >NUL
if not exist %PDMB% goto ACTIVATEMARKERWARN
call %PDMB%
if exist %PDMB% del %PDMB% >NUL
if "%GDD%"=="%1" goto ACTIVATEDONE

:ACTIVATEMARKERWARN
echo WARNING: Failed to write %PDM%. Path changes may trigger extra activate runs.
goto ACTIVATEDONE

rem Write directory marker after successful INSTALL+ACTIVATE flow.
:INSTALLMARKER
>%PDM% echo set GDD=%1
if not exist %PDM% goto INSTALLMARKERWARN
set GDD=
if exist %PDMB% del %PDMB% >NUL
copy %PDM% %PDMB% >NUL
if not exist %PDMB% goto INSTALLMARKERWARN
call %PDMB%
if exist %PDMB% del %PDMB% >NUL
if "%GDD%"=="%1" goto INSTALLDONE

:INSTALLMARKERWARN
echo WARNING: Failed to write %PDM%. Path changes may trigger extra activate runs.
goto INSTALLDONE

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
echo   FREEGEOS\60BETA\GSETUP
echo   FREEGEOS\60BETA\GSETUP INSTALL
echo   FREEGEOS\60BETA\GSETUP ACTIVATE
goto END

rem Show usage when current directory layout is invalid.
:BADDIR
echo NOTICE: GSETUP must be called from target root directory.
echo NOTICE: Current directory must contain FREEGEOS\60BETA\SETUP\INSTALL and FREEGEOS\60BETA\SETUP\ACTIVATE.
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
if exist %PDMB% del %PDMB% >NUL
set PINST=
set PACT=
set PDM=
set PDMB=
set GDD=
