##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System library
# FILE: 	profile.tcl
# AUTHOR: 	John Wedgwood,  August 28th, 1991
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	profile	    	    	Counts cycles
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
# DESCRIPTION:
#	Routines/commands for cycle-counting
#
#	$Id: profile.tcl,v 1.8.11.1 97/03/29 11:28:08 canavese Exp $
#
###############################################################################
[require fetch-cycles	    timing.tcl]

##############################################################################
#				profile
##############################################################################
#
# SYNOPSIS:	Profile execution of a section of code.
# PASS:		nothing
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	the machine may execute one or more instructions
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defcommand profile {args} profile
{Profile a section of code producing output that shows what calls were made
and how long they took.
    -x <routine>        Step over calls to <routine>
    -x <routine>=<val>  Step over calls to <routine> and assume that the call
                        takes <val> cycles for timing purposes

Timing information will be accumulated starting at the current address and
continuing until a breakpoint is hit.
}
{
    #
    # Create the list of routines to exclude
    #
    global excludes

    var excludes [table create]

    while {[string match [index $args 0] -x]} {
	var r [index $args 1]
	
	var rend [string first {=} $r]
    	if {$rend < 0} {
	    var rtime 0
	} else {
	    var rtime [range $r [expr $rend+1] end chars]
	    var r     [range $r 0 [expr $rend-1] char]
	}
	table enter $excludes $r $rtime
	
	var args [cdr [cdr $args]]
    }
    
    #
    # Enter some routines which we always want to skip
    #
    [foreach i {DebugMemory DebugProcess DebugLoadResource
		FarDebugProcess FarDebugMemory FarDebugLoadResource UNKNOWN_ROUTINE}
    {
	table enter $excludes $i 0
    }]

    #
    # See if the current patient is the current thread on the PC. The simplest
    # way to do this is to get the current patient stats, switch to the real
    # current thread and see if its patient stats are the same as the ones
    # we've got saved.
    #
    var cp [patient data]
    switch
    if {[string c $cp [patient data]]} {
    	#
	# Nope. Need to wait for the desired patient to wake up.
	#
    	var who [index $cp 0]:[index $cp 2]
	echo Waiting for $who to wake up
	if {![wakeup-thread $who]} {
    	    #
	    # Wakeup unsuccessful -- return after dispatching the proper
	    # FULLSTOP event.
	    #
	    event dispatch FULLSTOP $lastHaltCode
	    return
    	}
	event dispatch FULLSTOP _DONT_PRINT_THIS_
    }

    #
    # Now start accumulating information.
    #
    # "protect" also handles getting an error during this. It's very
    # frustrating to be stepping for a while, get an error, then get no
    # output for all the instructions you've already executed, so we
    # make sure to produce whatever total we've figured so far, regardless
    # of interrupts or errors.
    #
    protect {
	global totalTime
	global callStack
	global routineTimes
	global indentLevel
	global lastHaltCode

	var totalTime 0
	var callStack [func]
	var routineTimes {}
	var jumpCallList {}
	var indentLevel 0

	#
	# Step until we get a breakpoint
	# The technique is:
	#   - Count the cycles for the current instruction without executing it
	#   - Handle stuff like CALL, JMP, INT
	#   - Deal with wierd instructions that we can't just step over
	#
	break-taken 0
	while {![break-taken]} {
	    var inst      [unassemble cs:ip 1]
    	    var cycles    [fetch-cycles [concat cs:ip [range $inst 1 end]]]
	    var totalTime [expr $totalTime+$cycles]

	    var stepped 0
	    [case [index $inst 1] in
	     INT* {
		#
		# check for a software interrupt call
		#
		var minst [mangle-softint $inst cs:ip]
		var a [index $minst 1]
		if {[string c [index $a 0] CALL] == 0} {
		    var stepped [step-routine *[index $a 1] $inst]
		}
	     }
	     JMP* {
		step-jump $inst
	     }
	     CALL* {
		var cmd [index $inst 1]
		if {[string first DebugMemory $cmd] != -1} {
		    # Skip DebugMemory
		} elif {[string first FarDebugMemory $cmd] != -1} {
		    # Skip FarDebugMemory
		} else {
		    if {![null [index $inst 3]]} {
			var a   [addr-parse [makeaddr [index $inst 3]]]
			var seg [handle segment [index $a 0]]
			var s   [sym faddr func $seg:[index $a 1]]
			if {![null $s]} {
			    var routine [sym name $s]
			} else {
			    var routine UNKNOWN_DESTINATION
			}
		    } else { 
			var rpos    [expr [string last { } $cmd]+1]
			var routine [range $cmd $rpos end chars]
		    }
		    var stepped [step-routine $routine $inst]
		}
	     }
	     RET* {
		step-return 0 $inst
	     }
	     IRET* {
		step-return 0 $inst
	     }
	    ]
	    
	    #
	    # If we've already executed the instruction, don't execute
	    # another one... This happens when we exclude a routine.
	    #
	    if {! $stepped} {
		#
		# Execute the next instruction, being careful of certain things
		#
		[case [index $inst 1] in
		 REP\[NE\]* {
		    #already taken care of
		 }
		 REP* {
		    #
		    # skip to next instruction...
		    #
		    step-over-inst $inst
		 }
		 MOV*\[DE\]S,* {
		    handle-mov-segment $inst
		 }
		 POP*\[DES\]S {
		    handle-pop-segment $inst
		 }
		 MOV*SS,* {
		    handle-mov-ss $inst
		 }
		 XCHG*SP* {
		    handle-xchg-sp $inst
		 }
		 INT* {
		    handle-int $inst
		 }
		 {CALL*DebugMemory CALL*DebugProcess CALL*DebugLoadResource} {
		    handle-special-call $inst
		 }
		 default {
		    #
		    # It's ok to single-step the next instruction...
		    #
		    stop-catch {
			step-patient
		    }
		    if [break-taken] {
			echo {*** Breakpoint ***}
		    } elif {![string match $lastHaltCode *Single*]} {
			echo $lastHaltCode
			break
		    }
		 }
		]
	    }
    	}
    } {
	#
	# Clean up on the way out...
	#
	profile-update $indentLevel {DONE} {} $totalTime

	table destroy $excludes
	#
	# Make sure any temporary breakpoints we set are gone and our state
	# is set up as if the machine stopped normally
	#
	event dispatch FULLSTOP _DONT_PRINT_THIS_
    }
}]

