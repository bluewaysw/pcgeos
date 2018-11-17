##############################################################################
#
# 	Copyright (c) Geoworks 1997.  All rights reserved.
#
# PROJECT:	Swat
# MODULE:	hardware breakpoints
# FILE: 	hwbrk.tcl
# AUTHOR: 	Eric Weber, May 19, 1997
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#       hwbrk			manage hardware breakpoints
#	hwbrk-list		list hardware breakpoints
#	hwbrk-set		set a hardware breakpoint
#	hwbrk-enable		enable a hardware breakpoint
#	hwbrk-disable		disable a hardware breakpoint
#	hwbrk-delete		delete a hardware breakpoint
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	weber   	5/19/97   	Initial Revision
#
# DESCRIPTION:
#	Code to manage Intel debug registers
#	
#	$Id: hwbrk.tcl,v 1.4 98/01/26 15:36:23 allen Exp $
#	
#############################################################################

defvar dr7type [type make struct
             L0   [type word]  0 1
             G0   [type word]  1 1
             L1   [type word]  2 1
             G1   [type word]  3 1
             L2   [type word]  4 1
             G2   [type word]  5 1
             L3   [type word]  6 1
             G3   [type word]  7 1
             LE   [type word]  8 1
             GE   [type word]  9 1
             GD   [type word] 13 1
             RW0  [type word] 16 2
             LEN0 [type word] 18 2
             RW1  [type word] 20 2
             LEN1 [type word] 22 2
             RW2  [type word] 24 2
             LEN2 [type word] 26 2
             RW3  [type word] 28 2
             LEN3 [type word] 30 2]

defvar dr6type [type make struct
             B0   [type word]  0 1
             B1   [type word]  1 1
             B2   [type word]  2 1
             B3   [type word]  3 1
             BD   [type word] 13 1
             BS   [type word] 14 1
             BT   [type word] 15 1
             {}   [type word] 31 1]


# this is the format of arguments to the RPC calls
defvar debugregstype [type make pstruct
		      DR7 [type dword]
		      DR6 [type dword]
		      DR3 [type dword]
		      DR2 [type dword]
		      DR1 [type dword]
		      DR0 [type dword]]

		      
##############################################################################
#	get-debug-regs
##############################################################################
#
# SYNOPSIS:	Reads the Intel debug regs from the target
# PASS:		nothing
# CALLED BY:	
# RETURN:	struct of register values
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       weber    	5/19/97   	Initial Revision
#	
##############################################################################
[defsubr    get-debug-regs {} {
    global debugregstype

    var reglist [rpc call RPC_READ_DEBUG_REGS [type void] {} $debugregstype]
    # var reglist [rpc call 135 [type void] {} $debugregstype]
    
    return $reglist
}]

##############################################################################
#	set-debug-regs
##############################################################################
#
# SYNOPSIS:	Sets the Intel debug regs on the target
# PASS:		struct of register values
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       weber    	5/19/97   	Initial Revision
#	
##############################################################################
[defsubr    set-debug-regs {reglist} {
    global debugregstype

    [rpc call RPC_WRITE_DEBUG_REGS $debugregstype $reglist [type void]]
    # [rpc call 136 $debugregstype $reglist [type void]]

}]

##############################################################################
#	get-debug-reg
##############################################################################
#
# SYNOPSIS:	Get a debug register's value
# PASS:		name - name of register to read
# CALLED BY:	
# RETURN:	32-bit value of register
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       weber    	5/20/97   	Initial Revision
#	
##############################################################################
[defsubr get-debug-reg {name} {
    return [field [get-debug-regs] $name]
}]

