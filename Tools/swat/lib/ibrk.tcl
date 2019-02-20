##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- Interactive Breakpoint setting
# FILE: 	ibrk.tcl
# AUTHOR: 	Adam de Boor, Mar 12, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	ibrk	    	    	Interactively set a breakpoint
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/12/89		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: ibrk.tcl,v 3.0 90/02/04 23:46:50 adam Exp $
#
###############################################################################
[defvar ibrkPageLen 10 var
{Number of instructions to skip when using the ^D and ^U commands of ibrk}]

defvar ibrkAddrStack {}

[defsubr find-prev {addr {n 10}}
{
    global ibrkAddrStack

    if {[length $ibrkAddrStack] > 0} {
	#
	# Something still on the address stack -- use that since
	# we know it's right.
	#
	var addr [index $ibrkAddrStack 0]
	var ibrkAddrStack [range $ibrkAddrStack 1 end]
	return $addr
    } else {
	#
	# Apply a simple heuristic to try and find the previous
	# instruction:
	#   start $n bytes back (the maximum length of a 286 inst)
	#   advance a byte at a time until you find an instruction
	#   	that uses all the bytes to the instruction
	#		we're on at the moment.
	#
	for {var i $n} {$i > 0} {var i [expr $i-1]} {
	    var inst [unassemble $addr-$i]
	    if {[index $inst 2] == $i} {
		break
	    }
	}
	return $addr-$i
    }
}]

[defcommand ibrk {{addr nil}} breakpoint|top
{Set a breakpoint interactively. At each instruction, you have several options:
    q	Quit back to the command level.
    n	Go to next instruction (this also happens if you just hit
	return).
    p   Go to previous instruction.
    P	Look for a different previous instruction.
    ^D	Go down a "page" of instructions. The size of the page is controlled
    	by the global variable ibrkPageLen. It defaults to 10.
    ^U	Go up a "page" of instructions.
    b	Set an unconditional breakpoint at the current instruction and
	go back to command level.
    a  	Like 'b', but the breakpoint is set for all patients.
    t  	Like 'b', except the breakpoint is temporary and will be
    	removed the next time the machine stops.
    B	Like 'b', but can be followed by a command to execute when the
	breakpoint is hit.
    A	Like 'B', but for all patients.
    T	Like 'B', but breakpoint is temporary.}
{
    global ibrkAddrStack
    var ibrkAddrStack {}

    var addr [get-address $addr]

    [for {var inst [unassemble $addr]} {1} {var inst [unassemble $addr]} {
    	if {[brk isset $addr]} {
	    echo -n {b }
    	} else {
	    echo -n {  }
	}
    	echo -n [format-instruction $inst] {}
    	var ans [read-char 0]
	[case $ans in
    	    \[Nn\n\] {
    	    	var ibrkAddrStack [concat $addr $ibrkAddrStack]
    	    	var addr $addr+[index $inst 2]
    	    	echo
    	    }
    	    b {
    	    	var btype set
    	    	echo
    	    	break
    	    }
	    a {
    	    	var btype aset
    	    	echo
    	    	break
    	    }
	    t {
    	    	var btype tset
    	    	echo
    	    	break
    	    }
	    q {
    	    	echo
    	    	break
    	    }
	    p {
    	    	echo
    	    	var addr [find-prev $addr]
    	    }
	    P {
    	    	#
    	    	# Continue search for previous instruction if we found a bogus
	    	# one before...also wipe out the ibrkAddrStack in case we've
		# come back to an earlier instruction because we screwed up
		# before.
	    	#
    	    	var ilen [index $inst 2] ibrkAddrStack {}
    	    	var addr [find-prev $addr+$ilen [expr $ilen-1]]
    	    	echo
    	    }
    	    \004 {
    	    	global ibrkPageLen
    	    	echo
	    	for {var i $ibrkPageLen} {$i > 0} {var i [expr $i-1]} {
		    [var ibrkAddrStack [concat $addr $ibrkAddrStack]
			 addr $addr+[index $inst 2]]
    	    	    var inst [unassemble $addr 0]
    	    	    if {$i > 1} {
			if {[brk isset $addr]} {
			    echo b [format-instruction $inst]
			} else {
			    echo { } [format-instruction $inst]
			}
    	    	    }
		}
	    }
    	    \025 {
    	    	global ibrkPageLen
		echo
		for {var i $ibrkPageLen} {$i > 0} {var i [expr $i-1]} {
		    var addr [find-prev $addr]
    	    	    if {$i > 1} {
		    	var inst [unassemble $addr 0]
			if {[brk isset $addr]} {
			    echo b [format-instruction $inst]
			} else {
			    echo { } [format-instruction $inst]
			}
    	    	    }
		}
    	    }	    	
	    B {
	    	echo -n {B }
	    	var cond [read-line 1] btype set
	    	break
    	    }
	    A {
	    	echo -n {A }
	    	var cond [read-line 1] btype aset
	    	break
    	    }
	    T {
	    	echo -n {T }
	    	var cond [read-line 1] btype tset
	    	break
    	    }
    	    default {
	    	echo Excuse me?
	    }
	]
    }]
    set-address $addr

    if {[length $btype]} {
    	if {[length $cond]} {
    	    brk $btype $addr $cond
    	} else {
    	    brk $btype $addr
    	}
    }
}]
