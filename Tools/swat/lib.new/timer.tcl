##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	timer.tcl
# AUTHOR: 	Tony, Oct 31, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	twalk			print out all timers
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	10/29/90	Initial Revision
#
# DESCRIPTION:
#	Functions for examining timer stuff
#
#	$Id: timer.tcl,v 1.31.4.1 97/03/29 11:27:22 canavese Exp $
#
###############################################################################



##############################################################################
#				ptimer
##############################################################################
#
# SYNOPSIS:	Print out a timer given its handle
# PASS:		han 	= timer handle
#   	    	total	= ticks until timer fires, if known (passed by twalk)
# CALLED BY:	user, twalk, phandle
# RETURN:	nothing
# SIDE EFFECTS:	output, of course
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/ 7/92		Initial Revision
#
##############################################################################
[defcommand ptimer {han {total {}}} system.timer
{Usage:
    ptimer <handle>

Examples:
    "ptimer bx"	    	Print out information about the timer whose handle
    	    	    	is in BX

Synopsis:
    Prints out information about a timer registered with the system: when it
    will fire, what it will do when it fires, etc.

Notes:
    * <handle> may be a variable, register, or constant.

See also:
    twalk, phandle.
}
{
    # Deal with registers, variables, etc.
    var han [getvalue $han]

    # Fetch the whole structure at once.
    var timer [value fetch kdata:$han HandleTimer]

    var ty [type emap [field $timer HTI_type]
		[if {[not-1x-branch]}
		    {sym find type TimerType}
		    {sym find type TimerTypes}]]
    echo
    echo [format {Timer handle: %04xh -- %s} $han $ty]
    #
    # Print time until timer fires.
    #
    if {[string match $ty TIMER_*_REAL_TIME] == 0} {
	echo -n [format {    time remaining = }]
	if {[string compare $total noTotal] == 0} {
	    var total [value fetch kdata:$han.HTI_timeRemaining]
	} elif {[null $total]} {
	    # Need to sum the times of the timers before this one in the list
	    # to obtain the time remaining for this one.
	    var total 0
	    [for {var h [value fetch timeListPtr]}
		 {$h != 0 && $h != $han}
		 {var h [value fetch kdata:$h.HTI_next]}
	    {
		var total [expr $total+[value fetch kdata:$h.HTI_timeRemaining]]
	    }]
	    if {$h == 0} {
		error [format {Handle %04xh is not on the active-timer list} $han]
	    }
	    var total [expr $total+[value fetch kdata:$han.HTI_timeRemaining]]
	}
	print-time $total 1
	if {![string c $ty TIMER_MS_ROUTINE_ONE_SHOT]} {
	    echo [format {, %d units} [field $timer HTI_method]]
	} else {
	    echo
	}
    }
    
    #
    # Say who owns the timer.
    #
    var own [field $timer HTI_owner]
    var odhigh [expr ([field $timer HTI_OD]>>16)&0xffff]
    var odlow [expr [field $timer HTI_OD]&0xffff]
    var ownhan [handle lookup $own]
    echo [format {    owner = %s (%04xh)}
	    [if {[null $ownhan]}
		{format {?}}
		{patient name [handle patient $ownhan]}] $own]

    #
    # Print out data specific to the type of timer.
    #
    [case $ty in
	TIMER_EVENT_* {
	    echo -n {    destination = }
	    [print-obj-and-method $odhigh $odlow {}
		[field $timer HTI_method]]
	    if {![string c $ty TIMER_EVENT_ONE_SHOT]} {
		echo [format {    ID = %04xh}
				[field $timer HTI_intervalOrID]]
	    } elif {![string c $ty TIMER_EVENT_REAL_TIME]} {
	    	var date [field $timer HTI_timeRemaining]
		echo [format {    date = %2d/%2d/%4d %02d:%02d}
			[expr ($date>>5)&0xf] [expr $date&0x1f]
			[expr (($date>>9)&0x7f)+1980]
			[expr [field $timer HTI_intervalOrID]>>8]
			[expr [field $timer HTI_intervalOrID]&0xff]]
	    } else {
		echo -n [format {    interval = }]
		print-time [field $timer HTI_intervalOrID]
	    }
	}
	{TIMER_ROUTINE_* TIMER_MS_ROUTINE_ONE_SHOT} {
	    var dest [sym faddr proc $odhigh:$odlow]
	    if {[null $dest]} {
		var dest {unknown}
	    } else {
		var dest [sym fullname $dest]
	    }
	    echo [format {    destination = %04xh:%04xh, %s}
				$odhigh $odlow $dest]

	    if {![string c $ty TIMER_MS_ROUTINE_ONE_SHOT]} {
		echo [format {    data = %04xh}
				[field $timer HTI_intervalOrID]]
	    } else {
		echo [format {    data = %04xh}
				[field $timer HTI_method]]
	    }
	    if {![string c $ty TIMER_ROUTINE_ONE_SHOT]} {
		echo [format {    ID = %04xh}
				[field $timer HTI_intervalOrID]]
	    } elif {![string c $ty TIMER_ROUTINE_CONTINUAL]} {
		echo -n [format {    interval = }]
		print-time [field $timer HTI_intervalOrID]
	    } elif {![string c $ty TIMER_ROUTINE_REAL_TIME]} {
	    	var date [field $timer HTI_timeRemaining]
		echo [format {    date = %2d/%2d/%4d %02d:%02d}
			[expr ($date>>5)&0xf] [expr $date&0x1f]
			[expr (($date>>9)&0x7f)+1980]
			[expr [field $timer HTI_intervalOrID]>>8]
			[expr [field $timer HTI_intervalOrID]&0xff]]
	    }
	}
	{TIMER_SLEEP TIMER_SEMAPHORE} {
	    var queue [field $timer HTI_method]
	    if {$queue == 0} {
		echo {    No thread blocked}
	    } else {
		var qhan [handle lookup $queue]
		var own [patient name [handle patient $qhan]]
		var num [thread number [handle other $qhan]]
		echo [format {    Blocked thread is %04xh (%s:%d)}
		    $queue $own $num]
	    }
	    if {![string c $ty TIMER_SEMAPHORE]} {
	    	[if {$odhigh == [handle segment [handle find kdata:0]] &&
		     $odlow >= [value fetch geos::loaderVars.KLV_handleTableStart]}
    	    	{
		    var dest [format {^h%04xh} [expr $odlow&~0xf]]
    	    	} else {
		    var dest [sym faddr var $odhigh:$odlow]
		    if {[null $dest]} {
			var dest {unknown}
		    } else {
			var dest [sym fullname $dest]
		    }
    	    	}]
		echo [format {    semaphore = %04xh:%04xh, %s}
			    $odhigh $odlow $dest]
	    }
	}
    ]
}]

