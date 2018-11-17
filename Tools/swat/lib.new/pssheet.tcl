##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	pssheet.tcl
# FILE: 	pssheet.tcl
# AUTHOR: 	Gene Anderson, May 19, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/19/92		Initial Revision
#
# DESCRIPTION:
#	TCL commands for debugging spreadsheet object structures
#
#	$Id: pssheet.tcl,v 1.28.12.1 97/03/29 11:26:40 canavese Exp $
#
###############################################################################

[defsubr {fmtstruct-RefElementHeader} {type val offset space}
{
    var high [field [field $val REH_refCount] WAAH_high]
    var low [field [field $val REH_refCount] WAAH_low]
    if {$high == 0xff} {
    	echo -n {not in use}
    } else {
    	echo -n [expr $low+$high*65536]
    }
    return 1
}]

[defsubr {fmtstruct-AreaInfo} {type val offset space}
{
    var color [field $val AI_color]
    var red [field $color CQ_redOrIndex]
    if {[field $color CQ_info]==[getvalue CF_INDEX]} {
    	echo -n [penum Color $red]
    } else {
    	var green [field $color CQ_green]
    	var blue [field $color CQ_blue]
    	echo -n [format {R=%d, G=%d, B=%d} $red $green $blue]
    }
    echo -n [format {,\t%s} [penum SystemDrawMask [field $val AI_grayScreen]]]
    return 1
}]

[defsubr {fmtstruct-ColorQuad} {type val offset space}
{
    var red [field $val CQ_redOrIndex]
    if {[field $val CQ_info]==[getvalue CF_INDEX]} {
    	echo -n [penum Color $red]
    } else {
    	var green [field $val CQ_green]
    	var blue [field $val CQ_blue]
    	echo -n [format {R=%d, G=%d, B=%d} $red $green $blue]
    }
    return 1
}]

##############################################################################
#				_pcellrange
##############################################################################
#
# SYNOPSIS:	Print a cell reference in the form AB123
# PASS:		range - CellRange
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/17/92		Initial Revision
#
##############################################################################

[defsubr _pcellrange {range}
{
    var old-sd [sym-default]
    sym-default parse
    var start [field $range CR_start]
    var end [field $range CR_end]

    if {[recordfield [field $start CR_row] CRC_VALUE] >= 0x7fff} {
    	echo -n {nil}
    } else {
        _pcellref $start
        echo -n {:}
        _pcellref $end
    }
    sym-default ${old-sd}
}]

##############################################################################
#				_pcellref
##############################################################################
#
# SYNOPSIS:	Print a cell reference in the form AB123
# PASS:		ref - CellReference
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/17/92		Initial Revision
#
##############################################################################

[defsubr _pcellref {ref}
{
    var old-sd [sym-default]
    sym-default parse

    var row [recordfield [field $ref CR_row] CRC_VALUE]
    var col [recordfield [field $ref CR_column] CRC_VALUE]
    var absRow  [recordfield [field $ref CR_row] CRC_ABSOLUTE]
    var absCol  [recordfield [field $ref CR_column] CRC_ABSOLUTE]

    if { $absCol } {
    	echo -n {$}
    }
    if {$col > 16384} {
    	var col [expr $col-32767]
    	if {$col < 0} {
    	    echo -n {-}
    	    var col [expr 0-$col]
    	}
    }
    while {$col > 25} {
        var c [expr $col/26]
        var col [expr $col%26]
    	echo -n [format {%c} [expr $c+64]]
    }
    echo -n [format {%c} [expr $col+65]]
    if { $absRow } {
    	echo -n {$}
    }
    if {$row > 16384} {
    	var row [expr $row-32767]
    	if {$row < 0} {
    	    echo -n {-}
    	    var row [expr 0-$row]
    	}
    }
    echo -n [format {%d} [expr $row+1]]
    sym-default ${old-sd}

}]

##############################################################################
#				print-rows
##############################################################################
#
# SYNOPSIS:	Print the row or column array
# PASS:		addr - address of array (eg. *segment:chunk)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	3/ 8/91		Initial Revision
#
##############################################################################

