@echo off
rem WRITEGFS.BAT
rem Generate GFSEC.INI or GFS.INI from GEOS_DIST_DIR argument.
rem bootstrapPath holds the path with the
rem GFS image. bootstrapPath is used to remove that path from the
rem standard path list once the GFS has been loaded and runs.
rem The generated paths are relative to the Ensemble root so that
rem moved/renamed trees can boot without regenerating this file.
rem NOTE: using WRITEGFS and WRITEGFSEC instead of variables helps
rem us to keep environmental space low for COMMAND.COM.

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
>>gfs.ini echo top = FREEGEOS\60BETA\BOOT GFS:\FG
>>gfs.ini echo ini = FREEGEOS\60BETA\BOOT\NET.INI
>>gfs.ini echo.
>>gfs.ini echo [gfs]
>>gfs.ini echo file = FREEGEOS\60BETA\BOOT\GFS.IMG
>>gfs.ini echo drive = GFS
>>gfs.ini echo bootstrapPath = FREEGEOS\60BETA\BOOT
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
>>gfsec.ini echo top = FREEGEOS\60BETA\BOOT GFS:\FG
>>gfsec.ini echo ini = FREEGEOS\60BETA\BOOT\NETEC.INI
>>gfsec.ini echo.
>>gfsec.ini echo [gfs]
>>gfsec.ini echo file = FREEGEOS\60BETA\BOOT\GFS.IMG
>>gfsec.ini echo drive = GFS
>>gfsec.ini echo bootstrapPath = FREEGEOS\60BETA\BOOT
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
