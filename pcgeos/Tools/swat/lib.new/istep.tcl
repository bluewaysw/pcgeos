##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#    	istep	    	    	Interactive single-stepping
#   	sstep	    	    	Interactive single-stepping
#   	step-while  	    	Single-step the machine while the given
#				expression evaluates non-zero
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Interactive single stepping
#
#	$Id: istep.tcl,v 3.81.5.1 97/03/29 11:27:11 canavese Exp $
#
###############################################################################

[defvar stepSoftInts 0 swat_variable.step
{If non-zero, stepping into one of the special GEOS software interrupts
will land you in the kernel, not the destination of the interrupt. For normal
people (i.e. not kernel maintainers), this should be (and defaults to) 0}]

#
# Event handler to record the start and end of the swat stub on attach. this
# info is used by safe-step to decide whether to emulate a push of a segment
# register.
#
[defsubr _record_swat_seg {args}
{
    global swat_seg_bounds

    var h [handle find SwatSeg:0]
    var swat_seg_bounds [list [handle segment $h] [expr [handle segment $h]+([handle size $h]>>4)]]
    return EVENT_HANDLED
}]

##############################################################################
#				safe-step
##############################################################################
#
# SYNOPSIS:	Handle the various special-cases of single stepping needed
#   	    	to retain control of the machine, see all the instructions
#   	    	being executed, and hide some hacks in the system.
# PASS:		insn	= instruction list of instruction to be stepped,
#			  including operand values
#   	    	addr	= parseable address from which it comes
# CALLED BY:	istep
# RETURN:	possibly-empty list of temporary breakpoints set to
#   	    	    handle stepping the instruction.
# SIDE EFFECTS:	the machine may execute one or more instructions
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defsubr safe-step {insn}
{
    global lastHaltCode
    global showMethodNames
    global stepSoftInts    

    [case [index $insn 1] in
     MOV*\[DE\]S,* {
     	#
	# The 8086 won't allow interrupts after the loading of a segment
	# register, thus causing the next instruction to be skipped, as far
	# as the user is concerned. To get around this, we do the assigment
	# here and advance IP by hand, thus simulating the instruction.
	#
	var re [string first , [index $insn 1]]
	var sr [range [index $insn 1] [expr $re-2] [expr $re-1] chars]
	#
	# See if the source is a register or an effective address. If the
	# latter, the args string contains an = sign and the value follows
	# that. If the former, the args string contains only the value.
	#
	var vs [string first = [index $insn 3]]
	if {$vs >= 0} {
	    assign $sr [range [index $insn 3] [expr $vs+1] end chars]
	} else {
	    assign $sr [index $insn 3]
	}
	assign ip ip+[index $insn 2]
     }
     MOV*,*\[CDES\]S {
     	#
	# The V20 won't allow interrupts after the storing of a segment
	# register, thus causing the next instruction to be skipped, as far
	# as the user is concerned. To get around this, we do the assigment
	# here and advance IP by hand, thus simulating the instruction.
	#
	var re [string first , [index $insn 1]]
	var sr [index [range [index $insn 1] [expr $re+1] end chars] 0]
	#
	# See if the dest is a register or an effective address. If the
	# latter, the args string contains a comma, before which is the
	# effective addressan = sign and the value follows
	# that. If the former, the args string contains only the value.
	#
	var vs [string first , [index $insn 3]]
	if {$vs >= 0} {
	    var addr_name [range [index $insn 3] 0 [expr $vs-1] chars]
	    if {[string match $addr_name abs*]} {
    	    	#
	    	# "absolute" addresses can be reached by using a segment of 0
		# and the 32-bit linear offset of the argument
		#
	    	var addr_name 0:[range $addr_name 4 end char]
    	    } else {
    	    	#
	    	# take the address of the variable as a far byte ptr to make
		# sure any +nnn that follows will simply add that many to the
		# address, not generate the value of the variable plus that
		# amount, nor add nnn*sizeof(variable) to the base of the 
		# variable
		#
	    	var addr_name [format {(byte _far *)&%s} $addr_name]
    	    }
	    value store $addr_name [read-reg $sr] [type word]
	} else {
	    # extract the register name w/o spaces by skipping the MOV and
	    # stopping before the comma, using "index" get rid of the remaining
	    # whitespace
	    assign [index [range [index $insn 1] 3 [expr $re-1] char] 0] $sr
	}
	assign ip ip+[index $insn 2]
     }
     POP*\[DE\]S {
     	#
	# Ditto for popping a segment register, but the value is harder to
	# extract. The value being assigned looks like [SP]=<num>, so
	# we take characters from the args list starting at char 5.
	#
	var il [length [index $insn 1] chars]
	[assign [range [index $insn 1] [expr $il-2] end chars]
	    	[range [index $insn 3] 5 end chars]]
	assign ip ip+[index $insn 2]
    	assign sp sp+2
     }
     PUSH*\[CDES\]S {
     	#
    	# The chip in the Poqet also disables single-steps following the
	# pushing of segment registers. Blech. The argument string is the
	# value of the segment register.
	#
	global swatSegStackEvent swat_seg_bounds
	if {[null $swatSegStackEvent]} {
	    var swatSegStackEvent [event handle ATTACH _record_swat_seg]
	    _record_swat_seg
	}
	
	var ss [read-reg ss]
	[if {$ss < [index $swat_seg_bounds 0] ||
	     $ss >= [index $swat_seg_bounds 1]}
    	{
	    push [index $insn 3]
	    assign ip ip+[index $insn 2]
    	} else {
    	    #
	    # Can't perform this emulation when operating on the stub's
	    # stack, as we'd have to shift the state block down and do other
	    # nasty things...
	    #
	    defaultStep
    	}]
     }
     {MOV*SS,* POP*SS} {
    	#
	# We can't do the simulation as for DS and ES, as the
	# continuation of the machine to execute the following instruction
	# will whale on random pieces of memory. Instead, we print the
	# next instruction as well, to let the user know it was executed.
	#
     	var ni [unassemble cs:ip+[index $insn 2] 1]
	echo [format-instruction $ni cs:ip+[index $insn 2] $showMethodNames]
	
	stop-catch {
	    step-patient
	}
	if [break-taken] {
	    echo {*** Breakpoint ***}
	} elif {![string match $lastHaltCode *Single*]} {
	    echo $lastHaltCode
	}
     }
     {MOV*SP,*[CDE]S} {
     	#
	# Likely about to load ss:sp, which we have to be careful about.
	#
    	var l [index $insn 2]
    	# show MOV SS, SP instruction. no args, as SP not actually set to
	# the segment, so it'd be wrong in the display...
	var ni [unassemble cs:ip+$l 0]
	echo [format-instruction $ni cs:ip+$l $showMethodNames]
	var l [expr $l+[index $ni 2]]
	
    	# show MOV SP, xxx instruction, with args
	var ni [unassemble cs:ip+$l 1]
	echo [format-instruction $ni cs:ip+$l $showMethodNames]
	var l [expr $l+[index $ni 2]]
	
    	#
    	# Save CS and IP so we can figure out if we stopped in the right place
    	#
    	var cs [frame register cs [frame top]]
    	var ip [expr [frame register ip [frame top]]+$l]

    	var bpt [brk tset $cs:$ip]
	stop-catch {
	    continue-patient
	    wait
	}
	
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
    	var ip [expr $ip+[index $insn 2]]
    	var addr [index $insn 0]+[index $insn 2]
    	var insn [unassemble $addr]
    	# XCHG reg,SP
    	var addr $addr+[index $insn 2]
    	var ip [expr $ip+[index $insn 2]]
    	var insn [unassemble $addr]
    	# point after...
    	var addr $addr+[index $insn 2]
    	var ip [expr $ip+[index $insn 2]]
    	#
    	# Set a breakpoint there...
    	#
    	var bpt [brk tset $addr]
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
    	var i [mangle-softint $insn cs:ip]

	var num [index [index $insn 1] 1]
	if {$num < 0} {
	    # peculiarities of compiled expressions require us to first
	    # set num to the expression we want it to hold, and then
	    # pass that to expr (where it will be interpreted as a string,
	    # not some compiled expression whose value can't be taken).
	    # eventually, this may change, but not any time soon...
	    # 	-- ardeb 1/18/94
	    var num 256${num}
	    var num [expr $num]
	}

	var dest [value fetch 0:[expr 4*$num+2] word]:[value fetch 0:[expr 4*$num] word]

	if {[string c [index [index $i 1] 0] CALL] == 0} {
	    #
	    # Not really an interrupt after all. If stepSoftInts not true,
	    # we need to set a breakpoint at the destination of the call, not
	    # the destination of the interrupt. Don't use the operand of the
	    # mangled CALL instruction, as we may not have that symbol in
	    # our search path. Instead, form the ^h<hid>:<off> address of the
	    # destination from the 4 bytes that follow the 0xcd opcode.
    	    #
	    if {!$stepSoftInts} {
    	    	var dest ^h[expr ([value fetch cs:ip+2 byte]<<8)|(([value fetch cs:ip+1 byte]&0xf)<<4)]:[value fetch cs:ip+3 word]
	    }
	} elif {[string c [index [index $i 1] 0] INT] != 0} {
    	    #
	    # Borland/Microsoft floating-point artifact -- make the dest be
	    # the instruction after the emulated thing.
	    #
	    var dest cs:ip+[index $i 2]
    	}
    	#
	# Set a breakpoint immediately after the interrupt too, in case the
	# handler is in ROM -- we can't set a breakpoint there and not setting
	# one after the interrupt will cause us to lose control. Note the use 
	# of $i in case the thing is a special software interrupt -- don't want
	# to trash the following data...
	#
    	var bpt [concat [brk tset $dest] [brk tset cs:ip+[index $i 2]]]
	stop-catch {
	    continue-patient
	    wait
    	}
     }
     RETF* {
    	#
    	# If we're returning from a software interrupt call, do the right thing
    	#
	if {$stepSoftInts || [string c [index $insn 3] RCI_ret] != 0} {
    	    defaultStep
    	    return
	}
    	var b [brk tset RCI_end]
    	stop-catch {
    	    continue-patient
	    wait
	}
	brk clear $b
    	defaultStep
    	}
     {MOV*SP,*} {
	#
	# Deal with hosebags who like to use sp to set ss and then set
	# sp to something else...
	#
	var ni [unassemble cs:ip+[index $insn 2] 1]
	if {[string match [index $ni 1] {MOV*SS,*}]} {
	    #
	    # Save CS and IP so we can figure out if we stopped in the right
	    # place
	    #
	    var cs [frame register cs [frame top]]
	    var ip [frame register ip [frame top]]
	    
	    echo [format-instruction $ni cs:ip+[index $insn 2] 
	    		$showMethodNames]
	    #
	    # Next instruction will be mov sp, foo and we must skip it as
	    # well...
	    #
	    var off [index $insn 2]
	    var ni [unassemble cs:ip+$off+[index $ni 2] 1]
	    echo [format-instruction $ni cs:ip+$off+[index $ni 2]
	    		$showMethodNames]
	    #
	    # Set a breakpoint after that instruction and let the machine
	    # go until then.
	    #
	    var bpt [brk tset cs:ip+$off+[index $insn 2]]
	    stop-catch {
	    	continue-patient
		wait
	    }
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
	} else {
	    defaultStep
	}
     }
     default {
    	#
    	# It's ok to single-step the next instruction...
    	#
    	defaultStep
    }]
    return $bpt
}]

