##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	objtree.tcl
# AUTHOR: 	Chris/tony/doug
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	objtree	    	    	Print an object composite tree
#
#	$Id: objtree.tcl,v 3.35.6.1 97/03/29 11:26:51 canavese Exp $
#
###############################################################################
[defvar printNamesInObjTrees 0 swat_variable.output
{Usage:
    var printNamesInObjTrees (0|1)

Examples:
    "var printNamesInObjTrees 1"    Sets "gentree", "vistree", etc. commands
    	    	    	    	    to print object names (where available)

Synopsis:
    Determines whether object names are printed (where available) rather
    than class names when using the following commands:
    	vistree
    	gentree
    	focus
    	target
    	model
    	mouse
    	keyboard

Notes:
    * The default value for this variable is 0.

See also:
    gentree, vistree, focus, target, model, mouse, keyboard
}]

[defvar objtreeDepth 4 swat_variable.output
{Usage:
    var objtreeDepth (0-9+)

Examples:
    "var printNamesInObjTrees 10"    Sets "gentree", "vistree", etc. commands
    	    	    	    	     to print to a depth of 10

Synopsis:
    Controls how deep to print an object tree when using the
    following commands:
    	vistree
    	gentree

Notes:
    * The default value for this variable is 4.

See also:
    gentree, vistree
}]

defsubr fieldpos {f} {
	return [type size [index [sym get [sym find field $f]] 3]]
}

[defcmd gentree {{obj {}} {extrafield 0} {indent 0}} {top.object object.gen}
{Usage:
    gentree [<address>] [<instance field>]

Examples:
    "gentree"	    	    	print the generic tree starting at *ds:si
    "gentree -i"        	print the generic tree under the mouse
    "gentree [systemobj]"       print the generic tree starting at the 
    	    	    	    	system's root
    "gentree @23 GI_states"	print the generic tree with generic states
    "gentree *uiSystemObj"	start the generic tree at the root of the system

Synopsis:
    Print a generic tree.

Notes:
    * The address argument is the address to an object in the generic
      tree.  This defaults to *ds:si.

    * The special object flags may be used to specify <address>.  For a
      list of these flags, see pobj.

    * The instance field argument is the offset to any instance data
      within the GenInstance which should be printed out.

    * The variable "printNamesInObjTrees" can be used to print out the actual
      app-defined labels for the objects, instead of the class, where available.
      This variable defaults to false.

    * The variable "objtreeDepth" is the maximum depth to which a tree
      will be printed.
      This variable defaults to 4.

See also:
    gup, vistree, impliedgrab, systemobj.
}
{
    require default-patient user.tcl
    global objtreeDepth

    if {[string match $extrafield {[^0-9]*}]} {
    	var extrafield [default-patient ui $extrafield]
    }

    echo
    objtree $obj $extrafield $indent $objtreeDepth ui::Gen_offset ui::GI_link ui::GI_comp
}]

[defcmd vistree {{obj {}} {extrafield 0} {indent 0}} {top.object object.vis}
{Usage:
    vistree [<address>] [<instance field>]

Examples:
    "vistree"	    	    	print the visual tree starting at *ds:si
    "vistree -i"		print the visual tree under the mouse
    "vistree @23 VI_optFlags"   print the visual tree with opt flags
    "vistree *uiSystemObj"	starts the visual tree at the root of the system

Synopsis:
    Print out a visual tree.

Notes:
    * The address argument is the address to an object in the generic
      tree.  This defaults to *ds:si.

    * The special object flags may be used to specify <address>.  For a
      list of these flags, see pobj.

    * The instance field argument is the offset to any instance data
      within the VisInstance which should be printed out.

    * The variable "printNamesInObjTrees" can be used to print out the actual
      app-defined labels for the objects, instead of the class, where available.
      This variable defaults to false.

    * The variable "objtreeDepth" is the maximum depth to which a tree
      will be printed.
      This variable defaults to 4.

See also:
    vup, gentree, impliedgrab.
}
{
    require default-patient user.tcl
    global objtreeDepth

    if {[string match $extrafield {[^0-9]*}]} {
    	var extrafield [default-patient ui $extrafield]
    }
    echo
    objtree $obj $extrafield $indent $objtreeDepth ui::Vis_offset ui::VI_link ui::VCI_comp
}]


