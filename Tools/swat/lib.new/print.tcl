##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	print.tcl
# AUTHOR: 	Adam de Boor, Mar 29, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	print	    	    	Produces nice output from an address expr
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/29/89		Initial Revision
#
# DESCRIPTION:
#	Functions for format output nicely
#
#	$Id: print.tcl,v 3.72.4.1 97/03/29 11:27:58 canavese Exp $
#
###############################################################################
[defvar intFormat %xh swat_variable.output
{Usage:
    var intFormat <format-string>

Examples:
    "var intFormat %d"	Sets the default format for printing unsigned integers
			to decimal

Synopsis:
    $intFormat contains the string passed to the "format" command to print
    an integer.

Notes:
    * The default value is {%xh}, which prints the integer in hexadecimal,
      followed by an "h".

See also:
    print, byteAsChar.
}]

[defvar byteAsChar 0 swat_variable.output
{Usage:
    var byteAsChar (0|1)

Examples:
    "var byteAsChar 1"	Print byte variables as characters.

Synopsis:
    Determines how unsigned character variables are printed: if set non-zero,
    they are displayed as characters, else they are treated as unsigned
    integers.

Notes:
    * If $byteAsChar is 0, $intFormat is used

    * The default value for this variable is 0. It is mostly a hold-over from
      when we used MASM to develop and it had no "char" data type.

See also:
    intFormat, print
}]

[defvar alignFields 0 swat_variable.output
{Usage:
    var alignFields (0|1)

Examples:
    "var alignFields 1"	    Sets the "print" command to align the values for
    	    	    	    all the fields of a given structure.

Synopsis:
    Determines whether structure-field values follow immediately after the
    field name or if all values are indented to the same level.

Notes:
    * Having all values indented to the same level makes it easier for
      some people to locate a particular field in a structure. It is not
      without cost, however, in that Swat must determine the length of the
      longest field name before it can print anything.

    * The default value for this variable is 0.

See also:
    print
}]

[defvar dwordIsPtr 1 swat_variable.output
{Usage:
    var dwordIsPtr (1|0)

Examples:
    "var dwordIsPtr 1"	Tells "print" to print all double-word variables as
			if they were far pointers (segment:offset)

Synopsis:
    Controls whether dword (aka. long) variables are printed as 32-bit
    unsigned integers or untyped far pointers.

Notes:
    * For debugging C code, a value of 0 is more appropriate, while 1 is best
      for debugging assembly language.

    * The default value for this variable is 1.

See also:
    intFormat, print
}]

[defvar noStructEnum 1 swat_variable.output
{Usage:
    var noStructEnum (0|1)

Examples:
    "var noStructEnum 1"	Don't put "struct" or "enum" before the
				data type for variables that are structures
				or enums.

Synopsis:
    Structure fields that are structures or enumerated types normally have
    "struct" or "enum" as part of their type description. This usually
    just clutters up the display, however, so this variable shuts off this
    prepending.

Notes:
    * The default value of this variable is 1.

See also:
    print
}]

[defvar printRegions 1 swat_variable.output
{Usage:
    var printRegions (1|0)

Examples:
    "var printRegions 1"	If a structure contains a pointer to a region,
    	    	    	    	"print" will attempt to determine its
				bounding box.

Synopsis:
    Controls whether "print" parses regions to find their bounding rectangle.

Notes:
    * The default value for this variable is 1.

See also:
    print, condenseSpecial, condenseSmall.
}]

[defvar condenseSpecial 1 swat_variable.output
{Usage:
    var condenseSpecial (1|0)

Examples:
    "var condenseSpecial 0"	Turns off the special formatting of various
				types of structures by "print"

Synopsis:
    Controls the formatting of certain structures in more-intuitive ways
    than the bare structure fields.

Notes:
    * The default value of this variable is 1.

    * The current list of structures treated specially are:
    	Semaphore, Rectangle, OutputDescriptor, TMatrix, BBFixed,
	WBFixed, WWFixed, DWFixed, DFixed, WDFixed, DDFixed, FileDate,
	FileTime, FloatNum, SpecWinSizeSpec

See also:
    print, condenseSmall
}]

[defvar condenseSmall 1 swat_variable.output
{Usage:
    var condenseSmall (1|0)

Examples:
    "var condenseSmall 0"	Force even small structures to be printed
    	    	    	    	one field per line.

Synopsis:
    Controls whether "print" attempts to condense the output by printing
    small (< 4 bytes) structures (which are usually records in assembly
    language) as a list of <name> = <int>, where <name> is the field
    name and <int> is a signed integer.

Notes:
    * The default value for this variable is 1.

See also:
    print, condenseSpecial
}]

#
# isrecord
#	Decide if a given type is actually a record, returning 1 if so.
#	This is done by examining the number of bits and the type of the first
#	field in the type (it must be a structure type or an error will result)
#	If the two don't match, the type is a record (this is because the
#	type of each field in the record is declared to be a word).
#
#   	7/1/92: this used to check the first field for being a bitfield, dating
#   	back to the days of MASM etc. when we didn't have a "record" type. 
#   	Doing would cause a C structure that's got a couple bitfields as its
#   	first fields, but regular fields for everything else, to be
#   	misinterpreted as a record. -- ardeb
#
[defsubr isrecord {type}
{
    [if {([catch {sym type $type} stype] == 0) && 
    	 ([string c $stype record] == 0)}
    {
    	return 1
    } elif {([type size $type] <= 2) &&
	    ([string c [type class $type] struct] == 0)}
    {
    	var f1 [index [type fields $type] 0]
	return [expr {[type size [index $f1 3]]*8 != [index $f1 2]}]
    } else {
    	return 0
    }]
}]

#
# threadname
#   	Given a thread's handle ID, return its name in the form
#   	    <patient>:<#>
#
[defcommand threadname {thread} {thread print.utils}
{Usage:
    threadname <id>

Examples:
    "threadname 21c0h"	Returns the name of the thread whose handle id is 21c0h

Synopsis:
    Given a thread handle, produces the name of the thread, in the form
    <patient>:<n>

Notes:
    * If the handle is not one of those Swat knows to be for a thread, this
      returns the string "unknown".

See also:
    thread, patient.
}
{
    var t [mapconcat i [thread all] {
    	    if {$thread == [thread id $i]} {
	    	var i
    	    }
    }]

    if {[null $t]} {
    	return unknown
    } else {
    	return [patient name [handle patient [thread handle $t]]]:[thread number $t]
    }
}]

#
# makenegative
#   	Take a passed number and return the corresponding 32 bit signed
#   	number. If the number is positive, the result has a + sign at the
#	beginning. If the number can be considered negative, given its
# 	potential size, it has a - sign at the beginning.
#
[defsubr makenegative {num}
{
    [for {var m 0xff000000 sign 0x80000000 b 4}
	 {$b != 0}
	 {var m [expr $m>>8] sign [expr $sign>>8] b [expr $b-1]}
    {
	if {$num & $m} {
	    if {$num & $sign} {
		return [expr $num|$sign]
	    }
	    break
	}
    }]
    return +$num
}]