##############################################################################
#				step-routine
##############################################################################
#
# SYNOPSIS:	step into/over a routine
# CALLED BY:	profile
# PASS:	    	inst	    - Instruction that is the call
# RETURN:	1   	    - If the call was excluded
#   	    	0   	    - Otherwise
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr step-routine {routine inst}
{
    global  excludes
    global  totalTime
    global  indentLevel
    
    var xtime [table lookup $excludes $routine]

    #
    # Well, we're definitely going in...
    #
    if {![string compare [func] SetClipRectCommon]} {
	#
	# A call to SetClipRectCommon isn't really a call... The problem
	# is that it pops the return address off the stack and returns
	# to its callers caller... Sigh. I hate special case code.
	#
        push-call $routine $totalTime 1 $inst
    } else {
        push-call $routine $totalTime 0 $inst
    }

    if {![null $xtime]} {
    	#
	# We want to exclude this routine. Step over it.
	#
	step-over-inst $inst
	var totalTime [expr $totalTime+$xtime]
	pop-call $inst
	return 1
    } else {
    	#
	# The routine isn't one we want to exclude. 
	#
	return 0
    }
}]

##############################################################################
#				step-return
##############################################################################
#
# SYNOPSIS:	step over a return
# CALLED BY:	profile
# PASS:	    	isJump	- 0 if the instruction was a real 'ret'
#   	    	    	- 1 if the instruction was a 'jmp'
#   	    	inst	- Instruction which caused the return.
# RETURN:	nothing
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr step-return {isJump inst}
{
    global  indentLevel

    #
    # If we are returning into ExitGraphicsFill then we want to return only a 
    # single level rather than returning up 2 call-frames (since ExitGraphics
    # was jumped into).
    #
    # If we didn't do anything we would see:
    #	    ExitGraphics->ExitGraphicsFill->Caller
    # all in one step. 
    #
    # The problem is the call to ExitGraphicsFill was slighly put in
    # there by either EnterGraphicsText (or someone else). In this
    # case we want to not count the time spent in ExitGraphicsFill.
    #
    if {[string match [index $inst 3] ExitGraphicsFill*]} {
    	#
	# Don't count any of the code in here... Pretend that it was
	# part of ExitGraphics.
	#
	echo <Skipping ExitGraphicsFill code>
    } else {
	if {$indentLevel == 0} {
	    #
	    # We have returned from our current routine. Generate a break.
	    #
	    break-taken 1
	} elif {$isJump} {
	    pop-call $inst
	} else {
	    while {[pop-call $inst]} {
	    }
	}
    }
}]