[defcommand print-rows {{addr}} lib_app_driver.spreadsheet
{Usage:
    print-rows <addr>
Synopsis:
    Prints out a spreadsheet row array list.
}
{
    #
    # Set various variables that will be needed.
    #
    var address	    [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]
    var offset	    [index $address 1]
    var	lsize	    [expr [value fetch $seg:$offset-2 word]-2]
    var lsize	    [expr $lsize+$offset]
    #
    # Print out the row array
    #
    for {} {$offset < $lsize} {var offset [expr $offset+[size RowArrayEntry]]} {
    	var row	   [field [value fetch $seg:$offset RowArrayEntry] RAE_row]
    	var height [field [value fetch $seg:$offset RowArrayEntry] RAE_height]
    	var base   [field [value fetch $seg:$offset RowArrayEntry] RAE_baseline]
    	if {$base >= 0x8000} {
    	    var	baseline [format {%d (automatic)} [expr $base-0x8000]]
    	} else {
    	    var baseline [format {%d} $base]
    	}
    	if {$height != 0xffff} {
    	    echo [format {row %4d: hgt = %3d, base = %s} $row $height $baseline]
    	}
    }
}]

##############################################################################
#				pssheet
##############################################################################
#
# SYNOPSIS:	Print information about a spreadsheet object
# CALLED BY:	user
# PASS:		addr	= address of spreadsheet object
#   	    	args	= List containing:
#   	    	    	    -i	: ADDR is pointer to instance data
#   	    	    	    -f	: Print information about associated file
#   	    	    	    <etc>
# RETURN:	nothing

# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/19/92		Initial Revision
#
##############################################################################

