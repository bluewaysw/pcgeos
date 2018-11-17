#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		vtwatch.tcl
# AUTHOR:	John Wedgwood, Dec  3, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	vtwatch	    	    	Watch methods sent to VisTextClass
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	12/ 3/91	Initial revision
#
# DESCRIPTION:
#	Tcl code for watching methods being sent to VisText objects.
#
#	$Id: vtwatch.tcl,v 1.1 97/04/07 11:22:35 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# status and breakpoint for vtwatch
#
defvar	vtw_on  0
defvar	vtw_brk {}

##############################################################################
#				vtwatch
##############################################################################
#
# SYNOPSIS:	
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	12/ 3/91	Initial Revision
#
##############################################################################
[defcommand vtwatch {{onOff {}}} text
{Usage:
    vtwatch [onOff]

Examples:
    "vtwatch"	    	print the current vtwatch status
    "vtwatch on"    	turn vtwatch on
    "vtwatch off"    	turn vtwatch off

Synopsis:
    Watch methods being routed to objects of VisTextClass

Notes:

See also:
}
{
    global  vtw_on
    global  vtw_brk

    if {[null $onOff]} {
	if {$vtw_on} {
	    echo {On}
	} else {
	    echo {Off}
	}
    } elif {[string compare $onOff {on}] == 0} {
    	if {$vtw_on == 0} {
	    #
	    # vtwatch was off, turn it on
	    #
	    var vtw_on 1

	    var addr [addr-parse text::VisTextClass]
	    var seg  [handle segment [index $addr 0]]
	    var off  [index $addr 1]

	    var vtw_brk [brk aset ObjCallMethodTable::masterLoop]

	    brk cond $vtw_brk es=$seg bp=$off
	    brk cmd $vtw_brk  vtw-print-method
	}
    } elif {[string compare $onOff {off}] == 0} {
    	if {$vtw_on == 1} {
	    #
	    # vtwatch was on, turn it off
	    #
	    var vtw_on 0
	    brk del $vtw_brk
	}
    }
}]

##############################################################################
#				vtw-print-method
##############################################################################
#
# SYNOPSIS:	Print a method that is being sent to a VisText object.
# CALLED BY:	via breakpoint
# PASS:		registers containing the information
# RETURN:	0 always
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	12/ 3/91	Initial Revision
#
##############################################################################
[defsubr vtw-print-method {}
{
    var a [read-reg ax]
    var s [read-reg ds]
    var c [read-reg si]
    var h [value fetch ds:0 [type word]]
    
    var m [type emap $a [sym find type VisTextMethods]]
    if {[null $m]} {
    	#
	# Try meta-methods
	#
        var m [type emap $a [sym find type MetaMessages]]
    }
    
    if {[null $m]} {
    	#
	# Sigh... just use the value
	#
	var m $a
    }

    echo [format {%s sent to *%04xh:%04xh (^l%04xh:%04xh)}
    	    $m $s $c $h $c]

    return 0
}]
