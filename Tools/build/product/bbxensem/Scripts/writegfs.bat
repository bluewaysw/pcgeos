@echo off
rem WRITEGFS.BAT
rem Generate GFSEC.INI or GFS.INI from GEOS_DIST_DIR argument.

if "%1"=="" goto NOVAR

if exist geosec.ini goto MAKEGFSEC
if exist geos.ini goto MAKEGFS
if exist %1\BOOT\NETEC.INI goto MAKEGFSEC
goto MAKEGFS

:MAKEGFSEC
if exist gfsec.ini del gfsec.ini
if exist %1\BOOT\NETEC.INI goto GFSECNETEC
if exist %1\BOOT\NET.INI goto GFSECNET
goto GFSECNET

:GFSECNETEC
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
>>gfsec.ini echo ; bootstrapPath holds the path with the
>>gfsec.ini echo ; GFS image. That path is GEOS_DIST_DIR\BOOT.
>>gfsec.ini echo ; bootstrapPath is used to remove that path from the
>>gfsec.ini echo ; standard path list once the GFS has been loaded and runs.
>>gfsec.ini echo bootstrapPath = %1\BOOT
>>gfsec.ini echo cacheFile = none
>>gfsec.ini echo.
if exist gfsec.ini goto END
echo ERROR: Failed to generate GFSEC.INI.
goto END

:GFSECNET
>gfsec.ini echo [system]
>>gfsec.ini echo fs = megafile.geo
>>gfsec.ini echo.
>>gfsec.ini echo [paths]
>>gfsec.ini echo top = %1\BOOT GFS:\FG
>>gfsec.ini echo ini = %1\BOOT\NET.INI
>>gfsec.ini echo.
>>gfsec.ini echo [gfs]
>>gfsec.ini echo file = %1\BOOT\GFS.IMG
>>gfsec.ini echo drive = GFS
>>gfsec.ini echo ; bootstrapPath holds the path with the
>>gfsec.ini echo ; GFS image. That path is GEOS_DIST_DIR\BOOT.
>>gfsec.ini echo ; bootstrapPath is used to remove that path from the
>>gfsec.ini echo ; standard path list once the GFS has been loaded and runs.
>>gfsec.ini echo bootstrapPath = %1\BOOT
>>gfsec.ini echo cacheFile = none
>>gfsec.ini echo.
if exist gfsec.ini goto END
echo ERROR: Failed to generate GFSEC.INI.
goto END

:MAKEGFS
if exist gfs.ini del gfs.ini
if exist %1\BOOT\NET.INI goto GFSNET
if exist %1\BOOT\NETEC.INI goto GFSNETEC
goto GFSNET

:GFSNET
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
>>gfs.ini echo ; bootstrapPath holds the path with the
>>gfs.ini echo ; GFS image. That path is GEOS_DIST_DIR\BOOT.
>>gfs.ini echo ; bootstrapPath is used to remove that path from the
>>gfs.ini echo ; standard path list once the GFS has been loaded and runs.
>>gfs.ini echo bootstrapPath = %1\BOOT
>>gfs.ini echo cacheFile = none
>>gfs.ini echo.
if exist gfs.ini goto END
echo ERROR: Failed to generate GFS.INI.
goto END

:GFSNETEC
>gfs.ini echo [system]
>>gfs.ini echo fs = megafile.geo
>>gfs.ini echo.
>>gfs.ini echo [paths]
>>gfs.ini echo top = %1\BOOT GFS:\FG
>>gfs.ini echo ini = %1\BOOT\NETEC.INI
>>gfs.ini echo.
>>gfs.ini echo [gfs]
>>gfs.ini echo file = %1\BOOT\GFS.IMG
>>gfs.ini echo drive = GFS
>>gfs.ini echo ; bootstrapPath holds the path with the
>>gfs.ini echo ; GFS image. That path is GEOS_DIST_DIR\BOOT.
>>gfs.ini echo ; bootstrapPath is used to remove that path from the
>>gfs.ini echo ; standard path list once the GFS has been loaded and runs.
>>gfs.ini echo bootstrapPath = %1\BOOT
>>gfs.ini echo cacheFile = none
>>gfs.ini echo.
if exist gfs.ini goto END
echo ERROR: Failed to generate GFS.INI.
goto END

:NOVAR
echo ERROR: GEOS_DIST_DIR argument is missing.

:END