[defcmd gup {{obj {}} {extrafield 0} {indent 0}} {top.object object.gen}
{Usage:
    gup [<address>] [<instance field>]

Examples:
    "gup"	    	    print the generic object at *ds:si and its ancestors
    "gup @23 GI_states"     print the states of object @23 and its ancestors
    "gup -i	    	    print the generic object under the mouse
    	    	    	    and the object's ancestors

Synopsis:
    Print a list of the object and all of its generic ancestors.

Notes:
    * The address argument is the address to an object in the generic
      tree.  This defaults to *ds:si.

    * The instance field argument is the offset to any instance data
      within the GenInstance which should be printed out.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

See also:
    gentree, vup, vistree, impliedgrab.
}
{
    require default-patient user.tcl

    if {[string match $extrafield {[^0-9]*}]} {
    	var extrafield [default-patient ui $extrafield]
    }
    echo
    objparent $obj $extrafield $indent ui::Gen_offset ui::GI_link ui::GI_comp
}]

[defcmd vup {{obj {}} {extrafield 0} {indent 0}} {top.object object.vis}
{Usage:
    vup [<address>] [<instance field>]

Examples:
    "vup"	    	    print the visual object at *ds:si and its ancestors
    "vup @23 VI_optFlags"   print the states of object @23 and its ancestors
    "vup -i	    	    print the visual object under the mouse
    	    	            and the object's ancestors

Synopsis:
    Print a list of the object and all of its visual ancestors.

Notes:
    * The address argument is the address to an object in the visual
      tree.  This defaults to *ds:si.

    * The instance field argument is the offset to any instance data
      within the GenInstance which should be printed out.

    * The special object flags may be used to specify <address>.  For a
      list of these flags, see pobj.

See also:
    vistree, gup, gentree, impliedgrab.
}
{
    require default-patient user.tcl

    if {[string match $extrafield {[^0-9]*}]} {
    	var extrafield [default-patient ui $extrafield]
    }
    echo
    objparent $obj $extrafield $indent ui::Vis_offset ui::VI_link ui::VCI_comp
}]

[defsubr getobjclass {obj}
{
    var sym [obj-class $obj]
    if {![null $sym]} {
    	return [symbol name $sym]
    }
}]

[defcmd pclass {args} object.print
{Usage:
    pclass [-h] [<address>]

Examples:
    "pclass"   	    	prints the class of *ds:si
    "pclass -h *Foo"	prints out complete class hierarchy of object *Foo

Synopsis:
    Print the object's class.

Notes:
    * The address argument is the address of the object to find class
      of.  This defaults to *ds:si.
}
{
    require obj-foreach-class object.tcl
    var hierarchicalPrint 0

    for {var i 0} {$i < [length $args]} {[var i [expr $i+1]]} {
	var arg [index $args $i]

	if {[string match $arg -*]} {
	    if { $arg == {-h} } {
		var hierarchicalPrint 1
	    } else {
		error [concat {pclass: Unknown option:} $arg]
	    }
	} else {
	    if { ! [null $obj] } {
		error {pclass: Too many arguments}
	    } else {
		var obj $arg
	    }
	}
    }

    if { [null $obj] } {
	var obj {*ds:si}
    }

    if { $hierarchicalPrint == 1 } {
	# Print out the hierarchy.. use obj-foreach-class and a callback to
	# do this.

	var level {}
	obj-foreach-class pclass-hier-cb $obj

    } else {
	# Just print out the class of this object.

	echo [getobjclass $obj]
    }
}]

[defsubr pclass-hier-cb {class-sym obj} {
    var ctype [symbol type ${class-sym}]
    
    if { $ctype == variantclass } {
	var ctypeName {** Variant Master Class **}
	var vm 1
    } elif { $ctype == masterclass } {
	var ctypeName {** Master Class **}
	var vm 1
    } else {
	var ctypeName {}
    }
    
    echo [format {%s%s/%s    %s} [uplevel pclass var level]
	  [symbol name ${class-sym}]
	  [patient name [symbol patient ${class-sym}]]
	  $ctypeName]
	  
    if { ! [null $vm] } {
    	uplevel pclass var level {}
    } else {
    	uplevel pclass var level [format {%s  } [uplevel pclass var level]]
    }
	  
    return {}
}]

