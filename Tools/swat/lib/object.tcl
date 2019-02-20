##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	object.tcl
# FILE: 	object.tcl
# AUTHOR: 	Adam de Boor, Feb 12, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	obj-foreach-class    	Travel up the classes for an object
#   	print-obj-and-method	Print out the parameters for a method call
#   	get-chunk-addr-from-obj-addr	Figure the chunk for an object given
#   	    	    	    	    	its base address
#   	obj-name    	    	Figure the name for something associated
#				with a class based on its class name.
#   	next-master 	    	Skip up the class hierarchy for an object
#   	    	    	    	to figure out the class, base and instance
#   	    	    	    	structures for a master group in that object.
#   	print-method-table    	Prints out the method table for a given class
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#
# DESCRIPTION:
#	Functions for dealing with objects and their class chains etc.
#
#	$Id: object.tcl,v 1.11 90/11/03 19:36:45 adam Exp $
#
###############################################################################

##############################################################################
#				obj-foreach-class
##############################################################################
#
# SYNOPSIS:	Process all the classes in the hierarchy for an object.
# PASS:		func	= procedure to call with each class (starting from
#   	    	    	  the object's actual class and proceding up the
#   	    	    	  tree)
#   	    	obj 	= address of object to process (address expression
#   	    	    	  for the object's base)
#   	    	args	= extra data to pass to the procedure.
# CALLED BY:	EXTERNAL
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#   	The procedure is called:
#   	    $func $classSym $obj $args
#   	We accept as many arguments as desired and pass them verbatim to
#   	$func. Thus [obj-foreach-class ^lbx:si pclass a b c] would cause
#   	pclass to be invoked as [pclass $classSym ^lbx:si a b c] (i.e. the
#   	arguments we are passed are *not* passed in a list to the procedure).
#
#   	This function handles processing of variants, etc. The called procedure
#   	should return {} if processing should continue. Returning non-null
#   	will cause processing to stop and the value to be returned. The
#   	called procedure may use "uplevel 2" to access the variables of the
#   	procedure that called obj-foreach-class.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#
##############################################################################
[defdsubr obj-foreach-class {func obj args} prog.ui
{Process all the classes for an object from its actual class up to MetaClass.
First arg FUNC is the name of a procedure to call. Second arg OBJ is the address
of the object to process. Remaining args are passed verbatim to FUNC after the
symbol for the next class to process and OBJ. Returns what FUNC returns, if
processing stops before MetaClass is reached. Else returns {}}
{
    var cs [obj-class $obj]
    if {[null $cs]} {
    	error {object class unknown}
    }
    for {} {![null $cs]} {} {
    	#
    	# Call the procedure. If it returns non-null and non-zero, then finish
	# out the loop and return.
	#
    	var res [eval [concat [list $func $cs $obj] $args]]
	if {![null $res]} {
    	    return $res
    	}
	var md [sym get $cs]
	if {[string c [index $md 3] variant] == 0} {
    	    #
	    # Variant class -- fetch superclass from the first part of the
	    # instance data for the master part.
	    #
	    var mb [sym find type [obj-name [sym fullname $cs] Base]]
	    if {[null $mb]} {
	    	error [format {%s not a known type}
		    	[obj-name [sym fullname $cs] Base]]
	    }
	    var mo [expr [type size $mb]-2]
	    if {$mo >= 4} {
    	    	# Fetch the master offset from memory
	    	var mo [value fetch ($obj)+$mo word]
	    	if {$mo == 0} {
		    # Not built yet -- we're clueless
	            return
	    	} else {
	            var cs [obj-class ($obj)+$mo]
		    # Not built yet -- just return
		    if {[null $cs]} {
	        	return 
		    }
		}
	    } else {
    	    	error [format {%s: no room for master offset in base structure}
		    	[sym fullname $cs]]
	    }
	} else {
	    var cs [index $md 4]
    	}
    }
}]
	
defvar _mequ_list nil
defvar _mequ_first -1
defvar _mequ_last -1
#
# Set up to force a fetch of the imported methods list the first time 
# map-method is used after a detach.
#
[defsubr map-method-biff-mequ-list {args}
{
    uplevel 0 {
    	var _mequ_list nil _mequ_first -1 _mequ_last -1
    }
}]
defvar _mequ_biff_event nil

