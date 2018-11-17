##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	pobject.tcl
# AUTHOR: 	Adam de Boor, Mar 13, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	pobject	    	    	Print an object out given its address.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/13/89		Initial Revision
#   	jenny	7/08/93	    	Many changes to make pobject do more
#
# DESCRIPTION:
#	A function to print out the structure of an object given its address
#
#	$Id: pobject.tcl,v 3.26.6.1 97/03/29 11:27:04 canavese Exp $
#
###############################################################################

require addr-with-obj-flag user
require find-master object
require next-master object
require print-obj-and-method object
require pvardrange pvardata

##############################################################################
#				pobject
##############################################################################
#
# SYNOPSIS:	Given the address of an object, print it out in the proper form
# PASS:		addr	= address of object
#   	    	detail	= what info should be printed
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#   	jenny	7/08/93	    	Rewrote
#
##############################################################################
[defcmd pobject {{addr {}} {detail {}}} {top.object top.print object.print}
{Usage:
    pobject [<address>] [<detail>]

Examples:
    "pobj"  	    	print the object at *ds:si from Gen down if Gen
    	    	    	    is one of its master levels; else, print
    	    	    	    all	levels
    "pobj *MyGenObject" print MyGenObject from Gen down
    "pobj Gen"    	print the Gen level for the object at *ds:si
    "pobj last"	    	print the last master level for the object
    	    	    	    at *ds:si
    "pobj *MyObject all"
    	    	    	print all levels of MyObject
    "pobj -i sketch"   	print the master level headings of the windowed
    	    	    	    object at the mouse pointer
    "pobj *MyObject FI_foo"
    	    	    	print the FI_foo instance variable for MyObject
    "pobj HINT_FOO" 	print the HINT_FOO variable data entry for the
    	    	    	    object at *ds:si
    "pobj v"	    	print the variable data for the object at *ds:si

Synopsis:
    Print all or part of an object's instance and variable data.

Notes:
    * The address argument is the address of the object to examine. If
      none is specified, *ds:si is assumed to be an object unless the
      current function is a method written in C, in which case the
      variable "oself" is consulted.

    * Special values accepted for <address>:
      --------------------------------------------------------------------
    	-a  	the current patient's application object
    	-i  	the current "implied grab": the windowed object over
		which the mouse is currently located.
    	-f  	the leaf of the keyboard-focus hierarchy
	-t  	the leaf of the target hierarchy
	-m  	the leaf of the model hierarchy
	-c  	the content for the view over which the mouse is
		currently located
    	-kg  	the leaf of the keyboard-grab hierarchy
	-mg 	the leaf of the mouse-grab hierarchy

    * The detail argument specifies what information should be printed
      out about the object. If none is specified, all levels of the
      object from the Gen level down will be printed if Gen is one of
      the object's master levels; else, the whole object will be printed.

    * Values accepted for <detail>:
      ----------------------------
    	all (or a) 	    	- all master levels
    	last (or l) 	    	- last master level only
    	sketch (or s)	    	- master level headings only
    	vardata (or v)	    	- vardata only
    	a master level name
    	an instance variable name
    	a variable data entry name

See also:
    pinst, piv, pvardata
}
{
    #
    # If only one argument has been passed in and it's not one of our
    # special address values, it could be either an address or a
    # detail specification. If the latter, we print out the relevant
    # info for *ds:si or oself and return.
    #
    if {[null $detail] && ![null $addr]} {
    	[case $addr in
            {-a -i -f -t -m -c -kg -mg} {}
    	    default {
    	    	if {[catch {var a [addr-with-obj-flag {}]}] == 0} {
    	    	    if {[pdetail $a $addr]} {
    	    	    	return
    	    	    }
    	    	}
    	    }
    	]
    }
    #
    # Passed args are either just $addr or both $addr and $detail.
    #
    var origaddr $addr
    var addr [set-up-addr $addr]
    #
    # Handle "pobj <addr>"
    #
    if {[null $detail]} {
    	pbasic $addr
    	return
    }
    #
    # Handle "pobj <addr> <detail>"
    #
    if {![pdetail $addr $detail]} {
    	error [concat No information on '$detail' for the
    	    	object at '$origaddr']
    }
}]

##############################################################################
#				set-up-addr
##############################################################################
#
# SYNOPSIS: 	Preprocesses object address whether or not address is a C optr
# PASS:		addr	    = address of object
# CALLED BY:	pobject
# RETURN:	processed address
# SIDE EFFECTS:
#   	    Modifies $addr in caller's context
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Broke out of pobject
#
##############################################################################
[defsubr set-up-addr {addr}
{
    var addr [addr-with-obj-flag $addr]
    #    
    # Break the address into its segment and offset and reassemble it now
    # so if we store other things in the value history while printing the
    # thing, we don't screw up any relative value-history references in $addr
    #
    var a [addr-preprocess $addr seg off]
    var t [index $a 2]
    if {![null $t] && [type class $t] == int && [type size $t] == 4} {
    	#
	# Likely a C optr, so break it into two halves and reparse.
    	#
	var v [value fetch $seg:$off $t]
	addr-preprocess ^l[expr ($v>>16)&0xffff]:[expr $v&0xffff] seg off
    }
    return $seg:$off
}]

