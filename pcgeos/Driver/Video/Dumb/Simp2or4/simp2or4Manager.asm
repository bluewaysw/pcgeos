COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Video
MODULE:		Simp2or4
FILE:		simp2or4Manager.asm

AUTHOR:		Eric Weber, Jan 29, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	1/29/97   	Initial revision


DESCRIPTION:
		
	

	$Id: simp2or4Manager.asm,v 1.1 97/04/18 11:43:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;--------------------------------------
;		Include files
;--------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include driver.def
include	win.def
include timer.def
include	file.def
include	Internal/respondrStr.def
include Internal/semInt.def
include Internal/interrup.def

UseDriver Internal/powerDr.def

DefDriver Internal/videoDr.def

.ioenable	; Tell Esp to allow I/O instructions
.186		; allow 186 instructions

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include	simp2or4Constant.def

;------------------------------------------------------------------------------
;			Tables
;------------------------------------------------------------------------------
include	simp2or4DevInfo.asm

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------
include	simp2or4Entry.asm
include	simp2or4Switch.asm
