##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- Memory Access
# FILE: 	memory.tcl
# AUTHOR: 	Adam de Boor, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	get-address 	    	Fetch actual address to examine
#   	set-address 	    	Set most-recently-examined address
#   	bytes	    	    	Examine memory as bytes
#   	words	    	    	Examine memory as words
#   	dwords	    	    	Examine memory as double words
#   	listi	    	    	Examine memory as instructions
#   	imem	    	    	Examine memory interactively
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Commands for accessing memory
#
#   	These puppies share the variable $lastAddr, which is an
#	address-expression list ({handle offset type}) that is set to nil
#   	when the machine is continued.
#
#	$Id: memory.tcl,v 3.27.6.1 97/03/29 11:27:50 canavese Exp $
#
###############################################################################
defvar lastAddr nil

##############################################################################
#				nuke-lastAddr
##############################################################################
#
# SYNOPSIS:	Event handler to biff the last-accessed address when the
#   	    	machine continues.
# PASS:		[args]	= whatever
# CALLED BY:	CONTINUE event
# RETURN:	EVENT_HANDLED
# SIDE EFFECTS:	${lastAddr} is set to nil
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defsubr nuke-lastAddr {args}
{
    global lastAddr
    var lastAddr nil
    return EVENT_HANDLED
}]
[event handle CONTINUE nuke-lastAddr]


##############################################################################
#				get-address
##############################################################################
#
# SYNOPSIS:	Determine the address a memory-referencing command should use
# PASS:		[addr]	= the optional address argumment passed to the caller
#   	    	[defaultAddr] = the address to use if no address was specified
#				defaults to cs:ip
# CALLED BY:	listi, bytes, words, dwords, etc. etc. etc.
# RETURN:	the address expression to use (*not* an address list)
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defcommand get-address {{addr} {defaultAddr cs:ip}} swat_prog.memory
{Used by the various memory-access commands. Takes one argument, ADDR, being
the address argument for the command. Typically, the command is declared as
    [defcmd cmd {{addr nil}} ... ]
allowing the address to be unspecified. This function will return the given
address if it was, else it will return the last-accessed address (stored in
the global lastAddr variable as a 3-tuple from addr-parse) in the form of
an address expression. If no address is recorded (lastAddr is nil), the
default-addr argument is used.  If it is not specified then cs:ip will
be used.}
{
    if {[null $addr]} {
        global lastAddr
    	if {[null $lastAddr]} {
    	    echo -n Examining memory at $defaultAddr
    	    echo :
    	    var result ($defaultAddr)
    	} elif {![null [index $lastAddr 0]]} {
    	    var result [format {(^h%04xh:%04xh)} [handle id [index $lastAddr 0]]
    	    	    	    [index $lastAddr 1]]
    	} else {
	    var result ([index $lastAddr 1])
    	}
    } else {
    	var result ($addr)
    }
    #
    # Make sure the user knows the handle s/he's referencing is discarded,
    # so s/he doesn't get confused by almost-right code, since we don't do
    # any relocation.
    #
    var p [addr-parse $result]
    if {[null $p]} {
    	error [format {%s: invalid address} $result]
    }
    if {![null [index $p 0]] && ([handle state [index $p 0]] & 0x40)} {
    	echo Warning: Address in discarded handle
    }
    #
    # Also set the extra scope for the patient, allowing mangle-softint to
    # locate any local labels returned by unassemble.
    #
    var s [sym faddr scope $result]
    if {![null $s]} {
    	scope [sym fullname $s]
    }
    return $result
}]

##############################################################################
#				set-address
##############################################################################
#
# SYNOPSIS:	Set the last-referenced address.
# PASS:		addr	= an address-expression for the last-referenced address
#   	    	[tail]	= no longer used
# CALLED BY:	same as call get-address
# RETURN:	nothing
# SIDE EFFECTS:	${lastAddr} is altered
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defcommand set-address {addr {tail {}}} swat_prog.memory
{Set the last-accessed address recorded for memory-access commands. Single
argument is an address expression to be used by the next memory-access
command (except via <return>)}
{
    global lastAddr
    
    var lastAddr [addr-parse $addr]
    #
    # Also set the extra scope for the patient, allowing someone to list
    # a function and then set breakpoints at local labels in that function.
    #
    var s [sym faddr scope $addr]
    if {![null $s]} {
    	scope [sym fullname $s]
    }
}]

