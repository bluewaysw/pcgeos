COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore
MODULE:	        Manager
FILE:		managerManager.asm

AUTHOR:		Cassie Hartzog, Oct  5, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	10/ 5/95	Initial revision


DESCRIPTION:
	

	$Id: managerManager.asm,v 1.1 97/04/04 17:53:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;--------------------------------------------------------------------------
;		Definition files
;--------------------------------------------------------------------------

include	dsGeode.def

;-----------------------------------------------------------------------
;		Constants & Structures
;-----------------------------------------------------------------------

LOAD_RECORD_WITH_ID 	=	0	;Load a record using a record id
LOAD_RECORD_WITH_NUM	=	1	;Load a record using a record num


DSCloseFlags record
	:7
	DSCF_DISCARD_LOCKED_RECORDS:1
DSCloseFlags end


;
; The DSElement array is a NameArray of open DataStores.
; There is one DSElement per open DataStore file. Any information
; needed by the DataStore Manager about a DataStore file goes here.
;

DSElementData struct
	DSED_fileHandle		hptr.FileHandle	; of the DataStore file
	DSED_flags		DSElementFlags  ; defined in dsConstant.def
	align word				; word align for swat
DSElementData ends

DSElement struct
	DSE_meta	RefElementHeader<>
	DSE_data	DSElementData
	DSE_name	label	TCHAR
DSElement ends

;
; A new DSSessionElement is added to the DSSession ChunkArray each time
; a DataStore is succssfully opened.  All information needed by the
; DataStore Manager about a session goes here.
;
DSSessionElement struct
	DSSE_client		hptr	; GeodeHandle for this session
	DSSE_notifObj		optr	; notification object
	DSSE_dsToken		word	; DSElement token
	DSSE_recordID		RecordID ; current locked record
	DSSE_buffer		hptr	; record buffer handle
	DSSE_session		word    ; the application token
	DSSE_dsFlags		DSElementFlags
					;locks for this session's record
DSSessionElement ends

;
; The ManagerLMemBlock is created when the library is intialized and
; freed when it exits. The block contains the DSElement NameArray and
; the DSSessionElement ChunkArray.
;
ManagerLMemBlockHeader struct
    MLBH_meta		LMemBlockHeader 
    MLBH_sessionArray	lptr     	 ; ChunkHandle of DSSession array
    MLBH_dsElementArray	lptr		 ; ChunkHandle of DSElement name array
    MLBH_tokenCount     word		 ; next session token value
ManagerLMemBlockHeader ends


;-----------------------------------------------------------------------
;		     Global Variables
;-----------------------------------------------------------------------

udata	segment

	; Handle of Manager LMem Block.
	; Contains the DSElement array and DSSession array.

	dsMLBHandle	hptr
	
udata 	ends


;--------------------------------------------------------------------------
;			Code files
;--------------------------------------------------------------------------

include managerAccess.asm
include managerSynch.asm
include managerDataStore.asm
include managerRecord.asm
include	managerInit.asm




