@echo off
cls
echo Setze PC/GEOS Ensemble Status zurück...
echo J | del privdata\state\*.* > nul
echo J | del privdata\spool\*.* > nul
del privdata\ZWISCHEN.000
