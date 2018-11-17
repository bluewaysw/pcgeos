@ECHO OFF
REM Make a bootable DOS disk to load AOL
REM Modified 10/3/91 Jay Levitt - use FINDIT to make sure FORMAT
REM is available to us

IF EXIST kernel.exe GOTO START
ECHO 
ECHO You must be in the America Online directory to run this file.
ECHO 
GOTO END

:START
IF '%1' == '/clean' GOTO CLEAN1
IF '%1' == '/CLEAN' GOTO CLEAN1

CLS
ECHO                          America Online
ECHO                          1-800-827-6364
ECHO 
ECHO We are about to format a bootable disk.  This disk will allow
ECHO you to load America Online without any device drivers or other
ECHO memory-resident programs interfering.  You may press CTRL-C at
ECHO any time to cancel this process.
ECHO 
ECHO NOTE to high-density drive owners (1.2 or 1.44 Meg):
ECHO You may need to use a high-density disk.
ECHO 
ECHO 
ECHO Have a blank or unneeded disk ready.  ALL DATA
ECHO ON THIS DISK WILL BE ERASED.
ECHO 

system\qforms\findit.exe format.com
IF ERRORLEVEL -1 GOTO NOFMT

format a: /s
IF ERRORLEVEL 1 GOTO ERROR
GOTO COPY

:ERROR
ECHO 
ECHO Operation cancelled.
GOTO END

:NOFMT
ECHO 
ECHO The FORMAT.COM program could not be found.  Please add your DOS
ECHO directory to the PATH statements in your AUTOEXEC.BAT file.
ECHO See your DOS manual for details.
ECHO 
GOTO END

:CLEAN1
ECHO 
ECHO Insert your AOL boot disk into drive A.
PAUSE
IF EXIST a:autoexec.bat GOTO COPY
ECHO 
ECHO Boot files not found.  Please try again or call 1-800-827-6364
ECHO for assistance.
ECHO 
GOTO END

:COPY
ECHO Copying boot files...

REM Put current directory path into variable AOLOC
cd > setaoloc.dat
copy userdata\aol\setaoloc.set+setaoloc.dat setaoloc.bat > nul
CALL setaoloc.bat

REM Put current drive into file aolexec.2
cd \
cd > %aoloc%\aolexec.2
cd %aoloc% > nul

ECHO FILES=30 > a:config.sys
ECHO BUFFERS=30 >> a:config.sys

ECHO @ECHO OFF > aolexec.1
ECHO ECHO Loading America Online... >> aolexec.1
ECHO PROMPT $P$G >> aolexec.1

ECHO cd %aoloc% >> aolexec.2

REM For clean load, add extra parameters

IF '%1' == '/clean' GOTO CLEAN2
IF NOT '%1' == '/CLEAN' GOTO NOCLEAN

:CLEAN2
ECHO KERNEL /nowaitpost /nomem >> aolexec.2
GOTO COPY2

:NOCLEAN
ECHO KERNEL >> aolexec.2

:COPY2
copy aolexec.1+aolexec.2 a:autoexec.bat > nul


del setaoloc.dat > nul
del setaoloc.bat > nul
del aolexec.1 > nul
del aolexec.2 > nul

CLS
ECHO 
ECHO Reboot with this disk in the A: drive to load America Online.
ECHO 
ECHO If America Online operates properly when booted this way, you
ECHO will want to remove device drivers or other memory resident
ECHO programs one-by-one from the AUTOEXEC.BAT and CONFIG.SYS files
ECHO on your own hard drive to determine what causes your problem.  For details,
ECHO see your DOS manual, or go online to our DOS forum, keyword "dos".
ECHO 
IF '%1' == '/clean' GOTO CLEAN3
IF NOT '%1' == '/CLEAN' GOTO END

:CLEAN3
ECHO This disk uses a "clean" load, adding the parameter "/nowaitpost" to
ECHO turn off several optimizations in the PC/GEOS environment, and "/nomem"
ECHO to disable use of your extended/expanded memory.
ECHO 
ECHO If this clean load solves your problem, and the earlier boot disk did
ECHO not, you should try using:
ECHO 
ECHO AOL /nowaitpost /nomem
ECHO 
ECHO to load in the future when booting from your hard drive.
ECHO 

:END