[defcmd twalk {{args {}}} system.timer
{Usage:
    twalk [flags]

Examples:
    "twalk" 	    	print all the timers in the system.
    "twalk -o ui" 	print all the timers in the system for the ui thread.
    "twalk -a"	 	print all the timers with the "real" data for the
			time for time remaining rather than maintaining a
			total.

Synopsis:
    List all the timers currently active in GEOS.

}
{
    #
    # Parse the flags
    #
    var ownername {}
    var skipTotal 0
    var timersFound false

    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		o {
		    var ownername [index $args 1]
		    var args [cdr $args]	
		}
		a {
		    var skipTotal 1
		}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }

    #
    # Gave an owner whose handles are to be printed. Figure out if it's
    # a handle ID or a patient name and set owner to the decimal equiv
    # of the handle ID.
    #
    var owner 0
    var h [handle lookup $ownername]
    if {![null $h] && $h != 0} {
	var owner [handle id $h]
    } else {
	var owner [handle id
		[index [patient resources
				[patient find $ownername]] 0]]
    }

    var han [value fetch timeListPtr]
    if {$han != 0} {
	var timersFound true
    	var total 0
    	while {$han != 0} {
	    var timer [value fetch kdata:$han HandleTimer]
    	    var total [expr $total+[field $timer HTI_timeRemaining]]

	    if {($owner == 0) || ($owner == [field $timer HTI_owner])} {
		if {$skipTotal} {
	    	    ptimer $han noTotal
		} else {
	    	    ptimer $han $total
		}
    	    }
    	    var han [value fetch kdata:$han.HTI_next]
    	}
    }
    var han [value fetch realTimeListPtr]
    if {$han != 0} {
	var timersFound true
    	var total 0
    	while {$han != 0} {
	    var timer [value fetch kdata:$han HandleTimer]
    	    var total [expr $total+[field $timer HTI_timeRemaining]]

	    if {($owner == 0) || ($owner == [field $timer HTI_owner])} {
		if {$skipTotal} {
	    	    ptimer $han noTotal
		} else {
	    	    ptimer $han $total
		}
    	    }
    	    var han [value fetch kdata:$han.HTI_next]
    	}
    }
    if {$timersFound == false} {
    	echo {There are no timers active in the system}
    }
    echo
}]

[defsubr print-time {ticks {nolf 0}} {
    var min [expr $ticks/3600]
    var ticks [expr $ticks-($min*3600)]
    var sec [expr $ticks/60]
    var ticks [expr $ticks-($sec*60)]
    echo -n [format {%d %s, %d %s, %d %s}
    	    $min [pluralize minute $min]
    	    $sec [pluralize second $sec]
	    $ticks [pluralize tick $ticks]]
    if {!$nolf} {
    	echo
    }
}]

