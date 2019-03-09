#
# Alternative regwin display function, as per Jim's request.
#
defvar _lastRegs nil
[defsubr _display_regs {}
{
    global  _lastRegs regnums
    var	    regs [current-registers]

    if {[null $_lastRegs]} {
    	var _lastRegs $regs
    }
    foreach i {{AX 0} {BX 3} {CX 1} {DX 2} {CS 9}} {
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
    wmove +9 +0
    foreach i {{SS 10} {DS 11} {ES 8}} {
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
    wmove 0 1
    var ip [index $regs 12] fs [frame funcsym [frame top]]
    if {![null $fs]} {
    	var fa [index [symbol fget $fs] 1]
    	if {$fa == $ip} {
	    var sa [symbol fullname $fs]
	} else {
	    var sa [format {%s+%d} [symbol fullname $fs] [expr $ip-$fa]]
    	}
    } else {
    	var sa {}
    }
    var sl [length $sa chars]
    if {$sl >= 36} {
    	echo -n [format {<%s IP %04x  } [range $sa [expr $sl-35] end chars]
	    	    	$ip]
    } else {
    	echo -n [format {%-36sIP %04x  } $sa $ip]
    }
    foreach i {{SP 4} {BP 5} {SI 6} {DI 7}} {
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
    var _lastRegs $regs
}]
