##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
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
#   	pncbitmap    	    	print a generic uncompacted bitmap
#	pcbitmap		print out a generic packbits-compacted bitmap
#
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
#	$Id: putils.tcl,v 1.16 94/02/09 12:19:58 jimmy Exp $
#
###############################################################################

##############################################################################
#				psize
##############################################################################
#
# SYNOPSIS:	print the size of the passed structure.
# PASS:		$struct - structure to find size of
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcommand psize {struct} print
{Usage:
    psize <structure>

Examples:
    "psize FontsInUseEntry"

Synopsis:
    Print the size of the passed structure.

See also:
    prsize.
}
{
    	var size [size $struct]
	echo [format {size(%s) = %xh (%d) %s} $struct $size $size [pluralize byte $size]]
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
    var t [symbol find type $type]
    if {[null $t]} {
	var t [type $type]
    }
    return [type size $t]
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
# PASS:		$recType - record name (eg. TextStyle)
#   	    	$bit - bit to return value of (eg. TS_ITALIC)
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
    [case $name in
     is {
	    if {$number != 1} {
		return are
	    } else {
		return is
	    }
	}
     has {
	    if {$number != 1} {
		return have
	    } else {
		return has
	    }
	}
     entry {
	    if {$number != 1} {
		return entries
	    } else {
		return entry
	    }
	}
     default {
	if {$number != 1} {
	   return ${name}s
	} else {
	   return $name
	}
     }
    ]
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

[defsubr printbyte {set unset val {width 8}}
{
    for {var i 0} {$i != 8 && $width > $i} {var val [expr $val*2&0xff] i [expr $i+1]} {

	var foo [expr $val&0x80]
	if {$foo} {
	    echo -n $set
	} else {
	    echo -n $unset
	}
    }
}]

[defcmd pncbitmap {addr width height {nospace nil}} lib_app_driver.bitmap
{Usage:
    pncbitmap <address> <width> <height> [<no space flag>]

Examples:
    "pncbitmap *ds:si 64 64 t"	print the bitmap without spaces

Synopsis:
    Print out a one bit-deep noncompacted bitmap.

Notes:
    * The address argument is the address to the bitmap data.

    * The width argument is the width of the bitmap in pixels.

    * The height argument is the height of teh bitmap in pixels.

    * The space flag argument removes the space normally printed 
      between the pixels.  Anything (like 't') will activate the flag.

See also:
    pcbitmap.
}
{
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]
    var ptr	    [index $address 1]
    var bwidth	    [expr ($width+7)/8]

    if {[null $nospace]} {
    	var set {# } unset {. } hdr {--}
    } else {
    	var set {#} unset {.} hdr {-}
    }

    echo -n {+}
    for {var col 0} {$col < $width} {var col [expr $col+1]} {
	echo -n $hdr
    }
    echo {+}

    for {var row 0} {$row < $height} {var row [expr $row+1]} {
        var w $width
	echo -n {|}
	for {var col 0} {$col < $bwidth} {var col [expr $col+1]} {
	    var foo [value fetch $seg:$ptr byte]
	    printbyte $set $unset $foo $w
	    var ptr [expr $ptr+1]
    	    var w [expr $w-8]
	}
	echo {|}
    }

    echo -n {+}
    for {var col 0} {$col < $width} {var col [expr $col+1]} {
	echo -n $hdr
    }
    echo {+}
}]

[defsubr pCRow {bwidth seg ptr printfunc}
{
    for {var col 0} {$col < $bwidth} {} {
	var foo [value fetch $seg:$ptr byte]
	if {[expr $foo&0x80]} {
	    var n [expr 257-$foo]
	    var rept [value fetch $seg:$ptr+1 byte]

	    for {var i 0} {$i < $n} {var i [expr $i+1]} {
		eval [concat $printfunc $rept]
	    }
	    var ptr [expr $ptr+2]
	} else {
	    var n [expr $foo+1]

	    for {var i 0} {$i < $n} {var i [expr $i+1]} {
		eval [concat $printfunc [value fetch $seg:$ptr+$i+1 byte]]
	    }
	    var ptr [expr $ptr+1+$n]
	}
	var col [expr $col+$n]
    }

    return $ptr
}]

[defsubr pNCRow {bwidth seg ptr printfunc}
{
    for {var col 0} {$col < $bwidth} {var col [expr $col+1]} {
    	eval [concat $printfunc [value fetch $seg:$ptr+$col byte]]
    }

    return [expr $ptr+$col]
}]

[defcmd pcbitmap {addr width height {nospace nil}} lib_app_driver.bitmap
{Usage:
    pcbitmap <address> <width> <height> [<no space flag>]

Examples:
    "pcbitmap *ds:si 64 64 t"	print the bitmap without spaces

Synopsis:
    Print out a one bit-deep packbits-compacted bitmap.

Notes:
    * The address argument is the address to the bitmap data.

    * The width argument is the width of the bitmap in pixels.

    * The height argument is the height of the bitmap in pixels.

    * The space flag argument removes the space normally printed 
      between the pixels.  Anything (like 't') will activate the flag.

See also:
    pncbitmap.
}
{
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]
    var ptr	    [index $address 1]
    var bwidth	    [expr ($width+7)/8]

    if {[null $nospace]} {
    	var set {# } unset {. } hdr {--}
    } else {
    	var set {#} unset {.} hdr {-}
    }

    echo -n {+}
    for {var col 0} {$col < $width} {var col [expr $col+1]} {
	echo -n $hdr
    }
    echo {}
    for {var row 0} {$row < $height} {var row [expr $row+1]} {
	echo -n {|}
	var ptr [pCRow $bwidth $seg $ptr [concat printbyte $set $unset]]
	echo {}
    }
    echo -n {+}
    for {var col 0} {$col < $width} {var col [expr $col+1]} {
	echo -n $hdr
    }
    echo {}
}]

