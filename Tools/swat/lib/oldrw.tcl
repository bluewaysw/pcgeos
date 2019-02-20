[defsubr _display_regs {}
{
    global  _lastRegs regnums
    var	    regs [current-registers]

    if {[null $_lastRegs]} {
    	var _lastRegs $regs
    }

    foreach i {{AX 0} {BX 3} {CX 1} {DX 2} {SI 6} {DI 7} {BP 5} {SP 4}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s%04x} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s%04x} [index $i 0] $r1]
	}
	echo -n {  }
    }
    wmove 0 +1
    foreach i {{CS 9} {DS 11} {SS 10} {ES 8}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s%04x} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s%04x} [index $i 0] $r1]
	}
	echo -n {  }
    }
    var ip [index $regs 12] fs [frame funcsym [frame top]]
    if {![null $fs]} {
    	var fa [index [symbol fget $fs] 1]
    	echo [format {IP %04x (%s)} $ip
    	    	    [if {$fa == $ip} {
    	    	    	[symbol fullname $fs]
    	    	    } else {
    	    	    	[format {%s+%d} [symbol fullname $fs] [expr $ip-$fa]]
    	    	    }]]
    } else {
    	echo [format {IP %04x} $ip]
    }
    var _lastRegs $regs
}]
