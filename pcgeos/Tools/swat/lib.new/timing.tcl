##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System library
# FILE: 	timing.tcl
# AUTHOR: 	Adam de Boor, Mar 17, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	cycles	    	    	Counts cycles for executing all instructions
#				between cs:ip and given address.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/17/89		Initial Revision
#
# DESCRIPTION:
#	Routines/commands for cycle-counting
#
#   	Unhandled: BOUND, INTO (class cint)
#
#	$Id: timing.tcl,v 3.25.11.1 97/03/29 11:26:30 canavese Exp $
#
###############################################################################
defvar timingTable 0
[defvar timingProcessor i88 swat_variable
{The processor for which to generate cycle counts. One of i86, i88, i286, or
V20}]

#
# Read in the entire timing file into the timingTable
#
global timingTable file-root-dir file-syslib-dir
if {!$timingTable} {
    echo -n Reading timing database...

    var dbname ${file-syslib-dir}/timing.80x8x
    var s [stream open $dbname r]
    if {[null $s]} {
	error [format {unable to load timing database %s} $dbname]
    }
    var timingTable [table create 32]
    for {} {![stream eof $s]} {} {
    	var l [stream read list $s]
    	if {![null $l]} {
	    table enter $timingTable [index $l 0] $l
	}
    }
    stream close $s
    echo done
}

#
# Find the list describing the given instruction in the timing database
#
[defsubr find-inst {instName}
{
    global  timingTable

    return [table lookup $timingTable $instName]
}]
    
#
# Given an inst list returned by unassemble nil 1, figure the number
# of cycles the instruction will take.
#
[defsubr fetch-cycles {inst}
{
    var i [index $inst 1]
    var desc [find-inst [index $i 0]]
    
    if {[null $desc]} {
    	return -1
    }
    #
    # Strip off hex form of immediate source, if source immediate...
    #
    var paren [string first ( $i]
    if {$paren > 0} {
    	var cparen [string first ) $i]
	if {$cparen == [length $i chars]-1} {
	    var inst [list [index $inst 0]
		       	[range $i 0 [expr $paren-2] chars]
		       	[index $inst 2]
		       	[index $inst 3]]
	} else {
	    var inst [list [index $inst 0]
	    	    	    [format {%s%s} [range $i 0 [expr $paren-2] chars]
			    	    [range $i [expr $cparen+1] end chars]]
			    [index $inst 2]
			    [index $inst 3]]
    	}
    }

    return [eval [format {%s-cycles {%s} {%s}} [index $desc 1] $inst $desc]]
}]

