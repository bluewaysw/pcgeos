#######################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Object Variable Data Printout
# FILE:		pvardata.tcl
# AUTHOR:	brianc, 10/1/91
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pvardata	    	Print the variable data for an object
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	brianc	10/1		Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to print out variable data.
#
#	$Id: pvardata.tcl,v 1.25.11.1 97/03/29 11:26:53 canavese Exp $
#
#############################################################################@

require chunk-size lm

#
# Utility routine to get starting variable data address for an object.
#
[defsubr vardaddr {{address *ds:si}}
{
    var addr [addr-preprocess $address seg off]

    var cs [obj-class $address]
    if {[null $cs]} {
   	return -1
    }
    var fn [symbol fullname $cs]
    #
    # get location of last master offset
    #
    var varDataOff [value fetch $fn.Class_masterOffset word]
    #
    # get last master offset (if master part exists, else use 0)
    #
    if {$varDataOff != 0} {
        var varDataOff [value fetch $seg:$off+$varDataOff word]
    #
    # if master part for the highest class is not grown, assume no other master
    # parts are grown and compute the beginning of the variable data as the end
    # of the master offsets area
    #
	if {$varDataOff == 0} {
	    var varDataOff [value fetch $fn.Class_masterOffset word]
	    var varDataOff [expr $varDataOff+2]
	    return [expr $varDataOff+$off]
	}
    }
    #
    # get beginning of last master part
    #
    var varDataOff [expr $varDataOff+$off]
    #
    # get end of last master part
    #
    return [expr $varDataOff+[value fetch $fn.Class_instanceSize word]]
}]

#
# Utility routine to get size of variable data for an object.
#
[defsubr vardsize {{address *ds:si}}
{
    var addr [addr-preprocess $address seg off]

    #
    # size = end of chunk - start of var data
    #      = start of chunk + size of chunk - start of var data
    #
    var a [vardaddr $address]
    #
    # vardaddr returns -1 if it can't find the class
    #
    if {[$a == -1]} {
	return 0
    }
    return [expr [expr $off+[expr [chunk-size $seg $off]-2]-$a]]

}]

#
# Utility routine to get end of variable data for an object.
#
[defsubr vardend {address}
{
    #
    # Get segment and offset of object; get size of object chunk; 
    # remove size field; get end offset of chunk.
    #
    addr-preprocess $address oseg ooff
    var varDataEnd [chunk-size $oseg $ooff]
    var varDataEnd [expr $varDataEnd-2]
    var varDataEnd [expr $varDataEnd+$ooff]
    return $varDataEnd
}]

##############################################################################
#				get-entry
##############################################################################
#
# SYNOPSIS:	Returns info on a vardata entry for an object
# PASS:		address	    = address of a variable data entry
# CALLED BY:	pvardentry, pvardname
# RETURN:    	entry	    = 3-list of
#    	    	    	    	    A. VDE_dataType,
#    	    	    	    	    B. VDE_entrySize,
#   	    	    	    	    C. VDE_dataType with the low byte cleared
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Broke out of pvardentry
#
##############################################################################
[defsubr get-entry {address}
{
    var addr [addr-parse $address]
    var seg ^h[handle id [index $addr 0]]
    var off [index $addr 1]
    var element [value fetch $seg:$off word]
    var has_extra [expr $element&[fieldmask VDF_EXTRA_DATA]]
    if {$has_extra} {
    	var dataSize [expr [value fetch $seg:$off.VDE_entrySize]-4]
    } else {
    	var dataSize 0
    }
    var dataType [expr {$element & ~0x0003}]

    return [list $element $dataSize $dataType] 
}]

##############################################################################
#				pvardentry
##############################################################################
#
# SYNOPSIS:	Prints out a vardata entry for an object
# PASS:		address	    = address of a variable data entry
#    	    	obj 	    = address of an object with variable data
# CALLED BY:	pvardrange
# RETURN:	size of the entry
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Broke out get-entry and pvardentrylow
#
##############################################################################
[defcommand pvardentry {{address ds:bx} {obj *ds:si}} swat_prog.object
{Usage:
    pvardentry <address> <object>

Examples:
    pvardentry ds:bx *ds:si

Notes:
    * The address argument is the address of a variable data entry in
      an object's variable data storage area.  The default is ds:bx.

    * The <object> argument is required to determine the name of the
      tag for the entry, as well as the type of data stored with it.

See also:
    pvardrange, fvardata
}
{
    var entry [get-entry $address]
    #
    # Search up the tree for the vardata. Returns the token of the vardata
    # symbol found, {} if none was found anywhere, or 1 if none was found
    # and we stopped looking before the last class. If none was found and
    # we didn't look at the first classes, we set the "token" to 1 here.
    #
    var tok [obj-foreach-class search-var-data-range $obj [index $entry 2]]
    if {[null $tok] && [uplevel 1 {[expr $start]}]} {
    	var tok 1
    }
    #
    # Print out what we've found, if anything.
    #
    return [pvardentrylow $address $entry $tok]
}]