##############################################################################
#				pbasic
##############################################################################
#
# SYNOPSIS: 	Prints all master levels of an object if Gen is not
#    	    	one of them or all from Gen down otherwise
#   	    	     
# PASS:		addr	    = address of object
# CALLED BY:	pobject
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#   	If the class has a masterOffset of 0, it means it has no master classes
#   	in its hierarchy, so its Instance structure reflects the actual data at
#   	$addr.
#   	Else, we have to deal with instance pieces in master groups, which we
#	do with the help of the recursive pmaster routine.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Initial version
#
##############################################################################
[defsubr pbasic {addr}
{
    var class [sym fullname [obj-class $addr]]
    #
    # Print out a line with the name, address, label, etc.
    #
    plabel $addr

    if {[value fetch $class.Class_masterOffset] == 0} {
        #
        # No master classes, so just print.
        #
        _print [concat [obj-name $class Instance] $addr]
        pvardrange 0 ALL $addr
    } else {
        var stop [index [find-master $addr Gen] 1]
        #
        # If Gen is a master class for this object,
        #	$stop = number of master levels below Gen
        # Only Gen and those levels below it will be printed out.
        #
        # If not, this is a Vis object and
        #	$stop = ALL
        # All levels will be printed out.
        #
    	var this [next-master $addr 0]
        [pmaster [value fetch $addr [index $this 1]] $addr
        	     [index $this 0] [index $this 2] 1 0 $stop {}]
        pvardrange 0 $stop $addr
    }
}]

##############################################################################
#				pdetail
##############################################################################
#
# SYNOPSIS: 	Prints out specified information about an object
# PASS:		addr	    = address of object
#   	    	detail	    = what info should be printed
# CALLED BY:	pobject
# RETURN:	1 if successful
#   	    	0 if unsuccessful
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Initial version
#
##############################################################################
[defsubr pdetail {addr detail}
{
    #
    # Is $detail an instance variable name?
    # 
    if {[catch {[var iv [pifiv $detail $addr]]} b] != 0} {
    	#
    	# $addr isn't an object address.
    	#
    	return 0
    }
    if {![null $iv]} {
    	return 1
    }
    #
    # Is it a variable data entry name?
    #
    if {[pvardname $addr $detail]} {
    	return 1
    }
    #
    # Is it a master class name?
    # 
    if {[null [obj-class $addr]]} {
    	return 0
    }
    var class [sym fullname [obj-class $addr]]
    var m [find-master $addr $detail]
    if {[index $m 0]} {
        #
        # find-master succeeded
    	#
    	var stop [index $m 1]
    	var master [index $m 2]
    	plabel $addr
    	[plevel $addr
    	    [index [value fetch $addr [index $master 1]] 1]
    	    [index $master 0] [index $master 2]]
    	pvardrange $stop $stop $addr
    	return 1
    }
    #
    # Is it one of our options (all, last, sketch)?
    #
    [case $detail in
    	a* {
    	    pwholeobj $addr
    	    pvardrange 0 ALL $addr
    	    return 1
    	}
        l* {
    	    pinst $addr
    	    return 1
    	}
    	s* {
    	    pwholeobj $addr 1
    	    return 1
    	}
    	v* {
    	    pvardrange 0 ALL $addr
    	    return 1
    	}
    ]
    return 0
}]

##############################################################################
#				plevel
##############################################################################
#
# SYNOPSIS: 	Prints out one of an object's master levels
# PASS:		addr	    = address of object being printed
#   	    	a   	    =
#   	    	class	    = class name of lowest class in current master group
#   	    	inst	    = name of instance structure for same
# CALLED BY:	pdetail, pmaster, pinst
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Broke out of pmaster
#
##############################################################################
[defsubr plevel {addr a class inst}
{
    #
    # print the details of this level
    #
    echo -n {master part:} [index $a 0]
    if {[index $a 2] == 0} {
    	echo {(0) -- empty}
    } elif {[value fetch $class.Class_instanceSize] != 0} {
	echo [format {(%s) -- %s} [index $a 2] $inst]
    	_print [concat $inst ($addr)+[index $a 2]]
    } else {
    	echo [format {(%s) -- %s: no instance data} [index $a 2] $inst]
    }
}]

