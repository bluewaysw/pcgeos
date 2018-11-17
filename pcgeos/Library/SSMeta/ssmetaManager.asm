
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 8/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial revision

DESCRIPTION:
		
	$Id: ssmetaManager.asm,v 1.1 97/04/07 10:44:05 newdeal Exp $

-------------------------------------------------------------------------------@

include geos.def
include	geode.def


;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the SSMeta lib is going to
;       be used in a system where all geodes (or most, at any rate)
;       are to be executed out of ROM.  
;------------------------------------------------------------------------------
ifndef FULL_EXECUTE_IN_PLACE
        FULL_EXECUTE_IN_PLACE           equ     FALSE
endif

;------------------------------------------------------------------------------
;  The .GP file only understands defined/not defined;
;  it can not deal with expression evaluation.
;  Thus, for the TRUE/FALSE conditionals, we define
;  GP symbols that _only_ get defined when the
;  condition is true.
;-----------------------------------------------------------------------------
if      FULL_EXECUTE_IN_PLACE
        GP_FULL_EXECUTE_IN_PLACE        equ     TRUE
endif

if FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif

include resource.def
include ec.def
include library.def
include lmem.def
include	dbase.def
include	vm.def
include heap.def
include hugearr.def
include localize.def
include system.def
include geoworks.def

UseLib	ui.def
UseLib	math.def
UseLib	cell.def
UseLib	parse.def
UseLib	ssheet.def
UseLib	ffile.def
DefLib	ssmeta.def


include ssmetaConstant.def

include ssmetaStrings.rdef

include ssmetaInitAndExitCode.asm
include ssmetaMain.asm
include ssmetaUtils.asm
include ssmetaDataRecord.asm

;
; initialization routines
;
global	SSMetaEntryRoutine:far
global	SSMetaInitForStorage:far
global	SSMetaInitForRetrieval:far
global	SSMetaInitForCutCopy:far
global	SSMetaDoneWithCutCopy:far
global	SSMetaInitForPaste:far
global	SSMetaDoneWithPaste:far
global	SSMetaDoneWithCutCopyNoRegister:far
;
; storage routines
;
global	SSMetaSetScrapSize:far
global	SSMetaDataArrayLocateOrAddEntry:far
global	SSMetaDataArrayAddEntry:far
;
; retrieval routines
;
global	SSMetaSeeIfScrapPresent:far
global	SSMetaGetScrapSize:far
global	SSMetaDataArrayGetNumEntries:far
global	SSMetaDataArrayResetEntryPointer:far
global	SSMetaDataArrayGetFirstEntry:far
global	SSMetaDataArrayGetNextEntry:far
global	SSMetaDataArrayGetEntryByToken:far
global	SSMetaDataArrayGetEntryByCoord:far
global	SSMetaDataArrayGetNthEntry:far
global	SSMetaDataArrayUnlock:far
global	SSMetaFormatCellText:far

C_SSMeta	segment resource
global	SSMETAINITFORSTORAGE:far
global	SSMETAINITFORRETRIEVAL:far
global	SSMETAINITFORCUTCOPY:far
global	SSMETADONEWITHCUTCOPY:far
global	SSMETADONEWITHCUTCOPYNOREGISTER:far
global	SSMETAINITFORPASTE:far
global	SSMETADONEWITHPASTE:far
global	SSMETASETSCRAPSIZE:far
global	SSMETADATAARRAYLOCATEORADDENTRY:far
global	SSMETADATAARRAYADDENTRY:far
global	SSMETASEEIFSCRAPPRESENT:far
global	SSMETAGETSCRAPSIZE:far
global	SSMETADATAARRAYGETNUMENTRIES:far
global	SSMETADATAARRAYRESETENTRYPOINTER:far
global	SSMETADATAARRAYGETFIRSTENTRY:far
global	SSMETADATAARRAYGETNEXTENTRY:far
global	SSMETADATAARRAYGETENTRYBYTOKEN:far
global	SSMETADATAARRAYGETENTRYBYCOORD:far
global	SSMETADATAARRAYGETNTHENTRY:far
global	SSMETADATAARRAYUNLOCK:far
global	SSMETAGETNUMBEROFDATARECORDS:far 
global	SSMETARESETFORDATARECORDS:far
global  SSMETAFIELDNAMELOCK:far
global	SSMETAFIELDNAMEUNLOCK:far
global  SSMETADATARECORDFIELDLOCK:far
global	SSMETADATARECORDFIELDUNLOCK:far
global	SSMETAFORMATCELLTEXT:far
include ssmetaC.asm
C_SSMeta	ends

InitCode	segment	resource

SSMetaEntryRoutine	proc	far
	clc
	ret
SSMetaEntryRoutine	endp

InitCode	ends
