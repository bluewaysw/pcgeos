#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		pblk.tcl
# AUTHOR:	John Wedgwood, Nov  5, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pparams	    	    	Print a parameter block
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	11/ 5/91	Initial revision
#
# DESCRIPTION:
#	Code to print out the chart parameter block.
#
#	$Id: old.tcl,v 1.1 97/04/04 17:45:35 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# Various requirements
#
require	format-float fp

##############################################################################
#				pparams
##############################################################################
#
# SYNOPSIS:	Print a chart parameter block
# PASS:		address	- Address of the parameter block
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/ 5/91	Initial Revision
#
##############################################################################
[defcommand pparams {{address {}}} chart
{Usage:
    pparams [<address {}>]

Examples:
    "pparams"	    	print the chart parameters for the chart block
    	    	    	    whose segment is in ds.
    "pparams ^hax"    	print the chart parameters at ^hax

Synopsis:
    Print a chart parameter block in human readable form

Notes:

See also:
}
{
    #
    # If no address is supplied, create one
    #
    if {[null $address]} {
    	#
	# Get the memory handle for the chart block
	#
	var han  [value fetch ds:0 [type word]]
	var fhan [value fetch kdata:$han.HM_owner [type word]]
	var vhan [value fetch (*ds:TemplatePlotGroup).PGI_parameters]
	var address [format {^v%04xh:%04xh} $fhan $vhan]
    }

    #
    # Parse the address into something meaningful.
    #
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    
    var hdr 	 [value fetch $seg:0 [sym find type ChartParameters]]
    var nRows	 [field $hdr CP_nRows]
    var nColumns [field $hdr CP_nColumns]

    #
    # Print information about the basic block
    #
    echo [format {Chart Parameters %d bytes at ^h%04xh (%04xh:0h)}
			[field $hdr CP_endOfData]
    	    	    	$han $seg]
    echo [format {Contains %d Rows, %d Columns  (%d cells total)}
			$nRows
			$nColumns
			[expr $nRows*$nColumns]]

    #
    # Print out each of the entries
    #
    echo { ROW   COLUMN  OFFSET  SIZE   TYPE   DATA}
    echo {-----  ------  ------  ----  ------  ----}

    var cur  [type size [sym find type ChartParameters]]
    var cpct [sym find type ChartParameterCellType]

    for {var r 0} {$r < $nRows} {var r [expr $r+1]} {
    	for {var c 0} {$c < $nColumns} {var c [expr $c+1]} {
	    #
	    # Grab the offset to the data
	    #
	    var off [value fetch $seg:$cur [type word]]

	    if {$off == 0} {
	    	#
		# This entry hasn't been filled in yet...
		#
		var s 0
		var t NULL
		var data {}
	    } else {
		#
		# Figure the size based on the offset to the next entry or the
		# offset to the end of the block.
		#
		# Assume using end of block.
		#
    	    	var next    [field $hdr CP_endOfData]

    	    	var nextOff [value fetch $seg:$cur+2 [type word]]
		
		#
		# Check for conditions where another entry is available
		#
		if {($r!=($nRows-1) || $c!=($nColumns-1)) && $nextOff!=0} {
		    #
		    # Not last entry, use next field as offset
		    #
		    var next $nextOff
		}
		var s [expr $next-$off]

		#
		# Get the type
		#
		var t [type emap [value fetch $seg:$off $cpct] $cpct]
		var t [range $t 5 end chars]

		#
		# Scarf the data
		#
		var data [get-data $seg [expr $off+1] $t]
    	    }

	    echo [format {%5d   %5d   %04xh  %4d  %6s  %s}
	    	    	$r $c $off $s $t $data]

	    #
	    # Move to the next entry
	    #
    	    var cur [expr $cur+[type size [type word]]]
	}
    }
}]

##############################################################################
#				get-data
##############################################################################
#
# SYNOPSIS:	Get data for a chart parameter
# PASS:		seg 	- segment containing the data
#   	    	off 	- offset to the data
#   	    	t   	- type of the data
# CALLED BY:	pparams
# RETURN:	str 	- formatted data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/ 5/91	Initial Revision
#
##############################################################################
[var data-handlers {
    {EMPTY  	get-empty}
    {TEXT   	get-text}
    {NUMBER 	get-number}
}]

[defsubr get-data {seg off t}
{
    global data-handlers

    var rout [cdr [assoc [var data-handlers] $t]]

    return [$rout $seg $off]
}]

##############################################################################
#				get-empty
##############################################################################
#
# SYNOPSIS:	Format an empty parameter
# PASS:		seg, off    - segment and offset of the data
# CALLED BY:	get-data
# RETURN:	str 	    - formatted data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/ 5/91	Initial Revision
#
##############################################################################
[defsubr get-empty {seg off}
{
    return {<none>}
}]

##############################################################################
#				get-text
##############################################################################
#
# SYNOPSIS:	Format a text parameter
# PASS:		seg, off    - segment and offset of the data
# CALLED BY:	get-data
# RETURN:	str 	    - formatted data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/ 5/91	Initial Revision
#
##############################################################################
[defsubr get-text {seg off}
{
    var str {"}
    
    do {
	var c [value fetch $seg:$off [type byte]]
	if {$c != 0} {
	    var str [format {%s%c} $str $c]
	}
	var off [expr $off+1]
    } while {$c != 0}

    var str [format {%s"} $str]

    return $str
}]

##############################################################################
#				get-number
##############################################################################
#
# SYNOPSIS:	Format a number parameter
# PASS:		seg, off    - segment and offset of the data
# CALLED BY:	get-data
# RETURN:	str 	    - formatted data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/ 5/91	Initial Revision
#
##############################################################################
[defsubr get-number {seg off}
{
    var f [value fetch $seg:$off [sym find type FloatNum]]

    return [format-float $f]
}]