##############################################################################
#				listi
##############################################################################
#
# SYNOPSIS:	Disassemble machine instructions from memory
# PASS:		[addr]	= address from which to start listing
#   	    	[num]	= number of instructions to list
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	${lastAddr} is adjusted to the last address used.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defcmd listi {{addr nil} {num 16}} top.memory
{Usage:
    listi [<address>] [<length>]

Examples:
    "l"     	    	    disassemble at the current point of execution
    "listi geos::Dispatch"  disassemble at the kernel's dispatch routine
    "listi DocClip:IsOut"   disassemble at the local label
    "listi cs:ip 20"	    disassemble 20 instructions from the current
    	    	    	    point of execution

Synopsis:
    Disassemble at a memory address.

Notes:
    * The address argument is the address to examine.  If not
      specified, the address after the last examined memory location
      is used.  If no address has been examined then cs:ip is used for
      the address.

    * The length argument is the number of instructions to list.  It
      defaults to 16.

    * Pressing return after this command continues the list.

See also:
    istep, sstep, skip, where.
}
{
    var addr [get-address $addr]

    for {var i $num} {$i > 0} {var i [expr $i-1]} {
	var insn [mangle-softint [unassemble $addr] $addr]
	echo [format-instruction $insn $addr]
	var last $addr
	var addr $addr+[index $insn 2]
    }
    set-address $last
    set-repeat [format {$0 {%s} $2} $addr]
}]

##############################################################################
#				bytes
##############################################################################
#
# SYNOPSIS:	Dump memory as bytes, both hex and ascii
# PASS:		[addr]	= address from which to start dumping
#   	    	[num]	= number of bytes to dump
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	${lastAddr} is set to last address accessed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defcmd bytes {{addr nil} {num 16}} top.memory
{Usage:
    bytes [<address>] [<length>]

Examples:
    "bytes" 	    	lists 16 bytes at ds:si
    "bytes ds:di 32"	lists 32 bytes at ds:di

Synopsis:
    Examine memory as a dump of bytes and characters.

Notes:
    * The address argument is the address to examine.  If not
      specified, the address after the last examined memory location
      is used.  If no address has been examined then ds:si is used for the
      address.

    * The length argument is the number of bytes to examine.  It 
      defaults to 16.

    * Pressing return after this command continues the list.

    * Characters which are not typical ascii values are displayed as a
      period.

See also:
    words, dwords, imem, assign.
}
{
    addr-preprocess [get-address $addr ds:si] seg base
    #fetch the bytes themselves
    var bytes [value fetch $seg:$base [type make array $num [type byte]]]

    fmt-bytes $bytes $base $num 0

    set-address $seg:$base+$num-1
    set-repeat [format {$0 {%s} $2} $seg:$base+$num]
}]

[defsubr fmt-bytes {bytes base num fmtoff}
{
    echo [format {%*sAddr:  +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +a +b +c +d +e +f}
    	    $fmtoff {}]

    #
    # $s is the index of the first byte to display on this row, $e is the
    # index of the last one. $e can get > $num. The loop handles this case.
    #
    var s 0 e [expr 16-($base&0xf)-1]
    #
    # $pre can only be non-zero for the first line, so set it once here.
    # We'll set it to zero when done with the first line.
    # $post can be non-zero only for the last line, but we can't just 
    # set it to zero and let the loop handle it, as the first may be the
    # last, so...
    #
    var pre [expr 16-($e-$s)-1]
    if {$e > $num} {
    	var post [expr $e-($num-1)]
    } else {
    	var post 0
    }
    
    [for {var start [expr {$base&0xfff0}]}
	 {$s < $num}
	 {var start [expr ($start+16)&0xffff]}
    {
    	#extract the bytes we want
    	var bs [range $bytes $s $e]

    	echo [format {%*s%04xh: %*s%s%*s   "%*s%s%*s"}
    	    	$fmtoff {}
    	    	$start
	    	[expr $pre*3] {}
    	    	[map i $bs {format %02x $i}]
		[expr $post*3] {}
    	    	$pre {} 
    	    	[mapconcat i $bs {
    	    	    if {$i >= 32 && $i < 127} {
		    	format %c $i
    	    	    } elif {$i >= 0xa0 && $i < 0xff} {
		    	format %c [expr $i-0x80]
		    } else {
		    	format .
		    }
	    	}]
		$post {}]
	var s [expr $e+1] e [expr $e+16] pre 0
	if {$e >= $num} {
	    var post [expr $e-($num-1)]
	}
    }]
}]

