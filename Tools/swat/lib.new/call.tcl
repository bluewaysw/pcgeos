##############################################################################
#
#       Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       Swat -- System Library
# FILE:         call.tcl
# AUTHOR:       Adam de Boor, Jun 27, 1989
#
# COMMANDS:
#       Name                    Description
#       ----                    -----------
#       call                    user command to issue a call
#       call-patient            programmer's command to issue a call
#       exit                    make the current thread exit
#       run                     launch, spawn specified application
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       ardeb   6/27/89         Initial Revision
#
# DESCRIPTION:
#       Commands/routines for calling functions in the current patient
#
#	$Id: call.tcl,v 3.39 98/05/14 12:50:34 cthomas Exp $
#
###############################################################################
[defsubr _call_catch {sp tnum}
{
    return [expr {[index [patient data] 2] == $tnum && [read-reg sp] >= $sp}]
}]

[defcommand call-patient {func args} swat_prog.call
{Usage:
    call-patient <function> ((<reg>|push) <value>)*

Examples:
    "call-patient MemLock bx $h"        Locks down the block whose handle ID 
					is in $h.

Synopsis:
    This is a utility routine, not intended for use from the command line,
    that will call a routine in the PC after setting registers to or pushing
    certain values.

Notes:
    * Returns non-zero if the call completed successfully.
    
    * If the call is successful, the registers reflect the state of the machine
      upon return from the called routine. The previous machine state is
      preserved and can be retrieved, by invoking restore-state, or thrown
      away, by invoking discard-state. The caller *must* invoke one of these
      to clean up.

    * Arguments after <function> are as for "call".

    * If the called routine is in movable memory, this will lock the containing
      block down before issuing the call, as you'd expect.

    * Calling anything that makes message calls while on the geos:0 thread
      is a hazardous undertaking at best.
      
See also:
    call.
}
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

    #
    # Set newsp to be where to store the return address (as well as being
    # the new value for SP) and retaddr to the address expression of the
    # return address.
    #
    if {[index $fdata 1] == near} {
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
	var newsp {fptr ss:sp-4} retaddr cs:ip
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
    # Make sure assign doesn't try to get smart and look through $newsp
    # if it looks like a pointer (in the case where $newsp == {fptr ss:sp-4})
    # So, forcibly cast it to void.
    assign sp [list void $newsp]

    #
    # Set a breakpoint at the current CS:IP to invoke _call_catch with
    # the SP that must be reached for the call to be complete and the
    # thread in which the machine must be executing for the breakpoint
    # to apply...
    #
    var bp [brk pset cs:ip [format {_call_catch %d %d} $sp [index [patient data] 2]]]
    [if {[index $fdata 1] != near &&
	 !([handle state $handle]&8) &&
	 (!([handle state $handle]&1) ||
	  [value fetch kdata:[handle id $handle].geos::HM_lockCount] != -1)}
    {
    	#
	# Movable routine. Cope with XIP by using ProcCallFixedOrMovable
	#
    	var savedAX [value fetch ss:geos::TPD_dataAX]
	var savedBX [value fetch ss:geos::TPD_dataBX]
	
	value store ss:geos::TPD_dataAX [read-reg ax]
	value store ss:geos::TPD_dataBX [read-reg bx]

    	# Pass routine in bx:ax
	assign ax [index $addr 1]
	assign bx [expr 0xf000|([handle id [index $addr 0]]>>4)]

    	# go to PCFOM
	assign cs geos::ProcCallFixedOrMovable
	assign ip geos::ProcCallFixedOrMovable
    } else {
    	# else go directly to the routine
        assign cs [handle segment [index $addr 0]]
        assign ip [index $addr 1]
    }]
    
    #
    # Let the machine go and wait for it. We don't want it to generate
    # the FULLSTOP event since if the call completes, we don't want to
    # print out that it got back to where it started from. If the call
    # doesn't complete, we want to warn the user about what s/he's gotten
    # into. "Ergo" we do this all inside a stop-catch.
    #
    stop-catch {
	#
	# If on a GEOS stack, set initFlag non-zero so the EC code in
	# SysLockCommon doesn't throw up when what we're calling grabs
	# something (we're assuming that whoever is calling is knows what
	# it is doing...)
	#
	if {![null [patient find geos]]} {
	    var oldv [value fetch geos::initFlag]
	    var oldEF [value fetch geos::errorFlag]
	    assign geos::initFlag -1
	    assign geos::errorFlag -1
	}
	var ss [read-reg ss]
	continue-patient
	var result [expr {![wait] && [read-reg ss] == $ss && [read-reg sp] == $sp}]
	if {![null $oldv]} {
	    assign geos::initFlag $oldv
	    assign geos::errorFlag $oldEF
	}
    }
    brk clear $bp

    #
    # If we forced the function in, unlock its block now by calling MemUnlock
    #
    if {![null $savedAX]} {
    	value store ss:geos::TPD_dataAX $savedAX
	value store ss:geos::TPD_dataBX $savedBX
    }
    
    return $result
}]