[defcommand pssheet {args} lib_app_driver.spreadsheet
{Usage:
    pssheet [-isSfrcvd] ADDR
    	-i: address is a pointer to the instance data
	-s: print out style attribute structures
    	-f: print out information about associated file
    	-r: print out row heights
    	-c: print out column widths
    	-v: print out visual and selection information
    	-d: print out document information
    	-R: print out recalculation information
    	-N: print out spreadsheet name information

Examples:
    pssheet -s ^l3ce0h:001eh	- print style attributes
    pssheet -f -i 94e5h:0057h	- print file info from instance data

Synopsis:
    Prints out information about a spreadsheet object

Notes:
    If you are in the middle of debugging a spreadsheet routine and have
    a pointer to the Spreadsheet instance, the "-i" flag can be used to
    specify the object using that pointer.

    If you simply have the OD of the spreadsheet object, use that.

    To find the OD of a spreadsheet object in GeoCalc, you can move the
    mouse over the view it is in, and type "vistree [content]", and one
    of the objects in the tree should be a spreadsheet object.

    Alternatively, you can do:
    	pssheet <flags> [targetobj]

See also:
    content, targetobj
}
{
    global geos-release

    if {${geos-release} < 2} {
    	error {pssheet only works in V2.0}
    }

    var default 1
    var attrs 0
    var	file 0
    var inst 0
    var rows 0
    var cols 0
    var visible 0
    var doc 0
    var recalc 0
    var names 0
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		i {var inst 1}
		s {var attrs 1 default 0}
    	    	f {var file 1 default 0}
    	    	r {var rows 1 default 0}
    	    	c {var cols 1 default 0}
    	    	v {var visible 1 default 0}
    	    	d {var doc 1 default 0}
    	    	R {var recalc 1 default 0}
    	    	N {var names 1 default 0}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }
    #
    # Get the address
    #
    if {[length $args] == 0} {
	var address *ds:si
    } else {
	var address [index $args 0]
    }
    var addr	[addr-parse $address]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]
    #
    # Figure out where the interesting parts are
    #
    if {$inst == 0} {
        var SSI [expr $off+[value fetch $seg:$off.ssheet::Spreadsheet_offset]]
    } else {
    	var SSI	$off
    	var off [value fetch $seg:$off.ssheet::SSI_chunk]
    	var off [value fetch $seg:$off word]
    }

    var bl [value fetch $seg:LMBH_handle]
    var ch [value fetch $seg:$SSI.ssheet::SSI_chunk]
    var label [value hstore [addr-parse ^l$bl:$ch]]
    echo [format {Spreadsheet object: (@%d, ^l%04xh:%04xh)} $label $bl $ch]
    echo [format {Spreadsheet instance: %04xh:%04xh} $seg $SSI]
    #
    # Collect commonly used information
    #
    var filehan [value fetch $seg:$SSI.ssheet::SSI_cellParams.CFP_file]
    var styleBlk [value fetch $seg:$SSI.ssheet::SSI_styleArray]
    var rowBlk	[value fetch $seg:$SSI.ssheet::SSI_rowArray]
    var formatBlk [value fetch $seg:$SSI.ssheet::SSI_formatArray]
    var nameBlk [value fetch $seg:$SSI.ssheet::SSI_nameArray]
    var maxRow [value fetch $seg:$SSI.ssheet::SSI_maxRow]
    var maxCol [value fetch $seg:$SSI.ssheet::SSI_maxCol]
    var aptr *{^v$filehan:$styleBlk}:[size LMemBlockHeader]
    echo {============================================================}
    #
    # Now for the output
    #
    if {$default || $file} {
    	echo [format {File:\t\t%04xh} $filehan]
    	echo [format {  Row array:\t %03xh} $rowBlk]
    	echo [format {  Name array:\t %03xh} $nameBlk]
    	echo [format {  Style array:\t %03xh} $styleBlk]
    	echo [format {  Format array:\t %03xh} $formatBlk]
        echo {============================================================}
    }
    if {$file} {
    	echo {Row Blocks:}
    	var rbllen [expr [size RowBlockList]/2]
    	var roff [index [addr-parse $SSI.ssheet::SSI_cellParams.CFP_rowBlocks] 1]
    	for {var i 0} {$i < $rbllen} {var i [expr $i+1]} {
    	    var rb [value fetch $seg:$roff word]
    	    if {$rb} {
    	    	echo [format {  %2d-%2d: %03xh} [expr $i*32] [expr $i*32+31] $rb]
    	    }
    	    var roff [expr $roff+2]
    	}
    }
    if {$attrs} {
    	pcarray -tssheet::CellAttrs $aptr
    	echo {============================================================}
    }
    if {$rows} {
    	print-rows *{^v$filehan:$rowBlk}:[size LMemBlockHeader]
        echo {============================================================}
    }
    if {$cols} {
    	print-rows *{^v$filehan:$rowBlk}:[expr [size LMemBlockHeader]+2]
        echo {============================================================}
    }
    if {$visible} {
    	echo [format {maximum (r,c)\t= (%d,%d)} $maxRow $maxCol]
    	echo -n {visible range	= }
    	_print $seg:$SSI.ssheet::SSI_visible
    	echo -n {current cell	= }
    	_print $seg:$SSI.ssheet::SSI_active
    	echo -n {selection	= }
    	_print $seg:$SSI.ssheet::SSI_selected
    	var col [value fetch $seg:$SSI.ssheet::SSI_offset.PD_x]
    	var row [value fetch $seg:$SSI.ssheet::SSI_offset.PD_y]
    	echo [format {(x,y) offset\t= (%d,%d)} $col $row]
        echo {============================================================}
    }
    if {$doc} {
    	echo -n {flags		= }
    	var row [value fetch $seg:$SSI.ssheet::SSI_flags word]
    	precord ssheet::SpreadsheetFlags $row 1
    	echo -n {draw flags	= }
    	var row [value fetch $seg:$SSI.ssheet::SSI_drawFlags word]
    	precord ssheet::SpreadsheetDrawFlags $row 1
    	echo -n {attributes	= }
    	var row [value fetch $seg:$SSI.ssheet::SSI_attributes byte]
    	precord ssheet::SpreadsheetAttributes $row 1
    	_print $seg:$SSI.ssheet::SSI_bounds
    	echo -n {header	    	= }
    	_print $seg:$SSI.ssheet::SSI_header
    	echo -n {footer	    	= }
    	_print $seg:$SSI.ssheet::SSI_footer
        echo {============================================================}
    }
    if {$recalc} {
    	_print $seg:$SSI.ssheet::SSI_circCount
    	_print $seg:$SSI.ssheet::SSI_converge
    	_print $seg:$SSI.ssheet::SSI_ancestorList
    	_print $seg:$SSI.ssheet::SSI_childList
    	_print $seg:$SSI.ssheet::SSI_finalList
        echo {============================================================}
    }
    if {$names} {
    	print-ssheet-names ^v$filehan:$nameBlk
        echo {============================================================}
    }
}]

##############################################################################
#				print-ssheet-names
##############################################################################
#
# SYNOPSIS:	Print the spreadsheet name array
# CALLED BY:	pssheet
# PASS:		address - address of name array
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/ 3/93	    Initial Revision
#
##############################################################################

