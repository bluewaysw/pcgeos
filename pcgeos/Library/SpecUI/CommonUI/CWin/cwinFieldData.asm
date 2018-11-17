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

	$Id: cwinFieldData.asm,v 1.1 97/04/07 10:53:00 newdeal Exp $

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


; CHANGE to use same field for all UI's, so we don't get oddball corners
; peaking through in some UI's.
;
fieldRegion	label	Region
	word	-1,						EOREGREC
	word	PARAM_3, 0, PARAM_2,				EOREGREC
	word	EOREGREC


if _FXIP
RegionResourceXIP ends
else
Init ends
endif
