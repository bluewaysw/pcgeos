COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Bitmap Edit Object
FILE:		bitmapGState.asm

AUTHOR:		Jon Witort

ROUTINES:
	Name				Description
	----				-----------
	SetColorCommon			Stores the passed color information
					into the bitmap's instance data

	VisBitmapSetAreaColor		MSG_VIS_BITMAP_SET_AREA_COLOR handler
					for VisBitmapClass, sets the area color
					for the main bitmap.

	VisBitmapSetLineColor		MSG_VIS_BITMAP_SET_LINE_COLOR handler
					for VisBitmapClass, sets the line color
					for the main bitmap.

	VisBitmapSetTextColor		MSG_VIS_BITMAP_SET_TEXT_COLOR handler
					for VisBitmapClass, sets the text color
					for the main bitmap.

	VisBitmapSetLineWidth		MSG_VIS_BITMAP_SET_LINE_WIDTH handler
					for VisBitmapClass, sets the line width
					for the main bitmap.

	VisBitmapSetGStateStuff		MSG_VIS_BITMAP_SET_GSTATE_STUFF handler
					for VisBitmapClass, sets all of the
					gstate info for the bitmap at once.
					


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jon	2/91	initial version


DESCRIPTION:
		This file contains handlers for VisBitmapClass that
		set the gstate info.

		$Id: bitmapGState.asm,v 1.1 97/04/04 17:43:08 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapEditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SetColorCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine for setting gstate colors

CALLED BY:	VisBitmapSet(Area, Line, Text)Color

PASS:		bp = BitMapGraphicsStateStuff slot to set
			(e.g. if you want to set the area color, then
				bp = VBGSS_areaColor)

		ch - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					cl = index
				CF_RGB (1)
					cl = red
					dl = green
					dh = blue

		ds:di = VisBitmap instance
		*ds:si = VisBitmap object

RETURN:		ch = CF_RGB
		cl = red
		dl = green
		dh = blue

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new color;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetColorCommon	proc	near
	class	VisBitmapClass
	uses	ax, di
	.enter
	;
	;	If we're passed RGB values, then just store them into the
	;	instance data.
	;
	cmp	ch, CF_RGB
	je	gotRGB

	;
	;	Map the color index to RGB values. Use the default mapping.
	;
	clr	di					;no gstate
	mov	ah, cl					;ah <- color index
	call	GrMapColorIndex

	mov	cl, al					;cl <- red
	mov	ch, CF_RGB
	mov	dx, bx					;dl <- green
							;dh <- blue
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

gotRGB:
	add	di, VBI_gStateStuff			;set di so that
							;ds:di points to
							;the VBI_gStateStuff
							;instance data

	mov	ds:[di][bp].high, cx			;store high word
	mov	ds:[di][bp].low, dx			;store low word
	.leave
	ret
SetColorCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SET_AREA_COLOR handler for VisBitmapClass. Sets the
		area color for the VisBitmap so that any tools that require
		an area color use the passed color.

CALLED BY:	

PASS:		ch - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					cl = index
				CF_RGB (1)
					cl = red
					dl = green
					dh = blue

		ds:di = VisBitmap instance
		*ds:si = VisBitmap object
		
CHANGES:	The new area color is stored to instance data

RETURN:		ch = CF_RGB
		cl, dh, dl = red, blue, green of passed color

DESTROYED:	ax, bx, bp, si, di

PSEUDO CODE/STRATEGY:
		call SetColorCommon with the VBGSS_areaColor slot,
		then pass the info on to the text object

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetAreaColor	method	VisBitmapClass, MSG_VIS_BITMAP_SET_AREA_COLOR
	;
	;	Make the call to SetColorCommon, which will translate the
	;	color to RGB if necessary, and store it to instance data
	;
	mov	bp, VBGSS_areaColor
	call	SetColorCommon

	;
	;	Update the screen gstate to contain the new area color, if
	;	necessary
	;
	mov	bp, ds:[di].VBI_screenGState
	tst	bp
	jz	updateVTFB

	call	VisBitmapApplyGStateStuff
updateVTFB:
if BITMAP_TEXT
	;
	;	Tell the text object to set its background color to the
	;	passed area color
	;
	mov	bx, ds:[di].VBI_visText.handle
	mov	si, ds:[di].VBI_visText.chunk

	mov	ax, MSG_VIS_TEXT_SET_PARA_BG_COLOR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
endif
	ret
VisBitmapSetAreaColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSetLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SET_LINE_COLOR handler for VisBitmapClass. Sets the
		line color for the VisBitmap so that any tools that require
		a line color use the passed color.

CALLED BY:	

PASS:		ch - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					cl = index
				CF_RGB (1)
					cl = red
					dl = green
					dh = blue

		ds:di = VisBitmap instance
		*ds:si = VisBitmap object
		
CHANGES:	The new line color is stored to instance data

RETURN:		ch = CF_RGB
		cl, dh, dl = red, blue, green of passed color

DESTROYED:	ax, bx, bp, si, di

PSEUDO CODE/STRATEGY:
		call SetColorCommon with the VBGSS_lineColor slot,

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetLineColor	method	VisBitmapClass, MSG_VIS_BITMAP_SET_LINE_COLOR
	;
	;	Make the call to SetColorCommon, which will translate the
	;	color to RGB if necessary, and store it to instance data
	;
	mov	bp, VBGSS_lineColor
	call	SetColorCommon

	;
	;	Update the screen gstate to contain the new line color, if
	;	necessary
	;
	mov	bp, ds:[di].VBI_screenGState
	tst	bp
	jz	done

	call	VisBitmapApplyGStateStuff
