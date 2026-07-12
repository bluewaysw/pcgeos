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
IF NOT EXIST %destdir%\localpc\ensemble\ensemble.bat (
   echo *** Target at "%destdir%" not usable.
   GOTO :EOF
)
IF NOT DEFINED BASEBOX (SET BASEBOX=dosbox)
set OLD_PATH=%cd%
cd /D %destdir%\localpc 
del /F "%destdir%\localpc\IPX_STAT.txt"
del /F ensemble\init.bat
IF DEFINED GEOS_CENTRAL_STORAGE (
   echo mount s: %GEOS_CENTRAL_STORAGE% >> ensemble\init.bat
)
IF DEFINED GEOS_CDROM_DRIVE (
   IF EXIST "%GEOS_CDROM_DRIVE%\" (
      echo mount r %GEOS_CDROM_DRIVE% -t cdrom >> ensemble\init.bat
   ) ELSE (
      echo imgmount r "%GEOS_CDROM_DRIVE%" -t iso >> ensemble\init.bat
   )
)
IF EXIST ensemble\init.bat (
   echo swatgo >> ensemble\init.bat
)
start %BASEBOX% -conf %ROOT_DIR%\bin\basebox.conf -conf %LOCAL_ROOT%\basebox_user.conf
cd %OLD_PATH%
@cls
rem mode 120,50
IF EXIST "%USERPROFILE%\swat.rc" (
   set CUSTOM_TCL_LOCATION=%USERPROFILE%\swat.rc
) ELSE IF EXIST "%cd%\swat.rc" (
   set CUSTOM_TCL_LOCATION=%cd%\swat.rc
) ELSE (
   set CUSTOM_TCL_LOCATION=
)
sleep 3
swat 