##############################################################################
#				profile-update
##############################################################################
#
# SYNOPSIS:	give feedback...
# CALLED BY:	step-routine, step-return
# PASS:	    	indent	- Number of spaces to indent
#   	    	string	- Either START, END, DONE
#   	    	routine	- The name of the routine (or null if no routine)
#   	    	total	- The total number of cycles so far
# RETURN:	nothing
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr profile-update {indent string routine partial}
{
    global totalTime

    if {[null $partial]} {
	echo [format {%*s%-5s %-20s             %7d total}
		$indent {} $string $routine $totalTime]
    } else {
	echo [format {%*s%-5s %-20s %7d cyc %7d total}
		$indent {} $string $routine $partial $totalTime]
    }
}]

##############################################################################
#				step-jump
##############################################################################
#
# SYNOPSIS:	Handle a jmp instruction
# CALLED BY:	profile
# PASS:	    	inst	- The instruction we're about to execute
# RETURN:	nothing
# SIDE EFFECTS:	nothing
# STRATEGY
#   JMP instructions pose a unique problem. Sometimes a JMP
#   is just a JMP. Other times it is a CALL. Other times it
#   is a return.
#
#   No example is required for the basic JMP instruction.
#   EnterGraphics() is an example of a JMP as a RET.
#
#   The heuristic I use is this:
#   	JMP	constant
#   	    This is a basic JMP
#   	JMP	non_constant
#   	    This is a RET
#
#   Clearly there are ways to fool this heuristic, but this should
#   work for almost all cases.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr step-jump {inst}
{
    global totalTime
    global callStack

    #
    # First the special cases...
    #
    if {[string first PSL_afterDraw [index $inst 1]] != -1} {
    	#
	# This is the character drawing code returning to PutStringLow's
	# character drawing loop. Just ignore it.
	#
#	echo <returning to PutStringLow> |$inst|
	return
    }

    #
    # Figure out the function we're going to.
    #
    if {[null [index $inst 3]]} {
	#
	# It's a short jump...
	#
	var a [addr-parse [index [index $inst 1] 1]]
    } else {
	#
	# It's a real jump...
	#
	var a [addr-parse [makeaddr [index $inst 3]]]
    }

    var s {}
    
    if {! [null $a]} {
    	#
	# The address did parse.
	#
    	var seg [handle segment [index $a 0]]
    	var s   [sym faddr func $seg:[index $a 1]]
    }

    if {[null $s]} {
	#
	# Address didn't parse.
	#
	var routine UNKNOWN_DESTINATION
    } else {
	#
	# Address did parse, get the routine name
	#
	var routine [sym name $s]
    }

    #
    # Check the number of arguments to the JMP instruction.
    # JMPs to a constant address will have a single argument (the destination).
    # Other JMPs will have more than one argument (eg: DWORD xxx)
    #
    if {([length [index $inst 1]] == 3) || 
    	([string compare [func] EnterTranslate] == 0)} {
	#
	# We include a special case for EnterTranslate since it does some
	# really hokey stuff which we can't easily catch with our general
	# cases.
	#

    	#
	# This is a non-constant jump, we just assume that this is a return.
	# One important thing to note is that it isn't like a normal return.
	# A normal 'ret' will return up as many call-frames as are marked
	# with as having been jumped to. We only want to return up one frame.
	#
	step-return 1 $inst
    } else {
    	#
	# Jump with a constant as the argument.
	# Check to see if we are going to a different routine.
	#
#	echo ### $callStack
#	echo ### $routine

	if {![string compare [index $callStack 0] $routine]} {
	    #
	    # We are jumping into the same routine we are at now, do nothing
	    #
	} else {
	    #
	    # Changing routines. This is like a call, but it's a jump.
	    #
    	    [case $routine in
    	    	{VMPop_ExitVMFileFar} {
		    #
		    # Special case for a routine that is jumped to that returns
		    # to its caller's caller
		    #
		    push-call $routine $totalTime 0 $inst
    	    	}
    	    	* {
	    	    push-call $routine $totalTime 1 $inst
    	    	}
    	    ]
	}
    }
}]

