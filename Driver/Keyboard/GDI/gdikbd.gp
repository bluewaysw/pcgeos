##############################################################################
#
#	(c) Copyright Geoworks 1996 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# MODULE:	
# FILE:		gdi-kbd.gp
#
# AUTHOR:	Kenneth Liu, Apr 24, 1996
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#	kliu	4/24/96		Initial version.
#
# 
#
#	$Id: gdiKbd.gp,v 1.1 97/04/18 11:47:52 newdeal Exp $
#
##############################################################################
#

#
# Specify permanent name first
#
name 	gdikbd.drvr

#
# Specify geode type
#
type 	driver, single

#
# Import kernel routine definitions
#
library geos

#
# Desktop-related things
#
longname	"GDI Keyboard Driver"
tokenchars 	"GDIK"
tokenid		0

#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource Movable preload shared code read-only discard-only
resource KbdExtendedInfoSeg lmem,read-only,shared,conforming






