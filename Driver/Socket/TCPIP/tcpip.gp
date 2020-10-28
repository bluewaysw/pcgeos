##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
#			GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# FILE:		tcpip.gp
#
# AUTHOR:	Jennifer Wu, Jul  5, 1994
#
#	$Id: tcpip.gp,v 1.1 97/04/18 11:57:04 newdeal Exp $
#
##############################################################################
#
name		tcpip.drvr
#
type		driver, single
#
longname 	"TCP/IP Driver"
tokenchars	"SKDR"
tokenid 	0
#
library	geos
library netutils
library socket #noload
library ansic
library accpnt

# Allow static linkage for the resolver library.
ifdef STATIC_LINK_RESOLVER
library resolver
else
library resolver noload
endif

#
# Define resources other than standard discardable code
#
resource ResidentCode 	fixed code read-only shared
resource Strings	shared lmem read-only
resource IPAddrCtrlUI	ui-object read-only shared
resource TcpipClassStructures	fixed read-only shared
#resource TCPIPCLASSSTRUCTURES 	fixed read-only shared

# other resources
resource InputQueue	shared lmem

#
# export classes
#
export IPAddressControlClass
