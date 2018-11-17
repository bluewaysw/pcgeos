##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	swat/lib
# FILE: 	user.tcl
# AUTHOR: 	Doug Fults, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Misc NEW_UI functions
#
#	$Id: user.tcl,v 3.36.11.1 97/03/29 11:26:26 canavese Exp $
#
###############################################################################


[defcommand systemobj {} object.address
{Usage:
    systemobj

Examples:
    "gentree [systemobj]"   	print the generic tree starting at the 
    	    	    	    	system's root
    "pobject [systemobj]"   	print the system object

Synopsis:
    Prints out the address of the uiSystemObj, which is the top level of the 
    generic tree.

Notes:
    * This command is normally used with gentree as shown above to print out 
      the whole generic tree starting from the top.

See also:
    gentree, impliedgrab.
}
{
    if  {![null [sym find var ui::uiSystemObj]]} {
    	var system ui::uiSystemObj
    } else {
	# If there's no symbol defined, then assume we're dealing with a 2.0
	# GYM file here & look directly into code to get the address of the
	# variable.  Yes, this only works as longs as the code doesn't move.
    	var seg [value fetch ui::UserCallSystem+4 word]
    	var off [value fetch ui::UserCallSystem+14 word]
    	var system $seg:$off
    }
    var addr ^l[value fetch $system.handle]:[value fetch $system.chunk]
    return $addr
}]


[defcommand flowobj {} object.address
{Usage:
    flowobj

Examples:
    "pobject [flowobj]"	    print out the flow object

Synopsis:
    Prints out address of the uiFlowObj, which is the object which 
    grabs the mouse.

Notes:
    * This command is normally used with pobject to print out the object.
}
{
    if  {![null [sym find var ui::uiFlowObj]]} {
    	var flow ui::uiFlowObj
    } else {
	# If there's no symbol defined, then assume we're dealing with a 2.0
	# GYM file here & look directly into code to get the address of the
	# variable.  Yes, this only works as longs as the code doesn't move.
    	var seg [value fetch ui::UserCallFlow+4 word]
    	var off [value fetch ui::UserCallFlow+14 word]
    	var flow $seg:$off
    }
    var addr ^l[value fetch $flow.handle]:[value fetch $flow.chunk]
    return $addr
}]


[defcommand impliedwin {} object.address
{Usage:
    impliedwin

Examples:
    "wintree [impliedwin]"  	print the window tree of the window under
    	    	    	    	the mouse
Synopsis:
    Print the address of the current implied window (the window under the
    mouse).

Notes:
    * Note that the handle is returned as ^h<handle>.

    * This command is normally used with "wintree".  One may also use
      "print" if one properly casts the handle.
}
{
    # Returns implied window handle as ^h
    if {[not-1x-branch]} {
    	var iw [format {^h%04xh} 
	    	[value fetch ([flowobj]).ui::FI_impliedWin.ui::MG_gWin]]
    } else {
    	var iw [format {^h%04xh} 
	    	[value fetch ([flowobj]).ui::FI_impliedMouseGrab.ui::G_gWin]]
    }
    return $iw
}]


[defcommand impliedgrab {} object.address
{Usage:
    impliedgrab

Examples:
    "gentree [impliedgrab]" 	print the generic tree under the mouse

Synopsis:
    Print the address of the current implied grab, which is the windowed screen
    object under the mouse.

Notes:
    * This command is normally used with gentree to get the generic tree of
      an application by placing the mouse on application's window and
      issuing the command in the above example.

See also:
    systemobj, gentree.
}
{
    # Returns object holding implied mouse grab
    if {[not-1x-branch]} {
            var ig [format {^l%04xh:%04xh} 
    	    [value fetch ([flowobj]).ui::FI_impliedWin.ui::MG_OD.handle]
	    [value fetch ([flowobj]).ui::FI_impliedWin.ui::MG_OD.chunk]]
    } else {
            var ig [format {^l%04xh:%04xh} 
    	    [value fetch ([flowobj]).ui::FI_impliedMouseGrab.ui::G_OD.handle]
	    [value fetch ([flowobj]).ui::FI_impliedMouseGrab.ui::G_OD.chunk]]
    }
    return $ig
}]





