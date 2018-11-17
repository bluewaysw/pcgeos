@echo off
cls
echo This will print out various information about your system.
echo Make sure your printer is set up and online.  
pause
echo Printing DOS version, CONFIG.SYS, AUTOEXEC.BAT, PC/GEOS version,
echo and GEOS.LOG file...
echo .
echo          DOS VERSION: > %1 prn
	ver > %1 prn
echo ________________________________________ > %1 prn
echo          LISTING OF C:\CONFIG.SYS > %1 prn
	type c:\config.sys > %1 prn
echo ________________________________________ > %1 prn
echo          LISTING OF C:\AUTOEXEC.BAT > %1 prn
	type c:\autoexec.bat > %1 prn
echo ________________________________________ > %1 prn
echo          PC/GEOS VERSION > %1 prn
	type version.txt > %1 prn
echo ________________________________________ > %1 prn
echo          GEOS.LOG FILE > %1 prn
	type privdata\geos.log > %1 prn
echo ________________________________________ > %1 prn
if not exist sysinfo goto INI
	echo .
	echo Press enter to print SYSINFO. To cancel, press Ctrl-c.
	echo The SYSINFO file can be useful for troubleshooting.
	echo It may require 4 to 6 pages to print.
	echo .
	pause
	echo          PC/GEOS SYSINFO FILE > %1 prn
	type sysinfo > %1 prn
	goto END
:INI
	echo          (no SYSINFO file found) > %1 prn
	if not exist geos.ini goto NOINI
	echo .
	echo Press enter to print GEOS.INI. To cancel, press Ctrl-c.
	echo The GEOS.INI file can be useful for troubleshooting
	echo It may require 2 to 3 pages to print.
	echo .
	pause
	echo          GEOS.INI FILE > %1 prn
	type geos.ini > %1 prn
	goto END
:NOINI
	echo          (no GEOS.INI file found) > %1 prn
:END
