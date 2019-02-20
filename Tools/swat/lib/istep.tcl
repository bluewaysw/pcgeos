##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	istep.tcl
# AUTHOR: 	Adam de Boor, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	safe-step   	    	Single steps the given instruction,
#   	    	    	    	taking care of processor idiosyncracies
#   	istep	    	    	Interactive single-stepping
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Interactive single stepping
#
#	$Id: istep.tcl,v 3.14 91/01/25 20:29:22 roger Exp $
#
###############################################################################

[defvar stepSoftInts 0 variable.step
{If non-zero, stepping into one of the special PC/GEOS software interrupts
will land you in the kernel, not the destination of the interrupt. For normal
people (i.e. not kernel maintainers), this should be (and defaults to) 0}]

[defsubr safe-step {inst}
{
    global lastHaltCode
    global showMethodNames
    global stepSoftInts    

    [case [index $inst 1] in
     MOV*\[DE\]S,* {
     	#
	# The 8086 won't allow interrupts after the loading of a segment
	# register, thus causing the next instruction to be skipped, as far
	# as the user is concerned. To get around this, we do the assigment
	# here and advance IP by hand, thus simulating the instruction.
	#
	var re [string first , [index $inst 1]]
	var sr [range [index $inst 1] [expr $re-2] [expr $re-1] chars]
	#
	# See if the source is a register or an effective address. If the
	# latter, the args string contains an = sign and the value follows
	# that. If the former, the args string contains only the value.
	#
	var vs [string first = [index $inst 3]]
	if {$vs >= 0} {
	    assign $sr [range [index $inst 3] [expr $vs+1] end chars]
	} else {
	    assign $sr [index $inst 3]
	}
	assign ip ip+[index $inst 2]
     }
     POP*\[DES\]S {
     	#
	# Ditto for popping a segment register, but the value is harder to
	# extract. The value being assigned looks like [SP]=<num>, so
	# we take characters from the args list starting at char 5.
	#
	var il [length [index $inst 1] chars]
	[assign [range [index $inst 1] [expr $il-2] end chars]
	    	[range [index $inst 3] 5 end chars]]
	assign ip ip+[index $inst 2]
    	assign sp sp+2
     }
     MOV*SS,* {
    	#
	# We can't do the simulation as for DS and ES, as the
	# continuation of the machine to execute the following instruction
	# will whale on random pieces of memory. Instead, we print the
	# next instruction as well, to let the user know it was executed.
	#
     	var ni [unassemble cs:ip+[index $inst 2] 1]
	echo [format-instruction $ni $showMethodNames]
	
	stop-catch {
	    step-patient
	}
	if [break-taken] {
	    echo {*** Breakpoint ***}
	} elif {![string match $lastHaltCode *Single*]} {
	    echo $lastHaltCode
	}
     }
     XCHG*SP* {
    	#
    	# Save CS and IP so we can figure out if we stopped in the right place
    	#
    	var cs [frame register cs [frame top]]
    	var ip [frame register ip [frame top]]

    	echo -n Skipping XchgTopStack...

    	#
    	# Disassemble the next two instructions so we know where we should
    	# set our breakpoint.
    	#
    	# XCHG SS:0[reg],SP
    	var ip [expr $ip+[index $inst 2]]
    	var addr [format {%s+%d} [index $inst 0] [index $inst 2]]
    	var inst [unassemble $addr]
    	# XCHG reg,SP
    	var addr [format {%s+%d} $addr [index $inst 2]]
    	var ip [expr $ip+[index $inst 2]]
    	var inst [unassemble $addr]
    	# point after...
    	var addr [format {%s+%d} $addr [index $inst 2]]
    	var ip [expr $ip+[index $inst 2]]
    	#
    	# Set a breakpoint there...
    	#
    	brk tset $addr
    	stop-catch {
    	    continue-patient
    	    wait
    	}
    	echo done
    	#
    	# Make sure we're stopped where we want to be. If not, tell why we
    	# stopped.
    	#
    	[if {[frame register cs [frame top]] != $cs ||
    	     [frame register ip [frame top]] != $ip}
    	 {
	    if [break-taken] {
    	    	echo {*** Breakpoint ***}
    	    } elif {![string match $lastHaltCode *Single*]} {
    	    	echo $lastHaltCode
    	    }
    	}]
     }
     INT* {
     	#
	# Wants to step into the interrupt routine. Find where it's going
	# and set a breakpoint there.
	#
    	var i [mangle-softint $inst]
	if {[string c [index [index $i 1] 0] CALL] == 0} {
	    #
	    # Not really an interrupt after all. If stepSoftInts not true,
	    # we need to set a breakpoint at the destination of the call.
    	    #
	    if {!$stepSoftInts} {
		brk tset [index [index $i 1] 1]
    	    	stop-catch {
		    continue-patient 1
		    wait
		}
    	    	return
	    }
	}
    	var inst [index $inst 1]
	var num [index $inst 1]
	if {$num < 0} {var num [expr 256$num]}
	var seg [value fetch 0:[expr 4*$num+2] word]
	var off [value fetch 0:[expr 4*$num] word]
	brk tset $seg:$off
    	#
	# Set a breakpoint immediately after the interrupt too, in case the
	# handler is in ROM -- we can't set a breakpoint there and not setting
	# one after the interrupt will cause us to lose control. Note the use 
	# of $i in case the thing is a special software interrupt -- don't want
	# to trash the following data...
	#
    	brk tset cs:ip+[index $i 2]
	stop-catch {
	    continue-patient 1
	    wait
    	}
     }
     RETF* {
    	#
    	# If we're returning from a software interrupt call, do the right thing
    	#
	if {$stepSoftInts || [string c [index $inst 3] RCI_ret]} {
    	    defaultStep
    	    return
	}
    	brk tset RCI_end
    	continue-patient 1
    	defaultStep
    	}
     default {
    	#
    	# It's ok to single-step the next instruction...
    	#
    	defaultStep
    }]
}]

