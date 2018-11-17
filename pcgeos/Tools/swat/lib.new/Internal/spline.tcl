#############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
#PROJECT:	PC GEOS 
#MODULE:    	swat		
#FILE:		spline.tcl
#
#AUTHOR:	Chris Boyke
#
#REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CDB	5/91		Initial version
#
#ROUTINES:
#   	printChunkArray - print a general chunk array given the base
#   	    address and the element type.
#
#DESCRIPTION:	This file contains some TCL procedures to print the
#   	    	various data structures of the SPLINE object
#
#	$Id: spline.tcl,v 1.5 93/07/31 21:43:37 jenny Exp $
#
##############################################################################


##############################################################################
#	pointregs
##############################################################################
#
# SYNOPSIS:	Output a pair of registers as a point
# PASS:		regX, regY
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/ 2/92   	Initial Revision
#
##############################################################################
[defsubr    pointregs {regX regY} {

    echo [format {(%d, %d)} 
    	    [read-reg $regX]
    	    [read-reg $regY]]
}]


##############################################################################
#	mousewatch
##############################################################################
#
# SYNOPSIS:	Watch the mouse's interactions with the spline
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
#       chrisb 	12/ 1/92   	Initial Revision
#
##############################################################################
[defsubr    mousewatch {} {
    brk aset spline::SplineStartSelect {[echo START] [expr 0]} 
    brk aset spline::SplineDragSelect {[echo DRAG] [expr 0]} 
    brk aset spline::SplineEndSelect {[echo END] [expr 0]} 
}]


##############################################################################
#	points
##############################################################################
[defcommand points {{addr es:bp} {args}} lib_app_driver.spline 
{Usage:
    points [<address>] [<args>]

Examples:
    "points"	    	Print the spline points for the spline
    	    	    	whose instance data is at es:bp

    "points es:bp -n"	Print only the coordinates for the points
    	    	    	of the spline at es:bp.

    "points *ds:si -a"  Print the spline points at address *ds:si
Synopsis:
    Print the points of a spline

Notes:
    If no arguments are passed, or if es:bp is passed, then es:bp
    is assumed to be the Vis-level instance data of the spline 
    object.  Otherwise, the passed address is assumed to be a
    pointer to the Object, and the instance data is dereferenced
    accordingly.

    If passing the "-n" flag, you MUST pass an address for the spline.
    (So Sorry!)

See also:
   
}
{
    require carray-enum chunkarr.tcl

    if { [string first -a $args] != -1 } {
	var pointsAddr $addr
    } else {
	var pointsAddr  [spline-chunk VSI_points $addr]
    }

    carray-enum $pointsAddr	points-callback $args

}]


       
##############################################################################
#	pundo
##############################################################################
[defcommand    pundo {{addr es:bp} {args}} lib_app_driver.spline
{Usage:
    pundo [<address>]

Examples:
    "pundo"	    	Print the undo points for the spline
    	    	    	whose instance data is at es:bp

    "points es:bp -n"	Print only the coordinates for the points
    	    	    	of the spline at es:bp.

    "points *ds:si -a"  Print the undo array at address *ds:si
Synopsis:
    Print the points of a spline

Notes:
    If no arguments are passed, or if es:bp is passed, then es:bp
    is assumed to be the Vis-level instance data of the spline 
    object.  Otherwise, the passed address is assumed to be a
    pointer to the Object, and the instance data is dereferenced
    accordingly.

    If passing the "-n" flag, you MUST pass an address for the spline.
    (So Sorry!)

See also:

    Print the undo array
}

{
    require carray-enum chunkarr.tcl

    if { [string first -a $args] != -1 } {
	var pointsAddr $addr
    } else {
	var pointsAddr  [spline-chunk VSI_undoPoints $addr]
    }

    carray-enum $pointsAddr	undo-callback $args
}]

       
##############################################################################
#	pnew
##############################################################################
[defcommand    pnew {{addr es:bp} {args}} lib_app_driver.spline 
{Usage:
    pnew [<address>]

Examples:
    "pnew"	    	Print the new points for the spline
    	    	    	whose instance data is at es:bp

    "pnew *ds:si -a"  Print the undo array at address *ds:si

Synopsis:
    Print the list of "new" points

Notes:
    If no arguments are passed, or if es:bp is passed, then es:bp
    is assumed to be the Vis-level instance data of the spline 
    object.  Otherwise, the passed address is assumed to be a
    pointer to the Object, and the instance data is dereferenced
    accordingly.

    If passing the "-n" flag, you MUST pass an address for the spline.
    (So Sorry!)

See also:

    Print the undo array
}

{
    if { [string first -a $args] != -1 } {
	var pointsAddr $addr
    } else {
	var pointsAddr  [spline-chunk VSI_newPoints $addr]
    }

    pcarray -tSelectedListEntry $pointsAddr
}]

       
##############################################################################
#	psel
##############################################################################
[defcommand    psel {{addr es:bp} {args}} lib_app_driver.spline 
{Usage:
    psel [<address>]

Examples:
    "psel"	    	Print the new points for the spline
    	    	    	whose instance data is at es:bp

Synopsis:
    Print the list of "new" points

Notes:
    If no arguments are passed, or if es:bp is passed, then es:bp
    is assumed to be the Vis-level instance data of the spline 
    object.  Otherwise, the passed address is assumed to be a
    pointer to the Object, and the instance data is dereferenced
    accordingly.

See also:

}

{
    if { [string first -a $args] != -1 } {
	var pointsAddr $addr
    } else {
	var pointsAddr  [spline-chunk VSI_selectedPoints $addr]
    }

    pcarray -tSelectedListEntry $pointsAddr
}]




