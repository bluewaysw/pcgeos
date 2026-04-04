@echo off
rem WRITEGFS.BAT
rem Generate GFSEC.INI from GEOS_DIST_DIR.

if "%GEOS_DIST_DIR%"=="" goto NOVAR

set BOOT_ABS=%GEOS_DIST_DIR%\BOOT
set BOOT_INI=%BOOT_ABS%\NETEC.INI

if not exist %BOOT_INI% set BOOT_INI=%BOOT_ABS%\NET.INI

if exist gfsec.ini del gfsec.ini

>gfsec.ini echo [system]
>>gfsec.ini echo fs = megafile.geo
>>gfsec.ini echo.
>>gfsec.ini echo [paths]
>>gfsec.ini echo top = %BOOT_ABS% GFS:\FG
>>gfsec.ini echo ini = %BOOT_INI%
>>gfsec.ini echo.
>>gfsec.ini echo [gfs]
>>gfsec.ini echo file = %BOOT_ABS%\GFS.IMG
>>gfsec.ini echo drive = GFS
>>gfsec.ini echo ; bootstrapPath holds the path with the
>>gfsec.ini echo ; GFS image. That path is GEOS_DIST_DIR\BOOT.
>>gfsec.ini echo ; bootstrapPath is used to remove that path from the
>>gfsec.ini echo ; standard path list once the GFS has been loaded and runs.
>>gfsec.ini echo bootstrapPath = %BOOT_ABS%
>>gfsec.ini echo cacheFile = none
>>gfsec.ini echo.

if exist gfsec.ini goto END

echo ERROR: Failed to generate GFSEC.INI.
goto END

:NOVAR
echo ERROR: GEOS_DIST_DIR is not set.

:END
set BOOT_ABS=
set BOOT_INI=
