@echo off
cls
if "%1"=="A:" testdisk 0 A: %2
if "%1"=="B:" testdisk 1 B: %2
if "%1"=="C:" testdisk 2 C: %2
if "%1"=="D:" testdisk 3 D: %2
if "%1"=="E:" testdisk 4 E: %2
if "%1"=="F:" testdisk 5 F: %2
if "%1"=="G:" testdisk 6 G: %2
if "%1"=="a:" testdisk 0 A: %2
if "%1"=="b:" testdisk 1 B: %2
if "%1"=="c:" testdisk 2 C: %2
if "%1"=="d:" testdisk 3 D: %2
if "%1"=="e:" testdisk 4 E: %2
if "%1"=="f:" testdisk 5 F: %2
if "%1"=="g:" testdisk 6 G: %2
if "%1"=="0" goto okay
if "%1"=="1" goto okay
if "%1"=="2" goto okay
if "%1"=="3" goto okay
if "%1"=="4" goto okay
if "%1"=="5" goto okay
if "%1"=="6" goto okay
echo Enter the command "TESTDISK X:" where X: is a drive with a disk in it.
echo If you are using DR-DOS, type "TESTDISK X: DR"
goto end
:okay
if exist data.txt del data.txt
echo Displaying boot sector for drive %2 . Several rows of numbers should 
echo appear below. 
if "%3"=="DR" goto drdos
if "%3"=="dr" goto drdos
echo l ds:0 %1 0 1>> data.txt
echo d ds:0 3e>> data.txt
echo q>> data.txt
debug < data.txt
goto end
:drdos
rem NOTE: DO NOT PLACE ANY SPACES BEFORE THE GREATER-THAN SIGNS OR SID
rem WILL UPCHUCK
echo qrds:0,%1,0,1>> data.txt
echo dds:0,3e>> data.txt
echo q>> data.txt
sid < data.txt
:end
