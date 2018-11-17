rem
rem   NOTE!  cvtpcx give color=color8, which doesn't compile.  Manually
rem   change it to color=color4
rem
cvtpcx -G -2 -f -t -m1 -x50 -w15 -h15 -Stool -rAPPTC -nTiny FF000-8.pcx
cvtpcx -G -2 -f -t -m1 -x1 -y1 -w48 -h30 -rAPPTC -nApp FF000-8.pcx
cvtpcx -G -j -m1 -f -w15 -h13 -nFolder A060-8.pcx
cvtpcx -G -j -m1 -f -w15 -h13 -nFile BR001-8.pcx

