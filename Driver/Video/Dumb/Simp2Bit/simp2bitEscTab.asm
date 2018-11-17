COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Simp2Bit video driver
FILE:		simp2bitEscTab.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	Table of escape functions provided by the driver.

	$Id: simp2bitEscTab.asm,v 1.1 97/04/18 11:43:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	3
    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
    DefEscape	VidUnsetDevice, VID_ESC_UNSET_DEVICE	; uninitialize driver
    DefEscape	Simp2BitSetContrast, VID_ESC_SET_CONTRAST
