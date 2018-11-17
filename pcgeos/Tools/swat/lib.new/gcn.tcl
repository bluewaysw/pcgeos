##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	gcn.tcl
# FILE: 	gcn.tcl
# AUTHOR: 	Adam de Boor, May 26, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/26/92		Initial Revision
#
# DESCRIPTION:
#	Functions for examining GCN lists.
#
#	$Id: gcn.tcl,v 1.11.11.1 97/03/29 11:26:39 canavese Exp $
#
###############################################################################

##############################################################################
#				pobjgcnlist
##############################################################################
#
# SYNOPSIS:	Print the contents of an object's specified GCN list
# PASS:		list	= token for the list
#   	    	[manuf]	= manufacturer's ID for the list
#   	    	[lol]	= address of the list-of-lists in which to search
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/26/92		Initial Revision
#
##############################################################################
[defcommand pobjgcnlist {list {address *ds:si} {manuf MANUFACTURER_ID_GEOWORKS}} {object.gcnlist}
{
Usage:
    pobjgcnlist <list> [<address> [<manuf>]]

Examples:
    "pobjgcnlist GCNSLT_EXPRESS_MENU_CHANGE"	Print out all objects on the
					list via which changes to express menus
					changes are broadcast.

    "pobjgcnlist GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_CHANGE *Desktop"
					Print out all objects on GeoManager's
					GenApplication object's display control
					list.

Synopsis:
    Prints out the list of objects registered for an object's GCN list, as well
    as any status message stored for that list.

Notes:
    * <address> defaults to *ds:si.

See also:
    pcarray, pgcnlist
}
{
    require fvardata pvardata

    var listOfLists [fvardata TEMP_META_GCN $address]
    if [null $listOfLists] {
	echo {Object has no GCN lists.}
    } else {
	pgcnlist $list ^l[handle id [index [addr-parse $address] 0]]:[field [index $listOfLists 1] TMGCND_listOfLists] $manuf
    }
}]