#
# Given an instruction list, a list of times for the instruction's addressing
# mode, a flag indicating if the size of the operation should be checked to 
# determine whether to use the 88b/86 or the 88w times (or whether should
# just use the 88w time) and a repeat count, if operation being repeated,
# return the number of cycles the instruction takes to execute. In the case
# of variable-length instructions (multiplication, e.g.), returns a list of
# the min and max times.
#
[defsubr decode-cycles {inst times {noCheck 0} {repCount 0}}
{
    global timingProcessor

    [case $timingProcessor in 
     i88 {
    	if {!$noCheck} {
	    var addr [index $inst 0]

	    [for {var b [value fetch $addr [type byte]]}
		 {(($b & 0xfe)==0xf2) || (($b & 0xe7)==0x26) || ($b == 0xf0)}
		 {var b [value fetch $addr [type byte]]}
	     {
		 var addr $addr+1
	     }
	    ]
	    if {$b & 1} {
		# word operation -- use entry 2
		var cycles [index $times 2]
	    } else {
		var cycles [index $times 1]
	    }
    	} else {
    	    # noCheck -- always use word time
	    var cycles [index $times 2]
	}
     }
     i86 {
     	var cycles [index $times 1]
     }
     i286 {
     	var cycles [index $times 3]
     }
     V20 {
    	if {!$noCheck} {
	    var addr [index $inst 0]

	    [for {var b [value fetch $addr [type byte]]}
		 {(($b & 0xfe)==0xf2) || (($b & 0xe7)==0x26) || ($b == 0xf0)}
		 {var b [value fetch $addr [type byte]]}
	     {
		 var addr $addr+1
	     }
	    ]
	    if {$b & 1} {
		# word operation -- use entry 5
		var cycles [index $times 5]
	    } else {
	        # byte operation -- use entry 4
		var cycles [index $times 4]
	    }
    	} else {
    	    # noCheck -- always use word time
	    var cycles [index $times 5]
	}
     }
    ]

    var plus [string first + $cycles]
    if {$plus < 0} {
    	var plus [length $cycles chars]
    }
    
    # extract the base cycle
    var result [range $cycles 0 [expr $plus-1] chars]
    var extra 0 mode [index $times 0]

    if {[string first mem $mode] >= 0} {
	if {[string c $timingProcessor i286] == 0} {
	    # for the 286, the only penalty is incurred for disp[base][idx]
	    if {[string m [index $inst 1] {*[0-9]\[B[XP]\]\[[SD]I\]*}]} {
		var extra 1
	    }
	} else {
	    # figure the addressing mode using a case with patterns going
	    # from most to least restrictive. This way we'll get the most-
	    # qualified one if it matches...
    	    #debug
	    [case [index $inst 1] in
	     {*[0-9]\\[BX\\]\\[SI\\]* 
	      *[0-9]\\[BP\\]\\[DI\\]*} {
		var extra 11
	     }
	     {*[0-9]\\[BX\\]\\[DI\\]*
	      *[0-9]\\[BP\\]\\[SI\\]*} {
		var extra 12
	     }
	     {*\\[BX\\]\\[SI\\]*
	      *\\[BP\\]\\[DI\\]*} {
		var extra 7
	     }
	     {*\\[BX\\]\\[DI\\]*
	      *\\[BP\\]\\[SI\\]*} {
		var extra 8
	     }
	     {*[0-9]\\[B[XP]\\]*
	      *[0-9]\\[[DS]I\\]*} {
		var extra 9
	     }
	     {*\\[B[XP]\\]*
	      *\\[[SD]I\\]*} {
		var extra 5
	     }
	     default {
		# direct addressing...
    	    	if {[string match $mode *ax*]} {
    	    	    #special accumulator mode -- no EA penalty except for
		    #override.
		    var extra 0
		} else {
		    var extra 6
		}
	     }
	    ]
	    if {[string match [index $inst 1] {*[ESDC]S:*}]} {
		# segment override
		var extra [expr $extra+2]
	    }
	}
    }

    if {[string m $cycles *+m]} {
	# add size of destination instruction. first need to locate it...
    	var dest [range [index $inst 1] 1 end]
	[case $dest in
	 *DWORD* {
	    #far indirect. Get address from args. Weird because given as
	    #32-bit integer.
	    var dest 0x[range $dest [expr [string first = $dest]+1]
	    	    	    [expr [length $dest chars]-1] chars]
	    var dest [format {%04xh:%04xh} [expr ($dest>>16)&0xffff]
	    	    	    [expr $dest&0xffff]]
	    
	 }
	 *WORD* {
	    #near indirect. Get address from args
	    var dest cs:[range $dest [expr [string first = $dest]+1]
	    	    	    	[expr [length $dest chars]-1] chars]
    	 }]
	#disassemble instruction at dest to figure its size
	var extra [expr $extra+[index [unassemble $dest 0] 2]]
    } else {
	[case $cycles in
	 *+n {
	    var extra [expr $extra+$repCount]
	 }
	 {*+[0-9]n} {
	    var extra [expr
		       $extra+$repCount*[index $cycles
					 [expr
					  [length $cycles chars]-2]
					 chars]]
	 }
	 {*+[1-9][0-9]n} {
	    var cl [length $cycles chars]
	    var extra [expr
		       $extra+$repCount*[range $cycles
					 [expr $cl-3] [expr $cl-2] chars]]
	 }
	]
    }
    var colon [string first : $result]
    if {$colon != -1} {
	[var t1 [range $result 0 [expr $colon-1] chars]
	     t2 [range $result [expr $colon+1] end chars]]
	return [list [expr $t1+$extra] [expr $t2+$extra]]
    } else {
	return [expr $result+$extra]
    }
}]
	     
	    
#
# Instructions with implied operands...
#
[defsubr implied-cycles {inst desc {mode default} {repeatCount 0}}
{
    return [decode-cycles $inst [assoc $desc $mode] 1 $repeatCount]
}]

#
# Control-transfer instructions (jmp/call...)
#
[defsubr control-cycles {inst desc}
{
    # figure the mode of the instruction to find the right element...
    [case [index $inst 1] in
     *WORD* {
     	# indirect, near
	return [decode-cycles $inst [assoc $desc mem16] 1]
     }
     *DWORD* {
     	# indirect, far
	return [decode-cycles $inst [assoc $desc mem32] 1]
     }
     default {
     	[case [index $inst 2] in
	 2 {
	    # short or register-indirect
    	    [case [index [index $inst 1] 1] in
	     {[ABCD]X
	       BP
	       [SD]I} {
	     	return [decode-cycles $inst [assoc $desc reg] 1]
	     }
	     default {
	     	return [decode-cycles $inst [assoc $desc label_s] 1]
	     }
	    ]
	 }
	 3 {
	    #near direct
	    return [decode-cycles $inst [assoc $desc label_n] 1]
	 }
	 5 {
	    #far direct
	    return [decode-cycles $inst [assoc $desc label_f] 1]
	 }
	]
     }
    ]
}]

