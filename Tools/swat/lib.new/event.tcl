##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- Event-Related things
# FILE: 	event.tcl
# AUTHOR: 	Adam de Boor, Jul 13, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	elist	    	    	List events pending for a patient
#   	pevent	    	    	Print an event given a handle
#
#   	eqlist	    	    	List events given a queue handle
#   	eqfind	    	    	Find all event queues in the system
#   	erfind	    	    	Find all recorded events in the system
#
# INT  	getvalue    	    	get value of a constant, mask, enum, etc.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/13/89		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: event.tcl,v 3.31.11.1 97/03/29 11:27:19 canavese Exp $
#
###############################################################################

[defcmd elist {{pat {}}} {patient.event object.event}
{Usage:
    elist [<patient>]

Examples:
    "elist" 	    list the events for the current thread and patient 
    "elist ui"	    list the events for the last thread of the ui patient
    "elist :1"	    list the events for the first thread of the current patient
    "elist geos:2"  list the events for the second thread of the geos patient

Synopsis:
    Display all events pending for a patient.

Notes:
    * The patient argument is of the form 'patient:thread'.  Each part of 
      the patient name is optional, and if nothing is specified then the 
      current patient is listed.

See also:
    showcalls.
}
{
    var thd [string first : $pat]
    if {$thd < 0} {
    	var thd {}
    } elif {$thd == 0} {
    	var thd [range $pat 1 end char]
	var pat {}
    } else {
    	var thread [range $pat [expr $thd+1] end char]
	var pat [range $pat 0 [expr $thd-1] char]
    	var thd $thread
    }

    if {[null $pat]} {
	var pat [patient name]
    }

    #
    # Make sure patient is valid and find patient token for locating the thread
    #
    var p [patient find $pat]
    if {[null $p]} {
    	error [format {patient %s unknown} $pat]
    }
    if {[null $thd]} {
    	var thd [index [patient data $p] 2]
    }
    #
    # Now find the thread token.
    #
    var thread [mapconcat i [patient threads $p] {
    	if {[thread number $i] == $thd} {
	    var i
    	}
    }]
    if {[null $thread]} {
    	if {[null $thd]} {
            error [format {patient %s has no threads} $pat]
    	} else {
    	    error [format {patient %s has no thread #%d} $pat $thd]
    	}
    }
    var thdhan [thread id $thread]
    var queuehan [value fetch kdata:$thdhan.HT_eventQueue]

    if {$thdhan == 0 || $queuehan == 0} {
    	error [format {thread %d of %s has no associated event queue} $thd $pat]
    }

    eqlist $queuehan $pat:$thd
}]

[defcmd eqlist {queuehan {name {no one in particular}}} {patient.event object.event}
{Usage:
    eqlist <queue handle> <name>

Examples:
    "eqlist 8320 geos:2"   show the event list for geos:2

Synopsis:
    Display all events in a queue.

Notes:
    * The queue handle argument is the handle to a queue.

    * The name argument is the name of the queue.

See also:
    elist.
}
{
    global geos-release

    #
    # Special case a couple of otherwise misnamed queues
    #
    if {$queuehan == [value fetch wPtrEventQueue]} {
        var name {window pointer events}
    } elif {$queuehan == [value fetch wPtrSendQueue]} {
        var name {window send events}
    }
    #
    # We need this a lot... (use the kernel's internal structure for an event)
    #
    var et [sym find type HandleEvent]
    #
    # Fetch the queue
    #
    var queue [value fetch kdata:$queuehan HandleQueue]
    var front [field $queue HQ_frontPtr]
    #
    # Figure the size of the queue.
    #
    if {$front == 0} {
	echo [format {The event queue for "%s" is empty} $name]
    } else {
	echo [format {The event queue for "%s" currently holds:} $name]
	while {$front != 0} {
    	    #
	    # print this event
	    #
    	    pevent $front
    	    #
	    # Advance to next event
	    #
    	    var cur [value fetch kdata:$front $et]
	    if {${geos-release} >= 2} {
	        var front [expr [field $cur HE_next]&0xfff0]
	    } else {
	        var front [field $cur HE_next]
	    }
	}
    }
}]

##############################################################################
#				pevent
##############################################################################
#
# SYNOPSIS:	print an event given its handle
# PASS:		han - handle of event
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	11/19/91	Broken out from eqlist
#
##############################################################################

[defcmd pevent {han} {system.event patient.event object.event}
{Usage:
    pevent <handle>

Examples:
    "pevent 39a0h"  print event with handle 39a0h

Synopsis:
    Print an event given its handle

Notes:

See also:
    elist, eqlist, eqfind, erfind

}
{
    require print-obj-and-method object
    global geos-release

    var han [getvalue $han]
    var cur [value fetch kdata:$han HandleEvent]
    
    if {[field $cur HE_handleSig] == [getvalue SIG_EVENT_STACK]} {
    	var hasStack 1
	#
	# Data are arranged as a sequence of HandleEventData, with up
	# to 6 words of data that are to be pushed in order (from HED_word0
	# to HED_word5). The last handle has hits HED_next field pointing
	# back to the event.
	#
	var nbytes [expr ([field $cur HE_dx]+1)&~1]
	var datahan [field $cur HE_bp]
	var wt [type make array 2 [type byte]]
	var hed_0 [getvalue HED_word0]

	var bytes {}
	while {$nbytes > 0} {
	    [for {var i $hed_0}
		 {$nbytes > 0 && $i < 16}
		 {var i [expr $i+2] nbytes [expr $nbytes-2]}
    	    {
	    	var bytes [concat [value fetch kdata:$datahan+$i $wt] $bytes]
    	    }]
	    var datahan [value fetch kdata:$datahan.HED_next]
    	}
	type delete $wt
    } else {
    	var hasStack 0
    }
	
    #
    # See if the OD is actually a far pointer, which means this is a
    # classed event rather than a regular event.
    #
    var seg [value fetch kdata:$han.HE_OD.segment]
    var off [value fetch kdata:$han.HE_OD.offset]
    if {[isclassptr $seg:$off]} {
    	var symb [symbol faddr var $seg:$off]
    	echo -n {CLASSED, }
    	echo -n [map-method [field $cur HE_method]
			[symbol fullname $symb]]
    	echo [format {, %s} [symbol name $symb]]
    	if {$hasStack} {
	    echo [format {    cx = %04xh} [field $cur HE_cx]]
    	} else {
	    echo [format {    cx = %04xh, dx = %04xh, bp = %04xh}
		    [field $cur HE_cx]
		    [field $cur HE_dx]
		    [field $cur HE_bp]]
    	}
    } else {
        if {${geos-release} >= 2} {
    	    var caller [expr ([field $cur HE_next]&0xf)<<4]
    	} else {
    	    var caller [expr (([field $cur HE_OD]>>16)&0xf)<<4]
    	}
    	var caller [expr $caller|([field $cur HE_callingThreadHigh]<<8)]
    	if {$caller == 0} {
    	    echo -n {send }
    	} else {
    	    var chan [handle lookup $caller]
    	    if {[null $chan]} {
    	    	echo -n [format {call (%04xh), } $caller]
    	    } else {
    	    	echo -n [format {call (%s), } [patient name 
    	    	    	    	    	    	[handle patient $chan]]]
    	    }
    	}
    	if {${geos-release} >= 2} {
	    var odhanmask 0xffff
    	} else {
    	    var odhanmask 0xfff0
    	}
	if {$hasStack} {
	    [print-obj-and-method [expr ([field $cur HE_OD]>>16)&$odhanmask]
		[expr [field $cur HE_OD]&0xffff]
		{}
		[field $cur HE_method]
		[field $cur HE_cx]]
	} else {
	    [print-obj-and-method [expr ([field $cur HE_OD]>>16)&$odhanmask]
		[expr [field $cur HE_OD]&0xffff]
		{}
		[field $cur HE_method]
		[field $cur HE_cx]
		[field $cur HE_dx]
		[field $cur HE_bp]]
	}
    }
    if {$hasStack} {
    	require fmt-bytes memory

    	echo [format {    %d %s of data = } [field $cur HE_dx]
	    	[pluralize byte [field $cur HE_dx]]]
    	
	fmt-bytes $bytes 0 [length $bytes] 4
    }
}]

##############################################################################
#				eqfind
##############################################################################
#
# SYNOPSIS:	find all event queues in the system
# PASS:		none
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	11/19/91	Initial Revision
#
##############################################################################

[defcmd eqfind {args} system.event
{Usage:
    eqfind

Examples:
    "eqfind" 	    list all event queues in the system
    "eqfind -p"	    list and print all event queues in the system

Synopsis:
    Display all event queues in the system

Notes:

See also:
    elist, eqlist, erfind

}
{
    var pqs 0
    global geos-release
    #
    # Examine the flags word for things we know and set vars
    # accordingly.
    #
    foreach i [explode [range [index $args 0] 1 end chars]] {
        [case $i in
    		p {var pqs 1}
	]
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    }

    #
    # Set up initial conditions.
    #
    if {${geos-release} >= 2} {
    	var start [value fetch loaderVars.KLV_handleTableStart]
    	var end [value fetch loaderVars.KLV_lastHandle]
    } else {
	var start [sym addr [sym find var HandleTable]]
	var end [value fetch lastHandle]
    }
    var nextStruct [value fetch kdata:$start HandleQueue]
    var hs [type size [sym find type HandleQueue]]

    #
    # Loop through all the handles in the handle table
    #
    var qsig [getvalue SIG_QUEUE]
    for {var cur $start} {$cur != $end} {var cur $next} {
    	var val $nextStruct
	var next [expr $cur+$hs]
	var nextStruct [value fetch kdata:$next HandleQueue]

	var type [field $val HQ_handleSig]
    	#
    	# Is this an event queue?
    	#
    	if {$type == $qsig} {
    	    #
    	    # Print the handle of the queue or the queue itself
    	    #
    	    var thd [field $val HQ_thread]
    	    if {$thd != 0} {
    	    	var qname [threadname $thd]
    	    } else {
    	    	var qname {(no thread)}
    	    }
    	    echo -n [format {%xh = } $cur]
    	    if {$pqs} {
    	    	eqlist $cur $qname
    	    } else {
    	    	echo [format {"%s"} $qname]
    	    }
    	}
    }
}]


##############################################################################
#				erfind
##############################################################################
#
# SYNOPSIS:	find all recorded event handles in the system
# PASS:		none
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	11/19/91	Initial Revision
#
##############################################################################

[defcmd erfind {args} system.event
{Usage:
    erfind

Examples:
    "erfind" 	    list all recorded event handles in the system
    "erfind -p"	    list and print all recorded event handles in the system

Synopsis:
    Display all record event handles in the system.  These are events that
    have been recorded but not necessarily sent anywhere, so they will not
    appear in the queue of any thread.

Notes:

See also:
    elist, eqlist, eqfind

}
{
    var pes 0
    global geos-release
    #
    # Examine the flags word for things we know and set vars
    # accordingly.
    #
    foreach i [explode [range [index $args 0] 1 end chars]] {
        [case $i in
    		p {var pes 1}
	]
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    }

    #
    # Set up initial conditions.
    #
    if {${geos-release} >= 2} {
    	var start [value fetch loaderVars.KLV_handleTableStart]
    	var end [value fetch loaderVars.KLV_lastHandle]
    } else {
	var start [sym addr [sym find var HandleTable]]
	var end [value fetch lastHandle]
    }
    var nextStruct [value fetch kdata:$start HandleEvent]
    var hs [type size [sym find type HandleEvent]]

    #
    # Loop through all the handles in the handle table
    #
    var ersig [getvalue SIG_EVENT_REG]
    var essig [getvalue SIG_EVENT_STACK]
    for {var cur $start} {$cur != $end} {var cur $next} {
    	var val $nextStruct
	var next [expr $cur+$hs]
	var nextStruct [value fetch kdata:$next HandleEvent]

	var type [field $val HE_handleSig]
    	#
    	# Is this a recorded event?  If the HE_next field is non-zero,
    	# then this event is in a queue, so we are not interested in it.
#
#FIX THIS! This should follow Adam's suggestion and see if the thing is
#actually an OD (rather than a process or a queue).  If it is an OD, then
#we should find the process of burden for the object block, and see if
#this event is on that queue.  If it isn't, then the thing is actually
#a recorded event (otherwise the HE_next field was zero only because the
#event was the last in its queue).
#
#In addition, if it is a classed event (ie. isclassptr on the OD returns
#true), then by definition it is a recorded event (or so I'm told :-)
#
    	#
    	if {$type == $ersig || $type == $essig} {
    	    if {[field $val HE_next] == 0} {
    		echo -n [format {%xh } $cur]
    	    	if {!$pes} {
    	    	    if {$type == $ersig} {
    	    	        echo {(event in registers)}
    	    	    } else {
    		        echo {(event on stack)}
    	    	    }
    	    	} else {
    	    	    echo -n {= }
    		    pevent $cur
    	    	}
    	    }
    	}
    }
}]

##############################################################################
#				ptr
##############################################################################
#
# SYNOPSIS:	Generate pointer events, to make testing such things easier.
# PASS:		
#	ptr up <button>
#	ptr down <button>
#	ptr move <x> <y>
#
#   	<button> := left | middle | right
#	    may be abbreviated
#   	<x>	:= <num> | +<num> | -<num>
#   	<y> 	:= <num> | +<num> | -<num>
#	    if <num> given w/o leading sign, position is absolute and marked
#	    as such in the message
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/24/92		Initial Revision
#
##############################################################################
[defsubr ptr {cmd arg1 {arg2 {}}}
{
    global geos-release
    if {${geos-release} >= 2} {
    	foreach t [patient threads [patient find geos]] {
	    if {[thread number $t] == 2} {
	    	var im [thread id $t]
    	    }
    	}
	var impref {}
    } else {
    	var im [patient find im]
	if {[null $im]} {
	    error {Input manager not loaded}
    	}
    	var im [handle id [index [patient resources $im] 0]]
	var impref im::
    }
    
    var now [value fetch systemCounter]
    
    [case $cmd in
     {down up} {
	if {${geos-release} >= 2} {
	    var method MSG_IM_BUTTON_CHANGE
	} else {
     	    var method im::METHOD_BUTTON_CHANGE
	}
	[case $arg1 in
	    l*	{var button 0}
	    m*	{var button 1}
	    r*	{var button 2}
	    default {error [format {unknown button %s} $arg1]}
    	]
    	var margs [list cx [expr $now>>16] dx [expr $now&0xffff] bp
	    	    [expr [if {[string c $cmd up] == 0} {expr 0} {fieldmask BI_PRESS}]|$button]]
     }
     move {
	if {${geos-release} >= 2} {
	    var method MSG_IM_PTR_CHANGE
	} else {
     	    var method im::METHOD_PTR_CHANGE
	}
	var flags [expr $now&0x3fff]
	[case $arg1 in
	 +* {var arg1 0$arg1}
	 -* {var arg1 0$arg1}
	 *  {var flags [expr $flags|[fieldmask ${impref}PI_absX]]}]
	[case $arg2 in
	 +* {var arg2 0$arg2}
	 -* {var arg2 0$arg2}
	 *  {var flags [expr $flags|[fieldmask ${impref}PI_absY]]}]
	var margs [list cx $arg1 dx $arg2 bp $flags]
     }
     default {
    	error [format {unknown command: %s} $cmd]
     }
    ]


    [if {![eval [concat call-patient ObjMessage
    	    ax [getvalue $method]
	    bx $im
	    si 0
	    di [fieldmask MF_FORCE_QUEUE] $margs]]}
    {
    	echo [format {couldn't send %s to input manager} $method]
    	restore-state
    } else {
    	restore-state
    }]
}]