##############################################################################
#	set-debug-reg
##############################################################################
#
# SYNOPSIS:	Set a debug register
# PASS:		name - name of register to write
#               val  - new 32-bit value for register
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       weber    	5/20/97   	Initial Revision
#	
##############################################################################
[defsubr set-debug-reg {name val} {
    var regs [get-debug-regs]
    var regs [map r $regs {
	if {[string c [index $r 0] $name 1] == 0} {
	    [list [index $r 0] [index $r 1] $val]
	} else {
	    var r
	}
    }]
    set-debug-regs $regs
}]
 

##############################################################################
#	print-debug-regs
##############################################################################
#
# SYNOPSIS:	Print out the hardare debug regs in a friendly way
# PASS:		nothing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY:
#    The state of a breakpoint is encoded as follows:
#       1st letter: e = enabled, d = disabled
#       2nd letter: i = instruction, w = write, r = read/write
#       3rd letter: b = byte, w = word, d = dword, space for instruction bpts
#
#     The displayed address is either a segment/offset (e.g. 0123h:4567h),
#     or a 32 bit linear address (e.g. 01234567h).  The latter is the actual
#     contents of the register, and is displayed if swat is unable to parse
#     the actual address.
#
#  Example:  "di"  - a disabled instruction breakpoint
#            "eww" - an enabled data breakpoint on writes to a word
#            "drd" - a disable data breakoint on reads or writes to a dword
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       weber    	5/19/97   	Initial Revision
#	
##############################################################################
[defcmd    hwbrk-list {} top.breakpoint 
{Usage:
    hwbrk-list

Synopsis:
    Displays a summary of the Intel 386 debug registers.

Output:
    per-breakpoint output
	num: breakpoint number (0..3)
	state
	    1st letter: "d" disabled, "e" enabled
	    2nd letter: "i" instruction, "w" data write, "r" data read/write
	    3rd letter: " " instruction, "b" byte, "w" word, "d" dword
	address
            0000h:0000h  segment and offset of the breakpoint
            00000000h    linear address, if unable to determine the segment

    status line: reason(s) why the machine stopped
	BT - T bit set in a task descriptor
	BS - TF bit set in flags (single-step)
	BD - write-protect violation on debug registers
	B3 - breakpoint 3 taken
	B2 - breakpoint 2 taken
	B1 - breakpoint 1 taken
	B0 - breakpoint 0 taken

Notes:
    * BT and BD are unlikely to appear, as nothing in GEOS will trigger them
    * linear address = segment*16 + offset
    * all instruction breakpoints have a size of byte, so that information
      is not printed

See also:
    hwbrk, hwbrk-set, hwbrk-enable, hwbrk-disable, hwbrk-delete
} {
    global dr7type 
    global dr6type

    require cvtrecord print

    var regdata [get-debug-regs]
    var dr7data [cvtrecord $dr7type [index [assoc $regdata DR7] 2]]
    var dr6data [cvtrecord $dr6type [index [assoc $regdata DR6] 2]]

    echo
    echo {num state address}
    echo {--- ----- -------}

    print-breakpoint-state 0 $dr7data
    print-linear-address [field $regdata DR0] 16
    print-breakpoint-state 1 $dr7data
    print-linear-address [field $regdata DR1] 16
    print-breakpoint-state 2 $dr7data
    print-linear-address [field $regdata DR2] 16
    print-breakpoint-state 3 $dr7data
    print-linear-address [field $regdata DR3] 16

    echo
    echo -n {status: }
    fmtrecord $dr6type $dr6data 0
    echo
    echo

}]

[defsubr    print-breakpoint-state {n dr7data} {
    var blen  [field $dr7data [format %s%d LEN $n]]
    var btype [field $dr7data [format %s%d RW  $n]]
    var ble   [field $dr7data [format %s%d L   $n]]
    var gle   [field $dr7data [format %s%d G   $n]]

    echo -n [format { %d   } $n]

    if {$ble||$gle} {
	echo -n e
    } else {
	echo -n d
    }

    [case $btype in 
     0 {echo -n i}
     1 {echo -n w}
     2 {echo -n ?}
     3 {echo -n r}
    ]

    if [string m $btype 0] {
	if [string m $blen 0] {
	    echo -n { }
	} else {
	    echo -n {?}
	}
    } else {
	[case $blen in
	 0 {echo -n b}
	 1 {echo -n w}
	 2 {echo -n ?}
	 3 {echo -n d}
	]
    }

    echo -n {  }
}]

