##############################################################################
#
# 	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	smatch.tcl
# FILE: 	smatch.tcl
# AUTHOR: 	???
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	dbaumann	4/30/97   	added id string 
#
# DESCRIPTION:
#
#	
#
#	$Id: smatch.tcl,v 3.3 97/04/30 12:18:36 dbaumann Exp $
#
###############################################################################
[defcmd smatch {pattern {class any}} top
{Look for symbols of a given class by pattern. First argument PATTERN is the
pattern for which to search (it's a standard SWAT pattern using shell wildcard
characters). Optional second argument CLASS is the class of symbol for which
to search and is given directly to the "symbol match" command. Defaults to
"any".}
{
    var syms [symbol match $class $pattern]
    var len 0
    foreach i $syms {
    	var sl [length [symbol fullname $i] chars]
	if {$sl > $len} {
	    var len $sl
	}
    }
    var nc [expr [columns]/($len+3)]
    if {$nc == 0} {
	var nc 1
    }
    var fw [expr ([columns]-1)/$nc]

    var j 0
    foreach i $syms {
	echo -n [format {%-*s} $fw [symbol fullname $i]]
	var j [expr $j+1]
	if {$j == $nc} {
	    echo
	    var j 0
	}
    }
    if {$j != 0} {
	echo
    }
}]

