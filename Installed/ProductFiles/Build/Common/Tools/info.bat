@echo off
rem This program is for your use when calling technical support.
cls
echo ________________________________________ 
echo          PC/GEOS VERSION 
	type version.txt 
pause   
echo ________________________________________ 
echo          DOS VERSION: 
	ver 
pause
echo ________________________________________ 
echo          LISTING OF C:\CONFIG.SYS 
	type c:\config.sys | more
pause
echo ________________________________________ 
echo          LISTING OF C:\AUTOEXEC.BAT 
	type c:\autoexec.bat | more
pause
echo ________________________________________ 
echo          GEOS.LOG FILE
		
	type privdata\geos.log | more

