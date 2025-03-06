@ECHO OFF
CLS
ECHO PC/GEOS Ensemble Reset Utility (RESET.BAT)
ECHO.
ECHO This utility immediately deletes the following files:
ECHO  - state files in PRIVDATA\STATE\*.000
ECHO  - failed print jobs in PRIVDATA\SPOOL\*.000,*.PS,*.RAW
ECHO  - clipboard file: PRIVDATA\CLIPBOAR.000
ECHO  - WebMagick cache files in PRIVDATA\CACHE and its subdirectories.
ECHO.
ECHO After that everything should work fine again.
ECHO.
ECHO Are you sure you want to proceed ? 
CHOICE
IF ERRORLEVEL 4 GOTO CHOICENOTAVAIL
IF ERRORLEVEL 2 GOTO NO
IF ERRORLEVEL 1 GOTO YES
IF ERRORLEVEL 0 GOTO CHOICENOTAVAIL
REM // Errorlevel 3 is triggered on FreeDOS which has a choice of [Y,/,N] if you press N
REM // Errorlevel 4 is triggered on Windows XP's CMD.EXE, which has no CHOICE.COM
REM // Errorlevel 0 is triggered on other Systems if CHOICE.COM isn't available

:CHOICENOTAVAIL
ECHO.
ECHO Please press CTRL+C if you didn't want to proceed.
PAUSE

:YES
ECHO.
ECHO Trying to delete state files...
IF EXIST PRIVDATA\STATE\*.0?? DEL PRIVDATA\STATE\*.0?? 

ECHO Trying to delete failed print jobs...
IF EXIST PRIVDATA\SPOOL\*.0?? DEL PRIVDATA\SPOOL\*.0?? 
IF EXIST PRIVDATA\SPOOL\*.PS DEL PRIVDATA\SPOOL\*.PS 
IF EXIST PRIVDATA\SPOOL\*.RAW DEL PRIVDATA\SPOOL\*.RAW 

ECHO Trying to delete clipboard file...
REM // In a localized Version of RESET.BAT the localized filename
REM // of the clipboard file is necessary here.
IF EXIST PRIVDATA\CLIPBOAR.000 DEL PRIVDATA\CLIPBOAR.000 

ECHO Trying to delete WebMagick cache Files...
REM // Files in privdata\cache have an extension .000, .001 and so on...
IF EXIST PRIVDATA\CACHE\*.0?? DEL PRIVDATA\CACHE\*.0?? 
REM // Files in subfolders are in the form 00000001.ext ... ffffffff.ext
REM // ext can be anything from gif to jpg, svg, all the files of the web.
REM // Its a simple counter, which counts up for each filename in a hexadecimal representation.
REM // The probability of achieving values above "0fffffff.ext" is extremely low.
REM // There are actually 5 subdirectories and 5 alternative subdirectories.
REM // This is defined by NUM_CACHE_DIRS in the sourcecode of WebMagick.
IF EXIST PRIVDATA\CACHE\0\0*.* DEL PRIVDATA\CACHE\0\0*.*
IF EXIST PRIVDATA\CACHE\1\0*.* DEL PRIVDATA\CACHE\1\0*.*
IF EXIST PRIVDATA\CACHE\2\0*.* DEL PRIVDATA\CACHE\2\0*.*
IF EXIST PRIVDATA\CACHE\3\0*.* DEL PRIVDATA\CACHE\3\0*.*
IF EXIST PRIVDATA\CACHE\4\0*.* DEL PRIVDATA\CACHE\4\0*.*
IF EXIST PRIVDATA\CACHE\ALT0\0*.* DEL PRIVDATA\CACHE\ALT0\0*.*
IF EXIST PRIVDATA\CACHE\ALT1\0*.* DEL PRIVDATA\CACHE\ALT1\0*.*
IF EXIST PRIVDATA\CACHE\ALT2\0*.* DEL PRIVDATA\CACHE\ALT2\0*.*
IF EXIST PRIVDATA\CACHE\ALT3\0*.* DEL PRIVDATA\CACHE\ALT3\0*.*
IF EXIST PRIVDATA\CACHE\ALT4\0*.* DEL PRIVDATA\CACHE\ALT4\0*.*

ECHO Trying to delete WebMagick cache subdirectories...
IF EXIST PRIVDATA\CACHE\0\NUL RD PRIVDATA\CACHE\0 
IF EXIST PRIVDATA\CACHE\1\NUL RD PRIVDATA\CACHE\1 
IF EXIST PRIVDATA\CACHE\2\NUL RD PRIVDATA\CACHE\2 
IF EXIST PRIVDATA\CACHE\3\NUL RD PRIVDATA\CACHE\3 
IF EXIST PRIVDATA\CACHE\4\NUL RD PRIVDATA\CACHE\4 
IF EXIST PRIVDATA\CACHE\ALT0\NUL RD PRIVDATA\CACHE\ALT0 
IF EXIST PRIVDATA\CACHE\ALT1\NUL RD PRIVDATA\CACHE\ALT1 
IF EXIST PRIVDATA\CACHE\ALT2\NUL RD PRIVDATA\CACHE\ALT2 
IF EXIST PRIVDATA\CACHE\ALT3\NUL RD PRIVDATA\CACHE\ALT3 
IF EXIST PRIVDATA\CACHE\ALT4\NUL RD PRIVDATA\CACHE\ALT4 

ECHO.
ECHO Done.
GOTO END

:NO
ECHO.
ECHO Terminated by User.

:END
ECHO.
