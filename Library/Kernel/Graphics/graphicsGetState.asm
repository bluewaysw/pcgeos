COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphics
FILE:		graphicsGetState.asm

AUTHOR:		Steve Scholl, Oct  7, 1989

ROUTINES:
	Name			Description
	----			-----------
    GBL	GrGetMixMode		Returns the drawing mode from a GState
    GBL	GrGetLineColor		Returns the line color from a GState
    GBL	GrGetAreaColor		Returns the area color from a GState
    GBL	GrGetTextColor		Returns the text color from a GState
    GBL	GrGetLineMask		Returns the line draw mask from a GState
    GBL	GrGetAreaMask		Returns the area draw mask from a GState
    GBL	GrGetTextMask		Returns the text draw mask from a GState
    GBL	GrGetLineColorMap    	Returns line color map mode from a GState
    GBL	GrGetAreaColorMap    	Returns area color map mode from a GState
    GBL	GrGetTextColorMap    	Returns text color map mode from a GState
    GBL	GrGetTextSpacePad	Returns text space padding from a GState
    GBL	GrGetTextStyle		Returns text style from a GState
    GBL	GrGetTextMode		Returns text mode from a GState
    GBL	GrGetTextDrawOffset	Returns text draw offset from a GState
    GBL	GrGetLineWidth		Returns line width from a GState
    GBL	GrGetLineEnd    	Returns line end type from a GState
    GBL	GrGetLineJoin    	Returns line join type from a GState
    GBL	GrGetLineStyle    	Returns line style
    GBL	GrGetMiterLimit		Returns miter limit from a GState
    GBL	GrGetCurPos		Returns current pen position
    GBL GrGetInfo		Get info from gstate
    GBL GrGetFont		Get current fontID and point size
    GBL	GrGetGStringHandle	Get gstring handle from gstate

    INT	GetPrivateData		Return private data words from gstate
    INT GetWindow		Returns handle for window assoc with gstate
    INT GetPenPos		Returns current pen position

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	10/ 7/89		Initial revision


DESCRIPTION:



	$Id: graphicsGetState.asm,v 1.1 97/04/05 01:13:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the private data from a GState

CALLED BY:	GLOBAL

PASS: 		di - handle of graphics state
		ax - value in GrInfoType for type of info to get

RETURN: 	for ax =
		    GIT_PRIVATE_DATA:
			ax, bx, cx, dx - private data
		    GIT_WINDOW:
			ax - window that graphics state is associated with
		    GIT_PEN_POS:
			ax - pen x position
			bx - pen y position
		    GIT_PEN_POS:

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetInfo	proc	far
		push	ds
		call	LockDI_DS_checkFar
		push	di
EC<		test	ax, 1		; ODD?				>
EC<		ERROR_NZ GRAPHICS_BAD_GR_INFO_TYPE			>
EC<		cmp	ax, GrInfoType					>
EC<		ERROR_AE GRAPHICS_BAD_GR_INFO_TYPE			>
					; Get start of table
		mov	di, offset GetInfoTable
		add	di, ax		; add offset to routine entry
		call	cs:[di]		; call routine listed in table
		pop	di
		GOTO	UnlockDI_popDS, ds
GrGetInfo	endp

;------------------------------------------------------------------------

GetInfoTable	label	word
		word	offset GetPrivateData
		word	offset GetWindow


GetPrivateData	proc	near
		mov	ax,ds:[GS_privData].GPD_ax
		mov	bx,ds:[GS_privData].GPD_bx
		mov	cx,ds:[GS_privData].GPD_cx
		mov	dx,ds:[GS_privData].GPD_dx
		ret
GetPrivateData	endp


GetWindow	proc	near
		mov	ax,ds:[GS_window]
		ret
GetWindow	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns line drawing color from Graphics State

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
		al = R
		bl = G
		bh = B

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetLineColor	proc	far
		push	ds			;don't destroy
		mov	bx, GS_lineAttr
getColorCommon	label	near
		call	LockDI_DS_checkFar
		mov	al,ds:[bx].CA_colorRGB.RGB_red
		mov	bx,word ptr ds:[bx].CA_colorRGB.RGB_green
		GOTO	UnlockDI_popDS, ds
GrGetLineColor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns area drawing color from Graphics State

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
		al = R
		bl = G
		bh = B

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetAreaColor	proc	far
		push	ds			;don't destroy
		mov	bx, GS_areaAttr
		jmp	getColorCommon
GrGetAreaColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns text drawing color from Graphics State

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
		al = R
		bh = G
		bl = B

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetTextColor	proc	far
		push	ds			;don't destroy
		mov	bx, GS_textAttr
		jmp	getColorCommon
GrGetTextColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the text mode from a graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
	al - mode bits
		bit 7: kerning on (TEXT_MODE_KERNING)
		bit 6: fractional widths on (TEXT_MODE_FRAC_WIDTH)
		bit 5: draw from middle of font box.
		bit 4: draw from baseline-offset of font.
		bit 3: draw from bottom of font.
		bit 2: draw from ascent line of font.
		bits 1-0: unused.

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetTextMode	proc	far
		push	ds			;don't destroy
		call	LockDI_DS_checkFar
		mov	al,ds:[GS_textMode]
		GOTO	UnlockDI_popDS, ds
GrGetTextMode	endp

GraphicsCommon ends

;----------------

GraphicsObscure	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetMixMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the drawing mode from the graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphic state

RETURN:		al - current draw mode

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetMixMode	proc	far
		push	ds			;don't destroy
		push	bx
		mov	bx, offset GS_mixMode
		call	LockDI_DS_checkFar
		mov	al,ds:[bx]
		pop	bx
		GOTO	UnlockDI_popDS, ds
GrGetMixMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetLineMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return information about the line mask in a graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state
		al	- enum, of type GetMaskType
				GMT_ENUM	- returns record of type
						  SysDrawMask
				GMT_BUFFER - returns entire mask buffer
						  ((size DrawMask) bytes)

						  ds:si are passed pointing at
						  the buffer to fill.
RETURN: 	if GMT_ENUM passed:
			al - SysDrawMask record

		if GMT_BUFFER passed:
			al - SysDrawMask record
			buffer at ds:si filled with mask

DESTROYED:
		nothing


PSEUDO CODE/STRATEGY:
		if (GMT_ENUM)
			return enum stored in gstate
		else
			return buffer stored in gstate

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89	Initial version
	jim	1/18/90		added options

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetLineMask	proc	far
		
if	FULL_EXECUTE_IN_PLACE
EC <		cmp	al, GMT_BUFFER					>
EC <		jne	continue					>
EC <		push	bx						>
EC <		mov	bx, ds			; bx:si = buffer	>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
continue::
endif
		
		push	ds				;don't destroy
		push	bx
		mov	bx, GS_lineAttr
getMaskCommon	label	near
		call	GetMask
		pop	bx
		GOTO	UnlockDI_popDS, ds
GrGetLineMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetAreaMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return information about the area mask in a graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state
		al	- enum, of type GetMaskType
				GMT_ENUM	- returns record of type
						  SysDrawMask
				GMT_BUFFER - returns entire mask buffer
						  ((size DrawMask) bytes)

						  ds:si are passed pointing at
						  the buffer to fill.
RETURN: 	if GMT_ENUM passed:
			al - SysDrawMask record

		if GMT_BUFFER passed:
			al - SysDrawMask record
			buffer at ds:si filled with mask

DESTROYED:
		nothing


PSEUDO CODE/STRATEGY:
		if (GMT_ENUM)
			return enum stored in gstate
		else
			return buffer stored in gstate

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version
	jim	1/18/90		added options

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetAreaMask	proc	far

if	FULL_EXECUTE_IN_PLACE
EC <		cmp	al, GMT_BUFFER					>
EC <		jne	continue					>
EC <		push	bx						>
EC <		mov	bx, ds			; bx:si = buffer	>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
continue::
endif
		push	ds				;don't destroy
		push	bx
		mov	bx, GS_areaAttr
		jmp	getMaskCommon
GrGetAreaMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return information about the text mask in a graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state
		al	- enum, of type GetMaskType
				GMT_ENUM	- returns record of type
						  SysDrawMask
				GMT_BUFFER - returns entire mask buffer
						  ((size DrawMask) bytes)

						  ds:si are passed pointing at
						  the buffer to fill.
RETURN: 	if GMT_ENUM passed:
			al - SysDrawMask record

		if GMT_BUFFER passed:
			al - SysDrawMask record
			buffer at ds:si filled with mask

DESTROYED:
		nothing


PSEUDO CODE/STRATEGY:
		if (GMT_ENUM)
			return enum stored in gstate
		else
			return buffer stored in gstate

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89	Initial version
	jim	1/18/90		added options

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetTextMask	proc	far

