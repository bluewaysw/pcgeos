COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Gadget Library
FILE:		gdgpopup.asm

AUTHOR:		dloft, Sep 18, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/18/95   	Initial revision


DESCRIPTION:
	Implementation of the popup component
		

	$Id: gdgpopup.asm,v 1.1 98/03/11 04:30:42 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	GadgetPopupClass
idata	ends


makeUndefinedPropEntry popup, border

compMkPropTable Popup, popup, border

MakePropRoutines Popup, popup



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetPopupEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	arrange our guts the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetPopupClass object
		ds:di	= GadgetPopupClass instance data
		ds:bx	= GadgetPopupClass object (same as *ds:si)
		es 	= segment of GadgetPopupClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	some gen instance data messed with

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetPopupEntInitialize	method dynamic GadgetPopupClass, 
					MSG_ENT_INITIALIZE
		.enter
	;
	; Tell superclass to do its thing
	;
		mov	di, offset GadgetPopupClass
		call	ObjCallSuperNoLock
	;
	; deref back from chunk handle
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].GII_type, GIT_ORGANIZATIONAL
		mov	ds:[di].GII_visibility, GIV_POPUP
		mov	ds:[di].GII_attrs, 0

		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
		mov	ds:[di].GGI_flags, mask GGF_TILED

		mov	ax, HINT_ORIENT_CHILDREN_VERTICALLY
		clr	cx
		call	ObjVarAddData

		
		.leave
		ret
GadgetPopupEntInitialize	endm

GadgetPopupDontResize	method dynamic GadgetPopupClass,
			MSG_GADGET_SET_WIDTH,
			MSG_GADGET_SET_HEIGHT,
			MSG_GADGET_SET_LEFT,
			MSG_GADGET_SET_TOP
		.enter
		.leave
		ret
GadgetPopupDontResize	endm
			

