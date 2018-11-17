##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	Serial/IR communication protocol
# MODULE:	Loopback driver
# FILE:		loopback.gp
#
# AUTHOR:	Steve Jang, 9/8
#
#	$Id: loopback.gp,v 1.1 97/04/18 11:57:21 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	loopback .drv
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
longname	"Loopback driver"
tokenchars	"SKDR"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident			fixed code read-only shared
resource LoopbackCode			code shared read-only
resource LoopbackInfoResource		lmem shared preload no-swap
resource LoopbackUI			object
resource LoopbackClassStructures	fixed read-only shared
#
# Exported routines
#
export	LoopbackStrategy

