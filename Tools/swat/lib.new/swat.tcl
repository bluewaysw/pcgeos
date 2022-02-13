##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- runtime definitions
# FILE: 	swat.tcl
# AUTHOR: 	Adam de Boor, Nov  9, 1988
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/ 9/88	Initial Revision
#   	ardeb	3/13/89	    	Adapted to new help scheme
#
# DESCRIPTION:
#	This file contains various definitions that are helpful
# 	for the user and some that are essential for Swat's well-being.
# 	Documentation occurs at apropriate places
#
#
#	$Id: swat.tcl,v 3.71 97/04/29 20:26:37 dbaumann Exp $
#
###############################################################################
##############################################################################
#                                                                            #
#			PROGRAMMING UTILITIES				     #
#									     #
##############################################################################

[autoload loop 1 loop]

#
# swat_prog
#
[defhelp useful_aliases swat_prog
{Note the following handy aliases, which are already set up for use:

    alias while {for {} ARG1 {} ARG2}
    alias do {if {[string c ARG2 while] == 0} {
      	    	eval [format {for {} {1} {if {!(%s)} break} {%s}} ARG3 ARG1]
	  } else {
	    eval [format {for {} {1} {if {!(%s)} break} {%s}} ARG2 ARG1]
	  }}
    alias repeat {if {[string c ARG2 until] == 0} {
      	    	for {} {1} {if ARG3 break} ARG1
	      } else {
	        for {} {1} {if ARG2 break} ARG1
	      }}
}]

alias while {for {} $1 {} $2}
alias do {if {[string c $2 while] == 0} {
      	    	eval [format {for {} {1} {if {!(%s)} break} {%s}} $3 $1]
	  } else {
	    eval [format {for {} {1} {if {!(%s)} break} {%s}} $2 $1]
	  }}
alias repeat {if {[string c $2 until] == 0} {
      	    	for {} {1} {if $3 break} $1
	      } else {
	        for {} {1} {if $2 break} $1
	      }}

##############################################################################
#				name-root
##############################################################################
#
# SYNOPSIS:	    Return the name of a symbol without any preceding
#		    symbol-path components
# PASS:		    name    = name to be trimmed
# CALLED BY:	    ?
# RETURN:	    trimmed name
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 5/91	Initial Revision
#
##############################################################################
[defsubr	name-root {name} {
    var lo [expr [string last :: $name]+2]
    if {$lo == 1} {
	return $name
    } else {
        return [range $name $lo end chars]
    }
}]

##############################################################################
#				fieldmask
##############################################################################
#
# SYNOPSIS:	Map a record field name to its bit-mask
# PASS:		f   = name of field whose mask is desired
# CALLED BY:	?
# RETURN:	decimal representation of the field's bit-mask
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/90		Initial Revision
#
##############################################################################
[defsubr	fieldmask {f}
{
    var l [sym get [sym find field $f]]
    var width [index $l 1] offset [index $l 0]
    return [expr ((1<<$width+$offset)-1)&~((1<<$offset)-1)]
}]

##############################################################################
#				getvalue
##############################################################################
#
# SYNOPSIS:	Get value of some structure, constant, or what have you
# PASS:		value - thingy to get value of. if it's a variable, the
#			value of the variable is fetched.
# RETURN:	value of $value
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################
[defcommand getvalue {v} swat_prog
{Usage:
    getvalue <expr>

Example:
    "getvalue MSG_META_DETACH"		Returns the integer value of
					the symbol MSG_META_DETACH

Synopsis:
    This is a front-end to the "addr-parse" command that allows you to
    easily obtain the integer value of any expression. It's most useful
    for converting something the user might have given you to a decimal
    integer for further processing.

Notes:
    * If the expression you give does not evaluate to an address (whose
      offset will be returned) or an integer, the results of this function
      are undefined.

See Also:
    addr-parse, addr-preprocess
}
{
    var a [uplevel 1 addr-parse $v 0]
    if {[string c [index $a 0] value] == 0} {
    	return [index $a 1]
    } elif {[null [index $a 0]]} {
    	return [value fetch 0:[index $a 1] [index $a 2]]
    } else {
    	return [value fetch ^h[handle id [index $a 0]]:[index $a 1]
			    [index $a 2]]
    }
}]

