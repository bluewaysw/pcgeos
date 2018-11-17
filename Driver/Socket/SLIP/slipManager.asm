COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		
FILE:		slipManager.asm

AUTHOR:		Jennifer Wu, Sep 12, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	9/12/94		Initial revision

DESCRIPTION:
	Manager file for the slip driver.

	$Id: slipManager.asm,v 1.1 97/04/18 11:57:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;---------------------------------------------------------------------------
;				System Includes
;---------------------------------------------------------------------------

include geos.def
include heap.def
include	geode.def

ifdef FULL_EXECUTE_IN_PLACE	
include	Internal/xip.def	; must be included *before* resource.def
endif

include resource.def
include ec.def
include system.def

include library.def
include object.def
include timer.def
include timedate.def
include driver.def
include assert.def
include thread.def
include Internal/semInt.def
include sem.def
include Internal/heapInt.def
include Internal/im.def

include	char.def
include file.def
include localize.def
include initfile.def
include chunkarr.def

include Objects/processC.def

include medium.def

;---------------------------------------------------------------------------
;				System Libraries
;---------------------------------------------------------------------------

UseLib ui.def

UseLib	Internal/netutils.def
UseLib	Internal/socketInt.def

;---------------------------------------------------------------------------
;				Driver Declaration
;---------------------------------------------------------------------------

DefDriver Internal/socketDr.def

UseDriver Internal/serialDr.def

;---------------------------------------------------------------------------
;				Internal def files
;---------------------------------------------------------------------------
include	slip.def

;---------------------------------------------------------------------------
;				Compiled UI definitions
;---------------------------------------------------------------------------

include slipStrings.rdef

;---------------------------------------------------------------------------
;				Code files
;---------------------------------------------------------------------------

include	slip.asm

if _TIA
include slipTia.asm
endif
