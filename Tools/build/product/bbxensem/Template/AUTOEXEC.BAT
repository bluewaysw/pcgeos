@echo off

path c:\dos;c:\bin
set BLASTER=A220 I5 D1 T4

if not exist c:\globalpc\geos_act.ive goto bootGeos

if not exist d:\temp\nul md d:\temp

REM First store the names of files that are corrupted, if any.
cls
echo             ********************************************************
echo             * The computer was not shutdown properly.  The system  *
echo             * is now checking for any errors.                      *
echo             *                                                      *
echo             * One moment please ......                             *
echo             ********************************************************
c:\dos\chkdsk /c /f > d:\temp\chkdsk.out
REM Can't check ERRORLEVEL here, because CHKDSK doesn't return correct error
REM code for some errors.

REM Get the current system version.  Default is GEOS2000.
set geosver=GEOS2000
if exist c:\globalpc\version.bat call c:\globalpc\version.bat

REM Scan the output file to see if any GEOS system files were corrupted.  If
REM so, copy them from the backup on D:.
c:\dos\find "C:\%geosver%\PRIVDATA" d:\temp\chkdsk.out > nul
if errorlevel 1 goto afterPrivdata
cls
echo             ********************************************************
echo             * An error has been found, the system will now         *
echo             * attempt to correct it.                               *
echo             *                                                      *
echo             * One moment please ......                             *
echo             ********************************************************
set errMsgPrinted=yes
c:\dos\deltree /y c:\%geosver%\privdata > nul
c:\dos\xcopy /e d:\%geosver%\privdata c:\%geosver%\privdata\ > nul
:afterPrivdata

c:\dos\find "C:\%geosver%\SYSTEM" d:\temp\chkdsk.out > nul
if errorlevel 1 goto afterSystem
if %errMsgPrinted%==yes goto rdSystem
cls
echo             ********************************************************
echo             * An error has been found, the system will now         *
echo             * attempt to correct it.                               *
echo             *                                                      *
echo             * One moment please ......                             *
echo             ********************************************************
set errMsgPrinted=yes
:rdSystem
c:\dos\deltree /y c:\%geosver%\system > nul
c:\dos\xcopy /e d:\%geosver%\system c:\%geosver%\system\ > nul
:afterSystem

c:\dos\find "C:\%geosver%\USERDATA" d:\temp\chkdsk.out > nul
if errorlevel 1 goto afterUserdata
if %errMsgPrinted%==yes goto rdUserdata
cls
echo             ********************************************************
echo             * An error has been found, the system will now         *
echo             * attempt to correct it.                               *
echo             *                                                      *
echo             * One moment please ......                             *
echo             ********************************************************
set errMsgPrinted=yes
:rdUserData
c:\dos\deltree /y c:\%geosver%\userdata > nul
c:\dos\xcopy /e d:\%geosver%\userdata c:\%geosver%\userdata\ > nul
:afterUserData

c:\dos\find "C:\%geosver%\WORLD" d:\temp\chkdsk.out > nul
if errorlevel 1 goto afterWorld
if %errMsgPrinted%==yes goto rdWorld
cls
echo             ********************************************************
echo             * An error has been found, the system will now         *
echo             * attempt to correct it.                               *
echo             *                                                      *
echo             * One moment please ......                             *
echo             ********************************************************
set errMsgPrinted=yes
:rdWorld
c:\dos\deltree /y c:\%geosver%\world > nul
c:\dos\xcopy /e d:\%geosver%\world c:\%geosver%\world\ > nul
:afterWorld

REM Scan the output file to see if any documents were corrupted.  If so,
REM inform the user.
c:\dos\find "C:\GLOBALPC\DOCUMENT" d:\temp\chkdsk.out > nul
if not errorlevel 1 goto docBad
c:\dos\find "C:\GLOBALPC\DESKTOP" d:\temp\chkdsk.out > nul
if errorlevel 1 goto bootGeos

:docBad
cls
echo             ********************************************************
echo             * Some of your documents may be damaged.  If a         *
echo             * document contains errors, please restore it from its *
echo             * backup copy.                                         *
echo             ********************************************************
pause

:bootGeos
set errMsgPrinted=

REM Don't delete chkdsk.out for now.
if exist file*.chk del file*.chk
cd \globalpc
go.bat