[defsubr print-ssheet-names {address}
{
    var addr	[addr-parse $address]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]

    echo {spreadsheet names:}
    var defNames [value fetch $seg:$off.NH_definedCount]
    var undefNames [value fetch $seg:$off.NH_undefinedCount]
    echo [format {%d defined, %d undefined} $defNames $undefNames]
    var off [expr $off+[size NameHeader]]
    for {var i 0} {$i < [expr $defNames+$undefNames]} {var i [expr $i+1]} {
    	var ntoken [value fetch $seg:$off.NS_token]
    	var nlen [value fetch $seg:$off.NS_length]
    	var nflags [value fetch $seg:$off.NS_flags]
    	echo -n [format {#%d: "} $ntoken]
    	pstring $seg:$off+[size NameStruct] 1
    	echo -n {" }
    	var off [expr $off+$nlen+[size NameStruct]]
    	if {[field $nflags NF_UNDEFINED]} {
    	    echo {(undefined)}
    	} else {
    	    echo
    	}
    }
}]

##############################################################################
#	recordField
##############################################################################
#
# SYNOPSIS:	Return a field in a record, dealing with C stuff
#
# PASS:		
#
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#   	    First, try to get "field" to do the right thing. If that
#   	    doesn't work, then assume either:
#   	    1) "struct" is defined in C (integer), but "name" is a 
#   	       bitfield defined in ASM:
#   	    	     
#
#   	    2) Struct and Name are both defined in C
#   
#   
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	7/27/92   	Initial Revision
#
##############################################################################
[defsubr recordfield {struct name}
{

    var quick [field $struct $name]
    if {[null $quick]} {

	# See if $name is a bitfield
	
	var nsym [symbol find field $name]
	if {![null $nsym]} {
	    # It's a field, so convert the "position" and "width" 
	    # info to a value
	    var position [index [symbol get $nsym] 0]
	    var width [index [symbol get $nsym] 1]
	    var nValue [expr (2**$width-1)<<($position)]
	    return [expr ($struct&$nValue)>>($position)]
	} elif {![null [symbol find const $name]]} {
	    # name is a constant
	    var start [expr $struct&$name]
	    var i $name
	    
	    # Keep dividing by 2 until i is odd:

	    while {  ($start > 0) && ( $i & 1  == 0) } {
	    	var start [expr $start/2]
	    	var i [expr $i/2]
	    }
	    return $start
	} else {
	    return nil
	}
    } else {
	return $quick
    }
}]

##############################################################################
#				pcelldeps
##############################################################################
#
# SYNOPSIS:	Print dependencies for a cell in the spreadsheet
# PASS:		<filehan> - handle of file
#   	    	<addr> - address of CellCommon
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jeremy	7/31/92		Initial Revision
#
##############################################################################

[defcommand pcelldeps {args} lib_app_driver.spreadsheet
{Usage:
    pcelldeps <filehan> [<addr>]

Examples:
    pcelldeps	4be0h *es:di	- print dependencies of cell in file 4be0h

Synopsis:
    Prints dependencies for a cell in the spreadsheet

Notes:
    To find the OD of a spreadsheet object in GeoCalc, you can move the
    mouse over the view it is in, and type "vistree [content]", and one
    of the objects in the tree should be a spreadsheet object.

    If no address is given, *es:di is used.

See also:
    (mal)content, pcelldata
}
{
    require map-db-item-to-addr db.tcl

    var file [index $args 0]
    #
    # Get the address
    #
    if {[length $args] == 1} {
	var address *es:di
    } else {
	var address [index $args 1]
    }
    var addr	[addr-parse $address]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]
    #
    # Get the DB group and item
    #
    var group	[value fetch $seg:$off.DBGI_group]
    var item	[value fetch $seg:$off.DBGI_item]
    if {$group == 0} {
    	echo no dependencies
    }
    while {$group != 0} {
        #
        # Map the file, group and item to a ptr
        #
        var itemInfo    [map-db-item-to-addr $file $group $item]
        var itemSegment [index $itemInfo 2]
        var itemOffset  [index $itemInfo 4]
        var itemSize    [value fetch $itemSegment:$itemOffset-2 word]
    	#
    	# Get the next link in the chain, if any
    	#
    	var group	[value fetch $itemSegment:$itemOffset.DBGI_group]
    	var item	[value fetch $itemSegment:$itemOffset.DBGI_item]
        #
        # The size of the list is the size of the chunk (-2), minus
        # the size of a DBGroupAndItem, which is at the start of the
        # DB item, and is a link to the next dependency item, if any.
        #
        var listSize    [expr ($itemSize-2-[size DBGroupAndItem])/[size Dependency]]
        var itemOffset  [expr $itemOffset+[size DBGroupAndItem]]
        print Dependency $itemSegment:$itemOffset#$listSize
    }
}]

##############################################################################
#				pcelldata
##############################################################################
#
# SYNOPSIS:	Print data for a spreadsheet cell
# PASS:		PTR - ptr to CellCommon structure
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	8/10/92		Initial Revision
#
##############################################################################

[defcommand pcelldata {args} lib_app_driver.spreadsheet
{Usage:
    pcelldata [<addr>]

Examples:
    pcelldata	*es:di	- print cell data for cell at *es:di

Synopsis:
    Prints data for a spreadsheet data

Notes:
    To find the OD of a spreadsheet object in GeoCalc, you can move the
    mouse over the view it is in, and type "vistree [content]", and one
    of the objects in the tree should be a spreadsheet object.

    If no address is given, *es:di is used.

See also:
    content, pcelldeps
}
{
    require pstring pvm.tcl
    #
    # Get the address
    #
    if {[length $args] == 0} {
	var address *es:di
    } else {
	var address [index $args 0]
    }
    var addr	[addr-parse $address]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]
    #
    # Print various interesting things about the cell
    #
    if {[value fetch $seg:$off.CC_dependencies.segment]} {
    	echo {has dependencies}
    } else {
    	echo {no dependencies}
    }
    if {[value fetch $seg:$off.CC_notes.segment]} {
    	echo {has notes}
    } else {
    	echo {no notes}
    }
    echo [format {format token = %d} [value fetch $seg:$off.CC_attrs]]
    #
    # Figure out the cell type
    #
    var celltype [value fetch $seg:$off.CC_type]
    echo [format {cell type = %s} [penum CellType $celltype]]
    [case $celltype in
    	0 {pstring $seg:$off.CT_text}
    	2 {pfloat $seg:$off.CC_current}
    	4 { var rt [value fetch $seg:$off.CF_return]
    	    if {$rt == [getvalue RT_VALUE]} {
    	    	echo -n {current value = }
    	    	pfloat $seg:$off.CF_current
    	    } elif {$rt == [getvalue RT_TEXT]} {
    	    	echo -n {current text = }
    	    	var so [value fetch $seg:$off.CF_formulaSize]
    	    	pstring $seg:$off+$so+[size CellFormula]
    	    }
    	    echo {formula =}
    	    if {![null [info proc pexpr]]} {
            	pexpr $seg:$off.CF_formula
    	    }
    	  }
    	6 {}
    	8 {}
    	10 {}
    	12 {}
    	default {error [format {illegal cell type = %d} $celltype]}
    ]
}]

