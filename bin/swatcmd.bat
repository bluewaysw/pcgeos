cd %ROOT_DIR%
if *%1==* goto go
if %1==-r goto remote
if %1==-l goto local
goto go
:remote
swatcomm.pl "Serial"
goto go
:local
swatcomm.pl "Named Pipe"
:go
swat32
