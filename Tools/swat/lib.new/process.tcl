##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#	$Id: process.tcl,v 3.9.12.1 97/03/29 11:26:32 canavese Exp $
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
[defcommand wakeup-thread {who} swat_prog.thread
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

[defcmd wakeup {{who nil}} {thread patient.running}
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
    	    patient stop
	} else {
	    brk tset [patient name $patient]::[index $val 1]
	}
    }
    return EVENT_HANDLED
}]

[defcmd spawn {args} {top.running thread patient.running}
{Usage:
    spawn <patient> [<address>]

Examples:
    spawn hello	    Set a temporary breakpoint which the machine will
    	    	    	hit when the hello patient is created.
    sp hello	    Set a temporary breakpoint which the machine will
    	    	    	hit when the hello patient is created.
    sp hello HelloDraw
    	    	    Set a temporary breakpoint which the machine will
    	    	    	hit when the hello patient is created and reaches
    	    	    	HelloDraw.
    sp impex:1	    Set a temporary breakpoint which the machine will
    	    	    	hit when thread number 1 for the patient impex
    	    	    	is created.
Synopsis:
    Set a temporary breakpoint in a not-yet-existent patient/thread,
    waiting for a new one to be created.

Notes:
    * The <process> argument is the permanent name of the patient to
      watch for.

    * The optional <address> argument is an address expression saying
      where to place the breakpoint.  If none is specified, the
      the machine stops when the patient is created.

    * This can also be used to catch the spawning of a new thread.

    * If the machine stops before the breakpoint can be set, you'll
      have to call spawn again.

See also:
    run, freeze, thaw, wakeup.
}
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