##############################################################################
#	parse-spline-addr
##############################################################################
#
# SYNOPSIS:	Return the address of the Vis instance data of the spline. 
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
#   If the caller passes "es:bp" then assume this points to the instance
#   data already.  Otherwise, assume it's an OPTR, and get the Vis
#   master-level instance data.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	3/20/92   	Initial Revision
#
##############################################################################
[defsubr    parse-spline-addr {addr} {

    if { [string c $addr -t] == 0 } {
	var addr [targetobj]
    }
    var address [addr-preprocess $addr seg off]
    if { [string compare $addr es:bp] == 0 } {
	return $address
    } else {
	var master [value fetch $seg:$off.ui::Vis_offset]
	return [addr-parse $seg:$off+$master]
    }

}]


##############################################################################
#	spline-chunk
##############################################################################
#
# SYNOPSIS:	Return the address of one of the spline's data chunks
# PASS:		name - name of chunk (spline's instance data)
#   	    	addr - address of spline instance data
# CALLED BY:	
# RETURN:	address of chunk
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	3/20/92   	Initial Revision
#
##############################################################################
[defsubr spline-chunk {name addr} {

    var	address [parse-spline-addr $addr]

    var	seg [handle segment [index $address 0]]
    var off [index $address 1]

    var instance [value fetch $seg:$off [sym find type spline::VisSplineInstance]]
    var chunk [field $instance $name]

    var seg [spline-lmem-block $addr]

    return *$seg:$chunk
}]

##############################################################################
#	spline-lmem-block
##############################################################################
#
# SYNOPSIS:	Return the lmem block of the spline object
# PASS:		addr - address of spline
# CALLED BY:	
# RETURN:	lmem block containing spline points.
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	5/13/92   	Initial Revision
#
##############################################################################
[defsubr    spline-lmem-block {addr} {

    var	address [parse-spline-addr $addr]

    var han [handle id [index $address 0]]
    var	seg [handle segment [index $address 0]]
    var off [index $address 1]

    var instance [value fetch $seg:$off [sym find type VisSplineInstance]]

    return ^h[field $instance VSI_lmemBlock]

}]
      
      
###############################################################################
#   	printSplineChunkArray	
###############################################################################
#
#DESCRIPTION:	Print one of the chunk arrays belonging to a VisSpline 
#   	    	object 
#
#PASS:	    name: field in the spline that holds the chunk array handle
#   	    type: data type of each field in the chunk array
#
#RETURN:    nothing
#
#KNOWN BUGS/SIDE EFFECTS/IDEAS:	
#
#REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CDB	5/91		Initial version
#
###############################################################################
       