# Be sure to evaluate this in the global scope....
uplevel 0 {
    if {[null $_mequ_biff_event]} {
        var _mequ_biff_event [event handle DETACH map-method-biff-mequ-list]
    }
}

[defsubr map-method-callback {cs obj num}
{
    var mn [sym find type [obj-name [sym fullname $cs] Methods]]
    if {![null $mn]} {
    	return [type emap $num $mn]
    }
}]

[defdsubr map-method {num class {obj nil}} ui|object
{Map a method number to a method name. First argument is the number.
Second argument is either a class name or the address of an object.

When called from a program, the second argument should be the name of
the class from which to start the search, and the third argument should be
the object for which the the method name is being sought, so variant
classes can be handled, or 0 to indicate that variant classes either won't
occur or aren't to be handled.}
{

    global _mequ_list _mequ_first _mequ_last
    
    #
    # If ui now known and haven't figured out the funky exclusive methods
    # we like to map, do so now.
    #
    if {[null $_mequ_list] && ![null [patient find ui]]} {
    	var _mequ_list [eval [concat concat
    	    [map i {MOUSE KBD PRESSURE DIRECTION FOCUS TARGET
    	    	    FOCUS_WIN TARGET_WIN MODAL DEFAULT}
    	    {
    	    	var gained [sym find abs ui::MEQU_GAINED_${i}_EXCL]
		var lost [sym find abs ui::MEQU_LOST_${i}_EXCL]
		
		[list [list [sym get $gained] METHOD_GAINED_${i}_EXCL]
		      [list [sym get $lost] METHOD_LOST_${i}_EXCL]]
    	    }]]]
    	var _mequ_first [sym get [sym find abs ui::MEQU_FIRST]]
    	var _mequ_last [sym get [sym find abs ui::MEQU_LAST]]
    }

    # HACK... until swat adds the exported MetaClass methods to the
    # MetaClass enumerated type.

    if {$num >= $_mequ_first && $num <= $_mequ_last} {
    	var a [assoc $_mequ_list $num]
	if {![null $a]} {
	    return [index $a 1]
    	}
    }

    # back to the world of reality...

    if {[null $obj]} {
    	#
	# Called by user -- class can be a class name or an object
	#
	var s [sym find var $class]
	if {[null $s]} {
    	    var obj $class class [sym faddr var *($class).MB_class]
	    if {[null $class]} {
	    	return [format {class unknown}]
	    }
    	    #
	    # Change the class name to a path, since that's what's expected.
	    #
	    var class [sym fullname $class] cs $class
	} else {
	    #
	    # Given a class: change the class to a full name and the object
	    # to 0.
	    #
	    var class [sym fullname $s] obj {} cs $s
	}
    }

    #
    # Perform normal value things on the number, allowing registers and
    # whatnot to be given. The number used is just the offset of the
    # parsed "address".
    #
    var num [index [addr-parse $num] 1]

    if {![null $obj]} {
    	# XXX: handle class & object where method must come from class or its
	# ancestors
    	var en [obj-foreach-class map-method-callback $obj $num]
    } else {
    	#
	# No associated object, so just work up the class tree trying each
	# in turn.
	#
    	for {} {![null $cs]} {} {
    	    var mn [sym find type [obj-name [sym fullname $cs] Methods]]
	    if {![null $mn]} {
	    	var en [type emap $num $mn]
		if {![null $en]} {
		    return $en
    	    	}
    	    }
	    var cs [index [sym get $cs] 4]
    	}
    }
    #
    # If couldn't find the thing, perhaps we hit an unbuilt variant. Everything
    # goes to MetaClass everything, so make a final stab and look for the value
    # in MetaMethods (note that a method for MetaClass cannot be >= 2000, by
    # definition [q.v. object.h in Esp]).
    #
    if {[null $en] && ($num < 2000)} {
    	var en [type emap $num [sym find type kernel::MetaMethods]]
    }
    
    if {[null $en]} {
    	var en $num
    }

    return $en
}]

##############################################################################
#				print-obj-and-method
##############################################################################
#
# SYNOPSIS:	Print out the parameters for a method call given all the
#   	    	pertinent values.
# PASS:		od_handle   = handle of object being called
#   	    	od_chunk    = chunk handle of object being called
#   	    	method	    = number for method being invoked
#   	    	cx_value    = value passed to method in cx
#   	    	dx_value    = value passed to method in dx
#   	    	bp_value    = value passed to method in bp
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defsubr	print-obj-and-method {od_handle od_chunk method
				      cx_value dx_value bp_value}
{
	require name-root showcalls

    if {$od_handle == 0} {
	echo {NULL}
    } else {
    	var h [handle lookup $od_handle]
	[var odown [handle owner $h]
	     odname [index [range [patient fullname [handle patient $h]]
			     0 7 chars] 0]]
	if {$h == $odown} {
	    var thread [value fetch ^h[handle id $h].PH_firstThread]
    	    var h [handle lookup $thread]
	    var ss [value fetch kdata:$thread.HT_saveSS]
	    var s [sym faddr var *$ss:TPD_classPointer] obj {}
	} elif {[handle isthread $h]} {
	    var ss [value fetch kdata:[handle id $h].HT_saveSS]
	    var s [sym faddr var *$ss:TPD_classPointer] obj {}
    	} elif {([handle state $h] & 0xf0000) == 0x40000} {
	    # queue handle. See if it's got an associated thread
	    var tid [value fetch kdata:[handle id $h].HQ_thread]
	    if {$tid != 0} {
    	    	# Use the associated thread's class
    	    	var h [handle lookup $tid]
	    	var ss [value fetch kdata:$tid.HT_saveSS]
		var s [sym faddr var *$ss:TPD_classPointer] obj {}
    	    } else {
    	    	#
		# Disembodied event queue. Can't map the method to anything,
		# but at least print something
		#
	    	echo [format {Queue %04x, method = %d, data = %04x, %04x, %04x}
		    	[handle id $h] $method $cx_value $dx_value $bp_value]
		return
    	    }
    	} else {
    	    if {[expr [handle state $h]&0x40]} {
    	        echo -n {(discarded), }
    	    	var s {}
    	    } elif {[expr [handle state $h]&0x20]} {
    	        echo -n {(swapped), }
    	    	var s {}
    	    } else {
                var obj [format {^l%04xh:%04xh} $od_handle $od_chunk]
	        var s [obj-class $obj]
    	    }
	}
    	if {[null $s]} {
	    echo [format {class unknown, ^l%04xh:%04xh, method = %d, data = %04x, %04x, %04x}
	    	    $od_handle $od_chunk $method $cx_value $dx_value $bp_value]
	} else {
	    var sn [sym fullname $s]
	    var en [map-method $method $sn $obj]
	    if {[null $en]} {
		echo -n $method
	    } else {
		echo -n $en
	    }
	    if {![null $obj]} {
		echo -n [format {, ^l%04xh:%04xh, %s} $od_handle $od_chunk
				[name-root $sn]]
	    } else {
	    	echo -n , [name-root $sn] ([patient name [handle patient $h]]:[thread number [handle other $h]])
	    }
	    echo [format {, data = %04xh, %04xh, %04xh} $cx_value
		    $dx_value $bp_value]
	}
    }
}]

