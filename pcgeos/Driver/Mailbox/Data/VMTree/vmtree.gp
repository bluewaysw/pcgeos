##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Clavin
# FILE:		vmtree.gp
#
# AUTHOR:	Chung Liu, Jun 13, 1994
#
#
# VM Tree Data Driver for the Mailbox Library
#
#	$Id: vmtree.gp,v 1.1 97/04/18 11:41:49 newdeal Exp $
#
##############################################################################
#
name vmtree.drvr
type driver, single, discardable-dgroup

#
# Imported Libraries
#
library geos
library mailbox

#
# Desktop-related things
#
longname "VM Tree Data Driver"
tokenchars "MBDD"
tokenid 0

#
# Resource definitions
#
resource Resident 	fixed code shared read-only
resource Movable	code read-only shared
resource VMTreeState	lmem shared