if 	FULL_EXECUTE_IN_PLACE
EC <		cmp	al, GMT_BUFFER					>
EC <		jne	continue					>
EC <		push	bx						>
EC <		mov	bx, ds			; bx:si = buffer	>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
continue::
endif		
		push	ds				;don't destroy
		push	bx
		mov	bx, GS_textAttr
		jmp	getMaskCommon
GrGetTextMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return information about the mask in a graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state
		bx - offset to attributes we want mask for

		al	- enum, of type GetMaskType
				GMT_ENUM	- returns record of type
						  SysDrawMask
				GMT_BUFFER - returns entire mask buffer
						  ((size DrawMask) bytes)

						  ds:si are passed pointing at
						  the buffer to fill.
RETURN: 	if GMT_ENUM passed:
			al - SysDrawMask record

		if GMT_BUFFER passed:
			buffer at ds:si filled with mask

DESTROYED:
		nothing


PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89	Initial version
	jim	1/17/90		New improved version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetMask		proc	near
		uses	es
		.enter

EC<		cmp	al, GetMaskType				>
EC<		ERROR_AE	GRAPHICS_ILLEGAL_GET_MASK_TYPE	>

		segmov	es,ds
		call	LockDI_DS_checkFar
		
		; ds -> gstate segment, get the requested data

		cmp	al, GMT_ENUM	; want the number ?
		mov	al, ds:[bx].CA_maskType
		jne	getBuffer		;  no return the buffer
done:
		.leave
		ret

getBuffer:
		push	ax
		mov	ax, {word} ds:[bx].CA_mask
		mov	es:[si], ax
		mov	ax, {word} ds:[bx].CA_mask+2
		mov	es:[si+2], ax
		mov	ax, {word} ds:[bx].CA_mask+4
		mov	es:[si+4], ax
		mov	ax, {word} ds:[bx].CA_mask+6
		mov	es:[si+6], ax
		pop	ax
		jmp	done
GetMask		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetLineColorMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the line color map mode from the graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
	al
	    bits 0,1 = color mapping mode:
		0 - map colors to black or white (GR_CMT_CLOSEST)
		1 - map colors to gray scales (GR_CMT_DITHER)
		2 - map colors to patterns (GR_COLOR_MAP_PATTERN)

	     bit 2 = color-to-bw background color

		0 - writing on white background
		1 - writing on black background

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetLineColorMap proc	far
		push	ds			;don't destroy
		call	LockDI_DS_checkFar
		mov	al,ds:[GS_lineAttr.CA_mapMode]
		GOTO	UnlockDI_popDS, ds
GrGetLineColorMap endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetAreaColorMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the area color map mode from the graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
	al
	    bits 0,1 = color mapping mode:
		0 - map colors to black or white (GR_CMT_CLOSEST)
		1 - map colors to gray scales (GR_CMT_DITHER)
		2 - map colors to patterns (GR_COLOR_MAP_PATTERN)

	     bit 2 = color-to-bw background color

		0 - writing on white background
		1 - writing on black background

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetAreaColorMap proc	far
		push	ds			;don't destroy
		call	LockDI_DS_checkFar
		mov	al,ds:[GS_areaAttr].CA_mapMode
		GOTO	UnlockDI_popDS, ds
GrGetAreaColorMap endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextColorMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text color map mode from the graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
	al
	    bits 0,1 = color mapping mode:
		0 - map colors to black or white (GR_CMT_CLOSEST)
		1 - map colors to gray scales (GR_CMT_DITHER)
		2 - map colors to patterns (GR_COLOR_MAP_PATTERN)

	     bit 2 = color-to-bw background color

		0 - writing on white background
		1 - writing on black background

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetTextColorMap proc	far
		push	ds			;don't destroy
		call	LockDI_DS_checkFar
		mov	al,ds:[GS_textAttr].CA_mapMode
		GOTO	UnlockDI_popDS, ds
GrGetTextColorMap endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextSpacePad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the amount to pad spaces that is stored in the
		graphics state.

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
		dx.bl - space padding (WBFixed)
		DBCS:
			dx:15 - 1 = char padding, 0 = space padding
			dx:0-14 - space padding

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetTextSpacePad proc	far
		push	ds		;don't destroy
		call	LockDI_DS_checkFar
		mov	dx,ds:GS_textSpacePad.WBF_int
