##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#	$Id: objtree.tcl,v 3.7 91/01/18 17:13:51 roger Exp $
#
###############################################################################
defsubr fieldpos {f} {
	return [type size [index [sym get [sym find field $f]] 3]]
}

[defcommand gentree {{obj *ds:si} {extrafield 0} {indent 0}} output
{gentree [address] [instance field]
"gentree [impliedgrab]"     prints out the tree under the mouse
"gentree @23 GI_states"	    print out tree with generic states
"gentree *uiSystemObj"	    start the gentree at the root of the system

Print out a generic tree.

* The address argument is the address to an object in the generic
tree.  This defaults to *ds:si. 

* The instance field argument is the offset to any instance data
within the GenInstance which should be printed out.

Make sure, especially when using [impliedgrab], that you are in the
appropriate patient.

See also vistree, impliedgrab.
}
{
    echo
    objtree $obj $extrafield $indent 4 Gen_offset GI_link GI_comp
}]

[defcommand vistree {{obj *ds:si} {extrafield 0} {indent 0}} output
{vistree [address] [instance field]
"vistree"		    prints out the tree under the mouse
"vistree @23 VI_optFlags"   print out tree with opt flags
"vistree *uiSystemObj"	    starts the visual tree at the root of the system

Print out a visual tree.

* The address argument is the address to an object in the generic
tree.  This defaults to *ds:si. 

* The instance field argument is the offset to any instance data
within the VisInstance which should be printed out.

Make sure, especially when using [impliedgrab], that you are in the
appropriate patient.

See also gentree, impliedgrab.
}
{
    echo
    objtree $obj $extrafield $indent 4 Vis_offset VI_link VCI_comp
}]


[defcommand impgentree {{obj 0} {extrafield 0} {indent 0}} output
{Prints out generic tree starting at implied grab}
{
    if {$obj == 0} {var obj [impliedgrab]}
    echo
    objtree $obj $extrafield $indent 4 Gen_offset GI_link GI_comp
}]

[defcommand impvistree {{obj 0} {extrafield 0} {indent 0}} output
{Prints out visible tree starting at implied grab}
{
    if {$obj == 0} {var obj [impliedgrab]}
    echo
    objtree $obj $extrafield $indent 4 Vis_offset VI_link VCI_comp
}]


[defcommand gup {{obj *ds:si} {extrafield 0} {indent 0}} output
{Prints a list of this object & all generic parents.  A second
argument may be passed, which is the offset to any instance data within
GenInstance which should be printed out.  (For instance, GI_states)}
{
    echo
    objparent $obj $extrafield $indent Gen_offset GI_link GI_comp
}]

[defcommand vup {{obj *ds:si} {extrafield 0} {indent 0}} output
{Prints a list of this object & all visible parents.  A second
argument may be passed, which is the offset to any instance data within
VisInstance which should be printed out (For instance, VI_optFlags)}
{
    echo
    objparent $obj $extrafield $indent Vis_offset VI_link VCI_comp
}]

[defsubr getobjclass {obj}
{
    var sym [obj-class $obj]
    if {![null $sym]} {
    	return [symbol name $sym]
    }
}]

[defcommand pclass {{obj *ds:si}} output
{Prints the class of an object.}
{
    echo [getobjclass $obj]
}]

[defsubr objtree {obj extrafield indent depth masterOffset linkOffset compOffset}
{
	require pvismon pvm

    # Get the segment and offset of the object to print out.
    var objclass [getobjclass ($obj)]
    var addr [addr-parse ($obj)]
    var label [value hstore $addr]
    var bl [handle id [index $addr 0]]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]
    var masteroff [value fetch ($obj).$masterOffset]
    var master [expr [index $addr 1]+$masteroff]

    echo -n [format {%*s%s (@%d, ^l%xh:%xh) } $indent {} $objclass $label
								$bl $ch]

    if {$masteroff == 0} {
	echo { -- not yet built}
    } else {
        if {![string c $masterOffset Vis_offset]} {
            var bounds [value fetch ^h$bl:$master.VI_bounds]
	    var comp [field [value fetch ^h$bl:$master.VI_typeFlags]
							VTF_IS_COMPOSITE]
	    echo [format {, rect (%d, %d, %d, %d) }
			[field $bounds R_left] [field $bounds R_top]
			[field $bounds R_right] [field $bounds R_bottom] ]
	} elif {![string c $masterOffset Gen_offset]} {
	    var off [value fetch ^h$bl:$master.GI_visMoniker word]
	    if {[handle state [handle lookup $bl]] & 1} {
			#handle is resident
		if {$off != 0} then {
			pvismon *$seg:$off 1
		} else {
			echo
		}
	     } else {
		echo *** Non-resident ***
	     }
	    var comp [value fetch ^h$bl:$master.GI_comp.CP_firstChild.OD_handle]
	} else {
	    var comp 0
	}
	if {[string c $extrafield 0] != 0} {print (^h$bl:$master).$extrafield}
	if {$comp } {
	  if {$depth > 1} {
    	    var op [fetch-optr $bl $master.$compOffset.CP_firstChild]
	    var childHan [index $op 0] childCh [index $op 1]
	    while {(($childCh&1) == 0) && ($childCh != 0)} {
    	    	var caddr ^l$childHan:$childCh
	        [objtree $caddr $extrafield [expr $indent+3] [expr $depth-1]
		    	 $masterOffset $linkOffset $compOffset]
    		var masteroff [value fetch ($caddr).$masterOffset]
    		var master [expr [value fetch ^h$childHan:$childCh word]+$masteroff]
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
	require pvismon

    # Get the segment and offset of the object to print out.
    var addr [addr-parse $obj]
    var label [value hstore $addr]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    var masteroff [value fetch $seg:$off.$masterOffset]
    var master [expr $off+$masteroff]
    var bl [expr [value fetch $seg:0 [type word]]]
    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]

    var objclass [getobjclass $obj]
    echo -n [format {%*s%s (@%d, ^l%xh:%xh) } 0 {} $objclass $label
								$bl $ch]

    if {$masteroff == 0} {
	echo { -- not yet built}
    } else {
        if {![string c $masterOffset Vis_offset]} {
            var bounds [value fetch $seg:$master.VI_bounds]
	    echo [format {, rect (%d, %d, %d, %d)}
			[field $bounds R_left] [field $bounds R_top]
			[field $bounds R_right] [field $bounds R_bottom] ]
	} elif {![string c $masterOffset Gen_offset]} {
	    var off [value fetch ^h$bl:$master.GI_visMoniker word]
	    if {$off != 0} then {
		pvismon *$seg:$off 1
	    } else {
		echo
	    }
	} else {
	    echo
	}
	if {[string c $extrafield 0] != 0} {print ($seg:$master).$extrafield}

	# start with this object
	var nextHan $bl
	var nextCh $ch
				# And follow nextSibling linkage to get parent
				# (recognizable by low bit in chunk handle of
				# linkage being set)
	while {(($nextCh&1) == 0) && ($nextHan != 0)} {
	    var nextHan [value fetch
			$seg:$master.$linkOffset.LP_next.OD_handle]
	    var nextCh [value fetch
			$seg:$master.$linkOffset.LP_next.OD_chunk]
            var seg [handle segment [handle lookup $nextHan]]
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
