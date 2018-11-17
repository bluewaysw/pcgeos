##############################################################################
#
#       Copyright (c) Geoworks 1991 -- All Rights Reserved
#
# PROJECT:     PC GEOS
# MODULE:      
# FILE:        ssmeta.gp
#
# AUTHOR:      Cheng
#
#
# Geode parameters for the spreadsheet meta library
#
#       $Id: ssmeta.gp,v 1.1 97/04/07 10:44:07 newdeal Exp $
#
##############################################################################
#
# Specify the geode's permanent name
#
name ssmeta.lib

#
# Specify the type of geode (this is both a library, so other geodes can
# use the functions, and a driver, so it is allowed to access I/O ports).
# It may only be loaded once.
#
type library, single

#
# Define the library entry point
#
entry SSMetaEntryRoutine

#
# Import definitions from the kernel
#
library geos
library ui
library math
#
# Geode type
#
type	library, single
#
# Desktop-related things
#
ifdef DO_DBCS
longname        "SSMeta Lib"
else
longname        "SSheet Meta Library"
endif
tokenchars      "SSMT"
tokenid         0

#
# Specify alternate resource flags for anything non-standard
#
nosort
resource InitCode           	preload, shared, read-only, code, discard-only
resource SSMetaCode		code read-only shared
resource SSMetaDataRecordCode		code read-only shared
resource C_SSMeta		code read-only shared
resource StringsResource	lmem read-only shared

#
# initialization routines
#
export	SSMetaInitForStorage
export	SSMetaInitForRetrieval
export	SSMetaInitForCutCopy
export	SSMetaDoneWithCutCopy
export	SSMetaInitForPaste
export	SSMetaDoneWithPaste
#
# storage routines
#
export	SSMetaSetScrapSize
export	SSMetaDataArrayLocateOrAddEntry
export	SSMetaDataArrayAddEntry
#
# retrieval routines
#
export	SSMetaSeeIfScrapPresent
export	SSMetaGetScrapSize
export	SSMetaDataArrayGetNumEntries
export	SSMetaDataArrayResetEntryPointer
export	SSMetaDataArrayGetFirstEntry
export	SSMetaDataArrayGetNextEntry
export	SSMetaDataArrayGetEntryByToken
export	SSMetaDataArrayGetEntryByCoord
export	SSMetaDataArrayGetNthEntry
export	SSMetaDataArrayUnlock
#
# C stubs
#
export	SSMETAINITFORSTORAGE
export	SSMETAINITFORRETRIEVAL
export	SSMETAINITFORCUTCOPY
export	SSMETADONEWITHCUTCOPY
export	SSMETAINITFORPASTE
export	SSMETADONEWITHPASTE
export	SSMETASETSCRAPSIZE
export	SSMETADATAARRAYLOCATEORADDENTRY
export	SSMETADATAARRAYADDENTRY
export	SSMETASEEIFSCRAPPRESENT
export	SSMETAGETSCRAPSIZE
export	SSMETADATAARRAYGETNUMENTRIES
export	SSMETADATAARRAYRESETENTRYPOINTER
export	SSMETADATAARRAYGETFIRSTENTRY
export	SSMETADATAARRAYGETNEXTENTRY
export	SSMETADATAARRAYGETENTRYBYTOKEN
export	SSMETADATAARRAYGETENTRYBYCOORD
export	SSMETADATAARRAYGETNTHENTRY
export	SSMETADATAARRAYUNLOCK
export	SSMETAGETNUMBEROFDATARECORDS
export	SSMETARESETFORDATARECORDS
export	SSMETAFIELDNAMELOCK
export	SSMETAFIELDNAMEUNLOCK
export	SSMETADATARECORDFIELDLOCK
export	SSMETADATARECORDFIELDUNLOCK
export	SSMETAFORMATCELLTEXT

export	SSMetaGetNumberOfDataRecords
export	SSMetaResetForDataRecords
export	SSMetaFieldNameLock
export	SSMetaFieldNameUnlock
export	SSMetaDataRecordFieldLock
export	SSMetaDataRecordFieldUnlock
export	SSMetaFormatCellText

export	SSMetaDoneWithCutCopyNoRegister
export	SSMETADONEWITHCUTCOPYNOREGISTER

#
# XIP-enabled
#
