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
@IF EXIST %LOCAL_ROOT%\gbuild\localpc\IPX_STAT.txt GOTO foundFile
@sleep 1s
@echo|set /p="."
@GOTO waitForFile
:foundFile
FINDSTR /r /c:"127.0.0.1 from port" %LOCAL_ROOT%\gbuild\localpc\IPX_STAT.txt | perl -e "my $status = <>; $status =~  m/(\d+)$/; printf('%%04X', $1);" > %LOCAL_ROOT%\gbuild\localpc\IPX_PORT.txt
set /p IPX_PORT=<%LOCAL_ROOT%\gbuild\localpc\IPX_PORT.txt
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