##############################################################################
#				print-eval-dep-list
##############################################################################
#
# SYNOPSIS:	print a dependency list used for evaluation
# PASS:		addr - address of dependency list start
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	3/ 3/93	Initial Revision
#
##############################################################################

[defcommand print-eval-dep-list {args} lib_app_driver.spreadsheet
{Usage:
    print-eval-dep-list [<addr>]

Examples:
    print-eval-dep-list	es:0	- print dependency list at es:0

Synopsis:
    Prints a dependency list used for evalulation

See also:
    content, pcelldeps
}
{
    require isbitset Extra/font.tcl
    #
    # Get the address
    #
    if {[length $args] == 0} {
	var address *es:di
    } else {
	var address [index $args 0]
    }
    var addr	[addr-parse $address]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]
    #
    # Get the size
    #
    var	dsize	[value fetch $seg:DB_size]
    var off 	[size DependencyBlock]
    while {$off < $dsize } {
    	var dtype   [value fetch $seg:$off EvalStackArgumentType]
    	var off [expr $off+[size EvalStackArgumentType]]
    	if {[isbitset ESAT_STRING $dtype]} {
    	    if {[isbitset ESAT_NUMBER $dtype]} {
    	    	print EvalFunctionData $seg:$off
    	    	var asize [size EvalFunctionData]
    	    } else {
    	    	if {[isbitset ESAT_RANGE $dtype]} {
    	    	    print EvalNameData $seg:$off
    	    	    var asize [size EvalRangeData]
    	    	} else {
    	    	    error {illegal dependency type}
    	    	}
    	    }
    	} else {
    	    if {[isbitset ESAT_RANGE $dtype]} {
    	    	print EvalRangeData $seg:$off
    	    	var asize [size EvalRangeData]
    	    } else {
    	    	error {illegal dependency type}
    	    }
    	}
    	var off [expr $off+$asize]
    }
}]