[defsubr defaultStep {} {
    global lastHaltCode

    stop-catch {
    	step-patient
    }
    if [break-taken] {
    	echo {*** Breakpoint ***}
    } elif {![string match $lastHaltCode *Single*]} {
    	echo $lastHaltCode
    }
}]

[defcommand istep {{defcmd s}} step|top
{istep [default command]
"is"
"istep J"

Step through the execution of the current patient.
This is THE command for stepping through code.

* The default command argument determines what pressing the return key
does.  By default, return executes a step command.  Any other command
listed below may be substituted by passing the letter of the command.

Istep steps through the patient instruction by instruction, printing
where the ip is, what instruction will be executed, and what the
instruction arguments contain or reference.  Istep waits for the user
to type a command which it performs and then prints out again where
istep is executing.

This is a list of istep commands:

    q, ESC, ' '	Stops istep and returns to command level.
    b           Toggles a breakpoint at the current location.
    c           Stops istep and continues execution.
    n		Continues to the next instruction, skipping procedure calls,
 		repeated string instructions, and software interrupts. Only
		stops when the machine returns to the right context (i.e. the
		stack pointer and current thread are the same as they are
		when the 'n' command was given).
    l		Goes to the next library routine.
    N	    	Like n, but stops whenever the breakpoint is hit, whether
    	    	you're in the same frame or not.
    M           Goes to the next method called.   Doesn't work when the method
    		is not handled anywhere (sorry, I forgot).
    f	    	Finishes out the current stack frame.
    s, RET    	Steps one instruction.
    S		Skips the current instruction
    J	    	Jump on a conditional jump, even when "Will not jump" 
		appears.  This does not change the condition codes.
    g	    	Executes the 'go' command with the rest of the line as
    	    	arguments.
    e 		Executes a tcl command and returns to the prompt.

Emacs will load in the correct file executing and following the lines
where istep is executing if its server is started and if ewatch is on
in swat.  If ewatch is off emacs will not be updated.

If the current patient isn't the actual current thread, this will wait for the
patient to wake up before single-stepping it.

See also listi, ewatch.
}


{
    global lastHaltCode window-system showMethodNames

    if {[length $args] == 1} {
    	var defcmd [range [index $args 0] 0 0 chars]
    }

    #
    # Need a newline if not under the shell window-system
    #
    var nl [string c ${window-system} shell]

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

    for {} {[irq] != 1} {} {
    	if {[null $what]} {
    	    #no input pushed back by bogus go command...
	    var inst [unassemble cs:ip 1]
	    if {[string match [index $inst 1] RET*]} {
		#
		# If the instruction is a return, make sure the current SP is
		# the same as the SP in the calling frame (which points to the
		# return address)
		#
		var nf [frame next [frame top]]
		[if {![null $nf] && [read-reg sp] != [frame register sp $nf]}
		{
		    echo -n *** Warning: SP not pointing at return address
		    echo (off by [expr [frame register sp $nf]-[read-reg sp]])
		}]
	    }
	    echo -n [format-instruction $inst $showMethodNames] {}

    	    var what [read-char 0]
	    #
	    # Line-feed if necessary (and desired). Use string match for
	    # expansion's sake
	    #
	    if {$nl && ![string match $what {[g]}]} echo
	}
	#
	# If line was blank, use the default command
	# 
	if {[string c $what \n] == 0} {
	    var what $defcmd
	}
	[case $what in
	 s {
	     #
	     # Execute a single instruction and loop.
	     # 
	     safe-step $inst
	 }
	 \[q\e\040\] {
	     #
	     # Stop this nonsense now
	     # 
	     break
	 }
	 M {
	    #
	    # Go to the method
	    #
	    stop-catch {go ObjCallModuleMethod CallFixed}
	    event dispatch FULLSTOP _DONT_PRINT_THIS_
	    stop-catch {
	      var inst [unassemble cs:ip]
	      [if {[string c [index $inst 0] ObjCallModuleMethod] == 0}
	        {go ^hbx:ax}
		{go {*(dword es:bx)}}
		]}
	}
	 b {
	    #
	    # Toggle a breakpoint at the current location
	    #
	    var loc [index $inst 0]
	    var num [brk list cs:ip]
	    if {[null $num] == 0} {
		brk del [index $num 0]
	        echo [format { breakpoint %d cleared at %s} [index $num 0] $loc]
	    } else {
	        brk aset cs:ip
		var bpn [brk list cs:ip]
	        echo [format { breakpoint %d set at %s} $bpn $loc]
	    }
	}
	l {
	    #
	    # Go to the library routine
	    #
	    stop-catch {go ProcCallModuleRoutine}
	    event dispatch FULLSTOP _DONT_PRINT_THIS_
	    stop-catch {go ^hbx:ax}
	 }
	 c {
	     #
	     # Continue the patient and break out when  cont  returns.
	     # 
	     cont
	     break
	 }
	 f {
	     #
	     # Finish the current frame and loop when done
	     # 
	     finishframe [frame top]
	 }
	 F {
	     #
	     # Finish an object call.
	     # 
	     var curFrame [frame top]

	     var kernel [patient find kernel]
	     
	     do {
	        var prevFrame $curFrame
	     	var curFrame [frame next $curFrame]
	     } while {![string c [symbol patient [frame funcsym $curFrame]]
	     	    	    	    	    	    	 $kernel]}
	     
	     finishframe $prevFrame
	 }
	 \[Nn\] {
	    #
	    # Skip over the next procedure call/repeated string operation.
	    # If it's neither, just single-step, otherwise set a breakpoint
	    # after the instruction (as obtained by adding its length to
	    # cs:ip) and allow the machine to continue, keeping control of
	    # the interpreter.
	    # 
	    # Make sure we don't biff inline data for OS/90 softint "calls"
	    var inst [mangle-softint $inst]
	    [case [index $inst 1] in
	     REP*|CALL*|INT* { [stepcall $inst $what] }
	     default {
		#
		# Single step the thing as above
		# 
		safe-step $inst
	    }]
	 }
	 g {
    	    #prompt with nothing, start with "go "
	    var l [top-level-read {} {go }]
	    if {[string match $l go*]} {
	    	stop-catch {
		    eval $l
	     	}
		#
		# If didn't stop because of a breakpoint or we're somewhere
		# we weren't before, get out of here after dispatching the
		# proper FULLSTOP event.
		#
		[if {![string m $lastHaltCode *Breakpoint*] ||
		     [string c [patient data] $cp] != 0}
		{
		    event dispatch FULLSTOP $lastHaltCode
		    break
		}]
    	    } elif {[length $l chars] != 0} {
    	    	#take first char as actual command to exec
	    	var what [index $l 0 chars]
		continue
	    }
	 }
	 e {
    	    #prompt with nothing
	    var l [top-level-read {} {}]
	    stop-catch {
		    eval $l
	    }
	 }
	 S {
	     echo Skipping...
	     skip 1
	 }
    	 J {
    	    var i [index $inst 1]
    	    if {![string match [car $i] J*]} {
    	    	echo Error: the jump command follows conditional jumps only.
    	    } else {
    	    	assign ip [cdr $i]
    	    }
    	    
    	 }
	 \\? {
	     echo [help istep]
	 }
	 default {
	     echo Excuse me?
	 }
	]
    	#reset input variable so don't repeat endlessly
	var what {}
	event dispatch FULLSTOP _DONT_PRINT_THIS_
	if {[string compare [patient data] $cp] != 0} {
	    break
	}
    }
}]

