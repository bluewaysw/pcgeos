#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		hugearr.tcl
# AUTHOR:	John Wedgwood, Mar 23, 1992
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 3/23/92	Initial revision
#   	jim 	 3/27/92    	Added pharray
#
# DESCRIPTION:
#	Huge-array related tcl code.
#
#	$Id: hugearr.tcl,v 1.22 94/09/22 08:56:16 adam Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
##############################################################################
#				pharray
##############################################################################
#
# SYNOPSIS:	Print useful info about a huge array
# PASS:		vmfile	- vmFile containing a huge-array
#   	    	dirblk   - HugeArray directory block handle 
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	3/27/92		Initial Revision
#
##############################################################################

[defcommand pharray {args} {print lib_app_driver.text}
{Usage:
    pharray [<flags>] [<vmfile> <dirblk>]

Examples:
    "pharray"	    	    Print the huge array at ^vbx:di (header only)
    "pharray  dx cx"   	    Print the huge array at ^vdx:cx (header only)
    "pharray -e"    	    Print the huge array at ^vbx:di and print the
    	    	    	    elements in the array
    "pharray -tMyStruct"    Print the huge array at ^vbx:di and print the
    	    	    	    elements where the elements are of type MyStruct
    "pharray -e3"    	    Print the huge array at ^vbx:di and print the
    	    	    	    third element
    "pharray -h"    	    Print the header of the HugeArray at ^vbx:di, using
    	    	    	    the default header type (HugeArrayDirectory).
    "pharray -hMyHeader"    Print the huge array at ^vbx:di (header only)
    	    	    	    where the header is of type MyHeader
    "pharray -d"    	    Print the directory elements of a HugeArray
    "pharray -e5 -l8"	    Print 8 HugeArray elements starting with number 5

Synopsis:
    Print information about a huge array.

Notes:
    * The flags argument can be any combination of the flags 'e', 't',
      and 'h'. The 'e' flag prints all elements. If followed by a 
      number "-e3", then only the third element is printed.

      The 't' flag specifies the elements' type. It should be followed
      immediately by the element type.  You can also use "gstring", in 
      which case the elements will be interpreted as GString Elements.

      The 'h' flag specifies the header type. It should be followed
      immediately by the element type.  If no options are specified, then
      "-hHugeArrayDirectory" is used.  If any other options are specified,
      then the printing of the header is disabled.  So, for example, if you 
      want both the header and the third element, use "-h -e3".

      The 'd' flag specifies that the HugeArray directory entries should
      be printed out.

      The 's' flag prints out a summary of the HugeArray block usage.

      The 'l' flag specified how many elements to print.

      All flags are optional and may be combined.

    * The address arguments are the VM file handle and the VM block handle
      for the directory block.  If nothing is specified, then bx:di is used.
}
{
    global geos-release

    var summary 0
    var delem 0
    var elements 0
    var gselem 0
    var etype {}
    var htype HugeArrayDirectory
    var pheader 1
    var elementnum -1
    var elRange 0
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		e {
    	    	    var pheader [expr $pheader-1]
		    var elements 1
		    if {[length $arg chars] > 1} {
			var elementnum [expr [range $arg 1 end chars]]
    	    	    	if {$elRange == 0} {
    	    	    	    var elRange 1
    	    	    	}
    	    	    	var arg {}
		    }
		}
		t {
    	    	    var pheader [expr $pheader-1]
		    var elements 1
		    if {[length $arg chars] > 1} {
			var etype [range $arg 1 end chars]
    	    	    	var arg {}
		    }
		}
    	    	l {
    	    	    var pheader [expr $pheader-1]
		    var elements 1
    	    	    if {[length $arg chars] > 1} {
			var elRange [expr [range $arg 1 end chars]]
    	    	    	var arg {}
		    }
    	    	}
		h {
    	    	    var pheader 10
    	    	    if {[length $arg chars] > 1} {
		    	var htype [range $arg 1 end chars]
    	    	    	var arg {}
    	    	    } 
		}
		d {
    	    	    var pheader [expr $pheader-1]
		    var delem 1
		}
		s {
    	    	    var pheader [expr $pheader-1]
		    var summary 1
		}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }
    if {[length $args] == 0} {
        var vmfile bx
    	var dirblk  di
    } else {
	var vmfile [index $args 0]
	var dirblk [index $args 1]
    }

    ensure-vm-block-resident $vmfile [getvalue $dirblk]
    var addr [addr-parse ^v$vmfile:$dirblk]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    var dstate [handle state [index $addr 0]]

    # Print the header, but only if it is resident.  And only if it's wanted.
    # If it isn't there, then we can't do too much.

    if {$pheader >= 1} {
    	if {$dstate & 0x0001} {
            echo [format {--- Header (%s)---} $htype]
            print $htype $seg:$off
    	} else {
            echo [format {*** Sorry, directoy block is not resident ***}]
            var elements 0
            var delem 0
    	}
    }

    # If they want the Directory entries printed, print them.  Order them
    # in a nice tabular format

    if {$delem} {
        pcarray -H -tHugeArrayDirEntry *$seg:[value fetch $seg:$off.HAD_dir]
    }

    # If they want a summary of the HugeArray, give it to them nicely.

    if {$summary} {
        var dirch  [value fetch $seg:$off.HAD_dir]
    	var diroff [value fetch $seg:$dirch word]
        var ndirel [expr ([value fetch $seg:$diroff.CAH_count word])-1]
        var diroff [expr $diroff+[size ChunkArrayHeader]+[size HugeArrayDirEntry]]
        var firstel 0
        var blkNum 0
    	echo [format {\t\tHugeArray Block Summary}]
    	echo [format {Block\tFirstEl\tLastEl\tNumEl\tBlkSize\tBlockLocation}]
    	echo [format {-----\t-------\t------\t-----\t-------\t-------------}]
    	for {var curdir $ndirel} {$curdir > 0} {var curdir [expr $curdir-1]} {
            var lastel [value fetch $seg:$diroff.HADE_last]
    	    var dblk [value fetch $seg:$diroff.HADE_handle]
    	    var blkSize [value fetch $seg:$diroff.HADE_size]
    	    echo [format {%d\t%d\t%d\t%d\t%d\t^v%4xh:%04xh} $blkNum $firstel $lastel [expr $lastel-$firstel+1] $blkSize $vmfile $dblk]
    	    var blkNum [expr $blkNum+1]
    	    var firstel [expr $lastel+1]
    	    var diroff [expr $diroff+[size HugeArrayDirEntry]]
	}
    }

    # OK, here's the real work.  For each data block, print the elements 
    # that we'd like to see.  Step through the data blocks by stepping through
    # the directory entries.  If the data block is not resident, just bail.

    if {$elements} {
        var dirch  [value fetch $seg:$off.HAD_dir]
    	var diroff [value fetch $seg:$dirch word]
        var ndirel [expr ([value fetch $seg:$diroff.CAH_count word])-1]
        var diroff [expr $diroff+[size ChunkArrayHeader]+[size HugeArrayDirEntry]]
        var curel 0
    	for {var curdir $ndirel} {$curdir > 0} {var curdir [expr $curdir-1]} {
            var curend [value fetch $seg:$diroff.HADE_last]
    	    var dblk [value fetch $seg:$diroff.HADE_handle]
	    ensure-vm-block-resident $vmfile $dblk
    	    var daddr [addr-parse ^v$vmfile:$dblk]
    	    var dseg [handle segment [index $daddr 0]]
    	    var doff [index $daddr 1]
    	    var dstate [handle state [index $daddr 0]]
    	    if {$dstate & 0x0001} {
    	        if {$elementnum == -1} {
    	    	    if {$elRange == 0} {
       	    	    	pcarray -b$curel -H -t$etype -e *$dseg:HUGE_ARRAY_DATA_CHUNK
    	    	    } elif {[expr $curend-$curel+1] < $elRange} {
       	    	    	pcarray -b$curel -H -t$etype -e *$dseg:HUGE_ARRAY_DATA_CHUNK
    	    	    	var elRange [expr $elRange-[expr $curend-$curel+1]]
    	    	        var elementnum [expr $curend+1]
    	    	    } else {
       	    	    	pcarray -b$curel -H -t$etype -e -l$elRange *$dseg:HUGE_ARRAY_DATA_CHUNK
    	    	        var elementnum 0
    	    	    }
    	        } elif {($elementnum >= $curel) && ($elementnum <= $curend)} {
    	    	    var canum [expr $elementnum-$curel]
    	    	    if {[expr $curend-$elementnum+1] > $elRange} {
    	    	    	var calen $elRange
    	    	    } else {
    	    	    	var calen [expr $curend-$elementnum+1]
    	    	    	var elRange [expr $elRange-$calen]
    	    	    	var elementnum [expr $curend+1]
    	    	    }
    	    	    pcarray -b$curel -H -e$canum -l$calen -t$etype *$dseg:HUGE_ARRAY_DATA_CHUNK
    	    	}
    	    } else {
    	        echo [format {--- HA elements %d thru %d ---} $curel $curend]
    	        echo [format {\t*** Sorry, data block is not resident ***}]
    	    }
    	    var diroff [expr $diroff+[size HugeArrayDirEntry]]
    	    var curel [expr $curend+1]
    	}   	    	
    }
}]

