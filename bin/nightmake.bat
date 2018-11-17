@echo off
perl %ROOT_DIR%\Tools\scripts\perl\nightmake.pl
%ROOT_DIR%\bin\NIGHTOUT.COM < %ROOT_DIR%\Installed\nightmake.out > %ROOT_DIR%\Installed\err.out
C:\WINNT\system32\blat.exe %ROOT_DIR%\Installed\err.out -t installs@myturninc.com -c ayuen@myturn.com -s "Morning make errors" -try 100
