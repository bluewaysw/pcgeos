##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- Timer Profile
# FILE: 	timer-profile.tcl
# AUTHOR: 	Doug Fults, Apr 14, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	timer-profile 	       	print results of timer profile buffer
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	4/14/92		Initial Revision
#
# DESCRIPTION:
#	Functions for summarizing the contents of the kernel's
#	timerProfileBuffer, which contains handle+offset pairs indicating the
#	location of the instruction pointer at each timer interrupt over
#	the last 34 seconds (for a 2048 entry table)
#
#	$Id: timeprof.tcl,v 1.6.11.1 97/03/29 11:28:05 canavese Exp $
#
###############################################################################

[defsubr timer-profile-new {args}
{
    [value store timerProfileOffset 0]
    [value store timerProfileIdle 0]
    [value store timerProfileHeap 0]
    [value store timerProfileBIOS 0]
    [value store timerProfileTotal 0]

    if {![string compare [index $args 0] pcgeos] } {
        value store timerProfileGeode -1
    } elif {[null [index $args 0]]} {
        value store timerProfileGeode 0
    } else {
	var geodeHandle [handle id
		[index [patient resources [patient find [index $args 0]]] 0]]
        value store timerProfileGeode $geodeHandle [type word]
    }

    var size [getvalue {sizeof(timerProfileBuffer)/sizeof(timerProfileBuffer[0])}]
    for {var n 0} {$n < $size} {var n [expr $n+1]} {
	value store {timerProfileBuffer[$n]} 0
    }

}]


[defsubr timer-profile-routine {args}
{
    echo {ROUTINE                                    COUNT        %    SECONDS}
    var routineList {}
    [for {var n 0} {$n < 2048} {var n [expr $n+1]} {
	    var han  [value fetch {timerProfileBuffer[$n].handle}]
	    var off  [value fetch {timerProfileBuffer[$n].offset}]
	    if {$han == 65535} {
		var routineList [concat $routineList
		    [format {%04xh:????} $off]
		]
	    } elif {$han} {
		var calls [sym faddr func {^h$han:$off}]
		if {[null $calls]} {
		    var calls {UNKNOWN}
		} else {
		    var calls [sym fullname $calls]
		}
		var routineList [concat $routineList $calls]
	    }
    }]
    var routineList [sort $routineList]
    var total [length $routineList]

    var reportList {}
    var curRoutine [index $routineList 0]
    var count 0
    foreach i $routineList {
	if {![string compare $curRoutine $i]} {
	    var count [expr $count+1]
	} else {
	    var reportList [concat $reportList [list [list $count $curRoutine ]]]
	    var curRoutine $i
	    var count 1
	}
    }
    var reportList [concat $reportList [list [list $count $curRoutine]]]
    var reportList [sort -rn $reportList]

    var misc 0
    foreach i $reportList {
	if {[index $i 0] > [expr $total/500] } {
	    echo [format {%-42s %5d    %3.1f       %3.1f}
		[index $i 1]
		[index $i 0]
		[expr 100*[index $i 0]/$total float]
		[expr [index $i 0]/60 float]
	    ]
	} else {
	    var misc [expr $misc+[index $i 0]]
	}
    }
    if {$misc > 0} {
      echo [format {%-42s %5d    %3.1f       %3.1f}
	  Miscellaneous
	  $misc
	  [expr 100*$misc/$total float]
	  [expr $misc/60 float]
      ]
    }
    echo [format
	{TOTAL:                                     %5d    %3.1f      %3.1f}
	$total
	100.0
	[expr $total/60 float]
    ]

    var profIdle [value fetch timerProfileIdle]
    var profHeap [value fetch timerProfileHeap]
    var profBIOS [value fetch timerProfileBIOS]
    var profTotal [value fetch timerProfileTotal]
    if {$profTotal > 0} {
      echo {}
      echo [format
	  {Time since last "new": %d ticks (%.1f seconds)}
	  $profTotal [expr $profTotal/60 float]
      ]
      echo [format
	  { - Idle: %d ticks (%.1f seconds) \[excluded from routine breakdown and totals\]}
  	  $profIdle [expr $profIdle/60 float]
      ]
      if {$profTotal > $profIdle} {
        echo [format
	    { - Heap semaphore: %d ticks (%.1f seconds, %.1f%%)}
  	    $profHeap [expr $profHeap/60 float] [expr $profHeap*100/($profTotal-$profIdle) float]
        ]
        echo [format
	    { - DOS/BIOS semaphore: %d ticks (%.1f seconds, %.1f%%) \[outside of heap\]}
  	    $profBIOS [expr $profBIOS/60 float] [expr $profBIOS*100/($profTotal-$profIdle) float]
        ]
      }
      echo {}
    }
}]


