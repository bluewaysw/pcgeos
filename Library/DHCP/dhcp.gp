##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	DHCP
# FILE:		dhcp.gp
#
# AUTHOR:	Eric Weber, Jun 26, 1995
#
#
# 
#
#	$Id: dhcp.gp,v 1.1 97/04/04 17:53:00 newdeal Exp $
#
##############################################################################
#
name	dhcp.lib
#
# Specify the type of geode
#
type library, single, discardable-dgroup

#
# Define the library entry point
#
entry	DHCPEntry

#
# Import definitions from the kernel
#
library geos
library	ui
library	socket
library accpnt

#
# Desktop-related things
#
longname        "DHCP Library"
tokenchars      "DHCP"
tokenid         0

#
# Code resources
#
nosort
resource DHCPCode		code read-only shared

# other resources
resource FixedData		fixed

#
# exported routines
#
export	DHCPConfigure
