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
#   	pdata	    	    	Print a chart data block
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	11/ 5/91	Initial revision
#
# DESCRIPTION:
#	Code to print out the chart parameter block.
#
#	$Id: pblk.tcl,v 1.2.12.1 97/03/29 11:25:00 canavese Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# Various requirements
#
require	format-float fp

##############################################################################
#	print-datablock-header
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
#	cdb 	6/ 5/92   	Initial Revision
#
##############################################################################
[defsubr    print-datablock-header {han seg} {
    #
    # Print information about the basic block
    #

    var hdr 	 [value fetch $seg:0 [sym find type ChartData]]
    var nRows	 [field $hdr CD_nRows]
    var nColumns [field $hdr CD_nColumns]

    echo [format {Chart Parameters %d bytes at ^h%04xh}
			[field $hdr CD_endOfData]
    	    	    	$han] 
    echo [format {Contains %d Rows, %d Columns  (%d cells total)}
			$nRows
			$nColumns
			[expr $nRows*$nColumns]]

}]


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
[defcommand pparams {{address {ds:0}}} lib_app_driver.chart
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
    var addr [get-pblk-address $address]

    var han  [handle id [index $addr 0]]
    var seg  ^h$han
    
    var hdr 	 [value fetch $seg:0 [sym find type ChartData]]
    var nRows	 [field $hdr CD_nRows]
    var nColumns [field $hdr CD_nColumns]

    print-datablock-header $han $seg

    #
    # Print out each of the entries
    #
    echo { ROW   COLUMN  OFFSET  SIZE   TYPE   DATA}
    echo {-----  ------  ------  ----  ------  ----}

    var cur  [type size [sym find type ChartData]]
    var cdct [sym find type ChartDataCellType]

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
    	    	var next    [field $hdr CD_endOfData]

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
		var tnum [type emap [value fetch $seg:$off $cdct] $cdct]
		var t [range $tnum 5 end chars]

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
#	get-pblk-address
##############################################################################
#
# SYNOPSIS:	Return the address of the parameters block based on
#    	    	the passed address
#
# PASS:		address - address of chart block
# CALLED BY:	
# RETURN:	address token of params block
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	12/23/91	    Initial Revision
#
##############################################################################
[defsubr    get-pblk-address {address} {

    var addr [addr-preprocess $address seg off]
    var han [handle id [index $addr 0]]

    var vmfile [value fetch kdata:$han.HM_owner ]
    var vmblock [value fetch (*$seg:1eh).CGI_data]

    echo $vmfile
    echo $vmblock

    return [addr-parse [format { ^v%04xh:%04xh } $vmfile $vmblock]]

}]


##############################################################################
#				get-data
##############################################################################
#
# SYNOPSIS:	Get data for a chart data cell
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


##############################################################################
#	pdup
##############################################################################
#
# SYNOPSIS:	Print the duplicates
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
#	cdb 	12/23/91	    Initial Revision
#
##############################################################################
[defcommand    pdup {{address ds:0}} lib_app_driver.chart 
{
Usage:
    pdup [<address>]
Synopsis:
    Print the duplicates for a chart parameters block.
Notes:
    * If you give no address argument, ds:0 is used.
}
{


    var addr [get-pblk-address $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]

    print-datablock-header $han $seg


    var hdr 	 [value fetch $seg:0 [sym find type ChartData]]
    var nRows	 [field $hdr CD_nRows]
    var nColumns [field $hdr CD_nColumns]
    var endOfData [field $hdr CD_endOfData]

    var nCells [expr $nRows*$nColumns]
    for {var i 0} {$i < $nCells} {var i [expr $i+1]} {
    	var off [expr $i*10+$endOfData]
    	pfloat $seg:$off
    }    

}]

