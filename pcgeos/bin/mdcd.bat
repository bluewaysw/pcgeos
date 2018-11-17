@echo off
REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
REM %
REM %          Copyright 1999, GlobalPC.  All rights reserved.
REM %
REM % File: mdcd.bat
REM % Author: Tim Bradley
REM % Description: makes a directory and then cd's to it.
REM %
REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mkdir %1 2>NUL
cd /d %1
