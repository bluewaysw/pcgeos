##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#	$Id: thread.tcl,v 3.27.4.1 97/03/29 11:27:54 canavese Exp $
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
    if {[null [handle lookup [field $td HT_owner]]]} {
    	var pname [mapconcat i
		   [value fetch
	    	    [expr [value fetch
			   kdata:[field $td HT_owner].HM_addr]*16].GH_geodeName]
		   {var i}]:?
    } else {
    	var pname [threadname $id]
    }

    echo [format 
    	  {%04Xh (%-9s); base prio: %3d, usage: %3d, cur pri: %3d}
	  $id $pname
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
[defcmd threadstat {} {system.thread thread}
{Usage:
    threadstat

Examples:
    "threadstat"

Synopsis:
    Provides information about all threads and various thread queues and
    synchronization points in the system.

Notes:

See also:
    ps
}
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

    echo [format {Current thread: %04xh (%s #%d)} $thread
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
    	[if {[not-1x-branch]}
	 {list Heap DOS/BIOS Geode}
    	 {list Heap Directory {Working Directory} {File List} DOS/BIOS Geode {Disk Table}}]
	[if {[not-1x-branch]}
	 {list heapSem biosLock geodeSem}
	 {list heapSem dirLock cwdLock sftLock dosLock geodeSem diskLock}]
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
#   	    	ml  = value list for the ThreadLock structure
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
    global geos-release
    if {${geos-release} >= 2} {
	if {[null [field $ml TL_owner]]} {
	    echo [format {%30s: value = %d} $label 
		    [field [field $ml TL_sem] Sem_value]]
	} elif {[field $ml TL_owner] == 65535} {
	    echo [format {%30s: FREE} $label]
	} else {
	    echo [format {%30s: owned by: %s, value = %d} $label
		    [threadname [field $ml TL_owner]]
		    [field [field $ml TL_sem] Sem_value]]
	}
	#
	# Print any threads blocked on the queue
	#
	var q [field [field $ml TL_sem] Sem_queue]
	if {$q > 15} {
	    print-queue $q
	    echo
	}
    } else {
	if {[null [field $ml ML_owner]]} {
	    echo [format {%30s: value = %d} $label 
		    [field [field $ml ML_sem] Sem_value]]
	} elif {[field $ml ML_owner] == 65535} {
	    echo [format {%30s: FREE} $label]
	} else {
	    echo [format {%30s: owned by: %s, value = %d} $label
		    [threadname [field $ml ML_owner]]
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
[defcmd pthread {id} {system.thread thread}
{Usage:
    pthread <id>

Examples:
    "pthread 16c0h" 	Prints information about the thread whose handle is
    	    	    	16c0h

Synopsis:
    Provides various useful pieces of information about a particular thread,
    including its current priority and its current registers.

Notes:
    * <id> is the thread's handle ID, as obtained with the "ps -t" or
      "threadstat" command.

See also:
    ps, threadstat
}
{
    global geos-release

    var id [getvalue $id]
    var handle [handle lookup $id]
    if {[null $handle] || ![handle isthread $handle]} {
    	error [format {%s not a valid thread ID} $id]
    }

    var td [value fetch kdata:$id HandleThread]

    echo [format {Owner: %04xh (%s)}
    	    [field $td HT_owner] [patient name [handle patient $handle]]]
    var nhandle [handle lookup [field $td HT_nextQThread]]
    echo [format {nextQueued: %s, next = %04xh, event queue = %04xh}
    	    [if {[field $td HT_nextQThread]} {
    	    	[format {%04xh (%s #%d)}
    	    	    [field $td HT_nextQThread]
    	    	    [patient name [handle patient $nhandle]]
    	    	    [thread number [handle other $nhandle]]]
    	     } else {
    	    	[format nil]
    	    }]
    	    [field $td HT_next]
	    [field $td HT_eventQueue]]
    echo [format {base priority: %3d, cpu usage: %3d, current priority: %3d}
    	    [field $td HT_basePriority]
    	    [field $td HT_cpuUsage]
	    [field $td HT_curPriority]]

    if {[field $td HT_saveSS]} {
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
        	var handle [handle find [format %04xh:0 $regval]]
        	if {![null $handle]} {
        	    if {[handle state $handle] & 0x80} {
        	    	#
    			# Handle is a resource handle, so it's got a symbol in
			# its otherInfo field. We want its name.
        	    	#
        	    	echo [format {%-4s%04xh   handle %04xh (%s)}
        	    	    	    $i $regval [handle id $handle]
        	    	    	    [symbol fullname [handle other $handle]]]
        	    } else {
        	    	echo [format {%-4s%04xh   handle %04xh}
        	    	    	    $i $regval [handle id $handle]]
        	    }
        	} else {
        	    echo [format {%-4s%04xh   no handle} $i $regval]
        	}
        }
    } else {
    	echo No registers saved
    }
    if {[field $td HT_eventQueue]} {
    	eqlist [field $td HT_eventQueue]
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
[defcommand freeze {{who {}}} {thread patient.running}
{Usage:
    freeze [ <patient> | :<n> | <patient>:<n> | <id> ]

Examples:
    "freeze term"   	Freezes the application thread for "term"
    "freeze :1"	    	Freezes thread #1 of the current patient
    "freeze 16c0h"  	Freezes the thread whose handle is 16c0h
    "freeze"		Freezes the current thread

Synopsis:
    Freezing a thread prevents a thread from running unless it's the only thread
    that's runnable in the entire system.

Notes:
    * A frozen thread is not dead in the water, as it will still run if nothing
      else is runnable.

    * Freezing a thread is most useful when debugging multi-threaded applica-
      tions where a bug appears to be caused by a timing problem or race
      condition between the two threads. Freezing one of the threads ensures
      a consistent timing relationship between the two threads and allows the
      bug to be reproduced much more easily.

    * The freezing of a thread is accomplished by setting its base and current
      priorities to as high a number as possible (255) thereby making the
      thread the least-favored thread in the system. The previous priority
      can be restored using the "thaw" command.

    * If you give no argument, Swat will freeze the current thread, which
      may or may not be the thread the target system thinks is the
      current thread.

See also:
    thaw, block, unblock
}
{
    var curp [patient data]

    if {![null $who]} {
    	switch $who
    }

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
    var bp [value fetch kdata:$id.geos::HT_basePriority]
    if {$bp == 255} {
    	error [format {%s is already frozen} $who]
    }
    var _old_$desired $bp
    #
    # Increase both the base and the current priority to maximum.
    #
    assign kdata:$id.geos::HT_curPriority 255
    assign kdata:$id.geos::HT_basePriority 255
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
[defcommand thaw {{who {}}} {thread patient.running}
{Usage:
    thaw [ <patient> | :<n> | <patient>:<n> | <id> ]

Examples:
    "thaw term"   	Allows the application thread for "term" to run normally
    "thaw :1"	    	Allows thread #1 of the current patient to run normally
    "thaw 16c0h"  	Allows the thread whose handle is 16c0h to run normally
    "thaw"		Allows the current thread to run normally

Synopsis:
    Thawing a thread restores its priority to what it was before the thread
    was frozen.

Notes:
    * If you give no argument, Swat will thaw the current thread, which
      may or may not be the thread the target system thinks is the
      current thread.

See also:
    freeze, block, unblock
}
{
    var curp [patient data]

    if {![null $who]} {
    	switch $who
    }

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
    var bp [value fetch kdata:$id.geos::HT_basePriority]
    if {$bp != 255} {
    	error [format {%s isn't frozen} $who]
    }
    #
    # Reset its base priority to what it was before
    #
    assign kdata:$id.geos::HT_basePriority [var _old_$desired]

    #
    # Use that and its recent CPU usage to calculate the proper current
    # priority for the thread, handling wrap-around correctly
    #
    var cp [expr [value fetch kdata:$id.geos::HT_cpuUsage]+[var _old_$desired]]
    if {$cp > 255} {var cp 255}

    assign kdata:$id.geos::HT_curPriority $cp

    #
    # Switch back to previous "current patient"
    #
    switch [index $curp 0]:[index $curp 2]
}]

##############################################################################
#				antifreeze
##############################################################################
#
# SYNOPSIS:	Make a thread the most-likely thing to run.
# PASS:		who = an argument similar to that passed to "switch"
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	the thread's curPriority and basePriority are set to 0 until
#   	    	"thaw" is executed.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/12/92	Initial Revision
#
##############################################################################
[defcommand antifreeze {{who {}}} thread
{Usage:
    antifreeze <patient>
    antifreeze :<n>
    antifreeze <patient>:<n>
    antifreeze <id>

Examples:
    "antifreeze term"   	Promotes the application thread for "term"
				to be the "most-runnable"
    "antifreeze :1"	    	Does likewise for thread #1 of the current
				patient
    "antifreeze 16c0h"  	Does likewise the thread whose handle is 16c0h
    "antifreeze"    	    	Promotes the current thread to be the
				"most-runnable."

Synopsis:
    Antifreezing a thread makes a thread the most-favored thread in the entire
    system. Should it ever be runnable, it will be the thread the system
    runs, possibly to the detriment of other threads...

Notes:
    * The antifreezing of a thread is accomplished by setting its base and
      current priorities to as low a number as possible (0) thereby making the
      thread the most-favored thread in the system. The previous priority
      can be restored using the "antithaw" command.

See also:
    antithaw
}
{
    var curp [patient data]

    if {![null $who]} {
    	switch $who
    }

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
    var bp [value fetch kdata:$id.geos::HT_basePriority]
    if {$bp == 0} {
    	error [format {%s is already anti-frozen} $who]
    }
    var _old_$desired $bp
    #
    # Decrease both the base and the current priority to minimum.
    #
    assign kdata:$id.geos::HT_curPriority 0
    assign kdata:$id.geos::HT_basePriority 0
    #
    # Switch back to previous "current patient"
    #
    switch [index $curp 0]:[index $curp 2]
}]

##############################################################################
#				antithaw
##############################################################################
#
# SYNOPSIS:	Allow an "antifrozen" thread to run normally
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
[defcommand antithaw {{who {}}} thread
{Usage:
    antithaw <patient>
    antithaw :<n>
    antithaw <patient>:<n>
    antithaw <id>

Examples:
    "antithaw term"   	Allows the application thread for "term" to run normally
    "antithaw :1"	Allows thread #1 of the current patient to run normally
    "antithaw 16c0h"  	Allows the thread whose handle is 16c0h to run normally

Synopsis:
    Thawing a thread restores its priority to what it was before the thread
    was given antifreeze.

Notes:

See also:
    antifreeze
}
{
    var curp [patient data]

    if {![null $who]} {
    	switch $who
    }

    var desired [patient data]

    foreach i [patient threads] {
	if {[thread number $i] == [index $desired 2]} {
	    break
	}
    }
    
    var id [thread id $i]
    #
    # Make sure the thread is actually anti-frozen
    #
    global _old_$desired
    var bp [value fetch kdata:$id.geos::HT_basePriority]
    if {$bp != 0} {
    	error [format {%s isn't anti-frozen} $who]
    }
    #
    # Reset its base priority to what it was before
    #
    assign kdata:$id.geos::HT_basePriority [var _old_$desired]

    #
    # Use that and its recent CPU usage to calculate the proper current
    # priority for the thread, handling wrap-around correctly
    #
    var cp [expr [value fetch kdata:$id.geos::HT_cpuUsage]+[var _old_$desired]]
    if {$cp > 255} {var cp 255}

    assign kdata:$id.geos::HT_curPriority $cp

    #
    # Switch back to previous "current patient"
    #
    switch [index $curp 0]:[index $curp 2]
}]

[defsubr build-pop-axbx {}
 {
     # push the following code:
     #   pop bx
     #   pop ax
     #   retf 6
     #   int 3       (pad byte)
     assign sp sp-6
     var stackcode [read-reg sp]
     assign {byte ss:sp}    5bh
     assign {byte ss:sp+1}  58h
     assign {byte ss:sp+2}  cah
     assign {word ss:sp+3}  0006h
     assign {byte ss:sp+5}  cch
     
     # return address to next real instruction
     assign sp sp-4
     assign {fptr ss:sp}    cs:ip

     # actually push bx and ax
     assign sp sp-4
     assign {word ss:sp+2}  ax
     assign {word ss:sp}    bx

     # return address to our stack code above
     assign sp sp-4
     assign {fptr ss:sp}    ss:$stackcode
 }
]

[defsubr build-context {}
 {
     global flags

     # put code on the stack to restore ax and bx after a far return
     build-pop-axbx

     # turn off single-step flag, so we won't be single-stepping when
     # we wake up again
     var safecc [expr {[frame reg cc] & ~[index [assoc $flags TF] 1]}]
     

     # build the actual context
     var csize [size ThreadBlockState] # should be 20 for XIP and 18 for nonXIP
     assign sp sp-$csize
     if {$csize == 20} {
	 assign ss:sp.TBS_xipPage geos::curXIPPage
     }
     assign ss:sp.TBS_bp bp
     assign ss:sp.TBS_es es
     assign ss:sp.TBS_dx dx
     assign ss:sp.TBS_flags $safecc
     assign ss:sp.TBS_cx cx
     assign ss:sp.TBS_di di
     assign ss:sp.TBS_si si
     assign ss:sp.TBS_ds ds
     assign ss:sp.TBS_ret [index [addr-parse geos::FarRet] 1]
 }
]


[defsubr block-running-thread {thread}
 {
     # make sure we're touching the real registers
     frame set [frame top]

     # put some context information on the stack
     build-context

     # load ds with the kernel dgroup and save stack info
     assign ds geos::dgroup
     assign ds:$thread.HT_saveSS  ss
     assign ds:$thread.HT_saveSP  sp
     assign ds:$thread.HT_nextQThread ffffh

     # jump to Dispatch
     addr-preprocess geos::Dispatch s o
     assign cs $s
     assign ip $o
 }
]

[defsubr block-runnable-thread {prev thread}
 {
     # remove the thread from the queue
     var next [value fetch kdata:$thread.HT_nextQThread [type word]]
     value store kdata:$thread.HT_nextQThread ffffh [type word]
     if {$prev != 0} {
	 value store kdata:$prev.HT_nextQThread $next [type word]
     } {
	 value store geos::runQueue $next [type word]
     }
 }
]

[defcommand block {{who {}}} {thread patient.running}
{Usage:
     block  [ <patient> | :<n> | <patient>:<n> | <id> ]

Examples:
     "block term"   	Stops the application thread for "term" 
     "block :1"	        Stops thread #1 of the current patient 
     "block 16c0h"  	Stops the thread whose handle is 16c0h 
     "block"		Stops the current thread 

Synopsis:
     Make the current thread unrunnable, as if it had blocked on a semaphore.
     It will not execute again until it is explicitly unblocked.

Notes:
     * Argument syntax is the same as for switch
     * You can't block geos:0
     * Don't block in interrupts or while context switching is disabled.

See also:
     unblock, freeze, thaw
 }
 {
     # remember where we were
     var curp [patient data]

     # let swat parse the thread for us, and tell the user if it is wrong
     if {![null $who]} {
	 switch $who
     }
     protect {
	 var desired [patient data]
	 var tname [format {%s:%d} [index $desired 0] [index $desired 2]]
	 foreach thread [patient threads] {
	     if {[thread number $thread] == [index $desired 2]} {
		 break
	     }
	 }

	 var thread [thread id $thread]

	 # don't let them stop the kernel
	 if {$thread == 0} {
	     error {Please don't try to block the kernel thread.}
	 }

	 # is it active?
	 if {$thread == [index [addr-parse @curThread 0] 1]} {
	     if {[value fetch geos::interruptCount] != 0} {
		 error {Please don't block an interrupt handler.}
	     } {
		 echo [format {Blocking running thread %04xh (%s)...} 
		       $thread $tname]
		 block-running-thread $thread
	     }
	 } {
	     # perhaps it's in the run queue then
	     var last 0 
	     var this [value fetch geos::runQueue [type word]]
	     while {$this && ($this != $thread)} {
		 var last $this
		 var this [value fetch kdata:$this.HT_nextQThread [type word]]
	     }
	     if {$this == $thread} {
		 echo [format {Blocking runnable thread %04xh (%s)...} 
		       $thread $tname]
		 block-runnable-thread $last $thread
	     } {
		 error [format {%s is not running or runnable.} $tname]
	     }
	 }
     } {
	 #
	 # Switch back to previous "current patient"
	 #
	 switch [index $curp 0]:[index $curp 2]	 
     }
 }
]
     
[defcommand unblock {{who {}}} {thread patient.running}
{Usage:
     unblock  [ <patient> | :<n> | <patient>:<n> | <id> ]

Examples:
    "unblock term"   	Allows the application thread for "term" to run
    "unblock :1"	Allows thread #1 of the current patient to run
    "unblock 16c0h"  	Allows the thread whose handle is 16c0h to run
    "unblock"		Allows the current thread to run

Synopsis:
     Undo the effects of the block command.  Make a thread runnable.

Notes:
     * The argument syntax is the same as for "switch".
     * This will not force a context switch, even if the unblocked thread
       has a higher priority then the current thread.
     * You can only "unblock" a thread which was stopped with "block"

See also:
     block, freeze, thaw
 }
 {
     # remember where we were
     var curp [patient data]

     # let swat parse the thread for us, and tell the user if it is wrong
     if {![null $who]} {
	 switch $who
     }

     protect {
	 var desired [patient data]
	 var tname [format {%s:%d} [index $desired 0] [index $desired 2]]
	 
	 foreach thread [patient threads] {
	     if {[thread number $thread] == [index $desired 2]} {
		 break
	     }
	 }

	 var thread [thread id $thread]

	 #
	 # it better be something we blocked
	 #
	 if {[value fetch kdata:$thread.HT_nextQThread [type word]] != 65535} {
	     error [format {%04xh was not blocked by swat} $thread]
	 }
	 
	 echo [format {Waking up %04xh (%s)...} $thread $tname]

	 #
	 # stuff it in the run queue
	 #
	 var runQueue [value fetch geos::runQueue [type word]]
	 assign kdata:$thread.HT_nextQThread $runQueue
	 value store geos::runQueue $thread [type word]
     } {
	 #
	 # Switch back to previous "current patient"
	 #
	 switch [index $curp 0]:[index $curp 2]
     }
 }     
]

