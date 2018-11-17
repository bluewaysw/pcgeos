COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		context controller
FILE:		ctxtcontrolManager.asm

AUTHOR:		Jonathan Magasin, Jun 15, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/15/94   	Initial revision


DESCRIPTION:
	
		

	$Id: ctxtcontrolManager.asm,v 1.1 97/04/04 17:50:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include contentGeode.def

include system.def
include assert.def

DefLib conview.def

;---------------------------------------------------

ConviewClassStructures	segment	resource

	ContextControlClass		;declare the class record

ConviewClassStructures	ends

;---------------------------------------------------

;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include ctxtcontrolManager.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include ctxtcontrolControl.asm