#
# General instructions that can take an effective address (i.e. have a
# modrm byte)
#
[defsubr ea-cycles {inst desc}
{
    # find the instruction/modrm bytes
    var addr [index $inst 0]

    [for {var b [value fetch $addr [type byte]]}
	 {(($b & 0xfe) == 0xf2) || (($b & 0xe7) == 0x26) || ($b == 0xf0)}
	 {var b [value fetch $addr [type byte]]}
     {
	 var addr $addr+1
     }
    ]
    
    #see if source is immediate
    var i [index $inst 1]
    var il [length $i]

    if {$il == 2} {
    	# only 2 elements -- MUST be a register argument (memory operands
	# always have a size printed before them).
    	return [decode-cycles $inst [assoc $desc reg] 1]
    } else {
	# If able to parse last element as a number, must be immediate
	var isImmed [expr {[catch {expr [index $i [expr $il-1]]}] == 0}]

	if {$isImmed && [string match $i {*A[XL],*}]} {
	    #no modrm byte for this case
	    return [decode-cycles $inst [assoc $desc {reg,immed}] 1]
	} else {    	
	    var modrm [value fetch $addr+1 byte]

	    if {($modrm&0xc0) == 0xc0} {
		if {$isImmed} {
		    return [decode-cycles $inst [assoc $desc {reg,immed}] 1]
		} elif {[string first , $i] >= 0} {
		    return [decode-cycles $inst [assoc $desc {reg,reg}] 1]
		} else {
		    return [decode-cycles $inst [assoc $desc {reg}] 1]
		}
	    } elif {$isImmed} {
		return [decode-cycles $inst [assoc $desc {mem,immed}]]
    	    } elif {[string first , $i] < 0} {
	    	return [decode-cycles $inst [assoc $desc mem]]
	    } else {
		#figure direction or LEA instruction (0x8d)
		if {$b & 0x02 || $b == 0x8d} {
		    #memory to register
		    return [decode-cycles $inst [assoc $desc {reg,mem}]]
		} else {
		    return [decode-cycles $inst [assoc $desc {mem,reg}]]
		}
	    }
	}
    }
}]
	    
#
# Conditional branches. Third element contains "not" if branch will not
# be taken.
#
[defsubr branch-cycles {inst desc}
{
    if {[string first not [index $inst 3]] >= 0} {
    	return [decode-cycles $inst [assoc $desc branch_no] 1]
    } else {
    	return [decode-cycles $inst [assoc $desc branch_yes] 1]
    }
}]

#
# MOV instruction, with its plethora of modes
#
[defsubr move-cycles {inst desc}
{
    # find the instruction/modrm bytes
    var addr [index $inst 0]

    [for {var b [value fetch $addr [type byte]]}
	 {(($b & 0xfe) == 0xf2) || (($b & 0xe7) == 0x26) || ($b == 0xf0)}
	 {var b [value fetch $addr [type byte]]}
     {
	 var addr $addr+1
     }
    ]
    #see if source is immediate
    var i [index $inst 1]
    var il [length $i]

    # able to parse last element as a number -- must be immediate
    if {[catch {expr [index $i [expr $il-1]]}] == 0} {
    	[case [index $i 1] in
    	 {A[XL],} {
	    var times [assoc $desc {ax,immed}]
	    if {[null $times]} {
	    	var times [assoc $desc {reg,immed}]
	    }
	    return [decode-cycles $inst $times 1]
	 }
	 {[BCD][XL],
	  [BS]P,
	  [SD]I,} {
	    return [decode-cycles $inst [assoc $desc {reg,immed}] 1]
	 }
	 default {
	    return [decode-cycles $inst [assoc $desc {mem,immed}]]
	 }]
    } else {
	if {($b & 0xfc) == 0xa0} {
	    #special move ax,mem/mem,ax instruction
	    if {$b & 0x2} {
	    	return [decode-cycles $inst [assoc $desc ax,mem] 0]
	    } else {
	    	return [decode-cycles $inst [assoc $desc mem,ax] 0]
	    }
	}
	
	var modrm [value fetch $addr+1 byte]
    
	# See if either operand is a segment register, setting reg to be
	# seg if so, reg if not (used when forming the mode for which to
	# search)
    	if {[string m $i {* [ESCD]S,*}] || [string m $i {* [ESCD]S}]} {
	    var reg seg noCheck 1
	} else {
	    var reg reg noCheck 0
	}
	
    	if {$b & 0x02} {
    	    #ea to register
	    if {($modrm&0xc0) == 0xc0} {
    	    	return [decode-cycles $inst [assoc $desc $reg,reg] $noCheck]
	    } else {
	    	return [decode-cycles $inst [assoc $desc $reg,mem] $noCheck]
	    }
	} elif {($modrm&0xc0) == 0xc0} {
	    return [decode-cycles $inst [assoc $desc reg,$reg] 1]
	} else {
	    return [decode-cycles $inst [assoc $desc reg,mem]]
	}
    }
}]
     
#
# Software interrupt. Must deal with INT 3 brain damage (why does it take
# one more cycle to execute a smaller instruction?). Must also deal with
# the size of the destination instruction if timing for a 286
#
[defsubr int-cycles {inst desc}
{
    global timingProcessor
    
    [case $timingProcessor in
     i88 {
     	var result [index [assoc $desc default] 2]
    	if {[index [index $inst 1] 1] == 3} {
	    var result [expr $result+1]
	}
     }
     i86 {
     	var result [index [assoc $desc default] 1]
    	if {[index [index $inst 1] 1] == 3} {
	    var result [expr $result+1]
	}
     }
     i286 {
     	var result [index [assoc $desc default] 3]
	var result [range $result 0 [expr [string first + $result]-1] chars]
	var inum [expr [index [index $inst 1] 1]*4]
    	#add size of instruction at handler
	var result [expr
	    	    $result+[index
		    	     [unassemble
		    	      [value fetch 0:$inum+2
			       [type word]]:[value fetch 0:$inum
			       	    	     [type word]] 0]
			     2]]
     }
     V20 {
     	var result [index [assoc $desc default] 5]
     }
    ]
    
    return $result
}]

