##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	process.tcl
# AUTHOR: 	Adam de Boor, Mar 25, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	wakeup-thread	    	Subroutine to wait for a thread to wake up
#   	wakeup	    	    	Command-level interface to wakeup-thread
#   	spawn	    	    	Wait for a new thread for a patient to
#				be created and set a breakpoint or halt the
#				machine.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/25/89		Initial Revision
#
# DESCRIPTION:
#	Process/thread-oriented commands
#
#	$Id: process.tcl,v 3.1 90/02/24 19:07:04 adam Exp $
#
###############################################################################
##############################################################################
#				wakeup-thread
##############################################################################
#
# SYNOPSIS:	Wait for a thread to wake up
# PASS:		who = argument as for "switch" command:
#   	    	    <patient>	    	thread 0 of <patient>
#   	    	    :<number>	    	thread <number> of current patient
#   	    	    <patient>:<number>	thread <number> of <patient>
# CALLED BY:	wakeup, a few other things
# RETURN:	non-zero if the desired thread is awake. zero if the
#   	    	patient stopped for some other reason.
# SIDE EFFECTS:	guess?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/23/90		Initial Revision
#
##############################################################################
[defdsubr wakeup-thread {who} prog.thread
{Subroutine to actually wake up a thread. Argument WHO is as for the "switch"
command. Returns non-zero if the wakeup was successful and zero if the machine
stopped for some other reason.}
{
    switch $who

    var next [frame next [frame top]] desired [patient data]

    if {[null $next]} {
	#
	# If there is no next frame, kludge things by setting a conditional
	# breakpoint for the thread at DSI_awake.
	#
	foreach i [patient threads] {
	    if {[thread number $i] == [index $desired 2]} {
		break
	    }
	}
	protect {
	    var bp [cbrk aset DSI_awake thread=[thread id $i]]
	    stop-catch {
		continue-patient
		wait
	    }
	} {
	    brk clear $bp
	}
    } else {
	finishframe [frame top]
    }
    return [expr {[string c $desired [patient data]] == 0}]
}]

[defcommand wakeup {{who nil}} thread|patient
{Wait for a given patient/thread to wake up. WHO is of the same form as the
argument to the "switch" command, ("help switch" to find out more). Leaves
you stopped in the kernel in the desired thread's context unless something
else causes the machine to stop before the patient/thread wakes up. WHO
defaults to the current thread.}
{
    if {[null $who]} {
    	var who [patient name]:[index [patient data] 2]
    }
    wakeup-thread $who
    event dispatch FULLSTOP _DONT_PRINT_THIS_
    event dispatch STACK 1
}]

[defsubr _spawn_catch {patient val}
{
    if {[string m [patient name $patient] [index $val 0]*]} {
    	#
	# It's the patient we've been waiting for -- set the temporary
	# breakpoint where it's wanted if it's wanted. If no breakpoint
	# wanted, just return to top level after dispatching a FULLSTOP
	# event telling why.
	#
	if {[length $val] == 1} {
	    event dispatch FULLSTOP [format {%s spawned}
			    	     [patient name $patient]]
	    return-to-top-level
	} else {
	    brk tset [patient name $patient]::[index $val 1]
	}
    }
    return EVENT_HANDLED
}]

[defcommand spawn {args} thread|patient
{Set a temporary breakpoint in a not-yet-existent process/thread,
waiting for a new one to be created. First argument is the permanent
name of the process to watch for.  Second argument is address
expression of where to place the breakpoint.  If no second argument is present,
the machine will be stopped and SWAT will return to the command level.

This can also be used to catch the spawning of a new thread.

If the machine stops before the breakpoint can be set, you'll have to
do this again.}
{
    global lastHaltCode

    if {[length $args] > 2 || [length $args] == 0} {
    	error {Usage: spawn <patient-name> [<addr>]}
    }

    #
    # Set trap for START event, giving it the name of the patient to look for
    # and where to set the breakpoint
    #
    var ev [event handle START _spawn_catch $args]
    #
    # Continue the machine and wait for it to stop, when it does,
    # nuke the event since we're exiting stage left -- either the breakpoint
    # was set and has been removed now (it was temporary), or we stopped
    # for some other reason.
    #
    [protect
     {
     	continue-patient
	wait
     }
     {event delete $ev}]
}]