##############################################################################
#				addr-preprocess
##############################################################################
#
# SYNOPSIS:	    Preprocess an address expression into a form that is
#   	    	    faster to parse and easier to modify.
# PASS:		    addr    = expression to parse
#   	    	    seg	    = name of variable to which to assign the pre-
#			      processed segment
#   	    	    off	    = name of variable to which to assign the pre-
#			      processed offset
# RETURN:	    the address list from addr-parse
# SIDE EFFECTS:	    variables in caller's scope altered appropriately
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/29/92		Initial Revision
#
##############################################################################
[defcommand addr-preprocess {addr seg off {frame {}}} swat_prog
{Usage:
    addr-preprocess <addr> <seg-var> <off-var> [<frame>]

Examples:
    "addr-preprocess $args s o"	    Parse the address expression in $args,
    	    	    	    	    storing the segment portion in $s and
				    the offset portion in $o in the current
				    scope.

Synopsis:
    Preprocesses an address expression into a form that is easier to manipulate
    and faster to reparse.

Notes:
    * <seg-var> is the name of a variable in the caller's scope in which the
      segment of the address is stored. It should be treated as opaque, as it
      may or may not be numeric.

    * <off-var> is the name of a variable in the caller's scope in which the
      offset of the address is stored. This will always be numeric.

    * Returns the 3-list returned by addr-parse, in case you have a use for
      the type token stored in the list.

See also:
    addr-parse.
}
{
    # evaluate the address in the caller's context
    var a [uplevel 1 [concat [list addr-parse $addr 0] $frame]]
    global stub-is-geos32

    if {[null [index $a 0]]} {
        if {${stub-is-geos32}}  {
 	    uplevel 1 var $seg [expr [index $a 1]>>16]
	    uplevel 1 var $off [expr [index $a 1]&0xFFFF]
        } else {
            if {[index $a 1] >= 0x100000} {
                uplevel 1 var $seg 0xffff
	        uplevel 1 var $off [expr [index $a 1]-0xffff0]
    	    } else {
    	        uplevel 1 var $seg [expr [index $a 1]>>4]
	        uplevel 1 var $off [expr [index $a 1]&0xf]
    	    }
        }
    } else {
    	uplevel 1 var $seg ^h[handle id [index $a 0]]
	uplevel 1 var $off [index $a 1]
    }
    return $a
}]

#
# unalias just does a Tcl_DeleteCommand, but it's nice to have a more
# meaningful name for it should one use it to nuke tcl procedures...
#
alias purge {unalias}

[defcommand field {list name} {swat_prog.list swat_prog.memory}
{Usage:
    field <list> <field name>

Examples:
    "field [value fetch ds:si MyBox] topLeft"	return the offset of 
    	    	    	    	    	    	the topLeft field in MyBox

Synopsis:
    Return the value for the field's offset in the structure.

Notes:
    * The list argument is a structure-value list from the "value"
      command.

    * The field name argument is the the field in the structure.

See also:
    value, pobject, piv.
}
{
    var el [assoc $list $name]

    if {[null $el]} {
    	return nil
    } else {
    	return [index $el 2]
    }
}]

##############################################################################
#				push
##############################################################################
#
# SYNOPSIS:	    Push a word onto the current thread's stack. Must be
#   	    	    in frame 1 for this to work and not destroy things.
# PASS:		    arg	    = value to push
# SIDE EFFECTS:	    sp in the current frame is decremented by 2
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 1/92		Initial Revision
#
##############################################################################
[defsubr push {arg}
{
    assign sp sp-2
    assign {word ss:sp} $arg
}]

##############################################################################
#				pop
##############################################################################
#
# SYNOPSIS:	    Pop something off the stack into a register or memory
# PASS:		    arg	    = place to store the value popped
# SIDE EFFECTS:	    sp in the current frame is incremented by 2
#   	    	    $arg is assigned what was at ss:sp before the increment
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 1/92		Initial Revision
#
##############################################################################
[defsubr pop {arg}
{
    assign $arg [value fetch ss:sp word]
    assign sp sp+2
}]

[defsubr hex {args}
{
    return [format 0x%x [expr $args]]
}]

##############################################################################
#
#		      LOAD IMPORTANT OTHER FILES
#
##############################################################################
require set-repeat toplevel
load lisp
load fmt-inst
load stack
load istep
load memory
load autoload		

# mouse support stuff for DOS
if {[string c ${file-os} unix] != 0} {
    load mouse
    load srclist
}

[defsubr frame-instruction {args}
{
    if {[index $args 0]} {
    	return EVENT_NOT_HANDLED
    } else {
	echo [format-instruction [unassemble [frame register pc]] [frame register pc]]
	return EVENT_HANDLED
    }
}]

