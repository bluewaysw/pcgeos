##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Swat
# MODULE:	System Library
# FILE: 	bptutils.tcl
# AUTHOR: 	Adam de Boor, Apr 24, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	bpt-init    	    	Initialize support by this module for another
#   	bpt-free-number	    	Release a breakpoint number for re-use
#   	bpt-alloc-number    	Fetch the first free breakpoint number to
#				use for a new breakpoint.
#   	bpt-parse-arg	    	Parse a breakpoint argument into a list of
#				valid numbers for the caller to use.
#   	bpt-trim-name	    	Trim a string to fit within a given length,
#				removing stuff on the left if it's too long.
#   	bpt-set
#   	bpt-unset
#   	bpt-get
#   	bpt-addr
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/24/92		Initial Revision
#
# DESCRIPTION:
#	Utility routines for the various breakpoint-related commands
#
#   	There are effectively two layers here: one simply allocates and
#	frees and parses breakpoint tokens. the other tracks the state of
#	the block in which a breakpoint is set and calls you back to tell
#   	you, in simple terms, whether to install or uninstall a breakpoint.
#   	If you use this second layer, you effectively give up control of the
#   	table whose name you pass to bpt-init. When you wish access to your
#	own data for a breakpoint, you must call bpt-get.
#
#   	A bpttok, as returned by bpt-init and used by all the functions here,
#   	is a list with between 4 and 6 elements:
#   	    0)	the token for the table (created by the "table" command) in
#		which the data for the breakpoints are stored (keyed by
#		breakpoint number)
#   	    1) 	the name of the global variable in which the high water mark
#		for numbers in the table is stored.
#   	    2)	the name of the global variable that holds the list of free
#		numbers in the table.
#   	    3) 	the string prepended to breakpoint numbers to form a token
#		the user can use.
#   	    4)	the name of the callback procedure for installing a breakpoint
#	    5)	the name of the callback procedure for uninstalling a
#		breakpoint.
#   	    6)	the token for the START event handler registered to
#		care for these breakpoints
#   	    7)	the token for the EXIT event handler registered to care for
#		these breakpoints.
#
# TODO:
#   	If receive an error from the unset callback when exiting, mark the thing
#	as saved anyway.
#
#	$Id: bptutils.tcl,v 1.4.24.1 97/03/29 11:26:29 canavese Exp $
#
###############################################################################

##############################################################################
#				bpt-init
##############################################################################
#
# SYNOPSIS:	    Initialize support by this module for a breakpoint-related
#		    command. The function may safely be called multiple times
#		    as it is non-destructive in its actions.
# PASS:		    table   = name of global variable to hold breakpoint
#			      data for the command
#   	    	    prefix  = prefix command will attach to breakpoint numbers
#			      when returning them as tokens.
#   	    	    [max]   = name of global variable to hold the high-water
#			      mark for breakpoint numbers. If not given, a
#			      suitable default will be chosen.
#   	    	    [setcb] = callback procedure for setting a breakpoint.
#			      PASS:
#			      	bpnum	= breakpoint number
#				unsetdata = value returned from previous setcb
#				data	= data passed to bpt-set
#				alist	= address list where bpt is set
#				why 	= "start" if patient just starting
#					  or breakpoint has been enabled or
#					  the block has come in for the
#					  first time since the breakpoint
#					  was set.
#					  "in" if block in which breakpoint
#					  is set just became resident for
#					  the second or later time.
#   	    	    	      RETURN:
#   	    	    	    	value to pass to unsetcb
#   	    	    [unsetcb] = callback procedure for unsetting a breakpoint.
#			      PASS:
#			      	bpnum	= breakpoint number
#				unsetdata = value returned from setcb
#				data	= data passed to bpt-set
#   	    	    	    	alist	= address list where bpt was set
#   	    	    	    	why 	= "exit" if patient exiting or bpt
#					  being disabled or memory freed
#					  "out" if block in which breakpoint
#					  is set was just discarded or swapped
#					  out.
#   	    	    	      RETURN:
#   	    	    	    	non-zero if set callback should be called when
#				block next comes in (assumed so if why=exit)
# CALLED BY:	    EXTERNAL
# RETURN:	    token to pass to further bpt commands
# SIDE EFFECTS:	    the table is created and its token stored in the global
#		    variable if the variable was {} when this function was
#		    called.
# 
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/24/92		Initial Revision
#
##############################################################################
[defsubr bpt-init {table prefix {max {}} {setcb {}} {unsetcb {}}}
{
    global $table
    
    if {![null $setcb]} {
    	if {[null $unsetcb]} {
	    error {bpt-init: must provide both an unset callback and a set callback}
    	}
    } elif {![null $unsetcb]} {
	error {bpt-init: must provide both an unset callback and a set callback}
    }
    
    if {[null [var $table]]} {
    	var $table [table create]
    }
    
    if {[null $max]} {
    	var max ${table}-max
    }
    global $max
    if {[null [var $max]]} {
    	var $max 1
    }
    global ${table}-free-list
    
    var d [list $table $max ${table}-free-list $prefix $setcb $unsetcb]
    #
    # If callbacks provided, register handler functions for both the EXIT
    # and START events so we can properly call the callbacks.
    #
    if {![null $setcb]} {
    	var d [concat $d [list
	    	    	  [event handle EXIT bpt-exit-handler $d]
			  [event handle START bpt-start-handler $d]]]
    }
    return $d
}]

