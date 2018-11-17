COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2EscTab.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	This file contains the table of escape functions provided by the driver

	$Id: clr2EscTab.asm,v 1.1 97/04/18 11:43:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;		Escape Function Table
;------------------------------------------------------------------------------

DefEscapeTable	1

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