event handle STACK frame-instruction

##############################################################################
#                                                                            #
#			FRONT-ENDS TO THE BRK COMMAND			     #
#                                                                            #
##############################################################################
#
# top.breakpoint
#
[defhelp useful_aliases top.breakpoint
{Note the following handy aliases, which are already set up for use:

    alias del {brk clear}
    alias delete {brk clear}
    alias dis {brk disable}
    alias disable {brk disable}
    alias en {brk enable}
    alias enable {brk enable}
    alias j {brk list}
}]

alias del {brk clear}
alias delete {brk clear}
alias dis {brk disable}
alias disable {brk disable}
alias en {brk enable}
alias enable {brk enable}
alias j {brk list}

[defcmd go {args} top.running
{Usage:
    go [<address expressions>]

Examples:
    "go"
    "go drawLeftLine"

Synopsis:
    Go until an address is reached.

Notes:
    * The address expressions argument is as many address expressions
      as desired for breakpoints.  Execution is continued until a 
      breakpoint is reached.  These breakpoints are then removed when
      the machine stops AND ARE ONLY ACTIVE FOR THE CURRENT PATIENT.

See also:
    break, continue, det, quit.
}
{
    ensure-swat-attached

    foreach i $args {
    	brk tset $i
    }
    cont
}]

