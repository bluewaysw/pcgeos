##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	timebrk.tcl
# FILE: 	timebrk.tcl
# AUTHOR: 	Adam de Boor, April 17, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/17/92		Initial Revision
#
# DESCRIPTION:
#	Commands to implement timing breakpoints. Stolen wholesale from
#   	the tbrk implementation, which this thing closely resembles.
#
#	$Id: timebrk.tcl,v 1.6.11.1 97/03/29 11:27:00 canavese Exp $
#
###############################################################################

#
# Table of known timing breakpoints. We use the level-2 bpt support in
# bptutils and store only the list of address expressions, for where timing
# should stop, for each breakpoint. If an element of the list is null, it
# means timing should stop when the routine returns.
#
# The value returned from our set callback is the stub's breakpoint number
# for the thing.
#
defvar timebrks nil

require bpt-init bptutils

defvar timebrk-token [bpt-init timebrks timebrk maxtimebrk 
       	    	    	timebrk-set-callback timebrk-unset-callback]

##############################################################################
#				timebrk-unset-callback
##############################################################################
#
# SYNOPSIS:	    Tell the stub to get rid of a timebrk
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
[defsubr timebrk-unset-callback {bnum stubnum data alist why}
{
    if {$why == exit} {
    	rpc call RPC_CLEARTIMEBRK [type word] $stubnum [type void]
	return 1
    } else {
    	return 0
    }
}]

##############################################################################
#				timebrk-generate-end-list
##############################################################################
#
# SYNOPSIS:	Generate the list of words that specify where timing should
#		stop for a breakpoint.
# PASS:		end = list of address expressions where timing should stop.
#		      if one is null, timing will stop when the procedure
#		      returns.
#   	    	cs  = segment where starting bpt is being placed
#   	    	ip  = offset in cs where starting bpt is being placed
# CALLED BY:	timebrk-set
# RETURN:	list of words suitable for passing to rpc call
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/16/92	Initial Revision
#
##############################################################################
[defsubr timebrk-generate-end-list {end cs ip}
{
    var l [map e $end {
    	#
	# Figure the handle & offset of the ending breakpoint. If no ending
	# point specified, timing runs to the completion of the procedure in
	# which the breakpoint is set.
	#
    	if {[null $e]} {
    	    #
	    # Time until completion. Stub needs to know whether procedure is
	    # near or far. We pass the ending handle as 0, and the ending
	    # offset as non-zero if the procedure is far...
	    #
	    var endHandle 0
	    var proc [symbol faddr proc $cs:$ip]
	    [case [index [symbol get $proc] 1] in
	     near {var endIP 0}
	     far {var endIP 1}]
    	} else {
    	    #
	    # End-point defined, so parse it down to its handle and offset
	    #
    	    var enda [addr-parse $e]
	    var endIP [index $enda 1] endHandle [handle id [index $enda 0]]
    	}
	list $endIP $endHandle
    }]
    
    #
    # Mush all those sublists into one big happy list.
    #
    return [eval [concat concat $l]]
}]

##############################################################################
#				timebrk-set-callback
##############################################################################
#
# SYNOPSIS:	    Set the timing breakpoint in the stub.
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
[defsubr timebrk-set-callback {bnum stubnum data alist why}
{
    if {$why == start} {
    	#
	# Call the stub, passing it the offset and segment (in that order)
	# at which the timebrk should be set, expecting to get a word back
	# (the stub's breakpoint number)
	#

    	var han [index $alist 0]    	
    	var t [type make array [expr 3+[length $data]*2] [type word]]
	var ip [index $alist 1]
    
    	# if its an XIP handle, we must get the ID not the segment
    	var xipPage [handle xippage $han]
    	if {$xipPage != -1} {
    	    var cs [handle id $han]
    	} else {
    	    var cs [handle segment $han]
    	}

    	var args [concat [list $ip $cs $xipPage]
    	    	    [timebrk-generate-end-list $data 
    	    	    	    	    [handle segment $han] $ip]]

    	var timebrk [rpc call RPC_SETTIMEBRK $t $args [type word]]
    	type delete $t
	
    	return $timebrk
    } else {
    	return $stubnum
    }
}]

