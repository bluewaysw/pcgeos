###############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	tbrk.tcl
# FILE: 	tbrk.tcl
# AUTHOR: 	Adam de Boor, Jun 24, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/24/90		Initial Revision
#
# DESCRIPTION:
#	Commands to implement tally breakpoints.
#
#	$Id: tbrk.tcl,v 1.15.11.1 97/03/29 11:26:41 canavese Exp $
#
###############################################################################

#
# Table of known tally breakpoints. Each element is an n-list containing
#   {active/saved {addr-list where set} {stub tbrk number} {interest token}
#   	{address-expression where set}}
#
#   active/saved is an int that is 0 if the bp has been saved after the affected
#   handle was freed. {addr-list} is then empty.
#
defvar tbrks nil

require bpt-init bptutils

defvar tbrk-token [bpt-init tbrks tbrk maxtbrk 
       	    	    tbrk-set-callback tbrk-unset-callback]
       

##############################################################################
#				tbrk-unset-callback
##############################################################################
#
# SYNOPSIS:	    Tell the stub to get rid of a tbrk
# PASS:		    bnum    = number of the timebrk being nuked
#   	    	    stubnum = number from the stub's perspective
#   	    	    data    = data list for the timebrk
#   	    	    alist   = address list where the breakpoint is set
#   	    	    why	    = "exit" if we should really remove the thing,
#			      or "out" if the block just got discarded or
#			      swapped out
# CALLED BY:	    bpt utils
# RETURN:	    non-zero if breakpoint actually removed
# SIDE EFFECTS:	    stub may be called to remove the thing
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/10/91	Initial Revision
#
##############################################################################
[defsubr tbrk-unset-callback {bnum stubnum data alist why}
{
    if {$why == exit} {
    	rpc call RPC_CLEARTBREAK [type word] $stubnum [type void]
	return 1
    } else {
    	return 0
    }
}]

##############################################################################
#				tbrk-set-callback
##############################################################################
#
# SYNOPSIS:	    Set the tally breakpoint in the stub.
# PASS:		    bnum    = number of breakpoint to set
#   	    	    stubnum = value returned from previous call
#   	    	    data    = list of ending addresses
#   	    	    alist   = address list where bpt is set
#   	    	    why	    = "start" if patient just starting or bpt
#			      never been set before. "in" if block
#			      just came in from executable or swap.
# CALLED BY:	    bpt utils
# RETURN:	    value to pass to unset callback (the stub's number
#		    for the bpt)
# SIDE EFFECTS:	    the stub is called if "start", else nothing
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/16/92		Initial Revision
#
##############################################################################
[defsubr tbrk-set-callback {bnum stubnum data alist why}
{
    if {$why == start} {
    	#
	# Call the stub, passing it the offset and segment (in that order)
	# at which the tbrk should be set, expecting to get a word back
	# (the stub's breakpoint number)
	#
    	var t [type make array 2 [type word]]
	if {[null [index $alist 0]]} {
	    var ip [expr [index $alist 1]&0xf] cs [expr [index $alist 1]>>4]
    	} else {
	    var ip [index $alist 1] cs [handle segment [index $alist 0]]
    	}
    	var tbrk [rpc call RPC_SETTBREAK $t [list $ip $cs] [type word]]
    	type delete $t
	
    	return $tbrk
    } else {
    	return $stubnum
    }
}]

##############################################################################
#				tbrk-trim-name
##############################################################################
#
# SYNOPSIS:	Trim a symbolic address to find w/in a given bounds, nuking
#   	    	characters on the left as insignificant
# PASS:		name	= name to trim
#   	    	max 	= length to which to trim it
# CALLED BY:	tbrk
# RETURN:	the trimmed name
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/24/90		Initial Revision
#
##############################################################################
[defsubr tbrk-trim-name {name max}
{
    var len [length $name chars]
    
    if {$len > $max} {
    	return <[range $name [expr $len-$max+1] end chars]
    } else {
    	return $name
    }
}]

##############################################################################
#				tbrk-parse-arg
##############################################################################
#
# SYNOPSIS:	Parse an argument to the tbrk command into a list of 
#   	    	breakpoint numbers for it to process.
# PASS:		b   	= breakpoint token
# CALLED BY:	tbrk
# RETURN:	list of numbers; empty if no such breakpoint defined
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/24/90		Initial Revision
#
##############################################################################
[defsubr tbrk-parse-arg {b}
{
    global  tbrks tbrk-token

    if {[string match $b -p*]} {
    	var pat [range $b 2 end chars]
	
	global maxtbrk

    	var result {}

	for {var i 0} {$i < $maxtbrk} {var i [expr $i+1]} {
	    var data [table lookup $tbrks $i]
	    if {![null $data] && [string match [index $data 4] $pat]} {
	    	var result [concat $result $i]
    	    }
	}
    } else {
    	var result [bpt-parse-arg $b ${tbrk-token}]
    }

    return $result
}]