##############################################################################
#				harray-enum
##############################################################################
#
# SYNOPSIS:	Enumerate the elements of a huge-array.
# CALLED BY:	Utility
# PASS:		file	- File containing a huge-array
#   	    	arrayHan- Array handle (vm block handle)
#   	    	callback- Tcl function to call for each element
#   	    	extra   - A list of stuff to pass to the callback
# RETURN:	0   	    If all elements were processed
#   	    	non-zero    Otherwise
# SIDE EFFECTS:	none
#
# STRATEGY
#   The callback should be defined as taking three arguments:
#   	    elementNum	- The element number (numbered from 0)
#   	    elementAddr	- Address expression of the element
#   	    elementSize	- Size of the element
#   	    extra   	- The same list of information passed in
#
#   A huge-array is organized like:
#   	Directory block (we get passed the address of one)
#   	    Contains "first" link to first data block
#
#   	Data block:
#   	    Contains "next" link to next data block
#   	    Contains chunk-array of elements
#
#   We grab the first data block and use carray-enum to process the entries.
#   We continue until there are no more blocks.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 3/23/92	Initial Revision
#
##############################################################################
[defsubr harray-enum {file arrayHan callback extra}
{
    require carray-enum-internal chunkarr
    #
    # Start at the start...
    #
    var curElement 0
    var abort 0

    #
    # Get the first data block
    #
    ensure-vm-block-resident $file $arrayHan
    var blockHan [value fetch (^v$file:$arrayHan).HAD_data word]

    #
    # Process each block
    #
    var chan [symbol get [symbol find const HUGE_ARRAY_DATA_CHUNK]]

    while {($blockHan != 0) && ($abort == 0)} {
	#
	# Get the address of the chunk-array
	#
	ensure-vm-block-resident $file $blockHan
	var addr [addr-parse *(^v$file:$blockHan):$chan]
	var seg  [handle segment [index $addr 0]]
	var off  [index $addr 1]
	
	#
	# Enumerate the entries
	#
        var abort [carray-enum-internal $curElement $seg:$off $callback $extra]
	
	#
	# Advance the counter by adding the number of elements in this
	# chunk array.
	#
    	var caAddr     [get-carray-addr $file $blockHan]
	var caCount    [value fetch ($caAddr).CAH_count]
	var curElement [expr $curElement+$caCount]

	#
	# Move to the next block
	#
	var blockHan [value fetch $seg:HAB_next]
    }
    
    return $abort
}]

