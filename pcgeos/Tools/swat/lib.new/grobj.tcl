##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	grobj.tcl
# AUTHOR: 	tony
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	grobjtree    	    	Print an object composite tree
#   	pbody	    	    	Print the grobj body given the address
#   	    	    	    	of a grobj
#   	ptrans	    	    	Print the transform of a grobj
#   	getward	    	    	return the ward's OD
#   	pward	    	    	do a POBJ on the ward
#
#
#	$Id: grobj.tcl,v 1.18.11.1 97/03/29 11:27:24 canavese Exp $
#
###############################################################################

[defcommand    pbody {{address ds:0}} lib_app_driver.grobj 
{Usage:
    pbody [<address>]


Examples:
    "pbody"	    	prints the GrObjBody given a GrObj block
		    	at ds

    "pbody ^hbx"	Prints the GrObjBody given a GrObj block
		    	whose handle is bx

Synopsis:
    Finds the GrObjBody via the BodyKeeper -- prints its OD and its
    instance data.

Notes:
    * If no arguments are given, then DS is assumed to point to an
      object block containing GrObjects.

See also:
    ptrans, grobjtree
}
{
	var addr [addr-parse $address]
	var hid  [handle id [index $addr 0]]
	var body [fetch-optr $hid OLMBH_output]
	var bodyHandle [index $body 0]
	var bodyChunk [index $body 1]

	echo [format {%s (^l%04xh:%04xh)}
	      	    	GrObjBody:
			$bodyHandle
	                $bodyChunk
		]

	pobject ^l$bodyHandle:$bodyChunk

}]


####################################################################
[defcommand	ptrans {args} lib_app_driver.grobj
{Usage:
    ptrans [<flags>] [<address>]

Examples:
    "ptrans"	    	print the normal transform for the object
		    	at *ds:si

    "ptrans -s"	    	print the sprite transform for the GrObj
		    	object at *ds:si

    "ptrans ^lbx:cx"  	print the normal transorm for the
		      	object whose OD is ^lbx:cx

Synopsis:
    Prints the ObjectTransform data structure as specified.

Notes:
    * The -s flag can be used to print the 'sprite' transform

    * <address> defaults to *ds:si

See also:
    pobject.
}
{
    var sprite 0
    var normal 1
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
	 var arg [range [index $args 0] 1 end chars]
	 while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
	    	s {
	    	    var sprite 1
	    	    var normal 0
	    	}			
	    ]
	    if {![null $arg]} {
		var arg [range $arg 1 end chars]
	    }
	 }

	 # go to next argument
	 var args [cdr $args]
    }

    if {[length $args] == 0} {
    	var address *ds:si
    } else {
	 var address [index $args 0]
    }

    var addr [addr-parse $address]
    var	hid [handle id [index $addr 0]]
    var	off [index $addr 1]

    var inst [get-grobj-instance $hid $off]

    if {$normal}  {
        echo Normal Transform:
	var trans [value fetch ^h$hid:$inst.GOI_normalTransform]
	print-transform $hid $trans
    }

    if {$sprite } {
      	echo Sprite Transform:
	var trans [value fetch ^h$hid:$inst.GOI_spriteTransform]
      	print-transform $hid $trans
    }

}]


##############################################################################
#	print-transform
##############################################################################
#
# SYNOPSIS:	print out an object transform
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	3/20/92   	Initial Revision
#
##############################################################################
[defsubr    print-transform {bl chunk} {

    if {$chunk == 0 } {
    	echo transform does not exist
    } else {

	# Format the address nicely
	_print ObjectTransform [format (^l%04xh:%04xh) $bl $chunk]
	  
    }

}]

####################################################################

[defcommand grobjtree {{obj *ds:si} {extrafield {}} {indent 0}} lib_app_driver.grobj
{Usage:
    grobjtree [<address>] [<instance field>]

Examples:
    "grobjtree"	    	    	print the grobj tree starting at *ds:si

Synopsis:
    Print out a grobj tree.

Notes:
    * The address argument is the address of a GrObj Body
      This defaults to *ds:si.  

    * To get the address of the grobj body, use the "pbody" or
      "target" commands. 


See also:
    pbody
}
{
    require default-patient user.tcl
    require objtree-enum objtree.tcl
    require is-obj-in-class grab.tcl
    require addr-with-obj-flag user.tcl

    var obj [addr-with-obj-flag $obj]

    if {[is-obj-in-class $obj GrObjBodyClass]} {
	objtree-enum $obj 0 64 gt-print gt-link gt-comp $extrafield
    } elif  {[is-obj-in-class $obj GroupClass]} {
	objtree-enum $obj 0 64 gt-print gt-link gt-comp $extrafield
    } else {
	echo -n Error: Invalid Class
	pclass $obj
    }
}]