[defsubr printSplineChunkArray {name type addr} {
       pcarray -t$type [spline-chunk $name $addr]
       
}]

##############################################################################
#	undo-callback
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
#	cdb 	5/13/92   	Initial Revision
#
##############################################################################
[defsubr    undo-callback {elementNum elementAddr elementSize extra} {

    var address [addr-parse $elementAddr]
    var	seg [handle segment [index $address 0]]
    var off [index $address 1]

    echo -n [value fetch $seg:$off [type word]]
    var off [expr $off+2]
    print-spline-point-struct $seg:$off
    return 0
}]

##############################################################################
#	points-callback
##############################################################################
#
# SYNOPSIS:	callback routine to print a SplinePointStruct structure
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
#	cdb 	3/20/92   	Initial Revision
#
##############################################################################
[defsubr    points-callback {elementNum elementAddr elementSize extra} {

    echo -n $elementNum
    print-spline-point-struct $elementAddr
    return 0
}]


##############################################################################
#	print-spline-point-struct
##############################################################################
#
# SYNOPSIS:	Display a SplinePointStruct
# PASS:		addr - address of point
# CALLED BY:	points-callback
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	5/13/92   	Initial Revision
#
##############################################################################
[defsubr    print-spline-point-struct {addr} {


    var sps [value fetch $addr [sym find type SplinePointStruct]]

    echo -n [format-PointWBFixed $addr.SPS_point]

    var info [field $sps SPS_info]
    var common [field $info PI_common]
    var isControl [field $common PIF_CONTROL]

    if {[string compare $extra -n ] != 0} {

    	echo -n {   }

    	if ($isControl)    {
	    var control [field $info PI_control]
	    pflag $control CPIF_PREV PREV NEXT
	    pflag $control CPIF_CONTROL_LINE LINE {}

     	} else {
	    echo -n {ANCHOR}
	    var anchor [field $info PI_anchor]
	    pflag $anchor APIF_HOLLOW_HANDLE HOLLOW {}
	    pflag $anchor APIF_IM_CURVE IM_CURVE {}
	    pflag $anchor APIF_SELECTED SELECTED {}
	    echo -n {  }
	    echo -n [type emap [field $anchor APIF_SMOOTHNESS] 
	    	    	    	[sym find type SmoothType]]
    	}

	pflag $common PIF_FILLED_HANDLE FILLED {}
	pflag $common PIF_TEMP TEMP {}
    	# print a newline 
    	echo

    }
    echo

}]


	
[defcommand psc {{addr es:bp}} lib_app_driver.spline
{}
{
	_print ScratchData [spline-chunk VSI_scratch $addr]
}]
	


	  
	  
	  

##############################################################################
#	pflag
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
#	cdb 	3/20/92   	Initial Revision
#
##############################################################################
[defsubr    pflag {record fldname true false} {

    if ([field $record $fldname]) {
	echo -n [format {  %s} $true]
    } else {
	if { ![null $false] } {
	    echo -n	[format {  %s} $false]
	}
    }


}]

##############################################################################
#	format-PointWBFixed
##############################################################################
#
# SYNOPSIS:	return a formatted string that's a WBFixed number
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
#       chrisb 	12/17/92   	Initial Revision
#
##############################################################################
[defsubr    format-PointWBFixed {addr} {

    var x [value fetch $addr.PWBF_x]
    var y [value fetch $addr.PWBF_y]
    return [format {   (%.3f, %.3f)}
	[expr [normalize $x WBF_int 65536]+[field $x WBF_frac]/256 f]
	[expr [normalize $y WBF_int 65536]+[field $y WBF_frac]/256 f]
	]
}]
	  
