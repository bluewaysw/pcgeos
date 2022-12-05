##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Libraries -- PCCom Routines
# FILE:		pccom.gp
#
# AUTHOR:	Cassie Hartzog, Nov 8, 1993
#
#
#	$Id: pccom.gp,v 1.1 97/04/05 01:25:45 newdeal Exp $
#
##############################################################################
#
# Specify name of geode
#
name pccom.lib

#
# Specify type of geode
#
ifdef	GP_FULL_EXECUTE_IN_PLACE
type library, single, discardable-dgroup
else
type library, single
endif

entry PCComEntry

#
# Import library routine definitions
#
library geos
library ui

#
# Desktop-related things
#
longname	"PCCom Library"
tokenchars	"PCOM"
tokenid		0

#
# Override default resource flags
#

resource Init			preload, shared, read-only, code
resource Main			shared, read-only, code
resource PCComFileSelector	shared, read-only, code
resource Fixed			fixed, shared, read-only, code
resource Strings		lmem, read-only, shared
resource PCComClassStructures	fixed read-only shared
ifdef   GP_FULL_EXECUTE_IN_PLACE
resource FileExtAttrXIP	read-only, shared
endif

#
# Exported routines
#
export	PCCOMINIT
export	PCCOMEXIT
export	PCCOMABORT
#
#  Exported classes
#
export	PCComClass

incminor
#
#  new routines (responder)
#
export	PCCOMGET
export	PCCOMSEND
export	PCCOMSTATUS
export	PCCOMCD
export	PCCOMMKDIR
export	PCCOMGETFILESIZE
export	PCCOMDIR
export	PCCOMLISTDRIVES
export	PCCOMFILEENUM
export	PCCOMREMARK
export	PCCOMPWD
export	PCCOMGETFREESPACE
#
#  new classes (responder)
#
export	PCComFileSelectorClass

incminor
export	PCCOMDATA
export	PCCOMSETDATANOTIFICATION
export	PCCOMACKDATA
export	PCCOMWAIT
