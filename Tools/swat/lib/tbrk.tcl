##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
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
#	$Id: tbrk.tcl,v 1.2 90/06/28 14:38:49 adam Exp $
#
###############################################################################

#
# Table of known tally breakpoints. Each element is a n-list containing
#   {active/saved {addr-list where set} {attached breakpoint} {interest token}}
#
#   active/saved is an int that is 0 if the bp has been saved after the affected
#   handle was freed. {addr-list} is then the name of the patient to which the
#   handle belonged.
#
defvar tbrks nil

if {[null [uplevel 0 {var tbrks}]]} {
   uplevel 0 {var tbrks [table create]}
}

#
# Event handler for noting when patients start so we can restore any inactive
# breakpoints.
#
defvar tbrk-start-event nil
if {[null [uplevel 0 {var tbrk-start-event}]]} {
   uplevel 0 {var tbrk-start-event [event handle START tbrk-patient-start]}
}

#
# Event handler for noting when we attach so we can restore any inactive
# breakpoints.
#
defvar tbrk-attach-event nil
if {[null [uplevel 0 {var tbrk-attach-event}]]} {
   uplevel 0 {var tbrk-attach-event [event handle ATTACH tbrk-attach]}
}

##############################################################################
#				tbrk-interest-proc
##############################################################################
#
# SYNOPSIS:	Handle a state change for the handle in which a tally breakpoint
#   	    	is located.
# PASS:		handle	= handle token
#   	    	what	= type of state change
#   	    	bnum	= breakpoint number given when interest registered
# CALLED BY:	handle code
# RETURN:	nothing
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
[defsubr	tbrk-interest-proc {handle what bnum}
{
    global tbrks stub_tbreaks

    
    var data [table lookup $tbrks $bnum]

    [case $what in
	free {
    	    #
	    # Mark breakpoint as inactive and remember the name of the patient
	    # to which the handle belonged.
	    #
    	    table enter $tbrks $bnum [concat 0 
	    	    	    	    	[patient name [handle patient $handle]]
					[range $data 2 end]]
    	    value store [tbrk-addr $bnum cs] [type word] 0
	}
	swapin|load|resize|move {
	    #
    	    # Alter the segment in the TBreak structure to match the block's
	    # current location.
	    #
	    [value store [tbrk-addr $bnum cs] [type word]
			[handle segment $handle]]
	    
	    #
	    # Re-enable the breakpoint if it was disabled before.
	    #
	    brk enable [index $data 2]
	}
	swapout|discard {
	    #
	    # Make sure we don't trigger falsely while the block is out.
	    #
	    value store [tbrk-addr $bnum cs] [type word] 0
	    
	    brk disable [index $data 2]
	}
    ]
}]

##############################################################################
#				tbrk-patient-start
##############################################################################
#
# SYNOPSIS:	Note the start of a patient, restoring to active duty any
#   	    	breakpoints for handles belonging to this patient that
#   	    	were biffed when their handles were freed.
# PASS:		patient	= token for patient being started
# CALLED BY:	EVENT_START, tbrk-attach
# RETURN:	EVENT_HANDLED
# SIDE EFFECTS:	breakpoint(s) may be re-installed or deleted
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/24/90		Initial Revision
#
##############################################################################
[defsubr tbrk-patient-start {patient args}
{
    global stub_numTBreaks tbrks

    for {var i 0} {$i < $stub_numTBreaks} {var i [expr $i+1]} {
    	var data [table lookup $tbrks $i]
	[if {![null $data] &&
	     [index $data 0] == 0 &&
	     [string c [patient name $patient] [index $data 1]] == 0}
    	{
    	    if {[catch {brk address [index $data 2]} addr]} {
	    	echo [format {Tally breakpoint %d deleted} $i]
		table remove $tbrks $i
    	    } else {
	    	var a [addr-parse $addr]
		var h [index $a 0]
		if {[handle state $h] & 1} {
    	    	    # Handle is resident -- pretend it just came in
		    tbrk-interest-proc $h load $i
    	    	}
    	    	# register interest in the new handle
		var ip [handle interest $h tbrk-interest-proc $i]
    	    	# enter the new list for the active bp into the table
		table enter $tbrks $i [list 1 $a [index $data 2] $ip]

    	    	# initialize the rest of the record
    	    	value store [tbrk-addr $i ip] [type word] [index $a 1]
		value store [tbrk-addr $i tally] [type word] 0
    	    	[value store [tbrk-addr $i inst] [type byte] 
    	    	    [value fetch $addr [type byte]]]
    	    }
    	}]
    }

    return EVENT_HANDLED
}]
	    
