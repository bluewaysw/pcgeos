##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	grab.tcl
# FILE: 	grab.tcl
# AUTHOR: 	Gene Anderson, May 28, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	focus	    	    	print focus hierarchy
#   	target	    	    	print target hierarchy
#   	model	    	    	print model hierarchy
#   	fullscreen    	    	print full screen hierarchy
#   	mouse	    	    	print mouse grab hierarchy
#   	keyboard    	    	print keyboard grab hierarchy
#
#   	focusobj    	    	return object with focus
#   	targetobj   	    	return object with target
#   	modelobj    	    	return object with model
#   	fullscreenobj  	    	return object with full screen
#   	mouseobj    	    	return object with mouse grab
#   	keyboardobj 	    	return object with keyboard grab
#
#   	is-obj-in-class	    	see if an object is in the specified class
#   	psup	    	    	print superclasses
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
# DESCRIPTION:
#	TCL commands for printing various grab hierarchies
#
#	$Id: grab.tcl,v 1.22.11.1 97/03/29 11:27:23 canavese Exp $
#
###############################################################################

[defsubr addr-with-system-obj {obj}
{
    if {[null $obj]} {
    	return [systemobj]
    } else {
    	return $obj
    }
}]

[defsubr addr-with-flow-obj {obj}
{
    if {[null $obj]} {
    	return [flowobj]
    } else {
    	return $obj
    }
}]

##############################################################################
#				focus
##############################################################################
#
# SYNOPSIS:	print the focus hierarchy
# PASS:		obj - object to print hierarchy under
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand focus {{obj {}}} {top.object object.hierarchies}
{Usage:
    focus [<object>]

Examples:
    "focus" 	    	print focus hierarchy from the system object down
    "focus -i"	    	print focus hierarchy from implied grab down
    "focus ^l4e10h:20h"	print focus hierarchy from ^l4e10h:20h down
    "focus [content]"	print focus hierarchy from content under mouse

Synopsis:
    Prints the focus hierarchy below an object.

Notes:
    * If no argument is specified, the system object is used.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

    * Remember that the object you start from may have the focus
      within its part of the hierarchy, but still not have the focus
      because something in a different part of the tree has it.

    * The variable "printNamesInObjTrees" can be used to print out the actual
      app-defined labels for the objects, instead of the class, where available.
      This variable defaults to false.

See also:
    target, model, mouse, keyboard
}
{
    require addr-with-obj-flag user

    var obj [addr-with-obj-flag [addr-with-system-obj $obj]]
    global focusclasslists
    grab $focusclasslists $obj
}]

##############################################################################
#				target
##############################################################################
#
# SYNOPSIS:	print the target hierarchy
# PASS:		obj - object to print hierarchy under
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand target {{obj {}}} {top.object object.hierarchies}
{Usage:
    target [<object>]

Examples:
    "target"		print target hierarchy from the system object down
    "target -i"		print target hierarchy from implied grab down
    "target -c"		print target hierarchy from content under mouse
    "target ^l4e10h:20h" print target hierarchy from ^l4e10h:20h down

Synopsis:
    Prints the target hierarchy below an object.

Notes:
    * If no argument is specified, the system object is used.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

    * Remember that the object you start from may have the target
      within its part of the hierarchy, but still not have the target
      because something in a different part of the tree has it.

    * The variable "printNamesInObjTrees" can be used to print out the actual
      app-defined labels for the objects, instead of the class, where available.
      This variable defaults to false.

See also:
    focus, model, mouse, keyboard
}
{
    require addr-with-obj-flag user

    var obj [addr-with-obj-flag [addr-with-system-obj $obj]]
    global targetclasslists
    grab $targetclasslists $obj
}]

##############################################################################
#				model
##############################################################################
#
# SYNOPSIS:	print the model hierarchy
# PASS:		obj - object to print hierarchy under
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand model {{obj {}}} object.hierarchies
{Usage:
    model [<object>]

Examples:
    "model" 	    	print model hierarchy from system object down
    "model -i"	    	print model hierarchy from implied grab down
    "model ^l4e10h:20h" print model hierarchy from ^l4e10h:20h down

Synopsis:
    Prints the model hierarchy below an object.

Notes:
    * If no object is specified, the system object is used.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

    * Remember that the object you start from may have the model exclusive
      within its part of the hierarchy, but still not have the exclusive
      because something in a different part of the tree has it.

    * The variable "printNamesInObjTrees" can be used to print out the actual
      app-defined labels for the objects, instead of the class, where available.
      This variable defaults to false.

See also:
    target, focus, mouse, keyboard
}
{
    require addr-with-obj-flag user

    var obj [addr-with-obj-flag [addr-with-system-obj $obj]]
    global modelclasslists
    grab $modelclasslists $obj
}]

