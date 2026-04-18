@echo off
rem WRITEGFS.BAT
rem Generate GFSEC.INI or GFS.INI from GEOS_DIST_DIR argument.
rem bootstrapPath holds the path with the
rem GFS image (%1\BOOT). bootstrapPath is used to remove that
rem path from the standard path list once the GFS has been loaded
rem and runs.

if "%1"=="" goto NOVAR

set GFS_INI=
set BOOT_INI=

if exist geosec.ini set GFS_INI=gfsec.ini
if "%GFS_INI%"=="" if exist geos.ini set GFS_INI=gfs.ini
if "%GFS_INI%"=="" goto NOCFG

if "%GFS_INI%"=="gfsec.ini" set BOOT_INI=%1\BOOT\NETEC.INI
if "%GFS_INI%"=="gfs.ini" set BOOT_INI=%1\BOOT\NET.INI
if not exist %BOOT_INI% goto NONETCFG

:WRITEINI
if exist %GFS_INI% del %GFS_INI%

>%GFS_INI% echo [system]
>>%GFS_INI% echo fs = megafile.geo
>>%GFS_INI% echo.
>>%GFS_INI% echo [paths]
>>%GFS_INI% echo top = %1\BOOT GFS:\FG
>>%GFS_INI% echo ini = %BOOT_INI%
>>%GFS_INI% echo.
>>%GFS_INI% echo [gfs]
>>%GFS_INI% echo file = %1\BOOT\GFS.IMG
>>%GFS_INI% echo drive = GFS
>>%GFS_INI% echo bootstrapPath = %1\BOOT
>>%GFS_INI% echo cacheFile = none
>>%GFS_INI% echo.
if exist %GFS_INI% goto END
echo ERROR: Failed to generate %GFS_INI%.
goto END

:NOVAR
echo ERROR: GEOS_DIST_DIR argument is missing.
goto END

:NOCFG
echo ERROR: Neither GEOSEC.INI nor GEOS.INI exists in current directory.
goto END

:NONETCFG
echo ERROR: Missing required BOOT INI file: %BOOT_INI%

:END
set GFS_INI=
set BOOT_INI=