[defcommand content {} {top.object object.address}
{Usage:
    content

Examples:
    "vistree [content]" 	print the visual tree of the content of the
				view under the mouse.

Synopsis:
    Print the address of the content under the view with the current implied 
    grab.   Only works for V2.0 or higher.

Notes:
    * This command is normally used with vistree to get the visual tree of
      a content by placing the mouse on the content's view window and
      issuing the command in the example.

    * If the pointer is not over a GenView object, this is the same as the
      "impliedgrab" command.

See also:
    systemobj, gentree, impliedgrab.
}
{
    # Returns object holding implied mouse grab
    var ig [impliedgrab]
    
    if {[is-obj-in-class $ig GenViewClass]} {
    	var ig (($ig)+[value fetch ($ig).ui::Gen_offset]).ui::GVI_content
    	var ig [format {^l%04xh:%04xh}
	    	[value fetch $ig.handle]
		[value fetch $ig.chunk]]
    }
    return $ig
}]

[defcommand appobj {{patient {}}} object.address
{Usage:
    appobj [<patient>]

Examples:
    "pobj [appobj draw]" 	prints the GenApplication object for draw

Synopsis:
    Returns the address of the GenApplication object for the given patient,
    or the current one if you give no patient.

Notes:

See also:
    impliedgrab.
}
{
    if {[null $patient]} {
    	var patient [patient name]
	# Prevent what Jenny reports as an untimely death
	if {[string match $patient geos]} {
		error {appobj: patient geos has no application object}
	}
    }
    var p [patient find $patient]
    if {[null $p]} {
    	error [format {appobj: patient %s not known} $patient]
    }
    var core [index [patient resources $p] 0]
    if {![value fetch ^h[handle id $core]:GH_geodeAttr.GA_PROCESS]} {
    	error [format {appobj: patient %s is not a process so it can't have an application object} $patient]
    }
    var obj [value fetch ^h[handle id $core]:PH_appObject]
    
    return [format {^l%04xh:%04xh} [expr ($obj>>16)&0xffff] [expr $obj&0xffff]]
}]


[defcommand procobj {{patient {}}} object.address
{Usage:
    procobj [<patient>]

Examples:
    "methods [procobj grobj]" 	Look at the methods defined in draw's process

Synopsis:
    Returns the address of GenProcess object for the given patient, or the
    current one if you give no patient.

Notes:

See also:
    impliedgrab.
}
{
    if {[null $patient]} {
    	var patient [patient name]
    }
    var p [patient find $patient]
    if {[null $p]} {
    	error [format {appobj: patient %s not known} $patient]
    }
    var core [index [patient resources $p] 0]
    if {![value fetch ^h[handle id $core]:GH_geodeAttr.GA_PROCESS]} {
    	error [format {appobj: patient %s is not a process so it can't have a process object} $patient]
    }
    return [format {^h%04xh} [handle id $core]]
}]

#This is used within commands to check if the address passed is '-i'.  If
#so then the result of an implied grab is returned.  Otherwise the
#address passed is returned.

[defcommand addr-with-obj-flag {address} swat_prog.object
{Usage:
    addr-with-obj-flag <address>

Examples:
    "var addr [addr-with-obj-flag $addr]"	If $addr is "-i", returns
						the address of the current
						implied grab.

Synopsis:
    This is a utility routine that can be used by any command that
    deals with objects where the user may reasonably want to operate on the
    leaf object of one of the hierarchies, or the windowed object under the
    mouse. It can be given one of a set of flags that indicate where to find
    the address of the object on which to operate.

Notes:
    * Special values accepted for <address>:
    	Value	Returns address expresion for...
	-----	-----------------------------------------------------------
    	-a  	the current patient's application object
	-p	the current patient's process
    	-i  	the current "implied grab": the windowed object over which
		the mouse is currently located.
    	-f  	the leaf of the keyboard-focus hierarchy
	-t  	the leaf of the target hierarchy
	-m  	the leaf of the model hierarchy
	-c  	the content for the view over which the mouse is currently
		located
    	-kg  	the leaf of the keyboard-grab hierarchy
	-mg 	the leaf of the mouse-grab hierarchy

    * If <address> is empty, this will return the contents of the local
      variable "oself" within the current frame, if it has one, or *ds:si

    * If <address> isn't one of the above, this just returns <address>.

See also:
    impliedgrab, content, focusobj, targetobj, modelobj, keyboardobj, mouseobj.
}
{
    [case $address in
     -a {return [appobj]}
     -p {return [procobj]}
     -i {return [impliedgrab]}
     -f {return [focusobj]}
     -t {return [targetobj]}
     -m {return [modelobj]}
     -c {return [content]}
     -kg {return [keyboardobj]}
     -mg {return [mouseobj]}
     {{}} {
    	#
	# Return default address. If current frame's function has an oself
	# local variable, decompose it into an optr, else return *ds:si.
	#
	var oself [symbol find locvar oself [frame funcsym]]
	
	if {[null $oself]} {
	    return *ds:si
	} else {
	    return ^l[value fetch oself.handle]:[value fetch oself.chunk]
    	}
     }
     default {
    	#
	# Explicit address passed. Cope with C-style optrs being passed here
	# (address parses to that of a dword, rather than nothing (as happens
	# with ^lblah:mumble et al)).
	#
    	if {[catch {addr-preprocess $address seg off} a] != 0} {
	    # might be patient or thread, so return it unmolested
	    return $address
    	} else {
	    var t [index $a 2]
	    if {![null $t] && [type class $t] == int && [type size $t] == 4} {
		#
		# Likely a C optr, so break it into two halves and reparse.
		#
		var v [value fetch $seg:$off $t]
		return ^l[expr ($v>>16)&0xffff]:[expr $v&0xffff]
	    } else {
		return $address
	    }
    	}
     }
    ]
}]


# Several commands want to access fields in structures normally found in
# a patient (like the ui) but which sometimes appear in other threads
# (like motif).  So, this subroutine is used to check if the argument is
# visible in the current patient.  If not the routine prepends the 
# passed patient to the argument.  The result returned is a symbol which
# will be found.

[defsubr default-patient {patient arg}
{
    if {[null [sym find {field} $arg]]} {
    	return $patient::$arg
    } else {
    	return $arg
    }
}]

[defcommand screenwin {} object.address
{Usage:
    screenwin

Synopsis:
    Print the address of the current top-most screen window.

}
{
    # returns top-most screen window
    var addr [systemobj]
    var addr ($addr)+[value fetch ($addr).ui::Vis_offset]
    var addr ^l[value fetch ($addr).ui::VCI_comp.CP_firstChild.handle]:[value fetch ($addr).ui::VCI_comp.CP_firstChild.chunk]
    var addr ($addr)+[value fetch ($addr).ui::Vis_offset]
    return ^h[value fetch ($addr).ui::VCI_window]
}]

[defcommand fieldwin {} object.address
{Usage:
    fieldwin

Synopsis:
    Print the address of the current top-most field window.

}
{
    # returns top-most field window
    var addr [systemobj]
    var addr ($addr)+[value fetch ($addr).Vis_offset]
    var addr ^l[value fetch ($addr).VCI_comp.CP_firstChild.handle]:[value fetch ($addr).VCI_comp.CP_firstChild.chunk]
    var addr ($addr)+[value fetch ($addr).Vis_offset]
    var addr ^l[value fetch ($addr).VCI_comp.CP_firstChild.handle]:[value fetch ($addr).VCI_comp.CP_firstChild.chunk]
    var addr ($addr)+[value fetch ($addr).Vis_offset]
    return ^h[value fetch ($addr).VCI_window]
}]


[defcmd pgen {element {obj *ds:si}} object.print.fast
{Usage:
    pgen <element> [<object>]

Examples:
    "pgen GI_states @65"	print the states of object 65
    "pgen GI_visMoniker"	print the object at *ds:si
    "pgen GI_states -i"   	print the states of the object at the 
    	    	    	    	implied grab

Synopsis:
    Print an element of the generic instance data.

Notes:
    * The element argument specifies which element in the object to print

    * The object argument is the address to the object to print out.
      It defaults to *ds:si and is optional.  The '-i' flag for an
      implied grab may be used.

See also:
    gentree, gup, pobject, pvis.
}
{
    	require addr-with-obj-flag user

        var obj [addr-with-obj-flag $obj]
	_print (($obj)+[value fetch ($obj).ui::Gen_offset]).[default-patient ui $element]
}]


[defcmd pvis {element {obj *ds:si}} {object.print.fast object.vis}
{Usage:
    pvis <element> [<object>]

Examples:
    "pvis VI_bounds @65"    print the bounds of object 65
    "pvis VI_optFlags"	    print the flags of the object at *ds:si
    "pvis VI_attrs -i" 	    print the attributes of the object at the 
    	    	    	    implied grab

Synopsis:
    Print an element of the visual instance data.

Notes:
    * The element argument specifies which element in the object to print

    * The object argument is the address to the object to print out.
      It defaults to *ds:si and is optional.  The '-i' flag for an
      implied grab may be used.

See also:
    vistree, vup, pobject, pgen.
}
{
    	require addr-with-obj-flag user

        var obj [addr-with-obj-flag $obj]
	_print (($obj)+[value fetch ($obj).ui::Vis_offset]).[default-patient ui $element]
}]

[defcmd pvsize {{obj {}}} object.vis
{Usage:
    pvsize [<object>]

Examples:
    "pvsize"   	    print the dimensions of the visual object at *ds:si

Synopsis:
    Print out the dimensions of a visual object.

Notes:
    * The object argument is the address to the object to print out.
      It defaults to *ds:si and is optional.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.
}
{
    require addr-with-obj-flag user

    var obj [addr-with-obj-flag $obj]
    var vis ($obj)+[value fetch ($obj).ui::Vis_offset]
    var left [value fetch ($vis).ui::VI_bounds.geos::R_left]
    var right [value fetch ($vis).ui::VI_bounds.geos::R_right]
    var top [value fetch ($vis).ui::VI_bounds.geos::R_top]
    var bottom [value fetch ($vis).ui::VI_bounds.geos::R_bottom]
    echo [format {width = %4d, height = %4d} [expr {$right-$left}] 
	[expr {$bottom-$top}]]
}]

[defcmd sbwalk {{pat {}}} {patient.handle system.misc}
{Usage:
    sbwalk [<patient>]

Examples:
    "sbwalk"	    	list the saved blocks of the current patient.
    "sbwalk geos"   	list the saved blocks of the geos patient.

Synopsis:
    List all the saved blocks in a patient.

Notes:
    * The patient argument is any GEOS patient.  If none is specified
      then the current patient is used. 
}
{
    if {[null $pat]} {
    	var pat [index [patient data] 0]
    }
    var pid [patient find $pat]
    var core ^h[handle id [index [patient resources $pid] 0]]
    if {[field [value fetch $core:GH_geodeAttr] GA_PROCESS]} {
        var han [value fetch $core:PH_savedBlockPtr]
    } else {
    	var han 0
    }

    if {$han == 0} {
    	echo There are no saved blocks for $pat.
    } else {
    	while {$han != 0} {
    	    echo -n [format {(%04xh) -- } $han]
    	    _print HandleSavedBlock kdata:$han
    	    var han [value fetch kdata:$han.HSB_next]
    	}
    }
}]