##############################################################################
#				bpt-extract-table
##############################################################################
#
# SYNOPSIS:	Fetch the token for the table from a bpttok
# PASS:		bpttok	= token of the first part
# CALLED BY:	INTERNAL
# RETURN:	table token of the second part :)
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/17/92	Initial Revision
#
##############################################################################
[defsubr bpt-extract-table {bpttok}
{
    var table [index $bpttok 0]
    global $table
    return [var $table]
}]

##############################################################################
#				bpt-extract-max
##############################################################################
#
# SYNOPSIS:	Fetch the current high-water mark from a bpt token
# PASS:		bpttok	= token of the first part
# CALLED BY:	INTERNAL
# RETURN:	current high water mark
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/17/92	Initial Revision
#
##############################################################################
[defsubr bpt-extract-max {bpttok}
{
    var max [index $bpttok 1]
    global $max
    return [var $max]
}]

##############################################################################
#				bpt-free-number
##############################################################################
#
# SYNOPSIS:	    Utility routine to release a breakpoint number for
#   	    	    re-use.
# PASS:		    bnum    = the actual number
#   	    	    bpttok  = token returned by bpt-init
# CALLED BY:	    EXTERNAL
# RETURN:	    nothing
# SIDE EFFECTS:	    the list of free numbers and the high-water level may both
#		    be altered
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/23/92		Initial Revision
#
##############################################################################
[defsubr bpt-free-number {bnum bpttok}
{
    var list [index $bpttok 2] max [index $bpttok 1]

    global $list $max

    var elnum 0 handled 0
    foreach e [var $list] {
    	if {[index $e 0] == $bnum+1} {
	    aset $list $elnum [list $bnum [index $e 1]]
    	    var handled 1
	    break
    	} elif {[index $e 1] == $bnum-1} {
	    if {$bnum == [var $max]-1} {
	    	var $max [index $e 0]
    	    	if {$elnum == 0} {
    		    var $list {}
    	    	} else {
		    var $list [range [var $list] 0 [expr $elnum-1]]
    	    	}
    	    } else {
	    	aset $list $elnum [list [index $e 0] $bnum]
    	    }
	    var handled 1
	    break
    	} elif {$bnum < [index $e 0]} {
	    if {$elnum == 0} {
	    	var $list [concat [list [list $bnum $bnum]] [var $list]]
    	    } else {
	    	var $list [concat [range [var $list] 0 [expr $elnum-1]]
		    	    	  [list [list $bnum $bnum]]
				  [range [var $list] $elnum end]]
    	    }
	    var handled 1
    	    break
    	}
    }
    if {!$handled} {
    	var $list [concat [var $list] [list [list $bnum $bnum]]]
    }
}]