##############################################################################
#				pvardentrylow
##############################################################################
#
# SYNOPSIS:	Prints out a vardata entry for an object
# PASS:		address	    = address of a variable data entry
#    	    	entry	    = 3-list of
#    	    	    	    	    A. VDE_dataType,
#    	    	    	    	    B. VDE_entrySize,
#   	    	    	    	    C. VDE_dataType with the low byte cleared
#   	    	tok  	    = if caller found match for entry in class tree
#    	    	    	    	    token for entry
#   	    	    	      if no match
#   	    	    	    	    {}
#   	    	    	      if caller didn't look everywhere, found no match
#   	    	    	    	    1
# CALLED BY:	pvardentry, pvardname
# RETURN:	size of the entry
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Broke out of pvardentry
#
##############################################################################
[defsubr pvardentrylow {address entry tok}
{
    require fmtval print

    var element [index $entry 0]
    var dataSize [index $entry 1]
    var dataType [index $entry 2]

    if {$tok == 1} {
    	#
    	# We've found nothing in the classes we searched but we didn't
    	# look at all the classes so we don't want to announce that
    	# the data type is unknown. Just return.
    	#
    	if {$dataSize} {
	    return [expr $dataSize+4]
    	} else {
    	    return 2
    	}
    } elif {[null $tok]} {
    	echo -n [format {Unknown data type: %d} $dataType]
      	if {[expr $element&[fieldmask VDF_SAVE_TO_STATE]]} {
	    echo -n {*}
        }
	var dtype [type byte]
    } else {
    	echo -n [symbol name $tok]
        if {[expr $element&[fieldmask VDF_SAVE_TO_STATE]]} {
	    echo -n {*}
        }
    	var dtype [index [sym get $tok] 2]
	if {[string compare [type class $dtype] void] == 0} {
	    var dtype [type byte]
    	}
    }
    if {[expr $element&[fieldmask VDF_EXTRA_DATA]]} {
    	#
	# Enter the base of the extra data in the value history, so the user
	# can print it as something else easily...
	#
    	echo -n [format { @%d = }
	    	 [value hstore [concat [range
		    	    	    	 [addr-parse $address.VDE_extraData]
					 0 1]
				       [list $dtype]]]]
    	#
	# Figure if the data are singular or an array of elements.
	#
	var elsize [type size $dtype]
	if {$dataSize > $elsize} {
    	    #
	    # Figure the number of elements in the array, setting $left_over
	    # to the number of bytes left over at the end when that's been
	    # accomplished, in case they mean something.
	    #
	    var left_over [expr {$dataSize - ($dataSize/$elsize)*$elsize}]
	    var dtype [type make array [expr $dataSize/$elsize] $dtype]
	    var freetype 1
    	} elif {$dataSize < $elsize} {
    	    #
	    # Not enough data to make up a single element, so make them all
	    # left over.
	    #
	    var left_over $dataSize freetype 0
    	} else {
	    #
	    # Exactly as big as it should be.
	    #
	    var freetype 0 left_over 0
    	}
    	#
    	# Print the data for which we know the type...
	#
	if {$left_over != $dataSize} {
    	    fmtval [value fetch $address.VDE_extraData $dtype] $dtype 0
    	}

    	#
	# Print the left-over data as an array of bytes.
	#
	if {$left_over} {
	    echo {    left over bytes:}
	    var lo [type make array $left_over [type byte]]
	    [fmtval [value fetch (&$address.VDE_extraData)+$dataSize-$left_over
	    	    	 $lo]
    	    	    $lo 0]
	    type del $lo
    	}
	
	#
	# Biff $dtype if we manufactured it.
	#
	if {$freetype} {
	    type del $dtype
    	}
	
	return [expr $dataSize+4]
    } else {
    	echo
    	return 2
    }
}]

