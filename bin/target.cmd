if "%~1"=="-fcc" (
   SHIFT
) ELSE (
   CALL <NUL %0 -fcc %*
   GOTO :EOF
)
if "%1"=="-n" (
   set TYPE=nec
) ELSE (
   set TYPE=ec
)
IF NOT EXIST %LOCAL_ROOT%\.bbxxip\.bbxxip.nt.%TYPE% (
   echo *** Target type "%TYPE%" not built.
   GOTO :EOF
)
for /f "delims=" %%a in (%LOCAL_ROOT%\.bbxxip\.bbxxip.nt.%TYPE%) do set %%a
set GEOS_ROOT_REL=localpc\geos
IF NOT EXIST %destdir%\%GEOS_ROOT_REL%\ensemble.bat (
   echo *** Target at "%destdir%" not usable.
   GOTO :EOF
)
IF NOT DEFINED BASEBOX (SET BASEBOX=dosbox)
set OLD_PATH=%cd%
cd /D %destdir%
del /F "%destdir%\localpc\IPX_STAT.TXT"
del /F %GEOS_ROOT_REL%\init.bat
IF DEFINED GEOS_CENTRAL_STORAGE (
   echo mount s: %GEOS_CENTRAL_STORAGE% >> %GEOS_ROOT_REL%\init.bat
)
IF DEFINED GEOS_CDROM_DRIVE (
   IF EXIST "%GEOS_CDROM_DRIVE%\" (
      echo mount r %GEOS_CDROM_DRIVE% -t cdrom >> %GEOS_ROOT_REL%\init.bat
   ) ELSE (
      echo imgmount r "%GEOS_CDROM_DRIVE%" -t iso >> %GEOS_ROOT_REL%\init.bat
   )
)
IF EXIST %GEOS_ROOT_REL%\init.bat (
   echo swatgo >> %GEOS_ROOT_REL%\init.bat
)
IF EXIST %GEOS_ROOT_REL%\privdata\INI.BAK (
   perl -pi -e "s{C:\\\\GEOS\\\\GFS\\.IMG}{C:\\\\IMAGE\\\\GFS.IMG}ig; s{C:\\\\GEOS\\\\NETEC\\.INI}{C:\\\\LOCALPC\\\\GEOS\\\\NETEC.INI}ig; s{C:\\\\GEOS\\\\NET\\.INI}{C:\\\\LOCALPC\\\\GEOS\\\\NET.INI}ig; s{bootstrapPath\\s*=\\s*C:\\\\GEOS\\b}{bootstrapPath = C:\\\\LOCALPC\\\\GEOS}ig;" %GEOS_ROOT_REL%\privdata\INI.BAK
)
start /B %BASEBOX% -conf %ROOT_DIR%\bin\basebox.conf -conf %LOCAL_ROOT%\basebox_user.conf -noconsole
cd %OLD_PATH%
@cls
:waitForFile
@IF EXIST %destdir%\localpc\IPX_STAT.TXT GOTO foundFile
@sleep 1s
@echo|set /p="."
@GOTO waitForFile
:foundFile
FINDSTR /r /c:"127.0.0.1 from port" %destdir%\localpc\IPX_STAT.TXT | perl -e "my $status = <>; $status =~  m/(\d+)$/; printf('%%04X', $1);" > %destdir%\localpc\IPX_PORT.TXT
set /p IPX_PORT=<%destdir%\localpc\IPX_PORT.TXT
cls
rem mode 120,50
IF EXIST "%USERPROFILE%\swat.rc" (
   set CUSTOM_TCL_LOCATION=%USERPROFILE%\swat.rc
) ELSE IF EXIST "%cd%\swat.rc" (
   set CUSTOM_TCL_LOCATION=%cd%\swat.rc
) ELSE (
   set CUSTOM_TCL_LOCATION=
)
swat -net 00000000:7F000001%IPX_PORT%:003F