##############################################################################
#				tbrk-attach
##############################################################################
#
# SYNOPSIS:	Handle attachment to the PC, activating any inactive
#   	    	breakpoints.
# PASS:		nothing
# CALLED BY:	EVENT_ATTACH
# RETURN:	EVENT_HANDLED
# SIDE EFFECTS:	breakpoint(s) may be re-installed or deleted
#
# STRATEGY
#   	Just call tbrk-patient-start for all active patients
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/24/90		Initial Revision
#
##############################################################################
[defsubr tbrk-attach {args}
{
    foreach p [patient all] {
    	tbrk-patient-start $p
    }

    return EVENT_HANDLED
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
#				tbrk-find
##############################################################################
#
# SYNOPSIS:	Look up the data for a tally breakpoint
# PASS:		b   	= breakpoint token
#   	    	fatal	= non-zero if non-existent breakpoint is fatal and
#   	    	    	  we should generate an error instead of returning
#   	    	    	  an empty list
#   	    	bnvar	= variable in caller to be set to the breakpoint
#   	    	    	  number.
# CALLED BY:	tbrk
# RETURN:	data list
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
[defsubr tbrk-find {b fatal {bnvar {}}}
{
    global  tbrks

    if {![null $b]} {
    	if {[string match $b tbrk*]} {
	    var bn [range $b 4 end chars]
    	} else {
	    var bn $b
    	}

    	var data [table lookup $tbrks $bn]
	
	if {![null $bnvar]} {
	    uplevel 1 [format {var %s %s} $bnvar $bn]
	}
    }
    
    if {[null $data] && $fatal} {
    	error [format {tbrk: %s: no such breakpoint defined} $b]
    }
    return $data
}]

##############################################################################
#				tbrk-addr
##############################################################################
#
# SYNOPSIS:	Figure the address for a field in a tbrk record in the stub
# PASS:		b   	= breakpoint #
#   	    	field	= name of field whose address is desired
# CALLED BY:	tbrk and others
# RETURN:	address
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
[defsubr tbrk-addr {b {field base}}
{
    var off [index [assoc {{base 0} {ip 0} {cs 2} {tally 4} {inst 6}} $field] 1]
    if {[null $off]} {
    	error [format {tbrk-addr: unknown field %s} $base]
    }
    global stub_tbreaks
    return $stub_tbreaks+[expr $b*7]+$off
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
[defcommand tbrk {args} top|breakpoint|prog.breakpoint
{This command manipulates breakpoints that tally the number of times they
are hit without stopping execution of the machine -- the breakpoint is noted
and the machine is immediately continued. Such a breakpoint allows for
real-time performance analysis, which is nice.

If no subcommand is recognized, a tbrk is set at the address that must be the
first argument. A set of conditions as for "cbrk" may follow the address. Only
stops that meet the conditions will be counted. A token of the form "tbrk<n>"
is returned after the breakpoint is set. This token, or the <n> from the token,
should be used for all further manipulations of the breakpoint.

Example:
    tbrk    ObjCallMethodTable ax=METHOD_ATTACH

sets a tally breakpoint at ObjCallMethodTable to count all the times it is
called with AX containing METHOD_ATTACH.

Possible subcommands are:
    clear <tbrk>+
    del <tbrk>+
    delete <tbrk>+
    	All three forms delete one or more tbrk.

    list
    	Lists all active tbrks and gives their current counts.

    cond <tbrk> [<criteria>|none]
    	Change the conditions for a tbrk. <criteria> is as for the cbrk command.

    count <tbrk>
    tally <tbrk>
    	Both forms return the current count for the given tbrk.

    reset <tbrk>
    	Resets the tally for the given tbrk to 0.
}
{
    global tbrks stub_numTBreaks

    [case [index $args 0] in
     clear|del|delete {
    	#
	# Clear the given tally breakpoint(s)
	#
	foreach b [range $args 1 end] {
    	    var data [tbrk-find $b 0 bn]
	    if {[null $data]} {
	    	echo [format {tbrk: %s: no such breakpoint defined} $b]
    	    } else {
    	    	handle nointerest [index $data 3]
		brk delete [index $data 2]
		value store [tbrk-addr $bn cs] [type word] 0
    	    	table remove $tbrks $bn
    	    }
    	}
    	return
     }
     list {
     	echo {Num Address                        Count}
	for {var b 0} {$b < $stub_numTBreaks} {var b [expr $b+1]} {
    	    var data [table lookup $tbrks $b]
	    if {![null $data] && [index $data 0]} {
    	    	var a [index $data 1]
    	    	var name [format {^h%04xh:%04xh} [handle id [index $a 0]]
		    	    	[index $a 1]]
	    	var s [sym faddr {label proc} $name]
    	    	if {![null $s]} {
		    var off [index [sym get $s] 0]
		    var name [sym fullname $s]
		    
		    if {[index $a 1] == $off} {
		    	var name [tbrk-trim-name $name 30]
		    } else {
    	    	    	var diff +[expr [index $a 1]-$off]
		    	var name [tbrk-trim-name $name
			    	    30-[length $diff chars]]$diff
    	    	    }
    	    	}

		echo [format {%3d %-30s %5d} $b $name [tbrk count $b]]
    	    }
    	}
    	return
     }
     cond {
    	var data [tbrk-find [index $args 1] 1]

     	eval [concat brk cond [index $data 2] [range $args 2 end]]
    	return
     }
     count|tally {
    	var data [tbrk-find [index $args 1] 1 b]
	return [value fetch [tbrk-addr $b tally] word]
     }
     reset {
     	var data [tbrk-find [index $args 1] 1 b]
	value store [tbrk-addr $b tally] [type word] 0
    	return
     }
    ]
    
    #
    # Set a tally breakpoint
    #
    for {var b 0} {$b < $stub_numTBreaks} {var b [expr $b+1]} {
    	if {[null [table lookup $tbrks $b]]} {
	    break
    	}
    }
    if {$b == $stub_numTBreaks} {
    	error [format {too many tbrks set (%d max)} $stub_numTBreaks]
    }

    var a [addr-parse [index $args 0]]
    var h [index $a 0]
    
    if {![null $h]} {
    	var int [handle interest $h tbrk-interest-proc $b]
	
	var ip [index $a 1] cs [handle segment $h]
    } else {
    	var ip [expr [index $a 1]&0xf] cs [expr [index $a 1]>>4]
    }
    
    if {[length $args] > 1} {
    	var brk [eval [concat cbrk $args]]
    } else {
    	var brk [brk [index $args 0]]
    }
    
    table enter $tbrks $b [list 1 $a $brk $int]
    
    value store [tbrk-addr $b ip] [type word] $ip
    value store [tbrk-addr $b cs] [type word] $cs
    value store [tbrk-addr $b tally] [type word] 0
    [value store [tbrk-addr $b inst] [type byte] 
    	[value fetch [index $args 0] [type byte]]]

    return tbrk$b
}]
