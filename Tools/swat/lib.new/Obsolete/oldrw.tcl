#$Id: oldrw.tcl,v 3.2.30.1 97/03/29 11:25:53 canavese Exp $
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
	    echo -n [format {%-3s%04xh} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s%04xh} [index $i 0] $r1]
	}
	echo -n {  }
    }
    wmove 0 +1
    foreach i {{CS 9} {DS 11} {SS 10} {ES 8}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s%04xh} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s%04xh} [index $i 0] $r1]
	}
	echo -n {  }
    }
    var ip [index $regs 12] fs [frame funcsym [frame top]]
    if {![null $fs]} {
    	var fa [index [symbol fget $fs] 1]
    	echo [format {IP %04xh (%s)} $ip
    	    	    [if {$fa == $ip} {
    	    	    	[symbol fullname $fs]
    	    	    } else {
    	    	    	[format {%s+%d} [symbol fullname $fs] [expr $ip-$fa]]
    	    	    }]]
    } else {
    	echo [format {IP %04xh} $ip]
    }
    var _lastRegs $regs
}]
