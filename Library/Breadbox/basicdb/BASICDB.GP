############################################################################
#
#               Copyright (c) Breadbox Computer Company 1998
#                        -- All Rights Reserved --
#
# PROJECT:      Generic Database System
# MODULE:       Basic Database System
# FILE:         basicDB.gp
#
# AUTHOR:       Gerd Boerrigter
#
# $Header: /Home Bulletin Board/Library/BasicDB/BASICDB.GP 24    7/16/98 18:29 Gerdb $
#
# DESCRIPTION:
#   Geode definitions for the Multimedia Extension Library.
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   98-03-09  GerdB     Initial version.
#
############################################################################

name basicdb.lib
longname "Basic Database Library"
tokenchars "BDbL"
tokenid 16431

#platform breadbox, geos20   jfh 7/12/99
platform geos201


type    library, single, c-api

#
# Define library entry point
#
# entry   MediaExtLibraryEntry

#
# Libraries: list which libraries are used by the geode.
#
library geos
library ansic

# library hwlib
# exempt hwlib
#
# Resources
#

#
# Exported classes and routines
#
export DataBaseClass

export BASICDBGRABEXCLUSIVE                 # BasicDBGrabExclusive
export BASICDBSTRINGSEARCH                  # BasicDBStringSearch
export BASICDBCREATE                        # BasicDBCreate
export BASICDBCREATERECORD                  # BasicDBCreateRecord
export BASICDBDUPLICATERECORD               # BasicDBDuplicateRecord
export BASICDBSAVERECORD                    # BasicDBSaveRecord
export BASICDBDISCARDRECORD                 # BasicDBDiscardRecord
export BASICDBGETRECORD                     # BasicDBGetRecord
export BASICDBGETRECORDBYELEMNUM            # BasicDBGetRecordByElemNum
export BASICDBGETRECORDBYINDEX              # BasicDBGetRecordByIndex
export BASICDBDELETERECORD                  # BasicDBDeleteRecord
export BASICDBDELETERECORDBYID              # BasicDBDeleteRecordByID
export BASICDBGETRECORDID                   # BasicDBGetRecordID
export BASICDBGETELEMNUMFROMID              # BasicDBGetElemNumFromID
export BASICDBADDFIELD                      # BasicDBAddField
export BASICDBDELETEFIELD                   # BasicDBDeleteField
export BASICDBSETFIELDDATA                  # BasicDBSetFieldData
export BASICDBGETFIELDDATA                  # BasicDBGetFieldData
export BASICDBGETPTRTOFIELDDATA             # BasicDBGetPtrToFieldData
export BASICDBGETFIELDDATASIZE              # BasicDBGetFieldDataSize
export BASICDBSETFIELDNAME                  # BasicDBSetFieldName
export BASICDBGETFIELDNAME                  # BasicDBGetFieldName
export BASICDBGETFIELDID                    # BasicDBGetFieldID
export BASICDBGETFIELDIDPTR                 # BasicDBGetFieldIDPtr
export BASICDBINDEXCREATE                   # BasicDBIndexCreate
export BASICDBINDEXDESTROY                  # BasicDBIndexDestroy
export BASICDBINDEXELEMENTADD               # BasicDBIndexElementAdd
export BASICDBINDEXELEMENTDELETE            # BasicDBIndexElementDelete
export BASICDBINDEXGETCOUNT                 # BasicDBIndexGetCount

# 1.1
incminor

export BASICDBGETRECORDIDBYINDEX            # BasicDBGetRecordIDByIndex
export BASICDBRELEASEEXCLUSIVE				# BasicDBReleaseExclusive
export BASICDBINDEXELEMENTFIND				# BasicDBIndexElementFind
export BASICDBGETFIELDCOUNT					# BasicDBGetFieldCount

# 1.2
incminor

export BASICDBGETRECORDUSERID               # BasicDBGetRecordUserID
export BASICDBSETRECORDUSERID               # BasicDBSetRecordUserID


usernotes "Copyright 1998 Breadbox Computer Company"