##############################################################################
#				pwholeobj
##############################################################################
#
# SYNOPSIS: 	Prints out all the master levels of an object
# PASS:		addr	    = address of object being printed
#   	    	sketch	    = non-null if only master level headings
#   	    	    	      should be printed; else null
# CALLED BY:	pdetail
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#   	If the class has a masterOffset of 0, it means it has no master classes
#   	in its hierarchy, so its Instance structure reflects the actual data at
#   	$addr.
#   	Else, we have to deal with instance pieces in master groups, which we
#	do with the help of the recursive pmaster routine.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Initial version
#
##############################################################################
[defsubr pwholeobj {addr {sketch nil}}
{
    #
    # Get the class name and the name of the Instance structure.
    #
    var class [sym fullname [obj-class $addr]]
    var inst [obj-name $class Instance]
    #
    # Print out a line with the name, address, label, etc.
    #
    plabel $addr

    if {[value fetch $class.Class_masterOffset] == 0} {
    	if {![null $sketch]} {
    	    echo This object has no master classes.
    	} else {
    	    #
    	    #  Just print.
    	    #
	    _print [concat $inst $addr]
    	}
    } else {
	#
	# master part -- chain up the class tree to find master
	#
	[pmaster [value fetch $addr [index [next-master $addr 0] 1]]
    	    	$addr $class $inst 1 0 ALL $sketch]
    }
}]

##############################################################################
#				pmaster
##############################################################################
#
# SYNOPSIS:	Recursive routine to print out master groups
# PASS:		valuelist   = structure list for Base structure from current
#   	    	    	      master
#   	    	addr	    = address of object being printed
#   	    	class	    = class name of lowest class in current
#   	    	    	      master group
#   	    	inst	    = name of instance structure for same
#   	    	skip	    = number of master groups to skip
#   	    	count	    = number of master groups done so far
#   	    	stop	    = number of master groups after which to stop
#   	    	    	      or ALL if all levels are needed
#   	    	sketch	    = non-null if only master level headings
#   	    	    	      should be printed; else null
#
# CALLED BY:	pobject, pmaster
# RETURN:	nothing
# SIDE EFFECTS:	The instance group is printed after we recurse.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#	rsf	1/17/91		Added the sketch option
#   	jenny	7/08/93	    	Added count and stop, broke out plevel
#
##############################################################################
[defsubr pmaster {valuelist addr class inst skip count stop sketch}
{
    #
    # Recurse.
    #
    if {[string c ALL $stop] == 0 || $count < $stop} {
    	var next [next-master $addr $skip]
    	if {![null $next]} {
    	    [pmaster [value fetch $addr [index $next 1]] $addr [index $next 0]
		 [index $next 2] [expr $skip+1] [expr $count+1] $stop $sketch]
    	} elif {[value fetch $class.Class_masterOffset] == 0} {
	    return
    	}
    }
    var a [index $valuelist 1]

    if {[null $sketch]} {
    	#
    	# Print the details of this level.
    	#
    	plevel $addr $a $class $inst

    } else {
    	#
    	# Just print the level without the details.
    	#
    	echo -n [format {@%d: } [value hstore [addr-parse $addr]]]
        echo -n {master part:} [index $a 0]
    	echo [format {(%s) -- %s} [index $a 2] $inst]
    }

}]

##############################################################################
#				pinst
##############################################################################
#
# SYNOPSIS:	Given the address of an object, print out the instance data
#   	    	of the last level
# PASS:		addr	= address of the object to print.
# CALLED BY:	pdetail
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#   	If the class has a masterOffset of 0, it means it has no master classes
#   	in its hierarchy, so its Instance structure reflects the actual data at
#   	$addr.
#   	Else, we have to look up the instance of the first level.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	rsf	1/17/91		Initial Revision
#   	jenny	7/08/93	    	Cleaned up
#
##############################################################################
[defcommand pinst {{addr {}}} object.print.fast
{Usage:
    pinst [<address>]

Examples:
    "pinst" 	    	    print the last master level of the object at *ds:si
    "pinst *MyObject"	    print the last master level of MyObject
    "pinst -i"		    print the last master level of the windowed
			    object at the mouse pointer.

Synopsis:
    Print out all the instance and variable data in the last level of
    the object.

Notes:
    * The address argument is the address of the object to examine. If
      none is specified, *ds:si is assumed to be an object unless the
      current function is a method written in C, in which case the
      variable "oself" is consulted.

    * Special values accepted for <address>:
      --------------------------------------------------------------------
    	-a  	the current patient's application object
    	-i  	the current "implied grab": the windowed object over
		which the mouse is currently located.
    	-f  	the leaf of the keyboard-focus hierarchy
	-t  	the leaf of the target hierarchy
	-m  	the leaf of the model hierarchy
	-c  	the content for the view over which the mouse is
		currently located
    	-kg  	the leaf of the keyboard-grab hierarchy
	-mg 	the leaf of the mouse-grab hierarchy

    * "pinst" prints out the same information as "pobj l", but slightly faster.

See also:
    pobject, piv.
}
{
    #
    # Get the class name and the name of the Instance structure.
    #
    var addr [set-up-addr $addr]
    var class [sym fullname [obj-class ($addr)]]
    var inst [obj-name $class Instance]
    #
    # Print out a line with the name, address, label, etc.
    #
    plabel $addr

    if {[value fetch $class.Class_masterOffset] == 0} {
        #
        # No master classes, so just print.
        #
	_print [concat $inst $addr]
    } else {
        var a [index [value fetch $addr [index [next-master $addr 0] 1]] 1]
    	plevel $addr $a $class $inst
    }
    pvardrange 0 0 $addr 
}]