#
# handle simple prefixes by summing the time for the prefix and the
# unprefixed instruction. Only trick is we have to trim the prefix from
# both the representation (element 1 of $inst) and the instruction size
# (element 2).
#
[defsubr prefix-cycles {inst desc}
{
     return [expr {[decode-cycles $inst [assoc $desc default] 1]+
     	    	   [fetch-cycles [list
		    	    	  [index $inst 0]
				  [range [index $inst 1] 1 end]
				  [expr [index $inst 2]-1]
				  [index $inst 3]]]}]
}]
    	
#
# Figure cycles for pushing/popping. If no operand, use default mode.
# Else if only one word following the mnemonic, it must be a register or
# an immediate value ('286 only). Otherwise it's a memory operand.
# In all these cases, there's no need to check for byte/word instruction
# since one can only access the stack by words.
#
[defsubr stack-cycles {inst desc}
{
    var i [index $inst 1]
    var il [length $i]
    
    if {$il == 1} {
    	return [decode-cycles $inst [assoc $desc default] 1]
    } elif {$il == 2} {
    	[case [index $i 1] in
	 {[ESCD]S} {
	    return [decode-cycles $inst [assoc $desc seg] 1]
	 }
    	 {[0-9]*} {
	    return [decode-cycles $inst [assoc $desc immed] 1]
	 }
	 default {
	    return [decode-cycles $inst [assoc $desc reg] 1]
	 }
	]
    } else {
    	return [decode-cycles $inst [assoc $desc mem] 1]
    }
}]

#
# decides what mode to use based on final operand. If CL, figures reg/mem
# and uses (reg|mem),cl as the mode. If 1, uses (reg|mem),1. Else uses
# (reg|mem),immed ('286 only).
#
[defsubr shift-cycles {inst desc}
{
    var i [index $inst 1]
    var il [length $i]
    
    [case [index $i [expr $il-1]] in
     CL {
     	if {$il != 3} {
	    return [decode-cycles $inst [assoc $desc mem,cl] 0 [read-reg cl]]
	} else {
	    return [decode-cycles $inst [assoc $desc reg,cl] 0 [read-reg cl]]
	}
     }
     1 {
     	if {$il != 3} {
	    return [decode-cycles $inst [assoc $desc mem,1] 1 1]
	} else {
	    return [decode-cycles $inst [assoc $desc reg,1] 1 1]
	}
     }
     default {
     	if {$il != 3} {
	    return [decode-cycles $inst [assoc $desc mem,immed] 0
	    	    [index $i [expr $il-1]]]
	} else {
	    return [decode-cycles $inst [assoc $desc reg,immed] 1
	    	    [index $i [expr $il-1]]]
	}
     }
    ]
}]

#
# retn/retf/iret -- need to handle optional immediate operand for retn/retf
# and the size of the destination instruction when timing for a '286.
#
[defsubr return-cycles {inst desc}
{
    var i [index $inst 1]
    var il [length $i]
    
    if {$il != 1} {
    	var times [assoc $desc immed]
    } else {
    	var times [assoc $desc default]
    }
    global timingProcessor
    [case $timingProcessor in
     i88 {
     	return [index $times 2]
     }
     i86 {
     	return [index $times 1]
     }
     i286 {
    	#handle +m. index $inst 3 contains address to which we're returning
     	var result [index [index $times 3] 0]
	var result [range $result 0 [expr [string first + $result]-1] chars]
	return [expr $result+[index [unassemble [index $inst 3] 0] 2]]
     }
     V20 {
     	return [index $times 5]
     }
    ]
}]

#
# similar to ea except must take care of xchg ax, reg specially
#
[defsubr xchg-cycles {inst desc}
{
    var i [index $inst 1]
    var il [length $i]
    
    if {$il == 3 && [string c [index $i 1] AX,] == 0} {
	return [decode-cycles $inst [assoc $desc ax,reg] 1]
    } else {
    	return [ea-cycles $inst $desc]
    }
}]

#
# repeat prefixes. Need to figure out how many times it'll repeat, then call
# implied-cycles on the instruction being repeated, telling it to use the
# "repeat" mode and giving it the repeatCount to give to decode-cycles.
#
[defsubr repeat-cycles {inst desc}
{
    if {[string c [index [index $inst 1] 0] REP] == 0} {
    	#straight repeat -- can just use CX
	return [implied-cycles $inst [find-inst [index [index $inst 1] 1]]
	    	repeat [read-reg cx]]
    } else {
    	#step until not executing this instruction, counting the number of
	#steps taken.
	[for {var repeatCount 0
	      var ip [frame register ip [frame top]]}
	     {$ip == [frame register ip [frame top]]}
	     {var repeatCount [expr $repeatCount+1]}
	 {
	    stop-catch {
	    	step-patient
	    }
	 }
	]
	return [implied-cycles $inst [find-inst [index [index $inst 1] 1]]
	    	repeat $repeatCount]
    }
}]


