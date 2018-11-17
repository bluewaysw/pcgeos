COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		find controller
FILE:		findcontrolManager.asm

AUTHOR:		Tom Lester, Aug 23, 1994

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/23/94   	Initial revision


DESCRIPTION:
	Manager asm file for the Content Find Controller.
		

	$Id: findcontrolManager.asm,v 1.1 97/04/04 17:50:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include contentGeode.def

include system.def
include	gstring.def			;for icon triggers
include assert.def

UseLib Objects/Text/tCtrlC.def		;search/replace control

DefLib conview.def


;---------------------------------------------------

ConviewClassStructures	segment	resource

	ContentFindControlClass			;declare the class record

ConviewClassStructures	ends

;---------------------------------------------------


;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include findcontrolManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include findcontrolControl.asm

