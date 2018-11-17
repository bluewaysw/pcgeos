##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System library
# FILE: 	objprof.tcl
# AUTHOR: 	John Wedgwood, 10/02/90
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	obj-prof  	    	Show object and method calls, indented
#   	    	    	    	nicely so you can see what's going on.
#				between cs:ip and given address.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw 	10/ 2/90    	Initial revision.
#
# DESCRIPTION:
#
#	$Id: objprof.tcl,v 1.12.30.1 97/03/29 11:26:43 canavese Exp $
#
###############################################################################

#Show ObjMessage, and ObjCall* calls indented nicely so you can see what is
#going on. When an ObjMessage call is encountered where the flags passed
#contain MF_CALL, the current thread is frozen so that the method can be
#delivered before the ObjMessage call returns.

require remove-brk showcall
require obj-class object

[defsubr obj-prof {args}
{
    # Set the breakpoints and make a list of them so we can delete them later.
    global oi_brk_list oi_indent_list patient_list

    if {[null $args]} {
    	#remove breakpoints
	remove-brk oi_brk_list
	var oi_brk_list {}
	return 0
    }
    
    var oi_brk_list [list
    	    	    	[brk ObjMessage oi-om]
    	    	    	[brk ObjCallInstanceNoLock oi-ocinl]
			[brk ObjCallInstanceNoLockES oi-ocinles]
			[brk ObjCallClassNoLock oi-occnl]
			[brk ObjCallSuperNoLock oi-ocsnl]
			[brk CallMethodCommon+18 oi-end-call]
			[brk OM_doRet oi-end-call]
			[brk SM_fullyDiscarded+5 oi-om-discarded]
			[brk SM_fixupNone oi-end-call]
			[brk SM_fixupDS oi-end-call]
			[brk SM_fixupDSES oi-end-call]
			[brk OM_SE_exit oi-end-call]
			[brk OM_SE_afterLink+31 oi-end-call]
			[brk OM_SE_customRemoteWait+9 oi-end-call]
			]

    var patient_list $args
    var oi_indent_list {}
    foreach i $args {
    	var oi_indent_list [concat 0 $oi_indent_list]
    }
}]

#
# Calls types are denoted by the arrow between the method and the class:
#   ObjMessage	    	    -m>
#   ObjCallInstanceNoLock   -i>
#   ObjCallInstanceNoLockES -e>
#   ObjCallClassNoLock	    -c>
#   ObjCallSuperNoLock	    -s>
#

[defsubr oi-om {}
{
    # Check to see if the block is discarded. If it is, just wait, when
    # the code gets to SendMessage() the block will be loaded again.
    
    if {[read-reg bx] != 0} {
        var han [value fetch kdata:[read-reg bx] HandleMem]
    	if {[field $han HM_addr]<0xf000} {
            # is a memory block handle
	    if {[field [field $han HM_flags] HF_DISCARDED]} {
	    	# discarded block, don't echo anything now
	    } else {
    	    	oi-print-method ObjMessage {^l} bx si {^lbx:si} {} {-m>}
	    }
    	}
    }
    return 0
}]

[defsubr oi-om-discarded {}
{
    oi-print-method ObjMessage {^l} bx si {^lbx:si} {} {-m>}
    return 0
}]

[defsubr oi-ocinl {}
{
    oi-print-method ObjCallInstanceNoLock {*} ds si {*ds:si} {} {-i>}
    return 0
}]

[defsubr oi-ocinles {}
{
    oi-print-method ObjCallInstanceNoLockES {*} ds si {*ds:si} {} {-e>}
    return 0
}]

[defsubr oi-occnl {}
{
    oi-print-method ObjCallClassNoLock {*} ds si {*ds:si} {es:di} {-c>}
    return 0
}]

[defsubr oi-ocsnl {}
{
    oi-print-method ObjCallSuperNoLock {*} ds si {*ds:si} {es:di} {-s>}
    return 0
}]

[defsubr find-patient {}
{
    global oi_indent_list patient_list
    var cur_patient [patient name]

    var idx 0

    foreach i $patient_list {
    	if {[string c $i $cur_patient] == 0} {
	    break
	}
	var idx [expr $idx+1]
    }
    # idx == the index where we can find the patients information.
    if {$idx>[length patient_list]} {
	# Don't know this patient...
        return -1
    }
    return $idx
}]

[defsubr adjust-indent {idx val}
{
    global oi_indent_list
    
    var len [length $oi_indent_list]

    if {$idx == 0} {
    	if {$len > 1} {
    	    var oi_indent_list [concat [list $val]
    	    	    	    	       [range $oi_indent_list 1 end]]
    	} else {
    	    var oi_indent_list [list $val]
    	}
    } elif {$idx >= $len} {
    	error {index out of bounds}
    } elif {$idx == [expr $len-1]} {
    	var oi_indent_list [concat [range $oi_indent_list
	    	    	    	    	  0
					  [expr $len-2]]
				   [list $val]]
    } else {
        var oi_indent_list [concat [range $oi_indent_list
	    	    	    	    	  0
					  [expr $idx-1]]
				   [list $val]
				   [range $oi_indent_list [expr $idx+1] end]]
    }
}]

