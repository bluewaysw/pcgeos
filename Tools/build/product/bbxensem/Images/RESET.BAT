@echo off
cls
echo Resetting PC/GEOS Ensemble state...
echo Y | del privdata\state\*.* > nul
echo Y | del privdata\spool\*.* > nul
del privdata\clipboar.000
