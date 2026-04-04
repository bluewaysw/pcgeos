@echo off
rem WRITEGFS.BAT
rem Generate GFSEC.INI or GFS.INI from GEOS_DIST_DIR.

if "%GEOS_DIST_DIR%"=="" goto NOVAR

set BOOT_ABS=%GEOS_DIST_DIR%\BOOT
set GFS_INI_NAME=

if exist geosec.ini set GFS_INI_NAME=gfsec.ini
if "%GFS_INI_NAME%"=="" if exist geos.ini set GFS_INI_NAME=gfs.ini
if "%GFS_INI_NAME%"=="" if exist %BOOT_ABS%\NETEC.INI set GFS_INI_NAME=gfsec.ini
if "%GFS_INI_NAME%"=="" set GFS_INI_NAME=gfs.ini

set BOOT_INI=%BOOT_ABS%\NET.INI
if "%GFS_INI_NAME%"=="gfsec.ini" set BOOT_INI=%BOOT_ABS%\NETEC.INI
if exist %BOOT_INI% goto HAVEBOOTINI
if "%GFS_INI_NAME%"=="gfsec.ini" set BOOT_INI=%BOOT_ABS%\NET.INI
if "%GFS_INI_NAME%"=="gfs.ini" set BOOT_INI=%BOOT_ABS%\NETEC.INI
if exist %BOOT_INI% goto HAVEBOOTINI
set BOOT_INI=%BOOT_ABS%\NET.INI

:HAVEBOOTINI
if exist %GFS_INI_NAME% del %GFS_INI_NAME%

>%GFS_INI_NAME% echo [system]
>>%GFS_INI_NAME% echo fs = megafile.geo
>>%GFS_INI_NAME% echo.
>>%GFS_INI_NAME% echo [paths]
>>%GFS_INI_NAME% echo top = %BOOT_ABS% GFS:\FG
>>%GFS_INI_NAME% echo ini = %BOOT_INI%
>>%GFS_INI_NAME% echo.
>>%GFS_INI_NAME% echo [gfs]
>>%GFS_INI_NAME% echo file = %BOOT_ABS%\GFS.IMG
>>%GFS_INI_NAME% echo drive = GFS
>>%GFS_INI_NAME% echo ; bootstrapPath holds the path with the
>>%GFS_INI_NAME% echo ; GFS image. That path is GEOS_DIST_DIR\BOOT.
>>%GFS_INI_NAME% echo ; bootstrapPath is used to remove that path from the
>>%GFS_INI_NAME% echo ; standard path list once the GFS has been loaded and runs.
>>%GFS_INI_NAME% echo bootstrapPath = %BOOT_ABS%
>>%GFS_INI_NAME% echo cacheFile = none
>>%GFS_INI_NAME% echo.

if exist %GFS_INI_NAME% goto END

echo ERROR: Failed to generate %GFS_INI_NAME%.
goto END

:NOVAR
echo ERROR: GEOS_DIST_DIR is not set.

:END
set BOOT_ABS=
set BOOT_INI=
set GFS_INI_NAME=
