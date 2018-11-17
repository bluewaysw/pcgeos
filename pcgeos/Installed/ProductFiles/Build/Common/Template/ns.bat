rem run VAR(productlongname) with swat debugger
if exist SWATWAIT n:\swat /b:3 /i:d /s SERVER(VAR(dosdestpath)\)EC-dos(loader.exe) %1 %2 %3 %4
if not exist SWATWAIT n:\swat /b:3 /i:d SERVER(VAR(dosdestpath)\)EC-dos(loader.exe) %1 %2 %3 %4

