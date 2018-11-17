COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		gdi-keyboardManager.asm

AUTHOR:		Kenneth Liu, Jun  6, 1996

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu		6/ 6/96   	Initial revision


DESCRIPTION:
	Manager file for GDI Keyboard Driver.
		

	$Id: gdiKeyboardManager.asm,v 1.1 97/04/18 11:47:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_KeyboardDriver			=	1
_Driver				=	1

;----------------------------------------------------------------------------
;			System Inclues
;----------------------------------------------------------------------------

include geos.def
include	geode.def
include resource.def
include ec.def
include driver.def
include heap.def

include input.def
include timedate.def
include	system.def
include initfile.def
include file.def
include localize.def
include char.def
include	sysstats.def
include assert.def

include Objects/inputC.def

include Internal/im.def
include Internal/semInt.def
include Internal/interrup.def

;----------------------------------------------------------------------------
;			Libraries
;----------------------------------------------------------------------------

UseLib	gdi.def

;----------------------------------------------------------------------------
;			Driver Declaration
;----------------------------------------------------------------------------

DefDriver Internal/kbdDr.def

;----------------------------------------------------------------------------
;			Internal def files
;----------------------------------------------------------------------------

include gdiKeyboardConstant.def
include gdiKeyboardVariable.def

;----------------------------------------------------------------------------
;			Code files
;----------------------------------------------------------------------------

include gdiKeyboardStrategy.asm
include	gdiKeyboardInit.asm
include	gdiKeyboardProcess.asm



