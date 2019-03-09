##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	putils.tcl
# FILE: 	putils.tcl
# AUTHOR: 	Gene Anderson, Sep 14, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	pluralize   	    	construct correct plural form of a word
#   	psize	    	    	print the size of a structure
#   	pbitmap	    	    	print a generic bitmap

# UTILS:
# 	Name			Description
#	----			-----------
#   	size	    	    	return the size of a structure
#   	issubset    	    	see if bits are subset of other bits
#   	getbitvalue 	    	get value for named bit field
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
# DESCRIPTION:
#	Various utilities for printing out structures, sizes, et al.
#
#	$Id: putils.tcl,v 1.3 90/10/11 20:04:14 gene Exp $
#
###############################################################################

##############################################################################
#				psize
##############################################################################
#
# SYNOPSIS:	print the size of the passed structure.
# PASS:		$struc - structure to find size of
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcommand psize {struc} output
{Prints the size of the passed structure.}
{
    	var size [size $struc]
	echo [format {size(%s) = 0x%x (%d) %s} $struc $size $size [pluralize byte $size]]
}]

##############################################################################
#				size
##############################################################################
#
# SYNOPSIS:	Return the size of a structure.
# PASS:		$type - type of stucture to size
# RETURN:	$val - size of structure in bytes
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	10/11/90	Initial Revision
#
##############################################################################

[defsubr size {type}
{
    return [type size [symbol find type $type]]
}]

##############################################################################
#				issubset
##############################################################################
#
# SYNOPSIS:	Return if a set of bits is a subset of another set of bits
# PASS:		$set - set to check membership in
#   	    	$subset - set to check for being a subset
# RETURN:	non-zero if is a subset
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	10/11/90	Initial Revision
#
##############################################################################

[defsubr issubset {set subset}
{
    return [expr {!(($set&$subset)^$subset)}]
}]

##############################################################################
#				getbitvalue
##############################################################################
#
# SYNOPSIS:	Return numeric value for a bit in a record.
# PASS:		$recType - record name (eg. TextStyles)
#   	    	$bit - bit to return value of (eg. ST_ITALIC)
# RETURN:	$val - value of bit in record
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	10/10/90	Initial Revision
#
##############################################################################

[defsubr getbitvalue {recType bit}
{
    var r [type fields [sym find type $recType]]
    var val -1
    while {![null $r] && $val == -1} {
    	var field [index $r 0]
    	if {![string compare $bit [index $field 0]]} {
    	    var val [expr {(1<<[index $field 1])}]
    	}
    	var r [cdr $r]
    }
    return $val
}]

##############################################################################
#				pluralize
##############################################################################
#
# SYNOPSIS:	construct the correct plural form of a word
# PASS:		name - singular form of word
#   	    	number - quantity in question (1 or non-1)
# RETURN:	plural - correct form of word based on quantity
# STRATEGY
#   	A hacked series of special cases plus the general case of
#   	adding 's' at the end...
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defsubr pluralize {name number}
{
	if {![string compare $name is]} {
	    if {$number != 1} {
		return are
	    } else {
		return is
	    }
	}
	if {![string compare $name has]} {
	    if {$number != 1} {
		return have
	    } else {
		return has
	    }
	}
	if {![string compare $name entry]} {
	    if {$number != 1} {
		return entries
	    } else {
		return entry
	    }
	}
	if {$number != 1} {
	   return [format %ss $name s]
	} else {
	   return $name
	}
}]

##############################################################################
#				pbitmap
##############################################################################
#
# SYNOPSIS:	print generic bitmap
# PASS:     	$addr - ptr to bitmap
#   	    	$width - width of bitmap
#   	    	$height - height of bitmap
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defsubr printbyte {val}
{
    for {var i 0} {$i != 8} {var val [expr $val*2&0xff] i [expr $i+1]} {
	var foo [expr $val&0x80]
	if {$foo} {
	    echo -n {# }
	} else {
	    echo -n {. }
	}
    }
}]

[defcommand pbitmap {addr width height} output
{Prints out a generic, one bit-deep bitmap.  Takes three arguments:
a ptr to the bitmap data, the width and the height.}
{
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]
    var ptr	    [index $address 1]
    var bwidth	    [expr ($width+7)/8]

    echo -n {+}
    for {var col 0} {$col < $width} {var col [expr $col+1]} {
	echo -n {--}
    }
    echo {}
    for {var row 0} {$row < $height} {var row [expr $row+1]} {
	echo -n {|}
	for {var col 0} {$col < $bwidth} {var col [expr $col+1]} {
	    var foo [value fetch $seg:$ptr byte]
	    printbyte $foo
	    var ptr [expr $ptr+1]
	}
	echo {}
    }
    echo -n {+}
    for {var col 0} {$col < $width} {var col [expr $col+1]} {
	echo -n {--}
    }
    echo {}
}]