[autoload ibrk 0 ibrk]
[autoload stop 1 ibrk]
##############################################################################
#
# Handler for when the patient stops.
# When a FULLSTOP event is received, this function checks to see if
# printStop is non-null, and if it is, it prints a message indicating
# the function in which execution stopped, along with the source line, if
# available, or machine instruction, as a last resort.
#
[defvar printStop src swat_variable.misc
{Controls how the current machine state is printed each time the machine comes
to a complete stop. Possible values:
    asm	    Print the current assembly-language instruction, complete with
    	    the values for the instruction operands.
    src	    Print the current source line, if it's available. If the source
    	    line is not available, the current assembly-language instruction
	    is displayed as above.
    why     Print only the reason for the stopping, not the current machine
    	    state. "asm" and "src" modes also print this.
    nil	    Don't print anything.}]

[defsubr fullstop {why args}
{
    global printStop
    global defaultPatient

    if {![null $printStop] && [string c $why _DONT_PRINT_THIS_] != 0} {
	if {[string match $why *Breakpoint*]} {
	    var which [sort -n [brk list cs:ip]]
	    var l [length $which]
	    [case $l in
	    	0   	{echo -n $why}
		1   	{echo -n Breakpoint $which}
    	    	2   	{echo -n Breakpoints [index $which 0] and [index $which 1]}
		default {[echo
		    	  [format -n {Breakpoints %s %s and %s}
		    	   [map i [range $which 0 [expr $l-3]] {format $i,}]
			   [index $which [expr $l-2]]
			   [index $which [expr $l-1]]]]}
	    ]
    	    #
	    # Deal with call, which likes to tag on an extra message after
	    # the Interrupt 3: stuff.
	    #
	    var dash [string first -- $why]
	    if {$l != 0 && $dash > 0} {
	    	echo [range $why [expr $dash-1] end chars]
	    } else {
	    	echo
	    }
	} else {
	    echo $why
	    if {[string match $why {PC Halted}]} {
	    #
	    # New! If there's a "defaultPatient", switch to it, if we're not
	    # already in it.	-- Doug 7/5/93
	    #
		if {![null $defaultPatient]} {
		    if {![string match [index [patient data] 0]
				       $defaultPatient]} {
			if {[patient find $defaultPatient] != nil} {
			    switch $defaultPatient
			}
		    }
		}
	    }
	}
	var frame [frame top]
	echo -n Stopped in [frame function $frame],
	[if {[catch {src line [frame register pc $frame] $frame} fileLine]==0 &&
	     ![null $fileLine]}
    	{
	    var file [index $fileLine 0]
	    var line [index $fileLine 1]

    	    [if {[catch {src read $file $line} srcRead]==0} {
    	    	echo { line} $line, "$file"
    	    	if {[string c $printStop src] == 0} {
    	    	    echo [src read $file $line]
	    	} elif {[string c $printStop asm] == 0} {
	    	    echo [format-instruction [unassemble cs:ip 1] cs:ip]
    	    	}
    	    } else {
    	    	echo [format { %s} $srcRead]
    	    }]
	} else {
	    echo { address} [frame register pc $frame]
    	    [if {([string c $printStop src] == 0) ||
	    	 ([string c $printStop asm] == 0)}
    	    {
	    	echo [format-instruction [unassemble cs:ip 1] cs:ip]
    	    }]
    	}]
    }
    return EVENT_HANDLED
}]

event handle FULLSTOP fullstop
############################################################
#
#     STEPPING/CONTINUING THE PATIENT
#
############################################################
#
# "step", "next" and "cont" commands.
# If the variable waitForPatient is non-zero, performs a "wait" after
# each step-line or continue-patient command to make things nicer
# for those used to dbx...
#
[defvar waitForPatient 1 swat_variable.obscure
{Usage:
    var waitForPatient (1|0)

Examples:
    "var waitForPatient 0"	Tells Swat to return to the command prompt
    	    	    	    	after continuing the machine.

Synopsis:
    Determines whether the command-level patient-continuation commands (step,
    next, and cont, for example) will wait for the machine to stop before
    returning.

Notes:
    * The effect of this is to return to the command prompt immediately
      after having issued the command. This allows you to periodically
      examine the state of the machine without actually halting it.

    * The output when the machine does stop (e.g. when it hits a breakpoint)
      can be somewhat confusing. Furthermore, this isn't fully tested, so it
      should probably be set to 0 only in somewhat odd circumstances.

See also:
    step, next, cont, int.
}]

[defcmd step {args} top.step
{Usage:
    step

Examples:
    "step"  	    	execute the next instruction, where ever it is
    "s"

Synopsis:
    Execute the patient by a single machine instruction.

Notes:
    * If waitForPatient is non-zero, step waits for the machine to stop
      again. BEWARE: This doesn't do any of the checks for special things
      (XchgTopStack, software interrupts, etc.)  performed by the 's'
      command in istep.

See also:
    istep, next.
}
{
    ensure-swat-attached

    global waitForPatient lastCommand repeatCommand
    var repeatCommand $lastCommand
    step-patient
}]

[defcommand next {args} top.step
{Usage:
    next

Examples:
    "next"  	    	execute the next instruction without entering it
    "n"

Synopsis:
    Execute the patient by a single instruction, skipping over any
    calls, repeated instructions, or software interrupts.

Notes:
    * Next does not protect against recursion, so when the breakpoint
      for the next instruction is hit, the frame of execution may be
      one lower.

See also:
    step, istep.
}
{
    ensure-swat-attached

    global waitForPatient lastCommand repeatCommand

    var csip [read-reg cs]:[read-reg ip]
    var inst [mangle-softint [unassemble $csip] $csip]
    var op [index $inst 1]

    var repeatCommand $lastCommand
    [case $op in
     {REP* CALL* INT*} {
    	brk tset $csip+[index $inst 2]
    	continue-patient
    	if {$waitForPatient} wait
     }
     default {
    	step-patient
    }]
}]
[defcmd cont {args} top.running
{Usage:
    cont    [-f]
Examples:
    "cont"  	    	continue execution
    "c"	    	    	continue execution
    "cont    -f"    	continues even if at FatalError

Synopsis:
    Continue GEOS.

Notes:
    * If global variable waitForPatient is non-zero, waits for the machine to
      stop again before it returns.

See also:
    go, istep, step, next, detach, quit.
}
{
    ensure-swat-attached

    global waitForPatient

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		f { var force 1 }
	    ]
	}
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    }
    	
    if {[catch {geterror} errorstring] != 0 || ![null $force]} {
	continue-patient
	if {$waitForPatient} wait
    } else {
	echo {cannot continue from FatalError}
    }
}]

# Let the machine run while allowing us to probe its state occasionally
# (Nuked 8/24/92 by atw due to its similarity to "bt").
#alias bg {[continue-patient] [format {}]}

#
# Stop a backgrounded machine
#

#
# swat_prog.patient
#
[defhelp useful_alias swat_prog.patient
{Note the following handy alias, used to stop a backgrounded machine.
This alias is already set up for use:

alias halt {[stop-patient] [event dispatch FULLSTOP {PC Halted}] [format {}]}
}]

alias halt {[stop-patient] [event dispatch FULLSTOP {PC Halted}] [format {}]}
##############################################################################
#
#		 ATTACH/DETACH AND LAUNCHING GEOS
#
##############################################################################
[defcommand rs {} running
{Usage:
    rs

Example:
    "rs"    	    restart GEOS without attaching

Synopsis:
    Restart GEOS without attaching.

See also:
    att, attach.
}
{
    rs-common 0
}]
[defsubr rss {} {rs-common 1}]
[defsubr rsn {} {rs-common 2}]
[defsubr rssn {} {rs-common 3}]

