COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Bitmap
MODULE:		
FILE:		fatbits.asm

AUTHOR:		Jon Witort, August 26, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	26 aug 1992	Initial revision


DESCRIPTION:
	Main file for VisFatbitsClass, which provides fatbit functionality
	in the bitmap library

	$Id: fatbits.asm,v 1.1 97/04/04 17:43:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapClassStructures	segment resource

	VisFatbitsClass

BitmapClassStructures	ends

BitmapObscureEditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsSetVisBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisFatbits method for MSG_VIS_FATBITS_SET_VIS_BITMAP

Called by:	MSG_VIS_FATBITS_SET_VIS_BITMAP

Pass:		*ds:si = VisFatbits object
		ds:di = VisFatbits instance

		^lcx:dx - VisBitmap

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsSetVisBitmap		method dynamic	VisFatbitsClass,
				MSG_VIS_FATBITS_SET_VIS_BITMAP
	.enter

	movdw	ds:[di].VFI_visBitmap, cxdx

	.leave
	ret
VisFatbitsSetVisBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsSetImportantLocationAndImageBitSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisFatbits method for
		MSG_VIS_FATBITS_SET_IMPORTANT_LOCATION_AND_IMAGE_BIT_SIZE

Called by:	MSG_VIS_FATBITS_SET_IMPORTANT_LOCATION_AND_IMAGE_BIT_SIZE

