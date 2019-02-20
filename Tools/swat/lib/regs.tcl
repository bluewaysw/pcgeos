[proc biffmonster {}
{
    var sm [sym find module kernel::]
    foreach i {{AX 0} {BX 3} {CX 1} {DX 2} {SP 4} {BP 5} {SI 6} {DI 7}
	       {ES 8} {CS 9} {DS 11} {SS 10} {IP 20} {CC 257}
	       {ax 0} {bx 3} {cx 1} {dx 2} {sp 4} {bp 5} {si 6} {di 7}
	       {es 8} {cs 9} {ds 11} {ss 10} {ip 20} {cc 257}
	       {AL 12} {BL 15} {CL 13} {DL 14} {AH 16} {BH 19} {CH 17} {DH 18}
	       {al 12} {bl 15} {cl 13} {dl 14} {ah 16} {bh 19} {ch 17} {dh 18}} {
	var s [symbol make var [index $i 0]]
	symbol enter $s $sm
	sym vset $s nil register [index $i 0]
    }
    foreach i {byte word dword short long int char sbyte void} {
	var s [symbol make type $i]
	symbol enter $s $sm
	sym tset $s [type $i]
    }
}]

biffmonster
purge biffmonster