[defsubr objtree {obj extrafield indent depth masterOffset linkOffset compOffset}
{
	require pvismon pvm
    	require addr-with-obj-flag user
    	require print-obj-and-method object

    global printNamesInObjTrees

    # Get the segment and offset of the object to print out.
    var obj [addr-with-obj-flag $obj]
    var objclass [getobjclass ($obj)]
    var addr [addr-preprocess ($obj) seg off]
    var bl [handle id [index $addr 0]]
    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]
    if {[null $masterOffset]} {
    	var masteroff -1
    	var master [index $addr 1]
    } else {
    	var masteroff [value fetch ($obj).$masterOffset]
    	var master [expr [index $addr 1]+$masteroff]
    }

    echo -n [format {%*s } $indent {}]
    print-obj-and-method $bl $ch -n

    if {$masteroff == 0} {
	echo { -- not yet built}
    } else {
        if {![string c $linkOffset ui::VI_link]} {
            var bounds [value fetch ^h$bl:$master.ui::VI_bounds]
	    var comp [field [value fetch ^h$bl:$master.ui::VI_typeFlags]
							VTF_IS_COMPOSITE]
	    echo [format {, rect (%d, %d, %d, %d) }
			[field $bounds R_left] [field $bounds R_top]
			[field $bounds R_right] [field $bounds R_bottom] ]
	} elif {![string c $linkOffset ui::GI_link]} {
	    var off [value fetch ^h$bl:$master.ui::GI_visMoniker word]
	    if {[handle state [handle lookup $bl]] & 1} {
			#handle is resident
		if {$off != 0} then {
			echo -n [format { }]
			pvismon *$seg:$off 1
		} else {
			echo
		}
	     } else {
		echo *** Non-resident ***
	     }
	    var comp [value fetch ^h$bl:$master.ui::GI_comp.CP_firstChild.handle]
	} elif {![string c $linkOffset grobj::GOI_drawLink]} {
	    var comp [value fetch ^h$bl:$master.$compOffset.CP_firstChild.handle]
    	    var masterOffset {}
    	    echo
	}
	if {[string c $extrafield 0] != 0} {_print (^h$bl:$master).$extrafield}
	if {$comp } {
	  if {$depth > 1} {
    	    var op [fetch-optr $bl $master.$compOffset.CP_firstChild]
	    var childHan [index $op 0] childCh [index $op 1]
	    while {(($childCh&1) == 0) && ($childCh != 0)} {
    	    	var caddr ^l$childHan:$childCh
	        [objtree $caddr $extrafield [expr $indent+3] [expr $depth-1]
		    	 $masterOffset $linkOffset $compOffset]
    	    	if {[null $masterOffset]} {
    		    var master [value fetch ^h$childHan:$childCh word]
    	    	} else {
    		    var masteroff [value fetch ($caddr).$masterOffset]
    		    var master [expr [value fetch ^h$childHan:$childCh word]+$masteroff]
    	    	}
    	    	var op [fetch-optr $childHan $master.$linkOffset.LP_next]
    	    	var childHan [index $op 0] childCh [index $op 1]
	    }
	  } else {
    		echo [format {%*s>>>} [expr $indent+3] {} ]
	  }
	}
    }
    if {$indent == 0} {
        echo
    }
}]