##############################################################################
#				harray-enum-raw
##############################################################################
#
# SYNOPSIS:	Process the elements of an array in hunks
# CALLED BY:	Global
# PASS:		file	- File containing a huge-array
#   	    	arrayHan- Array handle (vm block handle)
#   	    	callback- Tcl function to call for each element
#   	    	start	- Place to start from
#   	    	extra   - A list of stuff to pass to the callback
# RETURN:	0   	    If all elements were processed
#   	    	non-zero    Otherwise
# SIDE EFFECTS:	none
#
# STRATEGY
#   The callback should be defined as taking three arguments:
#   	    elementNum	- The element number (numbered from 0)
#   	    elementAddr	- Address expression of the element
#   	    count	- Number of valid elements at elementAddr
#   	    extra   	- The same list of information passed in
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/13/92	Initial Revision
#
##############################################################################
[defsubr harray-enum-raw {file arrayHan callback start extra}
{
    require carray-get-element-addr chunkarr.tcl

    #
    # Get the first data block
    #
    var blockHan [value fetch (^v$file:$arrayHan).HAD_data word]
    ensure-vm-block-resident $file $blockHan
    
    #
    # Setup up our own counter
    #
    var pos $start

    #
    # Find the data-block which contains the information we want
    #
    var elNum 0
    while {$blockHan != 0} {
	#
	# Get the address of the chunk-array
	#
	var caAddr [get-carray-addr $file $blockHan]
	
	#
	# Compare the position we want with the count of elements in this
	# part of the array to see if we've found the right block.
	#
	var caCount [value fetch ($caAddr).CAH_count word]

	if {$pos < $caCount} {
	    #
	    # We've found the block, start the enumeration
	    #
	    var elAddr  [carray-get-element-addr $caAddr $pos $t]
	    var elCount [expr $caCount-$pos]
	    var elNum   [expr $elNum+$pos]
	    
	    var abort 0
	    while {$abort == 0} {
		#
		# Call the callback passing it the address, count, etc
		#
		var abort [uplevel 1 [list $callback
					   $elNum
					   $elAddr
					   $elCount
					   $extra]]
		#
		# Update the current element to be at the start of the next
		# chunk-array block
		#
    	    	var elNum [expr $elNum+$elCount]

		if {$abort == 0} {
		    #
		    # Callback did not abort, move to the next block
		    #
	    	    var blockHan [value fetch (^v$file:$blockHan).HAB_next word]
    	    	    ensure-vm-block-resident $file $blockHan
		    if {$blockHan == 0} {
		    	return $abort
		    }
	    	    var caAddr [get-carray-addr $file $blockHan]
		    #
		    # We pass back all the entries in this chunk-array
		    #
		    var elAddr  $caAddr
	    	    var elCount [value fetch ($caAddr).CAH_count word]
    	    	}
    	    }
	    return $abort
	}
	
	#
	# Keep searching for that block
	#
	var pos   [expr $pos-$caCount]
    	var elNum [expr $elNum+$caCount]

	#
	# Move to the next block
	#
	var blockHan [value fetch (^v$file:$blockHan).HAB_next word]
    	ensure-vm-block-resident $file $blockHan
    }
    return 0
}]

