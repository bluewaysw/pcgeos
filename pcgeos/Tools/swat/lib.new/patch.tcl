##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System library.
# FILE: 	patch.tcl
# AUTHOR: 	Tony
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	patch	    	    	Patch code
#	patchout, patchin	Null out routine, undo this
#
#	$Id: patch.tcl,v 3.9.12.1 97/03/29 11:26:25 canavese Exp $
#
###############################################################################

[require call-patient call]

[defcmd patch {args} top.breakpoint
{Usage:
    patch [<addr>]
    patch del <addr>*

Examples:
    "patch cs:ip"	    Set a patch at the current execution point
    "patch del"	    	    Deletes all patches

Synopsis:
    Patch assists in creating breakpoints that invisibly make small changes
    to code.  This can help the programmer find several bugs without
    remaking and redownloading.

Notes:
    * If you give no <addr> when creating a patch, the patch will be placed
      at the most-recently accessed address, as set by the command that
      most-recently accessed memory (bytes, words, listi, imem, etc.)

    * When creating a patch, you are prompted for its contents, each line of
      which comes from the following command set:

	Form			Meaning			Examples
	----			-------			--------
	<reg> = <value>		assign value to reg	ax = bx
							dl = 5
	push (<reg>|<value>)	push value		push ax
							push 45
	pop (<reg>|<value>)	pop value		pop ax
							pop 45
	pop			pop nothing (sp=sp+2)	pop
	jmp <address>		change ip		jmp UI_Attach+45
	scall <address> <regs>	call routine (save)	call MemLock ax=3
	mcall <address> <regs>	call routine (modify)	call MemLock ax=3
	xchg <reg> <reg>	swap two registers	xchg ax bx
	set <flag>		set condition flag	set CF
							set ZF
	reset <flag>		reset condition flag	reset CF
							reset ZF
	if <flag>		if flag set then ...	if CF
	if !<flag>		if flag reset then ...	if !ZF
	if <expr>		if expr then...		if foo == 4
	else
	endif
	ret			make function return	ret
	$			Terminate input
	a			Abort
	<other>		    	Tcl command		echo $foo

      <flag> is taken from the set TF, IF, DF, OF, SF, ZF, PF, AF, CF
      and *must* be in upper-case.

      The "scall" command has no effect on the current registers (not even
      for purposes of return values), while the "mcall" command changes whatever
      registers the function called modifies. See the "call" documentation for
      the format of <regs>.

    * You finish entering a patch by typing $ on a line by itself.

See also:
    brk, cbrk
}
{
    global plist flags

    if {[string c [index $args 0] del] == 0} {
    	# Delete patches
	if {[length $args] > 1} {
	    foreach i [range $args 1 end] {
    	    	# locate all breakpoints at the address
	    	var bps [brk list $i]
		if {[null $bps]} {
		    echo Warning: no breakpoints at $i
		} else {
    	    	    # For each breakpoint at the address, remove the breakpoint
		    # from plist. If the breakpoint was actually in plist,
		    # delete it.
		    foreach bp $bps {
		    	var nlist [mapconcat j $plist {
			    if {$j != $bp} {
			    	format {%s } $j
			    }
			}]
			if {[string c $nlist $plist] != 0} {
    	    	    	    var plist $nlist
			    brk clear $bp
			}
		    }
	    	}
	    }
    	} else {
    	    # confirm
	    echo -n Remove all patches?\ 
	    var l [read-line 0]
	    if {[string m $l {[Yy]*}]} {
    	    	# delete all the patches and reset plist to be empty
    	    	foreach i $plist {
		    catch {brk clear $i} foo
		}
		var plist {}
	    }
    	}
    } else {
	var templist {}
	var done 0
	var depth 0 offset 0
    	var addr [get-address $args]
    	echo Finish by typing \$ or . on a line by itself.
	while {$done == 0} {
	    #read next line with no pre-existing input and no history
	    if {$depth == 0} {
		var pr {patch => }
	    } else {
		var pr [format {patch (%d) => } $depth]
	    }
	    var line [top-level-read $pr {} 0]
	    if {[string match $line {[$.]}]} {
		var done 1
	    } else {
	    	#examine command
		[case [index $line 0] in
		    if {
    	    	    	#handle conditional
			#check for ! (reverses logic)
			var reverse [expr ![string c [index [index $line 1]
								0 c] !]]
			#check for flag
			var fl [assoc $flags [range [index $line 1] $reverse
								end c]]
			if {[null $fl]} {
			    var op [format {if {%s} \{} [range $line 1 end] ]
			} else {
    	    	    	    var op [format {if {%s([read-reg cc] & %d)} \{}
			    	    	[if {$reverse} {format {! }}]
					[index $fl 1]]
			}
			var depth [expr $depth+1]
		    }
		    endif {
			#close 'if' code and decrement depth
    	    	    	if {$depth > 0} {
			    var op \}
			    var depth [expr $depth-1]
    	    	    	    var offset $depth
    	    	    	} else {
			    echo Error: unmatched "endif"
			}
		    }
		    else {
			#output code to do else
    	    	    	if {$depth > 0} {
			    var op [format {\} else \{}] offset [expr $depth-1]
			} else {
			    echo Error: unmatched "else"
			}
		    }
		    set {
		    	#set condition flag
			var fl [index [assoc $flags [index $line 1]] 1]
			var op [format {assign cc [expr [read-reg cc]|%d]} $fl]
		    }
		    reset {
		    	#reset condition flag
			var fl [index [assoc $flags [index $line 1]] 1]
			var op [format {assign cc [expr [read-reg cc]&~%d]}
			    	    	 $fl]
		    }
		    push {
		    	#decrement sp and store next argument there
			var op [format {[assign sp sp-2] [assign ss:sp {%s}]}
			    	    [range $line 1 end]]
		    }
		    pop {
			if {[length $line] == 1} {
			    #pop and discard
			    var op {assign sp sp+2}
			} else {
			    #fetch word from ss:sp and store in arg, then
			    #increment sp
			    var op [format {[assign {%s} [value fetch ss:sp word]] [assign sp sp+2]}
			    	    	[range $line 1 end]]
			}
		    }
		    xchg {
    	    	    	#exchange register values using temporary
			#xxx: exchange memory too?
			var op [format {[var _patch [read-reg %s]] [assign %s [read-reg %s]] [assign %s $_patch]}
			    	    [index $line 1] [index $line 1]
    				    [index $line 2] [index $line 2]]
		    }
		    jmp {
    	    	    	#change ip to match next arg
			var op [format {assign ip {%s}} [range $line 1 end]]
		    }
		    {call mcall scall} {
    	    	    	#use internal call-patient function to perform call
    	    	    	#xxx: what if returns 0?
    	    	    	[case [index [index $line 0] 0 chars] in
			 m {var foo discard}
			 s {var foo restore}
			 default {
			    echo Warning: defaulting "call" to "scall"
			    var foo restore
			 }]
			var op [format {
if {[call-patient %s]} {
    %s-state
} else {
    discard-state
    error {call unsuccessful}
}
					} [range $line 1 end] $foo]
		    }
		    ret {
    	    	    	var s [sym faddr func $addr]
    	    	    	if {[null $s]} {
			    echo Error: can't do "ret" -- no function near $addr
    	    	    	    break
    	    	    	}
			var op [format {
assign ip [frame register ip [frame next [frame top]]]
assign cs [frame register cs [frame next [frame top]]]
assign sp [frame register sp [frame next [frame top]]]+%d}
    	    	    	[if {[string c [index [sym get $s] 1] near] == 0} {
			    expr 2
    	    	    	} else {
			    expr 4
    	    	    	}]]
		    }
		    a {
		    	#abort without doing anything
			return
		    }
		    default {
		    	#check for <foo> = <biff>
			if {[length $line] == 3 &&
					![string c [index $line 1] =]} {
    	    	    	    #perform assignment between two sides
			    var op [format {assign %s {%s}} [index $line 0]
			    	    	[range $line 2 end]]
			} else {
    	    	    	    #set to invoke line as given
			    var op $line
			}
		    }
		]
    	    	#add to growing list of commands
    	    	if {[null $templist]} {
		    var templist $op
		} else {
		    var templist [format {%s\n%*s%s} $templist $offset {} $op]
		}
		var offset $depth
	    }
	}
	while {$depth > 0} {
	    var templist [format {%s\n%*s\}} $templist [expr $depth-1] {}]
	    var depth [expr $depth-1]
	}

    	#make sure breakpoint doesn't cause stop except on error
	var templist [format {%s\nexpr 0} $templist]
    	#set breakpoint and add to list of patchpoints
    	scan [brk aset $addr $templist] {brk%d} bnum
	
	var plist [concat $plist $bnum]
    }
}]


[defcmd patchout routine breakpoint
{
	patchout causes a RET to be placed at the start of a routine.
}
{
    var s [index [sym get [sym find func $routine]] 1]
    if {[string m $s far]} {
	var op 203
    } else {
	var op 195
    }
    global patchout_$routine

    var patchout_$routine [value fetch $routine byte]

    assign {byte $routine} $op

    echo [format {Routine %s patched out} $routine]

}]


[defcmd patchin routine breakpoint
{
	patchin undoes the work of patchout
}
{
    global patchout_$routine

    assign {byte $routine} [var patchout_$routine]

    echo [format {Routine %s patched in} $routine]

}]
