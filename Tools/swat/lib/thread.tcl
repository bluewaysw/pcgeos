##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	thread.tcl
# AUTHOR: 	Adam de Boor, Apr 13, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	threadstat  	    	Print info on all threads
#   	pthread	    	    	Print a thread handle
#   	freeze	    	    	Try and keep the indicated thread from running
#   	    	    	    	unless it absolutely has to.
#   	thaw	    	    	Let a thread run normally.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/13/89		Initial Revision
#
# DESCRIPTION:
#	Functions for playing with things in the Thread module
#
#	$Id: thread.tcl,v 3.5 91/01/11 11:36:09 tony Exp $
#
###############################################################################

##############################################################################
#				print-thread
##############################################################################
#
# SYNOPSIS:	Callback routine for print-queue and others to print info about
#		a thread.
# PASS:		td  = value string containing the HandleThread fetched for the
#		      thread 
#   	    	id  = handle ID of the thread
# CALLED BY:	print-queue, thread-stat
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/27/90		Initial Revision
#
##############################################################################
[defsubr print-thread {td id}
{
    echo [format 
    	  {%04X owned by %04X (%10s); base prio: %3d, usage: %3d, cur pri: %3d}
	  $id [field $td HT_owner] 
	  [patient name [handle patient [handle lookup [field $td HT_owner]]]]
    	  [field $td HT_basePriority] [field $td HT_cpuUsage]
	  [field $td HT_curPriority]]
}]

##############################################################################
#				print-queue
##############################################################################
#
# SYNOPSIS:	Print out a queue of threads
# PASS:		head	= handle ID for the first thread on the queue
# CALLED BY:	threadstat
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/27/90		Initial Revision
#
##############################################################################
[defsubr print-queue {head}
{
    [for {var cur $head} {$cur} {var cur [field $td HT_nextQThread]}
    {
    	var td [value fetch kdata:$cur HandleThread]
    	print-thread $td $cur
    }]
}]