##############################################################################
#				full screen
##############################################################################
#
# SYNOPSIS:	print the full screen hierarchy
# PASS:		obj - object to print hierarchy under
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	4/93		Initial Revision
#
##############################################################################

[defcommand fullscreen {{obj {}}} object.hierarchies
{Usage:
    fullscreen [<object>]

Examples:
    "fullscreen" 	print full screen  hierarchy from system object down
    "fullscreen ^l4e10h:20h" print full screen  hierarchy from ^l4e10h:20h down

Synopsis:
    Prints the full screen below an object.

Notes:
    * If no object is specified, the system object is used.

    * Remember that the object you start from may have the full screen exclusive
      within its part of the hierarchy, but still not have the exclusive
      because something in a different part of the tree has it.

    * The variable "printNamesInObjTrees" can be used to print out the actual
      app-defined labels for the objects, instead of the class, where available.
      This variable defaults to false.

See also:
    target, focus, model, mouse, keyboard
}
{
    var obj [addr-with-system-obj $obj]
    global fullscreenclasslists
    grab $fullscreenclasslists $obj
}]

##############################################################################
#				mouse
##############################################################################
#
# SYNOPSIS:	print the mouse hierarchy
# PASS:		obj - object to print hierarchy under
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand mouse {{obj {}}} object.hierarchies
{Usage:
    mouse [<object>]

Examples:
    "mouse" 	    	print mouse hierarchy from flow object down
    "mouse ^l4e10h:20h" print mouse hierarchy from ^l4e10h:20h down

Synopsis:
    Prints the mouse hierarchy below an object.

Notes:
    * The mouse button must be down, otherwise the hierarchy stops at the
      flow object.

    * If no object is specified, the flow object is used.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

    * The variable "printNamesInObjTrees" can be used to print out the actual
      app-defined labels for the objects, instead of the class, where available.
      This variable defaults to false.

See also:
    focus, target, model, keyboard
}
{
    require addr-with-obj-flag user

    var obj [addr-with-obj-flag [addr-with-flow-obj $obj]]
    global mouseclasslists
    grab $mouseclasslists $obj
}]

##############################################################################
#				keyboard
##############################################################################
#
# SYNOPSIS:	print the keyboard grab hierarchy
# PASS:		obj - object to print hierarchy under
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand keyboard {{obj {}}} object.hierarchies
{Usage:
    keyboard [<object>]

Examples:
    "keyboard" 	    	    print keyboard hierarchy from flow object down
    "keyboard ^l4e10h:20h"  print keyboard hierarchy from ^l4e10h:20h down

Synopsis:
    Prints the keyboard grab hierarchy below an object.

Notes:
    * If no object is specified, the flow object is used.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

    * The variable "printNamesInObjTrees" can be used to print out the actual
      app-defined labels for the objects, instead of the class, where available.
      This variable defaults to false.

See also:
    focus, target, model, mouse
}
{
    require addr-with-obj-flag user

    var obj [addr-with-obj-flag [addr-with-flow-obj $obj]]
    global keyboardclasslists
    grab $keyboardclasslists $obj
}]

