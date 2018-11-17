##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	NetWare Driver
# FILE:		netware.gp
#
# REVISION HISTORY:
#	Eric	2/92		Initial version
#
# DESCRIPTION:	
#	This library allows PC/GEOS applications to access the Network
#	facilities such as messaging, semaphores, print queues, user account
#	info, file info, etc.
#
# RCS STAMP:
#	$Id: standalone.gp,v 1.1 97/04/18 11:48:49 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name standal.drvr

type	driver, single, system
#
# Imported Libraries
#
library geos
library net
#
# Desktop-related things
# 
longname	"Standalone Network Driver"
tokenchars	"SAND"
tokenid		0

#
# Specify alternate resource flags for anything non-standard
#
resource StandaloneResidentCode		code read-only shared fixed



