##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	netlib.tcl
# FILE: 	netlib.tcl
# AUTHOR: 	Gene Anderson, Apr 22, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	4/22/93		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: netlib.tcl,v 1.4.12.1 97/03/29 11:25:44 canavese Exp $
#
###############################################################################

require carray-enum chunkarr.tcl

##############################################################################
#				netlib
##############################################################################
#
# SYNOPSIS:	Print information about the net library and related shme
# PASS:		args - random flags of your choosing
# SIDE EFFECTS:	
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	4/22/93	Initial Revision
#
##############################################################################

[defcommand netlib {args} lib_app_driver.net
{Usage:
    netlib [<args>]

Examples:
    "netlib -p"	    print list of ports open by the Comm driver
    "netlib -s"	    print list of sockets open by the Comm driver

Synopsis:
    Print various bits of net library shme.

Notes:
    * The args argument may be chosen from the following:
    	-d  	domain information
    	-p  	ports open by Comm driver
    	-s  	socket information for Comm driver

See also:
    pcp
}
{
    #
    # parse the flags
    #
    var domains 0 portinfo 0 commsock 0

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		d {var domains 1}
		p {var portinfo 1}
		s {var commsock 1}
		default {error [format {unknown option %s} $i]}
	    ]
	}
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    } else {
	var summary 1
    }
    #
    # print shme as requested
    #
    if {$domains} {
    	pcarray -N -tDomainStruct ^l[value fetch net::lmemBlockHandle]:[value fetch net::domainArray]
    }
    if {$portinfo} {
    	pcarray -tPortStruct ^l[value fetch Comm::lmemBlockHandle]:[value fetch Comm::portArrayOffset]
    }
    if {$commsock} {
    	carray-enum ^l[value fetch Comm::lmemBlockHandle]:[value fetch Comm::portArrayOffset] print-one-port
    }
}]


##############################################################################
#				print-one-style
##############################################################################
#
# SYNOPSIS:	Print a single style.
# CALLED BY:	ptext via carray-enum
# PASS:		elnum	- Element number
#   	    	address	- Address expression of PortStruct
#   	    	rsize	- Size of style
#   	    	extra	- List containing:
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	eca	 4/22/93	Initial Revision
#
##############################################################################
[defsubr print-one-port {elnum address rsize extra}
{
    var addr	[addr-parse $address]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]

    var pn [value fetch $seg:$off.PS_number]
    if {$pn != 255} {
    	var mc [value fetch $seg:$off.PS_socketArray]
    	echo [format {sockets for %s (at *%4xh:%xh)} [penum SerialPortNum $pn] $seg $mc]
    	pcarray -tSocketStruct *$seg:$mc
    } else {
    	echo {port closed}
    }
    return 0
}]


##############################################################################
#				pcp
##############################################################################
#
# SYNOPSIS:	Print a packet for the Comm driver
# PASS:		address - address of the packet
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	4/26/93	Initial Revision
#
##############################################################################

[defcommand pcp {address} lib_app_driver.net
{Usage:
    pcp [address]

Examples:
    pcp	es:di	    - print the packet at es:di

Synopsis:
    Print out a packet for the Comm driver

Notes:

See also:
    netlib
}
{
    var addr	[addr-parse $address]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]

    print PacketHeader $seg:$off

    var plen  	[value fetch $seg:$off.PH_strLen]

    byte $seg:$off+[size PacketHeader] $plen
}]
