##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#	$Id: format-inst.tcl,v 3.5 90/09/09 22:25:18 adam Exp $
#
###############################################################################

[defvar showMethodNames 0 output
{If non-zero, prints out the names of the method in ax when unassembling a
"CALL ObjMessage" or equivalent.  }]

##############################################################################
#
# mangle-softint
#   Takes an insn (returned by unassemble) that describes a software interrupt
#   and, if it is one of geos's funky software interrupts to call movable
#   routines, mangle it into an insn for the CALL that it is.
#
[defsubr mangle-softint {insn}
{
    if {[string c [index [index $insn 1] 0] INT]} {
	# Not actually a software interrupt (there are folks who call us
	# unconditionally) -- just return the instruction unaltered
	return $insn
    }

    var inum [index [index $insn 1] 1]
    # Figure base address of instruction (elt 0 of insn)
    var addr [index $insn 0]
    [case $inum in
	{-12[0-8]|-11[3-9]} {
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
    return [list $addr [format {CALL    %s} $arg] 5 [index $insn 3]]
}]

##############################################################################
#
# format-instruction
#	Format an instruction (as returned by unassemble) in a regular way.
#
[defsubr format-instruction {insn {stepping 0}}
{
    global  showMethodNames

    # Deal with software-interrupts that are calls, first.
    if {[string c [index [index $insn 1] 0] INT] == 0} {
    	var insn [mangle-softint $insn]
    }
		    
    if {[length [index $insn 3] chars] != 0} {
	return [format {%-20s %-27s;%s} [index $insn 0]: [index $insn 1]
		[index $insn 3]]
    } else {
      if $stepping {
	if {[string c [index [index $insn 1] 0] CALL]==0 && $showMethodNames} {
	     var rout [index [index $insn 1] 1]
	     [case $rout in 
		 ObjMessage {
		    if {[handle segment [handle lookup [read-reg bx]]] != 0} {
			return [format-method $insn ^lbx:si]
		    } else {
			return [format {%-20s %s;(handle discarded)}
					[index $insn 0]: [index $insn 1]]
		    }
		 }
		 ObjCallInstanceNoLock {
		    return [format-method $insn *ds:si]
		 }
		 ObjCallInstanceNoLockES {
		    return [format-method $insn *ds:si]
		 }
		 ObjCallClassNoLock {
		    return [format-method $insn *ds:si]
		 }
		 ObjCallSuperNoLock {
		    return [format-method $insn *ds:si]
		 }
		 default {
	            return [format {%-20s %s} [index $insn 0]: [index $insn 1]]
		 }
	     ]
	} else {
	     return [format {%-20s %s} [index $insn 0]: [index $insn 1]]
	}
      } else {
	 return [format {%-20s %s} [index $insn 0]: [index $insn 1]]
      }
    }
}]
 

[defsubr format-method {insn obj}
{
    return [format {%-20s %-27s;%s} [index $insn 0]: [index $insn 1]
		[map-method [read-reg ax] $obj]]
}]