##############################################################################
#				defaultStep
##############################################################################
#
# SYNOPSIS:	Perform single-step for default case where no care is needed
# PASS:		nothing
# CALLED BY:	safe-step
# RETURN:	nothing
# SIDE EFFECTS:	the machine will execute a single instruction
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/31/91		Initial Revision
#
##############################################################################
[defsubr defaultStep {} {
    global lastHaltCode file-os

    stop-catch {
    	step-patient
    }
    if [break-taken] {
    	echo {*** Breakpoint ***}
    } elif {![string match $lastHaltCode *Single*]} {
    	echo $lastHaltCode
    }
}]

##############################################################################
#				istep-go-to-next-method
##############################################################################
#
# SYNOPSIS:	Allow the machine to continue until we reach the start of
#		next method called, regardless of whether it's the one
#		at whose invocation we might be located.
# PASS:		nothing
# CALLED BY:	istep, sstep
# RETURN:	nothing
# SIDE EFFECTS:	registers change, of course. _DONT_PRINT_THIS_ FULLSTOP event
#		is dispatched.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/21/93		Initial Revision
#
##############################################################################
[defsubr istep-go-to-next-method {}
{
    if {[not-1x-branch]} {
    	# go until we reach one of the three labels that says the kernel has
	# found a method to call
	stop-catch {
	    go ObjCallModuleMethod CallFixed CallCHandler OCMT_none
	}
    } else {
	stop-catch {go ObjCallModuleMethod CallFixed OCMT_none}
    }
    event dispatch FULLSTOP _DONT_PRINT_THIS_
    #
    # Use the registers to decide what method's going to be called, and
    # go to its beginning.
    #
    stop-catch {
	var insn [unassemble cs:ip]
	[case [index $insn 0] in
	    {ObjCallModuleMethod} {
		go ^hbx:ax
	    }
	    {CallFixed} {
		go {*(dword es:bx)}
	    }
	    {CallCHandler} {
		if {[read-reg bx] >= 0xf000} {
		    var addr ^h[expr ([read-reg bx]&0xfff)<<4]:[read-reg ax]
		} else {
		    var addr bx:ax
		}
		#
		# Want to get past the prologue so everything's set up
		# nicely, so first look for the function symbol, then
		# for the special ??START label within it and go
		# to the appropriate place.
		#
		var s [symbol faddr proc $addr]
		if {![null $s]} {
		    var s [symbol find label ??START $s]
		    if {![null $s]} {
			go [symbol fullname $s]
		    } else {
			go $addr
		    }
		} else {
		    go $addr
		}
	    }
	]
    }
}]

