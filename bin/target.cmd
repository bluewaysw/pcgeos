if "%~1"=="-fcc" (
   SHIFT
) ELSE (
   CALL <NUL %0 -fcc %*
   GOTO :EOF
)
IF NOT DEFINED BASEBOX (SET BASEBOX=dosbox)
set OLD_PATH=%cd%
cd /D %LOCAL_ROOT%\gbuild\localpc 
del /F %LOCAL_ROOT%\gbuild\localpc\IPX_STAT.txt
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
:waitForFile
:foundFile
IF EXIST "%USERPROFILE%\swat.rc" (
   set CUSTOM_TCL_LOCATION=%USERPROFILE%\swat.rc
) ELSE IF EXIST "%cd%\swat.rc" (
   set CUSTOM_TCL_LOCATION=%cd%\swat.rc
) ELSE (
   set CUSTOM_TCL_LOCATION=
)
sleep 20
swat