#
# Step over a CALL, INT or REP
#
#	what = "n" or "N"
#
[defsubr stepcall {inst what} {
    global lastHaltCode

    var ip [expr [read-reg ip]+[index $inst 2]] cs [read-reg cs]

    #
    # EnterHeap and EnterGraphics are tony-code, so they push
    # things on the stack before returning. If calling
    # either of them, set a breakpoint at the next address
    # regardless
    #
    [case [index $inst 1] in
        {*EnterHeap*|*EnterGraphics*|*PushAll*|*PopAll*|*VMPush_OverRide_EnterVMFile*|*FileErrorCatchStart*}
    	{
    	    #
	    # These things play with the stack in unhealthy ways, so just set
	    # an unconditional breakpoint as we would for N
	    #
	    brk tset $cs:$ip
    	}
	default {
	    if {[string c $what n] == 0} {
		#
		# Set a temporary breakpoint at the next instruction,
		# making sure we're back where we are now before
		# stopping there (sp and thread # the same)
		#
		[brk tset $cs:$ip 
		   [format {[expr {[read-reg sp] >= %d &&
				   [index [patient data] 2] == %d}]}
			   [read-reg sp]
			   [index [patient data] 2]]]
	    } else {
		#
		# Set a temporary breakpoint at the next instruction,
		# regardless of where we are when we hit it.
		#
		brk tset $cs:$ip
	    }
    	}
    ]

    stop-catch {
	continue-patient
	wait
    }
    [if {[read-reg ip] != $ip || [read-reg cs] != $cs ||
	 ![string m $lastHaltCode *Breakpoint*]}
     {
	echo $lastHaltCode
     }]
}]

[defcommand skip {{n 1}} top
{Skip the current instruction. Optional argument is number of
instructions to skip}
{
    for {} {$n > 0} {var n [expr $n-1]} {
	var inst [mangle-softint [unassemble cs:ip]]
	assign ip [expr [read-reg ip]+[index $inst 2]]
    }
}]