[defsubr rs-common {mode}
{
	global attached
    	global file-os


	if {$attached} {
		error {Swat is already attached to GEOS}
	}

    	if {[string c ${file-os} unix] == 0} {
    	    if {[null [getenv SWAT_NET]]} {
    	    	protect {
        	    var s [stream open [getenv PTTY] w]
    	    	    stream write [format {\eRS%c} [expr $mode+32]] $s
    	    	} {
		    catch {stream close $s} foo
	    	}
    	    }
    	} else {
    	    attach-low $mode
    	}
}]

if {![null [info command connect]]} {
# we renamed attach to connect, so now let attach map to att
    var	attach_command attach
    alias att attach
} else {
    var attach_command att
}

[defcommand $attach_command {args} top.running
{Usage:
    att [<args>]

Examples:
    "att"   	    attach Swat to GEOS.

Synopsis:
    Attach Swat to GEOS.

Notes:
    * The args argument can be one of the following:
    	-s  	reboot GEOS with error checking, attach, and stop
    	-sn 	reboot GEOS without error checking, attach, and stop
    	-f  	restart GEOS with error checking and attach after a pause
    	-r  	restart GEOS with error checking and attach
    	-rn 	restart GEOS without error checking and attach
    	-n  	same as -rn
    	-c  	attach to the PC, which must already be running GEOS

See also:
    detach, quit.
}
{
    global attached
    if {$attached} {
	error {Swat is already attached to GEOS}
    }
    if {![null [info command connect]]} {
    	var myattach connect
    } else {
	var myattach attach
    }
    if {[null $args]} {
    	var args -r
    	var default_args 1
    }
    [case $args in
	    -s	{
	    	rss
		sleep 2
    		[$myattach]
	    }
    	    -sn {
	    	rssn
		sleep 2
		[$myattach]
	    }
	    -f {
	    	rs
		sleep 20
    		[$myattach]
	    }
    	    {-n -rn} {
	    	rssn
		sleep 2
		stop-catch {[$myattach]}
    	    	echo Continuing...
		cont
    	    }
	    -r {
	    	rss
    	    	sleep 2
		stop-catch {
		    [$myattach]
    	    	}
    	    	if {[null $default_args] || [null [patient find geos]]} {
    	    	    echo Continuing...
		    cont
    	    	}
    	    }
	    -c {
	    	stop-catch {
		    [$myattach]
    	    	}
    	    	echo Continuing...
    	    	cont
    	    }
    ]
}]


[defcommand ensure-swat-attached {} swat_prog
{Usage:
    ensure-swat-attached

Examples:
    "ensure-swat-attached"   	    stop if Swat isn't attached to GEOS.

Synopsis:
    If Swat is not attached to GEOS display an error and stop a command.

Notes:
    * Use this command at the start of any other command that accesses the PC.
      Doing so protects the user from the numerous warnings that can result
      from an attempt to read memory when not attached.

}
{
    global attached
    if {$attached==0} {error {Swat is not attached to GEOS.}}
}]

[defcommand not-1x-branch {} swat_prog
{Usage:
    not-1x-branch

Examples:
    "if {[not-1x-branch]} {do_something}"   Returns non-zero if attached to
					    a version of GEOS that isn't
					    1.X

Synopsis:
    Of limited use outside GeoWorks, this allows a command to determine
    easily if it is dealing with a 1.X GEOS system and should examine
    system data structures accordingly.

Notes:
    * The decision is based on the global "geos-release" variable, which is
      set by Swat when it first attaches. The variable contains the major
      number of the version of GEOS running on the PC.

See also:
}
{
    return [expr {![null [info global geos-release]] &&
	    	  [uplevel 0 {var geos-release}] >= 2}]
}]

##############################################################################
#                                                                            #
#   	    	    	    	REGISTER ACCESS	    	    	    	     #
#                                                                            #
##############################################################################
#
# regnums is an assoc-list that maps register names to register numbers.
# The number can be used to index into a list returned by current-registers
#
var regnums {{AX 0} {BX 3} {CX 1} {DX 2} {SI 6} {DI 7} {BP 5} {SP 4}
	     {CS 9} {DS 11} {SS 10} {ES 8} {IP 12} {CC 13}
    	     {ax 0} {bx 3} {cx 1} {dx 2} {si 6} {di 7} {bp 5} {sp 4}
	     {cs 9} {ds 11} {ss 10} {es 8} {ip 12} {cc 13}
             {EAX 15} {ECX 16} {EDX 17} {EBX 18} {ESP 19} {EBP 20} {ESI 21} {EDI 22}
                {FS 23} {GS 24} {EIP 25}
             {eax 15} {ecx 16} {edx 17} {ebx 18} {esp 19} {ebp 20} {esi 21} {edi 22}
                {fs 23} {gs 24} {eip 25}}