##############################################################################
#				bpt-alloc-number
##############################################################################
#
# SYNOPSIS:	    Allocate a free breakpoint number for the caller. Used
#		    in conjunction with bpt-free-number...
# PASS:		    bpttok  = token returned by bpt-init
# CALLED BY:	    EXTERNAL
# RETURN:	    the number to use
# SIDE EFFECTS:	    the list of free numbers and the high-water level
#		    may both be altered.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/23/92		Initial Revision
#
##############################################################################
[defsubr bpt-alloc-number {bpttok}
{
    var list [index $bpttok 2] max [index $bpttok 1]
    global  $list $max
    
    var e [index [var $list] 0]

    if {[null $e]} {
    	var $max [expr [var $max]+1]
	return [expr [var $max]-1]
    }
    
    if {[index $e 0] == [index $e 1]} {
    	var $list [range [var $list] 1 end]
    } else {
    	var $list [concat [list [list [expr [index $e 0]+1] [index $e 1]]]
			  [range [var $list] 1 end]]
    }
    
    return [index $e 0]
}]

##############################################################################
#				bpt-remove-prefix
##############################################################################
#
# SYNOPSIS:	    Remove the token prefix from the start of a breakpoint
#		    token, if it's there, returning just the number
# PASS:		    arg	    = breakpoint token
#   	    	    bpttok  = token returned by bpt-init
# CALLED BY:	    bpt-parse-arg
# RETURN:	    -1 if token invalid, else the number
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/24/92		Initial Revision
#
##############################################################################
[defsubr bpt-remove-prefix {arg bpttok}
{
    var prefix [index $bpttok 3]
    
    if {[string match $arg ${prefix}*]} {
    	var arg [range $arg [length ${prefix} chars] end chars]
    }

    if {![string match $arg {[0-9]*}]} {
    	return -1
    } else {
    	return $arg
    }
}]
   
##############################################################################
#				bpt-parse-arg
##############################################################################
#
# SYNOPSIS:	    Given an argument that can hold a breakpoint number, token
#   	    	    or range of tokens, return the list of breakpoint
#		    numbers to which the argument refers.
# PASS:		    arg	    = the argument itself
#   	    	    bpttok  = token returned by bpt-init
# CALLED BY:	    EXTERNAL
# RETURN:	    List of breakpoint numbers. This will be empty if no
#		    existing breakpoint numbers are specified by the argument.
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/24/92		Initial Revision
#
##############################################################################
[defsubr bpt-parse-arg {arg bpttok}
{
    var table [bpt-extract-table $bpttok] max [bpt-extract-max $bpttok]
    
    #
    # First see if the thing is a range.
    #
    var m [string first - $arg]
    if {$m >= 0} {
    	#
	# Break the range into its component pieces.
	#
	var start [range $arg 0 [expr $m-1] chars]
	var end [range $arg [expr $m+1] end chars]
	
    	#
	# Convert the start and end to numbers. If either is missing, they
	# take on the value of their respective ends of the spectrum...
	#
    	if {[null $start]} {
	    var start 0
    	} else {
	    var start [bpt-remove-prefix $start $bpttok]
	    if {$start == -1} {
	    	error [concat malformed breakpoint number $start]
    	    }
    	}
	
	if {[null $end]} {
	    var end $max
    	} else {
    	    var end [bpt-remove-prefix $end $bpttok]
	    if {$end == -1} {
	    	error [concat malformed breakpoint number $end]
    	    }
    	}
    } else {
    	#
	# Set start and end to the single breakpoint specified by the argument.
	#
    	var start [bpt-remove-prefix $arg $bpttok]
	var end $start
    }
    
    #
    # Now lookup each number in the range in the table to make sure it
    # exists, putting those that exist into the list we're returning.
    #
    var result {}
    
    while {$start <= $end} {
    	if {![null [table lookup $table $start]]} {
	    var result [concat $result $start]
    	}
	var start [expr $start+1]
    }
    
    #
    # Returnez le liste
    #
    return $result
}]

##############################################################################
#				bpt-trim-name
##############################################################################
#
# SYNOPSIS:	Trim a symbolic address to find w/in a given bounds, nuking
#   	    	characters on the left as insignificant
# PASS:		name	= name to trim
#   	    	max 	= length to which to trim it
# CALLED BY:	EXTERNAL
# RETURN:	the trimmed name
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/24/90		Initial Revision
#
##############################################################################
[defsubr bpt-trim-name {name max}
{
    var len [length $name chars]
    
    if {$len > $max} {
    	return <[range $name [expr $len-$max+1] end chars]
    } else {
    	return $name
    }
}]