##############################################################################
#				threadstat
##############################################################################
#
# SYNOPSIS:	Print out info on the threads active in the system
# PASS:		nothing
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/27/90		Initial Revision
#
##############################################################################
[defcommand threadstat {} kernel
{Print info about all threads in the system}
{
    #
    # Fetch the current thread's id (in decimal)
    #
    var	thread [read-reg curThread]
    #
    # Just for kicks, find the patient it belongs to and its number w.r.t. that
    # patient.
    #
    var handle [handle lookup $thread]

    echo [format {Current thread: %04x (%s #%d)} $thread
    	    [patient name [handle patient $handle]]
	    [thread number [handle other $handle]]]

    #
    # This isn't strictly necessary, since Swat knows about all threads in
    # the system ([thread all] will return tokens for them all).
    #
    echo {List of threads:}
    [for {var cur [value fetch threadListPtr]}
    	 {$cur}
    	 {var cur [field $td HT_next]}
    {
    	var td [value fetch kdata:$cur HandleThread]
    	print-thread $td $cur
    }]
    
    echo
    echo {Run queue:}

    print-queue [value fetch runQueue]

    echo
    [map {label lock}
    	 {Heap Directory {Working Directory} {File List} DOS/BIOS Geode
	  {Disk Table}}
	 {heapSem dirLock cwdLock sftLock dosLock geodeSem diskLock}
    {
	pmodulelock [concat $label lock] [value fetch $lock]
    }]
}]

##############################################################################
#				pmodulelock
##############################################################################
#
# SYNOPSIS:	Print who owns a module lock and any threads queued on it
# PASS:		label	= label for the lock
#   	    	ml  = value list for the ModuleLock structure
# CALLED BY:	threadstat, user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/27/90		Initial Revision
#
##############################################################################
[defsubr pmodulelock {label ml}
{
    if {[null [field $ml ML_owner]]} {
    	echo [format {%30s: value = %d} $label 
	    	[field [field $ml ML_sem] Sem_value]]
    } elif {[field $ml ML_owner] == 65535} {
	echo [format {%30s: FREE} $label]
    } else {
	echo [format {%30s: owned by: %s, value = %d} $label
		[patient name [handle patient [handle lookup
						[field $ml ML_owner]]]]
		[field [field $ml ML_sem] Sem_value]]
    }
    #
    # Print any threads blocked on the queue
    #
    var q [field [field $ml ML_sem] Sem_queue]
    if {$q > 15} {
    	print-queue $q
	echo
    }
}]

##############################################################################
#				pthread
##############################################################################
#
# SYNOPSIS:	Print information about a thread
# PASS:		id  = handle ID for the thread
# CALLED BY:	user, phandle
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/27/90		Initial Revision
#
##############################################################################
[defcommand pthread {id} kernel|output
{Prints out information about thread ID}
{
    var handle [handle lookup $id]
    if {[null $handle] || ![handle isthread $handle]} {
    	error [format {%s not a valid thread ID} $id]
    }

    var td [value fetch kdata:$id HandleThread]

    echo [format {Owner: %04x (%s)}
    	    [field $td HT_owner] [patient name [handle patient $handle]]]
    var nhandle [handle lookup [field $td HT_nextQThread]]
    echo [format {nextQueued: %s, next = %04x, prev = %04x}
    	    [if {[field $td HT_nextQThread]} {
    	    	[format {%04x (%s #%d)}
    	    	    [field $td HT_nextQThread]
    	    	    [patient name [handle patient $nhandle]]
    	    	    [thread number [handle other $nhandle]]]
    	     } else {
    	    	[format nil]
    	    }]
    	    [field $td HT_next]
    	    [field $td HT_prev]]
    echo [format {base priority: %3d, cpu usage: %3d, current priority: %3d}
    	    [field $td HT_basePriority]
    	    [field $td HT_cpuUsage]
    	    [field $td HT_currentPriority]]

    if {[field $td saveSS]} {
        echo Registers:
        var thread [handle other $handle]
        var j 0
        foreach i {CX DX SP BP SI DI} {
        	var regval [thread register $thread $i]
        	echo -n [format {%-4s%04xh%8d} $i $regval $regval]
    	var j [expr ($j+1)%3]
    	if {$j == 0} {echo} else {echo -n \t}
        }
        foreach i {CS DS SS ES} {
        	var regval [thread register $thread $i]
        	var handle [handle find [format 0x%04x:0 $regval]]
        	if {![null $handle]} {
        	    if {[handle state $handle] & 0x80} {
        	    	#
    			# Handle is a resource handle, so it's got a symbol in
			# its otherInfo field. We want its name.
        	    	#
        	    	echo [format {%-4s%04xh   handle %04x (%s)}
        	    	    	    $i $regval [handle id $handle]
        	    	    	    [symbol fullname [handle other $handle]]]
        	    } else {
        	    	echo [format {%-4s%04xh   handle %04x}
        	    	    	    $i $regval [handle id $handle]]
        	    }
        	} else {
        	    echo [format {%-4s%04xh   no handle} $i $regval]
        	}
        }
    } else {
    	echo No registers saved
    }
}]


##############################################################################
#				freeze
##############################################################################
#
# SYNOPSIS:	Keep a thread from running unless it's the only thing in the
#   	    	system that's runnable.
# PASS:		who = an argument similar to that passed to "switch"
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	the thread's curPriority and basePriority are set to 255 until
#   	    	"thaw" is executed.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/27/90		Initial Revision
#
##############################################################################
[defdsubr freeze {who} thread
{Attempt to prevent a thread from running by setting its priority really high,
thereby making it not run unless it absolutely has to. The thread can be
restored to its previous condition by executing "thaw" with the same argument.

Only argument "who" is similar in format to the argument passed to "switch":
    <patient>	    thread 0 of the indicated patient
    :<n>    	    thread <n> of the current patient
    <patient>:<n>   thread <n> of the indicated patient
    <id>    	    thread with the given ID
}
{
    var curp [patient data]

    switch $who

    var desired [patient data]

    foreach i [patient threads] {
	if {[thread number $i] == [index $desired 2]} {
	    break
	}
    }
    
    #
    # Save old priority
    #
    global _old_$desired
    var id [thread id $i]
    var bp [value fetch kdata:$id.kernel::HT_basePriority]
    if {$bp == 255} {
    	error [format {%s is already frozen} $who]
    }
    var _old_$desired $bp
    #
    # Increase both the base and the current priority to maximum.
    #
    assign kdata:$id.kernel::HT_curPriority 255
    assign kdata:$id.kernel::HT_basePriority 255
    #
    # Switch back to previous "current patient"
    #
    switch [index $curp 0]:[index $curp 2]
}]

##############################################################################
#				thaw
##############################################################################
#
# SYNOPSIS:	Allow a "frozen" thread to run normally
# PASS:		who = an argument similar to that passed to "switch"
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	the thread's base priority is returned to its previous value
#   	    	and its current priority recalculated properly
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/27/90		Initial Revision
#
##############################################################################
[defdsubr thaw {who} thread
{Allow a thread to run as usual, resetting its priority to be what it was before
the thread was frozen.

Only argument "who" is similar in format to the argument passed to "switch":
    <patient>	    thread 0 of the indicated patient
    :<n>    	    thread <n> of the current patient
    <patient>:<n>   thread <n> of the indicated patient
    <id>    	    thread with the given ID
}
{
    var curp [patient data]

    switch $who

    var desired [patient data]

    foreach i [patient threads] {
	if {[thread number $i] == [index $desired 2]} {
	    break
	}
    }
    
    var id [thread id $i]
    #
    # Make sure the thread is actually frozen
    #
    global _old_$desired
    var bp [value fetch kdata:$id.kernel::HT_basePriority]
    if {$bp != 255} {
    	error [format {%s isn't frozen} $who]
    }
    #
    # Reset its base priority to what it was before
    #
    assign kdata:$id.kernel::HT_basePriority [var _old_$desired]

    #
    # Use that and its recent CPU usage to calculate the proper current
    # priority for the thread, handling wrap-around correctly
    #
    var cp [expr [value fetch kdata:$id.kernel::HT_cpuUsage]+[var _old_$desired]]
    if {$cp > 255} {var cp 255}

    assign kdata:$id.kernel::HT_curPriority $cp

    #
    # Switch back to previous "current patient"
    #
    switch [index $curp 0]:[index $curp 2]
}]
