COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		navigation controller
FILE:		navcontrolManager.asm

AUTHOR:		Jonathan Magasin, May  6, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/ 6/94   	Initial revision


DESCRIPTION:
	
		

	$Id: navcontrolManager.asm,v 1.1 97/04/04 17:49:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include contentGeode.def

include system.def
include	gstring.def			;for icon triggers

include assert.def


DefLib conview.def

;---------------------------------------------------

ConviewClassStructures	segment	resource

	ContentNavControlClass		;declare the class record

ConviewClassStructures	ends

;---------------------------------------------------


;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include navcontrolManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include navcontrolControl.asm
include	navcontrolHistory.asm
include	navcontrolUtils.asm
