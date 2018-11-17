##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	cwd.tcl
# FILE: 	cwd.tcl
# AUTHOR: 	Gene Anderson, Apr 11, 1991
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	pwd 	    	    	print current working directory for thread
#   	dirs	    	    	print directory stack
#   	stdpaths	    	Print out all paths set for std directories
#
#   	printdir    	    	print a directory and the disk label
#   	getnstring   	    	fetch a NULL-terminated string
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	4/11/91		Initial Revision
#
# DESCRIPTION:
#	TCL commands for current working directory and directory stack
#
#	$Id: cwd.tcl,v 1.16.5.1 97/03/29 11:26:21 canavese Exp $
#
###############################################################################

##############################################################################
#				getnstring
##############################################################################
#
# SYNOPSIS:	fetch up to 'n' chars of a NULL-terminated string
# PASS:		addr - ptr to string
#   	    	len - maximum # of characters to fetch (optional)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	4/11/91		Initial Revision
#
##############################################################################

[defsubr getstring {addr {len 666}}
{
    var a [addr-preprocess $addr s o]
    var	l 0

    var	str {}

    global dbcs
    if {[null $dbcs]} {
    	[for {var c [value fetch $s:$o+$l byte]}
	 {($c != 0) && ($l < $len)}
	 {var c [value fetch $s:$o+$l byte]}
    	{
    	    var str [format {%s%c} $str $c]
            var l [expr $l+1]
    	}]
    } else {
    	[for {var c [value fetch $s:$o+$l word]}
	 {($c != 0) && ($l < $len)}
	 {var c [value fetch $s:$o+[expr 2*$l] word]}
    	{
    	    var str [format {%s%c} $str $c]
            var l [expr $l+1]
    	}]
    }
    return $str
}]

##############################################################################
#				print-path
##############################################################################
#
# SYNOPSIS:	    Utility routine to format a disk handle and null-terminated
#   	    	    path nicely for output.
# PASS:		    diskHan = disk handle
#   	    	    addr    = start of null-terminated string
# CALLED BY:	    printdir, EXTERNAL
# RETURN:	    nothing
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/23/92		Initial Revision
#
##############################################################################
[defsubr print-path {diskHan addr}
{
    if {[not-1x-branch]} {
    	if {$diskHan & 1} {
	    echo [format {[%s]\t%s} [penum StandardPath $diskHan]
	    	    [getstring $addr]]
    	} else {
    	    echo [format {[%s]\t%s} 
	    	    [getstring FSInfoResource:$diskHan.DD_volumeLabel 11]
		    [getstring $addr]]
    	}
    } else {
    	echo [format {[%s]\t%s} [getstring kdata:$diskHan.HD_volumeLabel 11]
	    [getstring $addr]]
    }
}]

##############################################################################
#				printdir
##############################################################################
#
# SYNOPSIS:	Print a directory and associated disk label
# PASS:		han - handle of path block
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	4/11/91		Initial Revision
#
##############################################################################

[defsubr printdir {han}
{
    var	addr	    ^h$han
    var address     [addr-parse $addr]

    var diskHan	    [value fetch $addr:FP_logicalDisk]

    if {[not-1x-branch]} {
        print-path $diskHan *$addr:FP_path
    } else {
    	print-path $diskHan $addr:FP_path
    }
}]

##############################################################################
#				pwd
##############################################################################
#
# SYNOPSIS:	Print the current working directory for a thread
# PASS:		none
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	4/11/91		Initial Revision
#
##############################################################################

[defcommand pwd {} {path thread}
{Usage:
    pwd

Examples:
    "pwd"

Synopsis:
    Prints the current working directory for the current thread.

See also:
    dirs, stdpaths.
}
{
    printdir [value fetch ss:TPD_curPath]
}]

##############################################################################
#				dirs
##############################################################################
#
# SYNOPSIS:	Print the directory stack for a thread
#
# PASS:		address of stack segment for thread whose directory
#   	    	stack we'd like to see.
# 
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	4/11/91		Initial Revision
#
##############################################################################

[defcommand dirs {{thread ss}} {path thread}
{Usage:
    dirs

Examples:
    "dirs"

Synopsis:
    Print the directory stack for the current thread.

See also:
    pwd, stdpaths.
}
{
    var dirHan [value fetch $thread:TPD_curPath]
    while {$dirHan != 0} {
    	printdir $dirHan
    	var dirHan [value fetch ^h$dirHan.FP_prev]
    }
}]

##############################################################################
#				stdpaths
##############################################################################
#
# SYNOPSIS:	Print out all paths
# PASS:		flags detailed below
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of stuff is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defcmd stdpaths {args} {system.misc path}
{Usage:
    stdpaths

Examples:
    "stdpaths"	    

Synopsis:
    Print out all paths set for standard directories

See also:
    pwd, dirs.
}
{
    if {[length $args] > 0} {
	var pathseg [value fetch [index $args 0] word]
    } else {
    	if {[null [patient find geos]]} {
	    var pathseg [value fetch loader::loaderVars.KLV_stdDirPaths]
    	    if {$pathseg == 0} {
	    	error {No paths are set.}
    	    }
    	} else {
	    var pathseg [value fetch geos::loaderVars.KLV_stdDirPaths]
	    if {$pathseg == 0} {
	    	error {No paths are set.}
    	    }
	    var pathseg ^h$pathseg
    	}
    }
    #
    # foreach path, print it out
    #
    [for {var path 0} {$path != [expr [size StdDirPaths]-2]}
				    {var path [expr $path+2]} {
	var pname [penum StandardPath [expr $path+1]]
	var poff [value fetch $pathseg:$path word]
	var psize [expr [value fetch $pathseg:$path+2 word ]-$poff]
	if {$psize > 0} {
	    echo -n [format {%s: } $pname]
	    while {$psize > 1} {
		var ch [value fetch $pathseg:$poff byte]
		if {$ch != 0} {
		    echo -n [format {%c} $ch]
		} else {
		    if {$psize != 2} {
			echo -n {  }
		    }
		}
		var poff [expr $poff+1]
		var psize [expr $psize-1]
	    }
	    echo
	} else {
	    # echo {No path set for} $pname
	}
    }]
}]