##############################################################################
#				get-chunk-addr-from-obj-addr
##############################################################################
#
# SYNOPSIS:	Given object's address, figure out the chunk handle in its
#   	    	block that points to the object, allowing breakpoints and
#   	    	whatnot to be set for an unchanging quantity.
# PASS:		objaddr	= address expression giving the base of the object
# CALLED BY:	INTERNAL
# RETURN:	3-list for the object's chunk handle
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defsubr	get-chunk-addr-from-obj-addr {objaddr} 
{
    var address	    [addr-parse $objaddr]
    var	seg	    ^h[handle id [index $address 0]]
    [case $objaddr in
    	{^l*|\*[de]s:si|\*[de]s:di|\*[de]s:bx|\*[de]s:bp} {
    	    #
	    # Address given contains the chunk handle as its offset portion,
	    # so just use it directly.
	    #
	    var c [string first : $objaddr]
	    var chunk [index [addr-parse [range $objaddr [expr $c+1] end char]]
	    	    	    	1]
    	}
	default {
	    if {[index $address 1] == 0} {
		# If address passed is the start of a block, then keep it.
		return $address
	    } else {
		# Otherwise, figure out chunk handle that matches pointer
		# 	passed
		var caddr [index $address 1] hid [handle id [index $address 0]]
		[for {
		    	[var chunk [value fetch $seg:LMBH_offset]
			     nHandles [value fetch $seg:LMBH_nHandles]]
    	    	     }
		     {$nHandles > 0}
		     {var nHandles [expr $nHandles-1] chunk [expr $chunk+2]}
		{
		    if {[value fetch ^h$hid:$chunk word] == $caddr} {
			break
		    }
		}]
    	    }
	}
    ]
    return [addr-parse $seg:$chunk]
}]

