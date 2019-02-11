@echo off
cls
echo Resetting Breadbox Ensemble state...
echo Y | del privdata\state\*.* > nul
echo Y | del privdata\spool\*.* > nul
del privdata\clipboar.000
