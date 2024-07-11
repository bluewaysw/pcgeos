COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		gadget
FILE:		gadgetlabl.asm

AUTHOR:		David Loftesness, Sep 14, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/14/94   	Initial revision


DESCRIPTION:
	
		
	$Id: gdglabel.asm,v 1.1 98/03/11 04:31:00 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	GadgetLabelClass
idata	ends

makeUndefinedPropEntry label, readOnly
makeUndefinedPropEntry label, graphic
compMkPropTable GadgetLabelProperty, label, readOnly, graphic
MakePropRoutines Label, label


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetLabelGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return "label"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetLabelClass object
		ds:di	= GadgetLabelClass instance data
		ds:bx	= GadgetLabelClass object (same as *ds:si)
		es 	= segment of GadgetLabelClass
		ax	= message #
RETURN:		cx:dx	= fptr.char
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetLabelGetClass	method dynamic GadgetLabelClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetLabelString
		mov	dx, offset GadgetLabelString
		ret
GadgetLabelGetClass	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetLabelMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenText

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetLabelClass object
		ds:di	= GadgetLabelClass instance data
		ds:bx	= GadgetLabelClass object (same as *ds:si)
		es 	= segment of GadgetLabelClass
		ax	= message #
RETURN:		cx:dx	= superclass to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
 	----	----		-----------
	dloft	6/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetLabelMetaResolveVariantSuperclass	method dynamic GadgetLabelClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter
 
	cmp	cx, Ent_offset
	je	returnSuper

	mov	di, offset GadgetLabelClass
	call	ObjCallSuperNoLock
done:
 	.leave
	ret

returnSuper:
	mov	cx, segment GenGlyphClass
 	mov	dx, offset GenGlyphClass
	jmp	done

GadgetLabelMetaResolveVariantSuperclass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetLabelSetSizeHVControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow/disallow clipping based on the type of
		size control desired.

			AS_SPECIFIED:		clip if needed
			AS_NEEDED:		no clipping
			AS_SMALL_AS_POSSIBLE:	no clipping	
			AS_BIG_AS_POSSIBLE:	clip if needed


CALLED BY:	MSG_GADGET_SET_SIZE_HCONTROL
		MSG_GADGET_SET_SIZE_VCONTROL
PASS:		*ds:si	= GadgetLabelClass object
		ds:di	= GadgetLabelClass instance data
		ds:bx	= GadgetLabelClass object (same as *ds:si)
		es 	= segment of GadgetLabelClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		nothing
DESTROYED:	cx, dx, + whatever superclass call destroys
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetLabelSetSizeHVControl	method dynamic GadgetLabelClass, 
					MSG_GADGET_SET_SIZE_HCONTROL,
					MSG_GADGET_SET_SIZE_VCONTROL
		.enter
	;
	; Utility function does all the work.
	;
		call	GadgetUtilClipMkrBasedOnSizeControl

	;
	; Let superclass do its thing.
	;
		mov	bx, segment GadgetLabelClass
		mov	es, bx
		mov	di, offset GadgetLabelClass
		call	ObjCallSuperNoLock

		.leave
		Destroy	cx, dx
		ret
GadgetLabelSetSizeHVControl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetLabelSetWidthHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If user specifies width/height, then he implicitly
		specifies sizeH/VControl as AS_SPECIFIED, so we need
		to set HINT_CAN_CLIP_MONIKER_{WIDTH/HEIGHT}.

CALLED BY:	MSG_GADGET_SET_WIDTH
		MSG_GADGET_SET_HEIGHT
PASS:		*ds:si	= GadgetLabelClass object
		ds:di	= GadgetLabelClass instance data
		ds:bx	= GadgetLabelClass object (same as *ds:si)
		es 	= segment of GadgetLabelClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx and whatever superclass destroys
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetLabelSetWidthHeight	method dynamic GadgetLabelClass, 
					MSG_GADGET_SET_WIDTH,
					MSG_GADGET_SET_HEIGHT
		.enter

		call	GadgetUtilClipMkrForFixedSize
		mov	di, offset GadgetLabelClass
		call	ObjCallSuperNoLock

		.leave
		Destroy	ax, cx, dx
		ret
GadgetLabelSetWidthHeight	endm