##############################################################################
#				search-var-data
##############################################################################
#
# SYNOPSIS:	Looks for a vardata entry with the passed characteristic
# PASS:		cs	    = symbol token for the current class
#   	    	obj 	    = address of object (passed perforce by
#    	    	    	      obj-foreach-class)
#   	    	matchfunc   = comparison routine to use
#    	    	datum	    = characteristic to compare
# CALLED BY:	pvardname, search-var-data-range
# RETURN:	if vardata entry is found:
#    	    	    token of the vardata entry
#      	    	if not found
#    	    	    {}
# SIDE EFFECTS:
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Initial version
#
##############################################################################
[defsubr match-var-data-type {entry dataType}
{
    if {[index [symbol get $entry] 0] == $dataType} {
    	return [list 1 $entry]
    }
    return 0
}]

[defsubr match-var-data-name {entry name}
{
    if {[string c $name [symbol name $entry]] == 0 } {
    	return [list 1 $entry]
    }
    return 0
}]

[defsubr search-var-data {cs obj matchfunc datum}
{
    var cname [obj-name [sym fullname $cs] VarData]
    var vdType [sym find type $cname]
    if ![null $vdType] {
    	var match [index [symbol foreach $vdType enum $matchfunc $datum] 1]
    }
    return $match
}]

##############################################################################
#				search-var-data-range
##############################################################################
#
# SYNOPSIS:	Looks for a vardata entry within a range of master levels
# PASS:		cs	    = symbol token for the current class
#   	    	obj 	    = address of object (passed perforce by
#    	    	    	      obj-foreach-class)
#    	    	dataType    = type of vardata entry    
# CALLED BY:	pvardrange (via pvardentry and obj-foreach-class)
# RETURN:	if vardata entry is found:
#    	    	    token of the vardata entry
#      	    	if not found and search should continue:
#    	    	    {}
#    	    	if not found and search should stop:
#    	    	    1
# SIDE EFFECTS:
#   	see STRATEGY
# STRATEGY:
#   	"uplevel 3" manipulates the following variables in the context
#   	of our (indirect) caller, pvardrange.
# 	    $start	= first master level of interest (0 for bottommost)
#    	    $stop	= last master level of interest {0 for current one),
#   	    	    	  or ALL if we want all of them
#   	    $count   	= # of master levels we've encountered during
#   	    	    	  the search for this vardata entry
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Initial version
#
##############################################################################
[defsubr search-var-data-range {cs obj dataType}
{
    #
    # If $stop = ALL, all master levels should be searched;
    # otherwise, keep track of where we are with respect to the
    # range of master levels which interests us.
    #
    if {[uplevel 3 {[string c ALL $stop]}]} {
        uplevel 3 {
    	    if {$stop < 0} {
    	        #
    	    	# We've already finished searching all the master levels in
    	    	# the desired range; return 1 so we won't be called
    	    	# again for this vardata entry.
    	    	#
    	    	return 1
    	    }
    	}
    	#
    	# Keep track of how many master levels up we are.
    	#
    	if {[is-master $cs]} {
    	    uplevel 3 {
    	    	var stop [expr $stop-1]
    	    	var count [expr $count+1]
    	    	if {$count <= $start} {
    	    	    #
    	    	    # We're not yet past the last master class before our
    	    	    # interest begins.
    	    	    #
    	    	    return
    	    	}
    	    }
    	}
    	#
    	# Are we interested yet?
    	#
    	uplevel 3 {
    	    if {$count < $start} {
    	    	return
    	    }
    	}
    }
    #
    # Try to find something that matches the passed data type.
    #
    return [search-var-data $cs $obj match-var-data-type $dataType]
}]

##############################################################################
#				pvardname
##############################################################################
#
# SYNOPSIS:	Prints the named vardata entry
# PASS:		address	= address of an object with variable data
#   	    	name	= name of entry to print
# CALLED BY:	EXTERNAL    pdetail
# RETURN:	1 if successful
#   	    	0 if unsuccessful
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Initial version
#
##############################################################################
[defsubr pvardname {address name}
{
    require addr-with-obj-flag user
    #
    # Get vardata start and end.
    #
    var address [addr-with-obj-flag $address]
    addr-preprocess $address oseg ooff
    var varDataStart [vardaddr $address]
    var varDataEnd [vardend $address]
    if {$varDataStart == $varDataEnd || $varDataStart == -1} {
    	return 0
    }
    #
    # Search up the tree for the vardata. Returns the token of the vardata
    # symbol found or {} if none was found.
    #
    var tok [obj-foreach-class search-var-data $oseg:$ooff
   	    	    	    	    	    	match-var-data-name $name]
    if {[null $tok]} {
    	return 0
    }
    #
    # Roll through the vardata entries for our object till we find the
    # one whose type matches the type of our name-match, and print it out.
    #
    var dataType [index [symbol get $tok] 0]
    [for {var off $varDataStart}
	 {$off < $varDataEnd}
	 {var off [expr $off+[index $entry 1]+4]}
    {
    	var entry [get-entry $oseg:$off]
    	if {[index $entry 2] == $dataType} {
    	    pvardentrylow $oseg:$off $entry $tok
    	    return 1
    	}
	
    }]
    return 0
}]

