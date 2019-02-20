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
#   	assoc	    	    	Find a value in an assoc list
#   	car 	    	    	Return the first element of a list
#   	cdr 	    	    	Return the rest of a list
#   	aset	    	    	Set an element of an array
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Lisp-like commands
#
#	$Id: lisp.tcl,v 3.0 90/02/04 23:47:07 adam Exp Locker: adam $
#
###############################################################################

[defdsubr assoc {list key} prog.list|prog.lisp
{Given a LIST of the form {{KEY VAL} {KEY VAL} ...} and a KEY for which to
search, returns the {KEY VAL} element whose KEY matches the given one. If no
such element, returns nil. The name derives from the list being an
"associative" list, associating a key with a value.}
{
    foreach i $list {
    	if {[string c $key [index $i 0]] == 0} {
    	    return $i
    	}
    }
    return nil
}]
[defdsubr car {list} prog.list|prog.lisp
{Returns the first element of the list}
{
    return [range $list 0 0]
}]
[defdsubr cdr {list} prog.list|prog.lisp
{Returns all but the first element of LIST as a list}
{
    if {[length $list] > 1} {
    	return [range $list 1 end]
    } else {
    	return {}
    }
}]
[defdsubr aset {array ind val} prog.lisp
{Sets an element of an array (list). First arg ARRAY is the name of the
array variable. Second arg IND is the index at which to store (0-origin), and
third arg VAL is the value to put there.}
{
    var len [length [var $array]]

    if {$ind == 0} {
    	if {$len > 1} {
    	    var $array [concat [list $val] [range [var $array] 1 end]]
    	} else {
    	    var $array [list $val]
    	}
    } elif {$ind >= $len} {
    	error {index out of bounds}
    } elif {$ind == [expr $len-1]} {
    	var $array [concat [range [var $array] 0 [expr $len-2]] [list $val]]
    } else {
        var $array [concat [range [var $array]  0 [expr $ind-1]] [list $val] [range [var $array] [expr $ind+1] end]]
    }
}]