##############################################################################
#				obj-name
##############################################################################
#
# SYNOPSIS:	Figure a good name for something related to a class.
# PASS:	    	base	= full name of the class involved
#   	    	suffix	= suffix for related symbol (e.g. Base or Instance)
# CALLED BY:	next-master and EXTERNAL
# RETURN:	$base with any extra module information and trailing "Class"
#   	    	removed (patient name stays) and $suffix appended
# SIDE EFFECTS:	None
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#
##############################################################################
[defsubr obj-name {base suffix}
{
    #
    # Trim off any trailing Class, as Esp would have done
    #
    var l [length $base chars]
    if {$l > 5 && [string c [range $base [expr $l-5] end char] Class] == 0} {
    	var base [range $base 0 [expr $l-6] chars]
    }

    if {[string match $base *::*::*]} {
	#
	# In a different patient -- prefix the Instance structure's name
	# with the owning patient's name...
	#
	return [format {%s:%s%s}
			[range $base 0 [string first :: $base] chars]
			[range $base [expr [string last :: $base]+2] end chars]
			$suffix]
    } else {
	#
	# Same patient -- just replace the "Class" with "Instance" to form
	# the structure name
	#
	return [range $base [expr [string last :: $base]+2] end chars]$suffix
    }
}]

    	
##############################################################################
#				next-master
##############################################################################
#
# SYNOPSIS:	Locate the next master class in the class hierarchy. Sort of.
# PASS:		className   = full name of starting class
#   	    	addr	    = address of the object involved (for resolving
#   	    	    	      variants)
#   	    	skip	    = number of master classes to skip
# CALLED BY:	pmaster
# RETURN:	A 3-list containing the class name, its base structure's
#   	    	name and its instance structure's name, in that order.
#   	    	The class name is that of the first class immediately following
#   	    	$skip master classes, with the instance structure name coming
#   	    	from that same class.
#   	    	The base structure, however, belongs to the first master class
#   	    	above the returned class so the caller can just use the final
#   	    	field of the structure type to get the offset.
# SIDE EFFECTS:	None
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#
##############################################################################
[defsubr next-master-callback {cs addr}
{
    var type [index [sym get $cs] 3]
    uplevel 2 [format {
	if {$saveNext} {
	    var class {%s} saveNext 0
	}
    } $cs]

    if {[string c $type master] == 0 || [string c $type variant] == 0} {
    	uplevel 2 [format {
	    var skip [expr $skip-1] master {%s}
	    if {$skip < 0} {
	    	return 1
    	    }
	    var saveNext 1 
    	} $cs]
    }
}]

[defsubr next-master {addr skip}
{
    # Initialize for next-master-callback
    var saveNext 1

    # next-master-callback Sets $class to symbol for class above $skip'th master
    # $master is set to the master class immediately above that.
    # obj-foreach-class returns {} if we walk off the class tree.
    if {![null [obj-foreach-class next-master-callback $addr]]} {
	# return actual class name and the Base and Instance types to use
	var className [sym fullname $class]
	return [list $className [obj-name [sym fullname $master] Base] 
				[obj-name $className Instance]]
    }
}]

