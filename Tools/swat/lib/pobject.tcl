##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#
# DESCRIPTION:
#	A function to print out the structure of an object given its address
#
#	$Id: pobject.tcl,v 3.4 91/01/18 17:12:51 roger Exp $
#
###############################################################################

##############################################################################
#				pobject
##############################################################################
#
# SYNOPSIS:	Given the address of an object, print it out in the proper form
# PASS:		addr	= address of the object to print.
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#   	If the class has a masterOffset of 0, it means it has no master classes
#   	in its hierarchy, so its Instance structure reflects the actual data at
#   	$addr.
#   	Else, we have to deal with instance pieces in master groups, which we
#	do with the help of the recursive pmaster routine.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#
##############################################################################
[defcommand pobject {{addr *ds:si} {printLevels nil}} output
{pobject [address] [print levels]
"pobj *MyObject"    	prints out MyObject
"pobj *ds:si l"	    	prints out the master levels of the object at *ds:si

Print all the levels out of an object.

* The address argument is the address of the object to examine.  If not
specified then *ds:si assumed to be an object.

* The print levels argument makes pobject print only the headings to each
of the master levels along with an object history number.  Any non-nil
value ("levels" or "l") enables this.

See also pinst, piv.}
{
    #
    # First figure out the name of the structure for the object based on
    # the name of its class (get the name by replacing the "Class" in the
    # class name with "Instance")
    #
    var sn [sym fullname [sym faddr var *($addr).MB_class]]

    if {[value fetch $sn.Class_masterOffset] == 0} {

	# No variants, print normally

	var tn [obj-name $sn Instance]
	print $tn $addr
    } else {
	#
	# master part -- chain up the class tree to find master
	#
	var mn [next-master $addr 0]
	echo class = $sn
	[pmaster [value fetch $addr [index $mn 1]] $addr $sn 
		[obj-name $sn Instance] 1 $printLevels]
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
#   	    	sn  	    = class name of lowest class in current master group
#   	    	inst	    = name of instance structure for same
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
#	rsf	1/17/91		Added the print levels option
#
##############################################################################
[defsubr pmaster {valuelist addr objname inst skip printLevels}
{
    var next [next-master $addr $skip]
    if {![null $next]} {
    	[pmaster [value fetch $addr [index $next 1]] $addr [index $next 0]
		 [index $next 2] [expr $skip+1] $printLevels]
    } elif {[value fetch $objname.Class_masterOffset] == 0} {
	return
    }
    var a [index $valuelist 1]


    if {[null $printLevels]} {

    	# print the details of this level
        echo -n {master part:} [index $a 0]
    	if {[index $a 2] == 0} {
	    echo {(0) -- empty}
        } elif {[value fetch $objname.Class_instanceSize] != 0} {
	    echo [format {(%s) -- %s} [index $a 2] $inst]
    	    print $inst ($addr)+[index $a 2]
        } else {
    	    echo [format {(%s) -- %s: no instance data} [index $a 2] $inst]
    	}
    } else {

    	# just print the level without the details
    	echo -n [format {@%d: } [value hstore [addr-parse $addr]]]
        echo -n {master part:} [index $a 0]
    	echo [format {(%s) -- %s} [index $a 2] $inst]
    }

}]


##############################################################################
#				phint
##############################################################################
#
# SYNOPSIS:	Given the address of an object, print out the instance data
#   	    	of the last level
# PASS:		addr	= address of the object to print.
# CALLED BY:	user
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
#
##############################################################################
[defcommand pinst {{addr *ds:si}} output
{pinst [address]
"pinst *MyObject"

Print out all the instance data to the last level of the object.

* The address argument is the address of the object to examine.  If not
specified then *ds:si assumed to be an object.

This is useful for classes you've created by subclassing others and you
are not interested in the data in the master levels, which pobject would
display.

See also pobject, piv.}
{
    #
    # First figure out the name of the structure for the object based on
    # the name of its class (get the name by replacing the "Class" in the
    # class name with "Instance")
    #
    var sn [sym fullname [sym faddr var *($addr).MB_class]]
    var instName [obj-name $sn Instance]

    if {[value fetch $sn.Class_masterOffset] == 0} {

	# No variants, print normally

	print $instName $addr

    } else {

        var a [index [value fetch $addr [index [next-master $addr 0] 1]] 1]

	echo class = $sn

    	# print the details of this level

        echo -n {master part:} [index $a 0]
    	if {[index $a 2] == 0} {
	    echo {(0) -- empty}
        } elif {[value fetch $sn.Class_instanceSize] != 0} {
	    echo [format {(%s) -- %s} [index $a 2] $instName]
    	    print $instName ($addr)+[index $a 2]
        } else {
    	    echo [format {(%s) -- %s: no instance data} [index $a 2] $instName]
    	}
    }
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
[defcommand piv {master iv {obj *ds:si}} output
{piv master iv [address]
"piv Vis VCNI_viewHeight"   prints out Vis.VCNI_viewHeight at *ds:si

This prints out the value of the instance variable specified.  

* The master argument expects the name of a master level.  The name
may be found out print using pobject to print the levels, and then
using the name that appears after "master part: " and before the
"_offset".

* The iv argument expects the name of the instance variable to print.

* The address argument is the address of the object to examine.  If not
specified then *ds:si assumed to be an object.

This is useful for when you know what instance variable you want to
see but don't want to wade through a whole pobject command.

See also pobject, pinst.}
{
     print (($obj)+[value fetch ($obj).${master}_offset]).${iv}
}]

