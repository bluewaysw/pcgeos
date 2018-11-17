COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		send controller
FILE:		sendcontrolManager.asm

AUTHOR:		Tom Lester, Aug 23, 1994

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/23/94   	Initial revision


DESCRIPTION:
	Manager asm file for the Content Send Controller.
		

	$Id: sendcontrolManager.asm,v 1.1 97/04/04 17:50:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include contentGeode.def

include system.def
include assert.def
include	gstring.def			;for icon triggers

UseLib spool.def			; print control

DefLib conview.def


;---------------------------------------------------

ConviewClassStructures	segment	resource

	ContentSendControlClass			;declare the class record

ConviewClassStructures	ends

;---------------------------------------------------


;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include sendcontrolManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include sendcontrolControl.asm
