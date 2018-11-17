COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textregionManager.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	Manager file for the TextRegion module.

	$Id: textregionManager.asm,v 1.1 97/04/07 11:21:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include dbase.def
include texttext.def
include textstorage.def
include textregion.def
include textline.def
include textattr.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	trConstant.def

;-----------------------------------------------------------------------------
;	Include variables and tables for this module
;-----------------------------------------------------------------------------

include	trVariables.asm

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
include	trEC.asm		; Error checking code
endif

include trLargeText.asm		; VisLargeTextClass

include	trUtils.asm		; Misc utilities

include	trSmallGState.asm	; GState code
include	trLargeGState.asm

include	trSmallGet.asm		; Information getting code
include	trLargeGet.asm

include	trSmallSet.asm		; Information setting code
include	trLargeSet.asm

include	trSmallInfo.asm		; Misc information getting code
include	trLargeInfo.asm

include	trSmallNextPrev.asm	; Moving around in the region list
include	trLargeNextPrev.asm

include	trSmallRegion.asm	; Adding/removing regions
include	trLargeRegion.asm

include	trSmallClear.asm	; Clearing-area code
include	trLargeClear.asm

include	trSmallDraw.asm		; Drawing code
include	trLargeDraw.asm

include	trExternal.asm		; External interface