[defsubr    dump-debug-regs {} {
    global dr7type 
    global dr6type

    require cvtrecord print

    var regdata [get-debug-regs]

    var i [field $regdata DR7]
    echo [format {DR7: %08x} $i]
    echo -n {  }
    fmtval [cvtrecord $dr7type $i] $dr7type 2 {} 1
    echo

    var i [field $regdata DR6]
    echo -n [format {DR6: %08x  } $i]
    fmtrecord $dr6type [cvtrecord $dr6type $i] 4
    echo

    var i [field $regdata DR3]
    echo -n [format {DR3: %08x } $i]
    print-linear-address $i 16 (unknown)

    var i [field $regdata DR2]
    echo -n [format {DR2: %08x } $i]
    print-linear-address $i 16 (unknown)

    var i [field $regdata DR1]
    echo -n [format {DR1: %08x } $i]
    print-linear-address $i 16 (unknown)

    var i [field $regdata DR0]
    echo -n [format {DR0: %08x } $i]
    print-linear-address $i 16 (unknown)
}]

[defsubr print-linear-address {l indent {warn nil}} {
    if {[null [parse-linear-address $l s o]]} {
	if {[null $warn]} {
	    echo [format %08xh $l]
	} else {
	    echo $warn
	}
    } else {
        fmtval [format {%04x%04xh} $s $o] [type make fptr [type void]] $indent
    }
}]
 
[defsubr parse-linear-address {addr seg off} {
    var h [handle find 0:$addr]
    if {[null $h]} {
	return nil
    } else {
	uplevel 1 var $seg [handle segment $h]
	uplevel 1 var $off [expr {$addr-16*[handle segment $h]}]
	return t
    }
}]

