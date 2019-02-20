##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#	$Id: print.tcl,v 3.7 90/04/30 18:14:21 adam Exp $
#
###############################################################################
[defvar intFormat %x variable.output
{Contains the printf format string used to print integers. Defaults to %x}]

[defvar byteAsChar 0 variable.output
{If non-zero, all byte variables will have their values converted into
ascii characters. For single-byte variables, both the ascii and the hex
value will be printed. For multi-byte variables, only the characters will
be shown. This has been superseded by the "char" type, but remains for the
hell of it}]

[defvar alignFields 0 variable.output
{If non-zero, the values for all fields in a structure will be lined up when
printed, making it easier to scan them}]

[defvar dwordIsPtr 1 variable.output
{If non-zero, indicates that all dword-sized variables should be assumed to
be generic far pointers and be printed in segment:offset format, rather than
as one big 32-bit integer. Superseded by the various ptr types, but....
Defaults to 1.}]

[defvar noStructEnum 1 variable.output
{If non-zero, prevents fields that are structures or enums from having the
words "struct" or "enum" placed in front of them, making for more compact
output. Defaults to 1}]

[defvar printRegions 1 variable.output
{If non-zero, causes "print" to attempt to parse any region it finds,
printing out the size and bounds and type of region. Default value is 1}]

[defvar condenseSpecial 1 variable.output
{If non-zero, causes special PC GEOS structures (rectangles and output
descriptors, to name a couple) to be printed specially so as to present
more information in less space}]

[defvar condenseSmall 1 variable.output
{If non-zero, small (< 4 bytes) structures are printed on a single line
with each component considered as a signed integer}]

#
# isrecord
#	Decide if a given type is actually a record, returning 1 if so.
#	This is done by examining the number of bits and the type of the first
#	field in the type (it must be a structure type or an error will result)
#	If the two don't match, the type is a record (this is because the
#	type of each field in the record is declared to be a word).
#
[defsubr isrecord {type}
{
    [if {([catch {sym type $type} stype] == 0) && 
    	  ([string c $stype record] == 0)}
    {
    	return 1
    } elif {([string c [type class $type] struct] != 0) ||
    	    ([catch {index [type fields $type] 0} f1] != 0)}
    {
	#
	# type fields returned error -- can't be record
	#
	return 0
    } else {
    	return [expr {[type size [index $f1 3]]*8 != [index $f1 2]}]
    }]
}]