[defsubr timer-profile-resource {args}
{
    echo {HID    OWNER                          COUNT        %    SECONDS}
    var handleList {}
    [for {var n 0} {$n < 2048} {var n [expr $n+1]} {
	    var han  [value fetch {timerProfileBuffer[$n].handle}]
	    var off  [value fetch {timerProfileBuffer[$n].offset}]
	    if {$han == 65535} {
		var handleList [concat $handleList 0$off]
	    } elif {$han} {
		var handleList [concat $handleList $han]
	    }
    }]
    var handleList [sort $handleList]
    var total [length $handleList]

    var reportList {}
    var curHan [index $handleList 0]
    var count 0
    foreach i $handleList {
	if {![string compare $curHan $i]} {
		var count [expr $count+1]
	} else {
	    var reportList [concat $reportList [list [list $count $curHan]]]
	    var curHan $i
	    var count 1
	}
    }
    var reportList [concat $reportList [list [list $count $curHan]]]
    var reportList [sort -rn $reportList]

    var misc 0
    foreach i $reportList {
	if {[index $i 0] > [expr $total/500] } {
	    if {([index [explode [index $i 1]] 0] == 0)} {
		var num {}
		foreach m [explode [index $i 1]] {
		    if {$m >=1 || !($num == {} )} {var num $num$m}
		}
		if {$num == {}} {var num 0}
		echo [format {%04xh:????  %-25s %5d    %3.1f     %3.1f}
		    $num
		    {}
		    [index $i 0]
		    [expr 100*[index $i 0]/$total float]
		    [expr [index $i 0]/60 float]
		]
	    } else {
	        var handle [handle lookup [index $i 1]]
	        if {![null $handle]} {
	    	    var state [handle state $handle]
	    	    if {[handle ismem $handle]} {
    	                var n [patient name [handle patient $handle]]
    	                if {[null $args] || ![null [assoc $args $n]]} {
		   	    echo [format {%04xh  %-30s %5d    %3.1f     %3.1f}
			        [index $i 1]
			        [if {$state&0x80 || [handle iskernel $handle]} {
			            [format {%s::%s} $n
				        [symbol name [handle other $handle]]]
			        } else {
			            [patient name [handle patient $handle]]
			        }]
			        [index $i 0]
			        [expr 100*[index $i 0]/$total float]
			        [expr [index $i 0]/60 float]
		    	    ]
		        }
	            }
    	        }
	    }
	} else {
	    var misc [expr $misc+[index $i 0]]
	}
    }
    echo [format {%-37s %5d    %3.1f     %3.1f}
	Miscellaneous
	$misc
	[expr 100*$misc/$total float]
	[expr $misc/60 float]
    ]
    echo [format
	{TOTAL:                                %5d    %3.1f    %3.1f}
	$total
	100.0
	[expr $total/60 float]
    ]
}]


[defcommand timer-profile {args} profile
{Usage:
    timer-profile new [<geode>]	resets timer profile buffer to start collecting
    	    	    	    	a new set of data.
    timer-profile routine   	summarizes profile data by routine
    timer-profile resource  	summarizes profile data by resource

Examples:
    "timer-profile new desktop"	collects data for the geode named "desktop"
				only.
    "timer-profile new pcgeos"	collects data for all routines within PC/GEOS,
    	    	    	    	but not for anything in DOS, BIOS, etc.
    "timer-profile new"	    	collects data for routines everywhere.
    "timer-profile routine" 	prints the collected information sorted by
    	    	    	    	individual routines

Synopsis:
    Manages & prints analysis of the Kernel's Timer Profile Buffer.

Notes:
    * You must have downloaded a "TIMER_PROFILE" version of the kernel
      in order to be able to use this TCL function.  The "TIMER_PROFILE"
      version may be created by changing the TIMER_PROFILE constant in
      kernelConstant.def to TRUE, & recompiling.

    * "new" option clears out the contents of the kernel's timerProfileBuffer,
       and clears the timerProfileOffset, which indicates where the next
       timer interrupt's worth of data should be stored.  Any "geode" handle
       passed is stored in timerProfileGeode.  Once timer interrupts flow
       again (when "continue" is activated), the buffer will be added to
       at each interrupt, if the specified criteria is met.

    * "result", "resource" options use TCL funtions to tally the information
       present in the timerProfileBuffer, for printing out.  The buffer is
       not modified in any way.  Only those routines/resorces which were
       detected running more than .2% of the time are printed out.

    * PC-SDK: To use this command, you must run the non-error-checking
      version of Geos (GEOSNC) and select "GEOS Profiling Kernel - Timer"
      via the Debug application.

See also:
}
{
    ensure-swat-attached

    if {[null $args]} {var args routine}

    [case [index $args 0] in
	new { timer-profile-new [index $args 1] }
        reset { timer-profile-new [index $args 1] }
	routine { timer-profile-routine }
	resource { timer-profile-resource }
    ]

}]
