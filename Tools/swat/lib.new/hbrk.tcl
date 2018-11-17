##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
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
#	$Id: hbrk.tcl,v 3.9.12.1 97/03/29 11:26:33 canavese Exp $
#
###############################################################################

[defcmd hbrk {loc size brktype value} breakpoint
{Usage:	
    hbrk <address> (byte|word) (match|mismatch) <value>

Examples:
    "hbrk scrollTab+10 byte match 0"	print method handlers until a zero 
    	    	    	    	    	is written at scrollTab+10.
    "hbrk OLScrollButton+3 word mismatch 0x654f"
    	    	    	    	    	Break when the word at OLScrollButton+3 
    	    	    	    	    	is destroyed.

Synopsis:
    Break when a value in a memory location changes.

Notes:
    * The address argument is the address to watch for a change.

    * The (byte|word) argument indicates whether to watch a byte or a
      word for a change.

    * The (match|mismatch) argument indicates whether to break if the 
      value at the address matches or mismatches the value hbrk is
      called with.

    * hbrk emulates a hardware breakpoint by checking at every method
      call to see if a location in memory has been written to.  If so,
      swat breaks and tells between which two methods the write
      occurred.  The information and the return stack will hopefully
      guide you to the offending line of code.

    * The command creates two breakpoints.  Remove these to get rid of
      the hardware breakpoint.  

See also:
    brk, mwatch, showcalls.
}
{
    # Change brktype to be its proper relational operator
    if {[string c $brktype match] == 0} {var brktype ==} {var brktype !=}
    
    # Set breakpoints at the place in a method call where we know
    # to where we're going
    brk aset CallFixed [list hbrk-cm $loc $size $brktype
    	    	    	     $value]
    brk aset ProcCallModuleRoutine [list hbrk-pcmr  $loc $size
    	    	    	    	    	$brktype $value]
}]

[defsubr hbrk-cm {loc size brktype value} {                              
    # Set breakpoint for direct call to fixed method handler
    [brk tset {*(dword es:bx)}
	[list hbrk2 $loc $size $brktype $value]]
    # Keep going
    echo -n .
    flush-output
    return 0
}]

[defsubr hbrk-pcmr {loc size brktype value} {                              
    # Set breakpoint for call to moveable method handler
    [brk tset ^hbx:ax
	[list hbrk2 $loc $size $brktype $value]]
    # Keep going
    echo -n .
    flush-output
    return 0
}]

[defsubr hbrk2 {loc size brktype value} {
    global lastMtd breakpoint

    brk clear $breakpoint

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



