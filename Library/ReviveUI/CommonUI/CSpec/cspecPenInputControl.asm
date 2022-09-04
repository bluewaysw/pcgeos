COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecPenInputControl.asm

AUTHOR:		David Litwin, Apr  8, 1994

ROUTINES:
	Name			Description
	----			-----------
   BLB	OLBuildUIPenInputControl Convert a generic Pen input control to
				the OL equivalent
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/ 8/94   	Initial revision


DESCRIPTION:
	This file contains routines to handle the Open Look implementation
	of a generic Pen Input control.
		

	$Id: cspecPenInputControl.asm,v 1.1 94/04/26 10:27:56 dlitwin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Build segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBuildPenInputControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the specific UI class for a GenPenInputControl

CALLED BY:	GLOBAL

PASS:		*ds:si	= instance data
		ax	= MSG_META_RESOLVE_VARIANT_SUPERCLASS
RETURN:		cx:dx	= SPUI class (cx = 0 for no conversion)
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLBuildPenInputControl	proc	far
	.enter

	;
	; Always convert to OLPenInputControlClass
	;
	mov	cx, segment OLPenInputControlClass
	mov	dx, offset OLPenInputControlClass

	.leave
	ret
OLBuildPenInputControl	endp

Build ends


