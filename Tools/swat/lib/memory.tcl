##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#	$Id: memory.tcl,v 3.5 91/01/15 17:54:15 roger Exp $
#
###############################################################################
defvar lastAddr nil

[defsubr nuke-lastAddr {args}
{
    global lastAddr
    var lastAddr nil
    return EVENT_HANDLED
}]
[event handle CONTINUE nuke-lastAddr]


[defdsubr get-address {{addr} {defaultAddr cs:ip}} prog.memory
{Used by the various memory-access commands. Takes one argument, ADDR, being
the address argument for the command. Typically, the command is declared as
    [defcommand cmd {{addr nil}} ... ]
allowing the address to be unspecified. This function will return the given
address if it was, else it will return the last-accessed address (stored in
the global lastAddr variable as a 3-tuple from addr-parse) in the form of
an address expression. If no address is recorded (lastAddr is nil), the
default-addr argument is used.  If it is not specified then cs:ip will
be used.}
{
    global lastAddr
    if {[null $addr]} {
    	if {[null $lastAddr]} {
    	    echo -n Examining memory at $defaultAddr
    	    echo :
    	    var result ($defaultAddr)
    	} elif {![null [index $lastAddr 0]]} {
    	    var result [format {(^h%d:%d)} [handle id [index $lastAddr 0]]
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

[defdsubr set-address {addr {tail {}}} prog.memory
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

[defcommand listi {{addr nil} {num 16}} memory
{listi [address] [length]
"listi cs:ip 20"

Examine memory as a list of assembler instructions.

* The address argument is the address to examine.  If not specified,
the address after the last examined memory location is used.  If no
address has be examined then cs:ip is used for the address.

* The length argument is the number of instructions to list.  It is
optional and defaults to 16.

Pressing return after this command continues the list.}
{
    var addr [get-address $addr]

    for {var i $num} {$i > 0} {var i [expr $i-1]} {
	var inst [mangle-softint [unassemble $addr]]
	echo [format-instruction $inst]
	var last $addr addr $addr+[index $inst 2]
    }
    set-address $last
    set-repeat [format {$0 {%s} $2} $addr]
}]

[defcommand bytes {{addr nil} {num 16}} memory
{bytes [address] [length]
"bytes ds:si 32"

Examine memory as a dump of bytes and characters.

* The address argument is the address to examine.  If not specified, the
address after the last examined memory location is used.  If no
address has be examined then ds:di is used for the address.

* The length argument is the number of bytes to examine.  It is optional
and defaults to 16.

Pressing return after this command continues the list.  Characters
which are not typical ascii values are displayed as a period.

See also words, dwords, imem.}
{
    var addr [get-address $addr ds:di]

    var base [index [addr-parse $addr] 1]

    echo {Addr: +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +a +b +c +d +e +f}
    #fetch the bytes themselves
    var bytes [value fetch $addr [type make array $num [type byte]]]

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
    
    [for {var start [expr {$base&~0xf}]}
	 {$s < $num}
	 {var start [expr $start+16]}
    {
    	#extract the bytes we want
    	var bs [range $bytes $s $e]

    	echo [format {%04x: %*s%s%*s   "%*s%s%*s"} $start
	    	[expr $pre*3] {}
    	    	[map i $bs {format %02x $i}]
		[expr $post*3] {}
    	    	$pre {} 
    	    	[mapconcat i $bs {
    	    	    if {$i >= 32 && $i < 127} {
		    	format %c $i
		    } else {
		    	format .
		    }
	    	}]
		$post {}]
	var s [expr $e+1] e [expr $e+16] pre 0
	if {$e > $num} {
	    var post [expr $e-($num-1)]
	}
    }]
    set-address $addr+$num-1
    set-repeat [format {$0 {%s} $2} $addr+$num]
}]

[defcommand words {{addr nil} {num 8}} memory
{words [address] [length]
"words ds:si 16"

Examine memory as a dump of words.

* The address argument is the address to examine.  If not specified, the
address after the last examined memory location is used.  If no
address has be examined then ds:di is used for the address.

* The length argument is the number of bytes to examine.  It is optional
and defaults to 8.

Pressing return after this command continues the list.

See also bytes, dwords, imem.}
{
    var addr [get-address $addr ds:di]

    var base [index [addr-parse $addr] 1]
    var end $addr+[expr $num*2]
    set-address $end-2
    set-repeat [format {$0 {%s} $2} $end]

    echo {Addr: +0   +2   +4   +6   +8   +a   +c   +e}
    var words [value fetch $addr [type make array $num [type word]]]
    [for {var start $base}
	 {$num > 0}
	 {var start [expr $start+16]}
    {
    	echo -n [format {%04x: } $start]
    	for {var i 0} {$i < 16 && $num > 0} {var i [expr $i+2]} {
    	    echo -n [format {%04x } [index $words [expr ($start+$i-$base)/2]]]
    	    var num [expr $num-1]
    	}
    	echo
    }]
}]

#   rsf	1/11/91
#
[defcommand dwords {{addr nil} {num 4}} memory
{words [address] [length]
"words ds:si 8"

Examine memory as a dump of double words (32 bit hex numbers).

* The address argument is the address to examine.  If not specified, the
address after the last examined memory location is used.  If no
address has be examined then ds:di is used for the address.

* The length argument is the number of bytes to examine.  It is optional
and defaults to 4.

Pressing return after this command continues the list.

See also bytes, words, imem.}
{
    var addr [get-address $addr ds:di]

    var base [index [addr-parse $addr] 1]
    var end $addr+[expr $num*4]
    set-address $end-4
    set-repeat [format {$0 {%s} $2} $end]

    echo {Addr: +0       +4       +8       +c}
    var dwords [value fetch $addr [type make array $num [type dword]]]
    [for {var start $base}
	 {$num > 0}
	 {var start [expr $start+16]}
    {
    	echo -n [format {%04x: } $start]
    	for {var i 0} {$i < 16 && $num > 0} {var i [expr $i+4]} {
    	    echo -n [format {%08x } [index $dwords [expr ($start+$i-$base)/4]]]
    	    var num [expr $num-1]
    	}
    	echo
    }]
}]

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
	    var inst [mangle-softint [unassemble $handle$addr-$i]]
	    if {[index $inst 2] == $i} {
		break
	    }
	}
	return [expr $addr-$i]
    }
}]

[defvar imemPageLen 10 variable.memory
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
	var val [format {%-12.02x%-10s%-20s} $b 
		    [if {$b < 128} {format +$b} {expr $b-256}]
		    $cval]
	var incr 1
     }
     w* {
	var w [value fetch $handle$base [type word]]
	var val [format {%-12.04x%-10d%-20s} $w $w
			[if {$w < 32768} {format +$w} {expr $w-65536}]]
	var incr 2
     }
     d* {
	var d [value fetch $handle$base [type dword]]
	var seg [expr ($d>>16)&0xffff] off [expr $d&0xffff]
	var s [symbol faddr any $seg:$off]
	if {[null $s]} {
	    var val [format {%04x:%04x %-12d %20s} $seg $off $d {}]
	} else {
	    var val [format {%04x:%04x %-12d %-20.20s} $seg $off $d
			    [symbol name $s]]
	}
	var incr 4
     }
     i* {
	var i [mangle-softint [unassemble $handle$base]]
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
    echo -n [format {%04x: %s} $base $val]

    return $incr
}]

[defcommand imem {{addr nil} {dispmode default}} memory
{imem [address] [mode]
"imem ds:si"

Examine memory and modify memory interactively.

* The address argument is the address to examine.  If not specified,
the address after the last examined memory location is used.  If no
address has be examined then ds:di is used for the address.

* The mode argument determines how the memory is displayed and
modified.  Each of the four modes display the memory in 
various appropiate formats. The modes are:

    Mode  Size   1st column	 2nd column	 3rd column
    ============================================================
    b	  byte   hex byte	 signed decimal  ASCII character
    w	  word   hex word	 unsigned dec.   signed decimal
    d	  dword  segment:offset  signed decimal	 symbol
    i	  ???    hex bytes	 assembler instr.

The default mode is swat's best guess of what type of object is at the
address.

Imem lets you conviently examine memory at different locations and
assign it different values.  Imem displays the memory at the current
address according to the mode.  From there you can move to another
memory address or you can assign the memory a value.

You may choose from the the following single-character commands:

    b, w, d, i	    Sets the mode to the given one and redisplays
    	    	    the data.

    n, j, <return>  Advances to the next data item.  The memory
    	    	    address advances by the size of the mode.

    p, k    	    Returns to the preceeding data item. The memory
    	    	    address decreases by the size of the mode.  When
    	    	    displaying instructions, a heuristic is applied to
    	    	    locate the preceeding instruction. If it chooses
    	    	    the wrong one, use the 'P' command to make it
    	    	    search again.

    <space> 	    Clears the data display and allows you to enter a new
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

    q	    	    quit imem and return to command level. The last
    	    	    address accessed is recorded for use by the other
    	    	    memory-access commands. 

    ^D	    	    Display a "page" of successive memory elements in the
    	    	    current mode.

    ^U	    	    Display a "page" of preceeding memory elements in the
    	    	    current mode.

    h	    	    This help list.

For ^D and ^U, the size of a "page" is kept in the global variable
imemPageLen, which defaults to 10.


See also bytes, words, dwords, assign.}
{
    global imemAddrStack imemPageLen

    var imemAddrStack {}

    var addr [get-address $addr ds:di] nowin [null [info commands wmove]]
    var al [addr-parse $addr]
    
    if {![null [index $al 0]]} {
    	#handle-relative: set $handle to be ^h<hid>: for later use
	var handle ^h[handle id [index $al 0]]:
    }
    var base [index $al 1]

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
		2|default {var dispmode word}
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
    	var incr [imem-display-element $handle $base $dispmode]
	#
	# Fetch the command to execute next
	#
    	var cmd [read-char 0]
	#
	# Perform the command
	#
    	[case $cmd in
    	 h {
    	    echo
    	    help imem
    	 }
	 i|d|w|b {
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
	 j|n|\n {
    	    var imemAddrStack [concat $base $imemAddrStack]
	    var base [expr $base+$incr]
	    echo
    	 }
	 k|p {
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
    	 { } {
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
	 default {
	    echo \nExcuse me?
	 }
    	]
    }
    set-address $handle$base
}]



