##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	geode.tcl
# FILE: 	geode.tcl
# AUTHOR: 	Chris Boyke, Feb  4, 1994
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#      chrisb	2/ 4/94		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: geode.tcl,v 1.1 94/06/17 14:05:04 chrisb Exp $
#
###############################################################################


##############################################################################
#	pcore
##############################################################################
#
# SYNOPSIS:	Print out the variable-sized fields of a geode's core block
# PASS:		addr - address at which to print
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	2/ 4/94   	Initial Revision
#
##############################################################################
require getstring cwd

[defsubr    pcore {addr} {

    addr-preprocess $addr seg off

    echo
    echo [format {--- Core block for %s (^h%04xh) ---} 
	  [getstring $seg:GH_geodeName 8]
	  [value fetch $seg:GH_geodeHandle]]
    echo


    var geodeAttrs [value fetch $seg:GH_geodeAttr [sym find type GeodeAttrs]]

    # Imported libraries

    var libCount [value fetch $seg:GH_libCount]
    var libOffset [value fetch $seg:GH_libOffset]

    echo [format {Imported Libraries: %04xh} $libOffset]
    for { var i 0 } {$i < $libCount} {var i [expr $i+1]} {
	var han [value fetch $seg:[expr $libOffset+$i*2] [type word]]
	echo [format {^h%04xh (%s)}
	      $han 
	      [patient name [handle patient [handle lookup $han]]]]
    }


    # Exported library entries

    var exportCount [value fetch $seg:GH_exportEntryCount]
    var exportTab   [value fetch $seg:GH_exportLibTabOff]

    echo
    echo [format {Export Table: %04xh} $exportTab]
    for { var i 0 } {$i < $exportCount} {var i [expr $i+1]} {
	var expSeg [value fetch $seg:[expr $exportTab+$i*4+2] [type word]]
	var expOff [value fetch $seg:[expr $exportTab+$i*4] [type word]]

	if {[field $geodeAttrs GA_GEODE_INITIALIZED] || 
	    [field $geodeAttrs GA_XIP] } {
	    echo [format {segment: %04xh  offset: %04xh}
	      $expSeg
	      $expOff]
	} else {
	    
	    echo [format {ResId: %d  offset: 04xh}
		  $expSeg
		  $expOff]
	}
    }


    # Resources

    echo

    var resCount [value fetch $seg:GH_resCount]
    var resHandleOff [value fetch $seg:GH_resHandleOff]
    var resPosOff [value fetch $seg:GH_resPosOff]
    var resRelocOff [value fetch $seg:GH_resRelocOff]

    if {[field $geodeAttrs GA_GEODE_INITIALIZED] || 
	[field $geodeAttrs GA_XIP]} {
	echo [format {Resource Handle Table: %04xh} $resHandleOff]
	for { var i 0 } {$i < $resCount} {var i [expr $i+1] } {
	    var han [value fetch $seg:[expr $resHandleOff+$i*2] [type word]]
	    echo [format {%2d:  ^h%04xh (%04xh bytes)}
		  $i
		  $han
		  [expr [value fetch kdata:$han.HM_size]*16]]
	}
    } else {
	echo [format {Resource Size Table: %04xh} $resHandleOff]
	for { var i 0 } {$i < $resCount} {var i [expr $i+1] } {
	    var size [value fetch $seg:[expr $resHandleOff+$i*2] [type word]]
	    echo [format {%2d:  %04xh bytes}
		  $i
		  $size]
	}
    }
    echo
    echo [format {Resource Position Table: %04xh} $resPosOff]
    if { $resPosOff != 0} {
	for { var i 0 } {$i < $resCount} {var i [expr $i+1]} {
	    echo [format {%2d:  %08xh}
		  $i
		  [value fetch $seg:[expr $resPosOff+$i*4] [type dword]]]
	}
    }
    echo
    echo [format {Reloc Table Size Table: %04xh} $resRelocOff]
    if { $resRelocOff != 0 } {
	for { var i 0 } {$i < $resCount} {var i [expr $i+1]} {
	    echo [format {%2d:  %04xh}
		  $i
		  [value fetch $seg:[expr $resRelocOff+$i*2] [type word]]]
	}
    }

    # Extra libraries

    var libCount [value fetch $seg:GH_extraLibCount]
    var libOffset [value fetch $seg:GH_extraLibOffset]

    echo
    echo [format {Extra Libraries: %04xh} $libOffset]

    for { var i 0 } {$i < $libCount} {var i [expr $i+1]} {
	var han [value fetch $seg:[expr $libOffset+$i*2] [type word]]
	echo [format {^h%04xh (%s)}
	      $han
	      [patient name [handle patient [handle lookup $han]]]]
    }

	
}]

##############################################################################
#	geodeList
##############################################################################
#
# SYNOPSIS:	Print out the geode list
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
#       chrisb 	3/11/94   	Initial Revision
#
##############################################################################
[defsubr    geodewalk {} {
    for { var g [value fetch kdata::geodeListPtr] } {$g} { var g [value fetch ^h$g:GH_nextGeode] } {
	echo [format {^h%04xh (%s)}
	      $g
	      [patient name [handle patient [handle lookup $g]]]]
	}
}]
