@echo off
cls
echo Resetting PC/GEOS Ensemble state...

echo Clear browser cache...
for /d %%F in (0 1 2 3 4 alt0 alt1 alt2 alt3 alt4) do (
    echo Deleting contents of privdata\cache\%%F...
    del /q /s privdata\cache\%%F\*.* > nul
)

for %%F in (privdata\cache\*) do (
    if not exist %%F\ (
        del /q %%F > nul
    )
)

echo Clear state and spool folders...
echo Y | del privdata\state\*.* > nul
echo Y | del privdata\spool\*.* > nul

echo Clear clipboard...
del privdata\clipboar.000 > nul

echo Reset complete.
