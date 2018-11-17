##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	class.tcl
# AUTHOR: 	Doug Fults , Jun 26, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	classes	    	    	List patient classes
#	methods			List methods of a class
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	6/26/93		Initial Revision
#
# DESCRIPTION:
#	Commands/routines for looking at object classes
#
#	$Id: class.tcl,v 1.5.4.1 97/03/29 11:26:49 canavese Exp $
#
###############################################################################

[defcommand classes {{pat {}}} {top.object patient}
{Usage:
    classes [<patient>]

Examples:
    "classes"			Print list of classes in current patient
    "classes myapp"		Print list of classes in myapp

Synopsis:
    Prints list of classes defined by the given patient.  Useful
    as a starting place, along with "gentree -a" & "vistree -c", to get
    your bearings as to what's in an application.

Notes:
    * Remember that "brk" will take address arguments of the form
      <class>::<message>, so you use this function, & then set a brkpnt using
      "brk MyTextClass::MSG_MY_TEXT_MESSAGE".   If you need a breakpoint
      that's limited to one object, use objbrk instead.

See also:
    gentree, methods, objbrk, brk, cup
}
{
	global clist
	var clist {}

	if {![null $pat]} {
		var pat $pat::
	}
	var csp [symbol find scope [format {%sdgroup} $pat]]
	symbol foreach $csp var ct-cb $pat
	echo $list
}]


[defsubr ct-cb {sym pat}
{
    global clist

   # We could haved used "isclassptr" here, but this is a bit faster...
   var typename [type name [index [symbol get $sym] 2] {} 0]
   if {[string match $typename *ClassStruct*]} {
	var name [symbol name $sym]
	var addr [addr-parse [sym fullname $sym]]
	var label [value hstore $addr]
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
    	echo -n [format {%s (@%d, %04xh:%04xh)} $name $label $seg $off]
	var super [format {%s%s.Class_superClass} $pat $name]
	var seg [value fetch $super.segment [type word]]
	var off [value fetch $super.offset [type word]]
	if {$off} {
		var ssym [symbol faddr var $seg:$off]
		var sname [symbol fullname $ssym]
		echo , off $sname
	}
    }
    return 0
}]

[defcommand methods {{class {}} {meth {}}} {top.object}
{Usage:
    methods <class>
    methods <object>
    methods <special object flags>

Examples:
    "methods -p"			Print out methods defined for process
    "methods ui::GenDocumentClass"	Print out GenDocumentClass methods
    "methods 3ffch:072fh"		Print out methods for class at addr
    "methods -a"			Print methods of top class of app obj

Synopsis:
    Prints out the method table for the class specified, or if an object is
    passed, for the overall class of the object.  Useful for getting a list of
    candidate locations to breakpoint.

Notes:
    * The special object flags, which are interpreted by this command to
      mean the class of the specified object:

    	Value	Prints methods of...
	-----	-----------------------------------------------------------
    	-a  	the current patient's application object class
	-p	the current patient's process class
    	-i  	the current "implied grab" object class
    	-f  	the leaf of the keyboard-focus hierarchy's class
	-t  	the leaf of the target hierarchy's class
	-m  	the leaf of the model hierarchy's class
	-c  	the content for the view over which the mouse is currently
		located's class
    	-kg  	the leaf of the keyboard-grab hierarchy's class
	-mg 	the leaf of the mouse-grab hierarchy's class

See also:
    cup, classes, objbrk, brk
}
{
	var addr [class-addr-with-obj-flag $class]
	var sym [symbol faddr var $addr]
	var name [symbol fullname $sym]
	print-method-table $name $meth
}]


[defcommand cup {{class {}}} {top.object}
{Usage:
    cup <class>
    cup <object>
    cup <special object flags>

Examples:
    "cup ui::GenDocumentControlClass"	Print class hierarchy of named class
    "cup ^l2850h:0034h"			Print class hierarchy of object
    "cup -f"				Print class hierarchy of focus object
    "cup -p"				Print class hierarchy of process

Synopsis:
    Walks up the class hierarchy, starting at a given class, printing each
    class encountered.  May be passed an object, in which case the class of
    the object will be used as a starting place.

Notes:
    * The special object flags, which are interpreted by this command to
      mean the class of the specified object:

    	Value	Prints class hierarchy for...
	-----	-----------------------------------------------------------
    	-a  	the current patient's application object class
	-p	the current patient's process class
    	-i  	the current "implied grab" object class
    	-f  	the leaf of the keyboard-focus hierarchy's class
	-t  	the leaf of the target hierarchy's class
	-m  	the leaf of the model hierarchy's class
	-c  	the content for the view over which the mouse is currently
		located's class
    	-kg  	the leaf of the keyboard-grab hierarchy's class
	-mg 	the leaf of the mouse-grab hierarchy's class

    * As this command operates on object classes, & not objects (though they
      may be used to indicate a class), it will stop at any variant master
      class, for the superclass is defined by individual objects, & not
      the class itself.

See also:
    classes, methods, objbrk, brk
}
{
	var addr [addr-parse [class-addr-with-obj-flag $class]]
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
	while {($seg!=0)&&($seg!=1)} {
		var sym [symbol faddr var $seg:$off]
		var name [symbol fullname $sym]
		var label [value hstore [addr-parse $seg:$off]]
		echo [format {%s (@%d, %04xh:%04xh)}
			$name
			$label
			$seg
			$off]
		var nseg [value fetch $seg:$off.segment [type word]]
		var off [value fetch $seg:$off.offset [type word]]
		var seg $nseg
	}
}]



[defcommand class-addr-with-obj-flag {address} swat_prog.object
{Usage:
    class-addr-with-obj-flag <address>

Examples:
    "var addr [class-addr-with-obj-flag $addr]" If $addr is "-i", returns
                                                the address of the class of
						the current implied grab.

Synopsis:
    This is a utility routine that can be used by any command that operates
    on object classes.  It is basically a level layer above
    addr-with-obj-flag <address>, to either accept direct class addresses,
    or object references, in which case the class of the object is returned.
    See addr-with-obj-flag for all the special flags that may be passed
    (-a, -p, -i, etc.)

    * If <address> is empty, this will return the class of the local
      variable "oself" within the current frame, if it has one, or *ds:si

See also:
    addr-with-obj-flag
}
{
	require addr-with-obj-flag user
	var addr [addr-with-obj-flag $address]
	if {[isclassptr $addr]} {
		# Is class.  Just return it
		return $addr
	} else {
		# It's an object of some type.  Figure out which
		var ow_object [get-chunk-addr-from-obj-addr $addr]
		var h [index $ow_object 0]
		if {[handle isthread $h]} {
			#
			# Thread
			#
			var ss [value fetch kdata:[handle id $h].HT_saveSS [type word]]
			var ptr $ss:TPD_classPointer
			var nseg [value fetch ($ptr).segment [type word]]
			var off [value fetch ($ptr).offset [type word]]
			var seg $nseg
			return $seg:$off

		} elif {([handle state $h]&0xf8000) == 0x40000} {
			#
			# Event queue
			#
			error {Sorry, not yet implemented for event queues}

		} else {
			#
			# LMem object
			#
			var nseg [value fetch ($addr).segment [type word]]
			var off [value fetch ($addr).offset [type word]]
			var seg $nseg
			return $seg:$off
		}
	}
}]
