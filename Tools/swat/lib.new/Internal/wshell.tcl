##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	wshell.tcl
# FILE: 	wshell.tcl
# AUTHOR: 	Chris Boyke, Jul 16, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CB	7/16/92		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: wshell.tcl,v 1.2 93/07/31 21:47:13 jenny Exp $
#
###############################################################################

[defhelp wshell lib_app_driver
{Commands relating to WShell}]

#####################################################################
[defcommand    opentree {} lib_app_driver.wshell
{Usage:

    opentree

Examples:

			
Synopsis:

    Prints out all the "open" files
Notes:

See also:

}
{
    require objtree-enum objtree.tcl
    require is-obj-in-class grab.tcl
    objtree-enum OpenResource:OpenTop 0 3 nil openlink opencomp 0

}]

##############################################################################
#	openlink
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	7/16/92   	Initial Revision
#
##############################################################################
[defsubr    openlink {obj} {

    var addr [addr-parse $obj]
    var hid [handle id [index $addr 0]]
    var off [index $addr 1]
    return [fetch-optr $hid [expr $off+[getvalue OFI_link]]]
}]

##############################################################################
#	opencomp
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	7/16/92   	Initial Revision
#
##############################################################################
[defsubr    opencomp {obj} {

    var addr [addr-parse $obj]
    var hid [handle id [index $addr 0]]
    var off [index $addr 1]
    if { [is-obj-in-class $obj OpenFileCompClass] } {
    	return [fetch-optr $hid [expr $off+[getvalue OFCI_comp]]]
    }
}]
