@echo off
cls
echo This program will remove GeoWorks from your hard drive.
echo All GeoWorks files and subdirectories will be deleted.
echo (Press Ctrl-c now to abort)
pause
rename uninstal.bin uninstal.exe
uninstal.exe
rename uninstal.exe uninstal.bin

