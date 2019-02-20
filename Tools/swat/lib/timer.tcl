##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#	Functions for examining video stuff
#
#	$Id: timer.tcl,v 1.3 90/12/04 13:37:50 tony Exp $
#
###############################################################################

[defcommand sbwalk {{pat {}}} kernel
{Prints all saved blocks in the system}
{
    if {[null $pat]} {
    	var pat [index [patient data] 0]
    }
    var pid [patient find $pat]
    var core [handle segment [index [patient resources $pid] 0]]
    var han [value fetch $core:PH_savedBlockPtr]

    if {$han == 0} {
    	echo {There are no saved blocks for $pat}
    } else {
    	while {$han != 0} {
    	    echo -n [format {(%04xh) -- } $han]
    	    print HandleSavedBlock kdata:$han
    	    var han [value fetch kdata:$han.HSB_next]
    	}
    }
}]

##################

[defcommand oldtwalk {} kernel
{Prints all timers in the system}
{
    var han [value fetch timeListPtr]
    if {$han == 0} {
    	echo {There are no timers active in the system}
    } else {
    	echo [format {Time to next fire: %d} [value fetch timeToNextFire]]
    	while {$han != 0} {
    	    var timer [value fetch kdata:$han HandleTimer]
    	    echo -n [format {(%04xh) -- } $han]
    	    print HandleTimer kdata:$han
    	    var han [value fetch kdata:$han.HTI_next]
    	}
    }
}]

##################

[defcommand twalk {} kernel
{Prints all timers in the system}
{
    var han [value fetch timeListPtr]
    if {$han == 0} {
    	echo {There are no timers active in the system}
    } else {
    	var total [value fetch timeToNextFire]
    	var first 1
    	echo [format {Time to next fire: %d} $total]
    	while {$han != 0} {
    	    echo
    	    var timer [value fetch kdata:$han HandleTimer]
    	    var ty [type emap [field $timer HTI_type]
    	    	    	    	    	    [sym find type TimerTypes]]
    	    echo [format {Timer handle: %04xh -- %s} $han $ty]
    	    if {$first == 1} {
    	    	var first 0
    	    } else {
    	    	var total [expr $total+[field $timer HTI_timeRemaining]]
    	    }
    	    echo -n [format {    time remaining = }]
    	    print-time $total
    	    var own [field $timer HTI_owner]
    	    var odhigh [expr [field $timer HTI_OD]>>16]
    	    var odlow [expr [field $timer HTI_OD]&0xffff]
    	    echo [format {    owner = %s (%04xh)}
    	    	[patient name [handle patient [handle lookup $own]]] $own]
    	    [case $ty in
    	    	TIMER_EVENT_* {
    	    	    if {$own == $odhigh} {
    	    	    	var resOff [value fetch ^h$own:GH_resHandleOff]
    	    	    	var stack [value fetch ^h$own:$resOff+2 word]
    	    	    	var class [sym faddr var *(^h$stack:TPD_classPointer)]
    	    	    } else {
    	    	    	var class [sym faddr var *((^l$odhigh:$odlow).MB_class)]
    	    	    }
    	    	    if {![null $class]} {
    	    	    	var class [sym fullname $class]
    	    	    }
    	    	    echo [format {    destination = ^l%04xh:%04xh, %s}
    	    	    	    	$odhigh $odlow $class]
    	    	    echo -n [format {    method = }]
    	    	    if {![null $class]} {
    	    	    	echo [format {%s}
    	    	    	    [map-method [field $timer HTI_method] $class]]
    	    	    } else {
    	    	    	echo [format {%d} [field $timer HTI_method]]
    	    	    }
    	    	    if {![string c $ty TIMER_EVENT_ONE_SHOT]} {
    	    	    	echo [format {    ID = %04xh}
    	    	    	    	    	[field $timer HTI_intervalOrID]]
    	    	    } else {
    	    	    	echo -n [format {    interval = }]
    	    	    	print-time [field $timer HTI_intervalOrID]
    	    	    }
    	    	}
    	    	TIMER_ROUTINE_* {
    	    	    var dest [sym faddr proc $odhigh:$odlow]
    	    	    if {[null $dest]} {
    	    	    	var dest {unknown}
    	    	    } else {
    	    	    	var dest [sym fullname $dest]
    	    	    }
    	    	    echo [format {    destination = %04xh:%04xh, %s}
    	    	    	    	    	$odhigh $odlow $dest]
    	    	    echo [format {    data = %04xh} [field $timer HTI_method]]
    	    	    if {![string c $ty TIMER_ROUTINE_ONE_SHOT]} {
    	    	    	echo [format {    ID = %04xh}
    	    	    	    	    	[field $timer HTI_intervalOrID]]
    	    	    } else {
    	    	    	echo -n [format {    interval = }]
    	    	    	print-time [field $timer HTI_intervalOrID]
    	    	    }
    	    	}
    	    	TIMER_SLEEP|TIMER_SEMAPHORE {
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
    	    	    	var dest [sym faddr var $odhigh:$odlow]
    	    	    	if {[null $dest]} {
    	    	    	    var dest {unknown}
    	    	    	} else {
    	    	    	    var dest [sym fullname $dest]
    	    	    	}
    	    	    	echo [format {    semaphore = %04xh:%04xh, %s}
    	    	    	    	    $odhigh $odlow $dest]
    	    	    }
    	    	}
    	    ]
    	    var han [value fetch kdata:$han.HTI_next]
    	}
    }
    echo
}]

[defsubr print-time ticks {
    var min [expr $ticks/3600]
    var ticks [expr $ticks-($min*3600)]
    var sec [expr $ticks/60]
    var ticks [expr $ticks-($sec*60)]
    echo [format {%d minutes, %d seconds, %d ticks} $min $sec $ticks]
}]
