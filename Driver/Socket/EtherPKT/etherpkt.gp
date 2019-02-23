##############################################################################
#
#	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved
#
# PROJECT:	Native ethernet support
# MODULE:	Ethernet driver
# FILE:		etherodi.gp
#
# AUTHOR:	Todd Stumpf, July 19th, 1998
#
#	$Id:$
#
##############################################################################
#
# Specify permanent name first
#
name	etherpkt.drv

#
# Specify geode type
#
type	driver, single

#
# Import kernel routine definitions
#
library	geos
library	netutils
library	accpnt

#
# Desktop-related things
#
longname	"Packet Ethernet Driver"
tokenchars	"SKDR"
tokenid		0

#
# Process class
#
class	EtherProcessClass

stack 8192

#
# Define resources other than standard discardable code
#
resource ResidentCode			fixed code read-only shared
resource EtherClassStructures		fixed read-only shared