##############################################################################
#				gt-print
##############################################################################
#
# SYNOPSIS:	callback procedure to print additional information about
#   	    	the current object in the tree.
# PASS:		obj 	= address of base of object
#   	    	extra	= the extrafield argument passed to objtree-enum
#   	    	indent	= the indentation of the start of the object-description
#			  line already printed by objtree-enum (no newline
#			  has been printed)
# CALLED BY:	objtree-enum
# RETURN:	nothing
# SIDE EFFECTS:	prints out the extra field, if $extra is non-null
#
# STRATEGY  	use fmtval, not _print, so indentation can be maintained
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/18/94		Initial Revision
#
##############################################################################
[defsubr gt-print {obj extra indent}
{
    if {![null $extra]} {
    	require fmtval print.tcl

    	var a [addr-parse ($obj).$extra]
	var v [value fetch ($obj).$extra]
	fmtval $v [index $a 2] [expr $indent+4] {} 1
    }
}]

##############################################################################
#	gt-comp
##############################################################################
#
# SYNOPSIS:	return the first child of this object
# PASS:		obj - address of object
# CALLED BY:	objtree-enum
# RETURN:	od of first child, nil if none
# SIDE EFFECTS:	none
#
# STRATEGY:
#   	    for GrObjBody - return first child in draw order
#   	    for VisGuardian - return the ward
#   	    for Groups - return the first child (NOT IMPLEMENTED) 
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	6/23/92   	Initial Revision
#
##############################################################################
[defsubr    gt-comp {obj} {

    var	addr [addr-parse $obj]
    var hid [handle id [index $addr 0]]
    var off [index $addr 1]
    if {[is-obj-in-class $obj GrObjBodyClass]} {
	var masterOffset [value fetch ($obj).Vis_offset]
	var compOffset [expr $masterOffset+[getvalue GBI_drawComp]]
	return [fetch-optr $hid [expr $off+$compOffset].CP_firstChild]
    } elif {[is-obj-in-class $obj GrObjVisGuardianClass]} {
	var inst [get-grobj-instance $hid $off]
	var compOffset [expr $inst+[getvalue GOVGI_ward]]
	return [fetch-optr $hid $compOffset]
    } elif {[is-obj-in-class $obj GroupClass]} {
	var inst [get-grobj-instance $hid $off]
	var compOffset [expr $inst+[getvalue GI_drawHead]]
	return [fetch-optr $hid $compOffset]
    }
}]
	
##############################################################################
#	gt-link
##############################################################################
#
# SYNOPSIS:	return the optr of the next child, or nil if none
# PASS:		obj - address of current object
# CALLED BY:	objtree-enum
# RETURN:	OD of next sibling
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	6/23/92   	Initial Revision
#
##############################################################################
[defsubr    gt-link {obj} {
    var addr [addr-parse $obj]
    var hid [handle id [index $addr 0]]
    var off [index $addr 1]
    if {[is-obj-in-class $obj GrObjClass]} {
	var inst [get-grobj-instance $hid $off]
	var linkOffset [expr $inst+[getvalue GOI_drawLink]]

	return [fetch-optr $hid $linkOffset]
    }
}]



####################################################################

require	getobjclass objtree.tcl
require carray-enum chunkarr.tcl

[defcommand pobjarray {{address *ds:si} {extra nil}} lib_app_driver.grobj
{Usage:
    pobjarray [<address>]

Examples:
    "pobjarray"	    print the array of ODs at *ds:si

Synopsis:
    Print out an array of objects.

Notes:

See also:
    pbody
}
{

    carray-enum $address pobjarrayCB $extra
}]

##############################################################################
#	pobjarrayCB
##############################################################################
#
# SYNOPSIS:	callback routine to print each element of an object array
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	6/ 3/92   	Initial Revision
#
##############################################################################
[defsubr    pobjarrayCB {elementNum elementAddr elementSize extra} {

    var addr [addr-parse $elementAddr]
    var bl [handle id [index $addr 0]]
    var off [index $addr 1]
    var op [fetch-optr $bl $off]
    var objHan [index $op 0] objCh [index $op 1]
    if { $objHan != 0 } {
    	var objAddr ^l$objHan:$objCh
    	var label [value hstore [addr-parse $objAddr]]

    	var objclass [getobjclass $objAddr]

    	echo -n [format {%s (@%d, ^l%04xh:%04xh) } $objclass $label
						$objHan $objCh]

    	if {![null $extra]} {_print (^h$objHan:$objCh).$extra}
 
    	echo
    } else {
	echo Element $elementNum -- empty
    }
    return 0
}]

