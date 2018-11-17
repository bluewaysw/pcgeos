##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	whatis.tcl
# FILE: 	whatis.tcl
# AUTHOR: 	Adam de Boor, Dec  3, 1991
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	pscope	    	    	Print out all the symbols in a particular scope
#   	print-sym   	    	Print a human-readable description of a symbol
#				given its token.
#   	whatis	    	    	Print a human-readable description of a symbol
#				given its name.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
# DESCRIPTION:
#	Useful functions for interrogating symbol tables.
#
#	$Id: whatis.tcl,v 1.10 94/11/10 14:00:27 adam Exp $
#
###############################################################################

##############################################################################
#				pscope
##############################################################################
#
# SYNOPSIS:	    Print out all the symbols in a given scope.
# PASS:		    [name]  = the name of the scope. "." to print the current
#			      scope (also the default), or ".." to print the
#			      parent scope.
# CALLED BY:	    user
# RETURN:	    nothing
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
##############################################################################
[defcommand pscope {{name .} {class any}} print
{Usage:
    pscope [<scope-name> [<sym-class>]]

Examples:
    "pscope WinOpen"	Prints out all the local labels, variables, and
			arguments within the WinOpen procedure

Synopsis:
    This prints out all the symbols contained in a particular scope.

Notes:
    * This can be useful when you want to know just the fields in a structure,
      and not the fields within those fields, or if you know the segment in
      which a variable lies, but not its name. Admittedly, this could be
      overkill.

    * <sym-class> can be a list of symbol classes to restrict the output. For
      example, "pscope Filemisc proc" will print out all the procedures within
      the Filemisc resource.

See also:
    whatis.
}
{
    if {[string c $name .] == 0} {
	var scope [symbol find scope [frame scope]]
    } elif {[string c $name ..] == 0} {
	var scope [symbol scope [symbol find scope [frame scope]] 1]
    } else {
	var scope [symbol find scope $name]
    }

    if {[null $scope]} {
    	error [format {%s: no such scope defined} $name]
    }
    symbol foreach $scope $class print-sym
}]

##############################################################################
#				whatis-look-in-scope-chain
##############################################################################
#
# SYNOPSIS:	    Look for a symbol in the scopes from the passed to the
#		    global one, just as addr-parse does.
# PASS:		    name    = name of symbol for which to search
#   	    	    scope   = full name of scope in which to start
# CALLED BY:	    whatis
# RETURN:	    symbol token, if found
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 4/91	Initial Revision
#
##############################################################################
[defsubr whatis-look-in-scope-chain {name scope}
{
    var ssym [symbol find scope $scope]
    if {[null $ssym]} {
    	error [format {%s: no such scope defined} $scope]
    }

    while {[string c [symbol type $ssym] module] != 0} {
    	var sym [symbol find any $name $ssym]
	if {![null $sym]} {
	    return $sym
	}
	var ssym [symbol scope $ssym 1]
    }
    return nil
}]

##############################################################################
#				whatis
##############################################################################
#
# SYNOPSIS:	    Tell the user what the type of an expression is, or
#		    what a particular symbol is, given its name.
# PASS:		    name    = name of the symbol to print
# CALLED BY:	    user
# RETURN:	    nothing
# SIDE EFFECTS:	    ?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
##############################################################################
[defcmd whatis {addr} top.print
{Usage:
    whatis (<symbol-name>|<addr>)

Examples:
    "whatis WinColorFlags"	Print a complete description of the record
				WinColorFlags

Synopsis:
    This produces a human-readable description of a symbol, giving whatever
    information is pertinent to its type.

Notes:
    * For type symbols (e.g. structures and enumerated types), the description
      of the type is fully displayed, so if a structure has a field with an
      enumerated type, all the members of the enumerated type will be
      printed as well. Also all fields of nested structures will be printed.
      If this level of detail isn't what you need, use the "pscope" command
      instead.

    * It isn't clear why you'd need the ability to find the type of
      an address-expression, since those types always come from some symbol
      or other, but if you want to type more, you certainly may.

See also:
    pscope
}
{
    if {[catch {frame cur} cur] == 0 && ![null $cur] && ![null [frame scope]]} {
    	var sym [whatis-look-in-scope-chain $addr [frame scope]]
    }
    
    if {[null $sym] && ![null [scope]]} {
    	var sym [whatis-look-in-scope-chain $addr [scope]]
    }
    
    if {[null $sym]} {
    	var sym [symbol find any $addr]
    }
    
    if {[null $sym]} {
    	var a [addr-parse $addr]
	if {![null [index $a 2]]} {
	    echo [type name [index $a 2] $addr 1]
    	} else {
	    error {Expression has no known type}
    	}
    } else {
    	print-sym $sym
    }
}]