##############################################################################
#	hwbrk-set
##############################################################################
#
# SYNOPSIS:	Set a hardware  breakpoint
# PASS:		address of instruction or data, type of breakpoint to set
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       weber    	5/20/97   	Initial Revision
#	
##############################################################################
[defcmd    hwbrk-set {addr {rawtype i} {rawsize w}} top.breakpoint 
{Usage:
    hwbrk-set <address> [<type> [<size>]]

    type is "i" (instruction), "w" (data write), or "rw" (data read/write)
    size is "b" (byte), "w" (word), or "d" (dword)

Examples:
    "hwbrk-set myvar rw b"			break on read/write of byte
    "hwbrk-set mybigvar"			break on write of word
    "hwbrk-set mybiggervar w d"		break on write of dword
    "hwbrk-set MyProc i"			break on execution

Synopsis:
    Sets the Intel 386 debug registers so that the machine will stop if
    the instruction is executed or the data accessed.

Notes:
    * these commands do not work if GEOS is running under NT
    * Intel breakpoints can only be set in fixed data or code
    * there are no commands or conditions associated with Intel breakpoints
    * for data breakpoints, the machine will stop if any part of the
      data is accessed in the specified manner (read or read/write)
    * for instruction breakpoints, the size is ignored and the machine
      will stop when that instruction is executed
    * if more than one of a hardware instruction breakpoint, a hardware
      data breakpoint, and a conventional breakpoint occur on the same
      instruction, which and how many of them actually get taken is
      undefinedm, but at least one of them will be

See also:
    hwbrk, hwbrk-list, hwbrk-enable, hwbrk-disable, hwbrk-delete
} {
    global dr7type 
    require cvtrecord print

    #
    # validate the syntax
    #
    [case $rawtype in
     i  {var btype 0}
     w  {var btype 1}
     rw {var btype 3}
     *  {error {Usage: set-data-break <address> [i|w|rw [b|w|d]]}}
    ]
    
    if {$btype == 0} {
	var bsize 0
    } else {
	[case $rawsize in 
	 b {var bsize 0}
	 w {var bsize 1}
	 d {var bsize 3}
	 * {error {Usage: set-data-break <address> [i|w|rw [b|w|d]]}}
	]
    }

    #
    # look up the address
    # if it's invalid, the system will throw an error
    #
    var a [addr-parse $addr]

    #
    # now convert the address to linear form
    #
    if {[null [index $a 0]]} {
	# it's already in linear form
	var l [index $a 1]
    } else {
	# we have a handle - is it fixed?
	var h [index $a 0]
	if {[handle state $h] & 0x00008} {
	    # it sure is
	    var l [expr [list [handle segment $h] * 16 + [index $a 1]]]
	} else {
	    # don't panic yet - perhaps it's pseudo-fixed
	    var id [handle id $h]
	    var v [value fetch kdata:$id.HM_lockCount]
	    if {!($v == -1)} {
		echo {WARNING: Breakpoint is set at non-fixed memory.}
	    }
	    var l [expr [list [handle segment $h] * 16 + [index $a 1]]]
	}
    }
	       
    #
    # check for available breakpoints
    #
    var dr7val [get-debug-reg DR7]
    var dr7 [cvtrecord $dr7type $dr7val]

    if {!([field $dr7 L0] || [field $dr7 G0])} {
	var n 0
    } elif {!([field $dr7 L1] || [field $dr7 G1])} {
	var n 1
    } elif {!([field $dr7 L2] || [field $dr7 G2])} {
	var n 2
    } elif {!([field $dr7 L3] || [field $dr7 G3])} {
	var n 3
    } else {
	error {No available breakpoints.}
    }

    # compute the new integer value of DR7
    foreach f [type fields $dr7type] {
	[case [index $f 0] in
	 GE {
	     var dr7val [setbits $dr7val [index $f 1] [index $f 2] 1]
	 }
	 [format %s%d G $n] {
	     var dr7val [setbits $dr7val [index $f 1] [index $f 2] 1]
	 }
	 [format %s%d RW $n] {
	     var dr7val [setbits $dr7val [index $f 1] [index $f 2] $btype]
	 }
	 [format %s%d LEN $n] {
	     var dr7val [setbits $dr7val [index $f 1] [index $f 2] $bsize]
	 }
	]
    }

    # write the registers back to the machine
    set-debug-reg DR7 $dr7val
    set-debug-reg [format %s%d DR $n] $l

    # tell the user what we did
    echo [format {set breakpoint %d at %08x} $n $l]
}]

  
[defsubr setbits {val off sz data} {
    var negmask [expr ~(((1<<$sz)-1)<<$off)]
    var posmask [expr $data<<$off]
    return [expr ($val&$negmask)|$posmask]
}]

[defcmd hwbrk-disable {n} top.breakpoint 
{Usage:
    hwbrk-disable <n>

Examples:
    "hwbrk-disable 1"		Disable breakpoint number 1

Synopsis:
    Disable a previously set breakpoint

See also:
    hwbrk, hwbrk-list, hwbrk-set, hwbrk-enable, hwbrk-delete
} {
    # validate bpt num
    [case $n in
     {[0-3]} {var x}
     *      {error {Usage: hwbrk-disable <0..3> [clear]}}
    ]

    hwbrk-disable-low $n 0
}]

[defcmd hwbrk-delete {n {clear {}}} top.breakpoint 
{Usage:
    hwbrk-delete <n>

Examples:
    "hwbrk-delete 1"		Clear breakpoint number 1

Synopsis:
    Disable a breakpoint and clear the address register

See also:
    hwbrk, hwbrk-list, hwbrk-set, hwbrk-enable, hwbrk-disable
} {
    # validate bpt num
    [case $n in
     {[0-3]} {var x}
     *      {error {Usage: hwbrk-delete <0..3> [clear]}}
    ]

    hwbrk-disable-low $n 1
}]