##############################################################################
#
#		       Second Level of Support
#
# The data list passed to bpt-set is wrapped into our own data list before
# being stored in the table:
#
#   0)	the state (orphan, saved, set, unset)
#   1)	address list (empty if orphaned)
#   2)	address expression where set (full name, including patient)
#   3)	interest token for handle in (1)
#   4)	caller-supplied data
#   5)	return value from setcb
#
##############################################################################

##############################################################################
#				bpt-addr-list-to-addr-expr
##############################################################################
#
# SYNOPSIS:	    Convert an address list into an address expression
#		    suitable for use in restoring a bpt should the
#		    geode for which it's set be downloaded
# PASS:		    a	    = addr-list to convert
# CALLED BY:	    bpt
# RETURN:	    address expression, or {} if no code symbol before the
#		    address given by the list
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/19/92		Initial Revision
#
##############################################################################
[defsubr bpt-addr-list-to-addr-expr {a}
{
    var sym [symbol faddr {label proc var} ^h[handle id [index $a 0]]:[index $a 1]]
    if {![null $sym]} {
	var symOffset [index [symbol get $sym] 0]
	if {$symOffset == [index $a 1]} {
	    return [symbol fullname $sym with-patient]
	} else {
	    return [symbol fullname $sym with-patient]+[expr [index $a 1]-$symOffset]
	}
    }
    return {}
}]

##############################################################################
#				bpt-set
##############################################################################
#
# SYNOPSIS:	Set a breakpoint
# PASS:		bpttok	= the usual
#		num 	= the allocated breakpoint number
#		data	= opaque data for caller to use
#   	    	alist	= address list at which to set the breakpoint
# CALLED BY:	EXTERNAL
# RETURN:	1 if successfully set. 0 if not.
# SIDE EFFECTS:	data are entered into the table.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/16/92	Initial Revision
#
##############################################################################
[defsubr bpt-set {bpttok num data alist}
{
    var table [bpt-extract-table $bpttok]
    var setcb [index $bpttok 4]
    
    #
    # Convert the address list back into a symbolic address expression for
    # later restoration.
    #
    var addr [bpt-addr-list-to-addr-expr $alist]
    
    [if {![handle ismem [index $alist 0]] ||
    	 [handle state [index $alist 0]] & 1}
    {
    	#
	# Handle is resident. Attempt to install the bpt. If this returns
	# an error, we return an error.
	#
    	if {[catch {$setcb $num {} $data $alist start} unsetdata] != 0} {
    	    if {![null $unsetdata]} {
	    	echo ${setcb}: $unsetdata
    	    }
	    return 0
    	}
	var state set
    } else {
    	#
	# Set the unsetdata to a magic value so we know, when the handle comes
	# in for the first time, to call the callback with "start" for the
	# reason, not "in"
	#
    	var state unset
    }]
    
    #
    # Express interest in the handle so we can keep our client apprised of
    # changes and know, for ourselves, when the block gets freed.
    #
    var int [handle interest [index $alist 0] bpt-interest-proc 
    	     [list $bpttok $num]]

    #
    # Store this wealth of data in the table.
    #
    table enter $table $num [list $state $alist $addr $int $data $unsetdata]
    
    return 1
}]

##############################################################################
#				bpt-unset
##############################################################################
#
# SYNOPSIS:	Unset a breakpoint.
# PASS:		bpttok	= the usual
#   	    	num 	= the breakpoint number to nuke
#   	    	[notset]= non-zero if we should pretend the breakpoint isn't
#			  set, no matter what our records show; i.e. don't call
#			  the unset callback no matter what we long to do
# CALLED BY:	EXTERNAL
# RETURN:	1 if successfully deleted, 0 if breakpoint doesn't exist
# SIDE EFFECTS:	the entry in the table is nuked. the unsetcb will be
#		called if the breakpoint is installed.
#   	    	the breakpoint number is released to be used again.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/16/92	Initial Revision
#
##############################################################################
[defsubr bpt-unset {bpttok num {notset 0}}
{
    var table [bpt-extract-table $bpttok]
    var unsetcb [index $bpttok 5]
    
    var d [table lookup $table $num]
    if {[null $d]} {
    	return 0
    }
    
    #
    # If breakpoint installed, get the callback to uninstall it.
    #
    if {[index $d 0] == set && !$notset} {
    	$unsetcb $num [index $d 5] [index $d 4] [index $d 1] exit
    }
    #
    # Register disinterest in the handle if bpt not orphaned
    #
    if {![null [index $d 1]]} {
    	handle nointerest [index $d 3]
    }

    table remove $table $num
    
    bpt-free-number $num $bpttok

    return 1
}]

