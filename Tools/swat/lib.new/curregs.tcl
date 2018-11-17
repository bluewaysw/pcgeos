##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	curregs.tcl
# FILE: 	curregs.tcl
# AUTHOR: 	Adam de Boor, Oct  3, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	print-cur-regs	    	Print current registers based on what
#   	    	    	    	current-registers returns.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/ 3/90	Initial Revision
#
# DESCRIPTION:
#	Functions to print out the current registers regardless of whether the
#	thread's top frame is valid...
#
#	$Id: curregs.tcl,v 1.6.30.1 97/03/29 11:27:41 canavese Exp $
#
###############################################################################
[defsubr cur-reg {i}
{
    global regnums

    var regnum [index [assoc $regnums $i] 1]
    return [index [current-registers] $regnum]
}]

[defsubr print-cur-regs {}
{
    global regnums flags
    #
    # Print out the general registers in both hex and decimal
    #
    var j 0
    foreach i {AX BX CX DX SI DI BP SP} {
	var regval [cur-reg $i]
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
    	var regval [cur-reg $i]
    	var handle [handle find [format %04xh:0 $regval]]
    	if {![null $handle]} {
    	    if {[handle state $handle] & 0x480} {
    	    	#
		# Handle is a resource/kernel handle, so it's got a symbol in
    	    	# its otherInfo field. We want its name.
    	    	#
    	    	echo -n [format {%-4s%04xh   handle %04xh (%s)}
    	    	    	    $i $regval [handle id $handle]
    	    	    	    [symbol fullname [handle other $handle]]]
    	    } else {
    	    	echo -n [format {%-4s%04xh   handle %04xh}
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
    var ip [cur-reg IP] 
    var ipsym [symbol faddr func
			   [format {%04xh:%04xh} [cur-reg CS] $ip]]
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
    echo
    echo -n {Flags: }
    var flagval [cur-reg CC]
    foreach i $flags {
        var bit [index $i 1]
	echo -n [format {%s=%d } [index $i 0] [expr ($flagval&$bit)/$bit]]
    }
    echo
    echo
    #
    # Print the instruction and args at cs:ip. 
    #
    echo [format-instruction [unassemble cs:ip 1] cs:ip]
}]
