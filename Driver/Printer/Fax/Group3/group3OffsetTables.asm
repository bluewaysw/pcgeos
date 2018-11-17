COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3OffsetTables.asm

AUTHOR:		Andy Chiu, Feb 12, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/12/94   	Initial revision


DESCRIPTION:
	
	Offset tables that are used throughout this Driver.
	They are all put into this one file in case that anything
	might have to be duplicated accross procedures and/or files.

	$Id: group3OffsetTables.asm,v 1.1 97/04/18 11:52:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;
;		Tables needed in group3EvalFaxUI.asm
;
;-----------------------------------------------------------------------------
;
; These tables are used to get information about the print job
;
FJPTextObjects	word	\
	Group3NumberText,		; Receiver's fax #  (MUST BE FIRST!)
	Group3NameText,			; Receiver's name
	CoverPageFromText,		; Sender's Name
	CoverPageCompanyText,		; Sender's Company
	CoverPageVoicePhoneText,	; Sender's Voice Phone
	CoverPageFaxPhoneText,		; Sender's Fax Phone
	CoverPageFaxIDText		; Fax Machine's Fax ID

FJPTextOffsets	word	\
	FFH_faxNumber,			; MUST BE FIRST!  (See EvalPrintOptions)
	FFH_toName,
	FFH_senderName,
	FFH_senderCompany,
	FFH_senderVoice,
	FFH_senderFax,
	FFH_faxID

CheckHack	<length FJPTextObjects	eq length FJPTextOffsets>

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
	FFH_appName,
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
; This table tells how long the TTL line will be
;
BandLengthTable	word	\
	FAXFILE_TTL_STD_HEIGHT,			; PM_GRAPHICS_LOW_RES
	0,					; PM_GRAPHICS_MED_RES
	FAXFILE_TTL_FINE_HEIGHT			; PM_GRAPHICS_HI_RES


;-----------------------------------------------------------------------------
;
;		Tables needed in group3UI.asm
;
;-----------------------------------------------------------------------------
;
; Offsets to the strings that are used to read from the ini file
;
FileInitKeyOffsets		word	\
	offset fileInitAccessKey,
	offset fileInitLongDistanceKey,
	offset fileInitBillingCardKey

;
; Offsets to put info and get info about Dialing Assistance.
;
DialAssistTextOffsets		word	\
	DialAssistAccessText,
	DialAssistLongDistanceText,
	DialAssistBillingCardText

CheckHack	<length FileInitKeyOffsets eq length DialAssistTextOffsets>

;
; Tables to read from the CoverPageDialog and write the info in the
; appropiate place int the FaxInformationfile.
; Used in group3UI.asm
;
UIInformationObjChunks	word	CoverPageFromText,
				CoverPageCompanyText,
				CoverPageVoicePhoneText,
				CoverPageFaxPhoneText,
				CoverPageFaxIDText;

FileInformationOffsets	word	FIFI_fromName,
				FIFI_fromCompany,
				FIFI_fromVoicePhone,
				FIFI_fromFaxPhone,
				FIFI_fromFaxID;

CheckHack 	<length UIInformationObjChunks eq \
		 length FileInformationOffsets>



;-----------------------------------------------------------------------------
;
;		Tables needed in group3UI.asm
;
;-----------------------------------------------------------------------------
; Tables to read the objects in the CoverPageDialog and then place them
; into the GString to make the cover page.
; Used in group3CoverSheet.asm
;
ptrOffsets	word	CoverPageFromTextPtr-CoverGStringBase,
			CoverPageCompanyTextPtr-CoverGStringBase,
			CoverPageVoicePhoneTextPtr-CoverGStringBase,
			CoverPageFaxPhoneTextPtr-CoverGStringBase,
			Group3NameTextPtr-CoverGStringBase,
			CoverPageNumPagesPtr-CoverGStringBase

objChunks	word	CoverPageFromText,
			CoverPageCompanyText,
			CoverPageVoicePhoneText,
			CoverPageFaxPhoneText,
			Group3NameText,
			CoverPageNumPages

CheckHack	<length ptrOffsets eq length objChunks>

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
	offset	RanOutOfDiskSpace	; PDEC_RAN_OUT_OF_DISK_SPACE

;-----------------------------------------------------------------------------
;
;		Tables needed in group3AddrBook.asm
;
;-----------------------------------------------------------------------------
;
; This table is used to find the filter we need to screen out the text
; so we don't put anything bogus in the text object.
;
PhoneTextFilter		struct

	PTE_lowerBound	byte
	PTE_upperBound	byte

PhoneTextFilter	ends


PhoneTextFilterList	PhoneTextFilter	\
	<0, 31>,	; null - US is gone
			; space is included
	<33, 39>,	; ! - ' is gone
					; () is included
	<42, 43>,	; * - + is gone
					; , - - is included
	<46, 47>,	; . - / is gone
					; 0 - 9 is included
	<58, 255>	; all the rest is gone.















