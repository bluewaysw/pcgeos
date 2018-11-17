
##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	pscript.tcl
# AUTHOR: 	Jim DeFrisco
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	psstack			print out PostScript execution stack
#
#	$Id: pscript.tcl,v 1.5.12.1 97/03/29 11:25:12 canavese Exp $
#
###############################################################################

##############################################################################
#				psstack
##############################################################################
#
# SYNOPSIS:	print a PostScript execution stack
# PASS:		$addr - address of PSStack block (defaults to ds)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	9/3/91		Initial Revision
#
##############################################################################

[defcmd psstack {{length 400} {addr nil}} lib_app_driver.postscript
{Usage:
    psstack [<length>] [<address>]

Examples:
    "psstack"		lists all the elements on the stack
    "psstack 10"	lists the top 10 elements on the stack
    "psstack 1 es:0"	lists the top element on the stack, PSState at es:0

Synopsis:
    Dump the PostScript interpreters' execution stack

Notes:
    * This is only really useful inside the PostScript interpreter code

See also:

}
{
    #
    # Set various variables that will be needed.
    #
    var address     [get-address $addr ds:0]
    var address     [addr-parse $address]
    var	seg	    ^h[handle id [index $address 0]]
    var offset	    [index $address 1]
    var xstack      [value fetch $seg:$offset.PSS_xstack [type word]]
    var	xstack	    [value fetch $seg:$xstack [type word]]
    var	xsp	    [value fetch $seg:$offset.PSS_xsp [type word]]
    var	xsptr	    [expr $xsp+$xstack]

    #
    # before we get too far, make sure we really have a PSState block...
    #
    [if {([value fetch $seg:LMBH_offset] != (([size PSState]+3)&~3)) ||
	 [string c [type emap [value fetch $seg:LMBH_lmemType]
			    [if {[not-1x-branch]}
				{sym find type LMemType}
				{sym find type LMemTypes}]]
		    LMEM_TYPE_GENERAL] != 0}
    {
	#
	# Either the offset to the start of the heap, which should
	# be big enough to hold a PSState and no more (after accounting
	# for the rounding-to-a-longword the lmem code performs), is
	# wrong, or the lmemType of the block is not LMEM_TYPE_GENERAL.
	#
	# Both of these crimes indicate the address we've been given is
	# not that of a PSState
	#
	echo {Error: address passed does not point to PSState block}
    }]
	

    #
    # limit the number of objects we spit out the the number available
    #
    var cstack [expr $xsp/[size PSObject]]

    if {$length > $cstack} {
	var length $cstack
	}
    echo {PostScript execution stack:}
    #
    # for each desired object, print out it's type and value
    #
    for {var objc 0} {$objc < $length} {var objc [expr $objc+1]} {
	var xsp [expr $xsp-[size PSObject]]
	var xsptr [expr $xstack+$xsp]
	if {$objc == 0} {
	    echo -n {top object:}
	    } else {
	    echo -n [format {     %4d:} $objc]
	    }
	var dtype [value fetch $seg:$xsptr.PSO_type [type byte]]
	var dtype [penum PSDataType $dtype]
	echo -n [format {\t %s, } $dtype]
	[case $dtype in
	 PSDT_BOOLEAN {
	     var objvalue [value fetch $seg:$xsptr.PSO_value [type word]]
	     var objvalue [penum PSBoolean $objvalue]
	     echo $objvalue
	     }
	 PSDT_FONTID {
	     var objvalue [value fetch $seg:$xsptr.PSO_value [type word]]
	     var objvalue [penum FontID $objvalue]
	     echo $objvalue
	     }
	 PSDT_INT {
	     var objvalue [value fetch $seg:$xsptr.PSO_value [type word]]
	     if {$objvalue > 32767} {
		 var objvalue [expr $objvalue-65536]
		 }
	     echo [format {%5d} $objvalue]
	     }
	 {PSDT_MARK PSDT_NULL} {
	     echo 
	     }
	 PSDT_OPERATOR {
	     var objvalue [value fetch $seg:$xsptr.PSO_value [type word]]
	     var objvalue [penum PSOperator $objvalue]
	     echo $objvalue
	     }
	 PSDT_NAME {
	     var objvalue [value fetch $seg:$xsptr.PSO_value [type word]]
	     var dict [value fetch $seg:PSS_dict [type word]]
	     var dict [value fetch $seg:$dict [type word]]
	     var valptr [expr $dict+$objvalue]
	     var valptr [value fetch $seg:$valptr.PSDE_name [type word]]
	     var valptr [value fetch $seg:$valptr [type word]]
	     echo -n {/}
	     ppsstring $seg:$valptr 0
	     echo
	     }
	 PSDT_REAL {
	     var valptr [value fetch $seg:$xsptr.PSO_value [type word]]
	     var valptr [value fetch $seg:$valptr [type word]]
	     pdwfixed $seg:$valptr 
	     }
	 PSDT_ARRAY {
	     echo Array
	     }
	 PSDT_STRING {
	     var objvalue [value fetch $seg:$xsptr.PSO_value [type word]]
	     var valptr [value fetch $seg:$objvalue [type word]]
	     ppsstring $seg:$valptr 1
	     }
	 default {
	     echo {unsupported type}
	     }]
	}

}]