##############################################################################
#				grab
##############################################################################
#
# SYNOPSIS:	print a hierarchy (focus, target, model)
# PASS:		obj - object to print hierarchy under
#   	    	htable - table of hierarchy links (focus, target, model)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defsubr grab {{htable} {obj}}
{
    require addr-with-obj-flag user.tcl
    require getobjclass objtree.tcl
    require default-patient user.tcl
    #
    # The variable "printNamesInObjTrees" can be used to print out the actual
    # app-defined labels for the objects, instead of the class, where available.
    #
    global printNamesInObjTrees
    #
    # Parse the the address of the object
    #
    var obj [addr-with-obj-flag $obj]
    #
    # Keep going until we reach a leaf.  A leaf is defined as an
    # object that we don't recognize as an internal node
    #
    var indent 0
    var node 1
    echo {}
    
    while {$node} {
    	#
    	# Pretty-print the object
    	#
    	var addr [addr-parse ($obj)]
        var seg [handle segment [index $addr 0]]
    	var off [index $addr 1]
        var bl [handle id [index $addr 0]]
        var ch [index [get-chunk-addr-from-obj-addr $obj] 1]
    	var objclass [getobjclass ($obj)]
    	var label [value hstore $addr]
    	#
    	# If the user wants, print the object name instead of its class
    	#
    	var objtitle $objclass
    	if {![null $printNamesInObjTrees] && $printNamesInObjTrees != 0} {
    	    #
	    # Find a name for it, if we can.
    	    #
	    var namesym [symbol faddr var ^h$bl:$ch]
	    if {![null $namesym]} { 
	    	var namepos [symbol addr $namesym]
	    	if {[index [addr-parse $namepos 0] 1] == 
		    [index [addr-parse $ch 0] 1]} {
		    	var objtitle [symbol name $namesym]
	    	}
	    }
    	}
    	echo -n [format {%*s} $indent {}]
    	echo -n [format {%s (@%d, ^l%04xh:%04xh) } $objtitle $label $bl $ch]
    	#
    	# Print out the moniker, if any
    	#
    	if {[is-obj-in-class $obj GenClass]} {
            var masteroff [value fetch $seg:$off.ui::Gen_offset]
    	    var master [expr $off+$masteroff]
    	    if {$masteroff == 0} {
    	        echo { -- not yet built}
    	    } else {
    	        #
    	        # If the handle is resident, get the visMoniker, if any
    	        #
	        if {[handle state [handle lookup $bl]] & 1} {
	            var off [value fetch ^h$bl:$master.ui::GI_visMoniker word]
	    	    if {$off != 0} then {
		        pvismon *$seg:$off 1
	    	    } else {
		        echo
	    	    }
    	    	} else {
    	    	    echo {*** Non-resident ***}
    	    	}
    	    }
    	} else {
    	    echo
    	}
    	#
    	# Get the instance variable for the hierarchy we're following
    	#
    	var pfo [obj-foreach-class _find-node-obj $obj $htable]
    	if {[null $pfo]} {
    	    var node 0
    	} else {
    	    #
    	    # Fetch the OD to follow, if any
    	    #
	    var r [_fetch-node-obj $pfo $obj]
	    var bl [index $r 0] ch [index $r 1]
    	    #
    	    # If the OD isn't NULL, follow it
    	    #
    	    if {$bl != 0} {
    	        var obj ^l$bl:$ch
    	        var indent [expr $indent+2]
    	    } else {
    	        var node 0
    	    }
    	}
    }
}]

##############################################################################
#				_find-node-obj
##############################################################################
#
# SYNOPSIS:	Search up the class hierarchy until we find a class we know
# PASS:		class	= symbol token for the class being checked
#   	    	obj 	= address of the object in question
#   	    	htable	= hierarchy table to check
# CALLED BY:	grab
# RETURN:	the {master_offset instData patient} for object
#   	    	else {}
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defsubr _find-node-obj {class obj htable}
{
    var i $htable
    for {} {![null $i]} {var i [cdr $i]} {
    	if {![string compare [symbol name $class] [index [index $i 0] 0]]} {
    	    return [concat [index [index $i 0] 1]
	    	         [obj-name [symbol fullname $class] Instance]]
    	}
    }
    return {}
}]

#
# List of lists of classes we know about.  Format of each entry is:
#   {class  {master_offset  instData patient}}
# where:
#   class - class to match
#   master_offset - offset of the master class that contains the data we want
#   instData - name of instance data with hierarchy
#   patient - name of patient that instance data is defined in
#
defvar focusclasslists {
    {OLWinClass 
    	{Vis_offset OLWI_focusExcl.FTVMC_OD [get-spec-ui]}}
    {OLDisplayGroupClass 
    	{Vis_offset OLDGI_focusExcl.FTVMC_OD [get-spec-ui]}}
    {VisContentClass 
    	{Vis_offset VCNI_focusExcl.FTVMC_OD ui}}
    {OLPaneClass 
    	{Vis_offset OLPI_targetInfo.VTI_content.TR_object [get-spec-ui]}}
    {OLSystemClass 
    	{Vis_offset OLSYI_focusExcl.HG_OD [get-spec-ui]}}
    {OLFieldClass 
    	{Vis_offset OLFI_focusExcl.FTVMC_OD [get-spec-ui]}}
    {OLSettingCtrlClass 
    	{Vis_offset OLSCI_focusExcl [get-spec-ui]}}
    {FlatFileDatabaseClass 
    	{ssheet::Spreadsheet_offset FFI_focusExcl.HG_OD {ffile::struct _FlatFileDatabaseInstance}}}
    {GrObjBodyClass 
    	{Vis_offset GBI_focusExcl grobj}}
    {GrObjVisGuardianClass 
    	{Vis_offset GOVGI_ward grobj}}
}

