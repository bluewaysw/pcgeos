##############################################################################
#
#	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved
#
# PROJECT:	Native ethernet support
# MODULE:	Ethernet driver
# FILE:		ether.gp
#
# AUTHOR:	Todd Stumpf, July 19th, 1998
#
#	$Id:$
#
##############################################################################
#
# Specify permanent name first
#
name	ether.drv

#
# Specify geode type
#
type	driver, single

#
# Import kernel routine definitions
#
library	geos
library ui
library	netutils
library socket

#
# Desktop-related things
#
longname	"Ethernet driver"
tokenchars	"SKDR"
tokenid		0

#
# Define resources other than standard discardable code
#
resource Resident			fixed code read-only shared
resource EthernetCode			code shared read-only
resource EthernetInfoResource		lmem shared preload no-swap
resource EthernetUI			object
resource EthernetClassStructures	fixed read-only shared

#
# Exported routines
#
export	EthernetStrategy

