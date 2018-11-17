##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	dbwatch.tcl
# FILE: 	dbwatch.tcl
# AUTHOR: 	Adam de Boor, Dec  2, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	dbwatch	    	    	turn database watching on or off
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/ 2/89	Initial Revision
#
# DESCRIPTION:
#	Routines to track database library usage.
#
#	$Id: dbwatch.tcl,v 1.8.12.1 97/03/29 11:28:07 canavese Exp $
#
###############################################################################
#
# List of breakpoints we set
#
defvar _db_breaks {}
#
# Table of known DB files. Each entry contains the name of the associated file.
# The keys are the handles involved.
#
defvar _db_table nil

if {[null $_db_table]} {
    var _db_table [table create]
}

[defsubr _db_detach {args}
{
    global _db_table
    
    table destroy $_db_table
    var _db_table nil

    return EVENT_HANDLED
}]

[defsubr _db_attach {args}
{
    global _db_table
    
    if {[null $_db_table]} {
    	var _db_table [table create]
    }

    return EVENT_HANDLED
}]

defvar _db_events nil

if {[null $_db_events]} {
    var _db_events [concat
    	    	    	[event handle ATTACH _db_attach]
    	    	    	[event handle DETACH _db_detach]]
}

[defcommand db-to-addr {fhan grp {item {}}} lib_app_driver.dbase
{Usage:
    db-to-addr <file> <group> <item>
    db-to-addr <file> <db-item-ref>

Examples:
    "db-to-addr bx cx dx"	Return an address expression for the base of
				the DB item dx in group cx in file bx.

Synopsis:
    Provides a simple way to map from a file handle and a 32-bit DB item
    reference to an address in memory.

Notes:
    * If you've got a DBItemRef variable, you can pass it as the second
      argument, rather than having to break it into its group and item parts
      yourself.

See also:
    dbwatch
}
{
    if {[null $item]} {
    	var grp [getvalue $grp]
    	var item [expr $grp&0xffff]
	var grp [expr ($grp>>16)&0xffff]
    }
    var ch [value fetch (^v$fhan:$grp):$item.DBII_chunk]
    var b [value fetch (*(^v$fhan:$grp):$item.DBII_block).DBIBI_block]
    var a [addr-parse ^v$fhan:$b]
    
    return [format {^l%04xh:%04xh} [handle id [index $a 0]] $ch]
}]

[defdsubr dbwatch {{what on}} profile
{dbwatch controls observation of database usage. If given no argument, or "on",
all DB functions will be watched and their parameters and return values printed
in a nice fashion. Observation can be shut off by saying "dbwatch off"}
{
    global db_breaks
    
    [case $what in
    	{[Oo][Ff][Ff]} {
	    map i $db_breaks {brk clear $i}
	    var db_breaks {}
    	}
	default {
	    var db_breaks [map f {
		 VMOpen
		 VMUpdate
		 VMClose
		 DBLock
		 DBUnlock
		 DBDirty
		 DBAlloc
		 DBReAlloc
		 DBFree
	    } {
    	    	brk $f _db_$f
    	    }]
    	}
    ]
}]

#		 DBGroupAlloc
#		 DBGroupFree
#		 DBSetMap
#		 DBGetMap
#		 DBLockMap
#		 DBInsertAt
#		 DBDeleteAt
#		 VMSetThreadVMFile
#		 VMGetThreadVMFile
#		 DBSetThreadDBGroup
#		 DBGetThreadDBGroup

[defsubr _db_VMOpen {args}
{
    #
    # Fetch filename
    #
    var file {} len 0
    [for {var c [value fetch ds:dx [type byte]]}
	 {$c != 0}
	 {var c [value fetch ds:dx+$len [type byte]]}
    {
    	var len [expr $len+1]
    	var file [format %s%c $file $c]
    }]
    #
    # Decode access mode
    #
    [case [expr [read-reg al]&0x3] in
    	0   {var mode read-only}
	1   {var mode write-only}
	2   {var mode read-write}
	3   {var mode error}
    ]
    #
    # Decode sharing mode
    #
    [case [expr ([read-reg al]&0x70)>>4] in
    	0   {var share error}
	1   {var share exclusive}
	2   {var share deny-write}
	3   {var share deny-read}
	4   {var share deny-none}
	5|6|7 {var share error}
    ]
    #
    # Decode open type
    #
    var ah [read-reg ah]
    if {$ah & 0x80} {
    	var type longname/
	var ah [expr $ah&0x7f]
    }
    [case $ah in
    	0   {var type ${type}open-existing}
    	1   {var type ${type}temp-file}
	2   {var type ${type}create-ok}
	3   {var type ${type}create-only}
    	default {var type ${type}error}
    ]
    #
    # Print info
    #
    echo VMOpen($type, $share, $mode, "$file")
    #
    # Set breakpoint at return point to record handle
    #
    var f [frame next [frame cur]]
    brk pset [frame register pc $f] [list _db_DBOpen_2 $file [frame register sp $f]]
    #
    # Keep going
    #
    return 0
}]
    