defvar targetclasslists {
    {OLWinClass 
    	{Vis_offset OLWI_targetExcl.FTVMC_OD [get-spec-ui]}}
    {OLDisplayGroupClass 
    	{Vis_offset OLDGI_targetExcl.FTVMC_OD [get-spec-ui]}}
    {VisContentClass 
    	{Vis_offset VCNI_targetExcl.FTVMC_OD ui}}
    {OLPaneClass 
    	{Vis_offset OLPI_targetInfo.VTI_content.TR_object [get-spec-ui]}}
    {OLSystemClass 
    	{Vis_offset OLSYI_targetExcl.HG_OD [get-spec-ui]}}
    {OLFieldClass 
    	{Vis_offset OLFI_targetExcl.FTVMC_OD [get-spec-ui]}}
    {FlatFileDatabaseClass 
    	{ssheet::Spreadsheet_offset FFI_targetExcl.HG_OD {ffile::struct _FlatFileDatabaseInstance}}}
    {GrObjBodyClass 
    	{Vis_offset GBI_targetExcl grobj}}
    {GrObjVisGuardianClass 
    	{Vis_offset GOVGI_ward grobj}}
}

defvar modelclasslists {
    {OLSystemClass 
    	{Vis_offset OLSYI_modelExcl.HG_OD [get-spec-ui]}}
    {OLApplicationClass 
    	{Vis_offset OLAI_modelExcl.FTVMC_OD [get-spec-ui]}}
    {OLDocumentGroupClass 
    	{Vis_offset OLDGI_modelExcl.HG_OD [get-spec-ui]}}
    {GenDocumentControlClass 
    	{Gen_offset GDCI_documentGroup ui}}
}

defvar fullscreenclasslists {
    {OLSystemClass 
    	{Vis_offset OLSYI_fullScreenExcl.HG_OD [get-spec-ui]}}
    {OLFieldClass 
    	{Vis_offset OLFI_fullScreenExcl.FTVMC_OD [get-spec-ui]}}
}

defvar mouseclasslists {
    {FlowClass 
    	{{} FI_activeMouseGrab.GG_OD ui}}
    {VisContentClass 
    	{Vis_offset VCNI_activeMouseGrab.VMG_object ui}}
    {OLPaneClass 
    	{Vis_offset OLPI_targetInfo.VTI_content.TR_object [get-spec-ui]}}
}

defvar keyboardclasslists {
    {FlowClass 
    	{{} FI_activeKbdGrab.KG_OD ui}}
    {VisContentClass 
    	{Vis_offset VCNI_kbdGrab.KG_OD ui}}
    {OLPaneClass 
    	{Vis_offset OLPI_targetInfo.VTI_content.TR_object [get-spec-ui]}}
}

##############################################################################
#				is-obj-in-class
##############################################################################
#
# SYNOPSIS:	Check to see if an object is in the
# PASS:		obj - object to check
#   	    	class - class to check
# RETURN:	TRUE if object is in class
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/29/92		Initial Revision
#
##############################################################################

[defcommand is-obj-in-class {{obj {}} class} swat_prog.object
{Usage:
    is-obj-in-class <object> <class>

Examples:
    "is-obj-in-class ^l4e10h:1eh GenPrimaryClass" see if ^l4e10h:1eh is in
    	    	    	    	    	    	    	GenPrimaryClass

Synopsis:
    Returns whether a given object in in the specified class

Notes:
    * Returns 1 if the object is in the specified class, 0 otherwise.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

See also:
    psup
}
{
    require addr-with-obj-flag user

    var obj [addr-with-obj-flag $obj]
    
    var a [obj-foreach-class _check-class $obj $class]
    if {![null $a]} {
    	return $a
    } else {
    	return 0
    }
}]