done:
	ret
VisBitmapSetLineColor	endm

if BITMAP_TEXT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSetTextColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_TEXT_REPLACE_ALL_COLOR handler for VisBitmapClass.
		Sets the text color of the VisBitmap's text object.

CALLED BY:	

PASS:		ch - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					cl = index
				CF_RGB (1)
					cl = red
					dl = green
					dh = blue

		ds:di = VisBitmap instance
		
CHANGES:	nothing

RETURN:		nothing

DESTROYED:	ax, bx, bp, si, di

PSEUDO CODE/STRATEGY:
		send a MSG_VIS_TEXT_SET_COLOR to our text object

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetTextColor	method	VisBitmapClass, MSG_VIS_BITMAP_SET_TEXT_COLOR
	;
	;	Tell the text object to set its color to the passed color
	;
	mov	bx, ds:[di].VBI_visText.handle
	mov	si, ds:[di].VBI_visText.chunk

	mov	ax, MSG_VIS_TEXT_SET_COLOR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
VisBitmapSetTextColor	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSetBackColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_SET_BACK_COLOR handler for VisBitmapClass.
		Sets the background color for the VisBitmap.

CALLED BY:	

PASS:		ch - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					cl = index
				CF_RGB (1)
					cl = red
					dl = green
					dh = blue

		ds:di = VisBitmap instance
		*ds:si = VisBitmap object
		
CHANGES:	The new area color is stored to instance data

RETURN:		ch = CF_RGB
		cl, dh, dl = red, blue, green of passed color

DESTROYED:	ax, bx, bp, si, di

PSEUDO CODE/STRATEGY:
		call SetColorCommon with the VBGSS_areaColor slot,
		then pass the info on to the text object

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetBackColor	method	VisBitmapClass, MSG_VIS_BITMAP_SET_BACK_COLOR
	;
	;	Make the call to SetColorCommon, which will translate the
	;	color to RGB if necessary, and store it to instance data
	;
	mov	bp, VBGSS_backColor
	call	SetColorCommon
	ret
VisBitmapSetBackColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SET_AREA_COLOR handler for VisBitmapClass. Sets the
		area color for the VisBitmap so that any tools that require
		an area color use the passed color.

CALLED BY:	

PASS:		ch - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					cl = index
				CF_RGB (1)
					cl = red
					dl = green
					dh = blue

		ds:di = VisBitmap instance
		*ds:si = VisBitmap object
		
CHANGES:	The new area color is stored to instance data

RETURN:		ch = CF_RGB
		cl, dh, dl = red, blue, green of passed color

DESTROYED:	ax, bx, bp, si, di

PSEUDO CODE/STRATEGY:
		call SetColorCommon with the VBGSS_areaColor slot,
		then pass the info on to the text object

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetLineWidth	method	VisBitmapClass, MSG_VIS_BITMAP_SET_LINE_WIDTH
	mov	ds:[di].VBI_gStateStuff.VBGSS_lineWidth, cx
	;
	;	Update the screen gstate to contain the new line width, if
	;	necessary
	;
	mov	bp, ds:[di].VBI_screenGState
	tst	bp
	jz	done

	call	VisBitmapApplyGStateStuff
done:
	ret
VisBitmapSetLineWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmatSetGStateStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SET_GSTATE_STUFF handler for VisBitmap.
		Sets all the gstate related intfo for the bitmap.

CALLED BY:	

PASS:		ss:bp = pointer to BitMapGraphicsStateStuff record
		ds:di = VisBitmap instance
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetGStateStuff	method	VisBitmapClass, MSG_VIS_BITMAP_SET_GSTATE_STUFF
	uses	ax
	.enter

	;
	;  Setup es:di pointing to the VisBitmap's gStateStuff
	;
	segmov	es, ds
	add	di, offset VBI_gStateStuff

	;
	;  Setup ds:si pointing to the passed structure
	;
	segmov	ds, ss
	mov	si, bp

	;
	;  Let 'er rip!
	;
	mov	cx, size VisBitmapGraphicsStateStuff / 2
	rep movsw

	.leave
	ret
VisBitmapSetGStateStuff	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapApplyGStateStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_APPLY_GSTATE_STUFF handler for VisBitmapClass.

CALLED BY:	

PASS:		bp = gstate
		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		
CHANGES:	applies data in VisBitmap's BitmapGStateStuff to the gstate

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisBitmapApplyGStateStuff	method	VisBitmapClass,
				MSG_VIS_BITMAP_APPLY_GSTATE_STUFF

	xchg	di, bp				;di <- gstate handle
						;ds:bp = VisBitmap instance

	mov	ax, ds:[bp].VBI_gStateStuff.VBGSS_areaColor.high	
	mov	bx, ds:[bp].VBI_gStateStuff.VBGSS_areaColor.low
	call	GrSetAreaColor

	mov	ax, ds:[bp].VBI_gStateStuff.VBGSS_lineColor.high
	mov	bx, ds:[bp].VBI_gStateStuff.VBGSS_lineColor.low
	call	GrSetLineColor

	push	dx
	mov	dx, ds:[bp].VBI_gStateStuff.VBGSS_lineWidth
	clr	ax
	call	GrSetLineWidth
	pop	dx

	xchg	bp, di				;bp <- gstate
	ret
VisBitmapApplyGStateStuff	endm
		
BitmapEditCode	ends