[defsubr oi-end-call {}
{
    global oi_indent_list
    
    var patient_num [find-patient]
    
    if {$patient_num != -1} {
        var cur_indent [index $oi_indent_list $patient_num]
        if {$cur_indent <= 0} {
            var cur_indent [index $oi_indent_list $patient_num]
            echo [format {<%s> Returning from %s:%s.} [patient name]
	    	    	    [sym name [sym faddr scope cs:ip]]
			    [index [unassemble [get-address cs:ip]] 0]]
	    return 0
        }
        # decrement $patient_num'th element of the oi_indent_list.
	adjust-indent $patient_num [expr $cur_indent-1]
    } else {
        echo {*** End call, unknown patient}
    }
    return 0
}]

[defsubr oi-print-method {routine mod reg1 reg2 obj class arrow} {
    global oi_indent_list

    var patient_num [find-patient]
    var moniker {}

    if {$patient_num == -1} {
    	# We don't know this patient
	echo {*** Call, unknown patient ***}
	return {}
    }

    var cur_indent [index $oi_indent_list $patient_num]
    
    adjust-indent $patient_num [expr $cur_indent+1]
    
    if {$cur_indent < 0} {
    	var cur_indent 0
    }

    echo -n [format {%*s} $cur_indent {}]
    echo -n [format {<%s> } [patient name]]

    #
    # if reg1 is a handle and that handle is a thread then 
    # we want to use the class for the process we are sending the
    # event to.
    #
    var reg1val [read-reg $reg1]
    var h [handle lookup $reg1val]
    if {![null $h]} {
	# It is a handle
	var han [value fetch kdata:$reg1val HandleQueue]
	var type [field $han HQ_handleSig]
	if {$type==0xf4} {
	    #A queue handle. Get the thread field.
	    var h [handle lookup [field $han HQ_thread]]
	}
	if {$reg1val == [field $han HQ_owner]} {
	    # sending a method to a geode.
	    # we could check to see if it is a process... nah.
	    # the class we want is the class of the first thread...
	    # if we just get the first threads handle into 'h' 
	    # we can fall thru and get the class.
	    var h [handle lookup [value fetch (^h$reg1val).PH_firstThread]]
	    if {[null $h]} {
		if {[null $class]} {
		    var class {ProcessClass}
		}
	    }
	    var obj {}
	}
	if {[handle isthread $h]} {
	    var ss [value fetch kdata:[handle id $h].HT_saveSS]
	    var s [sym faddr var *$ss:TPD_classPointer] obj {}
	    if {[null $class]} {
		# if class isn't defined, define it now.
		var class [sym fullname $s]
	    }
	    var obj {}
	}
    }

    # the default.
    var method [read-reg ax]
    
    if {[null $obj]} {
	# there is no object, the method was intended for either a
	# process or a thread. Luckily the class is already set.
    } elif {[null $class]} {
	# there is an object but there is no class.
	var class [obj-class $obj]
	if {![null $class]} {
	    # Get the class name.
	    var class [sym fullname $class]
	}
    } else {
	# there is an object, but the class is already defined (as in the
	# case of ObjCallClassNoLock). We need a class name.
	var s [sym faddr var $class]
	if {![null $s]} {
	    # Well... we have a symbol, assume it is the class
	    var class [sym fullname $s]
	}
    }
    # Well here we are.
    # $obj contains the object (possibly null in the case of a thread).
    # $class contains the class name (possibly null if it is unknown).

    # $obj may be garbage if this is a call to another class.
    # In this case we need to double check $obj... The way I do this is
    # to fetch the first dword of $obj and make sure it is a class.
    
    # All this is necessary because you can do an ObjCallSuper and an
    # ObjCallClass with a thread. In this case there is no object, but we
    # don't really know that yet...

    if {![null $obj]} {
	var oco [value fetch $obj   word]
	var ocs [value fetch ($obj)+2 word]
	# $ocs:$oco is the address of the objects class
	var s [sym faddr var $ocs:$oco]
	if {[null $s]} {
	    # no variable there...
	    var obj {}
	} else {
	    # found something.
	    # if we do an addr-parse on the symbol we found
	    # we should get the same thing as if we did
	    # an addr-parse on the address we looked up.

	    var apc [addr-parse $ocs:$oco]
	    var apr [addr-parse [sym fullname $s]]
	    if {[index $apc 0] != [index $apr 0]} {
		var obj {}
	    } elif {[index $apc 1] != [index $apr 1]} {
		var obj {}
	    }
	}
    }

    if {[null $class]} {
	# Use the routine name.
	var class $routine
    } else {
	# Map the method.
	var method [map-method $method $class $obj]
	
	# Get the short name.
	var class [sym name [sym faddr var $class]]
	
	if {[string c $method {class unknown}] == 0} {
	    var method [read-reg ax]
	}
    }

    # Hack to get the right class printed.
    if {[string c $class NameParallelPort] == 0} {
    	var class SpoolPrintControlClass
    }
    
    # convert MSG_FOO to just FOO to shorten the output.
    if {[string match $method MSG_*]} {
	var method [range $method 7 end chars]
    }

    # if we are doing a VUP query, figure out what the query is.
    if {[string match $method VUP_QUERY*]} {
    	# cx holds the query type.
	var query [read-reg cx]
	var s [sym find type ui::VisUpwardQueryType]

	if {[null $s]} {
	    error {Can't find ui::VisUpwardQueryType}
	} else {
	    var q [type emap $query $s]
	    if {[null $q] || [string match $q SPEC_VIS_QUERY_START]} {
		# try again with SpecVisQueryTypes
		var s [sym find type motif::SpecVisQueryTypes]
		if {[null $s]} {
		    error {Can't find motif::SpecVisQueryTypes}
		} else {
		    var q [type emap $query $s]
		    if {[null $q]} {
	    	    	var method [format {%s(%04xh)} $method $query]
    	    	    } else {
		    	var method [format {%s(%s)} $method
    	    	    	    	    	    	    [range $q 5 end chars]]
		    }
		}
	    } else {
		# found under VisUpwardQueryType
    	    	var method [format {%s(%s)} $method [range $q 4 end chars]]
    	    }
	}
    }
    
    # if we are doing a GUP query, figure out what the query is.
    if {[string match $method GUP_QUERY*]} {
    	# cx holds the query type.
	var query [read-reg cx]
	var s [sym find type ui::GenUpwardQueryType]

	if {[null $s]} {
	    error {Can't find ui::GenUpwardQueryType}
	} else {
	    var q [type emap $query $s]
	    if {[null $q] || [string match $q SPEC_GEN_QUERY_START]} {
	    	# try again with motif::SpecGenUpwardQueryTypes
		var s [sym find type motif::SpecGenQueryTypes]
		if {[null $s]} {
		    error {Can't find motif::SpecGenQueryTypes}
		} else {
		    var q [type emap $query $s]
		    if {[null $q]} {
	    	    	var method [format {%s(%04xh)} $method $query]
    	    	    } else {
		    	var method [format {%s(%s)} $method
			    	    	    	    [range $q 5 end chars]]
		    }
		}
	    } else {
	    	var method [format {%s(%s)} $method [range $q 5 end chars]]
    	    }
	}
    }

    if {![null $obj]} {
	var moniker [oi-pvm $obj]
	if {[null $moniker]} {
	    echo [format {%s %s %s(%s%04xh:%04xh)}
	    	    	    	$method
				$arrow
	    	    	    	$class
				$mod
				[read-reg $reg1]
				[read-reg $reg2]]
	} else {
	    echo [format {%s %s %s (%s%04xh:%04xh, %s)}
	    	    	    	$method
				$arrow
				$class
				$mod
				[read-reg $reg1]
				[read-reg $reg2]
				$moniker]
	}
    } else {
	# method sent to thread or process
	echo [format {%s %s %s (Thread)}
    	    	    	    	$method
				$arrow
				$class]
    }
}]

[defsubr oi-pvm {address}
{
    var addr [addr-parse $address]
# Get segment and offset into separate vars
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]

    if {$off & 1} {
	return {}
    }
    var gboffset [value fetch $seg:$off.ui::Gen_offset]
    var off [expr $off+$gboffset]
    var off [value fetch $seg:$off.ui::GI_visMoniker word]
    if {$off & 1} {
        return {}
    }
    return [oi-pvismon *$seg:$off]
}]

[defsubr oi-pvismon {address}
{
    var addr [addr-parse $address]
# Get segment and offset into separate vars
    if {[null [index $addr 0]]} {
    	return {}
    }

    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
# Print associated graphics string
    var type [value fetch $seg:$off.VM_type VisMonikerType]

    if {[field $type VMT_MONIKER_LIST] != 0} {
#	echo is moniker list
    	return {}
    }
    if {[field $type VMT_GSTRING] != 0} {
#	echo is gstring
        return {}
    }
    if {[null [field $type VMT_GS_COLOR]]} {
#    	echo no color
        return {}
    }
    return [oi-pstring $seg:$off.VM_data.VMT_text]
}]

[defsubr oi-pstring addr {
    var a [addr-parse $addr]
    var ret {}
    
    if {![null [index $a 0]]} {
	var s [handle segment [index $a 0]]
	var o [index $a 1]

	[for {var c [value fetch $s:$o [type byte]]}
	     {$c != 0}
	     {var c [value fetch $s:$o [type byte]]}
	{
	    if {$c>0x7f} {
		var ret {}
		break
	    } elif {$c<0x20} {
	    	var ret {}
	    	break
	    }
	    var ret $ret[format %c $c]
	    var o [expr $o+1]
	}]
    }
    return $ret
}]