##############################################################################
#				timebrk-trim-name
##############################################################################
#
# SYNOPSIS:	Trim a symbolic address to find w/in a given bounds, nuking
#   	    	characters on the left as insignificant
# PASS:		name	= name to trim
#   	    	max 	= length to which to trim it
# CALLED BY:	timebrk
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
[defsubr timebrk-trim-name {name max}
{
    var len [length $name chars]
    
    if {$len > $max} {
    	return <[range $name [expr $len-$max+1] end chars]
    } else {
    	return $name
    }
}]

##############################################################################
#				timebrk-parse-arg
##############################################################################
#
# SYNOPSIS:	Parse an argument to the tbrk command into a list of 
#   	    	breakpoint numbers for it to process.
# PASS:		b   	= breakpoint token
# CALLED BY:	timebrk
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
[defsubr timebrk-parse-arg {b}
{
    global  timebrks timebrk-token

    if {[string match $b -p*]} {
    	var pat [range $b 2 end chars]
	
	global maxtimebrk

    	var result {}

	for {var i 0} {$i < $maxtimebrk} {var i [expr $i+1]} {
	    if {[string match [index [bpt-addr ${timebrk-token} $i] 1] $pat]} {
	    	var result [concat $result $i]
    	    }
	}
    } else {
    	var result [bpt-parse-arg $b ${timebrk-token}]
    }

    return $result
}]

