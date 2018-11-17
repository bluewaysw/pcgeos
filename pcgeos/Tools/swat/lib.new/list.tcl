##############################################################################
#
# 	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat
# FILE: 	list.tcl
# AUTHOR: 	Paul Canavese, May 11, 1995
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	5/11/95   	Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: list.tcl,v 1.1.10.1 97/03/29 11:27:16 canavese Exp $
#
###############################################################################


###############################################################################
# List display

[defsubr list-display {list {indentnum 0}} {
    if {[null $list]} {
	return
    }
    foreach entry $list {
	list-display-car $entry $indentnum
	list-display [cdr $entry] [expr $indentnum+1]
    }
} ]

[defsubr list-display-car {list {indentnum 0}} {
    if {![null [car $list]]} {
	thrindent $indentnum
	echo [car $list]
    }
} ]    

[defsubr list-display-keys {list {level 1} {indentnum 0}} {
    if {$level == 0 || [null $list]} {
	return
    }
    foreach entry $list {
	list-display-car $entry $indentnum
	list-display-keys [cdr $entry] [expr $level-1] [expr $indentnum+1]
    }
} ]

[defsubr indent {number} {
    if {$number == 0} {
	return
    } else {
	echo -n [format {%*s} $number {}]
    }
} ]

[defsubr thrindent {number} {
    indent [expr $number*3]
} ]


###############################################################################
# Hard list manipulation

[defsubr cutassoc {listname key} {
    uplevel 1 var $listname [delassoc [uplevel 1 var $listname] $key foo foundEntry]
    return $foundEntry
} ]

[defsubr cutcar {listname} {
    var list [uplevel 1 var $listname]
    uplevel 1 var $listname [cdr $list]
    return [car $list]
} ]

[defsubr append {listname entry} {
    uplevel 1 var $listname [concat [uplevel 1 var $listname] $entry]
} ]


###############################################################################
# Soft list manipulation

[defsubr reverse-list {list} {
    foreach entry $list {
	var returnList [concat [list $entry] $returnList]
    }
    return $returnList
} ]


###############################################################################
# High-level hierarchical list manipulation

[defsubr hlist-entry-exists {args} {
    var searchList [car $args]
    foreach key [cdr $args] {
	var entry [assoc $searchList $key]
	var currentKey $key
	var searchList [range $entry 1 end]
    }
    if {$currentKey == [car $entry]} {
	return 1
    } else {
	return 0
    }
} ]

[defsubr hlist-get-entry {args} {
    var searchList [car $args]
    foreach key [cdr $args] {
	var searchList [range [assoc $searchList $key] 1 end]
    }
    return $searchList
} ]

[defsubr hlist-add-entry {args} { 
    var listname [car $args]
    var entries [cdr $args]
    uplevel 1 var $listname [hlist-do-add-entry [uplevel 1 var $listname] $entries]
    return [uplevel 1 var $listname]
} ]

[defsubr hlist-do-add-entry {list entries} {
    if {[null $entries]} {
	return $list
    }
    if {[null $list] || $list == {{}}} {
	return [entries-to-hlist $entries]
    }

    [var sublist [cutassoc list [car $entries]]]
    if {[null $sublist]} {
	return [concat $list [entries-to-hlist $entries]]
    }
    
    [var newentry [concat [car $entries] 
		   [hlist-do-add-entry [cdr $sublist] [cdr $entries]]]]
    if {[null $list]} {
	return [list $newentry]
    } else {
	return [concat $list [list $newentry]]
    }
} ]

[defsubr hlist-delete-entry {args} { 
    var listname [car $args]
    var entries [cdr $args]
    var list [uplevel 1 var $listname]

    if {[null $entries] || [null $list]} { return }
    var returnEntry [hlist-do-delete-entry list $entries]
    uplevel 1 var $listname $list
    return $returnEntry
} ]

[defsubr hlist-do-delete-entry {listname entries} {

    var list [uplevel 1 var $listname]

    # Cut the sublist matching our first key.

    var sublist [cutassoc list [car $entries]]

    # If there wasn't an entry, we're done.

    if {[null $sublist]} {
	return
    }

    # Check if this was the last key.

    if {[null [cdr $entries]]} {

	# Set the passed list to be the same as the one in this frame, without the 
	# sub-list.

	if {[null [cdr $list]]} {
	    uplevel 1 var $listname {}
	} else {
	    uplevel 1 var $listname $list
	}

	# Return the meat of the sublist.

	return [cdr $sublist]
    }

    var returnValue [hlist-do-delete-entry sublist [cdr $entries]]

    # If there were the last entry for our set of keys, then
    # strip out the keys.

    if {[null $sublist]} {
	if {[null [cdr [car $list]]]} {
	    # Strip keys.
	    uplevel 1 var $listname {}
	} else {
	    uplevel 1 var $listname $list
	}
    } else {
	uplevel 1 var $listname [concat $list [list $sublist]]
    }
    return $returnValue
    
} ]

[defsubr hlist-get-keys {list} {
    var keys {}
    foreach entry $list {
	append keys [car $entry]
    }
    return $keys
} ]    

[defsubr entries-to-hlist {entries} {
    var entries [reverse-list $entries]
    var returnEntry [car $entries]
    foreach entry [cdr $entries] {
	var returnEntry [list $entry $returnEntry]
    }
    return [list $returnEntry]
} ]

[defsubr hlist-to-entries {list} {
    while {![null $list]} {
	append returnList [car $list]
	var list [cdr $list]
    }
    return $returnList
} ]