var flags {{OF 2048} {DF 1024} {IF 512} {TF 256} {SF 128} {ZF 64} {AF 16} {PF 4} {CF 1}}

[defsubr reg-name {rnum}
{
    global regnums

    var rname unknown
    foreach i $regnums {
    	if {[index $i 1] == $rnum} {
	    var rname [index $i 0]
	    break
	}
    }
    return $rname
}]

[defcommand read-reg {reg} {swat_prog.patient swat_prog.thread patient thread breakpoint}
{Usage:
    read-reg <register>

Examples:
    "read-reg ax"   	return the value of ax
    "read-reg CC"   	return the value of the conditional flags

Synopsis:
    Return the value of a register in decimal.

Notes:
    * The register argument is the two letter name of a register in
      either upper or lower case.

See also:
    frame register, assign, setcc, clrcc.
}
{
    return [index [addr-parse @$reg 0] 1]
}]

[defsubr print-frame-regs {frame}
{
    global regnums flags
    global stub-regs-are-32

    #
    # Print out the general registers in both hex and decimal
    #
    var j 0
    if {${stub-regs-are-32}}  {
        var reglist {CS DS SS ES FS GS}
        foreach i {EAX ESI EBX EDI ECX EBP EDX ESP} {
	    var regval [frame register $i $frame]
	    echo -n [format {%-4s%08xh%12d} $i $regval $regval]
	    var j [expr ($j+1)%2]
	    if {$j == 0} {echo} else {echo -n \t}
        }
    } else {
        var reglist {CS DS SS ES}
        foreach i {AX BX CX DX SI DI BP SP} {
	    var regval [frame register $i $frame]
	    echo -n [format {%-4s%04xh%8d} $i $regval $regval]
	    var j [expr ($j+1)%3]
	    if {$j == 0} {echo} else {echo -n \t}
        }
        echo
    }
    #
    # Blank line.
    #
    echo
    #
    # Now the segment registers in hex followed by the handle ID and name, if
    # they point at one.
    #
    foreach i $reglist {
    	var regval [frame register $i $frame]
    	var handle [handle find [format %04xh:0 $regval]]
    	if {![null $handle]} {
    	    if {[handle state $handle] & 0x480} {
    	    	#
		# Handle is a resource/kernel handle, so it's got a symbol in
    	    	# its otherInfo field. We want its name.
    	    	#
    	    	echo -n [format {%-4s%04xh   handle %04xh (%s)}
    	    	    	    $i $regval [handle id $handle]
    	    	    	    [symbol fullname [handle other $handle]]]
    	    } else {
    	    	echo -n [format {%-4s%04xh   handle %04xh}
    	    	    	    $i $regval [handle id $handle]]
    	    }
    	    if {[handle segment $handle] != $regval} {
    	    	echo [format { [handle segment = %xh]}
			     [handle segment $handle]]
    	    } else {
    	    	echo
    	    }
    	} else {
    	    echo [format {%-4s%04xh   no handle} $i $regval]
    	}
    }
    #
    # Print IP out both in hex and symbolically, if possible
    #
    var ip [frame register IP $frame] 
    var ipsym [symbol faddr func
			   [format {%04xh:%04xh} [frame register CS $frame] $ip]]
    if {![null $ipsym]} {
	var offset [index [symbol get $ipsym] 0]
    	if {$offset != $ip} {
    	    echo [format {IP  %04xh  (%s+%d)} $ip [symbol fullname $ipsym]
			 [expr $ip-$offset]]
    	} else {
    	    echo [format {IP  %04xh  (%s)} $ip [symbol fullname $ipsym]]
    	}
    } else {
    	echo [format {IP  %04xh} $ip]
    }
    #
    # Print the individual flag bits, but only for the top-most frame, as we
    # don't (yet) record where the flags are pushed.
    #
    echo -n {Flags: }
    var flagval [frame register CC $frame]
    foreach i $flags {
        var bit [index $i 1]
	echo -n [format {%s=%d } [index $i 0] [expr ($flagval&$bit)/$bit]]
    }
    echo
    echo
    #
    # Print the instruction and args at cs:ip. 
    #
    echo [format-instruction [unassemble [frame register cs $frame]:[frame register ip $frame] 1] cs:ip]
}]

