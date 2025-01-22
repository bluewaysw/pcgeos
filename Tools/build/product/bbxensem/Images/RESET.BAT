@echo off
cls
echo Resetting PC/GEOS Ensemble state...

echo Clear browser cache...
for %%F in (0 1 2 3 4 alt0 alt1 alt2 alt3 alt4) do (
    echo Deleting contents of privdata\cache\%%F...
    if exist privdata\cache\%%F\*.* del privdata\cache\%%F\*.* > nul
)

echo Clear state and spool folders...
if exist privdata\state\*.* del privdata\state\*.* > nul
if exist privdata\spool\*.* del privdata\spool\*.* > nul

echo Clear clipboard...
if exist privdata\clipboar.000 del privdata\clipboar.000 > nul

echo Reset complete.
