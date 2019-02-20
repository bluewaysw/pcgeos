##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	hbrk.tcl
# AUTHOR: 	Chris Hawley, June 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	hbrk	    	    	Pseudo-hardware breakpoint
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cbh	6/89		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: hbrk.tcl,v 3.1 90/03/30 17:34:53 andrew Exp $
#
###############################################################################

[defcommand hbrk {loc size brktype value} break
{
Usage:	"hbrk <location> (byte|word) (match|mismatch) <value>"

Emulates a hardware breakpoint by checking at every method call to
see if a location in memory has been written to, and breaks when it happens,
telling you between which two routines the write occurred.  The information
and the return stack will hopefully guide you to the offending line of code.

Examples:
	
	hbrk scrollTab+10 byte match 0
	(Continues, printing method handlers, until a zero is written at
         scrollTab+10)

	hbrk OLScrollButton+3 word mismatch 0x654f
	(Goes until the word at OLScrollButton+3 is destroyed. Hex numbers
	 require the 0x format)

The command creates two breakpoints.  Remove these to get rid of the 
hardware breakpoint.
}
{
    # Change brktype to be its proper relational operator
    if {[string c $brktype match] == 0} {var brktype ==} {var brktype !=}
    
    # Set breakpoints at the place in a method call where we know
    # to where we're going
    brk aset CallFixed [format {[hbrk-cm %s %s %s %s]} $loc $size $brktype
    	    	    	     $value]
    brk aset ProcCallModuleRoutine [format {[hbrk-pcmr %s %s %s %s]} $loc $size
    	    	    	    	    	$brktype $value]
}]

[defsubr hbrk-cm {loc size brktype value} {                              
    # Set breakpoint for direct call to fixed method handler
    [brk tset {*(dword es:bx)}
	[format {[hbrk2 %s %s %s %s]} $loc $size $brktype $value]]
    # Keep going
    echo -n .
    flush-output
    return 0
}]

[defsubr hbrk-pcmr {loc size brktype value} {                              
    # Set breakpoint for call to moveable method handler
    [brk tset ^hbx:ax
	[format {[hbrk2 %s %s %s %s]} $loc $size $brktype $value]]
    # Keep going
    echo -n .
    flush-output
    return 0
}]

[defsubr hbrk2 {loc size brktype value} {
    global lastMtd
    if [concat [value fetch $loc $size] $brktype $value] {
	echo
	echo Value changed between $lastMtd and [func]
    	# stop!
	return 1
    } else {
	var lastMtd [func]
    	# s'ok, keep going
	return 0
    }
}]