##############################################################################
#				_check-class
##############################################################################
#
# SYNOPSIS:	Search up the class hierarchy until we find a class we want
# PASS:		class	= symbol token for the class being checked
#   	    	obj 	= address of the object in question
#   	    	cclass	= class to check
# CALLED BY:	focus
# RETURN:	1 if object is in cclass
#   	    	else {}
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defsubr _check-class {class obj cclass}
{
    if {![string compare [symbol name $class] $cclass]} {
    	return 1
    }
    return {}
}]

##############################################################################
#				psup
##############################################################################
#
# SYNOPSIS:	Print superclasses for an object
# PASS:		obj - object to check
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/29/92		Initial Revision
#
##############################################################################

[defcommand psup {{obj {*ds:si}}} object.print
{Usage:
    psup [<object>]

Examples:
    "psup"  	    	print superclasses of object at *ds:si
    "psup -i"	    	print superclasses of object under mouse
    "psup ^l4e10h:1eh"	print superclasses of object at ^l4e10h:1eh

Synopsis:
    Print superclasses of an object

Notes:
    * If no object is specified, *ds:si is used.

See also:
    is-obj-in-class
}
{
    require addr-with-obj-flag user
    var obj [addr-with-obj-flag $obj]
    obj-foreach-class _print-class $obj
}]


##############################################################################
#				_print-class
##############################################################################
#
# SYNOPSIS:	Search up the class hierarchy until we find a class we know
# PASS:		class	= symbol token for the class being checked
#   	    	obj 	= address of the object in question
# CALLED BY:	focus
# RETURN:	TRUE if object is in cclass
#   	    	else {}
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defsubr _print-class {class obj}
{
    echo [symbol name $class]
    return {}
}]


##############################################################################
#				focusobj
##############################################################################
#
# SYNOPSIS:	return the object with the focus
# PASS:		none
# RETURN:	obj - object with focus
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand focusobj {} object.address
{Usage:
    focusobj

Examples:
    "focusobj" 	    	return object with focus
    "pobj [focusobj]"   do a pobj on the focus object
			(equivalent to "pobj -f")

Synopsis:
    Returns the object with the focus

Notes:

See also:
    focus, target, model, targetobj, modelobj
}
{
    global focusclasslists
    return [objwithgrab $focusclasslists [systemobj]]
}]

##############################################################################
#				targetobj
##############################################################################
#
# SYNOPSIS:	return the object with the target
# PASS:		none
# RETURN:	obj - object with target
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand targetobj {} object.address
{Usage:
    focusobj

Examples:
    "targetobj" 	return object with target
    "pobj [targetobj]"	do a pobj on the target object
			(equivalent to "pobj -t")

Synopsis:
    Returns the object with the target

Notes:

See also:
    focus, target, model, focusobj, modelobj
}
{
    global targetclasslists
    return [objwithgrab $targetclasslists [systemobj]]
}]

##############################################################################
#				modelobj
##############################################################################
#
# SYNOPSIS:	return the object with the model
# PASS:		none
# RETURN:	obj - object with model
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand modelobj {} object.address
{Usage:
    focusobj

Examples:
    "modelobj" 	    	return object with model grab
    "pobj [targetobj]"	do a pobj on the object with the model grab
			(equivalent to "pobj -t")

Synopsis:
    Returns the object with the model grab

Notes:

See also:
    focus, target, model, focusobj, targetobj
}
{
    global modelclasslists
    return [objwithgrab $modelclasslists [systemobj]]
}]

##############################################################################
#				fullscreenobj
##############################################################################
#
# SYNOPSIS:	return the object with the full screen excsluive
# PASS:		none
# RETURN:	obj - object with full screen exlusive
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	4/93		Initial Revision
#
##############################################################################

[defcommand fullscreenobj {} object.address
{Usage:
    fullscreenobj

Examples:
    "fullscreenobj"    	return object with full screen grab
    "pobj [fullscreenobj]" do a pobj on the object with the full screen grab

Synopsis:
    Returns the object with the full screen grab

Notes:

See also:
    fullscreen
}
{
    global fullscreenclasslists
    return [objwithgrab $fullscreenclasslists [systemobj]]
}]