[defsubr hwbrk-disable-low {n clear} {
    global dr7type
    var dr7val [get-debug-reg DR7]

    # compute the new integer value of DR7
    foreach f [type fields $dr7type] {
	[case [index $f 0] in
	 [format %s%d G $n] {
	     var dr7val [setbits $dr7val [index $f 1] [index $f 2] 0]
	 }
	 [format %s%d L $n] {
	     var dr7val [setbits $dr7val [index $f 1] [index $f 2] 0]
	 }
	 [format %s%d RW $n] {
	     if {$clear} {
		 var dr7val [setbits $dr7val [index $f 1] [index $f 2] 0]
	     }
	 }
	 [format %s%d LEN $n] {
	     if {$clear} {
		 var dr7val [setbits $dr7val [index $f 1] [index $f 2] 0]
	     }
	 }
	]
    }

    set-debug-reg DR7 $dr7val
    if {$clear} {
	set-debug-reg [format %s%d DR $n] 0
	echo [format {cleared breakpoint %d} $n]
    } else {
	echo [format {disabled breakpoint %d} $n]
    }
}]

[defcmd hwbrk-enable {n} top.breakpoint 
{Usage:
    hwbrk-enable <n>

Examples:
    "hwbrk-enable 1"		Enable breakpoint number one

Synopsis:
    Enable a previously set breakpoint

See also:
    hwbrk, hwbrk-list, hwbrk-set, hwbrk-disable, hwbrk-delete
} {
    global dr7type

    var dr7val [get-debug-reg DR7]

    # compute the new integer value of DR7
    foreach f [type fields $dr7type] {
	[case [index $f 0] in
	 [format %s%d G $n] {
	     var dr7val [setbits $dr7val [index $f 1] [index $f 2] 1]
	 }
	]
    }

    set-debug-reg DR7 $dr7val
    echo [format {enabled breakpoint %d} $n]
}]

[defcmd hwbrk {subcmd args} top.breakpoint 
{Usage:
    hwbrk list
    hwbrk set <addr> [i|w|rw [b|w|d]]
    hwbrk enable <n>
    hwbrk disable <n>
    hwbrk delete  <n>

Synopsis:
    Command to manage Intel 386 hardware breakpoints

See also:
    hwbrk-list, hwbrk-set, hwbrk-enable, hwbrk-disable, hwbrk-delete
} {
    [case $subcmd in
     {l}       {var func hwbrk-list}
     {li}      {var func hwbrk-list}
     {lis}     {var func hwbrk-list}
     {list}    {var func hwbrk-list}
     {s}       {var func hwbrk-set}
     {se}      {var func hwbrk-set}
     {set}     {var func hwbrk-set}
     {e}       {var func hwbrk-enable}
     {en}      {var func hwbrk-enable}
     {ena}     {var func hwbrk-enable}
     {enab}    {var func hwbrk-enable}
     {enabl}   {var func hwbrk-enable}
     {enable}  {var func hwbrk-enable}
     {d}       {var func hwbrk-disable}
     {di}      {var func hwbrk-disable}
     {dis}     {var func hwbrk-disable}
     {disa}    {var func hwbrk-disable}
     {disab}   {var func hwbrk-disable}
     {disabl}  {var func hwbrk-disable}
     {disable} {var func hwbrk-disable}
     {de}      {var func hwbrk-delete}
     {del}     {var func hwbrk-delete}
     {dele}    {var func hwbrk-delete}
     {delet}   {var func hwbrk-delete}
     {delete}  {var func hwbrk-delete}
     *         {
	 var func hwbrk-set
	 var args [concat $subcmd $args]
     }
    ]
    eval [concat $func $args]
}]
