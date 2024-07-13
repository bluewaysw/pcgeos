##############################################################################
#
#	Copyright (c) GeoWorks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	DataStore
# FILE:		datastor.gp
#
# AUTHOR:	Cassie Hartzog, Oct 5 1995
#
#
# Parameters file for: datastore.geo
#
#	$Id: datastor.gp,v 1.1 97/04/04 17:53:54 newdeal Exp $
#
##############################################################################
#
#       Permanent name
#
name    datastor.lib

#
#       Long name and identification
#
longname        "DataStore Library"
tokenchars      "DTST"
tokenid         0

#
#       Specify geode type
#
type 	library, single
entry	DataStoreLibraryEntry

# from homescreen:
# 13K is the XIP value.  The non-XIP value is 20K.
#
#heapspace 	13k
#stack		2000

#
# 	Import kernel routine definitions
#
library geos
library text
library datax

#
# Define resources other than standard discardable code
#
nosort
resource Strings		read-only, shared, lmem
resource DSClassStructures 	fixed
#
# Exported routines
#
export DataStoreCreate
export DataStoreOpen
export DataStoreClose
export DataStoreDelete
export DataStoreRename

export DataStoreAddField
export DataStoreRenameField
export DataStoreDeleteField
export DataStoreFieldEnum

export DataStoreGetFieldCount
export DataStoreGetRecordCount
export DataStoreGetFlags
export DataStoreGetOwner
export DataStoreGetVersion
export DataStoreSetVersion
export DataStoreGetExtraData
export DataStoreSetExtraData
export DataStoreGetTimeStamp
export DataStoreSetTimeStamp

export DataStoreFieldNameToID
export DataStoreFieldIDToName
export DataStoreGetFieldInfo

export DataStoreNewRecord
export DataStoreLoadRecord
export DataStoreLoadRecordNum
export DataStoreSaveRecord
export DataStoreDiscardRecord
export DataStoreDeleteRecord
export DataStoreDeleteRecordNum

export DataStoreGetField
export DataStoreGetFieldChunk
export DataStoreGetFieldSize
export DataStoreSetField
export DataStoreRemoveFieldFromRecord

export DataStoreBuildIndex

export DataStoreGetFieldPtr
export DataStoreGetNumFields
export DataStoreMapRecordNumToID
export DataStoreStringSearch
export DataStoreRecordEnum

export DataStoreLockRecord
export DataStoreUnlockRecord

export DataStoreGetNextRecordID
export DataStoreSetNextRecordID
export DataStoreGetRecordID
export DataStoreSetRecordID

export DATASTORECREATE
export DATASTOREOPEN
export DATASTORECLOSE
export DATASTOREDELETE
export DATASTORERENAME

export DATASTOREADDFIELD
export DATASTORERENAMEFIELD
export DATASTOREDELETEFIELD
export DATASTOREFIELDENUM

export DATASTOREGETFIELDCOUNT
export DATASTOREGETRECORDCOUNT
export DATASTOREGETFLAGS
export DATASTOREGETOWNER
export DATASTOREGETVERSION
export DATASTORESETVERSION
export DATASTOREGETEXTRADATA
export DATASTORESETEXTRADATA
export DATASTOREGETTIMESTAMP
export DATASTORESETTIMESTAMP

export DATASTOREFIELDNAMETOID
export DATASTOREFIELDIDTONAME
export DATASTOREGETFIELDINFO

export DATASTORENEWRECORD
export DATASTORELOADRECORD
export DATASTORELOADRECORDNUM
export DATASTORESAVERECORD
export DATASTOREDISCARDRECORD
export DATASTOREDELETERECORD
export DATASTOREDELETERECORDNUM

export DATASTOREGETFIELD
export DATASTOREGETFIELDCHUNK
export DATASTOREGETFIELDSIZE
export DATASTORESETFIELD
export DATASTOREREMOVEFIELDFROMRECORD
export DATASTOREGETFIELDPTR
export DATASTOREGETNUMFIELDS
export DATASTOREMAPRECORDNUMTOID
export DATASTORESTRINGSEARCH
export DATASTORERECORDENUM

export DATASTORELOCKRECORD
export DATASTOREUNLOCKRECORD

export DATASTOREBUILDINDEX

export DATASTOREGETNEXTRECORDID
export DATASTORESETNEXTRECORDID
export DATASTOREGETRECORDID
export DATASTORESETRECORDID

export DataStoreSaveRecordNoUpdate
export DATASTORESAVERECORDNOUPDATE

export DSApplicationClass

export DataStoreGetCurrentTransactionNumber
export DATASTOREGETCURRENTTRANSACTIONNUMBER