##############################################################################
#				timebrk
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
[defcommand timebrk {args} {breakpoint profile swat_prog.breakpoint}
{Usage:
    timebrk <start-addr> <end-addr>+
    timebrk del <timebrk>+
    timebrk list
    timebrk time <timebrk>
    timebrk reset <timebrk>

Examples:
    "timebrk LoadResourceData -f"   	    	Calculate the time required to
						process a call to 
						LoadResourceData
    "timebrk time 2"  	    	    	    	Find the amount of time
    						accumulated for timing
						breakpoint number 2.
    "timebrk reset 2"  	    	    	    	Reset the counter for timebrk
						number 2 to 0.
    "timebrk list"	    	    	    	Print a list of the set
						timing breakpoints and their
						current counts & time.

Synopsis:
    This command manipulates breakpoints that calculate the amount of time
    executing between their starting point and a specified ending point. The
    breakpoints also record the number of times their start is hit, so you can
    figure the average amount of time per hit.
    
Notes:
    * You can specify a place at which timing should end either as an address
      or as "-f". If you use "-f", timing will continue until the finish of
      the routine at whose start you've placed the breakpoint. Such a breakpoint
      may only be set at the start of a routine, as the stub hasn't the
      wherewithal to determine what the return address is at an arbitrary
      point within the function.

    * You may specify more than one ending point. Timing will stop when
      execution reaches any of those points.

    * When you've set a timing breakpoint, you will be returned a token of the
      form "timebrk<n>", where <n> is some number. You use this token, or just
      the <n>, if you're not a program, wherever <timebrk> appears in the
      Usage description, above.

See also:
    brk, cbrk, tbrk
}
{
    global timebrks maxtimebrk timebrk-token

    [case [index $args 0] in
     {clear del delete} {
    	#
	# Clear the given timing breakpoint(s)
	#
	foreach arg [range $args 1 end] {
	    var nums [timebrk-parse-arg $arg]
	    if {[null $nums]} {
	    	echo timebrk: ${arg}: no such breakpoint defined
    	    } else {
	    	foreach b $nums {
		    bpt-unset ${timebrk-token} $b
    	    	}
    	    }
    	}
    	return
     }
     list {
  	if {![string c [index $args 1] m]} {
    	    var msec 1000
     	    echo {Num Address                          Time (sec) Count      Average (msec)}
    	} else {
    	    var msec 1
     	    echo {Num Address                          Time (sec) Count      Average}
    	}
	for {var b 0} {$b < $maxtimebrk} {var b [expr $b+1]} {
	    var addr [bpt-addr ${timebrk-token} $b]
	    if {![null $addr]} {
    	    	var a [index $addr 1]

    	    	if {[null $a]} {
    	    	    var name [format {^h%04xh:%04xh}
			      [handle id [index [index $addr 0] 0]]
		    	      [index [index $addr 0] 1]]
    	    	} else {
    	    	    var name [timebrk-trim-name $a 30]
    	    	}

		var t [timebrk time $b]
      	    	var t0 [index $t 0]
    	    	var t1 [index $t 1]
		echo [format {%3d %-30s %12.6f %5d   %10.6f} $b $name
		    	[index $t 0] [index $t 1]
			[if {$t1 != 0}
			    {expr ($t0/$t1)*$msec f}
			    {expr 0}]]
    	    }
    	}
    	return
     }
     cond {
    	error {timebrk conditions not supported yet}
    	return
     }
     time {
    	#
	# Returns 2-list: {time hits}
	# time is the total time expressed as a real-number of seconds
	#
     	var nums [timebrk-parse-arg [index $args 1]]
	if {[null $nums]} {
	    error [concat timebrk time: [index $args 1]: no such breakpoint defined]
	} elif {[length $nums] > 1} {
	    error {timebrk time: can only fetch the time for one timebrk at a time}
	}
	

    	var data [bpt-get ${timebrk-token} [index $nums 0]]
	
	if {![null [index $data 1]]} {
	    # WORD(gtbr_ticksLow)	/* Ticks */
	    # WORD(gtbr_ticksHigh)/* Ticks (cont) */
	    # WORD(gtbr_cus) 	/* Clock units (19886 per tick) */
	    # WORD(gtbr_countLow)	/* Times hit */
	    # WORD(gtbr_countHigh)/* Times hit (cont) */
	    var t [type make array 5 [type word]]
	    var d [rpc call RPC_GETTIMEBRK [type word] [index $data 1] $t]
	    type delete $t
    	    var hits [expr [index $d 3]+([index $d 4]<<16)]
	    return [list
	    	    [expr (([index $d 1]*65536.0+[index $d 0])+([index $d 2]/19886.0))/60.0 float]
		    $hits]
    	} else {
	    return {0 0}
    	}
     }
     reset {
     	foreach arg [range $args 1 end] {
	    var nums [timebrk-parse-arg $arg]
	    if {[null $nums]} {
	    	echo timebrk: ${arg}: no such breakpoint defined
    	    } else {
	    	foreach b $nums {
		    var data [bpt-get ${timebrk-token} $b]
        	    if {![null [index $data 1]]} {
	    	    	[rpc call RPC_ZEROTIMEBRK [type word] [index $data 1]
			    [type void]]
    	    	    }
    	    	}
    	    }
    	}
    	return
     }
     symbol {
     	var nums [timebrk-parse-arg [index $args 1]]
	if {[null $nums]} {
	    error [concat timebrk symbol: [index $args 1]: no such breakpoint defined]
    	} elif {[length $nums] > 1} {
	    error {timebrk symbol: can only fetch the symbol for one timebrk at a time}
    	}

    	# fetch the timebrk data list for the beast
     	var data [bpt-addr ${timebrk-token} [index $nums 0]]

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
    # Set a timing breakpoint
    #
    var b [bpt-alloc-number ${timebrk-token}]

    var a [addr-parse [index $args 0]]

    var end [map e [range $args 1 end] {
    	if {[string c $e -f] != 0} {
    	    bpt-addr-list-to-addr-expr [addr-parse $e]
    	}
    }]
    
    # XXX: HANDLE BREAKPOINT CONDITIONS AGAIN
    
    if {[bpt-set ${timebrk-token} $b $end $a]} {
    	return timebrk$b
    }
}]
