##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
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
#   	isclassptr
#   	omfq
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#
# DESCRIPTION:
#	Functions for dealing with objects and their class chains etc.
#
#	$Id: object.tcl,v 1.74.4.1 97/03/29 11:27:17 canavese Exp $
#
###############################################################################

[defvar printObjLongClassName 0 swat_variable.output
{Usage:
    var printObjLongClassName (0|1)

Examples:
    "var printObjLongClassName 1"    Enables long class name printing

Notes:
    * The default value for this variable is 0.

See:
    See long-class
}]

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
[defcommand obj-foreach-class {func obj args} swat_prog.ui
{Usage:
    obj-foreach-class <function> <object> [<args>]

Examples:
    "obj-foreach-class foo-callback ^lbx:si"	calls foo-callback with each
						class in turn to which the
						object ^lbx:si belongs.

Synopsis:
    Processes all the classes to which an object belongs, calling a callback
    procedure for each class symbol in turn.

Notes:
    * <function> is called with the symbol for the current class as its first
      argument, <object> as its second, and the arguments that follow <object> 
      as its third and subsequent arguments.

    * <function> should return an empty string to continue up the class tree.
    
    * obj-foreach-class returns whatever <function> returned, if it halted
      processing before the root of the class tree was reached. It returns
      the empty string if <function> never returned a non-empty result.

See also:
    obj-class.
}
{
    var a [addr-preprocess $obj seg off]
    var obj $seg:$off

    var cs [obj-class $obj]
    if {[null $cs]} {
    	#
	# See if <object> is actually a class.
	#
    	var cs [symbol faddr var $obj]
	if {[null $cs]} {
    	    error {object class unknown}
    	} else {
    	    #
	    # It is. Pass a null object to indicate this.
	    #
	    var obj {}
    	}
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
	if {[string c [symbol type $cs] var] == 0} {
	    #
	    # yrg. class is defined in C, so we have to consult the class
	    # itself to find its variance and superclass. The result is left
	    # in $md as if the class were actually defined in the ever-
	    # cool object assembly language.
	    #
	    var fn [symbol fullname $cs]

	    [if {[field [value fetch $fn.Class_flags 
	    	    	    [symbol find type geos::ClassFlags]]
			CLASSF_VARIANT_CLASS]}
    	    {
	    	var md [concat [symbol get $cs] variant superclass_dont_matter]
    	    } else {
    	    	# the class symbol for the superclass must be protected
		# from concat by being placed inside a list, so we might
		# as well put both the flag and the superclass into a list
		# to protect the marginal data hiding we currently have
		# for symbol tokens...
	    	var md [concat [symbol get $cs] 
		    	[list not-variant 
		    	    [symbol faddr var *$fn.Class_superClass]]]
    	    }]
        } else {
    	    #
	    # A member of our own class, so to speak, so we can just get the
	    # required information from the symbol table itself.
	    #
	    var md [sym get $cs]
    	}
	if {[string c [index $md 3] variant] == 0} {
	    #
	    # Variant class -- fetch superclass from the first part of the
	    # instance data for the master part.
	    #
    	    if {[null $obj]} {
    	    	# not given object, so it has no superclass
		return
    	    }
	    var mb [sym find type [obj-name [sym fullname $cs] Base]]
	    if {[null $mb]} {
    	    	var mb [sym find type [obj-name [sym name $cs] Base]]
    	    	if {[null $mb]} {
		    error [format {%s not a known type}
			[obj-name [sym fullname $cs] Base]]
    	    	}
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
	
global geos-release
if {${geos-release} < 2} {
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
}

[defsubr map-method-callback {cs obj num}
{
    var mn [sym find type [obj-name [sym fullname $cs] Messages]]
    if {![null $mn]} {
    	return [type emap $num $mn]
    }
}]

[defsubr map-method-callback-r1 {cs obj num}
{
    var mn [sym find type [obj-name [sym fullname $cs] Messages]]
    if {![null $mn]} {
    	return [type emap $num $mn]
    }
}]

[defcommand map-method {num class {obj nil}} object.message
{Usage:
    map-method <number> <object>
    map-method <number> <class-name> [<object>]

Examples:
    "map-method ax ^lbx:si" 	Prints the name of the message in ax, from
    	    	    	    	the object at ^lbx:si's perspective.
    "map-method 293 GenClass"	Prints the name of message number 293 from
    	    	    	    	GenClass's perspective.

Synopsis:
    Maps a message number to a human-readable message name, returning that
    name. This command is useful both for the user and for a Tcl procedure.

Notes:
    * When called from a Tcl procedure, the <class-name> argument should be the
      fullname of the class symbol (usually obtained with the obj-class
      function), and <object> should be the address of the object for which
      the mapping is to take place. If no <object> argument is provided,
      map-method will be unable to resolve messages defined by one of the
      object's superclasses that lies beyond a variant superclass.

    * If no name can be found, the message number, in decimal, is returned.
    
    * The result is simply returned, not echoed. You will need to echo the
      result yourself if you call this function from anywhere but the command
      line.

See also:
    obj-class
}
{

    global geos-release
    
    if {${geos-release} < 2} {
	global _mequ_list _mequ_first _mequ_last

	#
	# If ui now known and haven't figured out the funky exclusive methods
	# we like to map, do so now.
	#
	if {[null $_mequ_list] && ![null [patient find ui]]} {
	    var _mequ_list [eval [concat concat
		[map i {MOUSE KBD PRESSURE DIRECTION FOCUS TARGET
			MODAL DEFAULT}
		{
		    var gained [sym find abs ui::MEQU_GAINED_${i}_EXCL]
		    var lost [sym find abs ui::MEQU_LOST_${i}_EXCL]

		    [list [list [sym get $gained] MSG_GAINED_${i}_EXCL]
			  [list [sym get $lost] MSG_LOST_${i}_EXCL]]
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
    }

    if {[null $obj]} {
    	#
	# Called by user -- class can be a class name or an object
	#
	var s [sym find var $class]
	if {[null $s]} {
    	    var obj $class
	    var class [obj-class $obj]
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
    var num [getvalue $num]

    if {![null $obj]} {
    	# XXX: handle class & object where method must come from class or its
	# ancestors
	if {[not-1x-branch]} {
	    var en [obj-foreach-class map-method-callback $obj $num]
	} else {
	    var en [obj-foreach-class map-method-callback-r1 $obj $num]
	}
    } else {
    	#
	# No associated object, so just work up the class tree trying each
	# in turn.
	#
    	for {} {![null $cs]} {} {
	    if {[not-1x-branch]} {
		var mn [sym find type [obj-name [sym fullname $cs] Messages]]
	    } else {
		var mn [sym find type [obj-name [sym fullname $cs] Methods]]
	    }
	    if {![null $mn]} {
	    	var en [type emap $num $mn]
		if {![null $en]} {
		    return $en
    	    	}
    	    }
	    if {[string c [symbol type $cs] var] == 0} {
		#
		# Bleah. The thing is a class defined in C, so we don't
		# know, from our symbol table, what the superclass is. This
		# forces us to go to the PC to find out. Sigh.
		#
		var cs [symbol faddr var *[symbol fullname $cs].Class_superClass]
	    } else {
	        #
		# Use the information in the symbol table to get the superclass
		#
	    	var cs [index [sym get $cs] 4]
	    }
    	}
    }
    #
    # If couldn't find the thing, perhaps we hit an unbuilt variant. Everything
    # goes to MetaClass eventually, so make a final stab and look for the value
    # in MetaMessages (note that a method for MetaClass cannot be >= 8192, by
    # definition [q.v. object.h in Esp]).
    #
    if {[null $en] && ($num < 8192)} {
    	var en [type emap $num [if {[not-1x-branch]}
				    {sym find type geos::MetaMessages}
				    {sym find type geos::MetaMethods}]]
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
# SYNOPSIS:	Print out a nice looking reference to an object, complete with
#		message & parameters, if desired, plus label & hex address.
# PASS:		od_handle   = handle of object being called
#   	    	od_chunk    = chunk handle of object being called
#		flags	    = misc flags for operation:
#				-n		No carriage return
#				-h		No hex address (^l4320:001eh)
#				-l		No label (@70)
#			      Flags can be combined, e.g. -nhl.  If not used,
#			      & args are passed, {} must be passed to occupy
#			      the argument slot.
#   	    	args	    = In order (any number of which may be given):
#					method
#					cx value
#					dx value
#					bp value
#					symbol token of class to print out
#						(if other than top class of obj)
# CALLED BY:	where, elist, pobj, objtree, objparent, etc..
# RETURN:	
# SIDE EFFECTS:	Prints out references to objects/messages, such as:
#
#		^l4350h:FolderUpButton::DirToolClass
#		*SystemField0::GenFieldClass (@850, ^l2980h:001eh)
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#	doug	7/93		class, flags, standardized commands on this
#
##############################################################################
[defcommand print-obj-and-method {od_handle od_chunk {flags {}} args} swat_prog.ui
{Usage:
    print-obj-and-method <handle> <chunk> [<flags> [<message> [<cx> [<dx> [<bp> [<class> ]]]]]]

Examples:
    "print-obj-and-method [read-reg bx] [read-reg si]"
    	    	    	    	Prints a description of the object ^lbx:si,
				vith value stored and a hex representation.
    "print-obj-and-method $h $c -nhl $m [read-reg cx] [read-reg dx] [read-reg bp]"
    	    	    	    	Prints a description of the object ^l$h:$c,
				the name of the message whose number is in $m,
				three words of data, a label, hex
				representation, but no CR.

Synopsis:
    Prints a nice looking representation of an object, with option message,
    register data, label, hex address, & carriage return.  The class indication
    may also be overriden.

Notes:
    * You may specify anywhere from 0 to 5 arguments after the flags.
      These are interpreted as the value of the message, the registers CX, DX
      and BP, and the symbol token of the class to print, respectively.

    * All arguments must be integers, as this is expected to be called by
      another procedure, not by the user, so the extra time required to
      call getvalue would normally be wasted.  (The user should call pobj/gup/
      etc. to see this type of printout)

See also:
    map-method
}
{
    global printObjLongClassName
    
    # If a method has been passed, get it
    if {[length $args]>=1} {
   	 var method [index $args 0]
    }
    if {$od_handle == 0} {
    	if {$od_chunk == 0} {
	    var on ANYONE
    	} else {
	    var on [format {BAD ADDR ^l%04xh:%04xh} $od_handle $od_chunk]
    	}
	if {![null $method]} {
    		var mn [map-method $method geos::MetaClass]
		if {[null $mn]} {var mn $method}
	}
    } else {
    	var h [handle lookup $od_handle]
	if {[null $h]} {
    	    # if not a handle, make $type a bogus value
	    var type f8000
    	} else {
	    # get the type of handle in an easily-matchable format (5 hex 
	    # digits)
	    var type [format {%05x} [expr [handle state $h]&0xf8000]]
    	}
	[case $type in
	    08000 {
	    	#
		# Memory handle
		#

		# Since Process handlers are passed dgroup in ds, the handle
		# of dgroup ends up being passed here by backtrace, since it
		# simply grabs it off the stack.  Seeing as this may happen
		# other places as well, let's handle this case by detecting
		# od_handle = dgroup, & changing it back to the process handle,
		# the real object, at this time.
		if {$h == [handle find dgroup]} {
			var h [handle owner $h]
		}

		# Special handling for geode/process handle
		if {$h == [handle owner $h]} {
		    [if {[not-1x-branch]}
		    {
			# first thread of a process is in the HM_otherInfo
			# field of the geode handle in 2.0+
			var thread [value fetch kdata:[handle id $h].HM_otherInfo]
		    } else {
			# but it's in the core block for 1.X
			var thread [value fetch ^h[handle id $h].PH_firstThread]
		    }]
		    # Deal with special weirdness of geos process -- otherInfo
		    # field just has a 1 in it, not a thread handle, so we
		    # only know the "object" by the name of the geode, not
		    # the thread as customary.
		    if {[string match $thread 1]} {
			var obj [patient name [handle patient $h]]
		    } else {
		    	var h [handle lookup $thread]
		    	var ss [thread register [handle other $h] ss]
		    	var s [sym faddr var *$ss:TPD_classPointer] obj {}
		    }

		    # if going to a process, then chunk is actually a data value
		    var si $od_chunk
		# Discarded block
		} elif {[expr [handle state $h]&0x40]} {
		    var obj [format {discarded ^l%04xh:%04xh} $od_handle $od_chunk]
		    var s {}
		# Swapped block
		} elif {[expr [handle state $h]&0x20]} {
		    var obj [format {swapped ^l%04xh:%04xh} $od_handle $od_chunk]
		    var s {}
		} else {
		    #If just a plain, ordinary object from a resource, see if
		    #it has a name. If so, use it.

		    var fc [value fetch ^h$od_handle:LMBH_offset]
		    var ocf [value fetch (^l$od_handle:$fc)+($od_chunk-$fc)/2
				[symbol find type geos::ObjChunkFlags]]
		    if {[field $ocf OCF_IN_RESOURCE]} {
			var name [get-obj-name $od_handle $od_chunk]
		    }
		    var obj [format {^l%04xh:%04xh} $od_handle $od_chunk]
		    var s [obj-class $obj]
		}
		# if label requested, generate it.
		if {([string first l $flags]==-1)} {
    			var label [value hstore
					[addr-parse ^l$od_handle:$od_chunk]]
		}
    	    }
	    e0000 {
	    	#
		# Thread handle
		#
		var ss [value fetch kdata:[handle id $h].HT_saveSS]
		var s [sym faddr var *$ss:TPD_classPointer] obj {}

		# if going to a thread, then chunk is actually a data value
		var si $od_chunk
    	    }
	    40000 {
	    	#
		# Queue handle -- see if it's got an associated thread
		#
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
		    var obj [format {queue ^h%04xh} $od_handle]
		    var s {}
		}
		# if going to a thread, then chunk is actually a data value
		var si $od_chunk
    	    }
	    default {
		var h {}
		if {[isclassptr $od_handle:$od_chunk]} {
		    var s [symbol faddr var $od_handle:$od_chunk]
		    var obj {}
		} else {
		    var obj [format {BAD ADDR ^l%04xh:%04xh}
				$od_handle $od_chunk]
		    var s {}
		}
    	    }
    	]

	# If a class has been passed, get it
    	if {[length $args]>=5} {
	    var classarg [index $args 4]
	}

    	#
	# At this point:
	#   s	= symbol token for class of object to which message is being
	#	  delivered. If null, class is unknown.
	#   classarg = symbol token for class to print, if passed
	#   obj	= formatted name of object. If null, then no object being
	#	  sent to (classed event, thread or queue destination)
	#   h	= handle token for $od_handle. If null, then classed event
	#	  or garbage address.
	#
    	if {[null $s]} {
    	    #
	    # Object class unknown, so we can't map the method, but provide 
	    # the message number and whatever info ($obj) we decided to print 
    	    # for the destination. If we didn't decide, do so now :)
	    #
	    if {[null $classarg]} {
		var cn {class unknown}
	    } else {
		var cn [symbol name $classarg]
	    }

	    if {![null $method]} {
		var mn [map-method $method geos::MetaClass]
    	    	# last-ditch attempt: map through MetaClass
	    	if {[null $mn]} {var mn $method}
	    }

	    if {[null $obj]} {
		var on [format {^l%04xh:%04xh} $od_handle $od_chunk]
	    } else {
		var on $obj
	    }

	} else {
	    if {![null $classarg]} {
		var s $classarg
	    }
	    var cn [symbol name $s]

	    if {![null $method]} {
	    	var mn [map-method $method [sym fullname $s] $obj]
	    	if {[null $mn]} {
    	    		# last-ditch attempt: map through MetaClass
			var mn [map-method $method geos::MetaClass $obj]
			if {[null $mn]} {var mn $method}
	    	}
	    }

	    if {![null $obj]} {
		if {![null $name]} {
			var on $name
		} else {
			var on $obj
		}
	    } elif {![null $h]} {
		var on [format {%s:%d}
			[patient name [handle patient $h]]
			[thread number [handle other $h]]]
	    } else {
	    	var on  [format {^l%04xh:%04xh} $od_handle $od_chunk]
    	    }
	}
    }

    if { $printObjLongClassName == 1 } {
    	var cn [get-all-class-names $od_handle $od_chunk]
    }
	     
    #
    # For the Responder project, check to see if we have a classname of
    # ComplexExpandingMonikerClass or ComplexMonikerClass.  If that is the
    # case, then set the classname to "CM/<variant superclass>" or "CEM/..."
    # so that the visibly apparent class of the object is printed, not just
    # "ComplexMonikerClass".  Foam library must be loaded.
    #
    if { $cn == ComplexMonikerClass && ![null [patient find foam]] } {
	
	# Get offset to ComplexMonikerClass instance data
	var master [value fetch (^l$od_handle:$od_chunk).foam::ComplexMoniker_offset]
	
	# getobjclass will now give us the variant superclass name.
    	require getobjclass objtree
	var cn CM/[getobjclass (^l$od_handle:$od_chunk)+$master]
    }

    #
    # OK.  Everything gathered, just print it out.
    #	on	- object name string
    #	mn	- message name string (or null for none)
    #	cn	- class name string
    #	args	- still has original args
    #
    echo -n [format {%s{%s}} $on $cn]
    if {![null $method]} {
	echo -n $mn
    }
    #
    # If caller provided data values for the other three registers,
    # print them now.
    #
    [case [length $args] in
	{0 1} {
    	    if {![null $si]} {echo -n [format {(%04xh)} $si]}
	}
    	2   {
	    echo -n [format {(%04xh} [index $args 1]]
    	    if {![null $si]} {echo -n [format { %04xh} $si]}
    	    echo -n [format {)}]
	}
	3   {
	    echo -n [format {(%04xh %04xh} [index $args 1] [index $args 2]]
    	    if {![null $si]} {echo -n [format { %04xh} $si]}
    	    echo -n [format {)}]
	}
    	{4 5} {
 	    echo -n [format {(%04xh %04xh %04xh}
			[index $args 1] [index $args 2] [index $args 3]]
    	    if {![null $si]} {echo -n [format { %04xh} $si]}
    	    echo -n [format {)}]
	}
    ]

    # if label requested & available, print it.
    if {([string first l $flags]==-1) && ![null $label]} {
	echo -n [format { (@%d} $label]
	# If hex address requested, print that too.
	if {([string first h $flags]==-1)} {
		echo -n [format {, ^l%04xh:%04xh)} $od_handle $od_chunk]
	} else {
		echo )
	}
    } else {
	# If hex address requested, print it, without label
	if {([string first h $flags]==-1)} {
		echo -n [format { (^l%04xh:%04xh)} $od_handle $od_chunk]
	}
    }

    # if -n flag wasn't passed, print CR at end
    if {[string first n $flags]==-1} {
	echo
    }
}]

[defcommand long-class {{value {}}} swat_prog.ui
{Usage:
    long-class [on|off]
     
Synopsis:
    Turns on or off printing out all class names for an object in
    print-obj-and-method (used in pobject, vup, vistree, etc...).
    
Examples:
    "long-class"         Show if long class name printint is currently enabled
    "long-class on"      Enables long class name printing
    "long-class off"     Disables long class name printing

Notes:
    When enabled, print-obj-and-method displays a string containing the class
    names for the furthest subclass for each master class.  For example, on
    a GenPrimary object, the resulting string is
    "GenPrimaryClass/OLBaseWinClass".  This is most useful for debugging or
    trying to understand what Gen objects build out to in the Specific UI.

See also:
    print-obj-and-method
}
{
    global printObjLongClassName
    
    if { $value == on } {
    	var printObjLongClassName 1
    } elif { $value == off } {
    	var printObjLongClassName 0
    } elif { ! [null $value] } {
    	error [format {Unknown value passed to long-class: "%s"} $value]
    }
	    
    if { $printObjLongClassName == 0 } {
    	echo Long class name printing is disabled
    } else {
    	echo Long class name printing is enabled
    }
}]

#
# Returns a string containing the class names for the furthest subclass for
# each master class of the given object.  For example, on a GenPrimary object,
# thre resulting string is: "GenPrimaryClass/OLBaseWinClass"
#
[defsubr get-all-class-names {h c} {
    # These variables are used by gacn-cb.
    #
    # includeNext means that the next class name encountered in the hierarchy
    #	 should be included in the string.
    #
    # name is the string that is being built up by the callback routine and
    #	 will eventually be returned by this function.
    #
    var includeNext 1 name {}
    obj-foreach-class gacn-cb ^l$h:$c
    return $name
}]

#
# Callback for above routine.  Gets called on each class of the object.
# This simply creates a string (global) that contains the next class name
# that appears AFTER a master/master-variant class, plus the first class name.
#
[defsubr gacn-cb {class-sym obj} {
    var ctype [symbol type ${class-sym}]
    var cname [symbol name ${class-sym}]
    
    # provide short name for ComplexMonikerClass because no one really cares
    # that much...
    if { $cname == ComplexMonikerClass } {
    	var cname CM
    }
    
    if { [uplevel get-all-class-names var includeNext] == 1 } {
	if { $cname != MetaClass } {
	    if { [null [uplevel get-all-class-names var name]] } {
		uplevel get-all-class-names var name $cname
	    } else {
		uplevel get-all-class-names var name [uplevel
				  get-all-class-names var name]/$cname
	    }
	}
	uplevel get-all-class-names var includeNext 0
    }
    
    if { $ctype == variantclass || $ctype == masterclass } {
	uplevel get-all-class-names var includeNext 1
    }
}]


[defsubr	get-obj-name {h c}
{
	# Find a name for this object.  If the address it's add has a symbolic
	# name (maching aexactly, of course), use it.
	#
    	var namesym [symbol faddr var ^h$h:$c]
    	if {![null $namesym]} {
	    var namepos [symbol addr $namesym]
	    if {[index [addr-parse $namepos 0] 1] ==
					[index [addr-parse $c 0] 1]} {
		return [format {*%s} [symbol name $namesym]]
	    }
	}

	# If the solution wasn't that easy, try something else -- see if the
	# block this object is in was duplicated via ObjDuplicateResource in
	# the EC code.  This code now actually tags blocks with a special
	# piece of vardata for the debugger just so we can show symbolic 
	# information about the object -- specifically, the symbolic name of
	# the chunk of the object.
	#
	# First, make sure DEBUG_META_OBJ_DUPLICATE_RESOURCE_INFO exists,
	# though, so we don't blow up in fvardata passing a bogus symbol
	#
	if {![null [symbol find enum DEBUG_META_OBJ_DUPLICATE_RESOURCE_INFO]]} {
		require fvardata pvardata
		var flags [value fetch ^h$h:LMBH_offset]
		if {[value fetch ((^l$h:$flags)+((1eh-$flags)/2)).OCF_IS_OBJECT]} {
		    var info [fvardata DEBUG_META_OBJ_DUPLICATE_RESOURCE_INFO ^l$h:1eh]
		} else {
			var info {}
		}
	} else {
		var info {}
	}
	if {![null $info]} {
	    var on {}
	    foreach char [index [index [index $info 1] 0] 2] {
		    var on [format {%s%s} $on $char]
	    }
	    var op [patient find [index $on 0]]
	    if {![null $op]} {
		var geode [handle id [index [patient resources $op] 0]]
		var entry [expr [index [index [index $info 1] 1] 2]&0fffh]
		var rho [value fetch ^h$geode:GH_resHandleOff [type word]]
		var th [value fetch ^h$geode:$rho+[expr $entry*2] [type word]]
		var namesym [symbol faddr var ^h$th:$c]
		if {![null $namesym]} {
			return [format {^l%4xh:%s}
				$h
				[symbol name $namesym]]
		}
	    } else {
		return {}
	    }
	} else {
	    return {}
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
# RETURN:	if objaddr refers to lmem-based object:
#   	    	    3-list for the object's chunk handle
#   	    	if objaddr is [<patient_name>][:<thread_num>]:
#   	    	    3-list {<thread handle> 0 {}}
#
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
    if {[catch {addr-parse $objaddr} address] != 0} {
    	#
	# Might be patient or thread.
	#
	var colon [string first : $objaddr]
	if {$colon > 0} {
	    var pname [range $objaddr 0 [expr $colon-1] char]
	    var tnum [range $objaddr [expr $colon+1] end char]
    	} elif {$colon == 0} {
	    var pname [patient name]
	    var tnum [range $objaddr 1 end char]
    	} else {
	    var pname $objaddr
	    var tnum 0
    	}
	var patient [patient find $pname]
	
	if {[null $patient]} {
	    error $address
    	}
	foreach t [patient threads $patient] {
	    if {[thread number $t] == $tnum} {
	    	return [list [thread handle $t] 0 {}]
    	    }
    	}
	error [format {thread #%s not known for patient %s} $tnum $pname]
    }
    
    var h [index $address 0]
    if {[handle ismem $h] && [handle owner $h] == $h} {
    	#
	# Process. Fetch handle for first thread, as stored in HM_otherInfo
	# field of the process handle.
	#
	return [list [handle lookup 
	       	      [value fetch kdata:[handle id $h].HM_otherInfo]]
		     0
		     {}]
    } elif {![handle ismem $h]} {
    	return [list $h 0 {}]
    }

    var	seg	    ^h[handle id $h]
    
    [case $objaddr in
    	{^l*
	 \*[de]s:si
	 \*[de]s:di
	 \*[de]s:bx
	 \*[de]s:bp} {
    	    #
	    # Address given contains the chunk handle as its offset portion,
	    # so just use it directly.
	    #
	    var c [string first : $objaddr]
	    var chunk [getvalue [range $objaddr [expr $c+1] end char]]
    	}
	default {
	    if {[index $address 1] == 0} {
		# If address passed is the start of a block, then keep it.
		return $address
	    } else {
		# Otherwise, figure out chunk handle that matches pointer
		# 	passed
		var caddr [index $address 1] hid [handle id [index $address 0]]
		var htable [value fetch $seg:LMBH_offset]
		var nHandles [value fetch $seg:LMBH_nHandles]

		#
		# Allow the passed address to be for a chunk handle, rather than
		# the data to which the thing points, by seeing if the offset
		# falls within the bounds of the handle table for the block.
		#
    	    	[if {($caddr & 1) == 0 &&
		      $caddr >= $htable &&
		      $caddr < $htable+2*$nHandles}
    	    	{
		    return $address
    	    	}]

    	    	#
		# Not a chunk handle, so find the chunk that points to the
		# address.
		#
		[for {var chunk $htable}
		     {$nHandles > 0}
		     {var nHandles [expr $nHandles-1] chunk [expr $chunk+2]}
		{
		    if {[value fetch ^h$hid:$chunk word] == $caddr} {
			break
		    }
		}]
		
		if {$nHandles == 0} {
		    error [format {%s doesn't refer to an lmem chunk} $objaddr]
    	    	}
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
    # If the class is defined in C and we're looking for the instance
    # structure then mangle it around
    #
    var cClass [expr {![string c $suffix Instance] &&
    	    	     ![string c [sym type [sym find any $base]] var]}]
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
	var retVal [format {%s:%s%s}
			[range $base 0 [string first :: $base] chars]
			[range $base [expr [string last :: $base]+2] end chars]
			$suffix]
    } else {
	#
	# Same patient -- just replace the "Class" with "Instance" to form
	# the structure name
	#
	var retVal [range $base
    	    	    	[expr [string last :: $base]+2] end chars]$suffix
    }
    if {$cClass} {
    	# goc(Metaware) puts out 'struct _foo' things, while goc(borland)
    	# puts out 'foo' only for the struct foo things so we will first
    	# look for foo and then look for struct foo
    	var cc [string first :: $retVal]
    	if {$cc != -1} {
            var retVal [format {%s::%s}
    	    	    	    [range $retVal 0 [expr $cc-1] chars]
    	    	    	    [range $retVal [expr $cc+2] end chars]]

    	    if {[null [sym find type $retVal]]} {
                var retVal [format {%s::struct _%s}
    	    	    	    [range $retVal 0 [expr $cc-1] chars]
    	    	    	    [range $retVal [expr $cc+2] end chars]]
    	    }
    	} else {
##          var retVal [format {%s} $retVal]
    	    if {[null [sym find type $retVal]]} {
                var retVal [format {struct _%s} $retVal]
    	    }
    	}
    }
    return $retVal
}]

##############################################################################
#				is-master
##############################################################################
#
# SYNOPSIS:	Determines whether a class is a master class
# PASS:		cs  	    = symbol token for a class
# CALLED BY:	INTERNAL    next-master-callback
#    	    	EXTERNAL    search-var-data-range
# RETURN:	1 if the class is a master class
#    	    	0 otherwise
# SIDE EFFECTS:	
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Broke out of next-master-callback
#
##############################################################################
[defsubr is-master {cs}
{
    if {[string c [sym type $cs] var] == 0} {
        #
        # yech. The class is defined in C and as such we need to actually
	# read things from it, rather than using our beloved symbol table.
	#
	var flags [value fetch [symbol fullname $cs].Class_flags
	    	    [symbol find type geos::ClassFlags]]
	var yesno [field $flags CLASSF_MASTER_CLASS]
    } else {
    	var flag [index [sym get $cs] 3]
	var yesno [expr {[string c $flag master] == 0 ||
			    [string c $flag variant] == 0}]
    }
    return $yesno
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
# STRATEGY:
#   	These functions are twisted. The idea is this:
#	    - $saveNext is set whenever a master class is encountered so
#	      the next class (the bottom-most class in the next master
#	      group) is recorded, as we need to find the Instance structure
#	      that encompasses all the data in that master group.
#   	    - $class is the variable in next-master's context that holds
#	      the symbol token for this bottom-most class whose Instance
#	      structure we need.
#   	    - $skip counts the number of master levels left to skip.
#   	    - $master records the symbol token for the master class that
#	      governs the master group currently being traversed.
#   	So, with this in mind, and knowing that "uplevel 2" in
#	next-master-callback actually manipulates variables in next-master's
#	context, everything should be obvious...
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/12/90		Initial Revision
#
##############################################################################
[defsubr next-master-callback {cs addr}
{
    uplevel 2 [format {
	if {$saveNext} {
	    var class {%s} saveNext 0
	}
    } $cs]

    if {[is-master $cs]} {
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

    #
    # next-master-callback Sets $class to symbol for class above $skip'th master
    # $master is set to the master class immediately above that.
    # obj-foreach-class returns {} if we walk off the class tree.
    #
    if {![null [obj-foreach-class next-master-callback $addr]]} {
	# return actual class name and the Base and Instance types to use
	var className [sym fullname $class]
	return [list $className [obj-name [sym fullname $master] Base] 
				[obj-name $className Instance]]
    }
}]

##############################################################################
#				find-master
##############################################################################
#
# SYNOPSIS:	Finds the specified master class for an object
# PASS:		addr	    = address of object
#   	    	Caller has set $masterName to the name of the desired class.
# CALLED BY:	EXTERNAL   pbasic, pdetail
# RETURN:	if successful, a 3-list of
#    	    	    1	    	= indicates success
#   	    	    $stop	= number of master levels below this
#   	    	    	    	  master class
#   	    	    $master	= 3-list of class name, base structure
#   	    	    	    	  name and instance structure name for
#   	    	    	    	  this master class
#   	    	if unsuccessful, a 3-list of
#   	    	    0	    	= indicates failure
#   	    	    ALL	    	= tells caller to handle all master levels
#   	    	    	    	  if it handles any (pbasic uses this)
#   	    	    $master 	= 3-list of class name, base structure
#   	    	    	    	  name and instance structure name for
#   	    	    	    	  the bottom-most master class
#
# SIDE EFFECTS:
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#   	jenny	7/08/93	    	Initial version
#
##############################################################################
[defsubr find-master {addr masterName}
{
    #
    # stop = the number of master classes next-master should
    #   	 skip before it returns one. If find-master succeeds
    #   	 in finding a match, stop will be the number of master
    #   	 classes below the matched master class.
    #
    var stop 0
    #
    # Look at every master class till we find a match or run out.
    #
    var first [next-master $addr 0]
    [for {var next $first}
         {![null $next]}
         {var next [next-master $addr $stop]} {
    	#
    	# Get the base name (e.g. ui::GenBase) of the next master
    	# class and extract the part between the last "::" and the "Base".
    	#
    	var nextName [index $next 1]
    	var start [expr [string last :: $nextName]+2]
    	if {$start == 1} {
    	    var start 0
    	}
    	var l [length $nextName chars]
    	var nextName [range $nextName $start [expr $l-5] chars]
    	#
    	# Compare the result with the passed master class name.
    	#
    	if {[string c $masterName $nextName] == 0} {
    	    return [list 1 $stop $next]
    	} else {
    	    #
    	    # Nope. We'll look at the next master class.
    	    #
    	    var stop [expr {$stop + 1}]
    	}
    }]
    #
    # No match. 
    #
    return [list 0 ALL $first]
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
[defcommand fetch-optr {bl off} swat_prog.ui
{Usage:
    fetch-optr <handle> <offset>

Examples:
    "fetch-optr $h $o.GI_comp.CP_firstChild"
    	    	    	    Fetch the optr from the GI_comp.CP_firstChild
			    field of the object at ^h$h:$o.
    	    	    	    	

Synopsis:
    Extracts an optr from memory, coping with the data in the block that
    holds the optr not having been relocated yet.

Notes:
    * <offset> is an actual offset, not a chunk handle, while <handle> is
      a handle ID, not a handle token.

    * Returns a two-list {<handle> <chunk>}, where <handle> is the handle
      ID from the optr, and <chunk> is the chunk handle (low word) from the
      optr.

    * We decide whether to relocate the optr ourselves based on
      the LMF_RELOCATED bit in the LMBH_flags field of the block's
      header. There are times, e.g. during the call to MSG_META_RELOCATE for
      an object, when this bit doesn't accurately reflect the state of the
      class pointer and we will return an error when we should not.

See also:
    comma-separated list of related commands
}
{
    #
    # Fetch the two pieces first
    #
    var chunk [value fetch ^h$bl:$off.chunk]
    var han [value fetch ^h$bl:$off.handle]
			    
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
    var off [value fetch {((void _far * _near *)($core.GH_exportLibTabOff))[$entry].offset}]
    var seg [value fetch {((void _far * _near *)($core.GH_exportLibTabOff))[$entry].segment}]
    
    if {$seg < 0x1000} {
    	return [symbol faddr var ^h[expr $seg<<4]:$off]
    } else {
    	return [symbol faddr var $seg:$off]
    }
}]

[defcommand obj-class {obj} swat_prog.ui
{Usage:
    obj-class <object>

Examples:
    "var cs [obj-class ^lbx:si]"	Store the symbol token for the class
					of the object ^lbx:si in the variable
					$cs.

Synopsis:
    Figures out the class of an object, coping with unrelocated object
    blocks and the like.

Notes:
    * The value return is a symbol token, as one would pass to the "symbol"
      command. Using "symbol name" or "symbol fullname" you can obtain the
      actual class name.

    * We decide whether to relocate the class pointer ourselves based on
      the LMF_RELOCATED bit in the LMBH_flags field of the object block's
      header. There are times, e.g. during the call to MSG_META_RELOCATE for
      an object, when this bit doesn't accurately reflect the state of the
      class pointer and we will return an error when we should not.

See also:
    symbol.
}
{
    #
    # Figure the handle of the object by parsing its address
    #
    var a [addr-parse $obj]
    var hid [handle id [index $a 0]]
    [if {(([handle state [index $a 0]] & 0xc0) == 0x40) ||
	 [string c [type emap
		    [value fetch ^h$hid:LMBH_lmemType]
		    [if {[not-1x-branch]} 
			{symbol find type LMemType}
			{symbol find type LMemTypes}]]
		   LMEM_TYPE_OBJ_BLOCK] != 0}
    {
	# Block's not an object block, or is discarded non-resource, so thing
	# can't have a class (or at least we can't figure it out :).
	return {}
    } elif {[field [value fetch ^h$hid:LMBH_flags] LMF_RELOCATED]} {
    	# Block's been relocated, so we can find the symbol token for that class
	# easily.
    	return [symbol faddr var *($obj).MB_class]
    } else {
    	#
    	# Unrelocate the class pointer. The low word contains the relocation
	# information that tells from whence the class pointer comes, while the
	# high word contains the exported entry number.
	#
	var rel [value fetch ($obj).MB_class.offset]
    	var entry [value fetch ($obj).MB_class.segment]
	var patient [handle patient [index $a 0]]
	if {[string c [patient name $patient] geos] == 0} {
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
	    {1 6} {
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
    	    	global geos-release
		if {${geos-release} >= 2} {
		    var lcore [value fetch 
		    	       {((word _near *)($core.GH_libOffset))[$rel&0xfff]}]
		    var patient [handle patient [handle lookup $lcore]]
    	    	} else {
		    var lseg [value fetch 
			      {((word _near *)($core.GH_libOffset))[$rel&0xfff]}]
		    var patient [handle patient [handle find $lseg:0]]
    	    	}
		return [map-entry-num-to-sym $patient $entry]
    	    }
	    default {
	    	error [format {Unhandled relocation type %d} 
		    	[expr ($rel>>12)&0xf]]
    	    }
    	]
    }]
}]


[defcommand print-method-table {class {meth {}}} object.message
{Usage:
    print-method-table <class> [method_number_or_name_pattern]

Examples:
    "print-method-table ui::VisClass"	Print out the messages handled by
					VisClass and the methods that handle
					them.
    print-method-table GenApplicationClass MSG_META_ICAP_*
    	    	    	    	    	Prints out all methods for messages
    	    	    	    	    	whose name starts out MSG_META_ICAP_
    print-method-table GenApplicatoinClass 987
    	    	    	    	    	Prints out the methods handler for
    	    	    	    	    	message 987 for GenApplicationClass
    	    	    	    	    	if there is one
Synopsis:
    Prints out the table for a class that maps messages to methods.

Notes:

See also:
    obj-find-method
}
{
    var methodcount [value fetch $class.Class_methodCount]
    for {var i 0} {$i < $methodcount} {var i [expr $i+1]} {
	var method [value fetch {$class.Class_methodTable[$i]}]
	var ptr [value fetch {((dword *)&$class.Class_methodTable[$methodcount])[$i]}]
	var low [expr $ptr&0xffff]
	var high [expr ($ptr>>16)&0xffff]
	if {$high > 0xf000} {
            var seg [format ^h%04xh [expr {($high-0xf000)<<4}]]
	} else {
	    var seg [format %04xh $high]
	}
	var label [value hstore [addr-parse $seg:$low]]
	var s [sym faddr func {$seg:$low}]

        if {![null $meth]} {
    	    if {$meth != $method} {
    	    	if {[string match [map-method $method $class] $meth] == 0} {
        	    	continue
     	    	}
    	    }
    	}

	if {![null $s]} {
	   var label [value hstore [addr-parse $seg:$low]]
	   var offset [expr $low-[sym addr $s]]
	   if {$offset} {
	       echo [format {%35s	(@%d), %s+%1d}
			[map-method $method $class]
			$label
			[sym name $s]
			$offset
		]
	   } else {
	       echo [format {%35s	(@%d), %s}
			[map-method $method $class]
			$label
			[sym name $s]
		]
	   }
	} else {
	   echo [format {%35s	(@%d), %s:%04xh}
			[map-method $method $class]
			$label
			$seg $low
		]
	}
    }
}]

##############################################################################
#				isclassptr
##############################################################################
#
# SYNOPSIS:	Return if the ptr is a class ptr or an OD
# PASS:		$ptr - ptr to check
# RETURN:	TRUE if is a pointer to a class and not an OD
#
# STRATEGY:
#   See if an OD is actually a far pointer, which means this is a
#   classed event rather than a regular event.  Our guess for whether
#   this is the case is if the offset of the symbol at the fptr matches
#   the offset of the fptr, which probably means the thing is a far pointer
#   to a class.  And of course, since classed events didn't exist prior
#   to V2.0, we can bail early if this isn't V2.0 or later.
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	10/11/90	Initial Revision
#
##############################################################################

[defsubr isclassptr {ptr}
{
    global geos-release
    #
    # Set various variables that will be needed.
    #
    if {${geos-release} >= 2} {
	var symb [symbol faddr var $ptr]
        if {![null $symb]} {
	    return [expr {
		([symbol addr $symb] == [index [addr-parse $ptr] 1]) &&
		[string match [type name [index [symbol get $symb] 2] {} 0]
			      *ClassStruct*]
	    }]
        }
    }
    return 0
}]

##############################################################################
#				omfq
##############################################################################
#
# SYNOPSIS:	    Helpful function to send a message with arbitrary data
#   	    	    to an object on its event queue.
# PASS:		    meth    = message # to send (likely a MSG_* constant)
#   	    	    obj	    = object to receive the message (^lbx:si, for
#			      example)
#   	    	    args    = pairs of arguments giving values for cx, dx and
#			      bp. ("dl VUM_MANUAL" might be 1 such pair)
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 1/92		Initial Revision
#
##############################################################################
[defcommand omfq {meth obj args} object.message
{Usage:
    omfq <message> <object> <args>*

Examples:
    "omfq MSG_META_QUIT *HelloApp"	Sends MSG_META_QUIT to the *HelloApp
					object.

Synopsis:
    Forces a message for an object onto its event queue.

Notes:
    * This command calls ObjMessage, passing it di=mask MF_FORCE_QUEUE.
    
    * <args> is the set of additional parameters to pass to ObjMessage. It
      consists of <variable/register> <value> pairs, which are passed to the
      "assign" command. As a special case, if the variable is "push", the
      value (a word) is pushed onto the stack and is popped when the message
      has been queued.

    * The registers active before you issued this command are always restored,
      regardless of whether the call to ObjMessage completes successfully.
      This is in contrast to the "call" command, which leaves you where ever
      the machine stopped with the previous state lost.

See also:
    call.
}
{
    var a [get-chunk-addr-from-obj-addr $obj]

    var curPat [patient name]
    var curThread [read-reg curThread]
    sw [patient name [handle patient [handle lookup $curThread]]]

    [if {![eval [concat call-patient ObjMessage
    	    ax [getvalue $meth]
	    bx [handle id [index $a 0]]
	    si [index $a 1]
	    di [fieldmask MF_FORCE_QUEUE] $args]]}
    {
    	echo [format {couldn't send %s to %s} $meth $obj]
    	restore-state
    	break
    } else {
    	restore-state
    }]

    sw $curPat
}]


##############################################################################
#				obj-find-method
##############################################################################
#
# SYNOPSIS:	Locate the method that will handle a message for a particular
#		object or class.
# PASS:		msg 	    = message number or name
#   	    	obj 	    = address of object or class
#   	    	[wantsym]   = non-zero if called from a program that wants
#			      the symbol token of the method, rather than
#			      the normal verbose message the user wants
#			      to see
# CALLED BY:	user/EXTERNAL
# RETURN:	if $wantsym not given, returns the full name of the method
#		    and the class for which it is defined (or "none" if the
#		    message isn't handled by any method)
#   	    	else returns the symbol token for the method ({} if no
#		    method will field the message)
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/29/92		Initial Revision
#
##############################################################################
[defsubr obj-find-method-callback {class obj msg wantsym}
{
    addr-preprocess [symbol fullname $class] seg off
    
    [for {var n [value fetch $seg:$off.Class_methodCount] i 0}
	 {$n > 0}
	 {var n [expr $n-1] i [expr $i+1]}
    {
    	if {[value fetch {$seg:$off.Class_methodTable[$i]}] == $msg} {
	    var a [value fetch {((byte *)&$seg:$off.Class_methodTable[$seg:$off.Class_methodCount])+$i*4} [type dword]]
	    break
    	}
    }]
    if {![null $a]} {
        var s [expr ($a>>16)&0xffff] o [expr $a&0xffff]
        if {$s >= 0xf000} {
            var s [format {^h%04xh} [expr ($s&0xfff)<<4]]
        } else {
	    var s [format %04xh $s]
    	}

	var handler [symbol faddr proc $s:$o]
	if {![null $handler]} {
	    if {$wantsym} {
	    	return $handler
    	    } else {
		return [format {%s for %s} [symbol fullname $handler]
				[symbol fullname $class]]
    	    }
    	} elif {!$wantsym} {
	    return [format {%s:%04xh for %s} $s $o [symbol fullname $class]]
    	}
    }
}]

[defcommand obj-find-method {msg obj {wantsym 0}} {object.message swat_prog.ui}
{Usage:
    obj-find-method <message> <object/class> [<wantsym>]

Examples:
    "obj-find-method MSG_META_DETACH ^lbx:si"
    	    	    	    Locates the method that would be executed if you
			    were to send MSG_META_DETACH to the object at
			    ^lbx:si
    "obj-find-method 4 VisCompClass 1"
    	    	    	    Returns the symbol token of the method that fields
			    message number 4 for VisCompClass.

Synopsis:
    Finds the method that will be executed if a particular message is sent
    to a particular object or class.

Notes:
    * If this encounters a variant class on its way up the class tree, and
      you've given only an object class, or an object that's not been built
      past that variant, it will indicate there's no method for the message,
      even if there's a default method for the message in MetaClass.

See also:
    obj-foreach-class, stop.
}
{
    var result [obj-foreach-class obj-find-method-callback $obj [getvalue $msg]
    	    	    $wantsym]
    if {[null $result]} {
    	if {$wantsym} {
	    return {}
    	} else {
    	    return none
    	}
    } else {
    	return $result
    }
}]