##############################################################################
#				words
##############################################################################
#
# SYNOPSIS:	Dump memory as words, hex only
# PASS:		[addr]	= address from which to start dumping
#   	    	[num]	= number of words to dump
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	${lastAddr} is set to last address accessed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defcmd words {{addr nil} {num 8}} top.memory
{Usage:
    words [<address>] [<length>]

Examples:
    "words" 	    	lists 8 words at ds:si
    "words ds:di 16"	lists 16 words starting at ds:di

Synopsis:
    Examine memory as a dump of words.

Notes:
    * The address argument is the address to examine.  If not
      specified, the address after the last examined memory location
      is used.  If no address has been examined then ds:si is used for
      the address.

    * The length argument is the number of bytes to examine.  It 
      defaults to 8.

    * Pressing return after this command continues the list.

See also:
    bytes, dwords, imem, assign.
}
{
    addr-preprocess [get-address $addr ds:si] seg base

    var end $seg:$base+$num*2
    set-address $end-2
    set-repeat [format {$0 {%s} $2} $end]

    var words [value fetch $seg:$base [type make array $num [type word]]]

    fmt-words $words $base $num 0
}]

[defsubr fmt-words {words base num fmtoff}
{
    echo [format {%*sAddr:  +0   +2   +4   +6   +8   +a   +c   +e} $fmtoff {}]
    
    global dbcs

    [for {var start $base}
	 {$num > 0}
	 {var start [expr $start+16]}
    {
    	var n $num
    	echo -n [format {%*s%04xh: } $fmtoff {} $start]
    	for {var i 0} {$i < 16 && $num > 0} {var i [expr $i+2]} {
    	    echo -n [format {%04x } [index $words [expr ($start+$i-$base)/2]]]
    	    var num [expr $num-1]
    	}
    	if {[null $dbcs]} {
    	    echo
    	} else {
	    # for DBCS, print the things as chars, if they're low-ascii...
            echo -n {   "}
            for {var i 0} {$i < 16 && $n > 0} {var i [expr $i+2]} {
    	    	var nc [index $words [expr ($start+$i-$base)/2]]
    	    	if {$nc >= 32 && $nc <= 127} {
		    echo -n [format {%c} $nc]
	    	} else {
		    echo -n {.}
    	    	}
    	    	var n [expr $n-1]
    	    }
    	    echo {"}
    	}
    }]
}]

##############################################################################
#				dwords
##############################################################################
#
# SYNOPSIS:	Dump memory as 32-bit hex numbers
# PASS:		[addr]	= address from which to start dumping
#   	    	[num]	= number of dwords to dump
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	${lastAddr} is set to last address accessed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	rsf	1/11/91		Initial Revision
#
##############################################################################
[defcmd dwords {{addr nil} {num 4}} top.memory
{Usage:
    dwords [<address>] [<length>]

Examples:
    "dwords"	    	lists 4 double words at ds:si
    "dwords ds:di 8"	lists 8 double words at ds:di

Synopsis:
    Examine memory as a dump of double words (32 bit hex numbers).

Notes:
    * The address argument is the address to examine.  If not
      specified, the address after the last examined memory location
      is used.  If no address has been examined then ds:si is used for
      the address.

    * The length argument is the number of bytes to examine.  It 
      defaults to 4.

    * Pressing return after this command continues the list.

See also:
    bytes, words, imem, assign.
}
{
    addr-preprocess [get-address $addr ds:si] seg base

    var end $seg:$base+$num*4
    set-address $end-4
    set-repeat [format {$0 {%s} $2} $end]

    echo {Addr:  +0       +4       +8       +c}
    var dwords [value fetch $seg:$base [type make array $num [type dword]]]
    [for {var start $base}
	 {$num > 0}
	 {var start [expr $start+16]}
    {
    	echo -n [format {%04xh: } $start]
    	for {var i 0} {$i < 16 && $num > 0} {var i [expr $i+4]} {
    	    echo -n [format {%08x } [index $dwords [expr ($start+$i-$base)/4]]]
    	    var num [expr $num-1]
    	}
    	echo
    }]
}]

##############################################################################
#				imem-find-prev
##############################################################################
#
# SYNOPSIS:	Figure the address of the previous instruction.
# PASS:		handle	= handle in which memory is being examined
#   	    	addr	= offset within that handle
#   	    	[n] 	= number of bytes back at which to start searching
# CALLED BY:	imem
# RETURN:	offset of the previous instruction
# SIDE EFFECTS:	imemAddrStack is popped one if it's non-empty.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defsubr imem-find-prev {handle addr {n 10}}
{
    global imemAddrStack

    if {[length $imemAddrStack] > 0} {
	#
	# Something still on the address stack -- use that since
	# we know it's right.
	#
	var addr [index $imemAddrStack 0]
	var imemAddrStack [range $imemAddrStack 1 end]
	return $addr
    } else {
	#
	# Apply a simple heuristic to try and find the previous
	# instruction:
	#   start $n bytes back (the maximum length of a 286 inst)
	#   advance a byte at a time until you find an instruction
	#   	that uses all the bytes to the instruction
	#		we're on at the moment.
	#
	for {var i $n} {$i > 0} {var i [expr $i-1]} {
	    var inst [mangle-softint [unassemble $handle$addr-$i] $handle$addr-$i]
	    if {[index $inst 2] == $i} {
		break
	    }
	}
	return [expr $addr-$i]
    }
}]

[defvar imemPageLen 10 swat_variable.memory
{Contains the number of elements to display when imem is given the ^D or ^U
command}]

[defsubr imem-display-element {handle base dispmode}
{
    [case $dispmode in
     b* {
	var b [value fetch $handle$base [type byte]]
	[case $b in
	 9	{var cval '\\t'}
	 10 {var cval '\\n'}
	 13 {var cval '\\r'}
	 default {
	    if {$b >= 32 && $b < 127} {
		var cval [format {'%c'} $b]
	    } else {
		var cval [format {'\\%03o'} $b]
	    }
	 }]
	var val [format {%-12s%-10s%-20s} [format {%02xh} $b]
		    [if {$b < 128} {format +$b} {expr $b-256}]
		    $cval]
	var incr 1
     }
     w* {
	var w [value fetch $handle$base [type word]]
	var val [format {%-12s%-10d%-20s} [format {%04xh} $w] $w
			[if {$w < 32768} {format +$w} {expr $w-65536}]]
	var incr 2
     }
     d* {
	var d [value fetch $handle$base [type dword]]
	var seg [expr ($d>>16)&0xffff] off [expr $d&0xffff]
	var s [symbol faddr any $seg:$off]
	if {[null $s]} {
	    var val [format {%04xh:%04xh %-12d %20s} $seg $off $d {}]
	} else {
	    var val [format {%04xh:%04xh %-12d %-20.20s} $seg $off $d
			    [symbol name $s]]
	}
	var incr 4
     }
     i* {
	var i [mangle-softint [unassemble $handle$base] $handle$base]
	var val {}
	for {var j [index $i 2]} {$j > 0} {var j [expr $j-1]} { 
	    var val [concat
		     [format {%02x} [value fetch $handle$base+$j-1
					 [type byte]]]
		     $val]
	}
	var val [format {%-22s%-20s} $val [index $i 1]]
	var incr [index $i 2]
     }]
    #
    # Print the contents of the current address now
    #
    echo -n [format {%04xh: %s} $base $val]

    return $incr
}]

[defcmd imem {{addr nil} {dispmode default}} top.memory
{Usage:
    imem [<address>] [<mode>]

Examples:
    "imem"  	    enter imem mode at the address after the last one
                        examined, or at ds:si if none has been examined
    "imem ds:di"    enter imem mode at ds:di

Synopsis:
    Examine memory and modify memory interactively.

Notes:
    * The address argument is the address to examine.  If not
      specified, the address after the last examined memory location
      is used.  If no address has been examined then ds:si is used for
      the address.

    * The mode argument determines how the memory is displayed and
      modified.  The four modes display the memory in various
      appropiate formats. The modes are:

      Mode  Size   1st column	  2nd column	  3rd column
      ============================================================
      b	    byte   hex byte	  signed decimal  ASCII character
      w	    word   hex word	  unsigned dec.   signed decimal
      d	    dword  segment:offset signed decimal  symbol
      i	    ???    hex bytes	  assembler instr.

    * The default mode is swat's best guess of what type of object is
      at the address.

    * Imem lets you conveniently examine memory at different locations
      and assign it different values.  Imem displays the memory at the
      current address according to the mode.  From there you can move
      to another memory address or you can assign the memory a value.

    * You may choose from the the following single-character commands:

    	b, w, d, i  Sets the mode to the given one and redisplays
    	            the data.

    	n, j, <return>  Advances to the next data item.  The memory
    	       	    	address advances by the size of the mode.

        p, k   	    Returns to the preceding data item. The memory
    	    	    address decreases by the size of the mode.  When
    	    	    displaying instructions, a heuristic is applied to
    	    	    locate the preceding instruction. If it chooses
    	    	    the wrong one, use the 'P' command to make it
    	    	    search again.

        <space>	    Clears the data display and allows you to enter a new
    	    	    value appropriate to the current display mode.
    	    	    The "assign" command is used to perform the
    	    	    assignment, so the same rules apply as for it,
    	    	    with the exception of '- and "-quoted strings. A
    	    	    string with 's around it ('hi mom') has its 
    	    	    characters poked into memory starting at the current
    	    	    address. A string with "s around it ("swat.exe") likewise
    	    	    has its characters poked into memory, with the addition
    	    	    of a null byte at the end.

    	    	    THIS COMMAND IS NOT VALID IN 'i' MODE. 

    	  q	    quit imem and return to command level. The last
    	    	    address accessed is recorded for use by the other
    	    	    memory-access commands. 

    	  ^D	    Display a "page" of successive memory elements in the
    	    	    current mode.

    	  ^U  	    Display a "page" of preceeding memory elements in the
    	    	    current mode.

    	   h, ?  	    This help list.

    	For ^D and ^U, the size of a "page" is kept in the global
    	variable imemPageLen, which defaults to 10.

See also:
    bytes, words, dwords, assign.
}
{
    global imemAddrStack imemPageLen

    var imemAddrStack {}

    var addr [get-address $addr] nowin [null [info commands wmove]]
    var al [addr-preprocess $addr handle base]
    var handle ${handle}:
    var	gotnull {}
    
    #address has associated type -- begin display in format appropriate to it
    if {[string c $dispmode default] == 0} {
	var type [index $al 2]
	if {![null $type]} {
	    [case [type class $type] in
	     array {
		var type [index [type aget $type] 0]
	     }
	    ]
	    [case [type size $type] in
		1	{var dispmode byte}
		{2 default} {var dispmode word}
		4	{var dispmode dword}]
	} else {
	    var dispmode word
	}
    }
   
    for {} {1} {} {
    	#
	# Format the data at the current address according to the
	# current dispmode.
	#
    	if {[null $gotnull]} {
    	    var incr [imem-display-element $handle $base $dispmode]
    	}
    	var gotnull {}
	#
	# Fetch the command to execute next
	#
    	var cmd [read-char 0]
    	if {[string c $cmd \200] == 0} {
    	    var gotnull TRUE
    	}

	#
	# Perform the command
	#
    	[case $cmd in
    	 {h \?} {
    	    echo
    	    help imem
    	 }
	 {i d w b} {
	    var dispmode $cmd imemAddrStack {}
    	    if {!$nowin} {
	    	wmove 0 +0
    	    	echo -n [format {%*s} [expr [columns]-1] {}]
		wmove 0 +0
    	    }
	 }
    	 q {
    	    echo
	    break
	 }
	 {j n \n} {
    	    var imemAddrStack [concat $base $imemAddrStack]
	    var base [expr $base+$incr]
	    echo
    	 }
	 {k p} {
	    if {[string match $dispmode {[bwd]*}]} {
	    	var base [expr $base-$incr]
	    } else {
	    	var base [imem-find-prev $handle $base]
	    }
	    echo
    	 }
	 P {
    	    if {[string match $dispmode i*]} {
	    	var ilen [index $i 2] imemAddrStack {}
		var base [imem-find-prev $handle $base+$ilen [expr $ilen-1]]
		echo
	    } else {
	    	echo What are you trying to do, confuse me?
	    }
	 }
    	 \004 {
	    echo
	    var imemAddrStack [concat $base $imemAddrStack]
	    var base [expr $base+$incr]
	    for {var i $imemPageLen} {$i > 1} {var i [expr $i-1]} {
		var incr [imem-display-element $handle $base $dispmode]
    	    	echo
		var imemAddrStack [concat $base $imemAddrStack]
		var base [expr $base+$incr]
	    }
     	 }	    	
    	 \025 {
	    echo
    	    if {[string match $dispmode {[bwd]*}]} {
		var base [expr $base-$incr]
    	    	for {var i $imemPageLen} {$i > 1} {var i [expr $i-1]} {
		    var incr [imem-display-element $handle $base $dispmode]
    	    	    echo
		    var base [expr $base-$incr]
		}
	    } else {
		var base [imem-find-prev $handle $base]
    	    	for {var i $imemPageLen} {$i > 1} {var i [expr $i-1]} {
		    var incr [imem-display-element $handle $base $dispmode]
	    	    echo
		    var base [imem-find-prev $handle $base]
		}
	    }
    	 }
    	 {{ }} {
    	    if {[string match $dispmode {[bwd]*}]} {
    	    	if {!$nowin} {
		    # Clear out the line
		    wmove 6 +0
		    echo -n [format {%*s} [expr [columns]-7] {}]
		    # Go back to its start
		    wmove 6 +0
		    # Read in the value to assign
		    var l [top-level-read {} {} 0]
		    # Counteract effect of newline
		    wmove +0 -1
    	    	} else {
		    var l [top-level-read {? } {} 0]
    	    	}

    	    	if {[string match $l '*]} {
    	    	    # Unterminated string
    	    	    #extract out the string
    	    	    scan $l {'%[^']} l
    	    	    #assign each character to its proper location
		    var len [length $l chars]
		    [for {[var len 0] [var j 0]}
			{$len < [length $l chars]}
			{var len [expr $len+1]}
		    {
		    	scan [index $l $len chars] %c c
		    	assign [format {byte %s%s} $handle $base+$j] $c
			var j [expr $j+1]
		    }]
    	    	} elif {[string match $l "*]} {
    	    	    # Null-terminated string
    	    	    #extract out the string
    	    	    scan $l {"%[^"]} l
		    var len [length $l chars]
    	    	    #assign each character to its proper location
		    [for {[var len 0] [var j 0]}
			{$len < [length $l chars]}
			{var len [expr $len+1]}
		    {
		    	scan [index $l $len chars] %c c
		    	assign [format {byte %s%s} $handle $base+$j] $c
			var j [expr $j+1]
		    }]
    	    	    #null-terminate
		    assign [format {byte %s%s} $handle $base+$j] 0
    	    	} else {
    	    	    # Take value as typed and form assign command with it
		    assign [format {%s %s%s}
			    [case $dispmode in
			     b* {format byte}
			     w* {format word}
			     d* {format dword}]
			    $handle
			    $base] $l
    	    	}
    	    } else {
    	    	echo
	    	echo Assembling instructions is not possible in swat.
    	    }
    	 }
    	 \200 {
    	    # special null character, do nothing
    	 }
	 default {
	    echo \nExcuse me?
	 }
    	]
    }
    set-address $handle$base
}]