##############################################################################
#				pvardrange
##############################################################################
#
# SYNOPSIS:	Prints out vardata for a particular range of master levels
# PASS:		start	= first master level of interest (0 for bottommost)
#    	    	stop	= last master level of interest
#   	    	address	= address of an object with variable data
# CALLED BY:	pvardata, pobject's subroutines
# RETURN:       nothing
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Initial version (based on old pvardata)
#
##############################################################################
[defcommand pvardrange {start stop {address *ds:si}} swat_prog.object
{
}
{
    require addr-with-obj-flag user
    #
    # Get vardata start and end.
    #
    var address [addr-with-obj-flag $address]
    addr-preprocess $address oseg ooff
    var varDataStart [vardaddr $address]
    var varDataEnd [vardend $address]

    echo Variable Data:

    if {$varDataStart == $varDataEnd || $varDataStart == -1} {
        echo \t *** No Variable Data ***
        return
    }
    #
    # For each piece of vardata, search all the classes within the
    # specified range of master levels and print out what we find.
    #
    var origstop $stop
    var count 0
    [for {var off $varDataStart}
	 {$off != $varDataEnd}
	 {}
    {
	if {$off > $varDataEnd} {
    	    echo \t *** Bad Variable Data ***
	    return
	}
	var off [expr $off+[pvardentry $oseg:$off $oseg:$ooff]]
    	#
    	# $stop and $count are modified by search-var-data-range.
    	# We reset them before going on to the next piece of vardata.
    	#
    	var stop $origstop
    	var count 0
    }]
}]

##############################################################################
#				pvardata
##############################################################################
#
# SYNOPSIS:	Prints out vardata for an object
# PASS:	    	address	= address of an object with variable data
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Broke out what became pvardrange
#
##############################################################################
[defcommand pvardata {{address *ds:si}} object.print.fast
{Usage:
    pvardata [<address>]

Examples:
    pvardata ds:si		Prints vardata of object at *ds:si
    pvardata -i			Prints vardata of object with implied grab.

Notes:
    * The address argument is the address of an object with variable data.
      The default is *ds:si.

    * "pvardata" prints out the same information as "pobj v", but
      slightly faster.

See also:
    pobject
}
{
    pvardrange 0 ALL $address
}]


[defcommand fvardata {token {address *ds:si}} object.print.obscure
{Usage:
    fvardata <token> [<address>]

Examples:
    fvardata ATTR_VIS_TEXT_STYLE_ARRAY *ds:si

Synopsis:
    Locates and returns the value list for the data stored under the given
    token in the vardata of the given object.

Notes:
    * If the data are found, returns a list {<token> <data>}, where <data>
      is a standard value list for the type of data associated with the
      specified token.

    * Returns an empty list if the object has no vardata entry of the given
      type.

    * If no <address> is given, the default is *ds:si

See also:
    pobject
}
{

	global objAddr

    #
    # get size of object chunk
    #
    var objAddr $address
    var addr [addr-preprocess $address oseg ooff]
    #
    # get vardata start and end
    #
    var off [vardaddr $address]
    if {$off == -1} {
    	return {}
    }
    var varDataEnd [vardend $address]

    var dat [sym get [sym find enum $token]]
    var token_val [index $dat 0]
    var token_type [index $dat 2]
    if {[string compare [type class $token_type] void] == 0} {
	var dtype [type byte]
    }

    while {$off != $varDataEnd} {
	if {$off > $varDataEnd} {
	    return {}
	}
    	if {[expr [value fetch $oseg:$off word]&0xfffc] == $token_val} {
	    # XXX: DEAL WITH ARRAY OF THESE THINGS
    	    return [list $token [value fetch $oseg:$off+4 $token_type]]
    	}
	var has_extra [expr [value fetch $oseg:$off word]&[fieldmask VDF_EXTRA_DATA]]
	if {$has_extra} {
	    var dataSize [expr [value fetch $oseg:$off+2 word]]
	} else {
	    var dataSize 2
	}
	var off [expr $off+$dataSize]
    }
    return {}
}]