##############################################################################
#				fmtoptr
##############################################################################
#
# SYNOPSIS:	Format an object pointer nicely
# PASS:		h   = handle ID from the optr
#   	    	l   = chunk handle from the optr
# CALLED BY:	fmtstruct, fmtval
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 7/91		Initial Revision
#
##############################################################################
[defcommand fmtoptr {h c} print.utils
{Usage:
    fmtoptr <handle-id> <chunk>

Examples:
    "fmtoptr 3160h 0"	Prints a description of the object whose address is
    	    	    	^l3160h:0 (likely a thread/process).

Synopsis:
    Takes a global and a local handle and prints a description of the
    object described by that optr.

Notes:
    * No newline follows the optr description. You must perform an additional
      "echo" if that's all you want on the current output line.

    * If the global handle is a thread or a process, the thread's name (process
      thread for a process handle) and the chunk handle (as an additional word
      of data for the message) are printed.

    * If the global handle is a queue handle, the queue handle and the chunk
      handle are printed, with a note that the thing's a queue.
      
    * If the optr is for an object whose class can be gotten, the optr,
      full classname, and current far pointer are printed. In addition, if the
      chunk has its low bit set, the word "parent" is placed before the
      output, to denote that the optr likely came from a link and is the
      parent of the object containing the optr.

See also:
    print
}
{
    require print-obj-and-method object

    if {[catch {handle lookup $h} han]} {
	var han {}
    }

    [if {$h == 0xffff} {
	echo -n [format {^l%04xh:%04xh (Invalid)} $h $c]
    } elif {$h == 0} {
    	if {$c != 0} {
	    echo -n [format {Unconnected (chunk = %04xh)} $c]
	} else {
	    echo -n null
    	}
    } elif {![null $han] && ([handle state $han] & 0xf8000) != 0x30000} {
	if {[handle isthread $han]} {
	} elif {[handle owner $han] == $han} {
	} elif {([handle state $han] & 0xf8000) == 0x40000} {
	} elif {([handle state $han] & 0xc0) == 0x40} {
	} else {
	    #
	    # Must be an object, since it's not a thread,
	    # process, or queue. If the chunk handle has its low
	    # bit set, we've got a "parent" link.
	    #
	    if {$c & 1} {
		echo -n [format {parent }]
		var c [expr $c&~1]
	    }
	    if {[value fetch ^h$h:geos::LMBH_lmemType] != 2} {
	    	echo -n [format {^l%04xh:%04xh} $h $c]
		return
    	    }
	}
	print-obj-and-method $h $c -n
    } else {
	echo -n [format {^l%04xh:%04xh (Invalid)} $h $c]
    }]
}]

