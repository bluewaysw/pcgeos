##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# FILE:		apmpwr.gp
#
# AUTHOR:	Todd Stumpf, Jun 21, 1994
#
#	This is the basic APM power driver module
#
#	$Id: apmpwr.gp,v 1.1 97/04/18 11:48:29 newdeal Exp $
#
##############################################################################
#
name apmpwr.drvr
#
longname "APM 1.0 Power Management"
#
type	driver, single, system
#
tokenchars "PWRD"
tokenid 0
#
library	geos
library	ui	noload

#  If there are PCMCIA ports in the system, load the PCMCIA library
ifdef	HAS_PCMCIA_PORTS_GP
library pcmcia
endif

#
resource Resident	fixed code read-only shared

# Minor Protocol increase for additional BIOS password routines
incminor	PowerPasswordStuff

