@echo off
cls
echo This program will return your CONFIG.SYS and AUTOEXEC.BAT
echo files to their state just before you installed PC/GEOS.
echo (Press Ctrl-c to abort)
pause
copy system\config.old c:\config.sys
copy system\autoexec.old c:\autoexec.bat
