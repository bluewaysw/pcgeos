rem Run VAR(productlongname) with Swat debugger
rem    (does not pause for swat)
NTDEMO(stub32nm EC-dos(loader.exe) %1 %2 %3 %4)
PCDEMO(stub32m /c:1 /b:3 EC-dos(loader.exe) %1 %2 %3 %4)
PROTO(stub32m /c:1 /b:3 EC-dos(loader.exe) %1 %2 %3 %4)