#
# fmtrecord
#	Format a record. If the record is nothing but flags, print out
#	the names of those fields whose flags are set.
#	If the record isn't all flags, at least don't print the (incorrect)
#	type of the field.
#
[defsubr fmtrecord {type val offset}
{
    global alignFields

    #
    # See if it's a flags record by making sure all fields that don't
    # contain UNUSED are a single bit.
    #
    var isFlags 1
    foreach i [type fields $type] {
	if {([index $i 2] != 1 && ![null [index $i 0]]) || 
	    ([string c enum [type class [index $i 3]]] == 0)} {
	    var isFlags 0
	    break
	}
    }
    if {$isFlags} {
	#
	# Yup. It's a flags word. Print out each element of the structure
	# only if its corresponding bit is set. The elements are printed
	# all on the same line.
	#
	var sep \{
	foreach i $val {
	    if {[index $i 2] && ![null [index $i 0]]} {
		echo -n [format {%s%s} $sep [index $i 0]]
		var sep {, }
	    }
	}
	if {[string c $sep {, }] != 0} {
	    echo -n \{
	}
	echo -n \}
    } else {
	#
	# Not a flags word, but we don't want to say the things are words
	# (that's the type recorded for them) when they aren't.
	#
	echo \{
	if {$alignFields} {
	    var len 0
	    foreach i $val {
		var fl [length [index $i 0] chars]
		if {$fl > $len} {var len $fl}
	    }

	    foreach i $val {
    	    	if {![null [index $i 0]]} {
		    echo -n [format {%*s%-*s = } $offset {} $len [index $i 0]]
		    fmtval [index $i 2] [index $i 1] $offset
    	    	}
	    }
	} else {
	    foreach i $val {
    	    	if {![null [index $i 0]]} {
		    echo -n [format {%*s%s = } $offset {} [index $i 0]]
		    fmtval [index $i 2] [index $i 1] $offset
    	    	}
	    }
	}
	echo -n [format {%*s\}} [expr $offset-4] {}]
    }
}]

#
#	fsigned formats a signed number
[defsubr fsigned {val}
{
    if {$val > 0} {
	return +$val
    } else {
	return $val
    }
}]

#
# Normalize the integer portion of a fixed-point number. All the _int fields are
# unsigned, so we get a very large number where we really want a negative one.
#   $val is the value list for the number
#   $field is the name of the integer field in the structure
#   $max is one more than the maximum unsigned integer that can be held in the
#   	integer portion.
# Returns the integer to use.
#
[defsubr normalize {val field max}
{
    var i [field $val $field]
    if {[expr $i-($max/2) f] >= 0} {
    	return [expr $i-$max f]
    } else {
    	return $i
    }
}]

##################################################################
#
# Routines for formatting special structures when $condenseSpecial
# is non-zero
#
##################################################################
[defsubr fmtstruct-Semaphore {type val offset space}
{
   var val [index [index $val 0] 2] thread [index [index $val 1] 2]
   if {$thread != 0} {
       echo -n [format {[%d, %04xh (%s)]} $val $thread
		[threadname $thread]]
   } else {
       echo -n [format {[%d, empty]} $val]
   }
   return 1
}]

[defsubr fmtstruct-Rectangle {type val offset space}
{
   var s [format {(%s, %s) to (%s, %s)}
		   [index [index $val 0] 2]
		   [index [index $val 1] 2]
		   [index [index $val 2] 2]
		   [index [index $val 3] 2]]
   echo -n $s
   return 1
}]

[defsubr fmtstruct-TMatrix {type val offset space}
{
   # Print six fixed-point numbers as floats in a matrix
   echo
   var indent [format {%*s} $offset {}]
   var nspace [expr $space-$offset]

   foreach row {{TM_11 TM_12 0} {TM_21 TM_22 0} {TM_31 TM_32 1}} {
       foreach field $row {
	   echo -n $indent
	   var f [assoc $val $field]
	   if {![null $f]} {
	       fmtstruct [index $f 1] [index $f 2] $offset $nspace
	   } else {
	       echo [format {%3.1f} $field]
	   }
       }
   }
   echo -n [format {%*s      } $offset {}]
   var f [assoc $val TM_xInv]
   fmtstruct [index $f 1] [index $f 2] $offset 80
   echo -n [format {%*s} $offset {}]
   var f [assoc $val TM_yInv]
   fmtstruct [index $f 1] [index $f 2] $offset 80
   echo 

   # finally all the flags
   echo -n [format {%*s} $offset {}]
   var f [assoc $val TM_flags]
   fmtrecord [index $f 1] [index $f 2] $offset
   echo
   return 0
}]

[defsubr fmtstruct-BBFixed {type val offset space}
{
    echo -n [format {%.4f}
	[expr [normalize $val BBF_int 256]+[field $val BBF_frac]/256 f]]
    return 1
}]

[defsubr fmtstruct-WBFixed {type val offset space}
{
    echo -n [format {%.4f}
	[expr [normalize $val WBF_int 65536]+[field $val WBF_frac]/256 f]]
    return 1
}]

[defsubr fmtstruct-WWFixed {type val offset space}
{
    echo -n [format {%.6f}
	[expr [normalize $val WWF_int 65536]+[field $val WWF_frac]/65536 f]]
    return 1
}]

[defsubr fmtstruct-DWFixed {type val offset space}
{
    echo -n [format {%.6f}
	[expr [field $val DWF_int]+[field $val DWF_frac]/65536 f]]
    return 1
}]

[defsubr fmtstruct-DFixed {type val offset space}
{
    echo -n [format {%.10f}
    	[expr [field $val DF_fracH]/65536+[field $val DF_fracL]/4294967296.0 f]]
    return 1
}]

[defsubr fmtstruct-WDFixed {type val offset space}
{
    echo -n [format {%.10f}
	[expr [normalize $val WD_int 65536]+[field $val WDF_fracH]/65536+[field $val WDF_fracL]/4294967296.0 f]]
    return 1
}]

[defsubr fmtstruct-DDFixed {type val offset space}
{
    echo -n [format {%.10f}
	[expr [field $val DDF_int]+[field $val DDF_frac]/4294967296.0 f]]
    return 1
}]

[defsubr fmtstruct-HugeInt {type val offset space}
{
    echo -n [format {%.2f}
	[expr [field $val HI_hi]*4294967296.0+[field $val HI_lo] f]]
    return 1
}]

[defsubr fmtstruct-FileDate {type val offset space}
{
    var m [field $val FD_MONTH] d [field $val FD_DAY] y [field $val FD_YEAR]
    if {$m+$d+$y == 0} {
    	echo -n Dawn Of Time
    } elif {$m == 0xf && $d == 0x1f && $y == 0x7f} {
    	echo -n Eternity
    } else {
	echo -n [format {%2d/%2d/%4d} $m $d [expr $y+1980]]
    }
    return 1
}]

[defsubr fmtstruct-FileTime {type val offset space}
{
    var hr [field $val FT_HOUR] min [field $val FT_MIN] sec [field $val FT_2SEC]
    if {$hr+$min+$sec == 0} {
    	echo -n Dawn Of Time
    } elif {$hr == 0x1f && $min == 0x3f && $sec == 0x1f} {
    	echo -n Eternity
    } else {
	echo -n [format {%2d:%2d:%2d} $hr $min [expr $sec*2]]
    }
    return 1
}]

[defsubr fmtstruct-FileDateAndTime {type val offset space}
{
    var date [field $val FDAT_date] time [field $val FDAT_time]
    var hr [field $time FT_HOUR] min [field $time FT_MIN] sec [field $time FT_2SEC]
    var m [field $date FD_MONTH] d [field $date FD_DAY] y [field $date FD_YEAR]
    if {$m+$d+$y+$hr+$min+$sec == 0} {
    	echo -n {Dawn Of Time}
    } elif {$m == 0xf && $d == 0x1f && $y == 0x7f && $hr == 0x1f && $min == 0x3f && $sec == 0x1f} {
    	echo -n Eternity
    } else {
	echo -n [format {%2d:%2d:%2d %2d/%2d/%4d} $hr $min [expr $sec*2]
		    $m $d [expr $y+1980]]
    }
    return 1
}]

[defsubr fmtstruct-FloatNum {type val offset space}
{
    require format-float fp.tcl

    echo -n [format-float $val] 
    return 1
}]

[defsubr fmtstruct-CellReference {type val offset space}
{
    require _pcellref pssheet.tcl

    echo -n [_pcellref $val]
    return 1
}]

[defsubr fmtstruct-CellRange {type val offset space}
{
    require _pcellrange pssheet.tcl

    echo -n [_pcellrange $val]
    return 1
}]

[defsubr fmtstruct-IEEE64 {type val offset space}
{
    var sgn [if {[field $val IEEE64_wd3]&0x8000} {expr -1} {expr 1}]
    var exp [expr (([field $val IEEE64_wd3]&0x7ff0)>>4)-0x3ff]
    var m3 [expr ([field $val IEEE64_wd3]&0xf)|0x10]
    echo -n [expr (((((([field $val IEEE64_wd0]/65536)+[field $val IEEE64_wd1])/65536)+[field $val IEEE64_wd2])+$m3)/16)*2**$exp*$sgn float]
    return 1
}]

[defsubr fmtstruct-OutputDescriptor {type val offset space}
{
   var odoff [index [index $val 0] 2]
   var odhan [index [index $val 1] 2]
   fmtoptr $odhan $odoff
   return 1
}]

[defsubr fmtstruct-ObjectDescriptor {type val offset space}
{
   var odoff [index [index $val 0] 2]
   var odhan [index [index $val 1] 2]
   fmtoptr $odhan $odoff
   return 1
}]

[defsubr fmtstruct-SpecWinSizeSpec {type val offset space}
{
    if {[field $val SWSS_SIGN]} {
	var sign -1
    } else {
	var sign 1
    }
    var frac [field $val SWSS_FRACTION]
    var mant [field $val SWSS_MANTISSA]
    if {[field $val SWSS_RATIO]} {
	echo -n [expr $sign*($mant+$frac/1024) f]
    } else {
	echo -n [expr $sign*$mant*1024+$frac]
    }
    return 1
}]


[defsubr fmtstruct-RegFloat {type val offset space}
{
    require prgfloat

    echo -n [format-rgfloat-mem $val]
    return 1
}]



#
# fmtstruct
#	Format a single structure. VAL is a structure list as returned by
#	value fetch. OFFSET is the offset at which to print fields. If
#	alignFields is non-zero, the ='s for the fields will be aligned on
#	the longest field. If noStructEnum is non-zero, any "struct" or
#   	"enum" at the beginning of a field name (as returned by type name)
#   	will be stripped, giving more compact output.  SPACE is the number
#	of characters left on the line to try to print a one-line structure.
#	Returns non-zero if the structure was printed all on one line.
#
[defsubr fmtstruct {type val offset space {blockhan 0}}
{
    global	alignFields noStructEnum intFormat printRegions
    global	condenseSpecial condenseSmall


    if {$condenseSpecial && ![string c [type class $type] struct]} {
    	var n [range [type name $type {} 0] 7 end c]
	if {![null [info command fmtstruct-$n]]} {
	    return [fmtstruct-$n $type $val $offset $space]
    	}
    }
    if {$condenseSmall && [type size $type] <= 4 && [length $val] > 1} {
	#
	# Special-case small nested structures. If it's less than four bytes,
	# we want to print the fields all on the same line if all the fields
	# are integers.
	#
	var linePrint 1
	foreach i $val {
	    if {[string c [type class [index $i 1]] int]} {
		var linePrint 0
		break
	    }
	}
	if {$linePrint} {
	    var line {}
	    var sep {}
	    foreach i $val {
    	    	var line $line[format {%s%s = %s} $sep [index $i 0]
    	    	    	    	    [if {[type signed [index $i 1]]}
					{fsigned [index $i 2]}
					{format $intFormat [index $i 2]}]]
		var sep {, }
	    }
	    if {[length $line chars] <= $space} {
		echo -n $line
		return 1
	    } else {
		echo [format {\n%*s%s} $offset {} $line]
		return 0
	    }
	}
	#
	# Else fall through.
	#
    }
    echo
    if {$alignFields} {
	var len 0
	foreach i $val {
	    var n [type name [index $i 1] [index $i 0] 0]
	    if {$noStructEnum} {
		[case $n in
		 enum* {
		    var n [range $n 5 end chars]
		 }
		 record* {
		    var n [range $n 7 end chars]
		 }
		 struct* {
		    var n [range $n 7 end chars]
		 }]
	    }
	    var fl [length $n chars]
	    if {$fl > $len} {var len $fl}
	}
    } else {
	# %-*s with a width of 0 has the effect of not justifying things
    	var len 0
    }

    foreach i $val {
	var tn [type name [index $i 1] [index $i 0] 0]
	if {$noStructEnum} {
	    [case $tn in
	     enum* {
		var tn [range $tn 5 end chars]
	     }
	     record* {
		var tn [range $tn 7 end chars]
	     }
	     struct* {
		var tn [range $tn 7 end chars]
	     }]
	}
	echo -n [format {%*s%-*s = } $offset {} $len $tn]
	if {$printRegions && [string match $tn {*Region *}]} {
	    fmtRegion [index $i 2] [index $i 1] $offset
	} else {
	    fmtval [index $i 2] [index $i 1] $offset {} 0 $blockhan
	}
    }

    return 0
}]

#
# fmtarray
# 	Format the elements of an array nicely. VAL is the value list, as
#	returned by value fetch, TYPE is the type of the elements in the
#	array (CLASS being its class). OFFSET is again the offset at which
#	to start printing elements. Simple arrays (i.e. arrays of
#   	non-structured elements) expect to be at OFFSET if they're to be
#   	printed on the next line. They do not print a newline.
#
[defsubr fmtarray {val type class offset {blockhan 0}}
{
    var j [length $val]

    # we are at the proper indentation for the first element of the array.
    # $thisoff will be set to $offset for the second and subsequent lines
    # we produce so the thing gets indented properly. Each format case will
    # put out $thisoff spaces before its element, you see, so the caller
    # can properly put out the closing bracket
    var thisoff 0

    [case $class in
     struct {
    	foreach i $val {
	    echo -n [format {%*s\{} $thisoff {}]
	    var thisoff $offset
	    var fret [fmtstruct $type $i [expr $offset+4]
				[expr [columns]-$offset-3] $blockhan]
	    var j [expr $j-1]
	    if {$fret} {
	    	# Fit on one line -- no leading $offset needed
    	        echo -n [format {\}%s} [if {$j} {concat ,\n} {}]]
	    } else {
    	        echo -n [format {%*s\}%s} $offset {} [if {$j} {concat ,\n} {}]]
	    }
	}
     }
     array {
	foreach i $val {
	    echo -n [format {%*s\{} $thisoff {}]
	    var thisoff $offset
	    var j [expr $j-1]
    	    fmtval $i $type $offset [format {\}%s} [if {$j} {concat ,\n} {}]] 0 $blockhan
	}
     }
     char {
	#
	# Print characters as we got them w/no intervening commas -- use
	# format to take care of \\, \{ and \} things. All other things are
	# printed as returned by value...
	#
	foreach i $val {
    	    if {[string m $i {\\[\{\}\\]}]} {
	    	echo -n [format $i]
	    } elif {[string c $i {\000}] == 0} {
		#print terminating NULL and exit
		echo -n $i
		break
    	    } else {
	    	echo -n $i
    	    }
	}
     }
     int {
     	global byteAsChar
	
	if {$byteAsChar && [type size $type] == 1} {
	    foreach i $val {
	    	if {$i == 0} {
		    echo -n {\000}
		    break
		} else {
		    echo -n [format %c $i]
		}
	    }
    	} else {
	    foreach i $val {
		var j [expr $j-1]
		fmtval $i $type 0 [if {$j} {concat {, }} {}]  1 $blockhan
	    }
	}
     }
     {enum pointer} {
    	foreach i $val {
	    echo -n [format {%*s} $thisoff {}]
	    var thisoff $offset
    	    var j [expr $j-1]
    	    fmtval $i $type 0 [if {$j} {concat {, }} {}]  1 $blockhan
	}
     }
     default {
	foreach i $val {
	    echo -n [format {%*s} $thisoff {}]
	    var thisoff $offset
	    var j [expr $j-1]
	    echo -n [format {%s%s} $i [if {$j} {concat {, }} {}]]
	}
    }]
}]

