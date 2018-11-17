##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Clavin
# FILE:		file.gp
#
# AUTHOR:	Chung Liu, May 31, 1994
#
#
# Data Driver for the Mailbox Library.
#
#	$Id: filedd.gp,v 1.1 97/04/18 11:41:46 newdeal Exp $
#
##############################################################################
#
name filedd.drvr

type driver, single, discardable-dgroup

#
# Imported Libraries
#
library geos
library mailbox

#
# Desktop-related things
#
longname "File Data Driver"
tokenchars "MBDD"
tokenid 0

#
# Resource definitions
#
resource Resident 	fixed code shared read-only
resource Movable	code read-only shared
resource FileDDState	lmem shared