[defsubr objparent {obj extrafield indent masterOffset linkOffset compOffset}
{
	require pvismon pvm
    	require addr-with-obj-flag user
    	require print-obj-and-method object

    # Get the segment and offset of the object to print out.
    var obj [addr-with-obj-flag $obj]
    var addr [addr-preprocess $obj seg off]
    var masteroff [value fetch $seg:$off.$masterOffset]
    var master [expr $off+$masteroff]
    var bl [expr [value fetch $seg:0 [type word]]]
    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]

    print-obj-and-method $bl $ch -n

    if {$masteroff == 0} {
	echo { -- not yet built}
    } else {
        if {![string c $masterOffset ui::Vis_offset]} {
            var bounds [value fetch $seg:$master.ui::VI_bounds]
	    echo [format {, rect (%d, %d, %d, %d)}
			[field $bounds R_left] [field $bounds R_top]
			[field $bounds R_right] [field $bounds R_bottom] ]
	} elif {![string c $masterOffset ui::Gen_offset]} {
	    var off [value fetch ^h$bl:$master.ui::GI_visMoniker word]
	    if {$off != 0} then {
		echo -n [format { }]
		pvismon *$seg:$off 1
	    } else {
		echo
	    }
	} else {
	    echo
	}
	if {[string c $extrafield 0] != 0} {_print ($seg:$master).$extrafield}

	# start with this object
	var nextHan $bl
	var nextCh $ch
				# And follow nextSibling linkage to get parent
				# (recognizable by low bit in chunk handle of
				# linkage being set)
	while {(($nextCh&1) == 0) && ($nextHan != 0)} {
	    var nextHan [value fetch
			$seg:$master.$linkOffset.LP_next.handle]
	    var nextCh [value fetch
			$seg:$master.$linkOffset.LP_next.chunk]
            var seg ^h$nextHan
	    var off [value fetch $seg:[expr $nextCh&0xfffe] word]
    	    var masteroff [value fetch $seg:$off.$masterOffset]
    	    var master [expr $off+$masteroff]
	}
	if {$nextHan != 0} {
	    [objparent $seg:$off $extrafield [expr $indent+3] $masterOffset
						$linkOffset $compOffset]
	}
    }
    if {$indent == 0} {
        echo
    }
}]



##############################################################################
#	objtree-enum
##############################################################################
#
# SYNOPSIS:	Traverse a tree of objects -- using callback routines
#		to process the various parts
#
# PASS:		obj - object to start at
#   	    	indent - current indent level
#   	    	depth - maximum depth
#
#   	    	objCB - callback routine to print out
#   	    	    the current object.  Define objCB as:
#   	    	    PASS:
#		    	  obj - OD of the current object
#			  extra - extra data (passed to objtree-enum)
#   	    	    	  indent - number of spaces OD printout is indented
#
#   	    	linkFN = function that returns the OD of the next sibling
#		    PASS: obj - OD of the object
#		
#   	    	compFN = function that determines whether the current
#			object is a composite, and if so, returns the
#			OPTR to its first child as a list.
#		    PASS: obj - OD of the object
#
#   	    	extra - extra data which is passed to objCB
#   	    	    
#
# CALLED BY:	GLOBAL
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cdb 	6/ 1/92   	baldly plagiarized from objtree
#
##############################################################################
[defsubr objtree-enum {obj indent depth objCB linkFN compFN extra}
{
	require pvismon pvm
    	require addr-with-obj-flag user

    # Get the segment and offset of the object to print out.
    var objclass [getobjclass ($obj)]
    var addr [addr-parse ($obj)]
    var label [value hstore $addr]
    var bl [handle id [index $addr 0]]
    var seg ^h$bl
    var off [index $addr 1]
    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]

    echo -n [format {%*s%s (@%d, ^l%04xh:%04xh) } $indent {} $objclass $label
								$bl $ch]

    if {![null $objCB]} {
    	    $objCB $obj $extra $indent
    }

    echo

    if {$depth > 1} {
	var op [$compFN $obj]
	if {![null $op]} {
	    var childHan [index $op 0] childCh [index $op 1]

	    # Enumerate all the siblings until we get to a parent pointer.
	    
	    while {(($childCh & 1) == 0) && ($childCh != 0)} {
    	    	var child ^l$childHan:$childCh
	    	[objtree-enum $child [expr $indent+3] [expr $depth-1]
		   	 $objCB $linkFN $compFN $extra]

	    	var op [$linkFN $child]
		if {![null $op]} {
    	    	    var childHan [index $op 0] childCh [index $op 1]
		} else {
		    var childCh 0
		}
	    }
	}
    } else {
        echo [format {%*s>>>} [expr $indent+3] {} ]
    }
}]