[defcmd regs {args} top.print
{Usage:
    regs

Examples:
    Print the current registers, flags, and instruction.

See also:
    assign, setcc, clrcc, read-reg.

}
{
    ensure-swat-attached

    print-frame-regs [frame cur]
}]
	
##############################################################################
#
#
# Aliases
#

[defcommand kpc {} support.unix
{
Usage:
    kpc

Synopsis:
    Attempts to knock some sense into a confused target pc. 

Notes:
    * This command is not supported for DOS.
}
{
    global file-os

    if {[string c ${file-os} unix] != 0} {
    	error {The "kpc" command is supported only for UNIX, not for DOS.}
    }

    exec kpc
}]
alias l listi
alias w where
alias bt backtrace
alias c cont
alias ds dumpstack
alias p print
alias s step
alias n next
alias sd   {[sym-default $1]}

alias :0 {switch :0}
alias :1 {switch :1}
alias :2 {switch :2}
alias :3 {switch :3}
alias :4 {switch :4}
alias :5 {switch :5}
alias :6 {switch :6}
alias :7 {switch :7}
alias :8 {switch :8}
alias :9 {switch :9}
alias : {switch}
# if we have a newer kernel, turn on some error checking
[if {![null [info command address-kernel-internal]] && 
    ![null [patient find geos]]} 
{ 
    brk tset [address-kernel-internal Idle] {  	ec normal
    	    	    	    	    	    	expr 0}
}]
##############################################################################
#									     #
#				FATAL ERROR STUFF			     #
#         								     #
# We've got a handler for the ATTACH event whose purpose is to make sure     #
# there's a breakpoint at FatalError (on the assumption it will invoke why)  #
##############################################################################
[defsubr _check_fatal_error {args}
{
    #
    # If patient just started is the kernel and there's not already a breakpoint
    # at FatalError, place our nice breakpoint there now.
    #
    if {![null [patient find geos]]} {
        [if {[null [sym find proc geos::FatalError]] && 
             ![null [info command address-kernel-internal]]} {
	     if {[null [address-kernel-internal WritableFatalError]]} {
                 var addr_fe [address-kernel-internal FatalError]
	     } else {
		 var addr_fe [address-kernel-internal WritableFatalError]
	     }
        } else {
	    if {[null [sym find proc geos::WritableFatalError]]} {
                var addr_fe geos::FatalError
	    } else {
		var addr_fe geos::WritableFatalError
	    }

        }]
    }
    if {![null [sym find proc geos::WritableWarningNotice]]} {
	var addr_wn geos::WritableWarningNotice
	var addr_cwn geos::WritableWarningNotice
    } else {
        var addr_wn geos::WarningNotice
        var addr_cwn geos::CWARNINGNOTICE
    }
    if {[string c [patient name [index $args 0]] geos] == 0} {
    	if {![brk isset $addr_fe]} {
    	    if {[null [info command address-kernel-internal]]} {
	    	brk aset $addr_fe {
    	    	    why
       	            assign {word errorFlag} 0
        	    expr 1}
    	    } else {
	    	brk aset $addr_fe {
    	    	    why
    	            assign {word [address-kernel-internal errorFlag]} 0
        	    expr 1}
    	    }
    	}
    	if {[not-1x-branch]} {
	    if {![brk isset $addr_wn]} {
		brk aset $addr_wn why-warning
	    }
	    if {![brk isset $addr_cwn]} {
		brk aset $addr_cwn why-warning
	    }
    	}
    }
    return EVENT_HANDLED
}]

event handle START _check_fatal_error
if {![null [patient find geos]]} {
    _check_fatal_error [patient find geos]
}

[defsubr _check_loader_error {args}
{
    #
    # If patient just started is the loader and there's not already a breakpoint
    # at LoaderError, place our nice breakpoint there now.
    #
    [if {[string c [patient name [index $args 0]] loader] == 0} 
    {
    	if {![null [sym find proc loader::LoaderError]]} {
    	    if {![brk isset loader::LoaderError]} {
    		brk aset loader::LoaderError [format {echo Loader death due to [penum LoaderStrings [read-reg ax]]\nexpr 1}]
    	    }
    	}
    }]
    return EVENT_HANDLED
}]