##############################################################################
#				harray-get-element
##############################################################################
#
# SYNOPSIS:	Fetch an element of a huge-array
# CALLED BY:	Global
# PASS:		file	- File containing the array
#   	    	arr 	- Array vm-block
#   	    	pos 	- Element number to retrieve
#   	    	t   	- Type of data to get
# RETURN:   	d	- Data from the huge-array
#   	    	Returns nil if there is no such element
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
[defsubr harray-get-element {file arrayHan pos t}
{
    #
    # Get the first data block
    #
    var blockHan [value fetch (^v$file:$arrayHan).HAD_data word]

    #
    # Process each block
    #
    while {$blockHan != 0} {
	#
	# Get the address of the chunk-array
	#
	var chan [symbol get [symbol find const HUGE_ARRAY_DATA_CHUNK]]
	var addr [addr-parse *(^v$file:$blockHan):$chan]
	var seg  [handle segment [index $addr 0]]
	var off  [index $addr 1]
	
	#
	# Compare the position we want with the count of elements in this
	# part of the array to see if we've found the right block.
	#
	var caCount [value fetch $seg:$off.CAH_count word]

	if {$pos < $caCount} {
	    #
	    # We've found the block...
	    #
	    return [carray-get-element $seg:$off $pos $t]
	}
	
	var pos [expr $pos-$caCount]

	#
	# Move to the next block
	#
	var blockHan [value fetch (^v$file:$blockHan).HAB_next word]
    }
    return {}
}]