[defcommand call {func args} top.running
{Usage:
    call <function> [<function args>]

Examples:
    "call MyFunc"
    "call MyDraw ax 1 bx 1 cx 10h dx 10h"
    "call FindArea box.bottom 5 box.right 5 push box"'

Synopsis:
    Call a function in the current thread.

Notes:
    * The function argument is the function to call. If it is a NEAR
      function, the thread must already be executing in the function's
      segment.

    * The function arguments are in pairs <variable/register> <value>.
      These pairs are passed to the "assign" command.  As a special
      case, if the variable is "push", the value (a word) is pushed
      onto the stack and is popped when the call finishes (if it
      completes successfully).

    * All current registers are preserved and restored when the call
      is complete.  Variables are not.

    * Once the call has completed, you are left in a sub-interpreter
      to examine the state of the machine. Type "break" to get back to
      the top level.

    * If the machine stops for any reason other than the call's
      completion, the saved register state is discarded and you are
      left wherever the machine stopped. You will not be able to get a
      stack trace above the called function, but if the call
      eventually completes, and no registers have actually been
      modified, things will get back on track ok.

See also:
    assign, call-patient, patch.
}
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
	
[defcommand exit-thread {{code 0}} thread
{Usage:
    exit-thread [<exit code>]

Examples:
    "exit-thread"           exit the current thread, returning 0 to its parent
    "exit-thread 1"         exit the current thread, returning 1 to its parent

Synopsis:
    Exit the current thread.

Notes:
    * The exit code argument is the status to return to the current thread's
      parent, which defaults to 0.

    * Do not invoke this function for an event-driven thread; send it a
      MSG_META_DETACH instead.

See also:
    quit.
}
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
    
    if {[value fetch kdata:[thread id $i].HT_eventQueue] != 0} {
	error {Do not use this function for event-driven threads, please}
    }

    if {[thread id $i] != [read-reg curThread]} {
	#
	# Not the actual current thread -- wait for this one to wake up
	#
	if {![wakeup-thread [thread id $i]]} {
	    # wakeup failed; abort
	    return
	}
    }
    
    #
    # Transfer control to ThreadDestroy and load AX with the desired exit code.
    # Remaining registers are to avoid sending a MSG_META_ACK anywhere.
    #
    assign cs [handle segment [handle lookup 1]]
    assign ip ThreadDestroy
    assign ax $code
    assign cx 0
    assign dx 0
    assign si 0
    assign bp 0
    
    #
    # Switch to the kernel thread so we can set a temporary breakpoint in
    # Dispatch for it (shouldn't normally get to Dispatch in kernel mode
    # except when exiting).
    #
    switch geos
    if {![null [sym find proc Dispatch]]} {
	brk tset Dispatch
    }

    #
    # Continue the machine at ThreadDestroy and wait for it to stop again.
    #
    stop-catch {
	continue-patient
	wait
    }
    event dispatch FULLSTOP {Thread Exit Complete}
}]


