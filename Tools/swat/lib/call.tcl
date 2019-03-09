##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	call.tcl
# AUTHOR: 	Adam de Boor, Jun 27, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	call	    	    	user command to issue a call
#   	call-patient	    	programmer's command to issue a call
#   	exit	    	    	make the current thread exit
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/27/89		Initial Revision
#
# DESCRIPTION:
#	Commands/routines for calling functions in the current patient
#
#	$Id: call.tcl,v 3.0 90/02/04 23:35:29 adam Exp $
#
###############################################################################
[defsubr _call_catch {sp tnum}
{
    return [expr {[index [patient data] 2] == $tnum && [read-reg sp] >= $sp}]
}]

[defdsubr call-patient {func args} prog.call
{Internal routine to actually perform a call. Returns non-zero if the call
completed successfully. The previous machine state is still preserved, so
the caller must invoke discard-state or restore-state, as it sees fit. Args
are as for "call"}
{
    #
    # Get the dope on the function we're supposed to be calling
    #
    var sym [symbol find func $func]
    if {[null $sym]} {
    	error [format {call-patient: %s isn't a function} $func]
    }

    var fdata [symbol get $sym]
    #
    # Figure out where the function is and set CS:IP to it (function must be
    # in a handle, by definition). Makes sure the function is resident and
    # makes it so, if possible, should it be absent.
    #
    var addr [addr-parse $func]
    var handle [index $addr 0] unlock 0

    if {([handle state $handle] & 1) == 0} {
    	#
	# Handle non-resident -- attempt to load it with GeodeLockResource
	#
    	if {[call-patient GeodeLockResource bx [handle id $handle]]} {
    	    restore-state
	    var unlock 1
	} else {
	    restore-state
	    error [format {call-patient: %s not resident} $func]
	}
    }

    #
    # Set newsp to be where to store the return address (as well as being
    # the new value for SP) and retaddr to the address expression of the
    # return address.
    #
    if {[string c [index $fdata 1] near] == 0} {
    	#
	# Near function -- make sure we're in the function's segment and
	# push the current IP as the return address.
	#
	var chandle [handle find cs:0]
	
	if {$handle != $chandle} {
	    error [format {call-patient: near function %s not in current CS}
			  $func]
	}
    	var newsp ss:sp-2 retaddr ip
    } else {
    	var newsp {dword ss:sp-4} retaddr cs:ip
    }

    #
    # Perform whatever assignments are requested, after saving away the
    # registers.
    #
    var len [length $args]
    if {$len & 1} {
	error {Usage: call-patient <func> [<var> <value>]*}
    }

    save-state

    for {var i 0} {$i < $len} {var i [expr $i+2]} {
    	if {[string c [index $args $i] push] == 0} {
	    assign ss:sp-2 [index $args [expr $i+1]]
	    assign sp sp-2
    	} else {
	    assign [index $args $i] [index $args [expr $i+1]]
    	}
    }

    #
    # Push the return address onto the stack, recording the sp above the
    # address in $sp for later use.
    #
    var sp [read-reg sp]
    assign $newsp $retaddr
    assign sp $newsp

    #
    # Set a breakpoint at the current CS:IP to invoke _call_catch with
    # the SP that must be reached for the call to be complete and the
    # thread in which the machine must be executing for the breakpoint
    # to apply...
    #
    var bp [brk pset cs:ip [format {_call_catch %d %d} $sp [index [patient data] 2]]]
    assign cs [handle segment [index $addr 0]]
    assign ip [index $addr 1]
    
    #
    # Let the machine go and wait for it. We don't want it to generate
    # the FULLSTOP event since if the call completes, we don't want to
    # print out that it got back to where it started from. If the call
    # doesn't complete, we want to warn the user about what s/he's gotten
    # into. "Ergo" we do this all inside a stop-catch.
    #
    stop-catch {
	continue-patient
    	var result [expr {![wait] && [read-reg sp] == $sp}]
    }
    brk clear $bp

    #
    # If we forced the function in, unlock its block now by calling MemUnlock
    #
    if {$unlock} {
    	call-patient MemUnlock bx [handle id $handle]
	restore-state
    }
    
    return $result
}]

[defdsubr call {func args} top
{Call a function in the current thread. First argument is the function to
call. If it is a NEAR function, the thread must already be executing in
the function's segment. Following arguments are in pairs:
    <variable/register> <value>
These pairs are passed to the "assign" command, which see. As a special case,
if the variable is "push", the value (a word) is pushed onto the stack and
will be popped when the call completes (if it completes successfully).
All current registers are preserved and restored when the call is complete.
Variables are not.

Once the call has completed, you are left in a sub-interpreter to examine
the state of the machine. Type "break" to get back to the top level.

If the machine stops for any other reason than the call's completion, the
saved register state is discarded and you are left wherever the machine
stopped. You will not be able to get a stack trace above the called function,
but if the call eventually completes, and no registers have actually been
modified, things will get back on track ok.

You may not call a function from a thread that has retreated into the kernel.
This function also will not allow you to call ThreadExit. Use the "exit"
function to do that.}
{
    if {[eval [format {call-patient %s %s} $func $args]]} {
        #
        # Call completed -- let the user know, then go into a
        # sub-interpreter to allow him/her to examine the results.
        # Get out when s/he types "quit".
        #
        echo Call complete. Type "break" to return to top level
        event dispatch FULLSTOP _DONT_PRINT_THIS_

        top-level

        #
        # Go back to previous registers
        #
    	restore-state
    } else {
	#
	# Interrupted or stopped somewhere else -- clear breakpoint,
	# discard state and get out of here, warning the user that
	# things are slightly messed up.
	#
	global lastHaltCode
	event dispatch FULLSTOP [format {%s -- unable to continue call (stack probably confused)} $lastHaltCode]
	discard-state
    }
}]
	
[defdsubr exit {{code 0}} top
{Causes the current thread to exit. Optional argument is the status to return
to its parent, which defaults to 0}
{
    #
    # Make sure the current thread is the real current thread.
    #
    var tnum [index [patient data] 2] threads [patient threads]

    #
    # Find the thread descriptor for this thread...(leaves it in i)
    #
    foreach i $threads {
    	if {[thread number $i] == $tnum} {
	    break
    	}
    }
    #
    # Make sure we don't hang waiting for other threads to exit if this is
    # the application thread but the process has other threads around
    #
    [if {([length $threads] > 1) &&
    	 ([thread id $i] == [value fetch applVars.PH_firstThread])}
     {
     	error [format {Thread %04x can't exit until other(s) (%s) exit}
	    	[thread id $i]
		[mapconcat j $threads {
		    if {$j != $i} {
		    	format {%04x } [thread id $j]
		    }
		}]]
    }]

    if {[thread id $i] != [read-reg curThread]} {
    	#
	# Not the actual current thread -- wait for this one to wake up
	#
    	if {![wakeup-thread [thread id $i]]} {
	    return
	}
    }
    
    #
    # Transfer control to ThreadExit and load AX with the desired exit code
    #
    assign cs [handle segment [handle lookup 1]]
    assign ip ThreadExit
    assign ax $code
    
    #
    # Switch to the kernel thread so we can set a temporary breakpoint in
    # Dispatch for it (shouldn't normally get to Dispatch in kernel mode
    # except when exiting).
    #
    switch kernel
    brk tset Dispatch

    #
    # Continue the machine at ThreadExit and wait for it to stop again.
    #
    stop-catch {
    	continue-patient
	wait
    }
    event dispatch FULLSTOP {Exit Complete}
}]