[defsubr get-carray-addr {file blockHan}
{
    var chan [symbol get [symbol find const HUGE_ARRAY_DATA_CHUNK]]
    var addr [addr-parse *(^v$file:$blockHan):$chan]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]

    return $seg:$off
}]
##############################################################################
#				phastats
##############################################################################
#
# SYNOPSIS:	Print some stats about HugeArray compaction (to be used in
#   	    	conjunction with special code in vmemHugeArray.asm.  This 
#   	    	is conditionally assembled by defining the constant 
#   	    	MEASURE_HUGE_ARRAY_COMPACTION.
# CALLED BY:	Global
# PASS:		nothing
# RETURN:   	prints a report of huge array block compaction
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	 8/23/93	Initial Revision
#
##############################################################################
[defcommand phastats {} {}
{Usage:
    phastats 	    	- needs a special kernel.  See vmemHugeArray.asm
}
{
echo [format {total\tZero\t<12.5\t<25\t<50\t>50}]
var total [value fetch kcode::totalChecked]
var zero [value fetch kcode::totalZero]
var eigth [value fetch kcode::totalEigth]
var quarter [value fetch kcode::totalQuarter]
var half [value fetch kcode::totalHalf]
var moreHalf [value fetch kcode::totalMoreHalf]
var zeroP [expr $zero*100/$total float]
var eigthP [expr $eigth*100/$total float]
var quarterP [expr $quarter*100/$total float]
var halfP [expr $half*100/$total float]
var moreHalfP [expr $moreHalf*100/$total float]
echo [format {%d\t%d\t%d\t%d\t%d\t%d} $total $zero $eigth $quarter $half $moreHalf]
echo [format {\t%4.1f\t%4.1f\t%4.1f\t%4.1f\t%4.1f} $zeroP $eigthP $quarterP $halfP $moreHalfP]
echo [format {LMemContract was called %d times} [value fetch kcode::countLMemContract]]
}]
##############################################################################
#				clrhastats
##############################################################################
#
# SYNOPSIS:	clears statistics gathering variables in the kernel.  Used in
#   	    	conjunction with special code in vmemHugeArray.asm.  This 
#   	    	is conditionally assembled by defining the constant 
#   	    	MEASURE_HUGE_ARRAY_COMPACTION.
# CALLED BY:	Global
# PASS:		nothing
# RETURN:   	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	 8/23/93	Initial Revision
#
##############################################################################
[defcommand clrhastats {} {}
{Usage:
    clrhastats 	    	- needs a special kernel.  See vmemHugeArray.asm
}
{
assign kcode::totalChecked 0
assign kcode::totalZero 0
assign kcode::totalEigth 0
assign kcode::totalQuarter 0
assign kcode::totalHalf 0
assign kcode::totalMoreHalf 0
assign kcode::countLMemContract 0
}]

