COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdgspace.asm

AUTHOR:		jimmy, Aug 28, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/28/95   	Initial revision


DESCRIPTION:
	code for spacer component
		

	$Id: gdgspace.asm,v 1.1 98/03/11 04:30:44 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment
GadgetSpacerClass
GadgetPictureClass
idata	ends


GadgetSpacerPictureCode	segment resource

;makePropEntry picture, picture, LT_TYPE_COMPLEX,	\
;	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_GRAPHIC>, \
;	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_GRAPHIC>


makeUndefinedPropEntry picture, readOnly
makeUndefinedPropEntry picture, caption
makeUndefinedPropEntry picture, enabled
makeUndefinedPropEntry picture, look
; Note: visible is still defined in EntVis.

compMkPropTable GadgetPicture, picture, \
	readOnly, caption, enabled, look
MakePropRoutines Picture, picture

makeUndefinedPropEntry spacer, readOnly
makeUndefinedPropEntry spacer, caption
makeUndefinedPropEntry spacer, graphic
makeUndefinedPropEntry spacer, enabled

compMkPropTable GadgetSpacer, spacer, readOnly, caption, graphic, enabled
MakePropRoutines Spacer, spacer

GadgetInitCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSG_META_RESOLVE_VARIANT_SUPERCLASS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	a MSG_META_RESOLVE_VARIANT_SUPERCLASS handler

PASS:		

Usage:		compResolveSuperclass	GadgetValue, GenValue


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetSpacerMetaResolveVariantSuperclass method dynamic GadgetSpacerClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

		compResolveSuperclass	GadgetSpacer, GenInteraction

GadgetSpacerMetaResolveVariantSuperclass	endm
		



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetSpacerClass object
		ds:di	= GadgetSpacerClass instance data
		ds:bx	= GadgetSpacerClass object (same as *ds:si)
		es 	= segment of GadgetSpacerClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSEntInitialize	method dynamic GadgetSpacerClass, 
					MSG_ENT_INITIALIZE
		uses	ax, cx, dx, bp
		.enter
	;
	; Tell superclass to do its thing
	;
		push	ds:LMBH_handle, si
		mov	di, offset GadgetSpacerClass
		call	ObjCallSuperNoLock
		pop	bx, si
		call	MemDerefDS
		
		sub	sp, size SetSizeArgs
		mov	bp, sp
		mov	ss:[bp].SSA_width, 15
		mov	ss:[bp].SSA_height, 15
		mov	dx, size SetSizeArgs
		mov	ss:[bp].SSA_count, 0
		mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_FIXED_SIZE
		call	ObjCallInstanceNoLock
		add	sp, size SetSizeArgs

		mov	ax, MSG_VIS_SET_SIZE
		mov	cx, 15
		mov	dx, 15
		call	ObjCallInstanceNoLock
		
		.leave
		ret
GSEntInitialize	endm

GadgetInitCode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSpacerVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws supplied string if one is defined for the object,
		otherwise it will draw a default background pattern.
		You can't call user code yet

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= GadgetSpaceClass object
		ds:di	= GadgetSpaceClass instance data
		ds:bx	= GadgetSpaceClass object (same as *ds:si)
		es 	= segment of GadgetSpaceClass
		ax	= message #
		cl	= DrawFlags
		bp	= gstate to draw to
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSpacerVisDraw	method dynamic GadgetSpacerClass, 
			MSG_VIS_DRAW
		.enter

		mov	al, ds:[di].GI_look
		cmp	al, GSLC_BLANK
		je	done		
		
		mov	di, bp			;di <- GState

	;
	; Suck the spacer's visual bounds into di,bx - cx, dx
	;
		push	si, ax
EC <		call	VisCheckVisAssumption				>
		mov	si, ds:[si]
		add	si, ds:[si].Vis_offset
		add	si, offset VI_bounds
		lodsw
		mov_tr	bp, ax			;bp <- left
		lodsw
		mov_tr	bx, ax			;bx <- top
		lodsw
		mov_tr	cx, ax			;cx <- right
		lodsw
		mov_tr	dx, ax			;dx <- bottom
		pop	si, ax


	;
	;  We want to draw either a horizontal or a vertical line,
	;  depending on which dimension is greater.
	;
		push	cx, dx
		sub	dx, bx
		sub	cx, bp
		cmp	cx, dx
		pop	cx, dx
		jb	vertical

horizontal::
		mov	ah, GSLT_HORIZONTAL
		add	dx, bx
		shr	dx
		mov	bx, dx
		jmp	haveCoords

vertical:
		mov	ah, GSLT_VERTICAL
		add	cx, bp
		shr	cx
		mov	bp, cx

