##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE: 	
# AUTHOR: 	jimmy lefkowitz
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jimmy	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#   	    	tcl code for sending/reciving files through RPC
#
#	$Id: filexfer.tcl,v 1.21 97/10/07 23:32:16 allen Exp $
#
###############################################################################

[defcommand send {args} top.support
{Usage:
    send [[-enp] [-r] <geode>]

Examples:
    "send write"			- send EC GeoWrite if running EC code
					- send GeoWrite if running non-EC code
    "send -r write" 	    	    	- do "send write" and then "run write"
    "send -e write"			- send EC GeoWrite
    "send -n write"			- send GeoWrite
    "send -p c:/pcgeos/appl/write.geo"	- send c:/pcgeos/appl/write.geo
    "send"				- send 'patient-default'

Synopsis:
    send a geode from host to target machine

Notes:
    * <geode>	either the geode's permanent name (specified in the .gp file),
		or the full path of the geode to send

      -e	send EC version of <geode>
      -n	send non-EC version of <geode>
      -p	<geode> argument is the path of geode
      -r    	run the geode after sending it

See also:
    run, patient-default
}
{
    global defaultPatient sendPatient sendPatientType sendSrc sendDest file-os

    if {[null $args] && [null $defaultPatient]} {
	error {Usage: send [-enp] <geode>}
    }

    var	run {}
    if {[null $args]} {
	var args $defaultPatient
    } else {
	#
	# parse the various arguments we allow.
	#
	while {[string match [index $args 0] -*]} {
	    if {[length [index $args 0] char] > 2} {
		error {Usage: send [-enp] <geode>}
	    }
	    [case [index $args 1 char] in
		e {var nec 0}
		n {var nec 1}
		p {var pathname 1}
    	    	r {var run TRUE}
	    ]
	    var args [cdr $args]
	}
    }

    #
    # are we running ec or non-ec
    #
    if {$nec == {} && $pathname == {}} {
	var geosPatient [patient find geos]
	if {$geosPatient == nil} {
	    var loaderPath [patient path [patient find loader]]
	    if {[string f loader.sym $loaderPath no_case] != -1} {
		var nec 1
	    } elif {[string f loaderec.sym $loaderPath no_case] != -1} {
		var nec 0
	    } else {
		echo
		echo  Warning: Unable to determine whether the target system is
		echo {         running EC or non-EC code.  Defaulting to EC.}
		echo

		var nec 0
	    }
	} elif {![string c [patient fullname $geosPatient] {geos    kern}]} {
	    var nec 1
	} else {
	    var nec 0
	}
    }

    if {$pathname == {} && [length $args char] > 8} {
	error {Geode name cannot be longer than eight characters}
    }

    if {($args != $sendPatient) || ($nec != $sendPatientType) ||
	[null $sendSrc] || [null $sendDest]} {

	if {$pathname == 1} {
	    var srcfile $args
	} else {
	    if {$nec == 1} {
		echo Looking for non-EC version of $args...
		catch {find-geode -n $args} srcfile
	    } else {
		echo Looking for EC version of $args...
		catch {find-geode $args} srcfile
	    }
	}

	if (![null $srcfile]) {
	    var sendPatient $args
	    var sendPatientType $nec
	    var sendSrc $srcfile
	    catch {get-send-dest $srcfile} sendDest
	} else {
	    echo
	    error {Unable to find source .geo file}
	}
    }

    send-file $sendSrc $sendDest
    # hack to make sure that source files are up to date for now...
    src flush
    if {![null $run]} {
        run	$args
    }
}]

[defsubr get-send-dest {src} {
    global file-os file-root-dir

    if {[string c ${file-os} unix] == 0} {
	var pathfile /staff/pcgeos/Tools/swat/lib.new/pcs.pat
    } else {
	if {[string c ${file-os} win32] == 0} {
	    var pathfile ${file-root-dir}/Tools/swat/lib.new/pcs.pat
	} else {
	    var pathfile ${file-root-dir}/include/pcs.pat
	}
	var src [string subst $src \\ / g]
	var src [upcase $src]
    }

    var dest [file tail [file-mangle-for-dos $src]]

    if {![file exists $pathfile]} {
	echo Warning: couldn't find $pathfile: sending to default directory
	if {[string first library $src no_case]} {
	    return SYSTEM/$dest
	} else {
	    return WORLD/$dest
	}
    } else {
	[for {var i 0} {1} {var i [expr $i+1]} {
	    if {[catch {src read $pathfile $i} line] == 0} {
		if {[string c ${file-os} unix] != 0} {
		    var line [string subst $line \\\\ / g]
		    var line [string subst $line \\ / g]
		}
		if {[string c ${file-os} win32] == 0} {
		    #upcase the match entry for win32
		    var line [upcase $line]
		}

		if {[string match $src [index $line 0]] == 1} {
		    return [index $line 2]/$dest
		}
	    } else {
		return WORLD/$dest
	    }
    	}]
    }
}]


[defcommand send-file-old {src dest} swat_prog
{Usage:
    send-file <filename>
Synopsis:
    	sends a file to the target machine
}
{
    rpc call RPC_RECEIVE_FILE [type void] {} [type void]
    rpc-send-file $src $dest
}]

##############################################################################
#				upcase
##############################################################################
#
# SYNOPSIS:	    convert a mixed case string to uppercase
# PASS:		    a mixed case string
# CALLED BY:	    get-send-dest
# RETURN:	    uppercase version of the string
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dbaumann 02/07/96	Initial Revision
#
##############################################################################
[defsubr upcase {mcstr} {

    var nl [length $mcstr chars]
    var ucstr {}
    #97 == 'a', 122 == 'z'
    for {var i 0} {$i < $nl} {var i [expr $i+1]} {
	scan [index $mcstr $i chars] %c c
	if {$c >= 97 && $c <= 122} {
	    var c [expr $c-32]
	}
	var ucstr [format {%s%c} $ucstr $c]
    }
    return $ucstr
}]

