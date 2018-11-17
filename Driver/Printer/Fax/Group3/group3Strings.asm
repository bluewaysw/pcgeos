COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3Strings.asm

AUTHOR:		Andy Chiu, Jan  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/ 1/94   	Initial revision


DESCRIPTION:
	Contains code segment strings that are used in the Group3
	Fax Printer Driver.
		

	$Id: group3Strings.asm,v 1.1 97/04/18 11:52:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

blankString	byte	0		; null string

faxFilePrefix		char	"FAX_",0

;
;Locations of where fax files are put.  Fax Disk handle is in SP_PRIVATE data
;and is declared in group3Constant.def
;
faxDir		char	"FAX",0

;
; Default address book that's used.  For group3AddrBook.asm
;
if _USE_PALM_ADDR_BOOK


addressBookFileName	char	"Address Book"
addressBookPath		char	0
ADDRESS_BOOK_DISK_HANDLE	equ	SP_DOCUMENT
endif

;
; For group3UI.asm  Strings that are used.
;
faxInformationFileName	char	"Fax Information",0
fileInitFaxCategory	char	"fax",0
fileInitAccessKey	char	"access",0
fileInitLongDistanceKey	char	"longdist",0
fileInitBillingCardKey	char	"billcard",0


;
; Tokens for the fax defaults file and the fax file.
;
faxDefaultsToken   GeodeToken <<'FXDF'>, MANUFACTURER_ID_GEOWORKS>

;
; Token for the FaxSpooler.
;
SpoolerToken	GeodeToken <<'FXSN'>, MANUFACTURER_ID_GEOWORKS>

;;char	"FXSN",0,0	; Token to identify
			; spooler with.