##############################################################################
#				plabel
##############################################################################
#
# SYNOPSIS:	Prints out reference line
# PASS:		addr	    = address of object being printed
# CALLED BY:	pbasic, pdetail, pwholeobj, pinst
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Broke out of pobject
#
##############################################################################
[defsubr plabel {addr}
{
    #
    # New -- before printing out the object, print out a nice reference
    # line, giving symbolic name, address, label, etc.  -- Doug 7/14/93
    #
    addr-preprocess $addr seg off
    var bl [expr [value fetch $seg:0 [type word]]]
    var ch [index [get-chunk-addr-from-obj-addr $addr] 1]
    print-obj-and-method  $bl $ch
}]

##############################################################################
#				pifiv
##############################################################################
#
# SYNOPSIS:	Print the value of a slot in a master level
# PASS:		iv  	= name of instance variable
#    	    	addr	= address of the object in question
# CALLED BY:	pdetail
# RETURN:	1 if value was successfully printed
#   	    	{} if no such instance variable exists for this object
#
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jenny	7/08/93	    	Cribbed from piv
#
##############################################################################
[defsubr pifiv {iv {addr {}}}
{
    var addr [addr-with-obj-flag $addr]
    
    #
    # Find the offset and type of the data by searching through the instance
    # structures of the various pieces of the object.
    #
    return [obj-foreach-class piv-callback $addr $iv]
}]

##############################################################################
#				piv
##############################################################################
#
# SYNOPSIS:	Print the value of a slot in a master level.
# PASS:		addr	= address of the object to print.
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#   	Just assume the user has got the stuff right.  Else it fails.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/17/91		Initial Revision
#
##############################################################################
[defsubr piv-callback {cs addr iv}
{
    var instsym [symbol find type [obj-name [symbol fullname $cs] Instance]]
    var ivsym [symbol find field $iv $instsym]
    
    if {![null $ivsym]} {
    	var master [value fetch [symbol fullname $cs].Class_masterOffset]

    	addr-preprocess $addr seg off
	if {$master} {
	    var a [addr-preprocess ($seg:$off+[value fetch $seg:$off+$master word]).[symbol fullname $ivsym] vseg voff]
    	} else {
    	    var a [addr-preprocess ($seg:$off).[symbol fullname $ivsym] vseg voff]
    	}
	var hnum [value hstore $a]
	echo -n @$hnum $iv {= }
	fmtval [value fetch $vseg:$voff [index $a 2]] [index $a 2] 0
	return 1
    }
}]

[defcommand piv {iv {addr {}}} object.print.fast
{Usage:
    piv <iv> [<address>]

Examples:
    "piv VCNI_viewHeight"   print Vis.VCNI_viewHeight at *ds:si

Synopsis:
    This prints out the value of the instance variable specified.  

Notes:
    * The iv argument expects the name of the instance variable to print.

    * The address argument is the address of the object to examine.
      If it's not specified then *ds:si assumed to be an object.

    * Special values accepted for <address>:
      --------------------------------------------------------------------
    	-a  	the current patient's application object
    	-i  	the current "implied grab": the windowed object over
		which the mouse is currently located.
    	-f  	the leaf of the keyboard-focus hierarchy
	-t  	the leaf of the target hierarchy
	-m  	the leaf of the model hierarchy
	-c  	the content for the view over which the mouse is
		currently located
    	-kg  	the leaf of the keyboard-grab hierarchy
	-mg 	the leaf of the mouse-grab hierarchy

    * "piv VCNI_viewHeight" prints out the same information as
      "pobj VCNI_viewHeight", but slightly faster.

See also:
    pobject, pinst.
}
{
    var addr [addr-with-obj-flag $addr]
    #
    # Find the offset and type of the data by searching through the instance
    # structures of the various pieces of the object.
    #
    var result [obj-foreach-class piv-callback $addr $iv]
    
    if {[null $result]} {
    	error [format {%s is not an instance variable for object %s} $iv $addr]
    }
}]
