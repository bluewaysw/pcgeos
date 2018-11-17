@echo off
cls
echo Resetting PC/GEOS state...
echo Y | del privdata\state\*.* > nul
del privdata\clipboar.000
del geos_act.ive
