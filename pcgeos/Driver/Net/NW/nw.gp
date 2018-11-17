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
#	$Id: nw.gp,v 1.1 97/04/18 11:48:41 newdeal Exp $
#
##############################################################################

name nw.drvr

type	driver, single, system
#
# Imported Libraries
#

library geos
library net
#
# Desktop-related things
# 

longname	"NetWare Driver"
tokenchars	"NWRD"
tokenid		0

#
# Specify alternate resource flags for anything non-standard
#

resource NetWareResidentCode		code read-only shared fixed
resource NetWareInitCode		code read-only shared discard-only
resource NetWareCommonCode		code read-only shared
resource NetWareIPXCode			code read-only shared
resource NetWareSemaphoreCode		code read-only shared
