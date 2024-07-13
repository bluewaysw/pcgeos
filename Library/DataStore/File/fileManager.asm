COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore
FILE:		fileManager.asm

AUTHOR:		Cassie Hartzog, Oct  5, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	10/ 5/95	Initial revision


DESCRIPTION:

	$Id: fileManager.asm,v 1.1 97/04/04 17:53:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;--------------------------------------------------------------------------
;			Def files
;--------------------------------------------------------------------------

include	dsGeode.def
include	timer.def		; for TimerSleep
include timedate.def		; for record time stamping
include	hugearr.def
include Internal/threadIn.def
include	Objects/vTextC.def	; for TextSearchInString

;--------------------------------------------------------------------------
;			Module-specific definitions
;--------------------------------------------------------------------------

DFFileOperationType	etype	byte, 0
	DFFOT_RENAME		enum DFFileOperationType
	DFFOT_DELETE		enum DFFileOperationType

TIME_STAMP_FIELD_ID equ 0 	;Field Id for time stamp is currently
				;hard coded to always be zero.


;--------------------------------------------------------------------------
;			Code files
;--------------------------------------------------------------------------

include	fileOpen.asm
include	fileMisc.asm
include	fileFieldName.asm
include	fileAccess.asm
include fileEC.asm
include fileAPI.asm
