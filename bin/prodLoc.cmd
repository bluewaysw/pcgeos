echo Destination folder: %1
echo Source folder: %2
echo Tools folder: %3
echo Translation folder: %4

echo mount k: %1 > %3\ensemble\INIT.BAT
echo mount l: %2 >> %3\ensemble\INIT.BAT
echo mount m: %4 >> %3\ensemble\INIT.BAT
echo loader.exe >> %3\ensemble\INIT.BAT
echo exit >> %3\ensemble\INIT.BAT

set OLD_PATH=%cd%
cd /D %3 
%BASEBOX% -conf %ROOT_DIR%\bin\basebox.conf -conf %LOCAL_ROOT%\basebox_user.conf
more TRANSLOG.TXT
cd %OLD_PATH%