##############################################################################
#				print-sym
##############################################################################
#
# SYNOPSIS:	    Print a human-readable description of a symbol
# PASS:		    sym	    = token of symbol to print
# CALLED BY:	    whatis, pscope (via symbol foreach)
# RETURN:	    0 (continue iterating)
# SIDE EFFECTS:	    stuff be printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 3/91	Initial Revision
#
##############################################################################
[defsubr print-sym {sym}
{
    [case [symbol class $sym] in
     {var locvar} {
     	var data [symbol get $sym]
	echo -n [format {%s, }
	    	 [if {[null [index $data 2]]} {
	    	    symbol fullname $sym
    	    	 } else {
		    type name [index $data 2] [symbol fullname $sym] 0
    	    	 }]]
	[case [index $data 1] in
	 {static lmem} {echo [format {at %04xh} [index $data 0]]}
	 local {echo [format {local %d from bp} [index $data 0]]}
	 param {echo [format {parameter %d from bp} [index $data 0]]}
	 reg {
    	    global regnums
	    
	    var rnum [index $data 0]
	    foreach r $regnums {
	    	if {[index $r 1] == $rnum} {
		    echo -n [format {register %s} [index $r 0]]
		    break
    	    	}
    	    }
	    echo
    	 }
    	]
     }
     module {
     	var resid 0
	foreach res [patient resources [symbol patient $sym]] {
	    if {[string c $sym [handle other $res]] == 0} {
	    	break
    	    }
	    var resid [expr $resid+1]
    	}
	echo [format {module %s: handle %04xh (at %04xh:0), resid %d}
	    	[symbol name $sym]
		[handle id $res]
		[handle segment $res]
		$resid]
     }
     proc {
     	var data [symbol get $sym]
	echo [format {%s at %04xh}
	    	[type name
		 [index $data 2]
	    	 [concat _[index $data 1]
		  [symbol fullname $sym]()] 0]
		[index $data 0]]
     }
     label {
     	var data [symbol get $sym]
	echo [format {_%s %s at %04xh} [index $data 1]
	    	[symbol fullname $sym] [index $data 0]]
     }
     type {
     	echo typedef [type name $sym [symbol fullname $sym] 1]
     }
     field {
     	var data [symbol get $sym]
	if {[index $data 0] & 7} {
	    echo [format {field %s at offset %d.%d (%d bits wide) in %s}
	    	    [type name [index $data 2] [symbol fullname $sym] 0]
		    [expr [index $data 0]/8]
		    [expr [index $data 0]&7]
		    [index $data 1]
		    [type name [index $data 3] {} 0]]
    	} else {
	    echo [format {field %s at offset %d (%d bits wide) in %s}
	    	    [type name [index $data 2] [symbol fullname $sym] 0]
		    [expr [index $data 0]/8]
		    [index $data 1]
		    [type name [index $data 3] {} 0]]
    	}
     }
     enum {
     	var data [symbol get $sym]
	echo [format {enum %s, value %d in %s} [symbol fullname $sym]
	    	[index $data 0]
		[type name [index $data 1] {} 0]]
     }
     {abs const} {
     	echo [format {absolute %s = %d} [symbol fullname $sym]
	    	[symbol get $sym]]
     }
     scope {
     	echo [format {scope %s, starting at %04xh} [symbol fullname $sym]
	    	[symbol get $sym]]
     }
     profile {
     	echo [format {profile mark (type %d) at %04xh}
	    	[index [symbol get $sym] 1] [symbol addr $sym]]
     }
     default {echo ??? [symbol fullname $sym]}
    ]
    
    return 0
}]