##############################################################################
#				step-over-inst
##############################################################################
#
# SYNOPSIS:	step over an instruction.
# CALLED BY:	step-routine, profile
# PASS:	    	inst	    - Instruction to step over
# RETURN:	nothing
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr step-over-inst {inst}
{
    var bpt [stepcall $inst n]

    if {![null $bpt]} {
	brk clear $bpt
    }
    if {![brk isset cs:ip]} {
	break-taken 0
    }
}]

##############################################################################
#				push-call
##############################################################################
#
# SYNOPSIS:	Put a call on the call stack.
# CALLED BY:	step-routine, step-jump
# PASS:	    	routine	    - Name of the routine
#   	    	time	    - Current total time
#   	    	isJump	    - 1 if the call was a jump, 0 if a call
#   	    	inst	    - Instruction that caused the call
# RETURN:	nothing
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr push-call {routine time isJump inst}
{
    global callStack
    global routineTimes
    global jumpCallList
    global indentLevel

    var callStack    [concat $routine $callStack]
    var routineTimes [concat $time $routineTimes]
    var jumpCallList [concat $isJump $jumpCallList]

    profile-update $indentLevel {START} $routine {}
#    echo [format {%*sSTART %s : Push %s} $indentLevel {} $routine $inst]

    var indentLevel  [expr $indentLevel+1]
}]

##############################################################################
#				pop-call
##############################################################################
#
# SYNOPSIS:	Remove a call on the call stack.
# CALLED BY:	step-return
# PASS:	    	inst	- Instruction that caused the pop
# RETURN:	1 if this routine was jumped to
#   	    	0 if this routine was called
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr pop-call {inst}
{
    global callStack
    global routineTimes
    global jumpCallList
    global totalTime
    global indentLevel

    var routine [index $callStack 0]
    var time    [index $routineTimes 0]
    var isJump  [index $jumpCallList 0]
    var rtime	[expr $totalTime-$time]
    
    var callStack    [range $callStack    1 end]
    var routineTimes [range $routineTimes 1 end]
    var jumpCallList [range $jumpCallList 1 end]

    var indentLevel [expr $indentLevel-1]
    
#    echo [format {%*sEND   %s : Pop %s} $indentLevel {} $routine $inst]
#echo [format {*** %s *** %s} [frame function] $routine]

    profile-update $indentLevel {END} $routine $rtime

    return $isJump
}]


##############################################################################
#				handle-mov-segment
##############################################################################
#
# SYNOPSIS:	Handle a move to segment register
# CALLED BY:	profile
# PASS:	    	inst	- The instruction we're about to execute.
# RETURN:	cs:ip set to point after the instruction
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr handle-mov-segment {inst}
{
    #
    # The 8086 won't allow interrupts after the loading of a
    # segment register, thus causing the next instruction to be
    # skipped, as far as the user is concerned. To get around this,
    # we do the assigment here and advance IP by hand, thus
    # simulating the instruction.
    #
    var re [string first , [index $inst 1]]
    var sr [range [index $inst 1] [expr $re-2] [expr $re-1] chars]
    #
    # See if the source is a register or an effective address. If
    # the latter, the args string contains an = sign and the value
    # follows that. If the former, the args string contains only
    # the value.
    #
    var vs [string first = [index $inst 3]]
    if {$vs >= 0} {
	assign $sr [range [index $inst 3] [expr $vs+1] end chars]
    } else {
	assign $sr [index $inst 3]
    }
    assign ip ip+[index $inst 2]
}]

##############################################################################
#				handle-pop-segment
##############################################################################
#
# SYNOPSIS:	Handle popping a segment register
# CALLED BY:	profile
# PASS:	    	inst	- The instruction we're about to execute.
# RETURN:	cs:ip set to point after the instruction
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr handle-pop-segment {inst}
{
    #
    # Same as move-segment for popping a segment register, but the
    # value is harder to extract. The value being assigned looks like
    # [SP]=<num>, so we take characters from the args list
    # starting at char 5.
    #
    var il [length [index $inst 1] chars]
    [assign [range [index $inst 1] [expr $il-2] end chars]
	    [range [index $inst 3] 5 end chars]]
    assign ip ip+[index $inst 2]
    assign sp sp+2
}]