##############################################################################
#	get-grobj-instance
##############################################################################
#
# SYNOPSIS: 	Return the offset of the GrObj master-level instance data
# PASS:		addr - grobject
# CALLED BY:	
# RETURN:	offset to instance data
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	7/10/92   	Initial Revision
#
##############################################################################
[defsubr    get-grobj-instance {hid off} {

    return [expr $off+[value fetch ^h$hid:$off.GrObj_offset]]
}]

##############################################################################
#	getward
##############################################################################
#
# SYNOPSIS:	return the OD of the ward
# PASS:		addr
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/17/92   	Initial Revision
#
##############################################################################
[defsubr    getward {addr} {
    var addr [addr-with-obj-flag $addr]
    var addrParse [addr-preprocess $addr seg off]
    var hid [handle id [index $addrParse 0]]
    var inst [get-grobj-instance $hid $off]
    return [format {^l%04xh:%04xh}
	    [value fetch ^h$hid:$inst.GOVGI_ward.handle]
	    [value fetch ^h$hid:$inst.GOVGI_ward.offset]]
}]


##############################################################################
#	pward
##############################################################################
#
# SYNOPSIS:	do a "pobj" on the ward
# PASS:		addr - address of grobj
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/16/92   	Initial Revision
#
##############################################################################
[defsubr    pward {addr } {
    var addr [addr-with-obj-flag $addr]
    pobj [getward $addr]
}]

##############################################################################
#				grobjstring
##############################################################################
#
# SYNOPSIS:	Print out all the graphics operations that go into
#		printing the passed graphic object
# PASS:		addr	= object to investigate
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#   	    	to be truly general, this would have to alter the gstate
#		it'll be creating to include the transformation of any
#		containing group
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/20/93	Initial Revision
#
##############################################################################

[defsubr    grobjstring {addr}
{
    var addr [addr-with-obj-flag $addr]
    
    var a [get-chunk-addr-from-obj-addr $addr]

    var vmf [value fetch kdata:[value fetch kdata:[handle id [index $a 0]].HM_owner].HVM_fileHandle]

    #
    # First get to a stopping point on the object's burden thread.
    #
    var inThread 0
    
    echo Getting on the right thread...
    var bp [cbrk ObjCallMethodTable ds=^h[handle id [index $a 0]] si=[index $a 1] ax=MSG_META_NULL]
    brk cmd $bp grobjstring-in-thread-catch
    
    omfq MSG_META_NULL $addr
    stop-catch {
    	continue-patient
	wait
    	brk clear $bp
	if {!$inThread} {
	    error {stopped too soon}
    	}
    }
    
    #
    # Now allocate the graphics string into which the thing will be drawn.
    #
    echo Allocating graphics string
    var tf [value fetch ui::uiTransferVMFile]
    if {![call-patient GrCreateGString bx $tf cl geos::GST_VMEM]} {
	restore-state
    	error {unable to create gstring in clipboard file}
    }
    var gs [read-reg di] vmb [read-reg si]
    restore-state
    
    #
    # Call a message to the object to print (MSG_GO_DRAW)
    #
    echo Printing object
    if {![call-patient ObjCallInstanceNoLock ax grobj::MSG_GO_DRAW bp $gs cl [fieldmask DF_PRINT] dx [fieldmask grobj::GODF_DRAW_WITH_INCREASED_RESOLUTION]]} {
    	restore-state
	call-patient GrDestroyGString di 0 si $gs dl geos::GSKT_KILL_DATA
	error {unable to send MSG_GO_DRAW}
    }
    restore-state
    
    #
    # Now print out the graphics string
    #
    pgs -s ^h$gs

    echo Destroying gstring
    call-patient GrDestroyGString di 0 si $gs dl geos::GSKT_KILL_DATA
    restore-state
#    echo vm file = $tf, vm block = $vmb
}]

[defsubr grobjstring-in-thread-catch {}
{
    uplevel grobjstring var inThread 1
    return 1
}]
