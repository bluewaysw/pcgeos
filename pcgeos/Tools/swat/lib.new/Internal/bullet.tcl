##############################################################################
#
# 	Copyright (c) Geoworks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	bullet.tcl
# FILE: 	bullet.tcl
# AUTHOR: 	Chris Boyke, Oct 11, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CB	10/11/93	Initial Revision
#
# DESCRIPTION:
#	Stuff for da bullet.
#
#	$Id: bullet.tcl,v 1.3 93/12/16 14:32:25 adam Exp $
#
###############################################################################


##############################################################################
#	memmap
##############################################################################
#
# SYNOPSIS:	Print out a memory map for the bullet 
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	This should only be used on the bullet, as it uses
#   	    	bullet-specific IO ports.
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	10/11/93   	Initial Revision
#
##############################################################################
[defsubr    memmap {} {
    # Save the old value of the address register in case the PC was
    # in the middle of using it.

    var origAddr [io 6ch]

    echo Memory Map for the Bullet:
    for {var i 80h} {$i < 0f0h} {var i [expr $i+4]} {
	io 6ch $i
	var dest [expr [index [io w 6eh] 0]]
	var dflags [expr ($dest&0f000h)>>12]
	var daddr [expr $dest&0fffh]
	echo -n [format {%02x00h mapped to  (%04xh):  } $i $dest] 
	if {![expr $dflags&8]} {
	    echo (disabled)
	}
	if {$dflags == 9} {
	    echo [format {RAM: %04xh} [expr $daddr*1024]]
	}
	if {$dflags == 10} {
	    echo [format {ROM bank 0: %04xh} [expr $daddr*1024]]
	}
	if {$dflags == 11} {
	    echo [format {ROM bank 1: %04xh} [expr $daddr*1024]]
	}
    }
    #
    # restore the address register
    #
    io 6ch [index $origAddr 0]

}]

##############################################################################
#	iostat
##############################################################################
#
# SYNOPSIS:	Print out the status of various IO registers related
#               to the pen and other fun stuff.
#
# NOTES:
#     The low nibble of PIC1 should have bit 2 CLEAR to enable
#     pen interrupts.  The Peripheral control should have bit 0 clear
#     if pen stuff is enabled.
#
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	10/21/93   	Initial Revision
#
##############################################################################
[defsubr    iostat {} {
    echo
    echo Interrupt controller:
    echo [format {  PIC0 (port 20h): %02xh  PIC1 (port 21h): %02xh}
	  [index [io 20h] 0] [index [io 21h] 0]]
    echo
    echo Peripheral control:
    echo [format {  (port 2eh): %02xh}
	  [index [io 2eh] 0]]
}]