##############################################################################
#				pgcnlist
##############################################################################
#
# SYNOPSIS:	Print the contents of a specified GCN list
# PASS:		list	= token for the list
#   	    	[manuf]	= manufacturer's ID for the list
#   	    	[lol]	= address of the list-of-lists in which to search
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/26/92		Initial Revision
#
##############################################################################
[defcommand pgcnlist {list {lol {}} {manuf MANUFACTURER_ID_GEOWORKS}} {object.gcnlist system.gcnlist}
{
Usage:
    pgcnlist <list> [<list-of-lists> [<manuf>]]

Examples:
    "pgcnlist GCNSLT_EXPRESS_MENU_CHANGE"	Print out all objects on the
					list via which changes to express menus
					changes are broadcast.

Synopsis:
    Prints out the list of objects registered for a GCN list, as well as
    any status message stored for that list.

Notes:
    * If all you give is <list>, you will get the contents of the GeoWorks-
      defined list in the system list block.

    * If you've defined your own lists within the system list block (i.e.
      the manufacturer ID you specified to GCNListAdd was not
      MANUFACTURER_ID_GEOWORKS), you can give <list-of-lists> as {} and give
      <manuf> as the appropriate manufacturer's ID and "pgcnlist" will look
      for the list within the block containing the system GCN lists.

See also:
    pcarray
}
{
    var id [getvalue $list]
    var mid [getvalue $manuf]
    
    if {[null $lol]} {
    	var lol *geos::GCNListBlock:GCNLBH_listOfLists
    }

    require carray-enum chunkarr

    var found [carray-enum $lol pgcnlist-find-list-callback [list $mid $id l]]
    if {!$found} {
    	error [format {%s:%s doesn't exist} $manuf $list]
    }
    var hid [handle id [index [addr-parse $lol] 0]]
    
    pgcnlist-internal $hid $l
}]

##############################################################################
#				pgcnlist-find-list-callback
##############################################################################
#
# SYNOPSIS:	Callback function to locate a particular GCN list
# PASS:		elNum	= number of the element being processed
#   	    	elAddr	= address expression for the base of the element
#   	    	elSize	= size of the element
#   	    	extra	= 3-list passed by pgcnlist:
#   	    	    	    {<manuf> <type> <varname>}
#   	    	    	    	manuf	= numeric manufacturer's ID
#   	    	    	    	type	= numeric list type
#   	    	    	    	varname	= name of variable to set to the
#					  list chunk if this element describes
#					  the sought-after list
# CALLED BY:	pgcnlist via carray-enum
# RETURN:	1 if list found, 0 if should keep enumerating
# SIDE EFFECTS:	$varname in pgcnlist will be set to a number (the chunk of
#		the gcn list within the same block as the list-of-lists
#		being enumerated) if the element is the one being sought.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/26/92		Initial Revision
#
##############################################################################
[defsubr pgcnlist-find-list-callback {elNum elAddr elSize extra}
{
    [if {[expr [value fetch $elAddr.GCNLOLE_ID.GCNLT_manuf]&0xfffe] == [expr [index $extra 0]&0xfffe] &&
    	 [expr [value fetch $elAddr.GCNLOLE_ID.GCNLT_type]&0xfffe] == [expr [index $extra 1]&0xfffe]}
    {
    	uplevel 1 [list var [index $extra 2] [value fetch $elAddr.GCNLOLE_list]]
	return 1
    }]
    return 0
}]

##############################################################################
#				pgcnlist-internal
##############################################################################
#
# SYNOPSIS:	Internal routine to print a gcnlist given its handle and chunk
# PASS:		hid 	= handle id of block containing the list
#   	    	l   	= chunk handle of chunk array that is the list
# CALLED BY:	pgcnlist, pgcnblock
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/27/92		Initial Revision
#
##############################################################################
[defsubr pgcnlist-internal {hid l}
{
    if {[value fetch (^h$hid):$l word] != 65535} {
	if {[value fetch (^l$hid:$l).GCNLH_statusEvent] != 0} {
	    echo -n {Status Event: }
	    pevent [value fetch (^l$hid:$l).GCNLH_statusEvent]
	    echo [format {Status Block: %04xh}
		    [value fetch (^l$hid:$l).GCNLH_statusData]]
	}
	require fmtoptr print
	carray-enum ^l$hid:$l pgcnlist-print-element
    } else {
	echo {Empty GCN list}
    }
}]

##############################################################################
#				pgcnlist-print-element
##############################################################################
#
# SYNOPSIS:	Print an element of a GCN list
# PASS:		elNum	= number of the element being processed
#   	    	elAddr	= address expression for the base of the element
#   	    	elSize	= size of the element
#   	    	extra	= ignored
# CALLED BY:	pgcnlist via carray-enum
# RETURN:	0 => keep enumerating
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/26/92		Initial Revision
#
##############################################################################
[defsubr pgcnlist-print-element {elNum elAddr elSize extra}
{
    echo -n [format {%2d: } $elNum]
    [fmtoptr [value fetch $elAddr.GCNLE_item.handle]
    	    [value fetch $elAddr.GCNLE_item.chunk]]
    echo
    return 0
}]

#
# List of lists telling us how to attempt to map a GCNLT_type to something
# readable. 
#
# Each sublist begins with a class to be sought within the object's
# class hierarchy. If that class is within the object's hierarchy, the rest
# of that sublist is made of lists of {<manuf> <type>+}, where <manuf> is the
# numeric manufacturer ID, and <type>+ is the name of the one or more data type
# within which to search for an enumerated constant whose value matches
# GCNLT_type.
#
# The special class "none" is used for lists-of-lists not associated with
# an object (e.g. the system one or some stand-alone block).
#
# Currently there is no "inheritance" of the types. You'll note, for example,
# that GenApplicationClass includes the thing for MetaClass.
#
defvar gcntypelists {
    {none
    	{0 GCNStandardListType}}
    {MetaClass
        {0 GeoWorksMetaGCNListType}}
    {GenApplicationClass
    	{0 GeoWorksGenAppGCNListType GeoWorksMetaGCNListType}}
    {VisContentClass
    	{0 GeoWorksVisContentGCNListType GeoWorksMetaGCNListType}}
    {PrefDialogClass
    	{0 GeoWorksPrefDialogGCNListType}}
    {MailboxApplicationClass
    	{0 MailboxGCNListType GeoWorksGenAppGCNListType GeoWorksMetaGCNListType}}
}

##############################################################################
#				pgcnblock
##############################################################################
#
# SYNOPSIS:	print out all the lists within a GCN block
# PASS:		[lol] 	= base of chunk array that is the list-of-lists
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/27/92		Initial Revision
#
##############################################################################

[defcommand pgcnblock {{lol {}}} {object.gcnlist system.gcnlist}
{Usage:
    pgcnblock [<list-of-lists> | <object>]

Examples:
    "pgcnblock"	    	    Prints out all the system-maintained GCN lists
    "pgcnblock *TaskApp"    Prints out the GCN lists maintained by the
			    TaskApp object.

Synopsis:
    "pgcnblock" prints out all the GCN lists either associated with an
    object, or defined for the system as a whole.

Notes:
    * If you give no argument, the lists defined for the system as a whole
      will be printed.

    * An object must have a TEMP_META_GCN vardata entry for this command to
      print out its GCN lists.
     
    * You can also give the address of a list-of-lists, as created by 
      GCNListCreateBlock, but the list types will be numeric, rather than
      mapped to an enumerated constant.

See also:
    pgcnlist, pvardata.
}
{
    if {[null $lol]} {
    	var hid [handle id [index [addr-parse geos::GCNListBlock:0] 0]]
	var l [value fetch ^h$hid:GCNLBH_listOfLists]
    } else {
    	var a [get-chunk-addr-from-obj-addr $lol]
    	var hid [handle id [index $a 0]] l [index $a 1]
    }
    
    #
    # Decide whether we've got an actual chunk array or an object.
    #
    if {[field [value fetch ^h$hid:LMBH_flags] LMF_HAS_FLAGS]} {
    	var b [expr ($l-[value fetch ^h$hid:LMBH_offset])/2]
	[if {[field [value fetch (^l$hid:[value fetch ^h$hid:LMBH_offset])+$b
	    	    [symbol find type geos::ObjChunkFlags]] OCF_IS_OBJECT]}
    	{
	    var typelist [obj-foreach-class pgcnblock-class-callback ^l$hid:$l]
	    var vdl [fvardata TEMP_META_GCN ^l$hid:$l]
	    if {[null $vdl]} {
	    	error [format {no GCN lists associated with ^l%04xh:%04xh}
		    	    $hid $l]
    	    }
	    var l [field [index $vdl 1] TMGCND_listOfLists]
    	}]
    }
    if {[null $typelist]} {
    	global gcntypelists
	
	var typelist [assoc $gcntypelists none]
    }
    var typelist [cdr $typelist]
    
    #
    # Now have everything set to go:
    #	^l$hid:$l   = chunk array holding GCNListOfListsElement structures
    #	$typelist   = assoc list of manufacturer IDs and data type names
    #	    	      for mapping list types to names
    #
    require carray-enum chunkarr

    carray-enum ^l$hid:$l pgcnblock-print-list [list $hid $typelist]
}]
    
##############################################################################
#				pgcnblock-print-list
##############################################################################
#
# SYNOPSIS:	Print out another list from the list-of-lists
# PASS:		elNum	= number of the element being processed
#   	    	elAddr	= address expression for the base of the element
#   	    	elSize	= size of the element
#   	    	extra	= 2-list: first element is handle ID within which all
#   	    	    	    	  these lists are located.
#				  second element is assoc list mapping
#				  manufacturer IDs to data type names
# CALLED BY:	pgcnblock via carray-enum
# RETURN:	0 (keep enumerating)
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/27/92		Initial Revision
#
##############################################################################
[defsubr pgcnblock-print-list {elNum elAddr elSize extra}
{
    var manuf [value fetch $elAddr.GCNLOLE_ID.GCNLT_manuf]
    var type [value fetch $elAddr.GCNLOLE_ID.GCNLT_type]
    var l [value fetch $elAddr.GCNLOLE_list]
    
    var hid [index $extra 0]
    var typelist [index $extra 1]
    var dtypename [assoc $typelist $manuf]
    if {![null $dtypename]} {
    	foreach tn [range $dtypename 1 end] {
    	    var t [symbol find type $tn]
	    if {![null $t]} {
	    	var tname [type emap [expr $type&~1] $t]
		if {![null $tname]} {
		    break
    	    	}
    	    }
    	}
    }
    
    if {[null $tname]} {
    	var tname $manuf:$type
    }
    echo [format {%s at ^l%04xh:%04xh} $tname $hid $l]
    pgcnlist-internal $hid $l
    
    echo

    return 0
}]

##############################################################################
#				pgcnblock-class-callback
##############################################################################
#
# SYNOPSIS:	Callback function to determine what list within gcntypelists
#   	    	is appropriate to this object, based on its class
# PASS:		class	= symbol token for the class being checked
#   	    	obj 	= address of the object in question
# CALLED BY:	pgcnblock via obj-foreach-class
# RETURN:	the appropriate type list, if the class is in gcntypelists
#   	    	else {}
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/27/92		Initial Revision
#
##############################################################################
[defsubr pgcnblock-class-callback {class obj}
{
    global gcntypelists
    
    return [assoc $gcntypelists [symbol name $class]]
}]