[defcommand run {args} top.running
{Usage:
    run [[-enp] <app>]

Examples:
    "run uki"                   run EC Uki if running EC code
				run non-EC Uki if running non-EC code
    "run -e uki"                run EC Uki
    "run -n uki"                run non-EC Uki
    "run -p games\ukiec.geo"	run games\ukiec.geo
    "run"                       run 'patient-default'

Synopsis:
    "Runs" an application by loading it via a call to UserLoadApplication &
    stopping when the app reaches the GenProcess handler for MSG_META_ATTACH.
    Return patient created, if any (in the example cases above, this would
    be "uki").

Notes:
    * <app>     either the app's permanent name or the path of the app relative
		to SP_APPLICATION

      -e        run EC version of <app>
      -n        run non-EC version of <app>
      -p        <app> argument is the path of app relative to SP_APPLICATION

    * If no argument is given, runs the 'patient-default'.

    * May be used even if stopped inside the loader, in which case GEOS will
      be allowed to continue starting up and the specified app will run
      after GEOS is Idle.

    * If the machine stops for any reason other than the call's completion,
      you are left wherever the machine stopped.

    * This function is only "reasonably" robust at this time.  Performs well
      at Idle or after a Ctrl-C.

    * For 2.X versions only

See also:
    spawn, switch, send, patient-default
}
{
    global defaultPatient runPatient runPatientType runAppPath file-os

    if {[null $args] && [null $defaultPatient]} {
	error {Usage: run [-enp] <app>}
    }

    if {[null $args]} {
	var args $defaultPatient
    } else {
	#
	# parse the various arguments we allow.
	#
	if {[string match [index $args 0] -*]} {
	    if {[length [index $args 0] char] > 2} {
		error {Usage: run [-enp] <geode>}
	    }
	    [case [index $args 1 char] in
		e {var nec 0}
		n {var nec 1}
		p {var pathname 1}
	    ]
	    var args [cdr $args]
	}
    }

    if {[null [patient find ui]]} {
	echo  Spawning ui... 
	spawn ui
    }
    if {[null [sym find proc Idle]]} {
	var bp [brk [address-kernel-internal Idle]]
    } else {
	var bp [brk Idle]
    }
    if {[string c ${file-os} win32] == 0} {
	if {![null [getenv STAFF_PATH]]} {
	    # Must be an internal developer so be verbose
	    echo Continuing to Idle loop for safety
	}
    } else {
	echo Continuing to Idle loop for safety
    }
    stop-catch {
	continue-patient
	var abortFlag [wait]
    }
    brk clear $bp
    if {$abortFlag} {error {Wait for Idle loop aborted}}

    #
    # are we running ec or non-ec
    #
    if {$nec == {} && $pathname == {}} {
	var geosPatient [patient find geos]
	if {$geosPatient == nil} {
	    var loaderPath [patient path [patient find loader]]
	    if {[string f loader.sym $loaderPath no_case] != -1} {
		var nec 1
	    } elif {[string f loaderec.sym $loaderPath no_case] != -1} {
		var nec 0
	    } else {
		echo
		echo  Warning: Unable to determine whether the target system is
		echo {         running EC or non-EC code.  Defaulting to EC.}
		echo

		var nec 0
	    }
	} elif {![string c [patient fullname $geosPatient] {geos    kern}]} {
	    var nec 1
	} else {
	    var nec 0
	}
    }

    if {$pathname == 1} {
	var runAppPath $args
    } elif {($args != $runPatient) || ($nec != $runPatientType) ||
	[null $runAppPath]} {

	echo Looking for application...
	if {$nec == 1} {
	    catch {rpc-find-geode -n $args} runAppPath
	} else {
	    catch {rpc-find-geode $args} runAppPath
	}

	if {$runAppPath == {}} {
	    error {Sorry, unable to find application to run}
	}

	var runPatient $args
	var runPatientType $nec
	var runAppPath [range $runAppPath
			      [expr [string first WORLD\\ $runAppPath]+6]
			      end char]
    }

    echo Allocating AppLaunchBlock
    if {[call-patient MemAllocFar ax [size AppLaunchBlock] cl 040h ch 0e0h]} {
	var block [read-reg bx]
	#echo Filename block: $block
	var seg [read-reg ax]
	#echo Filename block segment: $seg
	restore-state
	for {var i 0} {$i<[length $runAppPath c]} {var i [expr $i+1]} {
		scan [index $runAppPath $i c] %c foo
		assign {byte $seg:ALB_appRef.AIR_fileName+$i} $foo
	}
	assign {byte $seg:ALB_diskHandle} SP_APPLICATION
	echo Force-queueing MSG_USER_LAUNCH_APPLICATION
	omfq ui::MSG_USER_LAUNCH_APPLICATION ui dx $block
	echo Waiting for message...
	var bp [brk ui::UserLoadApplication]
	stop-catch {
		continue-patient
		var abortFlag [wait]
	}
	brk clear $bp
	if {$abortFlag} {error {Wait for message aborted}}
	echo Loading $runAppPath...
	# Clear CPU usage for UI, so that UserLoadApplication is more likely
	# to complete before new patient spawned.
	var id [thread id [patient threads [patient find ui]]]
	assign kdata:$id.geos::HT_cpuUsage 0
	# Let UserLoadApplication finish
	if {[finishframe [frame cur]]} {error {Unable to finish UserLoadApplication}}
	var flags [read-reg CC]
	var error [read-reg ax]
	var geode [read-reg bx]
	if {![expr $flags&1]} {
	    echo Spawning $args...
	    if {![null [sym find proc ui::UI_Attach]]} {
		var bp [brk ui::UI_Attach
			{expr { [handle id
				 [handle owner
				  [handle lookup
				   [value fetch ss:0 [type word]]]]]
				 == $geode }}]
	    }       
	    stop-catch {		
		continue-patient
		var $abortFlag [wait]
	    }
	    brk clear $bp
	    if {$abortFlag} {error {Wait for UI_Attach aborted}}
	    event dispatch FULLSTOP _DONT_PRINT_THIS_
	    return
	} else {
	    # most likely failed because of GLE_LIBRARY_NOT_FOUND
	    # reset the cached runAppPath.
	    echo [format {Unable to load %s due to %s}
		  $runAppPath
		  [penum GeodeLoadError $error]]
	    if {[string m [penum GeodeLoadError $error] *NOT_FOUND]} {
		var runAppPath {}
		echo {Cached path cleared.}
	    }
	    event dispatch FULLSTOP _DONT_PRINT_THIS_
	}
    } else {
	# Don't just error, as we need to restore-state before returning.
	echo Call to MemAlloc failed
	restore-state
    }
}]

