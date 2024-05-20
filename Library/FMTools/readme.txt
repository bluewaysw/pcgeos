This folder contains plug-in libraries for the 'Utilities' menu of the file manager.
These libraries have to include 'fmtool.goh' (if written in GOC).
The first exported routine must be based on the prototype FMFetchToolsProc (see fmtool.goh),
the second exported routine must be based on the FMToolProc prototype.
The token must be "FMTL", 0
You shold also provide a .rev file and a local.mk file.

An simple example can be found in "Library\SDK_C\FMTools\FMTDemo" folder.
