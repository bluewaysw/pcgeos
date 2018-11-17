COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Cyber16 Video Driver
FILE:		cyber16EscTab.asm

AUTHOR:		Allen Yuen, Mar 25, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/25/99   	Initial revision


DESCRIPTION:
		
	This file contains the table of escape functions provided by the driver

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

ifidn	PRODUCT, <>			; default version is NTSC
DefEscapeTable	7
else
DefEscapeTable	6
endif	; PRODUCT, <>

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
    DefEscape	Cyber16GetHorizPosParams, VID_ESC_GET_HORIZ_POS_PARAMS
    DefEscape	Cyber16GetVertPosParams, VID_ESC_GET_VERT_POS_PARAMS
    DefEscape	Cyber16SetHorizPos, VID_ESC_SET_HORIZ_POS
    DefEscape	Cyber16SetVertPos, VID_ESC_SET_VERT_POS
ifidn	PRODUCT, <>			; default version is NTSC
    DefEscape	Cyber16SetTVSubcarrierFreq, VID_ESC_SET_TV_SUBCARRIER_FREQ
endif	; PRODUCT, <>
    DefEscape	Cyber16SetBlackWhite, VID_ESC_SET_BLACK_WHITE
