##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	tprint.tcl
# AUTHOR: 	Jim DeFrisco, Sept 20, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	twalk			step through all the YPosElements in a block
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	9/20/90		Initial Revision
#
# DESCRIPTION:
#	Functions for examining ascii printing structures
#
#	$Id: tprint.tcl,v 1.7.12.1 97/03/29 11:25:13 canavese Exp $
#
###############################################################################

defsubr pascii {addr count} {
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    echo -n "
    if {$count!=0} then {
	    [for {var c [value fetch $s:$o [type byte]]}
		 {$c != 0 && $count != 0}
		 {var c [value fetch $s:$o [type byte]]}
	    {
		if {$c<32} then {
		    var c 32
		}
		echo -n [format %c $c]
		var o [expr $o+1]
		var count [expr $count-1]
	    }]
    }
    echo "
}

##############################################################################
#				tprint-ype
##############################################################################
#
# SYNOPSIS:	Print the current yposelement
# PASS:		addr	- address of YPosElement
# CALLED BY:	twalk
# RETURN:	nothing
# SIDE EFFECTS:	newline is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	9/20/90		Initial Revision
#
##############################################################################
[defsubr tprint-ype addr
{
    var a [addr-parse $addr]
    var segm [handle segment [index $a 0]]
    var offs [index $a 1]
    var xpos [value fetch $segm:$offs.YPE_pos.P_x [type word]]
    var ypos [value fetch $segm:$offs.YPE_pos.P_y [type word]]
    var shan [value fetch $segm:$offs.YPE_string [type word]]
    var	sptr [value fetch $segm:$shan [type word]]
    var numc [value fetch $segm:$sptr.SI_slen [type word]]

    if {$numc>60} then {
	var numc 60
	}
    echo -n [format {%d\t%d\t} $ypos $xpos]
    pascii $segm:$sptr.SI_slen+2 $numc

    [for {var n [value fetch $segm:$sptr.SI_next [type word]]}
	 {$n != 0}
	 {var n [value fetch $segm:$sptr.SI_next [type word]] }
    {
	var sptr [value fetch $segm:$n [type word]]
	var xpos [value fetch $segm:$sptr.SI_xpos [type word]]
        var nc [value fetch $segm:$sptr.SI_slen [type word]]
	echo -n [format {\t%d\t} $xpos]
        pascii $segm:$sptr.SI_slen+2 $nc
    }]
}]
##############################################################################
#				tswalk
##############################################################################
#
# SYNOPSIS:	Print the current textstrings block
# PASS:		addr	- address of TextStrings block
# CALLED BY:	twalk
# RETURN:	nothing
# SIDE EFFECTS:	newline is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	9/20/90		Initial Revision
#
##############################################################################
[defcommand tswalk {addr} lib_app_driver.spool
{Usage:
    tswalk <address>

Examples:
    tswalk ds:di

Synopsis:
    Print a TextStrings block for ascii printing.

Notes:
    * The address argument is the address of a TextStrings block.
}
{
    var a [addr-parse $addr]
    var segm [handle segment [index $a 0]]
    var offs [index $a 1]

    var ype1 [value fetch $segm:$offs.TS_firstYPos [type word]]
    var ypeptr [value fetch $segm:$ype1 [type word]]

    [for {var nype $ype1}
	 {$nype!=0}
	 {var nype [value fetch $segm:$ypeptr.YPE_next [type word]]}
    {
	var ypeptr [value fetch $segm:$nype [type word]]
        tprint-ype $segm:$ypeptr
    }]
}]