if CHAR_JUSTIFICATION
EC <		test	ds:GS_textMiscMode, not (mask TMMF_CHARACTER_JUSTIFICATION) >
EC <		ERROR_NZ GRAPHICS_ILLEGAL_TEXT_MISC_MODE_BITS_SET	>
		ornf	dh,ds:GS_textMiscMode
endif
		mov	bl,ds:GS_textSpacePad.WBF_frac
		GOTO	UnlockDI_popDS, ds
GrGetTextSpacePad endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current FontID and pointsize

CALLED BY:	GLOBAL

PASS:		di 	- handle of graphics state

RETURN:		cx	- fontID
		dx.ah	- pointsize (WBFixed)

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	3/5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetFont 	proc	far
		push	ds		;don't destroy
		call	LockDI_DS_checkFar
		movwbf	dxah, ds:GS_fontAttr.FCA_pointsize
		mov	cx, ds:GS_fontAttr.FCA_fontID
		GOTO	UnlockDI_popDS, ds
GrGetFont 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return text style from graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
	al - style bits (TextStyle)

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetTextStyle	proc	far
		push	ds			;don't destroy
		call	LockDI_DS_checkFar
		mov	al,ds:[GS_fontAttr].FCA_textStyle
		GOTO	UnlockDI_popDS, ds
GrGetTextStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextDrawOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the GS_textDrawOffset field of a gstate

CALLED BY:	Global
PASS:		di	= GState handle
RETURN:		ax	= GS_textDrawOffset
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetTextDrawOffset	proc	far
	push	ds			;don't destroy
	call	LockDI_DS_checkFar
	mov	ax, ds:GS_textDrawOffset
	GOTO	UnlockDI_popDS, ds
GrGetTextDrawOffset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns line width from graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:		dx.ax - line width

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89	Initial version
	jim	4/9/92		Rewritten for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetLineWidth	proc	far
		push	ds			;don;t destroy
		call	LockDI_DS_checkFar
		movdw	dxax, ds:[GS_lineWidth]
		GOTO	UnlockDI_popDS, ds
GrGetLineWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetLineEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return line end type from graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
		al - end type (enum type in LineEnd)

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetLineEnd	proc	far
		push	ds			;don;t destroy
		call	LockDI_DS_checkFar
		mov	al, ds:[GS_lineEnd]
		GOTO	UnlockDI_popDS, ds
GrGetLineEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetLineJoin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return line join type from graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
		al - join type (enum type in LineJoin)

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetLineJoin	proc	far
		push	ds			;don;t destroy
		call	LockDI_DS_checkFar
		mov	al, ds:[GS_lineJoin]
		GOTO	UnlockDI_popDS, ds
GrGetLineJoin 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetLineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return line join type from graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
		al - style type (enum type in LineStyle)

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		needs to return more info if custom dash array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetLineStyle	proc	far
		push	ds			;don't destroy
		call	LockDI_DS_checkFar
		mov	al, ds:[GS_lineStyle]
		GOTO	UnlockDI_popDS, ds
GrGetLineStyle 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetMiterLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the miter limit from the graphics state

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:
		bx:ax  - miter limit (16 bits integer, 	16 bits fractional)

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		The graphics state hold the inverse of the miter limit
		so we must invert it before it is returned

		See GrSetMiterLimit for more info

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetMiterLimit	proc	far
		push	ds			;don't destroy
		call	LockDI_DS_checkFar
		clr	bx			;assume no int to reciprocate
		mov	ax,ds:[GS_inverseMiterLimit]	;get inverse
		cmp	ax,0ffffh
		je	GGML_100
		call	GrReciprocal32Far
GGML_90:
		GOTO	UnlockDI_popDS, ds

GGML_100:		;special case of fffh means that 1 was passed
		inc	bx			;to GrSetMiterLimit
		inc	ax			; sets bx=1, ax=0
		jmp	short GGML_90
GrGetMiterLimit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetGStringHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the gstring handle associated with a gstate

CALLED BY:	GLOBAL

PASS:		di	- GState handle

RETURN:		ax	- GString handle or 0 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just lock the gstate and fetch the handle

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		srs	09/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetGStringHandle	proc	far
		uses	bx, ds
		.enter
		mov	bx, di
		call	MemLock
		mov	ds, ax
		mov	ax, ds:[GS_gstring]
		call	MemUnlock
		.leave
		ret
GrGetGStringHandle	endp

GraphicsObscure	ends