haveCoords:
	;
	;  At this point:
	;
	;  bp, bx - upper left coordinate of line
	;  cx, dx - lower right coordinate of line
	;  al - GadgetSpacerLineColor
	;  di - GState
	;

		cmp	al, GSLC_BLACK
		je	black
		cmp	al, GSLC_WHITE
		je	white
		cmp	al, GSLC_DOTTED
		je	dotted

	;
	;  OK, the thing is 3D. If we're on a B/W system, then just
	;  draw black like any normal person would.
	;  
		push	ax, bx, cx, dx
		mov	ax, GIT_PRIVATE_DATA	;pass di, ax
		call	GrGetInfo		;returns ax, bx, cx, dx

		and	ah, mask DF_DISPLAY_TYPE
		cmp	ah, DC_GRAY_1			;B&W display?
		pop	ax, bx, cx, dx
		je	black

	;
	; It's 3D.
	;
		cmp	al, GSLC_3D_OUT
		je	out3D
	;
	; It's 3D inwards.
	;
		mov	si, 1
		cmp	ah, GSLT_VERTICAL
		je	inVert

	;
	; It's a *horizontal* 3D inverted line, so bring in the right edge
	; by one.
	;
		dec	cx
		jmp	do3d
inVert:
	;
	; It's a *vertical* 3D inverted line, so bring in the bottom edge
	; by one.
	;
		dec	dx
		jmp	do3d

out3D:
	;
	; It's 3D outwards.
	;
		mov	si, -1
		cmp	ah, GSLT_VERTICAL
		je	outVert

	;
	; It's a *horizontal* 3D outverted line, so bring in the left edge
	; by one.
	;
		inc	bp
		jmp	do3d
outVert:
	;
	; It's a *vertical* 3D outverted line, so bring in the top edge
	; by one.
	;
		inc	bx

do3d:
	;
	; Draw the shadow first. This means 
	;
		mov	ax, C_WHITE
		call	GrSetLineColor

		mov	ax, bp
		add	ax, si
		add	bx, si
		add	cx, si
		add	dx, si

		call	GrDrawLine

		mov	ax, C_BLACK
		call	GrSetLineColor

		sub	bx, si
		sub	cx, si
		sub	dx, si

black:
		mov_tr	ax, bp
		call	GrDrawLine
done:
		.leave
		ret
dotted:
		mov	al, SDM_50
		call	GrSetLineMask
		jmp	black
white:
		mov	ax, C_WHITE
		call	GrSetLineColor
		mov_tr	ax, bp
		call	GrDrawLine
		mov	ax, C_BLACK
		call	GrSetLineColor
		jmp	done
GadgetSpacerVisDraw	endm
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;GadgetPicture code;;;;;;;;;;;;;;;;;;;;;;;

GadgetInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSG_META_RESOLVE_VARIANT_SUPERCLASS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	a MSG_META_RESOLVE_VARIANT_SUPERCLASS handler

PASS:		

Usage:		compResolveSuperclass	GadgetValue, GenValue


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetPictureMetaResolveVariantSuperclass method dynamic GadgetPictureClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

		compResolveSuperclass	GadgetPicture, GenGlyph

GadgetPictureMetaResolveVariantSuperclass	endm
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetSpacerClass object
		ds:di	= GadgetSpacerClass instance data
		ds:bx	= GadgetSpacerClass object (same as *ds:si)
		es 	= segment of GadgetSpacerClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPEntInitialize	method dynamic GadgetPictureClass, 
					MSG_ENT_INITIALIZE
		uses	ax, cx, dx, bp
		.enter
	;
	; Tell superclass to do its thing
	;
		push	ds:LMBH_handle, si
		mov	di, offset GadgetPictureClass
		call	ObjCallSuperNoLock
		pop	bx, si
		call	MemDerefDS
		
		sub	sp, size SetSizeArgs
		mov	bp, sp
		mov	ss:[bp].SSA_width, 15
		mov	ss:[bp].SSA_height, 15
		mov	dx, size SetSizeArgs
		mov	ss:[bp].SSA_count, 0
		mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_FIXED_SIZE
		call	ObjCallInstanceNoLock
		add	sp, size SetSizeArgs

		mov	ax, MSG_VIS_SET_SIZE
		mov	cx, 15
		mov	dx, 15
		call	ObjCallInstanceNoLock
		
		.leave
		ret
GPEntInitialize	endm

GadgetInitCode 	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSG_GADGET_PICTURE_SET_CAPTION,LOOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DO NOTHING	

PASS:		

Usage:		compResolveSuperclass	GadgetValue, GenValue


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetPictureSetCaption	method dynamic GadgetPictureClass,
				MSG_GADGET_SET_CAPTION,
				MSG_GADGET_SET_LOOK
		ret
GadgetPictureSetCaption	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetPictureGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return "picture"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetPictureClass object
		ds:di	= GadgetPictureClass instance data
		ds:bx	= GadgetPictureClass object (same as *ds:si)
		es 	= segment of GadgetPictureClass
		ax	= message #
RETURN:		cx:dx	= "picture"
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetPictureGetClass	method dynamic GadgetPictureClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetPictureString
		mov	dx, offset GadgetPictureString
		ret
GadgetPictureGetClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSpacerGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return "spacer"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetSpacerClass object
		ds:di	= GadgetSpacerClass instance data
		ds:bx	= GadgetSpacerClass object (same as *ds:si)
		es 	= segment of GadgetSpacerClass
		ax	= message #
RETURN:		cx:dx	= "spacer"
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSpacerGetClass	method dynamic GadgetSpacerClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetSpacerString
		mov	dx, offset GadgetSpacerString
		ret
GadgetSpacerGetClass	endm

		
GadgetSpacerPictureCode	ends

