##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	assign.tcl
# FILE: 	assign.tcl
# AUTHOR: 	Adam de Boor, Dec  3, 1991
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
# DESCRIPTION:
#	Function to assign a new value to a memory location or register
#
#	$Id: assign.tcl,v 1.12.11.1 97/03/29 11:26:45 canavese Exp $
#
###############################################################################

##############################################################################
#				assign
##############################################################################
#
# SYNOPSIS:	 Assign a new value to a simple variable (one that's
# 	 	 a dword or smaller but not a record).
# PASS:		 addr = place to store the value
# 	 	 value = value to assign it (an address expression)
# CALLED BY:	 user
# RETURN:	 nothing
# SIDE EFFECTS:	 ?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
##############################################################################
[defcommand assign {addr value} {top.memory swat_prog.memory}
{Usage:
    assign <addr> <value>

Examples:
    "assign ip ip+2"	 	Add 2 to the value of IP in the current frame.
    "assign {word ds:si} 63h"	Store 63h in the word at ds:si

Synopsis:
    Use this command to alter simple data stored in memory, or the value of
    a register. The data can be no larger than a dword.

Notes:
    * When assigning to an sptr, the value assigned will be the segment of
      the block indicated by the <value>, unless <value> is an absolute
      address (or just a number), in which case the low 16 bits of the
      offset will be used instead.
    
    * Similar behaviour occurs when assigning to an fptr, except if the <value>
      is an absolute address, in which case the linear address in the offset
      portion of the <value> will be decomposed into a segment and an offset.

See also:
    imem, value
}
{
    var a [uplevel 1 addr-parse $addr 0]

    var t [index $a 2]

    if {[null $t] || [string c [index $a 0] value] == 0} {
    	#
	# If the address has no type, see if it could be a register.
	#
	[if {([catch {frame register $addr} regval] == 0) && 
	     ($regval == [index $a 1])}
    	{
    	    #
	    # "frame register" thinks the address is a register and the value
	    # it returned matches the offset of the address, so we're dealing
	    # with a register, sure.
	    #
	    var v [uplevel 1 addr-parse $value 0]
	    [case $addr in
	     {DS ES CS SS ds es cs ss} {
    	    	#
		# Special handling for assigning to a segment register. We do
		# here exactly as for segment pointers, namely if the value is
		# absolute, we assume it was a number and just use the offset.
		# If the value falls in a block, however, we use the segment of
		# the block in which the value falls, if we can find it.
		#
	     	if {[null [index $v 0]] || [string c [index $v 0] value] == 0} {
		    var seg [index $v 1]
    	    	} elif {[handle state [index $v 0]] & 1} {
		    var seg [handle segment [index $v 0]]
    	    	} else {
		    error [format {handle %04xh isn't resident, so its segment cannot be determined}
			    [handle id [index $v 0]]]
    	        }
    	    	frame setreg $addr $seg
    	     }
	     default {
		[if {[null [index $v 2]] || [string c [index $v 0] value]==0 ||
		     [type class [index $v 2]] == function ||
		     [type class [index $v 2]] == void}
	    	{
		    frame setreg $addr [index $v 1]
		} else {
		    frame setreg $addr [value fetch $value]
		}]
    	     }
    	    ]
	    return
        }]
    	#
    	# See if the address is the name of a variable local to the
    	# current function and stored in a register.
    	#
    	if {[catch {symbol get [symbol find locvar $addr [frame funcsym]]} r]
    	    	== 0} {
    	    if {[string c [index $r 1] reg] == 0} {
	    	var v [uplevel 1 addr-parse $value 0]
    	    	frame setreg [reg-name [index $r 0]] [index $v 1]
    	    	return
    	    }
    	}
    	#
	# Not a register, so assume type is word.
	#
	var t [type word]
    }

    uplevel 1 [list assign-store-memory $t $value $addr]
}]

##############################################################################
#				assign-store-memory
##############################################################################
#
# SYNOPSIS:	    Store a value into memory for the assign command
# PASS:		    t	    = token for the type of data to store
#   	    	    value   = address expression for the value to store
#   	    	    addr    = address expression for the destination
# CALLED BY:	    assign, self
# RETURN:	    nothing
# SIDE EFFECTS:	    data are stored into memory.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
##############################################################################
[defsubr assign-store-memory {t value addr}
{
    [case [type class $t] in
        char {
	    uplevel 1 [list value store $addr
	    	    	     [format {\\%o} [getvalue $value]] $t]
	}
	{bitfield int enum} {
	    uplevel 1 [list value store $addr [getvalue $value] $t]
    	}
	struct {
	    require isrecord print
	    require cvtrecord print
	    
	    if {[isrecord $t]} {
    	    	# If the type is a record, convert the offset of the value
		# into the appropriate value list and store the whole mess
	    	uplevel 1 [list value store $addr
    		    [cvtrecord $t [uplevel 1 getvalue $value]]
    		    $t]
    	    } else {
	    	error {cannot assign to a structure or union, yet}
    	    }
    	}
	array {
    	    # XXX: at some point it would be nice to allow a list of values
	    # to be stored...for now, just assume wants to store to the
	    # base type.
	    uplevel 1 [list assign-store-memory
			    [index [type aget $t] 0] $value $addr]
    	}
	void {
	    error {cannot assign to something of type void}
    	}
	function {
	    error {cannot assign to something of type function}
    	}
	default {
	    error {cannot assign to something of unknown type}
    	}
	pointer {
	    var v [uplevel 1 addr-parse $value 0]
	    [case [index [type pget $t] 0]
	     near {
	     	#
		# Near pointer: store just the offset of the value (doesn't
		# matter if $v is address or value, as v[1] should be integer
		# we need in either case).
		#
	     	uplevel 1 [list value store $addr [index $v 1] $t]
    	     }
	     far {
	     	#
		# Far pointer: need to form the segment and offset into a
		# 32-bit number with the segment in the high 16 bits.
		#
	     	if {[null [index $v 0]] || ![string c [index $v 0] value]} {
    	    	    #
		    # Address is absolute, so figure the segment and offset,
		    # being careful of what segment we use for things in the
		    # HMA (always 0xffff)
		    #
    	    	    if {[index $v 1] >= 0x100000} {
		    	var seg 0xffff off [expr [index $v 1]-0xffff0]
    	    	    } else {
		    	[var seg [expr [index $v 1]>>4]
			     off [expr [index $v 1]&0xf]]
    	    	    }
    	    	} else {
		    #
		    # If the block is actually resident, use its segment and the
		    # offset from the address.
		    #
    	    	    if {[handle state [index $v 0]] & 1} {
			[var seg [handle segment [index $v 0]] 
			     off [index $v 1]]
    	    	    } else {
		    	error [format {handle %04xh isn't resident, so its segment cannot be determined}
			    	[handle id [index $v 0]]]
    	    	    }
    	    	}
		    	
		uplevel 1 [list value store $addr [expr ($seg<<16)|$off] $t]
    	     }
	     seg {
	     	#
		# Segment pointer: if the value lies in a block, use the segment
		# of that block. Else we assume the segment was given as a
		# number and therefore use the offset of the value.
		#
	     	if {[null [index $v 0]] || ![string c [index $v 0] value]} {
		    var seg [index $v 1]
    	    	} elif {[handle state [index $v 0]] & 1} {
		    var seg [handle segment [index $v 0]]
    	    	} else {
		    error [format {handle %04xh isn't resident, so its segment cannot be determined}
			    [handle id [index $v 0]]]
    	        }
		uplevel 1 [list value store $addr $seg $t]
    	     }
	     lmem {
    	    	#
		# LMem pointer: map the value back to its chunk handle, if it
		# includes an indirection (if it doesn't, g-c-a-f-o-a will do
		# the right thing...), and store the offset of the resulting
		# address list, it being a chunk handle. If the value is
		# absolute (meaning just a number was given), don't bother
		# with the mapping, but use the offset as-is.
		#
    	    	if {![null [index $v 0]] && [string c [index $v 0] value]} {
	     	    var v [uplevel 1 [list get-chunk-addr-from-obj-addr $value]]
    	    	}
		uplevel 1 [list value store $addr [index $v 1] $t]
    	     }
	     handle {
    	    	#
		# Handle pointer: if value is absolute, so handle ID was given
		# as a number, use just the offset, else use the ID of the
		# handle of the block in which the value falls.
		#
    	    	if {[null [index $v 0]] || ![string c [index $v 0] value]} {
		    var hid [index $v 1]
    	    	} else {
		    var hid [handle id [index $v 0]]
    	    	}
	     	uplevel 1 [list value store $addr $hid $t]
    	     }
	     object {
	     	#
		# Object pointer: similar to lmem, except the value cannot
		# be specified by a number, so call g-c-a-f-o-a immediately
		#
		if {![null [index $v 0]] && [string c [index $v 0] value]} {
	     	    var v [uplevel 1 [list get-chunk-addr-from-obj-addr $value]]
		    if {[null [index $v 0]]} {
			error [format {%s cannot be assigned to an optr as it doesn't fall within a block on the heap}
				    $value]
		    } else {
			var hid [handle id [index $v 0]]
		    }
		    uplevel 1 [list value store $addr
				[expr ($hid<<16)|[index $v 1]] $t]
    	    	} elif {[index $v 1] != 0} {
		    error {optrs can only be assigned 0 or a full address}
    	    	} else {
		    uplevel 1 value store $addr 0 $t
    	    	}
    	     }
    	    ]
	}
    ]
}]
	
	    
	
	    
