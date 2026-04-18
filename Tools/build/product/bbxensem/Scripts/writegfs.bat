@echo off
rem WRITEGFS.BAT
rem Generate GFSEC.INI or GFS.INI from GEOS_DIST_DIR argument.
rem bootstrapPath holds the path with the
rem GFS image (%1\BOOT). bootstrapPath is used to remove that
rem path from the standard path list once the GFS has been loaded
rem and runs.

if "%1"=="" goto NOVAR

if exist %1\BOOT\NET.INI goto WRITEGFS
if exist %1\BOOT\NETEC.INI goto WRITEGFSEC
goto NOCFG

:WRITEGFS
if exist gfs.ini del gfs.ini

>gfs.ini echo [system]
>>gfs.ini echo fs = megafile.geo
>>gfs.ini echo.
>>gfs.ini echo [paths]
>>gfs.ini echo top = %1\BOOT GFS:\FG
>>gfs.ini echo ini = %1\BOOT\NET.INI
>>gfs.ini echo.
>>gfs.ini echo [gfs]
>>gfs.ini echo file = %1\BOOT\GFS.IMG
>>gfs.ini echo drive = GFS
>>gfs.ini echo bootstrapPath = %1\BOOT
>>gfs.ini echo cacheFile = none
>>gfs.ini echo.
if exist gfs.ini goto END
echo ERROR: Failed to generate GFS.INI.
goto END

:WRITEGFSEC
if exist gfsec.ini del gfsec.ini

>gfsec.ini echo [system]
>>gfsec.ini echo fs = megafile.geo
>>gfsec.ini echo.
>>gfsec.ini echo [paths]
>>gfsec.ini echo top = %1\BOOT GFS:\FG
>>gfsec.ini echo ini = %1\BOOT\NETEC.INI
>>gfsec.ini echo.
>>gfsec.ini echo [gfs]
>>gfsec.ini echo file = %1\BOOT\GFS.IMG
>>gfsec.ini echo drive = GFS
>>gfsec.ini echo bootstrapPath = %1\BOOT
>>gfsec.ini echo cacheFile = none
>>gfsec.ini echo.
if exist gfsec.ini goto END
echo ERROR: Failed to generate GFSEC.INI.
goto END

:NOVAR
echo ERROR: GEOS_DIST_DIR argument is missing.
goto END

:NOCFG
echo ERROR: Neither NET.INI nor NETEC.INI exists in %1\BOOT.
goto END

:END
