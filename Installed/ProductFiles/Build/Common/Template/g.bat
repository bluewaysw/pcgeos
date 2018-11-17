rem run VAR(productlongname) with swat debugger
if exist SWATWAIT n:\nswat /n:f /s SERVER(VAR(dosdestpath)\)EC-dos(loader.exe) %1 %2 %3 %4
if not exist SWATWAIT n:\nswat /n:f SERVER(VAR(dosdestpath)\)EC-dos(loader.exe) %1 %2 %3 %4