##############################################################################
#				bpt-get
##############################################################################
#
# SYNOPSIS:	Retrieve the data stored for a breakpoint
# PASS:		bpttok	= the usual
#   	    	num 	= breakpoint number
# CALLED BY:	EXTERNAL
# RETURN:	2-list {data unsetdata}. unsetdata will be empty if the
#		setcb has never been called
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/16/92	Initial Revision
#
##############################################################################
[defsubr bpt-get {bpttok num}
{
    var table [bpt-extract-table $bpttok]
    
    var d [table lookup $table $num]
    if {[null $d]} {
    	return {}
    }
    
    if {[index $d 0] == unset} {
    	return [list [index $d 4] {}]
    } else {
    	return [list [index $d 4] [index $d 5]]
    }
}]

##############################################################################
#				bpt-addr
##############################################################################
#
# SYNOPSIS:	Return the address, both symbolic and as an address list,
#		for a set breakpoint
# PASS:		bpttok	= the usual
#   	    	num 	= the breakpoint number
# CALLED BY:	EXTERNAL
# RETURN:	2-list {alist sym-addr} alist is null if breakpoint has
#		been orphaned. sym-addr is null if address has no symbolic
#		representation.
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/16/92	Initial Revision
#
##############################################################################
[defsubr bpt-addr {bpttok num}
{
    var table [bpt-extract-table $bpttok]
    
    var d [table lookup $table $num]
    if {[null $d]} {
    	return {}
    }
    
    return [range $d 1 2]
}]
    
    
    
##############################################################################
#				bpt-interest-proc
##############################################################################
#
# SYNOPSIS:	Cope with a change of state in a breakpoint we're managing
# PASS:		handle	= handle token
#		what	= type of state change
#   	    	data	= 2-list of {bpttok num}
# CALLED BY:	handle module
# RETURN:	nothing
# SIDE EFFECTS:	breakpoint may be installed or uninstalled
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/16/92	Initial Revision
#
##############################################################################
[defsubr bpt-interest-proc {handle what data}
{
    var bpttok [index $data 0]
    var num [index $data 1]
    var table [bpt-extract-table $bpttok]
    var d [table lookup $table $num]
    
    [case $what in
    	free {
	    if {[null [index $d 2]]} {
	    	#
		# Breakpoint not relative, so nuke it.
		#
		echo [index $bpttok 3]$num deleted as it's not symbol-relative
    	    	bpt-unset $bpttok $num
    	    } else {
	    	#
		# If bpt set, call callback to unset it.
		#
		if {[index $d 0] == set} {
		    var unsetcb [index $bpttok 5]
		    [if {[catch {[$unsetcb $num [index $d 5] [index $d 4]
		    	    	  [index $d 1] exit]} err] != 0 && ![null $err]}
    	    	    {
		    	echo $unsetcb: $err
    	    	    }]
		}
		#
		# Enter revised data
		#
		table enter $table $num [concat orphan [list {}] [range $d 2 4]
		    	    	    	 [list {}]]
    	    }
    	}
	{swapin load} {
	    if {[index $d 0] == unset} {
	    	#
		# Call the callback to let it know the thing just came in.
		#
		var setcb [index $bpttok 4]
		var unsetdata [$setcb $num [index $d 5] [index $d 4]
		    	    	[index $d 1]
		    	    	[if {[index $d 0] == set} {
				    concat in
    	    	    	    	} else {
    	    	    	    	    concat start
    	    	    	    	}]]
    	    	#
		# Enter possibly-revised data.
		#
    	    	table enter $table $num [concat set [range $d 1 4]
		    	    	    	    [list $unsetdata]]
    	    }
    	}
	{swapout discard} {
	    if {[index $d 0] == set} {
    	    	#
		# Let the callback know the thing's out.
		#
	    	var unsetcb [index $bpttok 5]
		if [$unsetcb $num [index $d 5] [index $d 4] [index $d 1] out] {
    	    	    #
		    # Enter revised data so we call the thing when the block
		    # comes back in.
		    #
    	    	    table enter $table $num [concat unset [range $d 1 5]]
    	    	}
    	    }
    	}
    ]
}]
	    
