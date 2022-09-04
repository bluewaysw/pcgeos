COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Win
FILE:		winFieldData.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

DESCRIPTION:
	This file contains data for drawing open look fields.

	$Id: cwinFieldData.asm,v 2.12 94/05/27 16:34:44 skarpi Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;		Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;		Data
;------------------------------------------------------------------------------

if _FXIP
RegionResourceXIP segment resource
else
Init segment resource
endif

if not _MAC

; CHANGE to use same field for all UI's, so we don't get oddball corners
; peaking through in some UI's.
;
fieldRegion	label	Region
	word	-1,						EOREGREC
	word	PARAM_3, 0, PARAM_2,				EOREGREC
	word	EOREGREC

else

; MAC ui is a hack, so curve it to get the proper effect on the menu bars...
;
fieldRegion	label	Region
	word	-1,						EOREGREC
	word	0, 5, PARAM_2-5,				EOREGREC
	word	1, 4, PARAM_2-4,				EOREGREC
	word	2, 2, PARAM_2-2,				EOREGREC
	word	4, 1, PARAM_2-1,				EOREGREC
	word	PARAM_3-5, 0, PARAM_2,				EOREGREC
	word	PARAM_3-4, 1, PARAM_2-1,			EOREGREC
	word	PARAM_3-2, 2, PARAM_2-2,			EOREGREC
	word	PARAM_3-1, 4, PARAM_2-4,			EOREGREC
	word	PARAM_3, 5, PARAM_2-5,				EOREGREC
	word	EOREGREC
endif

if _FXIP
RegionResourceXIP ends
else
Init ends
endif
