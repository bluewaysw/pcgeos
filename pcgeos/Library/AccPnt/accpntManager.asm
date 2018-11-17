COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	socket
MODULE:		access point database
FILE:		accpntManager.asm

AUTHOR:		Eric Weber, Apr 24, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/24/95   	Initial revision


DESCRIPTION:
	
		

	$Id: accpntManager.asm,v 1.1 97/04/04 17:41:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	_RESPONDER	= FALSE
	_EDIT_ENABLE	= FALSE

;-----------------------------------------------------------------------------
;                          System Includes
;-----------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include system.def
include library.def
include driver.def
include sem.def
include object.def
include timer.def
include timedate.def
include assert.def
include initfile.def
include thread.def
include medium.def
include chunkarr.def
include gstring.def

include Internal/semInt.def
include Internal/heapInt.def

;-----------------------------------------------------------------------------
;                          System Libraries
;-----------------------------------------------------------------------------
UseLib	ui.def

;-----------------------------------------------------------------------------
;                        Library Declaration
;-----------------------------------------------------------------------------
DefLib  accpnt.def

;-----------------------------------------------------------------------------
;                         Internal def files
;-----------------------------------------------------------------------------
include accpntConstant.def
include accpntMacro.def
include accpntClass.def
include accpnt.rdef

;-----------------------------------------------------------------------------
;                             Code files
;-----------------------------------------------------------------------------
include	accpntApi.asm
include accpntUtils.asm
include	accpntControl.asm
include accpntList.asm
include accpntCApi.asm

