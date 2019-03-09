##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#	$Id: swat.tcl,v 3.6 90/08/24 04:00:45 adam Exp $
#
###############################################################################
##############################################################################
#                                                                            #
#			PROGRAMMING UTILITIES				     #
#									     #
##############################################################################
[autoload loop 1 loop prog.loop
{Simple integer loop procedure. Usage is:

        loop <loop-variable> <start>,<end> [step <step>] <body>

<start>, <end>, and <step> are integers. <body> is a string for
TCL to evaluate. If no <step> is given, 1 or -1 (depending as <start>
is less than or greater than <end>, respectively) is used. <loop-variable>
is any legal TCL variable name.}]

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

#
# unalias just does a Tcl_DeleteCommand, but it's nice to have a more
# meaningful name for it should one use it to nuke tcl procedures...
#
alias purge {unalias}

[defcommand wproc {name file {append 0}} prog
{Writes a command procedure NAME out to the file FILE. If optional third
arg APPEND is non-zero, the procedure will be appended to the file. Otherwise
it will overwrite the file. This does not know if a procedure is a subroutine.}
{
    [var args [info args $name] body [info body $name] pargs {}
     	 help [index [help-get $name] 0]]
    
    map i $args {
    	if {[info default $name $i def]} {
	    [list $i $def]
	} else {
	    var i
    	}
    }
    if {$append} {var mode a} {var mode w}
    var s [stream open $file $mode]
    if {[null $s]} {
    	error [format {couldn't open %s} $file]
    } else {
    	stream write [list defcommand $name $pargs $help $body] $s
	stream close $s
    }
}]


[defdsubr field {list name} prog.list|prog.memory
{Assuming first argument LIST is a structure-value list from the "value"
command, return the value for field NAME in the structure.}
{
    var el [assoc $list $name]

    if {[null $el]} {
    	return nil
    } else {
    	return [index $el 2]
    }
}]

##############################################################################
#
#		      LOAD IMPORTANT OTHER FILES
#
##############################################################################
require set-repeat top-level
load lisp
load format-inst
load stack
load istep
load memory
load autoload		

[defsubr frame-instruction {args}
{
    if {[index $args 0]} {
    	return EVENT_NOT_HANDLED
    } else {
	echo [format-instruction [unassemble [frame register pc]]]
	return EVENT_HANDLED
    }
}]
event handle STACK frame-instruction

##############################################################################
#                                                                            #
#			FRONT-ENDS TO THE BRK COMMAND			     #
#                                                                            #
##############################################################################
alias del {brk clear}
alias delete {brk clear}
alias dis {brk disable}
alias disable {brk disable}
alias en {brk enable}
alias enable {brk enable}
alias j {brk list}

[defcommand go {args} breakpoint|top
{Takes as many address expressions as desired for arguments and sets
breakpoints at all of them. These breakpoints will be removed when the machine
stops AND ARE ONLY ACTIVE FOR THE CURRENT PATIENT. After the breakpoints
are set, the machine is continued in the usual fashion.}
{
    foreach i $args {
    	brk tset $i
    }
    cont
}]

[autoload ibrk 0 ibrk]

#
# Just to amuse "perverts" or to make annoyed people more so :)
#
[defsubr fuck {args}
{
    if {[string c $args me] == 0} {
    	echo why?
    } else {
    	echo no
    }
}]

##############################################################################
#
# Handler for when the patient stops.
# When a FULLSTOP event is received, this function checks to see if
# printStop is non-zero, and if it is, it prints a message indicating
# the function in which execution stopped, along with the source line, if
# available, or machine instruction, as a last resort.
#
[defvar printStop 1 variable.misc
{If non-zero causes the current PC and the reason for stopping to be printed
each time the machine comes to a complete stop}]

[defsubr fullstop {why args}
{
    global printStop

    if {$printStop && [string c $why _DONT_PRINT_THIS_] != 0} {
	var frame [frame top]
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
	}
	echo -n Stopped in [frame function $frame],
	[if {[catch {src line [frame register pc $frame]} fileLine]==0 &&
	     ![null $fileLine]}
    	{
	    var file [index $fileLine 0]
	    var line [index $fileLine 1]

	    echo { line} $line, "$file"
	} else {
	    echo { address} [frame register pc $frame]
    	}]
	echo [format-instruction [unassemble cs:ip 1]]
    }
    return EVENT_HANDLED
}]

event handle FULLSTOP fullstop

#
# Functions for simple actions for breakpoints:
#     	halt makes the breakpoint unconditional
#
[defsubr halt {args}
{
    return 1
}]

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
[defvar waitForPatient 1 variable.obscure
{If non-zero, the command-level patient-continuation commands (step, next
and cont, e.g.) will wait for the machine to stop before returning. Otherwise,
they will return right away and you will have to use stop-patient to make
the machine stop. This isn't fully tested and should only be set 0 in
very weird circumstances}]

[defcommand step {args} step
{Make the patient execute a single machine instruction. If waitForPatient is 
non-zero, waits for the machine to stop again. BEWARE: This doesn't do any
of the checks for special things (XchgTopStack, software interrupts, etc.)
performed by the s command in istep.}
{
    global waitForPatient lastCommand repeatCommand
    var repeatCommand $lastCommand
    step-patient
}]

[defdsubr next {args} step|breakpoint
{Execute a single instruction, skipping over any calls, repeated instructions,
or software interrupts. Does not protect against recursion, however, so the
breakpoint set may be taken in an instance of the current function different
than the one in which you executed this command.}
{
    global waitForPatient lastCommand repeatCommand

    var csip [read-reg cs]:[read-reg ip]
    var inst [mangle-softint [unassemble $csip]]
    var op [index $inst 1]

    var repeatCommand $lastCommand
    [case $op in
     REP*|CALL*|INT* {
    	brk tset $csip+[index $inst 2]
    	continue-patient
    	if {$waitForPatient} wait
     }
     default {
    	step-patient
    }]
}]

[defcommand cont {args} top
{Continue the machine. If waitForPatient is non-zero, waits for the machine to
stop again.}
{
    global waitForPatient
    continue-patient
    if {$waitForPatient} wait
}]

[defsubr rs {} {rs-common 0}]
[defsubr rss {} {rs-common 1}]
[defsubr rsn {} {rs-common 2}]
[defsubr rssn {} {rs-common 3}]

[defsubr rs-common {mode}
{
	global attached
	if {$attached} {
		error {already attached}
	}
	protect {
		var s [stream open [getenv PTTY] w]
		stream write [format {\eRS%c} [expr $mode+32]] $s
	} {
		catch {stream close $s} foo
	}
}]

[defsubr att {args}
{
    global attached
    if {$attached} {
	error {already attached}
    }
    if {![null $args]} {
    	[case $args in
	    -s	{
	    	rss
		sleep 5
    		attach
	    }
    	    -sn {
	    	rssn
		sleep 5
		attach
	    }
	    -f {
	    	rs
		sleep 20
    		attach
	    }
    	    -rn {
	    	rssn
		sleep 5
		stop-catch {attach}
		cont
    	    }
	    -r {
	    	rss
		sleep 5
		stop-catch {
		    attach
    	    	}
		cont
    	    }
    	]
    } else {
    	attach
    }
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
	     {cs 9} {ds 11} {ss 10} {es 8} {ip 12} {cc 13}}

var flags {{OF 2048} {DF 1024} {IF 512} {TF 256} {SF 128} {ZF 64} {AF 16} {PF 4} {CF 1}}

[defdsubr read-reg {reg} prog.patient|prog.thread|patient|thread
{Returns the current value for register REG as a decimal number}
{
    return [index [addr-parse @$reg] 1]
}]

[defsubr print-frame-regs {frame}
{
    global regnums flags
    #
    # Print out the general registers in both hex and decimal
    #
    var j 0
    foreach i {AX BX CX DX SI DI BP SP} {
	var regval [frame register $i $frame]
	echo -n [format {%-4s%04xh%8d} $i $regval $regval]
	var j [expr ($j+1)%3]
	if {$j == 0} {echo} else {echo -n \t}
    }
    #
    # Blank line.
    #
    echo
    echo
    #
    # Now the segment registers in hex followed by the handle ID and name, if
    # they point at one.
    #
    foreach i {CS DS SS ES} {
    	var regval [frame register $i $frame]
    	var handle [handle find [format 0x%04x:0 $regval]]
    	if {![null $handle]} {
    	    if {[handle state $handle] & 0x480} {
    	    	#
		# Handle is a resource/kernel handle, so it's got a symbol in
    	    	# its otherInfo field. We want its name.
    	    	#
    	    	echo -n [format {%-4s%04xh   handle %04x (%s)}
    	    	    	    $i $regval [handle id $handle]
    	    	    	    [symbol fullname [handle other $handle]]]
    	    } else {
    	    	echo -n [format {%-4s%04xh   handle %04x}
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
			   [format {0x%x:0x%x} [frame register CS $frame] $ip]]
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
    echo [format-instruction [unassemble cs:ip 1]]
}]

[defcommand regs {args} top
{Print out the current registers in a nice format. This includes the flags,
and the instruction at the current CS:IP}
{
    print-frame-regs [frame cur]
}]
	
##############################################################################
#
#
# Aliases
#
alias l listi
alias w backtrace
alias where backtrace
alias bt backtrace
alias kpc {[exec kpc]}
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

##############################################################################
#									     #
#				FATAL ERROR STUFF			     #
#         								     #
# We've got a handler for the ATTACH event whose purpose is to make sure     #
# there's a breakpoint at FatalError (on the assumption it will invoke why)  #
##############################################################################
[defdsubr why {} misc
{Returns the enumerated constant for the error code in AX}
{
    if {[string c [func] FatalError] == 0} {
	#	
	# Find the symbol of the caller of FatalError
	#
    	var nf [frame next [frame top]]
        var fs [frame funcsym $nf]
	#
	# Fetch its full name so we find the patient.
	#
        var fn [symbol fullname $fs]
    	if {[string match $fn *::AppFatalError]} {
	    var nf [frame next $nf]
	    var fs [frame funcsym $nf]
	    var fn [symbol fullname $fs]
    	}
	if {[string match $fn *::*::*]} {
    	    #
	    # In a different patient -- find the FatalErrors for that patient
	    #
    	    var fe [symbol find type
	     	    [range $fn 0 [expr [string f : $fn]-1] chars]::FatalErrors]
	} else {
    	    #
	    # Else find it for this one
	    #
	    var fe [symbol find type FatalErrors]
    	}
    	return [type emap [value fetch [frame register pc $nf]+1 word] $fe]
    } else {
    	error {Not in FatalError, fish-brain}
    }
}]

[defsubr _check_fatal_error {args}
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

    if {![brk isset FatalError]} {
	brk aset FatalError [format {echo Death due to [why]\nassign kdata::errorFlag 0\nexpr 1}]
    }
    return EVENT_HANDLED
}]

event handle ATTACH _check_fatal_error
_check_fatal_error
#
# Load window-system-specific things
#
catch {load ${window-system}}

#
# Debugger things
#
[defvar debugger enter-debugger prog.debug
{Name of the command when things go wrong. The function is passed two
arguments: a condition and the current result string from the interpreter.
The condition is "enter" if entering a command whose debug flag is set, "exit"
if returning from a frame whose debug flag is set, "error" if an error occurred
and the "debugOnError" variable is non-zero, "quit" if quit (^\) is typed and
the "debugOnReset" variable is non-zero, or "other" for some other cause
(e.g. "debug" being invoked from within a function).

Execution continues when the function returns. The result of the function
replaces the previous result for the interpreter.}]

[defvar debugOnError 0 prog.debug
{If non-zero and an uncaught error is detected by the interpreter, the
function indicated by the "debugger" variable is invoked}]

[defvar debugOnReset 0 prog.debug
{If non-zero and ^\ is typed or you answer 'n' to the 'Do you want to abort?'
prompt, causes the function indicated by the "debugger" variable to be
invoked}]

load debug

#
# Read home .swat file first, then local .swat
#
if {[file ~/.swat exists]} {
    if {[catch {source [file ~/.swat expand]} res] != 0} {
    	echo Warning: ~/.swat: $res
    }
}
if {[file ${init-directory}/.swat exists]} {
    if {[catch {source ${init-directory}/.swat} res] != 0} {
    	echo Warning: ${init-directory}/.swat: $res
    }
}