event handle START _check_loader_error
if {![null [patient find loader]]} {
    _check_loader_error [patient find loader]
}
###############################################################################
#
#   STUB-SPECIFIC CODE
#
[defsubr _check_stub_type {args}
{
    #
    # The stub type can conceivably change between attaches (and the stub-
    # support code might need to define symbols in the kernel or what have you),
    # so load the stub-support code here.
    #
    global stub-type
    
    if {[catch {load ${stub-type}} why]} {
    	#echo Warning: couldn't load ${stub-type}: ${why}
    }
    return EVENT_HANDLED
}]
event handle ATTACH _check_stub_type
_check_stub_type

###############################################################################
#
# WINDOW-SYSTEM-SPECIFIC CODE
#
catch {load ${window-system}}

###############################################################################
#
# DEBUGGER THINGS
#
[defvar debugger enter-debugger swat_prog.debug
{Name of the command when things go wrong. The function is passed two
arguments: a condition and the current result string from the interpreter.
The condition is "enter" if entering a command whose debug flag is set, "exit"
if returning from a frame whose debug flag is set, "error" if an error occurred
and the "debugOnError" variable is non-zero, "quit" if quit (^\) is typed and
the "debugOnReset" variable is non-zero, or "other" for some other cause
(e.g. "debug" being invoked from within a function).

Execution continues when the function returns. The result of the function
replaces the previous result for the interpreter.}]

[defvar debugOnError 0 swat_prog.debug
{Usage:
    var debugOnError (0|1)

Examples:
    "var debugOnError 1" 	turn on debugging when there's an error

Synopsis:
    Enter debug mode when Swat encounters a Tcl error.

Notes:
    * The 0|1 simply is a false|true to stop and debug upon encountering
      an error in a Tcl command.

    * If an error is caught with the catch command, Swat will not 
      enter debug mode.

See also:
    debugger.
}]

[defvar debugOnReset 0 swat_prog.debug
{If non-zero and ^\ is typed or you answer 'n' to the 'Do you want to abort?'
prompt, causes the function indicated by the "debugger" variable to be
invoked}]

load debug
#
# Read home .swat file first, then local .swat if not in home directory.
#
if {[string c ${file-os} unix] == 0} {
    if {[file exists ~/swat.rc]} {
	if {[catch {source [file expand ~/swat.rc]} res] != 0} {
	    echo Warning: ~/swat.rc: $res
	}
    }
    [if {[file exists ${file-init-dir}/swat.rc] && 
	 [string c [file expand ~] ${file-init-dir}] != 0}
    {
	if {[catch {source ${file-init-dir}/swat.rc} res] != 0} {
	    echo Warning: ${file-init-dir}/swat.rc: $res
	}
    }]
} elif {[string c ${file-os} win32] == 0} {
    var h [getenv CUSTOM_TCL_LOCATION]
    if {![null $h]} {
	if {[file exists $h]} {
	    if {[catch {source $h} res] != 0} {
		echo Warning: $h: $res
	    }
	} else {
	    echo Warning: Couldn't find the init file: $h
	}
    }
} else {
    var h [getenv HOME]
    if {![null $h]} {
    	if {[string match $h {*\\}]} {
	    var h [range $h 0 [expr [length $h char]-2] char]
    	}
	if {[file exists $h/swat.rc]} {
    	    if {[catch {source $h/swat.rc} res] != 0} {
	    	echo Warning: $h/swat.rc: $res
    	    }
    	}
    }
    [if {[file exists ${file-init-dir}/swat.rc] &&
    	 [string c [getenv HOME] ${file-init-dir}] != 0}
    {
    	if {[catch {source ${file-init-dir}/swat.rc} res] != 0} {
	    echo Warning: ${file-init-dir}/swat.rc: $res
    	}
    }]
}


#set the kernelVersion number if not already set
if {[null $kernelVersion]} {
	var kernelVersion 0
}

#if the user doesn't specifically specific a startup and stop, and
# we are just up to the loader then continue
if {[string c ${file-os} dos] == 0 && ![null $continueStartup]} {
    echo done
    halt
    if {[null [patient find geos]]} {
    	echo Continuing...
    	cont
    }
}

#make sure the stub-regs-are-32 is set to 0 if not defined by older SWATs
if {[null ${stub-regs-are-32}]}  {
    var stub-regs-are-32 0
}

if {[null ${stub-is-geos32}]}  {
    var stub-is-geos32 0
}
