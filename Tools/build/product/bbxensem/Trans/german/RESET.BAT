@ECHO OFF
CLS
ECHO PC/GEOS-Ensemble Reset-Programm (RESET.BAT)
ECHO.
ECHO Dieses Dienstprogramm lîscht unmittelbar die folgenden Dateien und Ordner:
ECHO.
ECHO  - STATE-Dateien in PRIVDATA\STATE\*.000
ECHO  - Fehlgeschlagene DruckauftrÑge in PRIVDATA\SPOOL\*.000,*.PS,*.RAW
ECHO  - Zwischenablage: PRIVDATA\ZWISCHEN.000
ECHO  - WebMagick Cache-Dateien und -Ordner in PRIVDATA\CACHE incl. aller Unterordner
ECHO.
ECHO Danach sollte alles wieder wie gewohnt funktionieren. :-)
ECHO.
ECHO Mîchten Sie fortfahren? 
ECHO.
CHOICE
IF ERRORLEVEL 4 GOTO CHOICENOTAVAIL
IF ERRORLEVEL 2 GOTO NO
IF ERRORLEVEL 1 GOTO YES
IF ERRORLEVEL 0 GOTO CHOICENOTAVAIL
REM // Fehlerstufe 3 wird in FreeDOS ausgelîst, welches eine Auswahlmîglichkeit (CHOICE.COM)
REM // zwischen [Y,/,N] anbietet, wenn Sie 'N' drÅcken.
REM // Fehlerstufe 4 wird in CMD.EXE von Windows XP ausgelîst; diese hat keine Auswahlmîglichkeit (CHOICE.COM).
REM // Fehlerstufe 0 wird in anderen Systemen ausgelîst, falls CHOICE.COM nicht verfÅgbar ist.

:CHOICENOTAVAIL
ECHO.
ECHO DrÅcken Sie Strg+C wenn Sie NICHT forfahren mîchten!
PAUSE

:YES
ECHO.
ECHO Lîsche STATE-Dateien...
ECHO.
IF EXIST PRIVDATA\STATE\*.0?? DEL PRIVDATA\STATE\*.0?? 
ECHO.
ECHO Lîsche Fehlgeschlagene DruckauftrÑge...
ECHO.
IF EXIST PRIVDATA\SPOOL\*.0?? DEL PRIVDATA\SPOOL\*.0?? 
IF EXIST PRIVDATA\SPOOL\*.PS DEL PRIVDATA\SPOOL\*.PS 
IF EXIST PRIVDATA\SPOOL\*.RAW DEL PRIVDATA\SPOOL\*.RAW 
ECHO.
ECHO Lîsche Zwischenablage...
ECHO.
REM // In einer lÑnderspezifischen Version von RESET.BAT wird hier der lÑnderspezifische
REM // Dateiname der Zwischenablage benîtigt.
IF EXIST PRIVDATA\ZWISCHEN.000 DEL PRIVDATA\ZWISCHEN.000 
ECHO.
ECHO Lîsche WebMagick CACHE-Dateien und -Ordner...
ECHO.
REM // Dateien in privdata\cache haben die Dateiendung .000, .001, u.s.w. ...
IF EXIST PRIVDATA\CACHE\*.0?? DEL PRIVDATA\CACHE\*.0?? 
REM // Dateien in den Unterordnern haben das Format 00000001.ext ... ffffffff.ext
REM // wobei 'ext' fÅr 'gif' bis 'jpg', 'svg' und alle Dateien im Web steht.
REM // Es ist ein einfacher ZÑhler der jeden Dateinamen in hexadezimaler Form hochzÑhlt.
REM // Die Wahrscheinlichkeit, Werte oberhalb "0fffffff.ext" zu erreichen, ist extrem gering.
REM // Es existieren z. Z. 5 Unterordner und 5 alternative Unterordner.
REM // Diese Vorgabe wird durch den Programm-Code NUM_CACHE_DIRS in WebMagick definiert.
ECHO.
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
ECHO.
ECHO Lîsche WebMagick CACHE-Unterordner...
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
ECHO Fertig!
GOTO END

:NO
ECHO.
ECHO Durch Benutzer abgebrochen!

:END
ECHO.
