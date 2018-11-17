##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#   	stop	    	    	Source-level breakpoint setter
#   	ecbrk	    	    	Everywhere cbrk
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/12/89		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: ibrk.tcl,v 3.20.9.1 97/03/29 11:26:46 canavese Exp $
#
###############################################################################
[defvar ibrkPageLen 10 {swat_variable}
{Number of instructions to skip when using the ^D and ^U commands of ibrk}]

defvar ibrkAddrStack {}

[defsubr ibrk-find-prev {addr {n 10}}
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

[defcmd ibrk {{addr nil}} breakpoint
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
    var	gotnull {}
    var addr [get-address $addr]

    [for {var inst [unassemble $addr]} {1} {var inst [unassemble $addr]} {
    	if {[null $gotnull]} {
    	    if {[brk isset $addr]} {
	    	echo -n {b }
    	    } else {
	    	echo -n {  }
	    }
    	    echo -n [format-instruction $inst $addr] {}
    	}

    	var gotnull {}
    	var ans [read-char 0]
        if {[string c $ans \200] == 0} {
    	    var gotnull TRUE
    	}

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
    	    	var addr [ibrk-find-prev $addr]
    	    }
	    P {
    	    	#
    	    	# Continue search for previous instruction if we found a bogus
	    	# one before...also wipe out the ibrkAddrStack in case we've
		# come back to an earlier instruction because we screwed up
		# before.
	    	#
    	    	var ilen [index $inst 2] ibrkAddrStack {}
    	    	var addr [ibrk-find-prev $addr+$ilen [expr $ilen-1]]
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
			    echo b [format-instruction $inst $addr]
			} else {
			    echo { } [format-instruction $inst $addr]
			}
    	    	    }
		}
	    }
    	    \025 {
    	    	global ibrkPageLen
		echo
		for {var i $ibrkPageLen} {$i > 0} {var i [expr $i-1]} {
		    var addr [ibrk-find-prev $addr]
    	    	    if {$i > 1} {
		    	var inst [unassemble $addr 0]
			if {[brk isset $addr]} {
			    echo b [format-instruction $inst $addr]
			} else {
			    echo { } [format-instruction $inst $addr]
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
    	    \200 {
    	    	# special case null character
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


##############################################################################
#				stop
##############################################################################
#
# SYNOPSIS:	Interface for setting breakpoints in high-level language
#		programs.   
# PASS:		option	= "at" or "in" or an address
#   	    	[args]	= address for "at" or "in", or nothing.
# CALLED BY:	user
# RETURN:	breakpoint token
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/91		Initial Revision
#
##############################################################################
[defcommand stop {option args} {top.breakpoint}
{Usage:
    stop in <class>::<message> [if <expr>]
    stop in <procedure> [if <expr>]
    stop in <address-history token> [if <expr>]
    stop at [<file>:]<line> [if <expr>]
    stop <address> [if <expr>]

Examples:
    "stop in main"
    "stop in @3"
    "stop at /staff/pcgeos/Loader/main.asm:36 if {joe_local==22}"
    "stop at 25"
    "stop MemAlloc+3 if {ax==3}"

Synopsis:
    Specify a place and condition at which the machine should stop executing.
    This command is intended primarily for setting breakpoints when debugging
    a geode created in C or another high-level language, but may also be used
    when debugging assembly-language geodes.

Notes:
    * "stop in" will set a breakpoint at the beginning of a procedure, immed-
       iately after the procedure's stack frame has been set up.

    * For convenience, "stop in" also allows address-history tokens.  This is
      useful when used in conjunction with the "methods" command.

    * "stop at" will set a breakpoint at the first instruction of the given
      source line. If no <file> is specified, the source file for the current
      stack frame is used.

    * If a condition is specified, by means of an "if <expr>" clause,
      you should enclose the expression in {}'s to prevent any nested commands,
      such as a "value fetch" command, from being evaluated until the break-
      point is hit.

See also:
    brk, ibrk
}
{
    #
    # Check for a conditional and isolate it as the appropriate command to
    # be bound to the breakpoint.
    #
    # If there's a condition, it is placed in $cond, protected by an extra
    # list to cope with the "concat" used at the end to deal with specifying an
    # unconditional breakpoint...
    #
    var cond [string first { if } $args]
    if {$cond >= 0} {
    	[var cond [list [list getvalue [range $args [expr $cond+4] end chars]]]
	     args [range $args 0 [expr $cond-1] chars]]
    } else {
    	var cond {}
    }

    if {[string c $option at] == 0} {
    	if {[length $args chars] == 0} {
	    error {"stop at" requires <filename>:<line> or <line> as an additional argument}
    	}
    	if {[length $args] > 1} {
    	    #
	    # Allow the file and line to be separated by a space, as well
	    # as a colon.
	    #
	    var file [index $args 0] line [index $args 1]
    	} else {
    	    var colon [string last : $args]
	    if {$colon >= 0} {
    	    	#
		# File and line given, break them into separate variables.
		#
	    	var file [range $args 0 [expr $colon-1] chars]
		var line [index [range $args [expr $colon+1] end chars] 0]
    	    } else {
    	    	#
		# Line-only format. file'll be handled in a moment.
		#
	    	var line [index $args 0]
    	    }
	    [if {[null $file] && [catch {src line [frame register pc]} file]==0}
	    {
    	    	#
		# No file was given, but the current frame has source-line
		# information, so use that file.
		#
	    	var file [index $file 0]
	    } elif {[null $file]} {
	    	error {cannot determine source file for breakpoint}
    	    }]
	}
	
    	#
	# Get an address list for the file and line we've got.
	#
	var a [src addr $file $line]
	if {[null $a]} {
	    error [format {cannot determine address of %s:%s} $file $line]
    	}
    } elif {[string c $option in] == 0} {
    	if {[length $args chars] == 0} {
	    error {"stop in" requires a procedure name as an additional argument}
    	} elif {[length $args] != 1} {
	    error {"stop in" can only accept one procedure in which to stop}
	}


	#
    	# use "symbol faddr" rather than "symbol find" to allow things like
	# @3 or cs:ax as the procedure.
	#
	var s [symbol faddr proc [index $args 0]]

	if {[null $s]} {
	    error [format {procedure %s not defined} $args]
    	}
	
	var n [symbol fullname $s]
    	#
	# See if the special local label ??START is present in the procedure.
	# If so, it's the end of the prologue and we want to set the breakpoint
    	# there. Else, just use the start of the procedure.
	#
    	if {![null [sym find label ??START $s]]} {
	    var a [addr-parse $n::??START]
    	} else {
	    var a [addr-parse $n]
    	}
    } else {
    	#
	# Just treat it as an address.
	#
    	var a [addr-parse $option]
	if {[null $cond] && [string m $args if*]} {
	    var cond [list [list getvalue [range $args 1 end]]]
    	}
    }
    #
    # Use this strange construct to deal with $cond being the empty list (i.e.
    # the breakpoint is unconditional, since "brk" interprets any argument,
    # even if it's empty, as a command to be executed.
    #
    if {[null [index $a 0]]} {
    	return [eval [concat brk [index $a 1] $cond]]
    } else {
    	return [eval [concat brk ^h[handle id [index $a 0]]:[index $a 1] $cond]]
    }
}]
	    	
##############################################################################
#				ecbrk
##############################################################################
#
# SYNOPSIS: 	Set a memory-conditional breakpoint "everywhere" that it
#		might be useful to do so.
# PASS:		args	= arguments for cbrk (usually "(<addr>)<op><value"
#			  to set the condition based on the value of a
#			  memory location.
# CALLED BY:	Guess
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 1/92		Initial Revision
#
##############################################################################
[defsubr ecbrk {args}
{
    #
    # Set the same conditional breakpoint at the given addresses
    #
    foreach a {
	    ProcCallModuleRoutine
	    PCMR_ret
	    ResourceCallInt
	    RCI_ret
	    ProcCallFixedOrMovable
	    CallFixed
    } {
	eval [concat cbrk $a $args]
    }
}]