##############################################################################
#				bpt-start-handler
##############################################################################
#
# SYNOPSIS:	Take note of the start of a patient and see if there are
#   	    	any saved or orphaned breakpoints that need to be restored
# PASS:		patient	= token for the patient that just started
#   	    	bpttok	= token for the bpt system being managed
# CALLED BY:	START event
# RETURN:	EVENT_HANDLED
# SIDE EFFECTS:	breakpoints may be restored/reset/deleted
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/16/92	Initial Revision
#
##############################################################################
[defsubr bpt-start-handler {patient bpttok}
{
    var pname [patient name $patient]:
    var plen [expr [length $pname chars]-1]
    
    var table [bpt-extract-table $bpttok]
    var max [bpt-extract-max $bpttok]
    var setcb [index $bpttok 4]
    
    global $max
    
    for {var i 0} {$i < $max} {var i [expr $i+1]} {
    	var d [table lookup $table $i]
	if {[index $d 0] != saved && [index $d 0] != orphan} {
    	    # not in need of restoration
	    continue
    	}
	
	if {[range [index $d 2] 0 $plen char] != $pname} {
	    # not for this patient
	    continue
    	}
	if {[catch {addr-parse [index $d 2]} a] != 0} {
	    # couldn't parse address, but this is when we need to restore it,
	    # which means we can't restore it, so nuke it.
	    echo [index $d 2] no longer exists, so [index $bpttok 3]$i deleted
	    bpt-unset $bpttok $i
	    continue
    	}
	#
	# Re-express interest in the handle if the bpt is an orphan
	#
	if {[index $d 0] == orphan} {
	    var int [handle interest [index $a 0] bpt-interest-proc
	    	    	[list $bpttok $i]]
    	} else {
	    var int [index $d 3]
    	}
	# enter revised data into the table before calling callback,
	# in case callback needs it (it could be stupid...)
	table enter $table $i [concat [list unset $a [index $d 2] $int] 
	    	    	    	[range $d 4 5]]
	    
	if {[handle state [index $a 0]] & 1} {
	    # resident, so set the thing
	    var unsetdata [$setcb $i [index $d 5] [index $d 4] $a start]
	    #
	    # Enter revised data.
	    #
	    table enter $table $i [concat [list set $a [index $d 2] $int
	    	    	    	    	    [index $d 4]] 
					[list $unsetdata]]
    	}
    }
    return EVENT_HANDLED
}]
    
	    
##############################################################################
#				bpt-exit-handler
##############################################################################
#
# SYNOPSIS:	Take note of the exit of a patient and see if there are
#   	    	any breakpoints that need to be saved
# PASS:		patient	= token for the patient that is about to exit
#   	    	bpttok	= token for the bpt system being managed
# CALLED BY:	EXIT event
# RETURN:	EVENT_HANDLED
# SIDE EFFECTS:	breakpoints may be saved
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/16/92	Initial Revision
#
##############################################################################
[defsubr bpt-exit-handler {patient bpttok}
{
    var pname [patient name $patient]:
    var plen [expr [length $pname chars]-1]
    
    var table [bpt-extract-table $bpttok]
    var max [bpt-extract-max $bpttok]
    var unsetcb [index $bpttok 5]
    
    global $max
    
    for {var i 0} {$i < $max} {var i [expr $i+1]} {
    	var d [table lookup $table $i]
	if {[index $d 0] != set && [index $d 0] != unset} {
    	    # not in need of saving
	    continue
    	}
	
	if {[range [index $d 2] 0 $plen char] != $pname} {
	    # not for this patient
	    continue
    	}
    	#
	# If breakpoint is set, unset it.
	#	
	if {[index $d 0] == set} {
	    [if {[catch {[$unsetcb $i [index $d 5] [index $d 4]
			  [index $d 1] exit]} err] != 0 && ![null $err]}
    	    {
	    	echo $unsetcb: $err
    	    }]
    	}
	#
	# Enter data with new status in the table
	#
	table enter $table $i [concat [list saved {}] [range $d 2 5]]
    }
    return EVENT_HANDLED
}]