#
# Multiply/divide instructions -- average the range...
#
[defsubr muldiv-cycles {inst desc}
{
    [case [range [index $inst 1] 1 end] in
     {[ABCD]X
      [SD]I
      [SB]P} {
     	var result [decode-cycles $inst [assoc $desc reg16] 1]
     }
     {[ABCD][HL]} {
     	var result [decode-cycles $inst [assoc $desc reg8] 1]
     }
     {WORD*} {
     	var result [decode-cycles $inst [assoc $desc mem16] 1]
     }
     {BYTE*} {
     	var result [decode-cycles $inst [assoc $desc mem8] 1]
     }
     default {return 0}
    ]
    if {[length $result] > 1} {
    	return [expr ([index $result 0]+[index $result 1])/2]
    } else {
    	return $result
    }
}]
#
# IN/OUT instructions
#
[defsubr io-cycles {inst desc}
{
    var b [value fetch [index $inst 0] [type byte]]
    if {$b & 0x08} {
    	return [decode-cycles $inst
	    	 [assoc $desc
	     	    [if {$b & 2} {format immed,reg} {format reg,immed}]]]
    } else {
    	return [decode-cycles $inst [assoc $desc reg,reg]]
    }
}]

##############################################################################
# Main entry point.
#
[defcommand cycles {args} profile
{Usage:
    cycles [-r] [-i] [-I] [-f] [-n] (-x <routine>[=<cycles>])* [<end-address>]

Examples:
    "cycles -r"	    	    	Count cycles for each routine, rather than
				showing every instruction and its cycle count.
    "cycles -f"	    	    	Count machine cycles until the current routine
				finishes.
    "cycles -x FSDInt21=2"  	Count cycles normally, but let FSDInt21 run
				full-speed, assuming a cycle-count of 2 for
				the entire routine.
    "cycles endLoop"	    	Count cycles until execution reaches the
				label "endLoop"

Synopsis:
    A low-level optimization tool that counts the number of machine cycles
    a given set of instructions takes to execute on a particular processor.

Notes:
    * In normal operation, this prints out each instruction and its cycle
      count before executing it. If you give the -r, -i, or -I flags, it
      will only print cycle totals for routines, along with a running total.
      -i is like -r, except it indents the display of routines to indicate
      the level of nested routines. -I is like -i, except it indicates the
      call nesting by a number in parentheses, rather than a number of spaces.

    * The -f flag causes cycles to count until the current routine returns
      to its caller.
      
    * In normal operation, cycles tracks the number of cycles the interrupt
      flag remains off, generating a warning when it has been off for more
      than 2,000 cycles (the threshold, on an 8088, above which characters are
      lost when sent over a fast serial line). Pass the -n flag to shut off
      this check (it forces you to hit return to continue counting, which
      may not be ideal if you've left cycles to count something overnight).

    * Counting cycles can take a while. If you don't care about particular
      routines that the code you're profiling calls, or already know a
      typical value for the routine, you can use the -x flag. "-x <routine>"
      causes the routine to be ignored (have a count of 0), while
      "-x <routine>=<count>" tells cycles to assume the routine took <count>
      cycles. In either case, the routine is run at full speed, rather than
      being single-stepped.

See also:
    trace.
}
{
    global lastHaltCode regwindisp
    global cycles_totalList cycles_rnameList cycles_ilevel cycles_total
    var rout 0 indent 0 noIntWhining 0
    var excludes [table create]
    var addr {}

    #
    # Prime the exclusion table with Swat stub routines at 0 cycles each.
    #
    [foreach i {DebugMemory DebugProcess DebugLoadResource
		FarDebugMemory FarDebugProcess FarDebugLoadResource
		UNKNOWN_ROUTINE}
    {
	table enter $excludes $i 0
    }]

    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
	var opts [index $args 0]
	var args [cdr $args]
	foreach i [explode [range $opts 1 end chars]] {
	    [case $i in
		r {var rout 1}
		i {var rout 1 indent 1}
		I {var rout 1 indent 2}
		n {var noIntWhining 1}
		x {
		    var xel [index $args 0]
		    var eqpos [string first {=} $xel]
		    if {$eqpos < 0} {
			var xtime 0
		    } else {
			var xtime [range $xel [expr $eqpos+1] end chars]
			var xel [range $xel 0 [expr $eqpos-1] chars]
		    }
		    table enter $excludes $xel $xtime
		    var args [cdr $args]
		}
		f {
		    var next [frame next [frame top]]
		    var addr [frame register pc $next]
		}
		default {error [format {unknown option %s} $i]}]
	}
    }

    if {[null $addr]} {
	if {![null $args]} {
	    var addr [index $args 0]
	} else {
	    var addr {}
	}
    }

    if {![null $addr]} {
    	var dest [addr-parse $addr]
    } else {
    	var dest {}
    }

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
    # "protect" also handles getting an error during this. It's very
    # frustrating to be stepping for a while, get an error, then get no
    # output for all the instructions you've already executed, so we
    # make sure to produce whatever total we've figured so far, regardless
    # of interrupts or errors.
    #
    protect {
	var cycles_total 0 cycles_ilevel 0 cycles_intoff 0 ints_off 0
	var max_intoff 0
	var cycles_totalList {}
	var cycles_rnameList {}
	for {} {[string c [addr-parse cs:ip] $dest]} {if [break-taken] break} {
	    var inst [unassemble cs:ip 1]
	    # change the address to cs:ip -- fetch-cycles doesn't give a damn
	    # how the address looks, just so's it can use the darn thing.
    	    var cyc [fetch-cycles [concat cs:ip [range $inst 1 end]]]
	    var cycles_total [expr $cycles_total+$cyc]
    	    if {$ints_off && $noIntWhining == 0} {
	    	var cycles_intoff [expr $cycles_intoff+$cyc]
		if {$cycles_intoff > 2000 && $cycles_intoff-$cyc < 2000} {
    	    	    beep
		    beep
		    echo *** NOTICE *** INTERRUPTS HAVE BEEN OFF FOR $cycles_intoff CYCLES
		    echo -n hit return to continue
		    var l [read-line]
		    if {[string match $l {[Nn]}]} {
			break
		    }
    	    	}
    	    }

	    #
	    # If not doing routine totals, display the formatted instruction
	    #
	    if {$rout == 0} {
		echo [format {+%3d: %s} $cyc [format-instruction $inst cs:ip]]
	    }
	    #
	    # If doing only routine totals, do subtotal for routine
	    #
	    var stepped 0
	    if {$rout} {
		[case [index $inst 1] in
		 INT* {
		    #
		    # check for a software interrupt call
		    #
    	    	    var minst [mangle-softint $inst cs:ip]
		    if {[string c [index [index $minst 1] 0] CALL] == 0} {
			if {$indent == 1} {
			    echo -n [format {%*s} $cycles_ilevel {}]
			} elif {$indent == 2} {
			    echo -n [format {(%d) } $cycles_ilevel]
			}
    	    	    	var a [index $minst 1]
    	    	    	echo $a (INT)
			var rname [index $a 1]
			var stepped [doroutine $excludes $rname $indent
				  		$inst 0]
		    }
		 }
		 JMP* {
		    #
		    # If in CallMethod then handle specially
		    #
		    [if {[string compare [index $inst 0] RCI_end] == 0 ||
			 [string match [index $inst 0] ResourceCallInt+*]}
		    {
			#
			# Returning from a software interrupt.
			#
			doret $indent 0
		    } elif {![null [index $inst 3]]} {
			if {$indent == 1} {
			    echo -n [format {%*s} $cycles_ilevel {}]
			} elif {$indent == 2} {
			    echo -n [format {(%d) } $cycles_ilevel]
			}
			var a [addr-parse [makeaddr [index $inst 3]]]
			var seg [handle segment [index $a 0]]
			var s [sym faddr func $seg:[index $a 1]]
			if {![null $s]} {
			    var rname [sym name $s]
			    echo [format {JMP     %s (INDIRECT)} $rname]
			} else {
			    # jumping to la la land. what to do?
			    var rname DUMMY_NAME
			}
			var stepped [doroutine $excludes $rname $indent
						 $inst 1]
		    } else {
    	    	        #
    	    	        # Look for jumping to a place that we must handle
    	    	        # specially
    	    	        #
    	    	        if {[string first PSL_afterDraw [index $inst 1]]
    	    	    	    	    	    	    	    	    != -1} {
    	    	    	    doret $indent 0
    	    	    	}
    	    	    }]

		 }
		 CALL* {
		    #
		    # say which routine we're calling, save the current
		    # subtotal and reset the subtotal for the called routine
		    #
		    if {[string first EnterGraphics [index $inst 1]] != -1} {
    	    	        # skip EnterGraphics
    	    	    	var rname [index $cycles_rnameList 0]
    	    	    	var rname Real_$rname
    	    	    	var cycles_rnameList [concat $rname
    	    	    	    	    	[range $cycles_rnameList 1 end]]
    	    	    } elif {[string first DebugMemory [index $inst 1]] != -1} {
    	    	        # skip DebugMemory
    	    	    } elif {[string first FarDebugMemory [index $inst 1]] != -1} {
    	    	        # skip FarDebugMemory
    	    	    } else {
    	    	        if {[string match [index $inst 0] ResourceCallInt*]} {
			    # No print
			    var rname DUMMY_NAME
    	    	        } else {
			    if {$indent == 1} {
			        echo -n [format {%*s} $cycles_ilevel {}]
			    } elif {$indent == 2} {
			        echo -n [format {(%d) } $cycles_ilevel]
			    }
			    var cmd [index $inst 1]
			    if {![null [index $inst 3]]} {
			        var a [addr-parse [makeaddr [index $inst 3]]]
			        var seg [handle segment [index $a 0]]
				var s [sym faddr func $seg:[index $a 1]]
				if {![null $s]} {
				    var rname [sym name $s]
				    echo [format {CALL    %s (INDIRECT)} $rname]
				} else {
				    # calling unknown routine -- ignore
				    var rname UNKNOWN_ROUTINE
				}
			    } else { 
			        echo $cmd
			        var rpos [expr [string last { } $cmd]+1]
			        var rname [range $cmd $rpos end chars]
			    }
    	    	    	}
		        #
		        # Do common stuff
		        #
		        var stepped [doroutine $excludes $rname $indent
					 $inst 0]
    	    	    }
		 }
		 RET* {
    	    	    # For debugging
    	    	    #echo *** $inst ***
    	    	    doret $indent 1
    	    	 }
    	    	 IRET* {
    	    	    doret $indent 1
    	    	 }
		]
	    }

    	    #
	    # Deal with watching interrupt flag (hex 200 in the condition codes
	    # register...)
	    #
    	    if {[read-reg cc] & 0x200} {
	    	if {$ints_off} {
		    var ints_off 0
		    if {$cycles_intoff > $max_intoff} {
		    	var max_intoff $cycles_intoff
		    }
    	    	}
	    } else {
		if {!$ints_off} {
		    var cycles_intoff 0
		}
		var ints_off 1
	    }

	    #
	    # If we've already executed the instruction, don't execute
	    # another one...
	    #
	    if {$stepped} {
	    	continue
	    }
	    #
	    # Execute the next instruction, being careful of things
	    #
	    [case [index $inst 1] in
	     REP\[NE\]* {#already taken care of}
	     REP* {
		#skip to next instruction...
		var cs [frame register cs [frame top]]
		var ip [frame register ip [frame top]]
		var tbrk [brk tset $cs:$ip+[index $inst 2]]
		stop-catch {
		    continue-patient
		    wait
		}
		#
		# Make sure we're stopped where we want to be. If not, tell
    	    	# why we stopped.
		#
		[if {[frame register cs [frame top]] != $cs ||
		     [frame register ip [frame top]] != $ip+[index $inst 2]}
		 {
		    if [break-taken] {
			echo {*** Breakpoint ***}
		    } elif {![string match $lastHaltCode *Single*]} {
			echo $lastHaltCode
		    }
		    break
		}]
		brk clear $tbrk
		#if wasn't already a breakpoint here, clear the break-taken
    	    	#flag so we don't exit.
		if {![brk isset cs:ip]} {
		    break-taken 0
		}
	     }
	     MOV*\[DE\]S,* {
		#
		# The i86 won't allow interrupts after the loading of a
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
	     }
	     POP*\[DES\]S {
		#
		# Ditto for popping a segment register, but the value is
		# harder to extract. The value being assigned looks like
		# [SP]=<num>, so we take characters from the args list
		# starting at char 5.
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
		# continuation of the machine to execute the following
		# instruction will whale on random pieces of memory. Instead,
		# we print the next instruction as well, to let the user know
		# it was executed.
		#
    	    	var niaddr cs:ip+[index $inst 2]
		var ni [unassemble $niaddr 1]
		var cyc [fetch-cycles $ni]
		var cycles_total [expr $cycles_total+$cyc]
		if {$ints_off} {
		    var cycles_intoff [expr $cycles_intoff+$cyc]
		    if {$cycles_intoff > 2000 && $cycles_intoff-$cyc < 2000} {
    	    	    	beep
			beep
			echo *** NOTICE *** INTERRUPTS HAVE BEEN OFF FOR $cycles_intoff CYCLES
    	    	    	echo -n hit return to continue
			var l [read-line]
			if {[string match $l {[Nn]}]} {
			    break
    	    	    	}
		    }
		}

		if {$rout == 0} {
		    echo [format {+%3d: %s} $cyc [format-instruction $ni $niaddr]]
		}

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
	     XCHG*SP* {
		#
		# Save CS and IP so we can figure out if we stopped in the
		# right place
		#
		var cs [frame register cs [frame top]]
		var ip [frame register ip [frame top]]

		if {$rout == 0} {
		    echo Skipping XchgTopStack...(ignore arguments -- they're wrong)
		}

		#
		# Disassemble the next two instructions so we know where we
		# should set our breakpoint.
		#
		# XCHG SS:0[reg],SP
		var ip [expr $ip+[index $inst 2]]
		var addr [index $inst 0]+[index $inst 2]
		var inst [unassemble $addr 1]
		var cyc [fetch-cycles $inst]
		var cycles_total [expr $cycles_total+$cyc]

		if {$rout == 0} {
		    echo [format {+%3d: %s} $cyc [format-instruction $inst $addr]]
		}

		# XCHG reg,SP
		var addr $addr+[index $inst 2]
		var ip [expr $ip+[index $inst 2]]
		var inst [unassemble $addr 1]
		var cyc [fetch-cycles $inst]
		var cycles_total [expr $cycles_total+$cyc]
		if {$rout == 0} {
		    echo [format {+%3d: %s} $cyc [format-instruction $inst $addr]]
		}
		# point after...
		var addr $addr+[index $inst 2]
		var ip [expr $ip+[index $inst 2]]
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
		    if [break-taken] {
			echo {*** Breakpoint ***}
		    } elif {![string match $lastHaltCode *Single*]} {
			echo $lastHaltCode
		    }
		    break
		}]
    	    	brk clear $tbrk
		#if wasn't already a breakpoint here, clear the break-taken
		#flag so we don't exit.
		if {![brk isset cs:ip]} {
		    break-taken 0
		}
	     }
	     INT* {
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
		#if wasn't already a breakpoint here, clear the break-taken
		#flag so we don't exit.
		if {![brk isset cs:ip]} {
		    break-taken 0
		}
	     }
    	     {CALL*DebugMemory 
	      CALL*DebugProcess
	      CALL*DebugLoadResource} {
    	    	#
		# Going into Swat -- skip over the call.
		#
	     	var tbrk [brk tset cs:ip+3]
		stop-catch {
		    continue-patient 1
		    wait
		}
		brk clear $tbrk
		#if wasn't already a breakpoint here, clear the break-taken
		#flag so we don't exit.
		if {![brk isset cs:ip]} {
		    break-taken 0
		}
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
    } {
    	echo \n$cycles_total cycles total
    	if {$max_intoff} {
	    echo $max_intoff most cycles with interrupts off
    	}

	table destroy $excludes
    	#
	# Make sure any temporary breakpoints we set are gone and our state
	# is set up as if the machine stopped normally
	#
    	event dispatch FULLSTOP _DONT_PRINT_THIS_
    }
}]

[defsubr doroutine {excludes rname indent inst jumpFlag}
{
    global cycles_totalList cycles_rnameList cycles_ilevel cycles_total
    global cycles_jumpFlag

    var xtime [table lookup $excludes $rname]

    if {![null $xtime]} {
	var cycles_total [expr $cycles_total+$xtime]
	if {$indent == 1} {
	    echo -n [format {%*s} $cycles_ilevel {}]
        } elif {$indent == 2} {
            echo -n [format {(%d) } $cycles_ilevel]
        }
	echo $xtime cycles forced for $rname ($cycles_total total)
	var bpt [stepcall $inst n]
	# if only breakpoint at this address was the one stepcall set,
	# don't flag a breakpoint as having been taken
	if {![null $bpt]} {
 	    brk clear $bpt
	}
	if {![brk isset cs:ip]} {
	    break-taken 0
	}
	return 1
    } else {
	var cycles_totalList [concat $cycles_total $cycles_totalList]
	var cycles_rnameList [concat $rname $cycles_rnameList]
	var cycles_ilevel [expr $cycles_ilevel+1]
        var cycles_jumpFlag [concat $jumpFlag $cycles_jumpFlag]
    	return 0
    }
}]

[defsubr doret {indent firstTimeFlag}
{
    global cycles_totalList cycles_rnameList cycles_ilevel cycles_total
    global cycles_jumpFlag
#
# print the subtotal and the total so far
# and restore the total for the calling routine
#
    if {$cycles_ilevel == 0} {
	echo UNKNOWN cycles for UNKNOWN ($cycles_total total)
    } else {
        #
    	# if this is the first call and this routine was jumped to then handle
    	# the jumped to routine first
        #
    	if {[index $cycles_jumpFlag 0] == 1 && $firstTimeFlag == 1 &&
    	    	    	    $cycles_ilevel != 1} {
    	    doret $indent 0
    	}
	var rname [index $cycles_rnameList 0]
	var routineCycles [index $cycles_totalList 0]
	var cycles_ilevel [expr $cycles_ilevel-1]
	if {[string compare $rname DUMMY_NAME]} {
	    if {$indent == 1} {
		echo -n [format {%*s} $cycles_ilevel {}]
            } elif {$indent == 2} {
                echo -n [format {(%d) } $cycles_ilevel]
            }
	    echo [format {%d cycles for %s (%d total)}
			[expr $cycles_total-$routineCycles]
			$rname $cycles_total]
	}
	var cycles_totalList [range $cycles_totalList 1 end]
	var cycles_rnameList [range $cycles_rnameList 1 end]
	var cycles_jumpFlag [range $cycles_jumpFlag 1 end]
    }
}]

[defsubr makeaddr {str} {
    #
    # Check for "="
    #
    var rpos [string first {=} $str]
    if {$rpos != -1} {
	var str [range $str [expr $rpos+1] end chars]
    }
    if {[length $str chars] <= 5} {
	var retval [format {cs:%s} $str]
    } else {
	var retval [format {%sh:%s} [range $str 0 3 chars]
					[range $str 4 8 chars]]
    }
    return $retval
}]

[defsubr tt {str} {
    return [addr-parse [makeaddr $str]]
}]
