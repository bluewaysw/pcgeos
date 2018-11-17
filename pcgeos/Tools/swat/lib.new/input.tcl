##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	gui.tcl
# AUTHOR: 	doug
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	print-pre-passive	Prints out pre-passive grabs for VisContent obj
#   	print-post-passive	Prints out post-passive grabs for VisContent obj
#
#	$Id: input.tcl,v 1.2.12.1 97/03/29 11:26:36 canavese Exp $
#
###############################################################################

[defcmd print-pre-passive {{obj (*ds:si)}} object.vis 
{Usage:
    print-pre-passive <obj>

Examples:
    print-pre-passive		Prints out pre-passive grab list of
				VisContent object at *ds:si

Synopsis:
    Prints out pre-passive grab list

Notes:
See also:
}
{
    var vi ($obj+[value fetch ($obj+4).offset])
    var han [handle id [index [addr-parse $obj] 0]]
    var chk [value fetch $vi.VCNI_prePassiveMouseGrabList.chunk]
    var off [value fetch (^l$han:$chk).CAH_offset]
    var count [value fetch (^l$han:$chk).CAH_count]
    print VisMouseGrab ((^l$han:$chk)+$off)#$count
}]

[defcmd print-post-passive {{obj (*ds:si)}} object.vis
{Usage:
    print-post-passive <obj>

Examples:
    print-post-passive		Prints out post-passive grab list of
				VisContent object at *ds:si

Synopsis:
    Prints out post-passive grab list

Notes:
See also:
}
{
    var vi ($obj+[value fetch ($obj+4).offset])
    var han [handle id [index [addr-parse $obj] 0]]
    var chk [value fetch $vi.VCNI_postPassiveMouseGrabList.chunk]
    var off [value fetch (^l$han:$chk).CAH_offset]
    var count [value fetch (^l$han:$chk).CAH_count]
    print VisMouseGrab ((^l$han:$chk)+$off)#$count
}]