Pass:		*ds:si = VisFatbits object
		ds:di = VisFatbits instance

		cx,dx - location
		bp - ImageBitSize

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsSetImportantLocationAndImageBitSize	method dynamic VisFatbitsClass,
		MSG_VIS_FATBITS_SET_IMPORTANT_LOCATION_AND_IMAGE_BIT_SIZE
	uses	cx,dx,bp
	.enter

	mov	ds:[di].VFI_importantLocation.P_x, cx
	mov	ds:[di].VFI_importantLocation.P_y, dx
	mov_tr	ax, bp
	mov	ds:[di].VFI_imageBitSize, al

	movdw	bxdi, cxdx			;bx,di <- important location

	push	ax				;save IBS

	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock

	mov	bp, cx				;bp <- width
	pop	cx				;cl <- IBS

	;
	;  Do some wacky math to compute the center pixel
	;
	mov	ax, 1
	shl	ax, cl
	dec	ax
	add	bp, ax
	add	dx, ax
	shr	bp, cl
	shr	dx, cl
	push	bp, dx
	shr	bp
	shr	dx

	;
	;  Upper [left,top] = max (0, [importantX - w/2, importantY - h/2]

	sub	bx, bp
	jns	calcTop

	clr	bx

calcTop:
	sub	di, dx
	jns	gotTop

	clr	di

gotTop:
	pop	bp, dx
	push	dx				;save height
	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_PIXELS
	call	VisFatbitsCallVisBitmap
	pop	ax				;ax <- height

	sub	cx, bp
	js	checkHeight
	cmp	bx, cx
	jle	checkHeight
	mov	bx, cx

checkHeight:
	sub	dx, ax
	js	saveUpperLeft
	cmp	di, dx
	jle	saveUpperLeft
	mov	di, dx
saveUpperLeft:
	mov	bp, ds:[si]
	add	bp, ds:[bp].VisFatbits_offset

	mov	ds:[bp].VFI_upperLeft.P_x, bx
	mov	ds:[bp].VFI_upperLeft.P_y, di

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	.leave
	ret
VisFatbitsSetImportantLocationAndImageBitSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisFatbits method for MSG_META_START_SELECT

Called by:	MSG_META_START_SELECT

Pass:		*ds:si = VisFatbits object
		ds:di = VisFatbits instance

		ax - MSG_META_START_SELECT
		cx, dx - mouse location
		bp - Button info

Return:		ax - MouseReturnFlags from VisBitmap

Destroyed:	cx, dx, bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsStartSelect	method dynamic	VisFatbitsClass, MSG_META_START_SELECT,
						MSG_META_START_MOVE_COPY
	.enter

	;
	;  First, we'l turn on fatbits mode in the bitmap
	;
	push	cx, ax					;save x, msg
	mov	cx, sp					;non-zero
	mov	ax, MSG_VIS_BITMAP_SET_FATBITS_MODE
	call	VisFatbitsCallVisBitmap

	;
	;  Now pass the message along
	;
	pop	cx, ax					;cx <- x, ax <- msg
	call	VisFatbitsConvertAndSendMouseEvent
	call	VisGrabMouse

	.leave
	ret
VisFatbitsStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisFatbits method for MSG_META_DRAG_SELECT

Called by:	MSG_META_DRAG_SELECT

Pass:		*ds:si = VisFatbits object
		ds:di = VisFatbits instance

		ax - MSG_META_DRAG_SELECT
		cx, dx - mouse location
		bp - Button info

Return:		ax - MouseReturnFlags from VisBitmap

Destroyed:	cx, dx, bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsDragSelect	method dynamic	VisFatbitsClass, MSG_META_DRAG_SELECT
	.enter

	call	VisFatbitsConvertAndSendMouseEvent

	.leave
	ret
VisFatbitsDragSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisFatbits method for MSG_META_PTR

Called by:	MSG_META_PTR

Pass:		*ds:si = VisFatbits object
		ds:di = VisFatbits instance

		ax - MSG_META_PTR
		cx, dx - mouse location
		bp - Button info

Return:		ax - MouseReturnFlags from VisBitmap

Destroyed:	cx, dx, bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsPtr	method dynamic	VisFatbitsClass, MSG_META_PTR
	.enter

	call	VisFatbitsConvertAndSendMouseEventIfNewAndIn

	.leave
	ret
VisFatbitsPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisFatbits method for MSG_META_END_SELECT

Called by:	MSG_META_END_SELECT

Pass:		*ds:si = VisFatbits object
		ds:di = VisFatbits instance

		ax - MSG_META_END_SELECT
		cx, dx - mouse location
		bp - Button info

Return:		ax - MouseReturnFlags from VisBitmap

Destroyed:	cx, dx, bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsEndSelect	method dynamic	VisFatbitsClass, MSG_META_END_SELECT,
						MSG_META_END_MOVE_COPY
	.enter

	call	VisFatbitsConvertAndSendMouseEvent
	call	VisReleaseMouse

	;
	;  First, we'l turn on fatbits mode in the bitmap
	;
	clr	cx
	mov	ax, MSG_VIS_BITMAP_SET_FATBITS_MODE
	call	VisFatbitsCallVisBitmap

	.leave
	ret
VisFatbitsEndSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsConvertAndSendMouseEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisFatbits
		ax - message
		cx,dx,bp - mouse data

Return:		ax - mouse return flags

Destroyed:	cx,dx,bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsConvertAndSendMouseEvent	proc	near
	class	VisFatbitsClass
	.enter

	call	VisFatbitsConvertMouseEvent

	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset
	mov	ds:[di].VFI_lastMouse.P_x, cx
	mov	ds:[di].VFI_lastMouse.P_y, dx

	call	VisFatbitsCallVisBitmap
	

	.leave
	ret
VisFatbitsConvertAndSendMouseEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsConvertAndSendMouseEventIfNewAndIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisFatbits
		ax - message
		cx,dx,bp - mouse data

Return:		ax - mouse return flags

Destroyed:	cx,dx,bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsConvertAndSendMouseEventIfNewAndIn	proc	near
	class	VisFatbitsClass
	.enter

	call	VisFatbitsConvertMouseEvent

	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset
	cmp	ds:[di].VFI_lastMouse.P_x, cx
	jne	new
	cmp	ds:[di].VFI_lastMouse.P_y, dx
	je	dontSend

new:
	mov	ds:[di].VFI_lastMouse.P_x, cx
	mov	ds:[di].VFI_lastMouse.P_y, dx

	call	VisFatbitsCallVisBitmap
	
done:
	.leave
	ret

dontSend:
	mov	ax, mask MRF_PROCESSED
	jmp	done
VisFatbitsConvertAndSendMouseEventIfNewAndIn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsConvertMouseEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisFatbits
		cx,dx - location in VisFatbits window

Return:		cx,dx - VisBitmap location

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsConvertMouseEvent	proc	near
	class	VisFatbitsClass
	uses	ax, bp, di
	.enter

	call	VisConstrainPointToVisBounds

	push	cx				;save x
	push	dx				;save y
	mov	ax, MSG_VIS_GET_POSITION
	call	VisFatbitsCallVisBitmap

	mov_tr	ax, cx				;ax <- left

	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset
	mov	cl, ds:[di].VFI_imageBitSize

	pop	bp				;di <- y
	sar	bp, cl
	add	dx, bp

	pop	bp				;di <- x
	sar	bp, cl
	add	ax, bp

	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset
	add	ax, ds:[di].VFI_upperLeft.P_x
	add	dx, ds:[di].VFI_upperLeft.P_y

	mov_tr	cx, ax				;cx <- converted x

if 0
	;
	;  After all that trouble, we have to convert the pixel location
	;  into a visual location
	;

	push	cx, dx				;save pixel coords

	mov	ax, MSG_VIS_BITMAP_GET_FORMAT_AND_RESOLUTION
	call	VisFatbitsCallVisBitmap

	mov	di, dx				;di <- x res
	mov	bx, bp				;bx <- y res

	pop	cx, dx				;cx,dx <- coords

	call	ConvertBitmapPointToVisPoint

endif

 	.leave
	ret
VisFatbitsConvertMouseEvent	endp

if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBitmapPointToVisPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts a pixel coordinate to a vis (72 dpi) location

Pass:		cx, dx - point
		di - x resolution
		bx - y resolution

Return:		cx, dx - scaled by 72/res

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 10, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertBitmapPointToVisPoint	proc	far
	uses	ax, bp
	.enter

	mov	bp, 72

	cmp	di, bp
	je	calcYPixels

	push	ax, dx
	mov_tr	ax, cx			;ax <- x point size
	mul	bp			;dx:ax <- x pixel size
	cmp	dx, di
	jae	overflowX
	div	di
	tst	dx			;round up
	jz	haveXPixels
	inc	ax
haveXPixels:
	mov_tr	cx, ax
overflowX:
	pop	ax, dx

calcYPixels:

	cmp	bx, bp
	je	done

	mov_tr	ax, dx			;ax <- y point size
	mul	bp			;dx:ax <- y pixel size
	cmp	dx, bx
	jae	done
	div	bx
	tst	dx			;round up
	jz	haveYPixels
	inc	ax
haveYPixels:
	mov_tr	dx, ax

done:
	.leave
	ret
ConvertBitmapPointToVisPoint	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisFatbits method for MSG_VIS_DRAW

Called by:	MSG_VIS_DRAW

Pass:		*ds:si = VisFatbits object
		ds:di = VisFatbits instance

		bp - GState

Return:		nothing

Destroyed:	ax, cx, dx, bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsDraw	method dynamic	VisFatbitsClass, MSG_VIS_DRAW
	.enter

	mov	ax, MSG_VIS_BITMAP_GET_INTERACTIVE_DISPLAY_BITMAP
	call	VisFatbitsCallVisBitmap

	tst	dx
	jz	done

	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset

	mov	si, dx				;si <- vm block handle
	mov	dx, cx				;dx <- vm file handle

	mov	ax, ds:[di].VFI_upperLeft.P_x
	mov	bx, ds:[di].VFI_upperLeft.P_y

	;
	;	ax,bx <- scaled upper left
	;
	mov	cl, ds:[di].VFI_imageBitSize
	shl	ax, cl
	shl	bx, cl

	;
	;  We want a border, and IGNORE the mask, please.
	;
	or	cl, mask IF_BORDER or mask IF_IGNORE_MASK

	mov	di, bp				;di <- gstate

	call	GrSaveState
	push	ax
	mov	ax, C_LIGHT_GRAY
	call	GrSetLineColor
	mov	al,CMT_CLOSEST
	call	GrSetAreaColorMap
	pop	ax

	neg	ax
	neg	bx
	call	GrDrawHugeImage

	call	GrRestoreState

done:
	.leave
	ret
VisFatbitsDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsInvalidateRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisFatbits method for MSG_VIS_FATBITS_INVALIDATE_RECTANGLE

		This routine invalidates a sub-rectangle of the VisFatbits
		(we're hoping to speed up interactive tools like the pencil
		by not invalidating the whole fatbits on every ptr event).

Called by:	MSG_VIS_FATBITS_INVALIDATE_RECTANGLE

Pass:		*ds:si = VisFatbits object
		ds:di = VisFatbits instance

		ss:[bp] - VisBitmapEditBitmapParams, where the following
			  four fields:

			VBEBP_ax
			VBEBP_bx
			VBEBP_cx
			VBEBP_dx

			contain a rectangle (in bitmap coords) to invalidate

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsInvalidateRectangle	method dynamic	VisFatbitsClass,
				MSG_VIS_FATBITS_INVALIDATE_RECTANGLE
	.enter

	;
	;  This should never happen, but it just did.
	;
	tst	ds:[di].VFI_visBitmap.handle
	LONG	jz	done

	push	bp					;save VBEBP
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov_tr	ax, bp					;ax <- gstate
	pop	bp					;ss:bp <- VBEBP
	push	ax					;save gstate

	cmp	ss:[bp].VBEBP_invalRect.R_left, INVALIDATE_ENTIRE_FATBITS_WINDOW
	je	doDraw

	;
	;  We want to include a fudge factor = 1/2 line width
	;

	push	bp
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	VisFatbitsCallVisBitmap
	mov	di, bp
	pop	bp

	tst	di
	jz	afterLineWidth

	call	GrGetLineWidth
	mov	di, dx
	shr	di

afterLineWidth:

	inc	di

	mov	ax, ss:[bp].VBEBP_invalRect.R_left
	mov	bx, ss:[bp].VBEBP_invalRect.R_top
	mov	cx, ss:[bp].VBEBP_invalRect.R_right
	mov	dx, ss:[bp].VBEBP_invalRect.R_bottom

	cmp	ax, cx
	jl	checkY
	xchg	ax, cx
checkY:
	cmp	bx, dx
	jl	gotY
	xchg	bx, dx

gotY:
	;
	;  Push the bounds out by the line width
	;

	sub	ax, di
	sub	bx, di
	add	cx, di
	add	dx, di

	;
	;  Extra fudge, please
	;
	inc	cx
	inc	dx

	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset

	sub	ax, ds:[di].VFI_upperLeft.P_x
	sub	cx, ds:[di].VFI_upperLeft.P_x
	sub	bx, ds:[di].VFI_upperLeft.P_y
	sub	dx, ds:[di].VFI_upperLeft.P_y

	mov	bp, cx				;bp <- right

	mov	cl, ds:[di].VFI_imageBitSize

	shl	ax, cl
	shl	bx, cl
	shl	bp, cl
	shl	dx, cl

	dec	bx		; I think a bug in the path code is causing
				; the top line to not invalidate, so I'm
				; compensating here.

	mov	cx, bp				;cx <- new right

	pop	di				;di <- gstate
	push	si
	mov	si, PCT_REPLACE
	call	GrSetClipRect
	pop	si

	push	di

doDraw:
	pop	bp

	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock

	mov	di, bp
	call	GrDestroyState

done:
	.leave
	ret
VisFatbitsInvalidateRectangle	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFatbitsCallVisBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Utility routine for sending message to the VisBitmap

Pass:		*ds:si - VisFatbits
		ax - message to send to VisBitmap

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisFatbitsCallVisBitmap	proc	near
	class	VisFatbitsClass
	uses	bx, si, di

	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset
	movdw	bxsi, ds:[di].VFI_visBitmap
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
VisFatbitsCallVisBitmap	endp

BitmapObscureEditCode	ends