[defsubr _db_DBOpen_2 {file sp}
{
    if {[read-reg sp] >= $sp} {

	if {[read-reg cc]&1} {
	    #
	    # Error
	    #
	    echo VMOpen("$file") = error code [type emap [read-reg ax] [sym find type VMOpenStatus]]
	} else {
	    echo VMOpen("$file") = [format %04xh [read-reg bx]]
	    # record binding of handle to file
	    global _db_table
	    table enter $_db_table [read-reg bx] $file
	}
	#
	# Keep going after biffing our breakpoint
	#
	global breakpoint
	brk clear $breakpoint
    }
    return 0
}]

[defsubr _db_handle_group_override {}
{
    var group [value fetch ss:TPD_dbGroup [type word]]
    if {$group != 0} {
    	return $group
    } else {
    	return [read-reg ax]
    }
}]

[defsubr _db_handle_file_override {}
{
    global _db_table

    var f [value fetch ss:TPD_vmFile]
    if {$f == 0} {
    	var f [read-reg bx]
    }
    
    return [list $f [table lookup $_db_table $f]]
}]

[defsubr _db_VMUpdate {args}
{
    var f [_db_handle_file_override]
    echo VMUpdate("[index $f 1]" \[handle = [format %04xh [index $f 0]]\])
    return 0
}]

[defsubr _db_VMClose {args}
{
    global _db_table

    var f [_db_handle_file_override]
    echo VMClose("[index $f 1]" \[handle = [format %04xh [index $f 0]]\])
    
    table remove $_db_table [index $f 0]

    return 0
}]

[defsubr _db_DBLock {args}
{
    var f [_db_handle_file_override]
    var g [_db_handle_group_override]
    
    echo DBLock("[index $f 1]", [format %04xh:%04xh $g [read-reg di]]) = [db-to-addr [index $f 0] $g di]
    
    return 0
}]

[defsubr _db_DBUnlock {args}
{
    var f [_db_handle_file_override]
    
    echo DBUnlock("[index $f 1]", ^h[format %04xh [value fetch es:LMBH_handle]])
    
    return 0
}]

[defsubr _db_DBDirty {args}
{
    var f [_db_handle_file_override]

    echo DBDirty("[index $f 1]", ^l[format %04xh:%04xh [value fetch es:LMBH_handle] [read-reg di]])
    
    return 0
}]

[defsubr _db_DBAlloc {args}
{
    var f [_db_handle_file_override]
    var g [_db_handle_group_override]


    echo DBAlloc("[index $f 1]", group [format %04xh $g], [read-reg cx])
    #
    # Set breakpoint at return point to print result
    #
    var next [frame next [frame cur]]
    brk pset [frame register pc $next] [list _db_DBAlloc_2 [index $f 1] [frame register sp $next]]
    
    return 0
}]

[defsubr _db_DBAlloc_2 {file sp}
{
    if {[read-reg sp] >= $sp} {
	echo DBAlloc("$file") = [format {%04xh, %04xh} [read-reg ax] [read-reg di]]

	global breakpoint
	brk clear $breakpoint

    }
    return 0
}]

[defsubr _db_DBReAlloc {args}
{
    var f [_db_handle_file_override]
    var g [_db_handle_group_override]
    
    echo DBReAlloc("[index $f 1]", [format {%04xh, %04xh} [read-reg ax] [read-reg di]], [read-reg cx])

    return 0
}]

[defsubr _db_Free {args}
{
    var f [_db_handle_file_override]
    var g [_db_handle_group_override]

    echo DBFree("[index $f 1]", [format {%04xh, %04xh} [read-reg ax] [read-reg di]])

    return 0
}]
