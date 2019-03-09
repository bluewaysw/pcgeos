#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Text Object
# FILE:		chunkarr.tcl
# AUTHOR:	Tony Requist, July 18, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pcarray    	    	Print a chunk array
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	7/91		Initial revision
#	sk	2/94		Added -L to pcarray
#
# DESCRIPTION:
#	This file contains TCL routines to print out chunk arrays
#
#	$Id: chunkarr.tcl,v 1.29.9.1 97/03/29 11:27:05 canavese Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

[defcommand pcarray {args} print
{Usage:
    pcarray [<flags>] [<address>]

Examples:
    "pcarray"	    	    Print the chunk array at *ds:si (header only)
    "pcarray es:di"    	    Print the chunk array at es:di (header only)
    "pcarray -e"    	    Print the chunk array at *ds:si and print the
    	    	    	    elements in the array
    "pcarray -tMyStruct"	    Print the chunk array at *ds:si and print the
    	    	    	    elements where the elements are of type MyStruct
    "pcarray -tMyStruct -TMyExtraStruct"	    Like above, but data after MyStruct
    	    	    	    	    	    is printed as an array of
    	    	    	    	    	    MyExtraStruct structures
    "pcarray -e3"    	    Print the chunk array at *ds:si and print the
    	    	    	    third element
    "pcarray -e3 -l8"       Print the chunk array at *ds:si and print eight 
    	    	    	    elements starting with the third element
    "pcarray -hMyHeader"    Print the chunk array at *ds:si (header only)  where
    	    	    	    the header is of type MyHeader
    "pcarray -fVTCA_size"   Print only the field VTCA_size from each element
    "pcarray -E"    	    This is an element array.  Don't print empty
    	    	    	    elements
    "pcarray -N"    	    This is a name array.  Print the names.

Synopsis:
    Print information about a chunk array.

Notes:
    * The flags argument can be any combination of the flags 'e', 't',
      and 'h'. The 'e' flag prints all elements. If followed by a 
      number "-e3", then only the third element is printed.

      The 't' flag specifies the elements' type. It should be followed
      immediately by the element type.  You can also use "-tgstring" if
      the elements are GString Elements.

      The 'h' flag specifies the header type. It should be followed
      immediately by the element type.

      The 'l' flag specifies how many elements to print.  It can be used in
      conjunction with the 'e' flag to print a range of element numbers.

      The 'H' flag supresses printing of the header.

      The 'L' flag indicates that the elements in the array are actually
      lptrs to chunks in the same block as the array and should be 
      dereferenced before printing the elements.

      All flags are optional and may be combined.

    * The address argument is the address of the chunk array. If not 
      specified then *ds:si is used.

    * The 'Y' flag is a special flag for debugging nested calls -- use at
      your own peril.

}
{
    global geos-release
    global dbcs

    var elements 0
    var etype {}
    var extype {}
    var htype ChunkArrayHeader
    var elementnum -1
    var elementArray 0
    var nameArray 0
    var printHeader 1
    var elBase 0
    var elRange 0
    var callInfo 0
    var lptrArray 0
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		e {
		    var elements 1
		    if {[length $arg chars] > 1} {
			var elementnum [expr [range $arg 1 end chars]]
    	    	    	var arg {}
    	    	    	if {$elRange == 0} {
    	    	    	    var elRange 1
    	    	    	}
		    }
		}
    	    	l {
    	    	    var elements 1
		    if {[length $arg chars] > 1} {
			var elRange [expr [range $arg 1 end chars]]
    	    	    	var arg {}
		    }
    	    	}
		t {
		    var elements 1
		    if {[length $arg chars] > 1} {
			var etype [range $arg 1 end chars]
    	    	    	var arg {}
		    }
    	    	    # 
    	    	    # if we're printing gstring elements, load the file with
    	    	    # the function to print them
    	    	    #
#    	    	    if {[string c $etype gstring]} {
#    	    	    	required pgselem pvm
#    	    	    }
		}
		T {
		    var extype [range $arg 1 end chars]
    	    	    var arg {}
		}
		h {
		    var htype [range $arg 1 end chars]
    	    	    var arg {}
		}
		f {
    	    	    var elements 1
		    var field [range $arg 1 end chars]
    	    	    var arg {}
		}
		E {
    	    	    if {![string c $htype ChunkArrayHeader]} {
    	    	    	var htype ElementArrayHeader
    	    	    }
		    var elementArray 1
		}
		N {
    	    	    if {![string c $htype ChunkArrayHeader]} {
    	    	    	var htype NameArrayHeader
    	    	    }
		    var elementArray 1 nameArray 1
		}
    	    	H {
    	    	    var printHeader 0
    	    	}
		b {
		    if {[length $arg chars] > 1} {
			var elBase [expr [range $arg 1 end chars]]
    	    	    	var arg {}
		    }
		}
    	    	Y {
    	    	    var callInfo 1
    	    	}
		L {
    	    	    var elements 1
		    var lptrArray 1
		}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }
    if {[length $args] == 0} {
	var address *ds:si
    } else {
	var address [index $args 0]
    }

    var addr [addr-parse $address]
    #var seg [handle segment [index $addr 0]]
    var seg ^h[handle id [index $addr 0]]
    var off [index $addr 1]

    # Print the header

    if {$printHeader} {
    	echo [format {--- Header (%s)---} $htype]
    	print $htype $seg:$off
    }

    #
    # Print calling information if requested
    #
    if {$callInfo} {
    	echo -n {--- calling frames }
    	if {[value fetch $seg:$off.CAH_elementSize]} {
    	    echo {(fixed) ---}
    	} else {
    	    echo {(variable) ---}
    	}
    	var curOff [value fetch $seg:$off.CAH_curOffset]
    	if {$curOff} {
    	    for {var fnum 1} {$curOff} {var fnum [expr $fnum+1]} {
    	    	var cOff [value fetch ss:$curOff.SCOS_curOffset]
    	    	echo [format {  %d:  current offset = %d} $fnum $cOff]
    	    	var curOff [value fetch ss:$curOff.SCOS_next]
    	    }
    	} else {
    	    echo {  <none>}
    	}
    }

    if {$elements} {
	var elsize [value fetch $seg:$off.CAH_elementSize word]
	var chunksize [expr [value fetch $seg:$off-2 word]-2]
	if {${geos-release} >= 2} {
	    var eoff [expr $off+[value fetch $seg:$off.CAH_offset]]
	} else {
	    var eoff [expr $off+[size ChunkArrayHeader]]
	}

	if {($elementnum == -1)                    } {
#                               || ($elsize == 0)
# I cant figure out why var sized elements would need to run in this case...
# sk Aug-3-94
#
    	    var first 0
    	    if {($elRange == 0) || ($elRange > [value fetch $seg:$off.CAH_count])} {
    	    	var last [value fetch $seg:$off.CAH_count]
    	    } else {
    	    	var last $elRange
    	    }
    	} else {
    	    var first $elementnum
    	    var last [expr $elementnum+$elRange]
    	    if {$last > [value fetch $seg:$off.CAH_count]} {
    	    	var last [value fetch $seg:$off.CAH_count]
    	    }
    	    var eoff [expr $eoff+($elsize*$elementnum)]
    	}
	if {$nameArray} {
	    var nameOff [expr [value fetch $seg:$off.NAH_dataSize]+[size NameArrayElement]]
	}
	for {var el $first} {$el < $last} {var el [expr $el+1]} {
    	    if {$elsize == 0} {
# $nextoff used to be set to the size of the chunk if $el == $last-1, this is silly
# since $last might not be the last element in the chunkarray!
# sk Aug-3-94
    	    	if {$el == [value fetch $seg:$off.CAH_count]-1} {
    	    	    var nextoff $chunksize
    	    	} else {
    	    	    var nextoff [value fetch $seg:$eoff+2 word]
    	    	}
    	    	var thissize [expr $nextoff-[value fetch $seg:$eoff word]]
    	    	var dataoff [expr $off+[value fetch $seg:$eoff word]]
    	    	var addsize 2
    	    } else {
    	    	var thissize $elsize
    	    	var addsize $elsize
    	    	var dataoff $eoff
    	    }
#
# if it is an lptr array, deref it and find the size of the chunk
#
	    if {$lptrArray} {
		var lptraddr [value fetch $seg:$dataoff word]
		var dataoff  [value fetch $seg:$lptraddr word]
		var thissize [expr [value fetch $seg:$dataoff-2 word]-2]
	    }

    	    var freeFlag 0
    	    if {$elementArray} {
    	    	if {[value fetch $seg:$dataoff.REH_refCount.WAAH_high]
    	    	    	    	    	    	    	    	== 0xff} {
    	    	    var freeFlag 1
    	    	}
    	    }
    	    if {$freeFlag} {
		echo [format {--- Element #%d is FREE ---} [expr $el+$elBase]]
    	    } elif {($elementnum == -1) || ($el >= $elementnum)} {
		if {![null $field]} {
		    echo [format {--- Element #%d ---} [expr $el+$elBase]]
	    	    print $seg:$dataoff.$field
		} elif {[null $etype]} {
		    echo [format {--- Element #%d ---} [expr $el+$elBase]]

		    bytes $seg:$dataoff $thissize
		    if {$nameArray} {
			var extra [expr $thissize-$nameOff]
			if {$extra > 0} {
		    	    echo -n {Name: }
    	    	    	    if {[null $dbcs]} {
    	    	    	    	pstring -l $extra $seg:$dataoff+$nameOff
    	    	    	    } else {
    	    	    	    	pstring -l [expr $extra/2] $seg:$dataoff+$nameOff
    	    	    	    }
    	    	    	}
    	    	    }
    	    	} elif {[string c $etype gstring]==0} {
    	    	    pgselem $seg:$dataoff $thissize
		} else {
		    echo [format {--- Element #%d (%s) ---} [expr $el+$elBase] $etype]
		    print $etype $seg:$dataoff
		    if {![null $extype] || $nameArray} {
    	    	    	if {$nameArray} {
			    var extra [expr $thissize-[size $etype]]
			    if {$extra > 0} {
    	    	    	    	echo -n {Name: }
				var exdata [expr $dataoff+[size $etype]]
    	    	    	    	if {[null $dbcs]} {
    	    	        	    pstring -l $extra $seg:$exdata
    	    	    	    	} else {
    	    	    	    	    pstring -l [expr $extra/2] $seg:$exdata
    	    	    	    	}
    	    	    	    }
    	    	    	} else {
			    var extra [expr
				($thissize-[size $etype])/[size $extype]]
			    if {$extra > 0} {
				print $extype $seg:$dataoff+[size $etype] #$extra
    	    	    	    }
			}
		    }
    	    	}
    	    }
	    var eoff [expr $eoff+$addsize]
	}
    }
}]

##############################################################################
#				carray-enum
##############################################################################
#
# SYNOPSIS:	Enumerate the elements of a chunk-array.
# CALLED BY:	Utility
# PASS:		address	- Address expression of a ChunkArray
#   	    	callback- Tcl function to call for each element
#   	    	extra	- A list of stuff to pass to the callback
# RETURN:	0   	    if all elements were processed
#   	    	non-zero    otherwise
# SIDE EFFECTS:	none
#
# STRATEGY
#   The callback should be defined as taking three arguments:
#   	    elementNum	- The element number (numbered from 0)
#   	    elementAddr	- Address expression of the element
#   	    elementSize	- Size of the element.
#    	    	    	  For fixed-size elements, this is the count of the
#   	    	    	  number of elements after the current one.
#   	    extra   	- The same list of information passed in
#   If it returns non-zero, enumeration will cease.
#
#   It is called within the caller of carray-enum's context. Since the callback
#   is itself a Tcl procedure, "uplevel 1" will get you to the variables of
#   the caller of carray-enum.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/30/92	Initial Revision
#
##############################################################################
[defsubr carray-enum {address callback {extra {}}}
{
    return [uplevel 1 [list carray-enum-internal 0 $address $callback $extra]]
}]


##############################################################################
#				carray-enum-internal
##############################################################################
#
# SYNOPSIS:	Enumerate a chunk-array starting with a given number.
# CALLED BY:	carray-enum, harray-enum
# PASS:		start	- Number to give first element
#   	    	address, callback, extra - same as carray-enum
# RETURN:	same as carray-enum
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 3/23/92	Initial Revision
#
##############################################################################
[defsubr carray-enum-internal {start address callback extra}
{
    #
    # Parse the address expression into something meaningful
    #
    var addr [addr-parse $address]
    var seg  ^h[handle id [index $addr 0]]
    var off  [index $addr 1]

    #
    # Get the size of the elements and the size of the whole array
    #
    var elsize	  [value fetch $seg:$off.CAH_elementSize word]
    var chunksize [expr [value fetch $seg:$off-2 word]-2]
    
    #
    # Compute the offset to the start of the elements
    #
    var eoff	  [expr $off+[value fetch $seg:$off.CAH_offset]]

    #
    # Define the range of elements to use
    #
    var first 0
    var last  [value fetch $seg:$off.CAH_count]

    #
    # Now callback for each element
    #
    var abort 0
    for {var el $first} {($el < $last) && ($abort == 0)} {var el [expr $el+1]} {
	#
	# Compute the size of the current element and the offset to the
	# next element.
	#
	if {$elsize == 0} {
	    #
	    # Variable sized elements.
	    #
	    if {$el == $last-1} {
		var nextoff $chunksize
	    } else {
		var nextoff [value fetch $seg:$eoff+2 word]
	    }
	    var thissize [expr $nextoff-[value fetch $seg:$eoff word]]
	    var dataoff  [expr $off+[value fetch $seg:$eoff word]]
	    var addsize  2
	    #
	    # Now...
	    #   seg	    - Segment containing the chunk array
	    #   dataoff - Offset to this element
	    #   thissize- Size of this element
	    #
	    var abort [uplevel 1 [list $callback [expr $el+$start] 
	    	    	    	  $seg:$dataoff 
				  $thissize 
				  $extra]]
	} else {
	    #
	    # Fixed size elements
	    #
	    var thissize $elsize
	    var addsize  $elsize
	    var dataoff  $eoff
	    #
	    # Now...
	    #   seg	    - Segment containing the chunk array
	    #   dataoff - Offset to this element
	    #   thissize- Size of this element
	    #
	    var abort [uplevel 1 [list $callback [expr $el+$start] 
	    	    	    	  $seg:$dataoff 
				  [expr $last-$el]
				  $extra]]
	}
	
	var eoff [expr $eoff+$addsize]
    }
    
    return $abort
}]

##############################################################################
#				carray-get-element
##############################################################################
#
# SYNOPSIS:	Get an element of a chunk-array
# CALLED BY:	Utility
# PASS:		addr	- Address of the chunk-array
#   	    	el  	- Element number to get
#   	    	t   	- Type of the element
# RETURN:	data	- Retrieved element
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/13/92	Initial Revision
#
##############################################################################
[defsubr carray-get-element {address el t}
{
    
    return [value fetch [carray-get-element-addr $address $el $t] $t]
}]


[defsubr carray-get-element-addr {address el {t {}}}
{
    #
    # Parse the address expression into something meaningful
    #
    addr-preprocess $address seg off

    #
    # Get the size of the elements and the size of the whole array
    #
    var elsize	  [value fetch $seg:$off.CAH_elementSize]
    var elcount	  [value fetch $seg:$off.CAH_count]
    var chunksize [expr [value fetch $seg:$off-2 word]-2]
    
    #
    # Compute the offset to the start of the elements
    #
    var eoff	  [expr $off+[value fetch $seg:$off.CAH_offset]]

    if {$el >= $elcount} {
    	error [format {cannot get element %d from %s: only %d %s in the array}
	    	$el $address $elcount [pluralize element $elcount]]
    }

    if {$elsize != 0} {
    	#
	# Fixed size, so can just compute this
	#
	var dataoff [expr $eoff+$el*$elsize]
    } else {
    	#
	# Must index into the table of offsets, instead.
	#
	var dataoff [expr $off+[value fetch $seg:$eoff+2*$el word]]
    }
    
    return $seg:$dataoff
}]


[defsubr carray-get-element-size {address el}
{
    #
    # Parse the address expression into something meaningful
    #
    addr-preprocess $address seg off

    #
    # Get the size of the elements and the size of the whole array
    #
    var elsize	  [value fetch $seg:$off.CAH_elementSize]
    if {$elsize != 0} {
    	return $elsize
    }
    
    var elcount	  [value fetch $seg:$off.CAH_count]
    
    if {$el >= $elcount} {
    	error [format {cannot get size for element %d from %s: only %d %s in the array}
	    	$el $address $elcount [pluralize element $elcount]]
    }

    #
    # Compute the offset to the start of the elements
    #
    var eoff	  [expr $off+[value fetch $seg:$off.CAH_offset]]

    #
    # Must index into the table of offsets.
    #
    var dataoff [expr $off+[value fetch $seg:$eoff+2*$el word]]
    
    if {$el == $elcount-1} {
    	return [expr [value fetch $seg:$off-2 word]-2-($dataoff-$off)]
    } else {
    	return [expr $off+[value fetch $seg:$eoff+2*($el+1) word]-$dataoff]
    }
}]