##############################################################################
#				fetch-optr
##############################################################################
#
# SYNOPSIS:	Fetch an optr from an object, dealing with relocating it if
#   	    	the containing block isn't in memory.
# PASS:		bl  = handle ID of containing block
#   	    	off = offset in the block from which to get the optr
# CALLED BY:	objtree
# RETURN:	A two-list containing the optr's handle ID and chunk handle,
#   	    	in that order.
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/11/90		Initial Revision
#
##############################################################################
[defsubr fetch-optr {bl off}
{
    #
    # Fetch the two pieces first
    #
    var chunk [value fetch ^h$bl:$off.OD_chunk]
    var han [value fetch ^h$bl:$off.OD_handle]
			    
    #
    # See if the handle is resident and relocate $han if not.
    #
    var objhan [handle lookup $bl]
    if {![field [value fetch ^h$bl:LMBH_flags] LMF_RELOCATED]} {
	# The top four bits contain the type of relocation to perform on the
	# handle. The chunk handle needs no relocating.
	[case [expr ($han>>12)&0xf] in
	    0 {
		# ORS_NULL
    	    	var han 0
	    }
	    1 {
		# ORS_OWNING_GEODE. low 12 bits are resource ID
		var han [handle id
			 [index
			  [patient resources
			   [handle patient $objhan]]
			    [expr $han&0xfff]]]
	    }
	    2 {
		# ORS_KERNEL
		error [format {^h%04xh:%s.handle relocates to KERNEL?}
		    	    	$bl $off]
	    }
	    3 {
		# ORS_LIBRARY
		error [format {^h%04xh:%s.handle relocates to LIBRARY?}
		    	    $bl $off]
	    }
	    4 {
		# ORS_CURRENT_BLOCK -- set $han to $bl
		var han $bl
	    }
	    5 {
		# ORS_VM_HANDLE -- find block handle in saved block
		# list for owning geode
	    }
	]
    }
    return [list $han $chunk]
}]

##############################################################################
#				obj-class
##############################################################################
#
# SYNOPSIS:	Fetch the class of an object, unrelocating the thing if the
#   	    	block containing the object is not in memory
# PASS:		obj = address of the base of the object
# CALLED BY:	EXTERNAL
# RETURN:	The symbol token for the class
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/11/90		Initial Revision
#
##############################################################################
[defsubr map-entry-num-to-sym {patient entry}
{
    var core ^h[handle id [index [patient resources $patient] 0]]
    var off [value fetch (*$core.GH_exportLibTabOff)+[expr $entry*4] word]
    var seg [value fetch (*$core.GH_exportLibTabOff)+[expr $entry*4]+2 word]
    
    if {$seg < 0x1000} {
    	return [symbol faddr var ^h[expr $seg<<4]:$off]
    } else {
    	return [symbol faddr var $seg:$off]
    }
}]

[defsubr obj-class {obj}
{
    #
    # Figure the handle of the object by parsing its address
    #
    var a [addr-parse $obj]
    var hid [handle id [index $a 0]]
    if {[field [value fetch ^h$hid:LMBH_flags] LMF_RELOCATED]} {
    	# Block's been relocated, so we can find the symbol token for that class
	# easily.
    	return [symbol faddr var *($obj).MB_class]
    } else {
    	#
    	# Unrelocate the class pointer. The low word contains the relocation
	# information that tells from whence the class pointer comes, while the
	# high word contains the exported entry number.
	#
	var rel [value fetch ($obj).MB_class.OD_offset]
    	var entry [value fetch ($obj).MB_class.OD_segment]
	var patient [handle patient [index $a 0]]
	if {[string c [patient name $patient] kernel] == 0} {
	    # Must be a VM block -- find the owner of the thing's exec thread
	    var vmh [value fetch kdata:$hid.HM_owner]
	    var ethread [value fetch kdata:$vmh.HVM_execThread]
	    var patient [handle patient [handle lookup $ethread]]
	}

	[case [expr ($rel>>12)&0xf] in
	    0 {
	    	#ORS_NULL -- return nothing
    	    	return
	    }
	    1|6 {
	    	# ORS_OWNING_GEODE/ORS_OWNING_GEODE_ENTRY_POINT. low 12 bits
		# are resource ID (unused). Next word (OD_segment) is
		# entry-point number
    	    	return [map-entry-num-to-sym $patient $entry]
    	    }
	    2 {
	    	# ORS_KERNEL.
    	    	var off [value fetch krout:[expr $entry*2] word]
		return [symbol faddr var kcode:$off]
    	    }
	    3 {
	    	# ORS_LIBRARY. low 12 bits are library number. Next word
		# is entry-point number. Figure the library by indexing
		# the imported-library table for the geode with the low 12 bits
		# to get the patient.
		var core ^h[handle id [index [patient resources $patient] 0]]
    	    	var lseg [value fetch 
		    	    (*$core.GH_libOffset)+[expr ($rel&0xfff)*2] word]
		var patient [handle patient [handle find $lseg:0]]
		return [map-entry-num-to-sym $patient $entry]
    	    }
	    default {
	    	error [format {Unhandled relocation type %d} 
		    	[expr ($rel>>12)&0xf]]
    	    }
    	]
    }
}]