##############################################################################
#				time-log
##############################################################################
#
# SYNOPSIS:	    Print out the log of timer-related actions recorded by
#   	    	    the kernel when TEST_TIMER_CODE is defined in the kernel.
# PASS:		    nothing
# RETURN:	    nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 1/92		Initial Revision
#
##############################################################################
[defsubr time-log {}
{
    echo Smallest unmangled count: [value fetch minTotalToSet]
    echo Largest unmangled count: [value fetch maxTotalToSet]

    echo Smallest mangled count: [value fetch minNetToSet]
    echo Largest mangled count: [value fetch maxNetToSet]

    echo Total units added: [value fetch totalUnitsAdded]
    echo Total units "lost": [value fetch totalUnitsLost]
    echo Number of wraps: [value fetch numWraps]

    var timerLog [symbol find var geos::timerLog]

    if {[null $timerLog]} {
    	error {timer test code was not compiled into the kernel}
    }

    var timerLogSize	[type size [index [symbol get $timerLog] 2]]
    var TimerLog 	[symbol find type geos::TimerLog]
    var TimerLogSize	[type size $TimerLog]
    
    var base [index [symbol get $timerLog] 0]
    var limit [expr $base+$timerLogSize]

    #
    # Get a pointer to the first entry to display. It is the entry which
    # falls right before the next entry to deposit. If we go back before
    # the start of the buffer, we need to wrap to the bottom
    #
    var	end [value fetch geos::timerLogPtr]
    var cur [expr $end-$TimerLogSize]
    if {$cur < $base} {
	var cur $limit-$TimerLogSize
    }
    var n 0

    do {
    	var entry [value fetch kdata:$cur $TimerLog]
	var t	  [type emap [field $entry TL_type] [sym find type TimerType]]
	var v	  [field $entry TL_count]
	var f     [field $entry TL_flag]
	var d	  [field $entry TL_data]
	var l	  [field $entry TL_level]

	echo -n [format {%-4d:(%-5d:%-2d) %-20s} $n $v $l [range $t 6 end char]]

	if {$f} {
		echo MSEC TIMER INTERRUPT
	} else {
		echo
	}
	echo -n {                }

	var n [expr $n+1]

	[case $t
	    {TIMER_ROUTINE_ONE_SHOT TIMER_ROUTINE_CONTINUAL 
		TIMER_EVENT_CONTINUAL TIMER_EVENT_ONE_SHOT} {
		echo -n [format {Reprogram value: %5d} $d]
	    }

	    TIMER_MS_ROUTINE_ONE_SHOT {
		echo -n [format {Reprogram value: %5d} $d]
	    }

	    TIMER_MS_INTERRUPT {
		echo -n [format {Current units lost: %5d} $d]
	    }

	    TIMER_TB_INTERRUPT {
		echo -n [format {Units lost on last interrupt: %5d} $d]
	    }

	    TIMER_RESET_TB {
		echo -n [format {Change back to 60Hz: %5d} $d]
	    }

	    TIMER_MS_CALL {
		echo -n [format {Begin MS Routine, Timer Handle: ^h%04xh} $d]
	    }

	    TIMER_MS_RETURN {
		echo -n [format {End MS Routine, Timer Handle: ^h%04xh} $d]
	    }

	    TIMER_MS_CREATE {
		echo -n [format {Add MS Timer, Timer Handle: ^h%04xh} $d]
	    }

	    TIMER_RT_CALL {
		echo -n [format {Begin Tick-Timer, Timer Handle: ^h%04xh} $d]
	    }

	    TIMER_RT_RETURN {
		echo -n [format {End Tick-Timer, Timer Handle: ^h%04xh} $d]
	    }

	    TIMER_MSG_CALL {
		echo -n [format {Begin Message, Timer Handle: ^h%04xh} $d]
	    }

	    TIMER_MSG_RETURN {
		echo -n [format {End Message, Timer Handle: ^h%04xh} $d]
	    }

	    TIMER_OTHER_CREATE {
		echo -n [format {Add Non-MS Timer, Timer Handle:  ^h%04xh} $d]
	    }

	    TIMER_ENTER {
		echo -n Enter Interrupt routine
	    }

	    TIMER_LEAVE {
		echo -n Exit Interrupt Routine
	    }

	    TIMER_HAND_OFF {
		echo -n Allow previous timer routine to execute
	    }

	    TIMER_SEMAPHORE {
		echo -n Semaphore timed block
	    }

	    TIMER_SLEEP {
		echo -n Sleeping on a non-semaphore timer
	    }

	    default {
		echo -n [format {Help me Spock (%d,%d)} $t $d]
	    }
    	]
	echo
	var cur [expr $cur-$TimerLogSize]
	if {$cur < $base} {
	    var cur $limit-$TimerLogSize
    	}
    } while {$cur != $end}
}]




