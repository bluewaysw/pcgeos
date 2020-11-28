start basebox
sleep 2s
FINDSTR /r /c:"127.0.0.1 from port" %LOCAL_ROOT%\gbuild\localpc\IPX_STAT.txt | perl -e "my $status = <>; $status =~  m/(\d+)$/; printf('%%04X', $1);" > %LOCAL_ROOT%\gbuild\localpc\IPX_PORT.txt
set /p IPX_PORT=<%LOCAL_ROOT%\gbuild\localpc\IPX_PORT.txt
cls
mode 120,50
swat -net 00000000:7F000001%IPX_PORT%:003F