COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		saverStrings.asm

AUTHOR:		Adam de Boor, Dec  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 8/92	Initial revision


DESCRIPTION:
	Localizable things.
		

	$Id: saverStrings.asm,v 1.1 97/04/07 10:44:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaverStrings	segment	lmem LMEM_TYPE_GENERAL

; Empty cursor to set as the window cursor so the mouse doesn't show up
; on-screen

blankCursor	chunk	PointerDef
	PointerDef <16, 16, 0, 0>
	byte	64 dup (0)
blankCursor	endc

SaveScreenMoniker chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		VMO_NO_MNEMONIC			; VMT_mnemonicOffset
	>
SBCS <	char	"Screen Saver", 0					>
DBCS <	wchar	"Screen Saver", 0					>
SaveScreenMoniker endc

LockScreenMoniker chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		VMO_NO_MNEMONIC			; VMT_mnemonicOffset
	>
SBCS <	char	"Security Lock", 0					>
DBCS <	wchar	"Security Lock", 0					>
LockScreenMoniker endc

SaverStrings	ends
