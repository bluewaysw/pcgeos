##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	iacp.tcl
# AUTHOR: 	Adam de Boor, Oct 13, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/13/92	Initial Revision
#
# DESCRIPTION:
#	Functions to print out the IACP data structures
#
#	$Id: iacp.tcl,v 1.3 93/07/31 22:36:54 jenny Exp $
#
###############################################################################

##############################################################################
#				iacp-print-server
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/13/92		Initial Revision
#
##############################################################################
[defsubr iacp-print-server {eltNum eltAddr numLeft {indent 0}}
{
    [case [value fetch ($eltAddr).ui::IACPS_mode] in
     0 {var mode N}
     1 {var mode F}
     2 {var mode I}
     default {var mode ?}]
    [if {[value fetch ($eltAddr).ui::IACPS_flags.ui::IACPSF_MULTIPLE_INSTANCES]}
    {
    	var flags M
    } else {
    	var flags S
    }]
    echo -n [format {%*s#%2d (%s%s): } $indent {} $eltNum $mode $flags]
    [fmtoptr [value fetch ($eltAddr).ui::IACPS_object.handle]
	     [value fetch ($eltAddr).ui::IACPS_object.chunk]]
    echo
    return 0
}]

##############################################################################
#				iacp-print-connection
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/13/92	Initial Revision
#
##############################################################################
[defsubr iacp-print-connection {seg c indent}
{
    if {[value fetch (*$seg:$c).ui::IACPCS_client.handle]} {
    	echo -n [format {%*s%04xh: } $indent {} $c]
	[fmtoptr [value fetch (*$seg:$c).ui::IACPCS_client.handle] 
		 [value fetch (*$seg:$c).ui::IACPCS_client.chunk]]
    } else {
    	echo -n [format {%*s%04xh: no client} $indent {} $c]
    }
    var q [value fetch (*$seg:$c).ui::IACPCS_holdQueue]
    if {$q != 0} {
    	echo [format { [hold queue = %04xh]} $q]
    } else {
    	echo
    }
    require chunk-size lm.tcl

    var ns [expr ([chunk-size $seg [value fetch $seg:$c word]]-[getvalue ui::IACPCS_servers])/4]
    for {var i 0} {$i < $ns} {var i [expr $i+1]} {
	echo -n [format {%*s-> } [expr $indent+8] {}]
	var s [value fetch  {&(*$seg:$c).ui::IACPCS_servers+$i}]
    	if {$s&0xffff0000} {
	    fmtoptr [expr ($s>>16)&0xffff] [expr $s&0xffff]
    	} else {
	    echo -n shutdown
    	}
	echo
    }
    return 0
}]

##############################################################################
#				iacp-print-list
##############################################################################
#
# SYNOPSIS:	Print out an IACPList structure nicely
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/13/92	Initial Revision
#
##############################################################################
[defsubr iacp-print-list {eltNum eltAddr numLeft cmd}
{
    var e [value fetch $eltAddr ui::IACPList]
    var tchars [field [field $e IACPL_token] GT_chars]
    if {[string match $cmd *-lc*]} {
    	var pconnect 1
    } else {
    	var pconnect 0
    }
    addr-preprocess $eltAddr seg off

    var numConnect [field $e IACPL_numConnect]

    echo [format {#%3d: "%s%s%s%s", %d; %d %s%s} $eltNum
    	    [index $tchars 0] [index $tchars 1]
	    [index $tchars 2] [index $tchars 3]
	    [field [field $e IACPL_token] GT_manufID]
	    $numConnect [pluralize connection $numConnect]
	    [if {$pconnect && $numConnect} {format :}]]

    if {$pconnect && $numConnect} {
    	[for {var c [field $e IACPL_connections]}
	     {$c != 0}
	     {var c [value fetch (*$seg:$c).ui::IACPCS_next]}
    	{
	    iacp-print-connection $seg $c 6
    	}]
    }

    var sa [field $e IACPL_servers]
    if {[value fetch (*$seg:$sa).CAH_count]} {
    	echo {      Servers:}
	carray-enum *$seg:$sa iacp-print-server 6
    } else {
    	echo {      No servers}
    }

    return 0
}]

##############################################################################
#				iacp-print-connections
##############################################################################
#
# SYNOPSIS:	print all connections for a given object, or just all
#		connections, if no object specified
# PASS:		obj = addr list of object for which to check
# CALLED BY:	iacp
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/22/92	Initial Revision
#
##############################################################################
[defsubr iacp-print-connections {{obj {}}}
{
    if {![null $obj]} {
    	var obj [list [handle id [index $obj 0]] [index $obj 1]]
    }
    carray-enum *ui::iacpListArray iacp-print-connections-in-list $obj
}]

[defsubr iacp-print-connections-in-list {eltNum eltAddr numLeft obj}
{
    addr-preprocess $eltAddr seg off

    [for {var c [value fetch ($eltAddr).ui::IACPL_connections]}
    	 {$c != 0}
	 {var c [value fetch (*$seg:$c).ui::IACPCS_next]}
    {
    	iacp-print-connection $seg $c 0
    }]
    return 0
}]


##############################################################################
#				iacp-print-doc
##############################################################################
#
# SYNOPSIS:	print info about an open document
# PASS:		eltNum	= index of element in doc array
#		eltAddr	= address expression of IACPDocument
#   	    	numLeft = number of elements still to print
# CALLED BY:	iacp via carray-enum
# RETURN:	0 (continue enumerating)
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 9/93		Initial Revision
#
##############################################################################
[defsubr iacp-print-doc {eltNum eltAddr numLeft args}
{
    require _disk_name fs
    require fmtoptr print

    var disk [value fetch ($eltAddr).ui::IACPD_disk]

    echo -n [format {%04xh [%s]: %08xh\n    server = } $disk [_disk_name $disk]
    	    	[value fetch ($eltAddr).ui::IACPD_id]]

    [fmtoptr [value fetch ($eltAddr).ui::IACPD_server.handle]
	     [value fetch ($eltAddr).ui::IACPD_server.chunk]]
    echo

    return 0
}]


[defcommand iacp {cmd} lib_app_driver
{Usage:
    iacp -ac 	    prints all connections
    iacp -l 	    prints all lists w/o connections
    iacp -d 	    prints all open documents
    iacp <obj>      prints all connections to which <obj> is party

Examples:
    "usage"	Explanation

Synopsis:
    short description of command's purpose

Notes:
    * Note on subcommand

    * Another note on a subcommand or usage

See also:
    comma-separated list of related commands
}
{
    require carray-enum chunkarr.tcl
    [case $cmd in
    	-ac {
	    iacp-print-connections {}
    	}
	{-l -lc} {
	    carray-enum *ui::iacpListArray iacp-print-list $cmd
      	}
    	{-d} {
	    carray-enum *ui::iacpDocArray iacp-print-doc
    	}
	default {
	    require addr-with-obj-flag user.tcl

    	    iacp-print-connections [get-chunk-addr-from-obj-addr [addr-with-obj-flag $cmd]]
    	}
    ]
}]
