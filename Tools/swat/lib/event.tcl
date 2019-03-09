##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
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
#   	map-method    	    	Map a number to a method name
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/13/89		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: event.tcl,v 3.7 90/05/23 18:35:12 adam Exp $
#
###############################################################################

[defcommand elist {{pat {}}} process|object
{Display all events pending for a patient. If no patient name is given,
the events for the current patient are listed.}
{
    var thd [string first : $pat]
    if {$thd < 0} {
    	var thd {}
    } elif {$thd == 0} {
    	var thd [range $pat 1 end char]
	var pat {}
    } else {
    	var thd [range $pat [expr $thd+1] end char]
	var pat [range $pat 0 [expr $thd-1] char]
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
    	error [format {patient %s has no thread #%d} $pat $thd]
    }

    var queuehan [value fetch kdata:[thread id $thread].HT_eventQueue]
    
    if {$queuehan == 0} {
    	error [format {thread %d of %s has no associated event queue} $thd $pat]
    }
    
    eqlist $queuehan $pat:$thd
}]

[defcommand eqlist {queuehan {name {anonymous queue from hell}}} process|object
{Display all events in a queue.  The first argument is the queue handle, the
second is the name of the queue for printing}
{
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
	    # Fetch next event.
	    #
	    var cur [value fetch kdata:$front $et]
	    var caller [expr (([field $cur HE_OD]>>16)&0xf)<<4]
	    var caller [expr $caller|([field $cur HE_callingThreadHigh]<<8)]
	    if {$caller == 0} {
		echo -n {SEND, }
	    } else {
		var chan [handle lookup $caller]
		if {[null $chan]} {
		    echo -n [format {CALL (%04xh), } $caller]
		} else {
		    echo -n [format {CALL (%s), } [patient name
						[handle patient $chan]]]
		}
	    }
    	    [print-obj-and-method [expr ([field $cur HE_OD]>>16)&0xfff0]
	    	[expr [field $cur HE_OD]&0xffff]
		[field $cur HE_method]
		[field $cur HE_cx]
		[field $cur HE_dx]
		[field $cur HE_bp]]
    	    #
	    # Advance to next event
	    #
	    var front [field $cur HE_next]
	}
    }
}]