##############################################################################
#				tbrk
##############################################################################
#
# SYNOPSIS:	    Interface command for setting tally breakpoints
# PASS:		    cmd	    = subcommand
#   	    	    args    = extra args for the command
# CALLED BY:	    user
# RETURN:	    varies
# SIDE EFFECTS:	    varies
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/24/90		Initial Revision
#
##############################################################################
[defcmd tbrk {args} {top.breakpoint profile swat_prog.breakpoint}
{Usage:
    tbrk <addr> <condition>*
    tbrk del <tbrk>+
    tbrk list
    tbrk cond <tbrk> <condition>*
    tbrk count <tbrk>
    tbrk reset <tbrk>
    tbrk address <tbrk>

Examples:
    "tbrk ObjCallMethodTable ax=MSG_VIS_DRAW"	Count the number of times
						ObjCallMethodTable is called
						with ax being MSG_VIS_DRAW
    "tbrk count 2"  	    	    	    	Find the number of times tally
						breakpoint number 2 was hit.
    "tbrk reset 2"  	    	    	    	Reset the counter for tbrk
						number 2 to 0.
    "tbrk cond 2 ax=MSG_VIS_DRAW"    	    	Change it to count when ax
						holds MSG_VIS_DRAW
    "tbrk list"	    	    	    	    	Print a list of the set
						tally breakpoints and their
						current counts.

Synopsis:
    This command manipulates breakpoints that tally the number of times they
    are hit without stopping execution of the machine -- the breakpoint is
    noted and the machine is immediately continued. Such a breakpoint allows
    for real-time performance analysis, which is nice.

Notes:
    * If you specify one or more <condition> arguments when setting the tally
      breakpoint, only those stops that meet the conditions will be counted.

    * <condition> is exactly as defined by the "brk" command, which see.

    * When you've set a tally breakpoint, you will be returned a token of the
      form "tbrk<n>", where <n> is some number. You use this token, or just
      the <n>, if you're not a program, wherever <tbrk> appears in the
      Usage description, above.

    * There are a limited number of tally breakpoints supported by the stub.
      You'll know when you've set too many.

    * "tbrk address" returns the address at which the tbrk was set, as a
      symbolic address expression.

See also:
    brk, cbrk
}
{
    global tbrks maxtbrk tbrk-token

    [case [index $args 0] in
     {clear del delete} {
    	#
	# Clear the given tally breakpoint(s)
	#
	foreach arg [range $args 1 end] {
	    var nums [tbrk-parse-arg $arg]
	    if {[null $nums]} {
	    	echo tbrk: ${arg}: no such breakpoint defined
    	    } else {
	    	foreach b $nums {
		    bpt-unset ${tbrk-token} $b
    	    	}
    	    }
    	}
    	return
     }
     list {
     	echo {Num Address                        Count}
	for {var b 0} {$b < $maxtbrk} {var b [expr $b+1]} {
    	    var addr [bpt-addr ${tbrk-token} $b]
	    if {![null $addr]} {
    	    	var a [index $addr 1]

    	    	if {[null $a]} {
    	    	    var name [format {^h%04xh:%04xh}
		    	      [handle id [index [index $addr 0] 0]]
		    	    	[index [index $addr 0] 1]]
    	    	} else {
    	    	    var name [tbrk-trim-name $a 30]
    	    	}

		echo [format {%3d %-30s %5d} $b $name [tbrk count $b]]
    	    }
    	}
    	return
     }
     address {
     	var nums [tbrk-parse-arg [index $args 1]]
	if {[null $nums]} {
	    error [concat tbrk address: [index $args 1]: no such breakpoint defined]
    	} elif {[length $nums] > 1} {
	    error {tbrk address: can only fetch the address for one tbrk at a time}
    	}
	return [index [bpt-addr ${tbrk-token} [index $nums 0]] 1]
     }
     cond {
     	error {tbrk conditions not supported yet}
    	return
     }
     {count tally} {
     	var nums [tbrk-parse-arg [index $args 1]]
	if {[null $nums]} {
	    error [concat tbrk count: [index $args 1]: no such breakpoint defined]
	} elif {[length $nums] > 1} {
	    error {tbrk count: can only fetch the count for one tbrk at a time}
	}
	
    	var data [bpt-get ${tbrk-token} [index $nums 0]]
	
	if {![null [index $data 1]]} {
	    return [rpc call RPC_GETTBREAK [type word] [index $data 1]
	    	    	[type dword]]
    	} else {
	    return 0
    	}
     }
     reset {
     	foreach arg [range $args 1 end] {
	    var nums [tbrk-parse-arg $arg]
	    if {[null $nums]} {
	    	echo tbrk: ${arg}: no such breakpoint defined
    	    } else {
	    	foreach b $nums {
		    var data [bpt-get ${tbrk-token} $b]
        	    if {![null [index $data 1]]} {
	    	    	[rpc call RPC_ZEROTBREAK [type word] [index $data 1]
			    [type void]]
    	    	    }
    	    	}
    	    }
    	}
    	return
     }
     symbol {
     	var nums [tbrk-parse-arg [index $args 1]]
	if {[null $nums]} {
	    error [concat tbrk symbol: [index $args 1]: no such breakpoint defined]
    	} elif {[length $nums] > 1} {
	    error {tbrk symbol: can only fetch the symbol for one tbrk at a time}
    	}

    	# fetch the tbrk data list for the beast
     	var data [bpt-addr ${tbrk-token} [index $nums 0]]

    	# extract the address list of where the bpt is set
	var a [index $data 0]

	# locate the nearest label
	var s [symbol faddr {label proc}
	    	^h[handle id [index $a 0]]:[index $a 1]]

    	if {[null $s]} {
	    return {}
    	} else {
    	    # return a 2-list containing the symbol token and the offset
	    # from that symbol.
	    var d [symbol get $s]
	    return [list $s [expr [index $a 1]-[index $d 0]]]
    	}
     }
    ]
    
    #
    # Set a tally breakpoint
    #
    var b [bpt-alloc-number ${tbrk-token}]

    var a [addr-parse [index $args 0]]
    
    # XXX: HANDLE BREAKPOINT CONDITIONS AGAIN
    
    if {[bpt-set ${tbrk-token} $b {} $a]} {
    	return tbrk$b
    }
}]
