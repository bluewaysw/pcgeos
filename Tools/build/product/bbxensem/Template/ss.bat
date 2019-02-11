rem Run VAR(productlongname) with Swat debugger
rem    (pauses for swat)
NTDEMO(stub32nm /s EC-dos(loader.exe) %1 %2 %3 %4)
PCDEMO(stub32m /s /c:1 /b:3 EC-dos(loader.exe) %1 %2 %3 %4)
PROTO(stub32m /s /c:1 /b:3 EC-dos(loader.exe) %1 %2 %3 %4)