##############################################################################
#				exit, tdetach
##############################################################################
#
# SYNOPSIS:	Cause an application to exit (or transparently detach)
# PASS:		patient	= name of the patient to be exited
# CALLED BY:	user
# RETURN:	none
# SIDE EFFECTS:	machine is continued twice.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/17/94		Initial Revision
#
##############################################################################
[defcommand exit {patient} top.running
{Usage:
    exit <patient>

Examples:
    "exit faxmon"	Causes the faxmon application to exit

Synopsis:
    Sends messages required to make an application quit.

Notes:
    * You cannot do this when you're stopped at FatalError, as this command
      will wait until the machine is idle before attempting to send the
      MSG_META_QUIT; continuing from FatalError will cause the system to
      exit.

See also:
    run, tdetach
}
{
    exit-common $patient MSG_META_QUIT
}]

[defcommand tdetach {patient} top.running
{Usage:
    tdetach <patient>

Examples:
    "tdetach faxmon"	Causes the faxmon application to save to state

Synopsis:
    Sends messages required to make an application save to state.

Notes:
    * You cannot do this when you're stopped at FatalError, as this command
      will wait until the machine is idle before attempting to send the
      MSG_META_QUIT; continuing from FatalError will cause the system to
      exit.

See also:
    run, exit
}
{
    exit-common $patient MSG_META_TRANSPARENT_DETACH
}]


[defsubr exit-common {patient msg} {
    if {[null [patient find $patient]]} {
    	error [format {patient "%s" not loaded} $patient]
    }
    
    #
    # Make sure the system is someplace safe, stopping at DOSIdleHook, rather
    # than Idle, as DOSIdleHook is called repeatedly while the machine remains
    # idle, while Idle is reached only on a transition to the idle state.
    #
    switch geos:0

    # if we are using gym files for the MS driver, or that patient was ignored
    # lets hope that being in the geos:0 thread is enough, it seems to work
    if {![null [sym find any DOSIdleHook]]} {
    	stop-catch {
    	    go DOSIdleHook
        }
        event dispatch FULLSTOP _DONT_PRINT_THIS_
    }
    
    #
    # Send a quit message to the patient's application object and continue the
    # machine to allow it to take effect.
    #
    omfq $msg [appobj $patient]
    cont
}]
