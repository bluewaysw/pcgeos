##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	phelp.tcl
# FILE: 	phelp.tcl
# AUTHOR: 	Gene Anderson, Nov  3, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	11/ 3/92		Initial Revision
#
# DESCRIPTION:
#	Commands for printing stuff about a HelpControl object
#
#	$Id: phelp.tcl,v 1.6 93/07/31 21:03:19 jenny Exp $
#
###############################################################################

##############################################################################
#				phelp
##############################################################################
#
# SYNOPSIS:	Print various things about a help object
# PASS:		ADDR - address of HelpControl object
#   	    	flags - what to print
# CALLED BY:	user
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	11/ 3/92	Initial Revision
#
##############################################################################

[defcmd phelp {args} lib_app_driver.help
{Usage:
    phelp [<flags>] [<address>]

Examples:
    "phelp ^l20c0h:20h"	    print help text for object at ^l20c0h:20h
    "phelp -h"	    	    print history for help object at *ds:si

Synopsis:
    Print information about a help object.

Notes:
    * The default address is *ds:si

See also:
    
    fonts, pfont, pusage, pfontinfo.
}
{
    require addr-with-obj-flag user.tcl
    require carray-enum chunkarr.tcl
    #
    # parse the flags
    #
    var hhistory 0
    var htext 0
    var	hgoback 0
    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		t {var htext 1}
		h {var hhistory 1}
    	    	g {var hgoback 1}
	    ]
	}
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    } else {
	var hhistory 1
    }
    #
    # Get the address of the object
    #
    if {[null $args]} {
    	var args *ds:si
    }
    var addr [addr-parse ($args)]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    var	HI  [expr $off+[value fetch $seg:$off.ui::Gen_offset]]
    var instance [value fetch $seg:$HI ui::HelpControlInstance]
    #
    # Get the childblock 
    #
    var vd [fvardata TEMP_GEN_CONTROL_INSTANCE $args]
    var childBlock [field [index $vd 1] TGCI_childBlock]
    #
    # Print the text, if requested
    #
    if {$htext} {
    	ptext ^l$childBlock:20h
    }
    #
    # Print the history list, if requested
    #
    if {$hhistory} {
    	var histBuf [field $instance HCI_historyBuf]
    	echo {-------History--------}
    	if {$histBuf} {
    	    carray-enum ^l$histBuf:16 _print-one-history
    	} else {
    	    error {no history buffer}
    	}
    }
    #
    # Print the go back list, if requested
    #
    if {$hgoback} {
    	var histBuf [field $instance HCI_historyBuf]
    	echo {-------Go Back--------}
    	if {$histBuf} {
    	    carray-enum ^l$histBuf:18 _print-one-go-back
    	} else {
    	    error {no history buffer}
    	}
    }
}]

[defsubr _print-one-history {elnum addr lsize extra}
{
    var hhe [value fetch $addr ui::HelpHistoryElement]
    var addr [addr-parse ($addr)]
    var seg [handle segment [index $addr 0]]
    echo [format {#%d } $elnum]
    echo -n {file	= }
    var hname [field $hhe HHE_filename]
    pstring *$seg:$hname
    echo -n {context	= }
    var hname [field $hhe HHE_context]
    pstring *$seg:$hname
    echo -n {title	= }
    var hname [field $hhe HHE_title]
    if {$hname} {
    	pstring *$seg:$hname
    } else {
    	echo {}
    }
    echo [format {type = %s} [penum text::VisTextContextType [field $hhe HHE_type]]]
    echo {----------------------}
    return 0
}]

[defsubr _print-one-go-back {elnum addr lsize extra}
{
    var hgbe [value fetch $addr ui::HelpGoBackElement]
    var addr [addr-parse ($addr)]
    var seg [handle segment [index $addr 0]]
    echo [format {history number = #%d} [field $hgbe HGBE_history]]
    echo {----------------------}
    return 0
}]
