COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiramisu
MODULE:		Fax
FILE:		faxprintOffsetTables.asm

AUTHOR:		Andy Chiu, Feb 12, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/12/94   	Initial revision
	jdashe	11/2/94		Snarfed for tiramisu


DESCRIPTION:
	
	Offset tables that are used throughout this Driver.
	They are all put into this one file in case that anything
	might have to be duplicated accross procedures and/or files.

	$Id: faxprintOffsetTables.asm,v 1.1 97/04/18 11:53:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;
;		Tables needed in group3EvalFaxUI.asm
;
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;
;		Tables needed in group3StartJob.asm
;
;-----------------------------------------------------------------------------

;
; Given the type of resolution of the fax, this table gives the
; resolution value.  (This table is also used in group3StartPage.asm
;
FaxVerticalResolution	word	\
	FAX_STD_Y_RES,			; PM_GRAPHICS_LOW_RES
	0,				; PM_GRAPHICS_MED_RES (none)
	FAX_FINE_Y_RES			; PM_GRAPHICS_HI_RES

;
; These two tables are used to get data from the JobParamters and
; write them into the FaxFileHeader.
;
.warn -field
StartJobParameterOffsets	word	\
	JP_parent,
	JP_documentName,
	JP_printerData.FFH_faxNumber,
	JP_printerData.FFH_toName,
	JP_printerData.FFH_senderVoice,
	JP_printerData.FFH_senderFax,
	JP_printerData.FFH_faxID,
	JP_printerData.FFH_access,
	JP_printerData.FFH_longDistance,
	JP_printerData.FFH_billCard,
	JP_printerData.FFH_fileName
.warn @field

StartJobFaxFileOffsets		word	\
	FFH_bodyPageCount,
	FFH_documentName,
	FFH_faxNumber,
	FFH_toName,
	FFH_senderVoice,
	FFH_senderFax,
	FFH_faxID,
	FFH_access,
	FFH_longDistance,
	FFH_billCard,
	FFH_fileName
CheckHack	<length StartJobParameterOffsets eq \
		 length StartJobFaxFileOffsets >


;-----------------------------------------------------------------------------
;
;		Tables needed in group3StartPage.asm
;
;-----------------------------------------------------------------------------
;
; Given the type of resolution of the fax, this table gives the
; resolution value.  (This is already defined above
;
;FaxVerticalResolution	word	\
;	FAX_STD_Y_RES,			; PM_GRAPHICS_LOW_RES
;	0,				; PM_GRAPHICS_MED_RES (none)
;	FAX_FINE_Y_RES			; PM_GRAPHICS_HI_RES
;

;
; This table tells how long the TTL line will be and is not used anymore.
;
;BandLengthTable	word	\
;	FAXFILE_TTL_STD_HEIGHT,			; PM_GRAPHICS_LOW_RES
;	0,					; PM_GRAPHICS_MED_RES
;	FAXFILE_TTL_FINE_HEIGHT			; PM_GRAPHICS_HI_RES

;-----------------------------------------------------------------------------
;
;		Tables needed in group3EndJob.asm
;
;-----------------------------------------------------------------------------
;
; This table is used to know the appropiate string to display to the user
; if this error condition occurs.  A Zero indicates that no error
; message is to be poped up.
;
PrintDriverErrorCodeMessages	word	\
	0,				; Not en error.
	0,				; PDEC_USER_SAYS_NO_DISK_SPACE
	offset	CannotCreateFaxFile,	; PDEC_CANNOT_CREATE_FAX_FILE
	offset	CannotResizeJobParams,	; PDEC_CANNOT_RESIZE_JOB_PARAMETERS
	offset	RanOutOfDiskSpace,	; PDEC_RAN_OUT_OF_DISK_SPACE
	offset	RanOutOfMemory		; PDEC_NOT_ENOUGH_MEMORY 