##############################################################################
#				handle-mov-ss
##############################################################################
#
# SYNOPSIS:	Handle moving a value into SS
# CALLED BY:	profile
# PASS:	    	inst	- The instruction we're about to execute.
# RETURN:	cs:ip set to point after the instruction
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr handle-mov-ss {inst}
{
    global totalTime
    global lastHaltCode

    #
    # We can't do the simulation as for DS and ES, as the
    # continuation of the machine to execute the following
    # instruction will whale on random pieces of memory. Instead,
    # we print the next instruction as well, to let the user know
    # it was executed.
    #
    var niaddr    cs:ip+[index $inst 2]
    var ni 	  [unassemble $niaddr 1]
    var cycles    [fetch-cycles $ni]
    var totalTime [expr $totalTime+$cycles]

    stop-catch {
	step-patient
    }

    if {![string match $lastHaltCode *Single*]} {
	echo $lastHaltCode
    }
}]

##############################################################################
#				handle-xchg-sp
##############################################################################
#
# SYNOPSIS:	Handle an xchg with sp
# CALLED BY:	profile
# PASS:	    	inst	- The instruction we're about to execute.
# RETURN:	cs:ip set to point after the instruction
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr handle-xchg-sp {inst}
{
    global totalTime

    #
    # Save CS and IP so we can figure out if we stopped in the
    # right place
    #
    var cs [frame register cs [frame top]]
    var ip [frame register ip [frame top]]

    #
    # Disassemble the next two instructions so we know where we
    # should set our breakpoint.
    #
    # XCHG SS:0[reg],SP
    #
    var ip        [expr $ip+[index $inst 2]]
    var addr      [index $inst 0]+[index $inst 2]
    var inst      [unassemble $addr 1]
    var cycles    [fetch-cycles $inst]
    var totalTime [expr $totalTime+$cycles]

    #
    # XCHG reg,SP
    #
    var addr      $addr+[index $inst 2]
    var ip	  [expr $ip+[index $inst 2]]
    var inst      [unassemble $addr 1]
    var cycles    [fetch-cycles $inst]
    var totalTime [expr $totalTime+$cycles]

    #
    # point after...
    #
    var addr $addr+[index $inst 2]
    var ip   [expr $ip+[index $inst 2]]

    #
    # Set a breakpoint there...
    #
    var tbrk [brk tset $addr]
    stop-catch {
	continue-patient
	wait
    }
    #
    # Make sure we're stopped where we want to be. If not, tell
    # why we stopped.
    #
    [if {[frame register cs [frame top]] != $cs ||
	 [frame register ip [frame top]] != $ip}
     {
	break
    }]
    brk clear $tbrk

    #
    # if wasn't already a breakpoint here, clear the break-taken
    # flag so we don't exit.
    #
    if {![brk isset cs:ip]} {
	break-taken 0
    }
}]

##############################################################################
#				handle-int
##############################################################################
#
# SYNOPSIS:	Handle an INT instruction
# CALLED BY:	profile
# PASS:	    	inst	- The instruction we're about to execute.
# RETURN:	cs:ip set to point after the instruction
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr handle-int {inst}
{
    #
    # Wants to step into the interrupt routine. Find where it's
    # going and set a breakpoint there.
    #
    var intnum [index [index $inst 1] 1]
    if {$intnum < 0} {
	var intnum [expr 256+$intnum]
    }
    var tbrk [brk tset {*(dword 0:[expr 4*$intnum])}]
    stop-catch {
	continue-patient 1
	wait
    }
    brk clear $tbrk

    #
    # if wasn't already a breakpoint here, clear the break-taken
    # flag so we don't exit.
    #
    if {![brk isset cs:ip]} {
	break-taken 0
    }
}]

##############################################################################
#				handle-special-call
##############################################################################
#
# SYNOPSIS:	Handle a call to the swat stub
# CALLED BY:	profile
# PASS:	    	inst	- The instruction we're about to execute.
# RETURN:	cs:ip set to point after the instruction
# SIDE EFFECTS:	nothing
# STRATEGY
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/28/91	Initial Revision
#
##############################################################################
[defsubr handle-special-call {inst}
{
    #
    # Going into Swat -- skip over the call.
    #
    var tbrk [brk tset cs:ip+3]
    stop-catch {
	continue-patient 1
	wait
    }
    brk clear $tbrk
    #
    # if wasn't already a breakpoint here, clear the break-taken
    # flag so we don't exit.
    #
    if {![brk isset cs:ip]} {
	break-taken 0
    }
}]
