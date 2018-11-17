##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	lisp.tcl
# AUTHOR: 	Adam de Boor, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	cons			Create a new list, as in lisp
#   	assoc	    	    	Find a value in an assoc list
#   	car 	    	    	Return the first element of a list
#   	cdr 	    	    	Return the rest of a list
#   	aset	    	    	Set an element of an array
#   	delassoc    	    	Delete an element of an assoc list
#       member                  Return 1 if an element is found in a list
#       remove                  Remove all instance of an element from a list
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Lisp-like commands
#
#	$Id: lisp.tcl,v 3.11.3.1 97/03/29 11:27:27 canavese Exp $
#
###############################################################################

[defcommand cons {elt list} {swat_prog.list swat_prog.lisp}
{Usage:
    cons <element> <list>

Examples:
    "var alist [cons {a b} $alist]"	Adds {a b} to the front of $alist

Synopsis:
    Returns the list consisting of <element> added to the front of <list>.

Notes:
    * For technical reasons, it is difficult to cons a list of one element
      onto another list. If you want to do this, you must do:
        concat {{a}} $letters
      If you want a variable in place of a, use:
	concat [format {{%s}} $a] $letters

See also:
    car, cdr.
}
 {
     return [concat [list $elt] $list]
 }]

[defcommand assoc {list key} {swat_prog.list swat_prog.lisp}
{Usage:
    assoc <list> <key>

Examples:
    "assoc $classes GenPrimaryClass"	Examines the sublists of $classes
    	    	    	    	    	and returns the first one whose first
					element is the string GenPrimaryClass

Synopsis:
    Searches an associative list to find an element with a particular key.
    The list is made of sublists, each of whose first element is the key
    for accessing the value that is the rest of each sublist.

Notes:
    * A typical associative list is made of key/value pairs, like this:
    	{{<key> <value>} {<key> <value>} ...}

    * If an element is found whose <key> matches the passed <key>, the
      entire element is returned as the result. If no <key> matches, nil
      is returned.

See also:
    car, cdr, range, list, delassoc.
}
{
    foreach i $list {
    	if {[string c $key [index $i 0]] == 0} {
    	    return $i
    	}
    }
    return nil
}]

[defcommand car {list} {swat_prog.list swat_prog.lisp}
{Usage:
    car <list>

Examples:
    "car $args"	    Returns the first element of $args

Synopsis:
    Returns the first element of a list.

Notes:
    * This is a lisp-ism for those most comfortable with that language. It
      can be more-efficiently implemented by saying [index <list> 0]

See also:
    cdr
}
{
    return [index $list 0]
}]

[defcommand cdr {list} {swat_prog.list swat_prog.lisp}
{Usage:
    cdr <list>

Examples:
    "cdr $args"	    Returns the remaining arguments yet to be processed

Synopsis:
    Returns all but the the first element of a list.

Notes:
    * This is a lisp-ism for those most comfortable with that language. It
      can be more-efficiently implemented by saying [range <list> 1 end]

See also:
    car
}
{
    return [range $list 1 end]
}]

[defcommand aset {array ind val} swat_prog.lisp
{Usage:
    aset <array-name> <index> <value>

Examples:
    "aset foo $i $n"	Sets the $i'th element (counting from 0) of the value
    	    	    	stored in the variable foo to $n.

Synopsis:
    Allows you to treat a list stored in a variable as an array, setting
    arbitrary elements of that array to arbitrary values.

Notes:
    * <array-name> is the *name* of the variable, not the value of the variable
      to be altered.

    * This command returns nothing.
    
    * The index must be within the bounds of the current value for the variable.
      If it is out of bounds, aset will generate an error.

See also:
    index
}
{
    if {$ind >= [uplevel 1 [format {length [var %s]} $array]]} {
    	error {array index out-of-bounds}
    }
    uplevel 1 var $array [map el [uplevel 1 var $array] {
    	var ind [expr $ind-1]
	if {$ind == -1} {
	    var val
	} else {
	    var el
	}
    }]
}]

[defcommand delassoc {list key {foundvar {}} {elvar {}}} {swat_prog.list swat_prog.lisp}
{Usage:
    delassoc <list> <key> [<foundvar> [<elvar>]]

Examples:
    "delassoc $val murphy"	Returns $val without the sublist whose first
				element is the string "murphy"

Synopsis:
    Deletes an entry from an associative list.

Notes:
    * <foundvar>, if given, is the name of a variable in the caller's scope
      that is to be set non-zero if an element in <list> was found whose
      <key> matched the given one. If no such element was found (and therefore
      deleted), the variable is set zero.
      
    * <elvar>, if given, is the name of a variable in the caller's scope
      that receives the element that was deleted from the list. If no
      element was deleted, the variable remains untouched.

See also:
    assoc.
}
{
    if {[null $list]} {
    	return $list
    }
    var found 0
    var list [map el $list {
	if {!$found && [string c [index $el 0] $key] == 0} {
    	    var found 1
	    if {![null $elvar]} {
	    	uplevel 1 var $elvar $el
	    }
	} else {
	    list $el
	}
    }]
    if {![null $foundvar]} {
    	uplevel 1 [format {var %s %d} $foundvar $found]
    }
    
    # work around a bug in concat where concat {} gives garbage
    [if {$list == {{}}} then {
	return {}
    } else {
	return [eval [concat concat $list]]
    }]
}]

[defsubr member {elt {list {}}}
{
    foreach e $list {
        if {$elt == $e} {
            return 1
        }
    }
    return 0
}]

[defsubr remove {elt {list {}}}
 {
     var list [map e $list {
	 if {$e != $elt} {
	     list $e
	 }
     }]
	 
     # work around a bug in concat where concat {} gives garbage
     if {$list == {{}}} {
	 return {}
     } else {
	 return [eval [concat concat $list]]
     }
     
 }]