##############################################################################
#				pspath
##############################################################################
#
# SYNOPSIS:	print the current PostScript path
# PASS:		$addr - address of PSStack block (defaults to ds)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	9/3/91		Initial Revision
#
##############################################################################

[defcmd pspath {{addr nil}} lib_app_driver.postscript
{Usage:
    pspath [<address>]

Examples:
    "pspath"		lists all the elements of the current path
    "psstack es:0"	lists the path elements, PSState at es:0

Synopsis:
    Dump the PostScript interpreters' current path

Notes:
    * This is only really useful inside the PostScript interpreter code

See also:

}
{
    #
    # Set various variables that will be needed.
    #
    var address     [get-address $addr ds:0]
    var address     [addr-parse $address]
    var	seg	    ^h[handle id [index $address 0]]
    var offset	    [index $address 1]
    var point       [value fetch $seg:$offset.PSS_path [type word]]
    var	point	    [value fetch $seg:$point [type word]]
    var	pcount	    [value fetch $seg:$offset.PSS_pcount [type word]]

    #
    # before we get too far, make sure we really have a PSState block...
    #
    [if {([value fetch $seg:LMBH_offset] != (([size PSState]+3)&~3)) ||
	 [string c [type emap [value fetch $seg:LMBH_lmemType]
			    [if {[not-1x-branch]}
				{sym find type LMemType}
				{sym find type LMemTypes}]]
		    LMEM_TYPE_GENERAL] != 0}
    {
	#
	# Either the offset to the start of the heap, which should
	# be big enough to hold a PSState and no more (after accounting
	# for the rounding-to-a-longword the lmem code performs), is
	# wrong, or the lmemType of the block is not LMEM_TYPE_GENERAL.
	#
	# Both of these crimes indicate the address we've been given is
	# not that of a PSState
	#
	echo {Error: address passed does not point to PSState block}
    }]
	

    #
    # limit the number of objects we spit out the the number available
    #
    echo {current PostScript path:}
    #
    # for each point, print out the coords
    #
    var nline 5
    var npts 0
    for {var objc 0} {$objc < $pcount} {var objc [expr $objc+1]} {
	if {$point == 0} {
	    echo {Bad path -- terminated early}
	} else {
	    if {$nline == 5} {
		echo {}
		echo -n [format {%4d: } $npts]
		var nline 1
		} else { 
		var nline [expr $nline+1]
		}
	    var xcoord [value fetch $seg:$point.PSPP_coord.P_x [type word]]
	    var ycoord [value fetch $seg:$point.PSPP_coord.P_y [type word]]
	    echo -n [format {(%d,%d)   } $xcoord $ycoord]
	    var point  [value fetch $seg:$point.PSPP_next [type word]]
	    var point  [value fetch $seg:$point [type word]]
	    var npts [expr $npts+1]
	}
    }
    echo {}
}]

[defsubr pwwfixed {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]
    var frac [value fetch $s:$o [type word]]
    var intgr [value fetch $s:$o+2 [type short]]
    if {$intgr < 0} then {
	var normfrac [expr $intgr-$frac/65536 float]
    } else {
        var normfrac [expr $intgr+$frac/65536 float]
    }
    echo [format {%.4f} $normfrac]
}]

[defsubr pdwfixed {addr} 
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]
    var frac [value fetch $s:$o [type word]]
    var intgr [value fetch $s:$o+2 [type dword]]
    if {$intgr < 0} then {
	var normfrac [expr $intgr-$frac/65536 float]
    } else {
        var normfrac [expr $intgr+$frac/65536 float]
    }
    echo [format {%.4f} $normfrac]
}]

[defsubr ppsstring {addr quotes}  {
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    if {$quotes == 1} {
        echo -n "
	}
    [for {var c [value fetch $s:$o [type byte]]}
         {$c != 0}
	 {var c [value fetch $s:$o [type byte]]}
    {
	  echo -n [format %c $c]
	  var o [expr $o+1]
    }]
    if {$quotes == 1} {
        echo "
	} else {
	echo
	}
}]