#  The following appear to work about as well as "call" does, which isn't
#  great...
#
#[defsubr objcall {obj method {cxvalue 0} {dxvalue 0} {bpvalue 0}}
#{
#	require call
#
#    # Get the segment and offset of the object to print out.
#    # var objclass [getobjclass ($obj)]
#    var addr [addr-parse ($obj)]
#    # var label [value hstore $addr]
#    var bl [handle id [index $addr 0]]
#    # var seg [handle segment [index $addr 0]]
#    # var off [index $addr 1]
#    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]
#    # var masteroff [value fetch ($obj).$masterOffset]
#    # var master [expr [index $addr 1]+$masteroff]
#
#    [call ObjMessage	push bx
#			push si
#			bx $bl
#			si $ch 
#			ax $method
#			push di
#			di 8000h
#			cx $cxvalue
#			dx $dxvalue
#			bp $bpvalue
#    ]
#
#}]
#
#[defsubr objmessage {obj method {cxvalue 0} {dxvalue 0} {bpvalue 0}}
#{
#	require call
#
#    # Get the segment and offset of the object to print out.
#    # var objclass [getobjclass ($obj)]
#    var addr [addr-parse ($obj)]
#    # var label [value hstore $addr]
#    var bl [handle id [index $addr 0]]
#    # var seg [handle segment [index $addr 0]]
#    # var off [index $addr 1]
#    var ch [index [get-chunk-addr-from-obj-addr $obj] 1]
#    # var masteroff [value fetch ($obj).$masterOffset]
#    # var master [expr [index $addr 1]+$masteroff]
#
#    [call ObjMessage	push bx
#			push si
#			bx $bl
#			si $ch 
#			push ax
#			ax $method
#			push di
#			di 0
#			push cx
#			cx $cxvalue
#			push dx
#			dx $dxvalue
#			push bp
#			bp $bpvalue
#    ]
#
#}]


[defsubr print-method-table {class}
{
    var methodcount [value fetch $class.Class_methodCount]
    for {var i 0} {$i < $methodcount*2} {var i [expr $i+2]} {
	var method [value fetch $class.Class_methodTable+$i]
	var addrbase $class.Class_methodTable+[expr $methodcount*2]
	var low [value fetch $addrbase+[expr $i*2+0]]
	var high [value fetch $addrbase+[expr $i*2+2]]
	if {$high > 0xf000} {
            var seg ^h[expr {($high-0xf000)<<4}]
	} else {
	    var seg $high
	}
	var s [sym faddr func {$seg:$low}]
	if {![null $s]} {
	   var offset [expr $low-[sym addr $s]]
	   if {$offset} {
	       echo [format {%35s	(%s+%1d)}
			[map-method $method $class]
			[sym fullname $s]
			$offset
		]
	   } else {
	       echo [format {%35s	(%s)}
			[map-method $method $class]
			[sym fullname $s]
		]
	   }
	} else {
	   echo [format {%35s	(%04x:%04x ???)}
			[map-method $method $class]
			$seg $low
		]
	}
    }
}]

