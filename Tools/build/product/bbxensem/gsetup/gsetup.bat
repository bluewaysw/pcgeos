@echo off
rem GSETUP.BAT
rem called by gsetup.exe: distribution directory, free drive, user mode
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
set GI=
set GM=
set GS=

if "%3"=="" goto PARSEDEFAULT
if "%3"=="install" goto PARSEINSTALL
if "%3"=="INSTALL" goto PARSEINSTALL
if "%3"=="activate" goto PARSEACTIVATE
if "%3"=="ACTIVATE" goto PARSEACTIVATE
goto USAGE

rem Parse INSTALL arguments.
:PARSEINSTALL
if not "%4"=="" goto USAGE
if exist %1\ginst.bat goto CHECKINSTALL2
goto BADDIR

rem Verify activate payload directory exists for INSTALL flow.
:CHECKINSTALL2
if exist %1\setup\activate\gfs.ini goto INSTALLCONFIRM
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
if not "%4"=="" goto USAGE
if exist %1\ginst.bat goto CHECKDEFAULT2
goto BADDIR

rem Verify activate payload directory exists.
:CHECKDEFAULT2
if exist %1\setup\activate\gfs.ini goto CHECKDEFAULTINI
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
if not "%4"=="" goto USAGE
if exist %1\setup\activate\gfs.ini goto DOACTIVATE
goto BADDIR

rem Update marker forces activate-only and is then cleared.
:UPDATEMARKER
echo NOTICE: Update marker found (UPDATE.TXT). Running activate phase only.
goto DOACTIVATE

rem Select the shared copy flow after argument and payload checks.
:DOINSTALL
set GI=1
if not "%GI%"=="1" goto ENVFAIL

:DOACTIVATE
if "%2"=="-" goto MAPFAIL
if "%2"=="" goto NOENTRY
if not exist %1\gsetup.exe goto BADDIR
if not exist %1\gact.bat goto BADDIR

rem Reserve these small variables before creating a mapping.
set GS=0
set GM=E
if not "%GS%"=="0" goto ENVFAIL
if not "%GM%"=="E" goto ENVFAIL

rem A file check cannot detect an empty drive or a drive without media.
%1\gsetup.exe /CHECKDRIVE %2
if errorlevel 1 goto BUSY
emudrv %2 %1\
goto VERIFY

:TRYSUB
set GM=S
if not "%GM%"=="S" goto ENVFAIL
subst %2 %1\
goto VERIFY

:TRYSW
set GM=W
if not "%GM%"=="W" goto ENVFAIL
swsubst %2 %1\

rem Test real source files. Mapper exit codes differ between DOS versions.
:VERIFY
if not exist %2\gact.bat goto BADMAP
if not exist %2\setup\activate\gfs.ini goto BADMAP
if not "%GI%"=="1" goto MAPPED
if not exist %2\ginst.bat goto BADMAP

:MAPPED
set GS=1
if not "%GS%"=="1" goto BADMAP
if not "%GI%"=="1" goto COPYACT

echo Installing from %1\setup\install to current target directory ...
call %2\ginst.bat %2
echo.

:COPYACT
echo Activating from %1\setup\activate to current target directory ...
call %2\gact.bat %2
goto UNMAP

rem Remove a failed mapping before trying another command.
:BADMAP
%1\gsetup.exe /CHECKDRIVE %2
if errorlevel 2 goto CLEANERR
if not errorlevel 1 goto NEXTMAP

:UNMAP
if "%GM%"=="E" emudrv -d %2
if "%GM%"=="S" subst %2 /D
if "%GM%"=="W" swsubst %2 /D
%1\gsetup.exe /CHECKDRIVE %2
if errorlevel 1 goto CLEANERR

:NEXTMAP
if "%GS%"=="1" goto FINISH
if "%GM%"=="E" goto TRYSUB
if "%GM%"=="S" goto TRYSW
goto MAPFAIL

:FINISH
echo.
if not exist gfs.ini goto GFSINIFAIL
rem Explicit ACTIVATE leaves the update marker unchanged.
if "%GI%"=="1" goto CLEARMK
if not "%3"=="" goto ACTIVATEDONE

:CLEARMK
if exist update.txt del update.txt
if "%GI%"=="1" goto INSTALLDONE

:ACTIVATEDONE
echo Activate complete.
goto END

:INSTALLDONE
echo Install complete.
goto END

:GFSINIFAIL
echo ERROR: Activate payload did not provide GFS.INI.
goto END

:BUSY
echo ERROR: Setup drive %2 is occupied or cannot be checked.
goto END

:MAPFAIL
echo ERROR: Cannot map a free setup drive. Check EMUDRV, SUBST or SWSUBST.
echo ERROR: DOS must have a free drive letter within its LASTDRIVE limit.
goto END

:CLEANERR
echo ERROR: Cannot confirm removal of setup drive %2. Setup stopped.
goto END

:ENVFAIL
echo ERROR: Not enough DOS environment space for setup.
goto END

rem Show launcher-only usage when GEOS_DIST_DIR is missing.
:NOENTRY
echo NOTICE: GSETUP.BAT needs GEOS_DIST_DIR as first argument.
echo NOTICE: Use GSETUP from the target root directory (usually "Ensemble").
echo.
echo Usage:
echo   FREEGEOS\600\GSETUP
echo   FREEGEOS\600\GSETUP INSTALL
echo   FREEGEOS\600\GSETUP ACTIVATE
goto END

rem Show usage when current directory layout is invalid.
:BADDIR
echo NOTICE: GSETUP must be called from target root directory (usually "Ensemble").
echo.
echo Usage:
echo   FREEGEOS\600\GSETUP
echo   FREEGEOS\600\GSETUP INSTALL
echo   FREEGEOS\600\GSETUP ACTIVATE
goto END

rem Show usage for invalid argument combinations.
:USAGE
echo NOTICE: Invalid arguments.
echo.
echo Usage:
echo   FREEGEOS\600\GSETUP
echo   FREEGEOS\600\GSETUP INSTALL
echo   FREEGEOS\600\GSETUP ACTIVATE

rem Shared script exit label.
:END
set GI=
set GM=
set GS=