##############################################################################
#				istep
##############################################################################
#
# SYNOPSIS:	Interactive assembly-language step command
# PASS:		defcmd	= default command to use if <enter> is given
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/31/91		Initial Revision
#
##############################################################################
[defcmd istep {{defcmd s}} top.step
{Usage:
    istep [<default command>]

Examples:
    "is"	enter instruction step mode
    "istep n"  	enter instruction step mode, <ret> does a next command

Synopsis:
    Step through the execution of the current patient.
    This is THE command for stepping through code.

Notes:
    * The default command argument determines what pressing the return
      key does.  By default, return executes a step command.  Any
      other command listed below may be substituted by passing the
      letter of the command.

    * Istep steps through the patient instruction by instruction,
      printing where the ip is, what instruction will be executed, and
      what the instruction arguments contain or reference.  Istep
      waits for the user to type a command which it performs and then
      prints out again where istep is executing.

    * This is a list of istep commands:

        q, ESC, ' ' Stops istep and returns to command level.
        c           Continues execution. (Quits istep as well)

        s, RET      Steps one instruction.
        n	    Continues to the next instruction, skipping procedure
    	    	    calls, repeated string instructions, and software
    	    	    interrupts.  Next only stops when the machine returns 
    	    	    to the right context (i.e. the stack pointer and 
    	    	    current thread are the same as they are when the 'n' 
    	    	    command was given).  Routines which change the stack
    	    	    pointer should use 'N' instead.
        l   	    Goes to the next library routine.
        M   	    Goes to the next method called.

        b           Toggles a breakpoint at the current location.

        f	    Finishes out the current stack frame.
        F	    Finishes the current method.

    	N	    Like 'n', but stops whenever the breakpoint is hit,
    	    	    whether you're in the same frame or not.
    	o   	    Like 'n' but steps over macros as well.
    	O   	    Like 'N' but steps of macros as well.

	A	    Aborts the current stack frame.
	B	    Backs up an instruction (opposite of "S").
        J	    Jump on a conditional jump, even when "Will not jump" 
		    appears.  This does not change the condition codes.
        S	    Skips the current instruction (opposite of "B").

        h, ?	    This help message.
        r 	    list the registers (uses the regs command)
	R	    References either the function to be called or the 
		    function currently executing

        e 	    Executes a tcl command and returns to the prompt.
        g	    Executes the 'go' command with the rest of the line as
    	    	    arguments.

    * Emacs will load in the correct file executing and following the
      lines where istep is executing if its server is started and if
      ewatch is on in swat.  If ewatch is off emacs will not be updated.

    * If the current patient isn't the actual current thread, istep
      waits for the patient to wake up before single-stepping it.

See also:
    sstep, listi, ewatch.
}


{
    global lastHaltCode window-system showMethodNames srcwinmode

    # variable used for dealing with bound key presses during interactive
    # commands
    var	gotnull {}

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
    # we've got saved. "switch" also resets the current frame, even if we're
    # on the current thread already.
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
    if {[catch {src line [frame register pc]} curLine] != 0} {
	# Couldn't map the address to a source line, so just set
	# $curLine to null -- everything else should just work.
	var curLine {}
    } else {
    	var srcwinmode _srcwin
    	event dispatch FULLSTOP _DONT_PRINT_THIS_
    }
    for {} {[irq] != 1} {} {
    	if {[null $gotnull]} {
    	    var insn [unassemble cs:ip 1]
	    echo -n [format-instruction $insn cs:ip $showMethodNames] {}
    	} else {
    	    var gotnull {}
    	}
    	if {[null $what]} {
    	    #no input pushed back by aborted "go" command...
	    if {[string match [index $insn 1] RET*]} {
		#
		# If the instruction is a return, make sure the current SP is
		# the same as the SP in the calling frame (which points to the
		# return address)
		#
		var nf [frame next [frame top]]
		[if {![null $nf] && [read-reg sp] != [frame register sp $nf]}
		{
		    echo -n WARNING: SP is not pointing at the return address
		    echo (off by [expr [frame register sp $nf]-[read-reg sp]])
		}]
	    }

    	    var what [read-char 0]
    	    if {[string c $what \200] == 0} {
    	    	var gotnull TRUE
    	    }
    	}
	#
	# Line-feed if necessary (and desired). Use string match for
	# expansion's sake
	#
    	if {[null $gotnull]} {
	    if {$nl && ![string match $what {[g]}]} {
    	    	 echo
    	    }
    	}

	#
	# If line was blank, use the default command
	# 
	if {[string m $what \[\015\n\]] == 1} {
	    var what $defcmd
	}
	[case $what in
	 s {
	     #
	     # Execute a single instruction and loop.
	     # 
	     safe-step $insn
	 }
	 {[q\e\040]} {
	     #
	     # Stop this nonsense now
	     # 
	     break
	 }
	 M {
	    #
	    # Go to the method
	    #
	    istep-go-to-next-method
	}
	 b {
	    #
	    # Toggle a breakpoint at the current location
	    #
	    var loc [index $insn 0]
	    var num [brk list cs:ip]
	    if {[null $num] == 0} {
		brk clear [index $num 0]
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
	    stop-catch {go ProcCallModuleRoutine ProcCallFixedOrMovable}
	    event dispatch FULLSTOP _DONT_PRINT_THIS_
    	    if {![string c [frame function] ProcCallFixedOrMovable]} {
    	    	if {[read-reg bx]>=0xf000} {
	    	    stop-catch {go ^h(bx<<4):ax}
    	    	} else {
	    	    stop-catch {go bx:ax}
    	    	}
    	    } else {
	    	stop-catch {go ^hbx:ax}
    	    }
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
	     var topFrame [frame top]
	     var nextFrame [frame next $topFrame]
	     var nfFrame [sym fullname [frame funcsym $nextFrame]]
	     var nfRCI [string compare $nfFrame geos::kcode::ResourceCallInt]

	     if {$nfRCI == 0} {
		 finishframe $nextFrame
	     } else {
	         finishframe $topFrame
	     }
	 }
	 F {
	     #
	     # Finish an object call.
	     #
    	     # Since objects are called by geos code which is called to
    	     # handle methods, call finishframe with the frame before
    	     # all the geos code.  There may be several frames of kernel
    	     # code. 
	     var curFrame [frame top]

	     var kernel [patient find geos]
	     
	     do {
	        var prevFrame $curFrame
	     	var curFrame [frame next $curFrame]
    	    	if {[string c $curFrame nil] == 0} break
	     } while {![string c [symbol patient [frame funcsym $curFrame]]
	     	    	    	    	    	    	 $kernel]}
   	     if {[string c $curFrame nil] == 0} {
    	    	echo ERROR: There is no more of this patient's code to execute.
    	     } else {
	        finishframe $prevFrame
    	     }
	 }
	 {[NnOo]} {
	    #
	    # Skip over the next procedure call/repeated string operation.
	    # If it's neither, just single-step, otherwise set a breakpoint
	    # after the instruction (as obtained by adding its length to
	    # cs:ip) and allow the machine to continue, keeping control of
	    # the interpreter.
	    # 
	    # Make sure we don't biff inline data for GEOS softint "calls"
	    var i [mangle-softint $insn cs:ip]
	    [case [index $i 1] in
	     {REP* CALL* INT*} { [stepcall $i $what] }
	     default {
    	    	if {[string c [index [index $insn 1] 0] INT] == 0} {
    	    	    # mangled fpu instruction -- step special
		    stepcall $i $what
    	    	} else {
		    #
		    # Single step the thing as above
		    # 
		    safe-step $insn
    	    	}
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
	 A {
	     echo Aborting frame...
	     abort
	 }
	 B {
	     echo Backing up...
	     backup 1
	 }
	 S {
	     echo Skipping...
	     skip 1
	 }
    	 J {
    	    var i [index $insn 1]
    	    if {[index $insn 2] != 2 || ![string match [car $i] J*]} {
    	    	echo ERROR: the jump command follows conditional jumps only.
    	    } else {
	    	# use relative shme to cope with doing this in "absolute"
		# memory
    	    	assign ip ip+2+[value fetch cs:ip+1 sbyte]
    	    }
    	 }
	 r {
	     regs
	 }
	 R {	
    	    var i [index $insn 1]
    	    if {![string match [car $i] CALL]} {
    	    	echo [ref]
    	    } else {
		echo [ref [index $i 1]]
    	    }
    	 }
	 {[\\?h]} {
	     echo [help istep]
	 }
    	 \200 {
    	    var what {}
    	    continue
    	 }
	 default {
	     echo Excuse me?
	 }
	]

    	    
    	#update the source line memory
    	var lastLine $curLine
	if {[catch {src line [frame register pc]} curLine] != 0} {
	    # Couldn't map the address to a source line, so just set
	    # $curLine to null -- everything else should just work.
	    var curLine {}
	}

    	    # we have finished the command and the command isn't one
    	    # which we want to repeat so we clear 'what' so that
    	    # we ask the user what to do next
    	[if {!([string compare $curLine $lastLine] == 0 && 
    	     [string match $what {[Oo]}] != 0)}
    	{ 
            var what {}
    	}]

	event dispatch FULLSTOP _DONT_PRINT_THIS_
	if {[string compare [patient data] $cp] != 0} {
	    break
	}
    }
}]


##############################################################################
#				sstep
##############################################################################
#
# SYNOPSIS:	Interactive source-code step command
# PASS:		defcmd	= default command to use when just <enter> is typed
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	rf	3/?/91		Initial Revision
#
##############################################################################

[defcmd sstep {{defcmd s}} top.step
{Usage:
    sstep [<default command>]

Examples:
    "ss"    	enter source step mode
    "sstep n"  	enter source step mode, <ret> does a next command

Synopsis:
    Step through the execution of the current patient by source lines.
    This is THE command for stepping through high level code.

Notes:
    * The default command argument determines what pressing the return
      key does.  By default, return executes a step command.  Any
      other command listed below may be substituted by passing the
      letter of the command.

    * Sstep steps through the patient line by line, printing where the
      ip is and what line is to be executed Sstep waits for the user
      to type a command which it performs and then prints out again
      where sstep is executing.

    * This is a list of sstep commands:
	q, ESC, ' ' Stops sstep and returns to command level.
	b           Toggles a breakpoint at the current location.
	c           Stops sstep and continues execution.
	n	    Continues to the next source line, skipping procedure
		    calls, repeated string instructions, and software
		    interrupts. Only stops when the machine returns to
		    the right context (i.e. the stack pointer and
		    current thread are the same as they are when the
		    'n' command was given).
	l	    Goes to the next library routine.
	N	    Like n, but stops whenever the breakpoint is hit, whether
		    you're in the same frame or not.
	M   	    Goes to the next method called.  Doesn't work when the
		    method is not handled anywhere (sorry, I forgot).
        F	    Finishes the current method.
	f	    Finishes out the current stack frame.
	s, RET      Steps one source line
	S	    Skips the current source line.
	J	    Jump on a conditional jump, even when "Will not jump" 
		    appears.  This does not change the condition codes.
	g	    Executes the 'go' command with the rest of the line as
		    arguments.
	e 	    Executes a Tcl command and returns to the prompt.
	R	    References either the function to be called or the 
		    function currently executing
	h, ?        This help message.

    * Emacs will load in the correct file executing and following the
      lines where sstep is executing if its server is started and if
      ewatch is on in swat.  If ewatch is off emacs will not be updated.

    * If the current patient isn't the actual current thread, sstep
      waits for the patient to wake up before single-stepping it.

See also:
    istep, srclist, ewatch.
}


{
    global lastHaltCode window-system showMethodNames srcwinmode

    #gotnull is a variable used for dealing with the special NULL
    #character that can be returned from read-char
    var	gotnull {}

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
    	    #no input pushed back by aborted "go" command...
	    var insn [unassemble cs:ip 1]
	    if {[string match [index $insn 1] RET*]} {
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
    	    #
	    # Determine where we are and tell the user if we've switched
	    # source files. If we can't figure where we are in the source
	    # code, just put up the instruction.
	    #
    	    var where [src line cs:ip]
	    if {![null $where] && [file exists [index $where 0]]} {
		if {[string c [car $where] $lastFile] != 0} {
		    echo Stepping in [car [src line cs:ip]]...
		    var lastFile [car $where]
    	    	    var srcwinmode _srcwin
    	    	    event dispatch FULLSTOP _DONT_PRINT_THIS_
		}
    	    	if {[null $gotnull]} {
		    echo -n [format {%5d:%s} [index $where 1] [eval [concat src read $where]]]
    	    	}
        	var gotnull {}
    	    } else {
	    	if {![null $lastFile]} {
		    echo No source available for [format %04xh:%04xh [read-reg cs] [read-reg ip]]...
		    var lastFile {}
    	    	}
    	    	if {[null $gotnull]} {
    	    	    echo -n [format-instruction $insn cs:ip] {}
    	    	} 
    	    	var gotnull {}
    	    }

    	    var what [read-char 0]

    	    if {[string c $what \200] == 0} {
    	    	var gotnull TRUE
    	    } else {
	    	#
	    	# Line-feed if necessary (and desired). Use string match for
	    	# expansion's sake
	    	#
	    	if {$nl && ![string match $what {[g]}]} echo
    	    }
	}
	#
	# If line was blank, use the default command
	# 
	if {[string m $what \[\015\n\]] == 1} {
	    var what $defcmd
	}

	[case $what in
	 s {
    	    snext $what 0
	 }
	 {[q\e\040]} {
	     #
	     # Stop this nonsense now
	     # 
	     break
	 }
	 M {
	    #
	    # Go to the method
	    #
    	    istep-go-to-next-method
	 }
	 b {
	    #
	    # Toggle a breakpoint at the current location
	    #
	    var loc [index $insn 0]
	    var num [brk list cs:ip]
	    if {[null $num] == 0} {
		brk clear [index $num 0]
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
	     var topFrame [frame top]
	     var nextFrame [frame next $topFrame]
	     var nfFrame [sym fullname [frame funcsym $nextFrame]]
	     var nfRCI [string compare $nfFrame geos::kcode::ResourceCallInt]

	     if {$nfRCI == 0} {
		 finishframe $nextFrame
	     } else {
	         finishframe $topFrame
	     }
	 }
	 F {
	     #
	     # Finish an object call.
	     # 
	     var curFrame [frame top]

	     var kernel [patient find geos]
	     
	     do {
	        var prevFrame $curFrame
	     	var curFrame [frame next $curFrame]
	     } while {![string c [symbol patient [frame funcsym $curFrame]]
	     	    	    	    	    	    	 $kernel]}
	     
	     finishframe $prevFrame
	 }
	 \[Nn\] {
	    #
    	    # Step to the next source line, running any function calls at
	    # full speed.
	    #

    	    snext $what 0
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
	     #
	     # Skip to the next source line.
	     #
	     echo Skipping...
	     var count 1
	     var startLine [src line [frame register pc [frame top]] [frame top]]
	     if {![null $startLine]} {
		 var count [index [findnext $startLine S] 0]
	     }
	     skip $count
	 }
    	 J {
    	    var i [index $insn 1]
    	    if {![string match [car $i] J*]} {
    	    	echo Error: the jump command follows conditional jumps only.
    	    } else {
    	    	assign ip [cdr $i]
    	    }
    	    
    	 }
	 R {	
    	    var i [index $insn 1]
    	    if {![string match [car $i] CALL]} {
    	    	echo [ref]
    	    } else {
		echo [ref [index $i 1]]
    	    }
    	 }
	 \[?h\] {
	     echo [help sstep]
	 }
    	 \200 {
    	    var what {}
    	    continue
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
[defsubr stepcall {insn what} {
    global lastHaltCode

    var ip [expr [read-reg ip]+[index $insn 2]] cs [read-reg cs]

    #
    # EnterHeap and EnterGraphics are tony-code, so they push
    # things on the stack before returning. If calling
    # either of them, set a breakpoint at the next address
    # regardless
    #
    [case [index $insn 1] in
        {*EnterHeap* 
	 *EnterGraphics*
	 *EnterTranslate*
    	 *EnterFile*
	 *PushAll*
	 *PopAll*
	 *VMPush_EnterVMFile*
	 *FileErrorCatchStart*
	 *PathStoreState*
	 *PathRestoreState*
	 *FarEnterFile*
	 *lockCurPathToES*
    	 *FindExtraLibraries*
	 *BorrowStackDSDX*
    	 *ThreadBorrowStackSpace*
    	 *ThreadReturnStackSpace*
    	 *SwitchStackWithData*
	 {INT*37 (25h)}
	 {INT*38 (26h)}
    	 *SwitchStackWithData*
    	 *_mwpush*
    	 *PUSH@*
	 *SCUPrepareForDriverCall*}
    	{
    	    #
	    # These things play with the stack in unhealthy ways, so just set
	    # an unconditional breakpoint as we would for N
	    #
	    var bpt [brk tset $cs:$ip]
    	}
	default {
	    [case [index $insn 1] in
		*WarningNotice* {
		    #call followed by mov ax, #, which is never executed
		    var ip [expr $ip+3]
		}
		*FileErrorCatchEnd* {
		    #call followed by .inst byte, which is never executed
		    var ip [expr $ip+1]
		}
	    ]
	    if {[string c $what n] == 0} {
		#
		# Set a temporary breakpoint at the next instruction,
		# making sure we're back where we are now before
		# stopping there (sp and thread # the same)
		#
    	    	var stackhan [handle find ss:0]
    	    	if {![null $stackhan] && [catch {addr-parse geos::dgroup:0} kdata] == 0} {
		    if {[read-reg ss] == [handle segment [index $kdata 0]]} {
		    	# on kernel stack, so no borrowing to take place.
			var bpt [brk tset $cs:$ip 
			   [format {expr {[read-reg sp] >= %d &&
					  [string c [patient data] {%s}] == 0}}
				   [read-reg sp]
				   [patient data] ]]
    	    	    } else {
		    	# stop when sp >= current sp and word at the bottom
			# of the stack (SL_savedStackBlock in StackFooter 
			# structure) matches what's there now (i.e. sp not >=
			# due to stack borrow).
		    	var bpt [brk tset $cs:$ip
			    [format {expr {[read-reg sp] >= %d &&
			    	    	   [value fetch ss:%d word] == %d &&
					   [string c [patient data] {%s}] == 0}}
				    [read-reg sp]
				    [expr [handle size $stackhan]-2]
				    [value fetch ss:[handle size $stackhan]-2
				    	word]
				    [patient data]]]
    	    	    }
    	    	} else {
		    # in loader, so no stack borrowing
		    var bpt [brk tset $cs:$ip 
		       [format {expr {[read-reg sp] >= %d &&
				      [string c [patient data] {%s}] == 0}}
			       [read-reg sp]
			       [patient data] ]]
    	    	}
	    } else {
		#
		# Set a temporary breakpoint at the next instruction,
		# regardless of where we are when we hit it.
		#
		var bpt [brk tset $cs:$ip]
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
    return $bpt
}]

[defcommand skip {{n 1}} top.step
{Usage:
    skip [<number of instructions>]

Examples:
    "skip"  	skip the current instruction
    "skip 6"	skip the next six instructions

Synopsis:
    Skip the one or more instructions.

Notes:
    * The number of instructions argument defaults to one if not specified.

See also:
    istep, sstep, patch.
}
{
    for {} {$n > 0} {var n [expr $n-1]} {
	var insn [mangle-softint [unassemble cs:ip] cs:ip]
	assign ip [expr [read-reg ip]+[index $insn 2]]
    }
}]

[defcommand backup {{n 1}} top.step
{Usage:
    backup [<number of instructions>]

Examples:
    "backup"  	backs up one instruction
    "backup 6"	backup six instructions

Synopsis:
    Backs up the instruction pointer one or more instructions.

Notes:
    * The number of instructions argument defaults to one if not specified.

See also:
    istep, sstep, patch, skip
}
{
    [for {} {$n > 0} {var n [expr $n-1]} {
	[for {var ptr [index [addr-parse cs:ip-20] 1]}
	    {![string match $ptr [read-reg ip]]}
	    {}
	    {
		var prevPtr $ptr
		var insn [mangle-softint [unassemble cs:$ptr] cs:$ptr]
		var ptr [expr $ptr+[index $insn 2]]
		if {$ptr>[read-reg ip]} {error {Sorry, can't figure it out}}
	    }
	]
	assign ip $prevPtr
    }]
}]


##############################################################################
#				findnext
##############################################################################
#
# SYNOPSIS:	find the next source line
# PASS:		startLine = the source line to start from
#               what	= S, n, N or s to tell whether to skip everything till
#                         the next source line (S), run called procedures
#			  at full speed (n or N) or stop inside any
#			  procedure that may be called (s).
# CALLED BY:	snext, sstep
# RETURN:	a 3-list containing
#                         the number of instructions between the start
#                           source line and the next one
#                         the offset of the next source line from the
#                           start one
#                         the last instruction examined (list returned from
#                           find-opcode)
# SIDE EFFECTS:
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jenny	11/ 9/93	Broke out of snext
#
##############################################################################
[defsubr findnext {startLine what}
{
    var curLine $startLine
    #
    # Create type that is the maximum length of an instruction, so find-opcode
    # has enough to go on.
    #
    var bytesType [type make array 10 [type byte]]
    #
    # Look at instructions until we find one whose branch-type is not
    # just sequential. branch-type is element 2 of the list returned
    # by find-opcode.
    #
    [for {[var offset 0 count 0]}
         {[string c $startLine $curLine] == 0}
	 {catch {src line cs:ip+$offset} curLine
	     var count [expr $count+1]}
    {
	var op [eval [concat find-opcode cs:ip+$offset
		      [value fetch cs:ip+$offset $bytesType]]]
	var bt [index $op 2]
	if {[string c $bt 1] != 0} {
	    # found a possible stopping point. if the flow-change is
	    # non-linear, and either we're not in a "next" mode, or the
	    # instruction is neither a CALL nor an INT. If it's a CALL or
	    # INT in "next" mode, we don't need to stop here as we'd just
	    # continue anyway.
	    [if {[string match $what$bt {[SNn]I}]} {
		# form a regular insn list and mangle any special softint
		# calls so we don't start interpreting data as instructions
		var insn [mangle-softint [list cs:ip+$offset
					  [index $op 7]
					  [index $op 1]
					  {}]
					  cs:ip+$offset]
		var offset [expr $offset+[index $insn 2]]
	    } elif {[string match $what$bt {[SNn][bj]}] &&
		[string compare [index $op 0] CALL] == 0}
	    {
		var offset [expr $offset+[index $op 1]]
	    } else {
		break
	    }]
	} else {
	    # add the length of the instruction to our current offset for
	    # the next loop
	    var offset [expr $offset+[index $op 1]]
	}
     }]
    return [list $count $offset $op]
}]
	
##############################################################################
#				snext
##############################################################################
#
# SYNOPSIS:	step to the next source line
# PASS:		what	= n, N or s to tell whether to run called procedures
#			  at full speed (n or N) or to stop inside it should
#			  one be called.
#   	    	notify	= 1 if user should be notified when machine stops
# CALLED BY:	user, sstep
# RETURN:	nothing
# SIDE EFFECTS:	this and that
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/31/91		Initial Revision
#
##############################################################################
[defsubr snext {{what s} {notify 1}}
{
    var startLine [src line [frame register pc [frame top]] [frame top]]
    var curLine $startLine

    if {[null $startLine]} {
    	#
	# Source line unknown -- behave like istep.
	#
	var insn [unassemble cs:ip 1]
	
    	if {[string c $what s] == 0} {
	    var bpt [safe-step $insn]
    	} else {
    	    var insn [mangle-softint $insn cs:ip]
	    [case [index $insn 1] in
	     {REP* CALL* INT*} { var bpt [stepcall $insn $what] }
	     default {
		#
		# Single step the thing as above
		# 
		var bpt [safe-step $insn]
	    }]
	}
	
	if {![null $bpt]} {
	    eval [concat brk clear $bpt]
    	}
	#
	# Send out a FULLSTOP event if completion-notification was requested. If
	# not requested, our caller will have to issue the event instead.
	#
	if {$notify} {
	    global lastHaltCode
	    event dispatch FULLSTOP $lastHaltCode
	}
	return
    }
	
    [for {}
    	{[string c $startLine $curLine] == 0}
	{catch {src line cs:ip} curLine}
    {
    	#
	# Look at instructions until we find one whose branch-type is not
	# just sequential.
	#
	var next [findnext $startLine $what]
	var offset [index $next 1]
    	if {$offset != 0} {
	    #
	    # Set a breakpoint at the point we decided we needed to get to and
	    # let the machine run until then.
	    #
	    var bpt [list [brk pset cs:ip+$offset]]
	    stop-catch {
		continue-patient
		wait
	    }
    	} else {
	    var op [index $next 2]
	    var fs [frame funcsym [frame top]]
    	    if {[string match $what {[Nn]*}]} {
    	    	# If nexting and we're at a call or interrupt, just set a
		# breakpoint after the instruction and let the machine go.
		# Else execute the single instruction safely
	    	[case [index $op 2] in
		    I {	# Interrupt
		    	var insn [mangle-softint [unassemble cs:ip] cs:ip]
			var bpt [brk pset cs:ip+[index $insn 2]]
			stop-catch {
			    continue-patient
    	    	    	    wait
    	    	    	}
    	    	    }
		    {b j} {# relative or absolute branch/jump/call
    	    	    	if {[string compare [index $op 0] CALL] == 0} {
			    var bpt [brk pset cs:ip+[index $op 1]]
			    stop-catch {
				continue-patient
				wait
			    }
    	    	    	} else {
			    var bpt [safe-step [unassemble cs:ip 1]]
    	    	    	}
    	    	    }
		    default {
		    	var bpt [safe-step [unassemble cs:ip 1]]
    	    	    }
    	    	]
    	    } else {
    	    	# We're stepping, so just step the instruction without
		# regard for what type it is -- we'll bail if it takes us
		# outside the source line, and if it doesn't, we don't care.
	    	var bpt [safe-step [unassemble cs:ip 1]]
    	    }

	    # if we end up in a procedure that's got a ??START
	    # label, stop there instead.
    	    var nfs [frame funcsym [frame top]]

    	    [case [sym name $nfs] in
    	        {*_mwpush*
    	    	 *PUSH@*}
    	    {
    	    	#we want to hide these uglies from the user so
    	    	#continue to just past it
    	    	var fr [frame next [frame top]]
    	    	if {[string compare [sym name [frame funcsym $fr]] 
    	    	    	    	ResourceCallInt] == 0} {
    	    	    var fr [frame next $fr]
    	    	}
    	    	var tbpt [brk pset [frame register cs $fr]:[frame register ip $fr]]
    	    	stop-catch {
    	    	    continue-patient
    	    	    wait
    	    	}
    	    	brk clear $tbpt
    	    }
	    default {
	    	if {$nfs != $fs && ![null $nfs]} {
	    	#
		# We're in a new procedure. See if it's got a ??START
		# label and run to there if it does.
		#
		    var sl [symbol find label ??START 
    	    	    	    	    [frame funcsym [frame top]]]
    	    	    if {![null $sl] && [index $op 2] != R} {
	    	    	var bpt [concat $bpt 
				    [list [brk pset [symbol fullname $sl]]]]
    	    	    	stop-catch {
		    	    continue-patient
			    wait
		    	}
		    }
    	    	}
    	    }]
    	}
	# Clear any and all breakpoints we've set so we don't have to issue
	# a FULLSTOP event.
	if {![null $bpt]} {
	    eval [concat brk clear $bpt]
    	}
    }]
    
    #
    # Send out a FULLSTOP event if completion-notification was requested. If
    # not requested, our caller will have to issue the event instead.
    #
    if {$notify} {
    	global lastHaltCode
    	event dispatch FULLSTOP $lastHaltCode
    }
}]

##############################################################################
#				step-while
##############################################################################
#
# SYNOPSIS:	    Continually single-step the PC while the given expression
#		    (which is passed to the "expr" command) evaluates to
#		    true.
# PASS:		    test-expr	= expression to evaluate after each instruction
#                   noStop      = non-null if the caller wants to handle
#                                     stopping the machine
#                                 null if step-while should stop the machine
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 1/92		Initial Revision
#
##############################################################################
[defsubr step-while {test-expr}
{
    for {} ${test-expr} {} {
	var insn [unassemble cs:ip 1]
	echo [format-instruction $insn cs:ip 0]
    	step-once $insn
    }
    event dispatch FULLSTOP [format {"%s" is now false} ${test-expr}]
}]

[defsubr step-once {insn}
{
    #
    # Don't even try to step into int 13h
    #
    [case [index $insn 1] in
	{{*INT*19 (13h)} {*INT*40 (28h)}} {
	    uplevel 1 var lastAddr {}
	    var bpt [brk tset cs:ip+2]
	    stop-catch {
		    continue-patient
		    wait
	    }
	}
	{*LOOP*} {
	    if {[null [uplevel 1 var lastAddr]]} {
		uplevel 1 var lastAddr [addr-parse cs:ip]
		var bpt [safe-step $insn]
	    } elif {[uplevel 1 var lastAddr] == [addr-parse cs:ip]} {
		# looping in place. skip the instruction
		var bpt [brk tset cs:ip+2]
		stop-catch {
			continue-patient
			wait
		}
	    } else {
		uplevel 1 var lastAddr {}
		var bpt [safe-step $insn]
	    }
	}
	{*REP*} {
    	    uplevel 1 var lastAddr {}
	    var bpt [brk tset cs:ip+[index $insn 2]]
	    stop-catch {
	    	continue-patient
		wait
	    }
    	}
	default {
	    uplevel 1 var lastAddr {}
	    var bpt [safe-step $insn]
	}
    ]

    #
    # If set a temporary breakpoint in there, clear it now.
    #
    if {![null $bpt]} {
	eval [concat brk clear $bpt]
    }
}]

##############################################################################
#				step-to
##############################################################################
#
# SYNOPSIS:	    Continually single-step the PC until the given address
#   	    	    or another breakpoint is hit.
# PASS:		    addr	= address cs:ip must reach before execution
#   	    	    	    	  stops.
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/26/92		Initial Revision
#
##############################################################################
[defsubr step-to {addr}
{
    #
    # Parse the address now (might involve labels local to the current scope...)
    # We only need the 0th and 1st elements; the type is unimportant.
    #
    var a [range [addr-parse $addr] 0 1]
    var why [list $addr reached]
    protect {
    	#
	# Register interest in the handle to make sure the handle token stays
	# valid across continues/steps. We do this inside a protect clause
	# so we don't lose track of the interest record.
	#
        var interest [handle interest [index $a 0] concat]

    	#
	# Keep stepping while cs:ip doesn't parse to the same address as
	# our destination.
	#
	for {} {[string c $a [range [addr-parse cs:ip] 0 1]] != 0} {} {
    	    #
	    # Decode and print out the instruction at cs:ip
	    #
	    var insn [unassemble cs:ip 1]
	    echo [format-instruction $insn cs:ip 0]
    	    step-once $insn
	    if {[brk isset cs:ip]} {
	    	#
		# Breakpoint set at current address, so stop.
		#
		var why {Breakpoint hit}
    	    	break
    	    }
	}
    } {
    	#
	# If we managed to register interest in the target address's handle,
	# unregister it now.
	#
    	if {![null $interest]} {
	    handle nointerest $interest
    	}
    }
    #
    # Issue the much-delayed FULLSTOP event to update the register displays,
    # etc.
    #
    event dispatch FULLSTOP $why
}]

##############################################################################
#				step-until
##############################################################################
#
# SYNOPSIS:	Step until some expression is true.
# CALLED BY:	user
# PASS:		expression	- Expression which indicates we should stop
#               byteWord        - type of data to check against
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/15/92	Initial Revision (sans code :)
#       jenny    11/12/93       Wrote it.
#
##############################################################################
[defcommand step-until {expression {byteWord byte}} top.step
{Usage:
    step-until <expression> [<byteOrWord>]

Examples:
    step-until ax=0 	    	Single-step until ax is zero
    step-until ds:20h!=0 byte	Single-step until byte at ds:20h is non-zero
    step-until ds:20h!=0 word	Single-step until word at ds:20h is non-zero
    step-until c=0  	    	Single-step until the carry is clear
    step-until ax!=ax	    	Step forever :-)

Synopsis:
    Step until a condition is met

Notes:
    * <expression> is the expression to evaluate.

    * "byte" or "word" may be passed as an optional second argument to
      indicate the type of data to check against. They may be abbreviated
      as "b" and "w".

    * step-until is useful for tracking memory or register trashing bugs

See also:
    step-while
}
{
    #
    # Parse the expression into component parts
    #	left	    - Left-side value expression
    #	cond	    - Passed condition expression
    #	right	    - Right-side value expression
    #	byteWord    - Type of data to check against
    #
    #   len         - Length of passed condition expression
    #
    # Since we're using [string first...] to find the condition expression,
    # we must check for all possible conditions containing '=' before
    # checking for '=' itself.
    #
    var len 2
    foreach listX {{!= >= <= ==} {= < >}} {
	foreach cond $listX {
	    var c [string first $cond $expression]
	    if {$c != -1} {
		break
	    }
	}
	if {$c != -1} {
	    break
	}
	var len 1
    }
    if {$c == -1} {
	error {Invalid condition expression}
    }
    if {[string match $cond =]} {
	#
	# expr won't recognize "=", so we make it "==".
	#
	var cond ==
    }
    var left [range $expression 0 [expr $c-1] chars]
    var right [range $expression [expr $c+$len] end chars]
    [case $byteWord in
        b* {var byteWord byte}
	w* {var byteWord word}
    ]
    #
    # Find out what we'll need to call to find the values stored on the
    # left and the right.
    #
    var left_callback [get-callback $left $byteWord]
    var right_callback [get-callback $right $byteWord]
    #
    # Step till the passed expression is true.
    #
    while {1} {
	#
	# Leave or step. We form the condition in this way, fetching the
	# values in $left and $right, so the thing will byte-compile.
	# Compiled expressions can't cope with operators stored in variables.
	#
	if [eval $left_callback]$cond[eval $right_callback] {
	    break
	}
	var insn [unassemble cs:ip 1]
	echo [format-instruction $insn cs:ip 0]
    	step-once $insn
    }
    event dispatch FULLSTOP [format {"%s" is now true} $expression]

}]

##############################################################################
#				get-callback
##############################################################################
#
# SYNOPSIS:	Figure out what command will give the value of the passed
#               argument
# CALLED BY:	step-until
# PASS:		thing	 - register, memory address, flag, or number
#               byteWord - type of data returned command may need to check
#                          against
# RETURN:	a list containing the command to evaluate whenever one
#               wants to find the value stored in the passed argument 
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       jenny   12/16/93        Initial version
#
##############################################################################
[defsubr get-callback {thing byteWord}
{
    global regnums

    var regNum [index [assoc $regnums $thing] 1]
    if {![null $regNum]} {
	#
	# Register.
	#
	return [concat index {[current-registers]} $regNum]
    } elif {[catch {get-address $thing} addr] == 0} {
	#
	# Memory address.
	#
	addr-preprocess $addr seg off
	return [list value fetch $seg:$off [type $byteWord]]
    } elif {[length $thing chars] == 1}  {
	global flags
	#
	# Uppercase the character and check for it in the $flags list.
	#
	scan $thing %c flag
	var flag [format %c [expr $flag&~32]]
	var bit [index [assoc $flags ${flag}F] 1]
	if {![null $bit]} {
	    #
	    # Flag.
	    #
	    return [list flag-callback $bit]
	}
    }
    #
    # Assume it's a number, which may be hex. We will want it as a
    # decimal number.
    #
    return [list expr [getvalue $thing]]
}]

[defsubr flag-callback {bit}
{
    #
    # Return 1 if the flag at the passed bit is set and 0 otherwise.
    #
    if {[read-reg cc] & $bit} {
	return 1
    } else {
	return 0
    }
}]
