#######################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Vis Moniker Printout
# FILE:		phint.tcl
# AUTHOR:	Andrew Wilson, June 27, 1989
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	phintchunk    	    	Print a hints chunk
#   	phint 	    	    	Print a hints chunk for an object
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	atw	6/27		Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to print out VisMonikers and GStrings.
#
#	$Id: phint.tcl,v 3.10.30.1 97/03/29 11:25:55 canavese Exp $
#
#############################################################################@

[defcommand phintchunk {{address *ds:si}} {output ui}
{Usage:
    phintchunk [<address>]

Examples:
    phintchunk ds:si

Notes:
    * The address argument is the address of a chunk with hints.  The
      default is *ds:si.

See also:
    phint.
}
{
	echo Hints:
	var addr [addr-parse $address]
	var seg [handle segment [index $addr 0]]
	var chunk [index $addr 1]
# If at end of gstring, exit
	var off [value fetch $seg:$chunk word]
	if {$off == 65535} then {	#Empty chunk
		echo \t *** No Hints ***
		return
	}
	var sz [value fetch $seg:$off-2 word]
	[for {var sz [expr $sz-2]}
	    {$sz != 0} 
	    {}
	{	
		var element [value fetch $seg:$off word]
		var eltype [penum Hints $element]
		var elsize [value fetch $seg:$off+2 word]
		  [case $eltype in 
			HINT_SET_DESIRED_SIZE {
				echo \t $eltype
				if {$elsize == 10} {
					print CompSpecSize $seg:$off+4
				} else {
					print GadgetSpecSize $seg:$off+4
				}
			}
			HINT_SET_WIN_POS_SIZE_ATTR {
				echo \t $eltype
				print PosSizeAttrInfo $seg:$off+4
			}
			HINT_LIST_SCROLLING {
				echo -n \t $eltype {-- }
				echo [value fetch $seg:$off+4 word]
			}
			nil {
				echo [format {Bad Hint: %d } $element]
			}
			default {
				echo \t $eltype
			}
		    ]
	    	var sz [expr $sz-[value fetch $seg:$off+2 word]] 
		var off [expr $off+$elsize]
	}]
}]
[defcommand phint {{address *ds:si}} {output ui}
{Usage:
    phint [<address>]

Examples:
    "phint"

Synopsis:
    List the hints of the passed object.

Notes:
    * The address argument is the address of an object with hints.  The
      default is *ds:si.

See also:
    phintchunk.
}
{
	var addr [addr-parse $address]
# Get segment and offset into separate vars
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
	var gboffset [value fetch $seg:$off.Gen_offset]
	var off [expr $off+$gboffset]
# Print Hints
	var off [value fetch $seg:$off.GI_hints word]
	if {$off == 0} then {
		echo \t *** No Hint chunk ***
		return
	}
	phintchunk $seg:$off
}]