##############################################################################
#				mouseobj
##############################################################################
#
# SYNOPSIS:	return the object with the mouse grab
# PASS:		none
# RETURN:	obj - object with mouse grab
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand mouseobj {} object.address
{Usage:
    mouseobj

Examples:
    "mouseobj" 	    	return object with mouse grab
    "pobj [mouseobj]"	do a pobj on the object with the mouse grab
			(equivalent to "pobj -mg")

Synopsis:
    Returns the object with the mouse grab

Notes:
    * The mouse button must be down, otherwise the hierarchy stops at the
    flow object.

See also:
    mouse, keyboard, focus, target, keyboardobj
}
{
    global mouseclasslists
    return [objwithgrab $mouseclasslists [flowobj]]
}]

##############################################################################
#				keyboardobj
##############################################################################
#
# SYNOPSIS:	return the object with the keyboard grab
# PASS:		none
# RETURN:	obj - object with keyboard grab
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	5/28/92		Initial Revision
#
##############################################################################

[defcommand keyboardobj {} object.address
{Usage:
    keyboardobj

Examples:
    "keyboardobj" 	    return object with keyboard grab
    "pobj [keyboardobj]"    do a pobj on the object with the keyboard grab
			    (equivalent to "pobj -kg")

Synopsis:
    Returns the object with the keyboard grab

Notes:

See also:
    keyboard, mouse, focus, target, mouseobj
}
{
    global keyboardclasslists
    return [objwithgrab $keyboardclasslists [flowobj]]
}]
##############################################################################
#	_fetch-node-obj
##############################################################################
#
# SYNOPSIS:	
# PASS:		pfo - list (master offset, instance offset, patient)
#   	    	obj - object    	
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       gene 	3/ 5/93   	Initial Revision
#
##############################################################################
[defsubr _fetch-node-obj {pfo obj}
{
    var pat [index $pfo 2]
    var inst [range $pfo 3 end]
    var iv [index $pfo 1]
    if {![null [index $pfo 0]]} {
	var master [default-patient ui [index $pfo 0]]
	var addr [concat (($obj)+[value fetch ($obj).${master}]).$pat::${iv}]
    } else {
	var addr [concat ($obj).$pat::${iv}]
    }
    return [list [value fetch $addr.handle]
		 [value fetch $addr.offset]]
}]
##############################################################################
#				objwithgrab
##############################################################################
#
# SYNOPSIS: 	Return object under hierarchal grab (focus, target, etc.)
# PASS:		htable - table of hierarchy links
#   	    	startobj - object to start from ([systemobj], usually)
# CALLED BY:	targetobj, focusobj
# RETURN:	object - address of object with grab
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	8/12/92		Initial Revision
#
##############################################################################

[defsubr objwithgrab {{htable} {obj}}
{
    require default-patient user.tcl
    #
    # Keep going until we reach a leaf.  A leaf is defined as an
    # object that we don't recognize as an internal node
    #
    var node 1
    while {$node} {
    	#
    	# Get the address of the object
    	#
    	var addr [addr-parse ($obj)]
        var seg [handle segment [index $addr 0]]
    	var off [index $addr 1]
        var bl [handle id [index $addr 0]]
        var ch [index [get-chunk-addr-from-obj-addr $obj] 1]
    	var label [value hstore $addr]
    	#
    	# Get the instance variable for the hierarchy we're following
    	#
    	var pfo [obj-foreach-class _find-node-obj $obj $htable]
    	if {[null $pfo]} {
    	    var node 0
    	} else {
    	    #
    	    # Fetch the OD to follow, if any
    	    #
    	    var r [_fetch-node-obj $pfo $obj]
	    var bl [index $r 0] ch [index $r 1]
    	    #
    	    # If the OD isn't NULL, follow it
    	    #
    	    if {$bl != 0} {
    	        var obj ^l$bl:$ch
    	    } else {
    	        var node 0
    	    }
    	}
    }
    return $obj
}]

##############################################################################
#				get-spec-ui
##############################################################################
#
# SYNOPSIS:	Return the name of the specific UI in use
# PASS:		none
# CALLED BY:	UTILITY
# RETURN:	name of specific UI
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	8/17/92		Initial Revision
#
##############################################################################

[defsubr get-spec-ui {}
{
    global specific-ui

    if {[null [sym find var ui::uiSpecUILibrary]]} {
    	if {[null ${specific-ui}]} {
    	    error {unable to determine specific ui}
    	} else {
    	    #eliminate extra stuff in name
    	    var	pname [range ${specific-ui} 0 7 chars]
    	    return $pname
       	}
    } else {
    	var specUIHan [value fetch ui::uiSpecUILibrary]
        return [patient name [handle patient [handle lookup $specUIHan]]]
    }
}]
