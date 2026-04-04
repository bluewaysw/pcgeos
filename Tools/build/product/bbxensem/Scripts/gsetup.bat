@echo off
rem GSETUP.BAT
rem Install/enable from current target directory.
rem
rem Usage:
rem   GSETUP INSTALL
rem   GSETUP INSTALL -F
rem   GSETUP ENABLE

set FORCE=
set PHASE=
set SETUP_ROOT=
set INSTALL_SOURCE=
set ENABLE_SOURCE=
set GFS_CWD_TOOL=
set GFS_WRITER=
set GFS_ENVBAT=_gcwdset.bat
set GEOS_DIST_DIR=
set NEXT_LABEL=

if "%1"=="" goto USAGE
if "%1"=="install" goto PARSEINSTALL
if "%1"=="INSTALL" goto PARSEINSTALL
if "%1"=="enable" goto PARSEENABLE
if "%1"=="ENABLE" goto PARSEENABLE
goto USAGE

:PARSEINSTALL
if "%2"=="" goto PREPCHECKINSTALL
if "%2"=="-f" goto FORCEINSTALL
if "%2"=="-F" goto FORCEINSTALL
goto USAGE

:FORCEINSTALL
if not "%3"=="" goto USAGE
set FORCE=1
goto PREPCHECKINSTALL

:PARSEENABLE
if not "%2"=="" goto USAGE
goto PREPCHECKENABLE

:PREPCHECKINSTALL
set NEXT_LABEL=CHECKINSTALL
goto RESOLVEPATHS

:PREPCHECKENABLE
set NEXT_LABEL=CHECKENABLE
goto RESOLVEPATHS

:RESOLVEPATHS
if exist %GFS_ENVBAT% del %GFS_ENVBAT%

if not "%GFS_CWD_TOOL%"=="" goto HAVECWDTOOL
if exist getcwd.com set GFS_CWD_TOOL=getcwd.com
if not "%GFS_CWD_TOOL%"=="" goto HAVECWDTOOL
if exist .\getcwd.com set GFS_CWD_TOOL=.\getcwd.com
if not "%GFS_CWD_TOOL%"=="" goto HAVECWDTOOL
if exist freegeos\60beta\getcwd.com set GFS_CWD_TOOL=freegeos\60beta\getcwd.com
if not "%GFS_CWD_TOOL%"=="" goto HAVECWDTOOL
if exist \freegeos\60beta\getcwd.com set GFS_CWD_TOOL=\freegeos\60beta\getcwd.com
if "%GFS_CWD_TOOL%"=="" goto BADDIR

:HAVECWDTOOL
%GFS_CWD_TOOL% %0 %GFS_ENVBAT%
if errorlevel 1 goto BADDIR
if not exist %GFS_ENVBAT% goto BADDIR

call %GFS_ENVBAT%
if exist %GFS_ENVBAT% del %GFS_ENVBAT%
if "%GEOS_DIST_DIR%"=="" goto BADDIR

set SETUP_ROOT=%GEOS_DIST_DIR%\setup
set INSTALL_SOURCE=%SETUP_ROOT%\install
set ENABLE_SOURCE=%SETUP_ROOT%\enable
set GFS_CWD_TOOL=%GEOS_DIST_DIR%\getcwd.com
set GFS_WRITER=%GEOS_DIST_DIR%\writegfs.bat

goto %NEXT_LABEL%

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
echo Installing from %INSTALL_SOURCE% to current target directory ...
xcopy %INSTALL_SOURCE%\*.* .\ /S /E /Y

rem Ensure bootstrap INI is present in target directory even if XCOPY omits it.
if exist %INSTALL_SOURCE%\geosec.ini copy %INSTALL_SOURCE%\geosec.ini .\
if exist %INSTALL_SOURCE%\geos.ini copy %INSTALL_SOURCE%\geos.ini .\

echo.
echo Running enable phase ...
set PHASE=INSTALL
goto DOENABLE

:DOENABLE
echo Enabling from %ENABLE_SOURCE% to current target directory ...
xcopy %ENABLE_SOURCE%\*.* .\ /S /E /Y
echo.

echo Regenerating GFSEC.INI for %GEOS_DIST_DIR% ...
call %GFS_WRITER%
if not exist gfsec.ini goto GFSGENFAIL

set GEOS_DIST_DIR=

if "%PHASE%"=="INSTALL" goto INSTALLDONE
echo Enable complete.
goto END

:INSTALLDONE
echo Install complete.
goto END

:GFSGENFAIL
echo ERROR: Failed to generate GFSEC.INI for current GEOS_DIST_DIR.
if exist %GFS_ENVBAT% del %GFS_ENVBAT%
set GEOS_DIST_DIR=
set SETUP_ROOT=
set INSTALL_SOURCE=
set ENABLE_SOURCE=
set GFS_WRITER=
goto END

:BADDIR
echo NOTICE: GSETUP must be called from target root directory.
echo NOTICE: Current directory must contain FREEGEOS\60BETA\SETUP\INSTALL and ...\ENABLE.
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
set FORCE=
set PHASE=
set SETUP_ROOT=
set INSTALL_SOURCE=
set ENABLE_SOURCE=
set GFS_CWD_TOOL=
set GFS_WRITER=
set GFS_ENVBAT=
set GEOS_DIST_DIR=
set NEXT_LABEL=
