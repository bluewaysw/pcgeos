##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	format-inst.tcl
# AUTHOR: 	Adam de Boor, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	format-instruction  	Formats an instruction list
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Format an instruction (as returned by unassemble) in a regular way.
#
#	$Id: fmt-inst.tcl,v 3.13.11.1 97/03/29 11:26:37 canavese Exp $
#
###############################################################################

[defvar showMethodNames 0 swat_prog.variable
{If non-zero, prints out the names of the method in ax when unassembling a
"CALL ObjMessage" or equivalent.  }]

##############################################################################
#				mangle-softint
##############################################################################
#
# SYNOPSIS:	Deal with pc/geos use of software interrupts for far calls
#   	    	to movable routines.
# PASS:		insn	= instruction list from unassemble, with or without
#			  args.
#   	    	addr	= address from which the instruction was fetched
# CALLED BY:	istep, listi, others
# RETURN:	instruction list to display
# SIDE EFFECTS:	none
#
# STRATEGY
#   	If interrupt number is one of pc/geos's special interrupts (0x80-0x8f)
#   	fetch the handle and offset from the interrupt number and the following
#	
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/18/91		Initial Revision
#
##############################################################################
[defsubr mangle-softint {insn addr}
{
    if {[string c [index [index $insn 1] 0] INT]} {
	# Not actually a software interrupt (there are folks who call us
	# unconditionally) -- just return the instruction unaltered
	return $insn
    }

    var inum [index [index $insn 1] 1]

    [case $inum in
	{-12[0-8] -11[3-9]} {
	    #
	    # Call of routine. Low four bits of interrupt number contain
	    # high nibble of low byte of handle. First byte contains high
	    # byte of handle. Next two bytes are offset in block.
	    #
	    # Fetch the next three bytes
	    var j [map i {2 3 4} {value fetch $addr+$i [type byte]}]

    	    var han ^h[expr ([index $j 0]<<8)+(($inum&0xf)<<4)]
	    var off [expr ([index $j 2]<<8)+[index $j 1]]
    	}
        {5[23456789]} {
    	    # do the normal coprocessor instruction
	    var t [type make array 9 [type byte]]
	    var op [eval [concat find-opcode $addr+1 [expr $inum+(0xd8-0x34)]
    	    	    	 [value fetch $addr+2 $t]]]
    	    type delete $t
    	    return [list [index $insn 0] [index $op 7] [expr [index $op 1]+1] {}]
    	}
    	{60} {
    	    # coprocessor instruction with segment override
    	    var t [type make array 8 [type byte]]
    	    var oph [value fetch $addr+2 [type byte]]
##    	    var op [eval [concat find-opcode $addr+2 [ expr $oph|0xc0]
##   	    	    	 [value fetch $addr+3 $t]]]

            var op [eval [concat find-opcode $addr+1 [expr 0x26|(($oph&0xc0)>>3)]
	 			[expr $oph|0xc0]
                       		[value fetch $addr+3 $t]]]

    	    type delete $t
    	    return [list [index $insn 0] [index $op 7] [expr [index $op 1]+1] {}]
    	}    	    	        	    
	{61} {
    	    return [list [index $insn 0] FWAIT 2 {}]
    	}
	default {
	    # Anything else is just a software interrupt
	    return $insn
	}
    ]
    # Lookup the routine's symbol
    var s [sym faddr func $han:$off]
    if {![null $s]} {
    	# Use symbol's name as argument
	var arg [symbol name $s]
    } elif {[string match $han ^h*]} {
    	# The numbers in $han and $off are in decimal, but user expects
	# to see them in hex.
	var arg [format {^h%04xh:%04xh} [range $han 2 end c] $off]
    } else {
    	# Non-movable, but numbers are in decimal -- convert to hex
	var arg [format {%04xh:%04xh} $han $off]
    }
    # Return modified insn, giving length of 5
    return [list [index $insn 0] [format {CALL    %s} $arg] 5 [index $insn 3]]
}]

##############################################################################
#				format-instruction
##############################################################################
#
# SYNOPSIS:	Format an instruction list in a regular way
# PASS:		insn	= instruction 4-list returned from "unassemble"
#   	    	addr	= address from which the instruction was fetched
#   	    	[stepping] = if given and non-zero, finds the method being
#   	    	    	     sent if calling a message function and the
#			     global variable showMethodNames is non-zero
# CALLED BY:	GLOBAL
# RETURN:	the formatted instruction, ready for printing
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
[defsubr format-instruction {insn addr {stepping 0}}
{
    global  showMethodNames

    # Deal with software-interrupts that are calls, first.
    if {[string c [index [index $insn 1] 0] INT] == 0} {
    	var insn [mangle-softint $insn $addr]
    }
		    
    [if {[length [index $insn 3] chars] != 0} {
    	#
	# If arguments present for the instruction, just field-format the
	# instruction with the args following a semi-colon (comment)
	#
	return [format {%-20s %-27s;%s} [index $insn 0]: [index $insn 1]
		[index $insn 3]]
    } elif {$stepping &&
      	    ([string c [index [index $insn 1] 0] CALL]==0) &&
	    $showMethodNames}
    {
	 var rout [index [index $insn 1] 1]
	 [case $rout in 
	     ObjMessage {
		return [format-method $insn ^lbx:si]
	     }
	     {ObjCallInstanceNoLock ObjCallInstanceNoLockES ObjCallClassNoLock
	      ObjCallSuperNoLock} {
		return [format-method $insn *ds:si]
	     }
	     default {
		return [format {%-20s %s} [index $insn 0]: [index $insn 1]]
	     }
	 ]
    } else {
	 return [format {%-20s %s} [index $insn 0]: [index $insn 1]]
    }]
}]
 

##############################################################################
#				format-method
##############################################################################
#
# SYNOPSIS:	Format an instruction that's calling a message-sending
#   	    	routine, determining what message is being sent
# PASS:		insn	= instruction-list from unassemble
#   	    	obj 	= address of the object to which the message is
#			  being sent
# CALLED BY:	format-instruction
# RETURN:	the formatted instruction
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
[defsubr format-method {insn obj}
{
    #
    # Message is always in AX -- use map-method and the object we've been
    # given to determine the method name.
    #
    return [format {%-20s %-27s;%s} [index $insn 0]: [index $insn 1]
		[map-method [read-reg ax] $obj]]
}]
