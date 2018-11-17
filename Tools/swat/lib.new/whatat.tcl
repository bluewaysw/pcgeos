##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	whatat.tcl
# AUTHOR: 	Tony
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	whatat	    	    	Print an object out given its address.
#
# DESCRIPTION:
#	A function to print the name of a variable at an address
#
#	$Id: whatat.tcl,v 3.8.11.1 97/03/29 11:27:20 canavese Exp $
#
###############################################################################

[defcmd whatat {{addr *ds:si}} top.print
{Usage:
    whatat [<address>]

Examples:
    "whatat"    	    	name of variable at *ds:si
    "whatat ^l2ef0h:002ah"	name of variable at the specified address

Synopsis:
    Print the name of the variable at the address.

Notes:
    * The address argument specifies where to find a variable name
      for.  The address defaults to *ds:si.

    * If no appropiate variable is found for the address, '*nil*' is returned.

See also:
    pobj, hwalk, lhwalk.
}
{
    #
    # Look for a variable near the address
    #
    var a [sym faddr var $addr]
    if {[null $a]} {
	echo *nil*
    } else {
	#
	# Parse the address down to seg + offset so we can figure out what the
	# difference is between the symbol found and the address.
	#
	addr-preprocess $addr s o
    	#
	# Find the offset and type of the symbol
	#
    	var d [symbol get $a]
    	#
	# Figure the difference from the base, and the type of the variable.
	#
	var diff [expr $o-[index $d 0]] t [index $d 2]
    	#
	# $n and $fn hold the simple and full (i.e. with patient & module)
	# versions of the part of the variable the address represents. They
	# are built up in the coming loop
	#
	var n [symbol name $a]
	var fn [symbol fullname $a]
    	#
	# Loop to narrow the address down to part of the variable. We cope with
	# structures and arrays, here...
	#
	for {} {1} {} {
	    [case [type class $t] in
	     struct {
    	    	#
		# First find the field in which the offset falls
		#
	     	var f [type field $t $diff]
		if {[null $f]} {
    	    	    # the thing we found doesn't actually reach to the place
		    # in question. Sigh.
		    break
    	    	}
    	    	#
		# Tack the field name onto both the simple and full versions of
		# the name.
		#
		var n $n.[index $f 0]
		var fn $fn.[index $f 0]
    	    	#
		# Since we can't get the offset of the field in question from
		# the data we get back, we now have to parse the full variable-
		# part string down to another segment and offset so we can
		# figure the offset within this part of the variable...
		#
		addr-preprocess $fn s q
		var diff [expr $o-$q]
		var t [index $f 2]
    	     }
	     array {
    	    	#
		# Find in which element of the array the offset falls. First we
		# need to find the base type of the array.
		#
	     	var ad [type aget $t]
		var elsize [type size [index $ad 0]]
    	    	#
		# Using the element size, compute the array index. This is,
		# of course, the floor of the offset divided by the element
		# size. We add the low index value in as well to get the index
		# the user (and Swat) expects.
		#
		var el [expr $diff/$elsize+[index $ad 1]]
    	    	#
		# Now adjust diff by the base of the found element and loop
		# with the element type
		#
		var diff [expr $diff-($el-[index $ad 1])*$elsize]
		var t [index $ad 0]
		var n $n\[$el\]
		var fn $fn\[$el\]
    	     }
	     default {
	     	break
    	     }
    	    ]
    	}
	    
    	if {$diff} {
	    echo $n ($diff [pluralize byte $diff] below)
    	} else {
	    echo $n
    	}
    }
}]