#
# fmtval
# 	Format a value list. VAL is the value list, TYPE is its type, OFFSET
#	is the offset at which to print the thing. TAIL is a kludge that
#	contains text to follow the last element of the list before the
#	newline. Used only for nested arrays.
#
[defcommand fmtval {val type offset {tail {}} {oneline 0} {blockhan 0}} print.utils
{Usage:
    fmtval <value-list> <type-token> <indent> [<tail> [<one-line> [<block-han>]]]

Examples:
    "fmtval [value fetch foo] [symbol find type FooStruct] 0"
    	    	    	Prints the value of the variable foo, which is
			assumed to be of type FooStruct.

Synopsis:
    This is the primary means of producing nicely-formatted output of
    data in Swat. It is used by both the "print" and "_print" commands and
    is helpful if you want to print the value of a variable without
    entering anything into the value history.

Notes:
    * <value-list> is the return value from "value fetch". You can, of course,
      glom together one of these if you feel so inclined.

    * <type-token> is the token for the type-description used when fetching
      the value.

    * <indent> is the base indentation for all output. When "fmtval" calls
      itself recursively, it increases this by 4 for each recursive call.
      "fmtval" assumes the cursor is already at this position on the current
      line for the first line of output.

    * <tail> is an optional parameter that exists solely for use in formatting
      nested arrays. It is a string to print after the entire value has been
      formatted. You will almost always omit it or pass the empty string.

    * <one-line> is another optional parameter used almost exclusively for 
      recursive calls. It indicates if the value being formatted is expected to
      fit on a single line, and so "fmtval" should not force a newline to be 
      output at the end of the value. The value should be 0 or 1.

See also:
    print, _print, fmtoptr, threadname.
}
{
    var class [type class $type]

    [case $class in
     {union struct} {
     	global condenseSpecial

	if {[type size $type] == 0} {
		echo -n \{\}$tail
        } else {
	    if {[catch {wmove +0 +0} curpos] == 0} {
		var xpos [index $curpos 0]
	    } else {
    	    	# wild guess
		var xpos [expr $offset+25]
	    }
	    var space [expr [columns]-$xpos-1]

	    var n [range [type name $type {} 0] 7 end c]
	    [if {($condenseSpecial && ![null [info proc fmtstruct-$n]]) ||
	    	  ![isrecord $type]}
    	    {
	    	echo -n \{
		var fret [fmtstruct $type $val [expr $offset+4] $space $blockhan]

		if {$fret} {
		    # All on one line -- no $offset needed
		    echo -n \}$tail
		} else {
		    echo -n [format {%*s\}%s} $offset {} $tail]
		}
	    } else {
		fmtrecord $type $val [expr $offset+4]
		echo -n $tail
	    }]
    	}
     }
     array {
     	global condenseSpecial
	
	
    	# NOTE: the [var n mumble] != 0 is a hack to assign the type name
	# to $n only when condenseSpecial is non-zero without having to have
	# a nested if; the var command always returns {} as its value, so the
	# test is always true...
	[if {$condenseSpecial &&
	     [var n [type name $type {} 0]] != 0 &&
	     ![string match $n {*\[*\]}] &&
	     ![null [info proc fmtstruct-$n]]}
    	{
		if {[catch {wmove +0 +0} curpos] == 0} {
		    var xpos [index $curpos 0]
		} else {
		    # wild guess
		    var xpos [expr $offset+25]
		}
		var space [expr [columns]-$xpos-1]

    	    	# \{ match other bracket down below
	    	echo -n \{
		if {[fmtstruct-$n $type $val $offset $space]} {
		    # All on one line -- no $offset needed
		    echo -n \}$tail
		} else {
		    echo -n [format {%*s\}%s} $offset {} $tail]
		}
    	} else {
	    var adata [type aget $type]
	    var base [index $adata 0]
	    var len [expr [index $adata 2]-[index $adata 1]]
	    var class [type class $base]

	    #
	    # Decide whether to print the thing on this line. If it contains
	    # fewer than 10 elements, each of which is less than 4 bytes long,
	    # we print it on the same line. These limits are fairly arbitrary,
	    # but have worked so far.
	    #
	    if {($len < 10) && ([type size $base] < 4)} {
		echo -n \{
		fmtarray $val $base [type class $base] 0 $blockhan
		echo -n \}$tail
	    } else {
		echo -n [format {\{\n%*s} [expr $offset+4] {}]
		[fmtarray $val $base [type class $base] [expr $offset+4]
		    $blockhan]
		echo -n [format {\n%*s\}%s} $offset {} $tail] 
	    }
    	}]
     }
     int {
	global byteAsChar intFormat dwordIsPtr

	if {![type signed $type] && $dwordIsPtr && [type size $type] == 4} {
    	    #
	    # Print double-word as a pointer (XXX: symbolically?)
	    #
	    echo -n [format %04xh:%04xh [expr ($val>>16)&0xffff]
		     [expr $val&0xffff]]$tail
	} elif {$byteAsChar && [type size $type] == 1} {
	    #
	    # Print bytes as characters (and their decimal value too)
	    #
	    echo -n [format [format {'%%c' (%s)} $intFormat] $val $val]$tail
	} elif {[type signed $type]} {
	    echo -n [format {%s%d} [if {$val > 0} {concat +} {}] $val]$tail
	} else {
	    echo -n [format [format {%s%s} $intFormat $tail] $val]
	}
     }
     enum {
    	#
	# Figure the name for the constant and print it, if we can find
	# it.
	#
    	var e [type emap $val $type]
	if {![null $e]} {
	    echo -n $e$tail
	} else {
	    echo -n $val (invalid)
	}
     }
     pointer {
    	if {$val == 0} {
	    echo -n null$tail
	} elif {$val == 0xffff} {
	    echo -n nil$tail
	} else {
	    [case [index [type pget $type] 0] in
	     lmem {
    	    	#
		# Find the offset and size of the block pointed to.
		# We need the segment from which our pointer came, however.
		# Since print has entered the thing into the value history,
		# we can just consult it to get the proper handle back.
		#
    	    	if {$blockhan != 0} {
		    var seg ^h[handle id $blockhan]
		    var off [value fetch $seg:$val [type word]]
		    if {$off == 0xffff} {
			var sz 0
		    } else {
			var sz [expr [value fetch $seg:$off-2 [type word]]-2]
		    }
		    var bl [handle id $blockhan]
		    echo -n [format
			    {%04xh [%d bytes at ^l%04xh:%04xh]}
					 $val $sz $bl $val]$tail
    	    	} else {
		    echo -n [format {%04xh} $val]$tail
    	    	}
	     }
	     near {
		echo -n [format %04xh $val]$tail
	     }
	     seg {
    	    	#
		# Attempt to locate the handle of the block for which it's the
		# segment.
		#
	     	var h [handle find $val:0]
		if {[null $h]} {
    	    	    # not block-relative, so just give the segment
		    echo -n [format %04xh $val]$tail
    	    	} else {
		    #
		    # If the segment isn't the block's segment, but just points
		    # within the block, also tell the user the real segment of
		    # the block within which it falls.
		    #
    	    	    if {[handle segment $h] != $val} {
		    	var at [format { at %04xh} [handle segment $h]]
    	    	    } else {
		    	var at {}
    	    	    }
		    if {[handle state $h] & 0x480} {
			#
			# Handle is a resource/kernel handle, so it's got a
			# symbol in its otherInfo field. We want that
			# symbol's name.
			#
			echo -n [format {%04xh (%s%s)} $val 
				 [symbol fullname [handle other $h]] $at]$tail
		    } else {
    	    	    	#
			# Tell the user the handle ID
			#
			echo -n [format {%04xh (^h%04xh%s)} $val
				 [handle id $h] $at]$tail
		    }
    	    	}
    	     }
	     handle {
    	    	#
		# Figure out to which handle it refers
		#
		if {[catch {handle lookup $val} h] || [null $h]} {
		    echo -n [format {^h%04xh (invalid)} $val]$tail
    	    	} elif {[handle ismem $h]} {
    	    	    #
		    # Decide what info to print about it by its state flags
		    #
		    if {[handle state $h] & 0x480} {
			#
			# Handle is a resource/kernel handle, so it's got a
			# symbol in its otherInfo field. We want that
			# symbol's name.
			#
			echo  -n [format {^h%04xh (%s at %04xh)}
				   $val [symbol fullname [handle other $h]]
				   [handle segment $h]]$tail
		    } elif {[handle state $h] & 0x100} {
			#
			# Process handle (these things ain't resources).
			# Give the name of the owner.
			#
			echo -n [format {^h%04xh (%s)} $val
				 [patient name [handle patient $h]]]$tail
		    } else {
    	    	    	#
			# Blah -- just print its segment
			#
			echo -n [format {^h%04xh (at %04xh)} $val
				 [handle segment $h]]$tail
		    }
		} elif {[handle isthread $h]} {
		    #
		    # Handle is a thread handle, so find its owner and
		    # number
		    #
    	    	    echo -n [format {^h%04xh (%s)} [handle id $h]
			     [threadname [handle id $h]]]$tail
    	    	} else {
		    var sig [type emap [expr ([handle state $h]>>16)|0xf0]
    	    	    	    	[if {[not-1x-branch]}
				    {sym find type geos::HandleType}
				    {sym find type geos::HandleTypes}]]
		    echo -n [format {^h%04xh (type %s)} $val $sig]$tail
    	    	}
	     }
	     far {
		#
		# Print the thing out as segment:offset and symbolically
		#
		var s [expr ($val>>16)&0xffff] o [expr $val&0xffff]
		var h [handle find $s:0]
		if {![null $h] && !([handle state $h] & 0x800)} {
    	    	    # in a known handle and that block's not lmem, so
		    # there's a chance there's a reasonable symbol...
		    var sym [sym faddr any $s:$o]
		} else {
		    var sym nil
    	    	}

		if {[null $sym]} {
		    echo -n [format %04xh:%04xh $s $o]$tail
		} else {
		    echo -n [format {%04xh:%04xh (%s)} $s $o
		    	    	     [symbol fullname $sym]]$tail
		}
    	    	# if the thing is a pointer to a string, or number then
    	    	# print out the value as well as the pointer itself
    	    	var subtype [index [type pget $type] 1]
    	    	var tc [type class $subtype]
    	    	[case $tc in
    	    	    char {
    	    	    	echo -n { "}
    	    	    	if {[catch {pstring -s -l 256 $s:$o} val] == 1}  {
    	    	    	    echo -n [format {" Invalid char pointer}]
			} else {
    	    	    	    echo -n {"}
    	    	    	}
    	    	    }
    	    	    {short long int} {
    	    	    	echo -n [format { %d } [value fetch $s:$o $subtype]]
    	    	    }
    	    	    enum {
    	    	    	echo -n [format { %s } [type emap [value fetch $s:$o $subtype] $subtype]]
    	    	    }
    	    	]
	     }
	     virtual {
		#
		# Print the thing out as segment:offset or ^hhandle:offset and
		# symbolically
		#
		var s [expr ($val>>16)&0xffff] o [expr $val&0xffff]
		if {$s != 0xffff && $s >= 0xf000} {
		    var s [expr ($s&0xfff)<<4]
		    var h [handle lookup $s]
		    var seg [format {^h%04xh} $s]
    	    	} else {
		    var seg [format {%04xh} $s]
		    var h [handle find $s:0]
    	    	}
		if {![null $h] && !([handle state $h] & 0x800)} {
    	    	    # in a known handle and that block's not lmem, so
		    # there's a chance there's a reasonable symbol...
		    var sym [sym faddr any $seg:$o]
		} else {
		    var sym nil
    	    	}

		if {[null $sym]} {
		    echo -n [format %s:%04xh $seg $o]$tail
		} else {
		    echo -n [format {%s:%04xh (%s)} $seg $o
		    	    	     [symbol fullname $sym]]$tail
		}
    	    	# if the thing is a char *, then print out the string
    	    	if {[type class [index [type pget $type] 1]] == char} {
    	    	    echo -n { "}
    	    	    pstring -s -l 256 $seg:$o
    	    	    echo -n {"}
    	    	}
	     }
	     object {
    	    	#
		# Break the pointer into its two pieces and see if we can
		# find a handle token for the handle portion.
		#
	    	var h [expr ($val>>16)&0xffff] l [expr $val&0xffff]
		fmtoptr $h $l
    	     }
	     vm {
	     	echo -n [format {^v%04xh:%04xh}
		    	    [expr ($val>>16)&0xffff]
			    [expr $val&0xffff]]$tail
    	     }
	    ]
    	}
     }
     bitfield {
    	fmtval $val [index [type bfget $type] 2] 0 $tail $oneline $blockhan
    	return
     }
     default {
    	#
	# Default to printing the value
	#
    	echo -n $val$tail
    }]
    if {! $oneline} {
    	echo
    }
}]

#
# fmtRegion
#	Format a single structure. VAL is a structure list as returned by
#	value fetch. OFFSET is the offset at which to print fields.
#
[defsubr fmtRegion {val type offset {tail {}}}
{
    #
    # Handle null region pointer specially
    #
    if {$val == 0} {
    	echo LMem Null$tail
	return
    }

    var seg [handle segment [index [value hfetch 0] 0]]
    var off [value fetch $seg:$val [type word]]
    var size [expr [value fetch $seg:$off-2 [type word]]&~1]
    if {[value fetch $seg:$off [type word]] == 0x7fff} {
	#
	# Matches the universe. Doug wants it to say "Whole"...
	#
	echo Whole$tail
    } elif {[value fetch $seg:$off [type word]] == 0x8000} {
	#
	# Null region
	#
	echo Null$tail
    } elif {$size == 16 &&
    	    [value fetch $seg:$off+2 [type word]] == 0x8000 &&
	    [value fetch $seg:$off+10 [type word]] == 0x8000 &&
	    [value fetch $seg:$off+12 [type word]] == 0x8000} {
	#
	# Rectangular region
	#
	echo [format {Rectangular, bounds = (%d, %d, %d, %d)%s}
		[value fetch $seg:$off+6 short]
		[expr {[value fetch $seg:$off short]+1}]
		[value fetch $seg:$off+8 short]
		[value fetch $seg:$off+4 short] $tail]
    } else {
    	require region-get-bounds region
    	var bounds [region-get-bounds $seg:$off $size 0]
	if {[null $bounds]} {
	    echo [format {Bogus (longer than allocated chunk [%d bytes])}
			    $size]
    	    var bounds [list -1 -1 -1 -1 $size]
    	}

	require convert-param-region region
	echo [format {Complex (%d), bounds = (%s, %s, %s, %s)%s}
		[expr [index $bounds 4]/2]
		[convert-param-region [index $bounds 0] 0]
		[convert-param-region [index $bounds 1] 0]
		[convert-param-region [index $bounds 2] 0]
		[convert-param-region [index $bounds 3] 0] $tail]
    }
}]

[defcmd print {noeval} top.print
{Usage:
    print <expression>

Examples:
    "p 56h"	    	    print the constant 56h in various formats
    "print 56h"	    	    print the constant 56h in various formats
    "print ax - 10"	    print ax less 10 decimal
    "print ^l31a0h:001eh"   print the absolute address of the pointer
    "print MyStruct es:di #4"
                            print 4 elements of MyStruct array
                            starting at address es:di 

Synopsis:
    Print the value of an expression.

Notes:
    * The expression argument is usually an address that has a type or
      that is given a type by casting and may span multiple arguments.
      The contents of memory of the given type at that address is
      what's printed. If the expression has no type, its offset part
      is printed in both hex and decimal. This is used for printing
      registers, eg.

      The first argument may contain the following flags (which start
      with '-' infront):
    	   x	integers (bytes, words, dwords if dwordIsPtr false)
    	    	printed in hex
    	   d	integers printed in decimal
    	   o	integers printed in octal
    	   c	bytes printed as characters (byte arrays printed as
    	    	strings, byte variables/fields printed as character
    	    	followed by integer equivalent)
    	   C	bytes treated as integers
    	   a	align structure fields
    	   A	Don't align structure fields
    	   p	dwords are far pointers
    	   P	dwords aren't far pointers
    	   r	parse regions
    	   R	don't try and parse regions

      These flags operate on the following TCL variables:
    	   intFormat	 A printf format string for integers
    	   byteAsChar	 Treat bytes as characters if non-zero
    	   alignFields	 Align structure fields if non-zero
    	   dwordIsPtr	 DWord's are far pointers if non-zero
    	   noStructEnum  If non-zero, doesn't print the "struct", "enum" or
    	    	    	 "record" before the name of a structured/enumerated
			 type -- just gives the type name.
    	   printRegions  If non-zero, prints what a Region * points to
    	    	    	 (bounds and so on).			
    	   condenseSpecial If non-zero, condense special structures (Rectangles,
			 OutputDescriptors, ObjectDescriptors, TMatrixes and all
			 fixed-point numbers) to one line.

    * This does not print enumerations. Use penum for that.

    * To print an array of fixed size elements, specify the number of
      elements by "#<num>" as the last argument. For example, "print
      MyStruct *ds:si #10" prints out 10 elements of MyStruct starting
      at address *ds:si.

See also:
    precord, penum.
}
{
    global intFormat byteAsChar alignFields dwordIsPtr printRegions
    [var oldIF $intFormat
    	 oldBAC $byteAsChar
	 oldAF $alignFields
	 oldDIP $dwordIsPtr
	 oldPR $printRegions]
    protect {
	if {[string m [index $noeval 0] -*]} {
	    #
	    # Gave us some flags
	    #
	    foreach i [explode [index $noeval 0]] {
		[case $i in
		    x {var intFormat %xh}
		    d {var intFormat %d}
		    o {var intFormat %o}
		    a {var alignFields 1}
		    A {var alignFields 0}
		    c {var byteAsChar 1}
		    C {var byteAsChar 0}
		    p {var dwordIsPtr 1}
		    P {var dwordIsPtr 0}
		    r {var printRegions 1}
		    R {var printRegions 0}
		 ]
	    }
	    var noeval [range $noeval 1 end]
	}
	var addr [uplevel 1 addr-parse $noeval 0]

	[if {[null $addr]} {
	    error [concat Couldn't parse the address '$noeval'.]
	} elif {[null [index $addr 2]] ||
	    	(([string c [index $addr 0] value] == 0) &&
		 ([string c [type class [index $addr 2]] int] == 0))}
    	{
	    #
	    # Doesn't have any type -- print as a constant of some sort
	    #
	    if {[null [index $addr 0]] || ![string c [index $addr 0] value]} {
		#
		# No handle either -- print offset in both hex and decimal
		#
		var val [index $addr 1]
		echo [format {%s = %04xh, %u, %s%s} $noeval $val 
			$val [makenegative $val]
			[if {$val >= 32 && $val <= 255} {format {, '%c'} $val}
			 elif {$val < 32} {format {, Ctrl-%c} [expr {$val + 0x40}] } ]]
	    } else {
		#
		# Ah hah -- just wants to know the address.
		#
		echo [format {%s = %04xh:%04xh} $noeval 
			[handle segment [index $addr 0]] [index $addr 1]]
	    }
	} elif {[string c [index $addr 0] value] == 0} {
	    #
	    # Value already fetched by addr-parse. Now print it.
	    #
    	    echo -n $noeval {= }
	    fmtval [index $addr 1] [index $addr 2] 0
	} else {
	    #
	    # Fetch the actual value
	    #
    	    if {![null [index $addr 0]]} {
    	    	var val [value fetch ^h[handle id [index $addr 0]]:[index $addr 1]
			    [index $addr 2]]
    	    } else {
    	    	var val [value fetch 0:[index $addr 1] [index $addr 2]]
    	    }
	    #
	    # Print the expression as given, and the number under which it's
	    # been stored in the value history (after storing it, of course)
	    #
	    echo -n @[value hstore $addr]: $noeval {= }
	    #
	    # Format the value list
	    #
	    fmtval $val [index $addr 2] 0 {} 0 [index $addr 0]
	    #
	    # If the argument string contained the last-history token (an @
	    # followed by an operator character or nothing), set up to repeat
	    # the thing. This is mostly to go down a list of objects easily.
	    #
	    if {[string match $noeval {*@[-.+^)]*}] || [string match $noeval {*@}]} {
		global repeatCommand lastCommand
		var repeatCommand $lastCommand
	    }
	}]
    } {
    	[var intFormat $oldIF
	    byteAsChar $oldBAC
	    alignFields $oldAF
	    dwordIsPtr $oldDIP
	    printRegions $oldPR]
    }
}]

##############################################################################
#				_print
##############################################################################
#
# SYNOPSIS:	Similar to "print", except it takes no flags and TCL evaluates
#   	    	its arguments for variables and nested commands before calling
#		it. It also doesn't affect the repeatCommand variable.
#
#   	    	This is the preferred function for other functions to call.
#
# PASS:		args	= address expression whose value is to be printed
# CALLED BY:	other functions
# RETURN:	nothing
# SIDE EFFECTS:	the address is entered into the value history
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/ 7/91		Initial Revision
#
##############################################################################
[defcommand _print {args} print.utils
{Usage:
    _print <expression>

Examples:
    "_print ax-10"	print ax less 10 decimal.

Synopsis:
    Print the value of an expression.

Notes:
    * The difference between this command and the "print" command is a subtle
      one: if one of the arguments contains square-brackets, the Tcl interpreter
      will attempt to evaluate the text between the brackets as a command before
      _print is given the argument. If the text between the brackets is
      intended to be an array index, the interpreter will generate an error
      before the Swat expression evaluator has a chance to decide whether the
      text is a nested Tcl command or an array index.
      
      For this reason, this function is intended primarily for use by Tcl
      procedures, not by users.

See also:
    print, addr-parse
}
{
    var addr [addr-parse $args 0]

    if {[null $addr]} {
	error [concat Couldn't parse the address '$args'.]
    } elif {[null [index $addr 2]]} {
	#
	# Doesn't have any type -- print as a constant of some sort
	#
	if {[null [index $addr 0]]} {
	    #
	    # No handle either -- print offset in both hex and decimal
	    #
	    var val [index $addr 1]
	    echo [format {%s = %04xh, %u, %s%s} $noeval $val 
		    $val [makenegative $val]
		    [if {$val >= 0 && $val <= 255} {format {, '%c'} $val}]]
	} else {
	    #
	    # Ah hah -- just wants to know the address.
	    #
	    echo [format {%s = %04xh:%04xh} $args 
		    [handle segment [index $addr 0]] [index $addr 1]]
	}
    } elif {[string c [index $addr 0] value] == 0} {
    	#
	# Value already fetched by addr-parse. Now print it.
	#
	echo -n $args {= }
	fmtval [index $addr 1] [index $addr 2] 0
    } else {
	#
	# Fetch the actual value
	#
	if {![null [index $addr 0]]} {
	    var val [value fetch ^h[handle id [index $addr 0]]:[index $addr 1]
			[index $addr 2]]
	} else {
	    var val [value fetch 0:[index $addr 1] [index $addr 2]]
	}
	#
	# Print the expression as given, and the number under which it's
	# been stored in the value history (after storing it, of course)
	#
	echo -n @[value hstore $addr]: $args {= }
	#
	# Format the value list
	#
	fmtval $val [index $addr 2] 0 {} 0 [index $addr 0]
    }
}]

[defcommand penum {enumtype val} print
{Usage:
    penum <type> <value>

Examples:
    "penum FatalErrors 0"	print the first FatalErrors enumeration

Synopsis:
    Print an enumeration constant given a numerical value.

Notes:
    * The type argument is the type of the enumeration.

    * The value argument is the value of the enumeration in a 
      numerical format.

See also:
    print, precord.
}
{
	return [type emap [getvalue $val] [sym find type $enumtype]]
}]

[defcommand precord {recType val {silent 0}} print
{Usage:
    precord <type> <value> [<silent>]

Examples:
    "precord WelcomeProcessFlags c0h"	print the WelcomeProcessFlags
					record with the top two bits set

Synopsis:
    Print a record using a certain value.

Notes:
    * The type argument is the type of the record.

    * The value argument is the value of the record.

    * The silent argument will suppress the text indicating the record
      type and value.  This is done by passing a non zero value like
      '1'.  This is useful when precord is used by other functions.

See als:
    print, penum.
}
{
    #
    # Locate the symbol token for the type. Bitch if undefined.
    #
    var t [sym find type $recType]
    if {[null $t]} {
	error [concat precord: '$recType' is not a defined type.]
    }

    #
    # Allow arbitrary value
    #
    var n [getvalue $val]

    #
    # Fetch the fields for the structure. This thing will nuke us if the
    # recType isn't really a record. 
    #

    if {![isrecord $t]} {
	error [concat precord: '$recType' is not a record.]
    }
    var v [cvtrecord $t $n]

    #
    # Finally, use fmtrecord to print the thing out properly
    #
    if {!$silent} {
	echo -n $val as $recType {= }
    }
    fmtrecord $t $v 4
    echo
}]
   
##############################################################################
#				cvtrecord
##############################################################################
#
# SYNOPSIS:	    Convert an integer into a value list for a record
# PASS:		    t	= type token for the record
#   	    	    n	= integer holding the value to be broken into
#			  the appropriate values in the resulting value list
# CALLED BY:	    precord, self
# RETURN:	    value list suitable for passing to fmtrecord or fmtval
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/ 3/91	Initial Revision
#
##############################################################################
[defcommand cvtrecord {t n} swat_prog.util
{Usage:
    cvtrecord <type> <number>

Examples:
    "cvtrecord [symbol find type HeapFlags] 36"	Return a value list for the
						number 36 cast to a HeapFlags
						record.

Synopsis:
    Creates a value list for a record from a number, for use in printing out
    the number as a particular record using fmtval.

Notes:
    * <type> is a type token for a record (or a structure made up exclusively
      of bitfields).

    * <number> must be an actual number suitable for the "expr" command. It
      cannot be a register or variable or some such. Use "getvalue" to obtain
      an integer from such an expression.

    * Returns a value list suitable for "value store" or for "fmtval".

See also:
    value, fmtval, expr, getvalue.
}
{
    var flds [type fields $t]

    #
    # Build up a value list to pass to fmtrecord. The value list consists of
    # elements in the form:
    #	{name type value}
    # while the fields list is
    #	{name offset length type}
    #

    return [map i $flds {
    	var f [expr {($n>>[index $i 1])&((1<<[index $i 2])-1)}]
	[list [index $i 0]
	      [index $i 3]
	      [if {[string c [type class [index $i 3]] struct] == 0}
    	       {cvtrecord [index $i 3] $f}
	       {var f}]]
    }]
}]

##############################################################################
#				pbitmap
##############################################################################
#
# SYNOPSIS:	Command to print out a bitmap (complex or simple)
# PASS:		addr	= address of Bitmap or CBitmap structure. Only
#			  handles monochrome bitmaps for now.
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/28/90	Initial Revision
#
##############################################################################
[defcommand pbitmap {addr} lib_app_driver.bitmap
{Usage:
    pbitmap <address>

Examples:
    "pbitmap ^h3060h:163h"   	Print the bitmap from a gstring (the
				address comes from the output of the "pgs"
				command).

Synopsis:
    Print a bitmap graphically.

Notes:
    * The address argument is the address of the Bitmap or CBitmap
      structure.

    * Color bitmaps are printed with a letter representing the color
      as well.  The letters are index from the string (kbgcrvnAaBGCRVYW).

}
{
    if {[not-1x-branch]} {
    	var bpref B btpref BMT bcpref BMC
    } else {
    	var bpref BM btpref BM bcpref BM
    }

    [var width [value fetch ($addr).${bpref}_width]
	 height [value fetch ($addr).${bpref}_height]]

    if {[field [value fetch ($addr).${bpref}_type] ${btpref}_COMPLEX]} {
    	echo [format {Total dimensions = %dx%d, slice height = %d (start = %d)}
	    	$width $height [value fetch ($addr).CB_numScans]
		[value fetch ($addr).CB_startScan]]
	echo [format {X resolution = %d dots/inch, Y resolution = %d dots/inch}
	    	[value fetch ($addr).CB_xres] [value fetch ($addr).CB_yres]]

    	var data [value fetch ($addr).CB_data]
	var height [value fetch ($addr).CB_numScans]
    } else {
    	echo [format {Total dimensions = %dx%d} $width $height]
	var data [size Bitmap]
    }
    if {[field [value fetch ($addr).${bpref}_type] ${btpref}_FORMAT]} {
    	pColorBitmap $addr $data $width $height nospace
    } else {
    	[if {[value fetch ($addr).${bpref}_compact] ==
	     [index [symbol get [symbol find enum ${bcpref}_PACKBITS]] 0]}
    	{
    	    pcbitmap ($addr)+$data $width $height nospace
    	} else {
    	    pncbitmap ($addr)+$data $width $height nospace
    	}]
    }
}]

[defsubr printColor {c}
{
    echo -n [index {kbgcrvnAaBGCRVYW} $c char]
}]

[defsubr print4byte {val}
{
    printColor [expr ($val&0xf0)>>4]
    printColor [expr $val&0xf]
}]


[defsubr borderLine {length}
{
    echo -n {+}
    for {var col 0} {$col < $length} {var col [expr $col+1]} {
	echo -n -
    }
    echo {+}
}]


[defsubr pColorBitmap {addr data width height args}
{
    addr-preprocess ($addr)+$data seg ptr
    var pwidth	    [expr ($width+1)/2]

    borderLine $width

    if {[not-1x-branch]} {
    	var mask [field [value fetch ($addr).B_type] BMT_MASK]
	var compact [value fetch ($addr).B_compact]
    } else {
    	var mask [field [value fetch ($addr).BM_type] BM_MASK]
	var compact [value fetch ($addr).BM_compact]
    }

    if {$compact} {
    	var pfunc pCRow
    } else {
    	var pfunc pNCRow
    }
    
    if {$mask} {
    	var mwidth	    [expr ($width+7)/8]

    	for {var row 0} {$row < $height} {var row [expr $row+1]} {
	    echo -n |
	    var ptr [$pfunc $mwidth $seg $ptr {printbyte {#} { }}]
	    echo -n \n|
	    var ptr [$pfunc $pwidth $seg $ptr print4byte]
	    echo {}
    	}
    } else {
    	for {var row 0} {$row < $height} {var row [expr $row+1]} {
	    echo -n {|}
	    var ptr [$pfunc $pwidth $seg $ptr print4byte]
	    echo {}
    	}
    }

    borderLine $width

}]

##############################################################################
#				pdw
##############################################################################
#
# SYNOPSIS:	Command to print the dword value of a register pair
# PASS:		regpair = register pair
#
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	simon	6/13/96		Initial Revision
#
##############################################################################
[defcommand pdw {regpair} top.print
{Usage:
    pdw	<register pair>

Examples:
    "pdw dxax"			
    "pdw dx.ax"			
    "pdw dx:ax"                 prints the dword value of register
                                pair dx:ax

Synopsis:
    Prints the dword value of a register pair

Notes:
    * The first register is the high register while the second is the
      low register.

See also:
    print.
}
{
    #
    # Split up the register pair into hi and low regs. 
    #
    var lowreg [range $regpair 2 end char] hireg [range $regpair 0 1 char]

    #
    # Verify the register arguments
    #
    [case $hireg in
    {[A-Za-z][A-Za-z]} {
	# Correct syntax, do nothing
    }
    default {
	error [format {pdw: %s: Invalid argument} $regpair]
    }]

    #
    # If the syntax of register pair is "dx.ax" or "dx:ax", we still
    # want to filter them into dx and ax.
    #
    [case $lowreg in 
    {[:.][A-Za-z][A-Za-z]} {
	# one of "dx.ax" or "dx:ax" syntax, ignore extra delimiter
	var lowreg [range $lowreg 1 end char]
    }
    {[A-Za-z][A-Za-z]} {
	# Correct syntax, do nothing
    }
    default {
	error [format {pdw: %s: Invalid argument} $regpair]
    }]
    
    #
    # Get the value
    #
    var n [expr ([read-reg $hireg]<<16)+[read-reg $lowreg]]

    #
    # Display the value is various format
    #
    if {$n >= 0} {
	  var s +$n
    } else {
	  var s $n
    }
    echo [format {%s = %08xh, %u, %s} $regpair $n $n $s]
}]

##############################################################################
#				pdgroup
##############################################################################
#
# SYNOPSIS:	Print out the variables defined in dgroup
# PASS:		args = arguments passed to pdgroup
# CALLED BY:	USER
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	7/ 1/96   	Initial Revision
#
##############################################################################
[defcommand    pdgroup {args} top.print
{Usage:
    pdgroup [<flags>] [<patient>]
	 
Examples:
    "pdgroup"		Prints out all dgroup variables of the current
			patient 
    "pdgroup -e *lock*" Prints out all dgroup variables matching expression
			"*lock*" of the current patient
    "pdgroup term"	Prints out all dgroup variables of the
			patient "term"
    "pdgroup -e *lock* term"
			Prints out all dgroup variables matching expression
			"*lock*" of the patient "term"

Synopsis:
    Prints out the variables defined in dgroup 

Notes:
    * Flags:
	-e <expression>
			Only prints out the variables matching <expression>.
			When -e flag is used, <expression> argument must be
			supplied. The expression syntax is the same as the
			one specified in "string match" command.

See also:
    print, pscope.
}
{
    # This is used to store regular expression to filter variables
    var pdgroupExpr nil

    # Get some flags
    if {[string m [index $args 0] -*]} {
	var curarg [range [index $args 0] 1 end chars]
	var args [range $args 1 end]
	[case $curarg in
	 e {
	     var pdgroupExpr [index $args 0]
	     if {$pdgroupExpr == {}} {
		 error [format {pdgroup: Missing argument for -e option}]
	     }
	     var args [range $args 1 end]
	 }]
    }

    #
    # All options and flags should have been parsed. $args should be
    # left empty or with the patient name.
    #
    # $pat = patient name to get info from
    #
    if {![null $args]} {
	if {[length $args] != 1} {
	    error [format {pdgroup: %s: Too many patients} $args]
	}
	if {[null [patient find $args]]} {
	    error [format {pdgroup: %s: Invalid patient} $args]
	}
	
	# patient is passed from command line
	var pat $args
    } else {

	# patient is current patient
	var pat [patient name]
    }

    # Get the dgroup variable names first
    var scope [symbol find scope $pat::dgroup]
    symbol foreach $scope any print-dgroup-elem $pdgroupExpr
}]

##############################################################################
#			print-dgroup-elem
##############################################################################
#
# SYNOPSIS:	Print out an element defined in dgroup 
# PASS:		sym		= token of symbol to print
#               pdgroupExpr	= expression to match the symbols
# CALLED BY:	pdgroup (via symbol foreach)
# RETURN:	0 (continue iterating)
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	7/ 1/96   	Initial Revision
#
##############################################################################
[defsubr print-dgroup-elem {sym pdgroupExpr}
{
    var symname [symbol fullname $sym] 
    var n [string last :: $symname]
    var shortname [range $symname [expr $n+2] end char]

    # Only display those matching variables if pdgroupExpr is set
    if {![null $pdgroupExpr]} {
	if {![string m $shortname $pdgroupExpr]} {
	    return 0
	}
    }

    echo -n [format {> %s = } $shortname]
    #
    # Fetch and print the actual value
    #
    catch {
	var val [value fetch $symname]
	#
	# Print the expression as given, and the number under which it's
	# been stored in the value history (after storing it, of course)
	#
	# Format the value list
	#
	fmtval $val [index [symbol get $sym] 2] 0
    }
    return 0
}]


