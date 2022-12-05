##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# FILE:		irlmp.gp
#
# AUTHOR:	Chung Liu, Mar  6, 1995
#
# Geode definitions for the IrLMP Library.
#
#	$Id: irlmp.gp,v 1.1 97/04/05 01:08:03 newdeal Exp $
#
##############################################################################
#
name 		irlmp.lib
type		library, single, discardable-dgroup
longname	"IrLMP Library"
tokenchars	"ILMP"
tokenid		0
#class		IrlmpProcessClass
entry		IrlmpLibraryEntry
#
# Required libraries
#
library geos
library ui
library netutils
#
# Resources
#
resource IrlmpFsmObjects object
resource IasFsmObjects object
resource ResidentCode fixed code read-only

ifdef GP_FULL_EXECUTE_IN_PLACE
resource ResidentXIP fixed code read-only
endif


#
# Object classes
#
export StationFsmClass
export IrlapFsmClass
export IasClientFsmClass
#
# Exported Routines
#
export IrlmpRegister
export IrlmpUnregister
export IrlmpDiscoverDevicesRequest
export IrlmpConnectRequest
export IrlmpConnectResponse
export IrlmpDisconnectRequest
export IrlmpStatusRequest
export IrlmpDataRequest
export IrlmpUDataRequest
export IrlmpGetValueByClassRequest
export IrlmpDisconnectIas
export IrlmpGetPacketSize

export TTPRegister
export TTPUnregister
export TTPConnectRequest
export TTPConnectResponse
export TTPDataRequest
export TTPTxQueueGetFreeCount
export TTPDisconnectRequest

export TTPStatusRequest
export TTPAdvanceCredit

export IRDBOPENDATABASE
export IRDBCLOSEDATABASE
export IrdbCreateEntry
export IrdbAddAttribute

# C stubs
export IRDBCREATEENTRY
export IRDBDELETEENTRY
export IRDBADDATTRIBUTE

incminor
export IRLMPREGISTER
export IRLMPUNREGISTER
export IRLMPDISCOVERDEVICESREQUEST
export IRLMPCONNECTREQUEST
export IRLMPCONNECTRESPONSE
export IRLMPDISCONNECTREQUEST
export IRLMPSTATUSREQUEST
export IRLMPDATAREQUEST
export IRLMPUDATAREQUEST
export IRLMPGETPACKETSIZE
export IRLMPDISCONNECTIAS
export IRLMPGETVALUEBYCLASSREQUEST

incminor
export TTPREGISTER
export TTPUNREGISTER
export TTPCONNECTREQUEST
export TTPCONNECTRESPONSE
export TTPDATAREQUEST
export TTPTXQUEUEGETFREECOUNT
export TTPDISCONNECTREQUEST
export TTPSTATUSREQUEST
export TTPADVANCECREDIT