#
# threadname
#   	Given a thread's handle ID, return its name in the form
#   	    <patient>:<#>
#
[defsubr threadname {thread}
{
    var t [mapconcat i [thread all] {
    	    if {[string c $thread [thread id $i]] == 0} {
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
	if {[index $i 2] != 1 && ![null [index $i 0]]} {
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
[defsubr fmtstruct {type val offset space}
{
    global	alignFields noStructEnum intFormat printRegions
    global	condenseSpecial condenseSmall

    if {$condenseSpecial && ![string c [type class $type] struct]} {
	[case [type name $type {} 0] in
	    {struct Semaphore} {
	       var val [index [index $val 0] 2] thread [index [index $val 1] 2]
	       if {$thread != 0} {
		   echo -n [format {[%d, %04xh (%s)]} $val $thread
			    [threadname $thread]]
	       } else {
		   echo -n [format {[%d, empty]} $val]
	       }
	       return 1
	    }
	    {struct Rectangle} {
	       var s [format {(%s, %s) to (%s, %s)}
			       [index [index $val 0] 2]
			       [index [index $val 1] 2]
			       [index [index $val 2] 2]
			       [index [index $val 3] 2]]
	       if {[length $s chars] <= $space} {
		   echo -n $s
		   return 1
	       }
	    }
	    {struct OutputDescriptor|struct ObjectDescriptor} {
	       var odoff [index [index $val 0] 2]
	       var odseg [index [index $val 1] 2]
	       if {$odseg == 0xffff || $odseg == 0} {
		   echo -n Unconnected
		   return 1
	       }
	       if {[catch {handle lookup $odseg} odhan] || [null $odhan] ||
		   (![handle ismem $odhan] && ![handle isthread $odhan])} {
		   echo -n [format {Invalid (%04xh:%04xh)} $odseg $odoff]
	       } else {
		   if {$odhan == [handle owner $odhan]} {
		       echo -n [format {Process "%s", data = %04xh}
				       [patient name [handle patient $odhan]]
				       $odoff]
		   } elif {[handle isthread $odhan]} {
		       echo -n [format {%s, data = %04xh} 
				[threadname [handle id $odhan]] $odoff]
		   } else {
		       var csym [sym faddr var *(^l$odseg:$odoff).MB_class]
		       if {[null $csym]} {
			   echo -n [format {Obj, class ? at ^l%04xh:%04xh}
					   $odseg $odoff]
		       } else {
			   var cname [sym name $csym]
			   var tn [range $cname 0 [expr [string first Class $cname]-1] chars]
			   echo -n [format {Obj, class "%s", at ^l%04xh:%04xh}
					   $tn $odseg $odoff]
		       }
		   }
	       }
	       return 1
	    }
	    {struct TMatrix} {
	       # Print six fixed-point numbers as floats in a matrix
	       echo [format {\n%*s%16.8f %16.8f %16.8f} $offset {}
		       [expr [field $val TM_11H]+[field $val TM_11]/65536 f]
		       [expr [field $val TM_12H]+[field $val TM_12]/65536 f]
		       0]
	       echo [format {%*s%16.8f %16.8f %16.8f} $offset {}
		       [expr [field $val TM_21H]+[field $val TM_21]/65536 f]
		       [expr [field $val TM_22H]+[field $val TM_22]/65536 f]
		       0]
	       var sval [field $val TM_simple]
	       echo [format {%*s%16.8f %16.8f %16.8f} $offset {}
		       [expr [field $sval TM_31H]+[field $sval TM_31]/65536 f]
		       [expr [field $sval TM_32H]+[field $sval TM_32]/65536 f]
		       1]
	       # Same for the two inverses
	       echo [format {%*s        %16.8f %16.8f} $offset {}
		       [expr [field $val TM_xInvH]+[field $val TM_xInv]/65536 f]
		       [expr [field $val TM_yInvH]+[field $val TM_yInv]/65536 f]]
	       # finally all the flags
	       echo -n [format {%*s} $offset {}]
	       var f [assoc $sval TM_flags]
	       fmtrecord [index $f 1] [index $f 2] $offset
	       echo
	       return 0
	    }
	    {struct BBFixed} {
		echo -n [format {%.4f}
		    [expr [normalize $val BBF_int 256]+[field $val BBF_frac]/256 f]]
		return 1
	    }
	    {struct WBFixed} {
		echo -n [format {%.4f}
		    [expr [normalize $val WBF_int 65536]+[field $val WBF_frac]/256 f]]
		return 1
	    }
	    {struct WWFixed} {
		echo -n [format {%.6f}
		    [expr [normalize $val WWF_int 65536]+[field $val WWF_frac]/65536 f]]
		return 1
	    }
	    {struct DFixed} {
		echo -n [format {%.10f}
		    [expr [field $val DF_fracH]/65536+[field $val DF_fracL]/4294967296 f]]
		return 1
	    }
	    {struct WDFixed} {
		echo -n [format {%.10f}
		    [expr [normalize $val WD_int 65536]+[field $val WDF_fracH]/65536+[field $val WDF_fracL]/4294967296 f]]
		return 1
	    }
    	    {struct DDFixed} {
    	    	echo -n [format {%.10f}
		    [expr [normalize $val DDF_int 4294967296]+[field $val DDF_frac]/4294967296 f]]
		return 1
    	    }
	]
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
	    fmtval [index $i 2] [index $i 1] $offset
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
[defsubr fmtarray {val type class offset}
{
    var j [length $val]

    [case $class in
     struct {
    	foreach i $val {
	    echo -n [format {%*s\{} $offset {}]
	    var fret [fmtstruct $type $i [expr $offset+4]
				[expr [columns]-$offset-3]]
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
	    var j [expr $j-1]
    	    fmtval $i $type $offset [if {$j} {concat ,} {}] 
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
     int|enum|pointer {
    	foreach i $val {
    	    var j [expr $j-1]
    	    fmtval $i $type 0 [if {$j} {concat {, }} {}]  1
	}
     }
     default {
	foreach i $val {
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
[defsubr fmtval {val type offset {tail {}} {oneline 0}}
{
    var class [type class $type]

    [case $class in
     union|struct {
	if {[type size $type] == 0} {
		echo -n \{\}$tail
	} elif {![isrecord $type]} {
	    echo -n \{
	    if {[catch {wmove +0 +0} curpos] == 0} {
		var xpos [index $curpos 0]
	    } else {
    	    	# wild guess
		var xpos [expr $offset+25]
	    }
	    var fret [fmtstruct $type $val [expr $offset+4]
				[expr [columns]-$xpos-1]]
	    if {$fret} {
    	    	# All on one line -- no $offset needed
	        echo -n \}$tail
	    } else {
	        echo -n [format {%*s\}%s} $offset {} $tail]
	    }
	} else {
	    fmtrecord $type $val [expr $offset+4]
	    echo -n $tail
	}
     }
     array {
    	var adata [type aget $type]
    	var base [index $adata 0] len [expr [index $adata 2]-[index $adata 1]]
	var class [type class $base]

    	#
	# Decide whether to print the thing on this line. If it contains
	# fewer than 10 elements, each of which is less than 4 bytes long,
	# we print it on the same line. These limits are fairly arbitrary,
	# but have worked so far.
	#
    	if {($len < 10) && ([type size $base] < 4)} {
    	    echo -n \{
    	    fmtarray $val $base [type class $base] 0
	    echo -n \}$tail
	} else {
	    echo -n [format {\{\n%*s} $offset {}]
    	    fmtarray $val $base [type class $base] [expr $offset+4]
	    echo -n [format {\n%*s\}%s} $offset {} $tail] 
	}
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
		var seg [handle segment [index [value hfetch 0] 0]]
    	    	var off [value fetch $seg:$val [type word]]
		if {$off == 0xffff} {
		    echo -n empty$tail
    	    	} else {
		    var bl [expr [value fetch $seg:0 [type word]]]
		    var sz [expr [value fetch $seg:$off-2 [type word]]-2]
		    echo -n [format
			{%04xh [%d bytes at ^l%04xh:%04xh]}
				     $val $sz $bl $val]$tail
    	    	}
	     }
	     near|seg {
		echo -n [format %04xh $val]$tail
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
					[sym find type kernel::HandleTypes]]
		    echo -n [format {^h%04xh (type %s)} $val $sig]$tail
    	    	}
	     }
	     far {
		#
		# Print the thing out as segment:offset and symbolically
		#
		var s [expr ($val>>16)&0xffff] o [expr $val&0xffff]
		var sym [sym faddr any $s:$o]
		if {[null $sym]} {
		    echo -n [format %04xh:%04xh $s $o]$tail
		} else {
		    echo -n [format {%04xh:%04xh (%s)} $s $o
		    	    	     [symbol fullname $sym]]$tail
		}
	     }
	     object {
		if {$val & 1} {
		    var extra {parent }
		    var val [expr $val&~1]
		} else {
		    var extra {}
		}
	    	var h [expr ($val>>16)&0xfffff] l [expr $val&0xffff]
    	    	[if {($h&0xf) || [catch {handle lookup $h} han] ||
    	    	     [null $han] || ![handle ismem $han] ||
		     [catch {addr-parse ^l$h:$l} a]}
    	    	{
		    echo -n [format {%s^l%04xh:%04xh (Invalid)} $extra $h $l]
		} elif {[catch {sym faddr var {*(^l$h:$l).MB_class}} csym] ||
		    	[null $csym]}
    	    	{
		    echo -n [format {%s^l%04xh:%04xh (%04xh:%04xh)}
		    	     $extra $h $l
		    	     [handle segment [index $a 0]]
			     [index $a 1]]$tail
    	    	} else {
		    echo -n [format {%s^l%04xh:%04xh (%s@%04xh:%04xh)}
		    	     $extra $h $l
    	    	    	     [symbol fullname $csym]
		    	     [handle segment [index $a 0]]
			     [index $a 1]]$tail
	    	}]
    	     }
	    ]
    	}
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
	var left 32000
	var right -1
	# start out pointing at first yval
	var cp [expr $off+4] maxcp [expr $off+$size]
	var yval [value fetch $seg:$cp short]
	do {
	    # cp points at yValue
	    var bottom $yval
	    var cp [expr $cp+2]
	    #cp points at first on value for line
	    var firstOn [value fetch $seg:$cp short]
	    if {$firstOn != -32768} {
	        if {$firstOn < $left} {var left $firstOn}
		do {
	            var cp [expr $cp+4]
		} while {[value fetch $seg:$cp short] != -32768}
		# cp points at EOREGREC at end of line
	        var lastOn [value fetch $seg:$cp-2 short]
	        if {$lastOn > $right} {var right $lastOn}
	    }
	    var cp [expr $cp+2]
	    # cp points at yVal for start of next section
	    var yval [value fetch $seg:$cp short]
	} while {$yval != -32768 && $cp < $maxcp}
	if {$cp == $maxcp} {
	    echo [format {Bogus (longer than allocated chunk [%d bytes])}
			$size]
	} else {
	    echo [format {Complex (%d), bounds = (%d, %d, %d, %d)%s}
		    [expr {($cp-$off+2)/2}]
		    $left [expr {[value fetch $seg:$off short]+1}]
		    $right $bottom $tail]
	}
    }
}]

[defcommand print {args} output
{Prints the value of an expression. The expression may span multiple
arguments (i.e. you don't need to put {}'s around it). An expression is
usually an address that has a type or that is given a type by casting. The
contents of memory of the given type at that address is what's printed. If
the expression has no type, its offset part is printed in both hex and
decimal. This is used for printing registers, eg.

If the first argument begins with '-', it is taken to contain flags that
control how the value is printed.  Multiple flags may be given in the same
argument (in fact, this only pays attention to the first argument). The
flags are:
    x	integers (bytes, words, dwords if dwordIsPtr false) printed in hex
    d	integers printed in decimal
    o	integers printed in octal
    c	bytes printed as characters (byte arrays printed as strings, byte
	variables/fields printed as character followed by integer equivalent)
    C	bytes treated as integers
    a	align structure fields
    A	Don't align structure fields
    p	dwords are far pointers
    P	dwords aren't far pointers
These flags operate on the following TCL variables:
    intFormat		A printf format string for integers
    bytesAsChar		Treat bytes as characters if non-zero
    alignFields		Align structure fields if non-zero
    dwordIsPtr		DWord's are far pointers if non-zero
    noStructEnum    	If non-zero, doesn't print the "struct", "enum" or
    	    	    	"record" before the name of a structured/enumerated
			type -- just gives the type name.
    printRegions    	If non-zero, prints what a Region * points to (bounds
			and so on).			
    condenseSpecial	If non-zero, condense special structures (Rectangles,
			OutputDescriptors, ObjectDescriptors, TMatrixes and all
			fixed-point numbers) to one line.
}
{
    global intFormat byteAsChar alignFields dwordIsPtr
    [var oldIF $intFormat
    	 oldBAC $byteAsChar
	 oldAF $alignFields
	 oldDIP $dwordIsPtr]

    protect {
	if {[string m [index $args 0] -*]} {
	    #
	    # Gave us some flags
	    #
	    foreach i [explode [index $args 0]] {
		[case $i in
		    x {var intFormat %x}
		    d {var intFormat %d}
		    o {var intFormat %o}
		    a {var alignFields 1}
		    A {var alignFields 0}
		    c {var byteAsChar 1}
		    C {var byteAsChar 0}
		    p {var dwordIsPtr 1}
		    P {var dwordIsPtr 0}]
	    }
	    var args [cdr $args]
	}
	var addr [addr-parse $args]

	if {[null $addr]} {
	    error {Couldn't parse address}
	} elif {[null [index $addr 2]]} {
	    #
	    # Doesn't have any type -- print as a constant of some sort
	    #
	    if {[null [index $addr 0]]} {
		#
		# No handle either -- print offset in both hex and decimal
		#
		echo [format {%s = %04xh (%d)} $args [index $addr 1] 
			[index $addr 1]]
	    } else {
		#
		# Ah hah -- just wants to know the address.
		#
		echo [format {%s = %04xh:%04xh} $args 
			[handle segment [index $addr 0]] [index $addr 1]]
	    }
	} else {
	    #
	    # Fetch the actual value
	    #
    	    if {![null [index $addr 0]]} {
    	    	var val [value fetch ^h[handle id [index $addr 0]]:[index $addr 1]
			    [index $addr 2]]
    	    } else {
    	    	var val [value fetch [index $addr 1] [index $addr 2]]
    	    }
	    #
	    # Print the expression as given, and the number under which it's
	    # been stored in the value history (after storing it, of course)
	    #
	    echo -n @[value hstore $addr]: $args {= }
	    #
	    # Format the value list
	    #
	    fmtval $val [index $addr 2] 0
	    #
	    # If the argument string contained the last-history token (an @
	    # followed by an operator character or nothing), set up to repeat
	    # the thing. This is mostly to go down a list of objects easily.
	    #
	    if {[string match $args {*@[-.+^]*}] || [string match $args {*@}]} {
		global repeatCommand lastCommand
		var repeatCommand $lastCommand
	    }
	}
    } {
    	[var intFormat $oldIF
	    byteAsChar $oldBAC
	    alignFields $oldAF
	    dwordIsPtr $oldDIP]
    }
}]

[defdsubr prenum {enumtype val} print
{Given an enumerated TYPE and a VALUE, returns the appropriate enum constant.}
{
	return [type emap $val [sym find type $enumtype]]
}]

[defdsubr precord {recType val {silent 0}} print
{Given a record type and a value, print the proper bits...we'll
fill this in later}
{
    #
    # Locate the symbol token for the type. Bitch if undefined.
    #
    var t [sym find type $recType]
    if {[null $t]} {
	error [format {precord: %s: no such type defined} $recType]
    }

    #
    # Parse the value and use the offset.
    #
    var a [addr-parse $val]
    var n [index $a 1]

    #
    # Fetch the fields for the structure. This thing will nuke us if the
    # recType isn't really a record. 
    #

    if {![isrecord $t]} {
	error [format {precord: %s: not a record} $recType]
    }
    var flds [type fields $t]

    #
    # Build up a value list to pass to fmtrecord. The value list consists of
    # elements in the form:
    #	{name type value}
    # while the fields list is
    #	{name offset length type}
    #
    var v [map i $flds {
	[list [index $i 0]
	      [index $i 3]
	      [expr {($n>>[index $i 1])&((1<<[index $i 2])-1)}]]
    }]

    #
    # Finally, use fmtrecord to print the thing out properly
    #
    if {!$silent} {
	echo -n $val as $recType {= }
    }
    fmtrecord $t $v 4
    echo
}]
   
