##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat system library
# FILE: 	pwwf.tcl
# AUTHOR: 	Adam de Boor, January 1, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	pwwf			given two numbers being the integer and
#				fractional parts of a WWFixed number, print
#				the thing as a real number
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/1/92		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: pwwf.tcl,v 1.3.30.1 97/03/29 11:26:34 canavese Exp $
#
###############################################################################
[defsubr pwwf {int frac {type WWFixed}}
{
    var t [symbol find type $type]
    #
    # Create a value list placing the values we were given in their proper
    # locations.
    #
    var val [map f [type fields $t] {
	[case [index $f 0] in
  	    *_frac {
		list [index $f 0] [index $f 3] [getvalue $frac]
	    }
  	    *_int {
		list [index $f 0] [index $f 3] [getvalue $int]
	    }
	]
    }]
    require fmtval print
    fmtval $val $t 4 {} 0
}]
