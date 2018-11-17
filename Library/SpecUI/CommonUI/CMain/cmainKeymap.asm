COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	SPUI
MODULE:		CMain
FILE:		cmainKeymap.asm

AUTHOR:		David Litwin, May 13, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/13/94   	Initial revision


DESCRIPTION:
	This file contains the code for the VisKeymapClass.
		

	$Id: cmainKeymap.asm,v 1.1 97/04/07 10:52:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonUIClassStructures segment resource
	VisKeymapClass
CommonUIClassStructures ends


VisKeymapCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup our GState once we get it.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= VisKeymapClass object
		ds:di	= VisKeymapClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapOpen	method dynamic VisKeymapClass, 
					MSG_VIS_OPEN
	.enter

	mov	di, offset VisKeymapClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisKeymap_offset
	mov	di, ds:[di].VCGSI_gstate

	mov	ax, MM_COPY			; al = draw mode
	call	GrSetMixMode

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetLineColor
	call	GrSetTextColor

	call	VisKeymapSetEnabledDisabledDrawMask

	.leave
	ret
VisKeymapOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the VisKeymap object

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= VisKeymapClass object
		ds:di	= VisKeymapClass instance data
		^hbp	= GState
		cl	= DrawFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDraw	method dynamic VisKeymapClass, 
					MSG_VIS_DRAW
	.enter

	mov	di, bp

	call	GrSaveState
	mov	ax, MM_COPY			; al = draw mode
	call	GrSetMixMode

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetLineColor
	call	GrSetTextColor

	call	VisKeymapSetEnabledDisabledDrawMask

	clr	dx					; letters and outlines
	call	VisKeymapRedraw
	call	GrRestoreState

	.leave
	ret
VisKeymapDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapSetEnabledDisabledDrawMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the draw mask to 100% or 50% depending on whether or
		not we are enabled or disabled.

CALLED BY:	ViskeymapOpen, VisKeymapRedraw, VisKeymapSendKeyPress

PASS:		*ds:si	= VisKeymapClass object
		^hdi	= GState
RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapSetEnabledDisabledDrawMask	proc	near
	uses	bx, cx, dx, bp
	.enter

	;
	; Assume enabled, but set to gray if not
	;
	push	si, di
	mov	ax, MSG_VIS_GET_ATTRS
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			;CX <- classed event
	pop	si, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent

	test	cl, mask VA_FULLY_ENABLED

	mov	al, SDM_100
	jnz	gotMask

	mov	al, SDM_50
gotMask:
	call	GrSetAreaMask
	call	GrSetLineMask
	call	GrSetTextMask

	.leave
	ret
VisKeymapSetEnabledDisabledDrawMask	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw the Keymap from the tables pointed to by our instance
		data.

CALLED BY:	VisKeymapDraw, VisKeymapPress

PASS:		*ds:si	= VisKeymapClass object
		^hdi	= GState
		dx	= True to draw only letters
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapRedraw	proc	near
	uses	ax, bx, cx, dx, bp, ds, es, di, si
	.enter

	push	dx
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisKeymap_offset
	mov	cx, ds:[bx].VKMI_desc.KMD_letterFontType
	mov	dx, ds:[bx].VKMI_desc.KMD_letterFontSize
	clr	ax				; dx.ah is font size
	call	GrSetFont
	pop	dx

	mov	bx, handle VisKeymapData
	call	MemLock
	mov	es, ax

	push	si				; save our chunk handle
	mov	si, ds:[si]			; give up the chunk handle
	add	si, ds:[si].VisKeymap_offset	;   for the instance ptr

	tst	dx
	jnz	afterOutlineDraw

	call	ds:[si].VKMI_desc.KMD_drawOutlines

afterOutlineDraw:
	clr	cx
	mov	cl, ds:[si].VKMI_desc.KMD_layoutLength
	mov	bp, ds:[si].VKMI_desc.KMD_layoutOffset	; cs:bp is layoutoffset
	mov	bx, ds:[si].VKMI_desc.KMD_layoutChars	; char array chunk

	mov	bx, es:[bx]			; dereference char array chunk

	push	dx
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics
	pop	ax				; restore letter only flag to ax
	pop	si				; restore our chunk handle

	;
	; ax	= true if only drawing letters (no outlines)
	; bx	= ptr into char array chunk
	; cx	= keys remaining to check in keymap layout
	; dx	= height of letter font
	; bp	= ptr to Rectangle description of key
	; di	= GState
	; *ds:si = VisKeymapClass object
	;
keyLoop:
	push	ax, cx				; letters flag, loop counter
	tst	ax

	push	bx, dx
	mov	ax, cs:[bp].R_left
	mov	bx, cs:[bp].R_top
	mov	cx, cs:[bp].R_right
	mov	dx, cs:[bp].R_bottom
	jz	drawLine

	inc	ax				; inside of key only
	inc	bx
	push	ax
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	pop	ax
	call	GrFillRect			; blank out old letter
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor
	jmp	afterDrawOrBlank

drawLine:
	mov	ax, cx
	call	GrDrawVLine			; complete the key outline

afterDrawOrBlank:
	pop	bx, dx

	LocalGetChar	ax, esbx
SBCS<	mov	ah, CS_BSW				>
SBCS<	cmp	al, C_SPACE				>
SBCS<	jae	gotIt					>
SBCS<	mov	ah, CS_CONTROL				>
SBCS<gotIt:						>

	call	VisKeymapHandleSubstitutions

	call	VisKeymapCheckIfSpecialKey
	jc	specialChar

	call	VisKeymapDrawLetter
	jmp	nextKey

specialChar:
	call	VisKeymapDrawSpecialKey

nextKey:
	pop	ax, cx
	add	bp, size Rectangle
	loop	keyLoop


	mov	bx, handle VisKeymapData
	call	MemUnlock

	.leave
	ret
VisKeymapRedraw	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapCheckIfSpecialKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a character is a special key.  If so,
		return the special information about it.

CALLED BY:	VisKeymapRedraw

PASS:		*ds:si	= VisKeymapClass object
		es	= segment of locked down VisKeymapData
		ax	= character to check
RETURN:		carry	= clear if it is a normal character
				ax = unchanged
			= set if it is a special character
				es:ax = KeymapSpecialKeyInfo
				
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapCheckIfSpecialKey	proc	near
	uses	si, di
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].VisKeymap_offset

	tst	ds:[si].VKMI_specialKeys	; do we have a special key table
	clc
	jz	exit

	mov	di, ds:[si].VKMI_specialKeys
	mov	di, es:[di]			; dereference special keys chunk

specialCharLoop:
	cmp	ax, es:[di].KSKI_char
	jne	nextSpecialChar

	mov	ax, di				; es:ax is our KSKI stuct
	stc
	jmp	exit

nextSpecialChar:
	add	di, size KeymapSpecialKeyInfo
	tst	es:[di].KSKI_char
	jnz	specialCharLoop

	clc					; no special char found

exit:
	.leave
	ret
VisKeymapCheckIfSpecialKey	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawSpecialKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the special text/gstring/bitmap/letter of this
		key, and invert it if the keymap object is currently
		in that state.

CALLED BY:	VisKeymapRedraw

PASS:		*ds:si	= VisKeymapClass object
		^hdi	= GState
		es:ax	= KeymapSpecialKeyInfo
		dx	= fontheight
		cs:bp	= Rectangle of keys bounds
RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawSpecialKey	proc	near
	uses	bx, cx
	.enter

	mov	bx, ax
	clr	cx
	mov	cl, es:[bx].KSKI_drawData.KSKDD_drawType
	test	cl, mask KSKDI_GREY
	jz	stripKSKDIs

	;
	; Set to a grey pattern
	;
	mov	al, SDM_50
	call	GrSetAreaMask
	call	GrSetLineMask
	call	GrSetTextMask

stripKSKDIs:
	andnf	cl, not (mask KSKDI_INVERT or mask KSKDI_GREY)

	;
	; All but KSKDT_LETTER use drawData in ax.
	;
	mov	ax, es:[bx].KSKI_char
	cmp	cx, KSKDT_LETTER
	je	drawLetter

	mov	ax, es:[bx].KSKI_drawData.KSKDD_data

	cmp	cx, KSKDT_ALTERNATE
	je	drawLetter

	cmp	cx, KSKDT_STRING
	je	drawString

EC<	cmp	cx, KSKDT_BITMAP		>
EC<	ERROR_NE	ERROR_ILLEGAL_KSKDT	>
	call	VisKeymapDrawBitmap
	jmp	afterDraw

drawString:
	call	VisKeymapDrawString
	jmp	afterDraw

drawLetter:
	call	VisKeymapDrawLetter

	;
	; Check if we should invert because of the draw type or because
	; the key is a state key and we are in that state.  If both, 
	; don't invert because they cancel.
	;
afterDraw:
	mov	cl, es:[bx].KSKI_state
	push	si					; preserve our lptr
	mov	si, ds:[si]
	add	si, ds:[si].VisKeymap_offset		; deref to si
	and	cl, ds:[si].VKMI_currentState
	pop	si					; restore our lptr

	mov	ch, es:[bx].KSKI_drawData.KSKDD_drawType
	test	ch, mask KSKDI_GREY
	jz	maskReset

	mov	al, SDM_100
	call	GrSetAreaMask
	call	GrSetLineMask
	call	GrSetTextMask

maskReset:
	and	ch, mask KSKDI_INVERT
	jcxz	exit				; neither were set

	tst	cl				; state key?
	jz	invertIt
	tst	ch				; draw inverted?
	jnz	exit

invertIt:
	call	VisKeymapInvertKey

exit:
	.leave
	ret
VisKeymapDrawSpecialKey	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a letter for a key

CALLED BY:	VisKeymapRedraw

PASS:		^hdi	= GState
		ax	= character to draw
		dx	= font height
		cs:bp	= Rectangle of key's bounds
RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawLetter	proc	near
	uses	bx, cx, dx
	.enter

	;
	; if we are the null character, draw a gray key
	;
	LocalIsNull	ax
	jnz	drawChar

	mov	ax, GMT_ENUM
	call	GrGetAreaMask
	push	ax				; preserve old area mask
	mov	al, SDM_50
	call	GrSetAreaMask
	mov	ax, cs:[bp].R_left
	inc	ax				; inside key bounds
	mov	bx, cs:[bp].R_top
	inc	bx
	mov	cx, cs:[bp].R_right
	mov	dx, cs:[bp].R_bottom
	call	GrFillRect
	pop	ax				; restore old area mask
	call	GrSetAreaMask
	jmp	exit

	;
	; figure out height (top of key + (key height - letter height)/2)
	;
drawChar:
	mov	bx, cs:[bp].R_bottom		; bottom
	sub	bx, cs:[bp].R_top		; bottom - top
	sub	bx, dx				; bottom - top - height
	inc	bx				; round up
	sar	bx, 1				; (b - t - h)/2
	add	bx, cs:[bp].R_top		; t + (b - t - h)/2

	;
	; figure out width (left of key + (key width - letter width)/2)
	;
	push	ax
	call	GrCharWidth
	mov	ax, dx				; width in ax
	pop	dx				; char in dx
	neg	ax				; -width
	add	ax, cs:[bp].R_right		; right - width
	sub	ax, cs:[bp].R_left		; right - left - width
	inc	ax				; round up
	sar	ax, 1				; (r - l - w)/2
	add	ax, cs:[bp].R_left		; l + (r - l - w)/2

	call	GrDrawChar
exit:
	.leave
	ret
VisKeymapDrawLetter	endp


;
;	We've taken out support for drawing gstrings, as to do so 
; requires allocating a block (when loading the gstring), and this is
; a bit costly.  Also, it requires a separate block for the gstrings
; data to be in, because otherwise they would grow when being loaded
; which would invalidate our pointers into the VisKeymapData block,
; which is a *bad* thing.  I am, however, not going to nuke this code
; entirely, because it does work and could be conceivable useful in
; the future.		dlitwin 5/23/94
;
if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a GString for the key.

CALLED BY:	VisKeymapRedraw

PASS:		ds:si	= VisKeymapClass instance data (si is *not* an lptr)
		^hdi	= GState
		es:ax	= lptr of GString to draw
		cs:bp	= Rectangle of key's bounds
RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawGString	proc	near
	uses	bx, cx, dx, si, es
	.enter

	;
	; Load the GString
	;
	mov	cl, GST_CHUNK
	mov	bx, handle SOME_RESOURCE_OTHER_THAN_VisKeyMapData
	mov	si, ax				; load our gstring chunk
	call	GrLoadGString

	clr	dx
	call	GrGetGStringBounds
	jc	bail

	;
	; Center the GString in the key
	;
	sub	ax, cx				; - width of gstring
	add	ax, cs:[bp].R_right
	sub	ax, cs:[bp].R_left		; key width - gstring width
	inc	ax				; round up
	sar	ax				; split difference to center
	add	ax, cs:[bp].R_left

	sub	bx, dx				; - height of gstring
	add	bx, cs:[bp].R_bottom
	sub	bx, cs:[bp].R_top		; key height - gstring height
	inc	bx				; round up
	sar	bx				; split difference to center
	add	bx, cs:[bp].R_top

	;
	; Draw the puppy
	;
	clr	dx
	call	GrDrawGString

bail:
	;
	; Free up the handle we created to draw the gstring
	;
	mov	dl, GSKT_LEAVE_DATA		; don't nuke our gstring data
	call	GrDestroyGString

	.leave
	ret
VisKeymapDrawGString	endp

endif		; endif of if 0  (see above comments)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character string in the keybounds.

CALLED BY:	VisKeymapDrawSpecialKey

PASS:		*ds:si	= VisKeymapClass object
		^hdi	= GState
		es:ax	= lptr of character string to draw
		dx	= font height
		cs:bp	= Rectangle of key's bounds
RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawString	proc	near
	uses	bx, cx, dx, si
	.enter

	push	si				; save our chunk handle

	;
	; Set our gstate to the word font for correct width calculations...
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisKeymap_offset	; deref our obj. into bx
 
	mov	cx, ds:[bx].VKMI_desc.KMD_wordFontType
	mov	dx, ds:[bx].VKMI_desc.KMD_wordFontSize
	push	ax
	clr	ax
	call	GrSetFont
	pop	ax

	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics

	;
	; figure out height (top of key + (key height - letter height)/2)
	;
	mov	bx, cs:[bp].R_bottom		; bottom
	sub	bx, cs:[bp].R_top		; bottom - top
	sub	bx, dx				; bottom - top - height
	inc	bx				; round up
	sar	bx, 1				; (b - t - h)/2
	add	bx, cs:[bp].R_top		; t + (b - t - h)/2

	;
	; figure out width (left of key + (key width - letter width)/2)
	;
	segxchg	ds, es				; swap lmem and obj block sptrs
	mov	si, ax				; es:^lbx is our string
	mov	si, ds:[si]			; dereference chunk
	ChunkSizePtr	ds, si, cx
	call	GrTextWidth

	mov	ax, dx
	neg	ax				; -width
	add	ax, cs:[bp].R_right		; right - width
	sub	ax, cs:[bp].R_left		; right - left - width
	inc	ax				; round up
	sar	ax, 1				; (r - l - w)/2
	add	ax, cs:[bp].R_left		; l + (r - l - w)/2

	;
	; ax, bx is our centered start point, ds:si is our string
	;
	clr	cx				; null terminated
	call	GrDrawText

	segxchg	ds, es

	;
	; Restore us to the letter font
	;
	pop	si				; restore our chunk handle
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisKeymap_offset	; deref our obj. into bx

	mov	cx, ds:[bx].VKMI_desc.KMD_letterFontType
	mov	dx, ds:[bx].VKMI_desc.KMD_letterFontSize
	clr	ax
	call	GrSetFont
exit:
	.leave
	ret
VisKeymapDrawString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bitmap for a key.

CALLED BY:	VisKeymapDrawSpecialKey

PASS:		^hdi	= GState
		es:ax	= lptr of bitmap to draw
		cs:bp	= Rectangle of key's bounds
RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawBitmap	proc	near
	uses	bx,dx,si,bp
	.enter

	segxchg	ds, es				; swap lmem and obj block sptrs
	mov	si, ax
	mov	si, ds:[si]			; dereference our bitmap

	;
	; Get starting height by centering our bitmap in our key
	;
	mov	bx, cs:[bp].R_bottom		; bottom
	sub	bx, cs:[bp].R_top		; bottom - top
	sub	bx, ds:[si].B_height		; bottom - top - height
	inc	bx				; round up
	sar	bx, 1				; (b - t - h)/2
	add	bx, cs:[bp].R_top		; t + (b - t - h)/2

	mov	ax, cs:[bp].R_right		; right
	sub	ax, cs:[bp].R_left		; right - left
	sub	ax, ds:[si].B_width		; right - left - width
	inc	ax				; round up
	sar	ax, 1				; (r - l - w)/2
	add	ax, cs:[bp].R_left		; l + (r - l - w)/2

	;
	; ax, bx, is our starting position, ds:si is our bitmap and
	; we won't be needing a call back
	;
	clr	dx
	call	GrFillBitmap

	segxchg	ds, es

	.leave
	ret
VisKeymapDrawBitmap	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawStylusBigKeyOutlines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outlines of the keys for the stylus
		Big Key keymap.

CALLED BY:	VisKeymapRedraw

PASS:		^hdi	= GState
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawStylusBigKeyOutlines	proc	near
	uses	ax, bx, cx, dx
	.enter

	;
	; Blank the whole area
	;
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	mov	ax, STYLUS_LEFT_MARGIN
	mov	bx, STYLUS_BK_ROW_1_T
	mov	cx, STYLUS_RIGHT_MARGIN
	mov	dx, STYLUS_BK_ROW_4_B
	call	GrFillRect
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	mov	ax, STYLUS_BK_ROW_1_L
	mov	cx, STYLUS_BK_ROW_1_L + STYLUS_BK_WIDTH*10
	mov	dx, STYLUS_BK_ROW_1_B
	call	GrDrawRect

	mov	ax, STYLUS_BK_ROW_2_L
	mov	bx, STYLUS_BK_ROW_2_T
	mov	cx, STYLUS_BK_ROW_2_L + STYLUS_BK_WIDTH*9
	mov	dx, STYLUS_BK_ROW_2_B
	call	GrDrawRect

	mov	ax, STYLUS_BK_ROW_3_L
	mov	bx, STYLUS_BK_ROW_3_T
	mov	cx, STYLUS_BK_ROW_3_L + STYLUS_BK_WIDTH*10
	mov	dx, STYLUS_BK_ROW_3_B
	call	GrDrawRect

	mov	ax, STYLUS_BK_ROW_4_L
	mov	bx, STYLUS_BK_ROW_4_T
	mov	cx, STYLUS_BK_ROW_4_L + STYLUS_BK_WIDTH*5
	mov	dx, STYLUS_BK_ROW_4_B
	call	GrDrawRect

	mov	ax, STYLUS_BK_LEFT_MARGIN
	mov	dx, STYLUS_BK_ROW_4_B
	call	VisKeymapDrawPICGadgets

	.leave
	ret
VisKeymapDrawStylusBigKeyOutlines	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawNumbersOutlines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outlines for the Numbers keymap

CALLED BY:	VisKeymapRedraw

PASS:		^di	GState
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawNumbersOutlines	proc	near
	uses	ax, bx, cx, dx
	.enter

	;
	; Blank the whole area
	;
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	mov	ax, STYLUS_NUM_GROUP_A_L
	mov	bx, STYLUS_NUM_ROW_1_T
	mov	cx, STYLUS_NUM_RIGHT_MARGIN
	mov	dx, STYLUS_NUM_ROW_4_B
	call	GrFillRect
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	;
	; Draw group A
	;
	mov	cx, STYLUS_NUM_GROUP_A_L + STYLUS_NUM_A_WIDTH*3
	call	GrDrawRect

	mov	bx, STYLUS_NUM_ROW_2_T
	call	GrDrawHLine
	mov	bx, STYLUS_NUM_ROW_3_T
	call	GrDrawHLine
	mov	bx, STYLUS_NUM_ROW_4_T
	call	GrDrawHLine

	;
	; Draw Group B
	;
	mov	ax, STYLUS_NUM_GROUP_B_L
	mov	bx, STYLUS_NUM_ROW_1_T
	mov	cx, STYLUS_NUM_GROUP_B_L + STYLUS_NUM_B_WIDTH*2
	mov	dx, STYLUS_NUM_ROW_4_B
	call	GrDrawRect

	mov	bx, STYLUS_NUM_ROW_2_T
	call	GrDrawHLine
	mov	bx, STYLUS_NUM_ROW_3_T
	call	GrDrawHLine
	mov	bx, STYLUS_NUM_ROW_4_T
	call	GrDrawHLine

	;
	; Draw Group C
	;
	mov	ax, STYLUS_NUM_GROUP_C_L
	mov	bx, STYLUS_NUM_ROW_1_T
	mov	cx, STYLUS_NUM_GROUP_C_L + STYLUS_NUM_C_WIDTH*2
	mov	dx, STYLUS_NUM_ROW_5_B
	call	GrDrawRect

	mov	bx, STYLUS_NUM_ROW_2_T
	call	GrDrawHLine
	mov	bx, STYLUS_NUM_ROW_3_T
	call	GrDrawHLine
	mov	bx, STYLUS_NUM_ROW_4_T
	call	GrDrawHLine
	mov	bx, STYLUS_NUM_ROW_5_T
	call	GrDrawHLine

	mov	ax, STYLUS_NUM_LEFT_MARGIN
	mov	dx, STYLUS_NUM_ROW_5_B
	call	VisKeymapDrawPICGadgets

	.leave
	ret
VisKeymapDrawNumbersOutlines	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawPunctuationOutlines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outlines for the Punctuation keymap

CALLED BY:	VisKeymapRedraw

PASS:		^di	GState
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawPunctuationOutlines	proc	near
	uses	ax, bx, cx, dx
	.enter

	;
	; Blank out the area first
	;
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	mov	ax, STYLUS_PUN_ROW_1_L
	mov	bx, STYLUS_PUN_ROW_1_T
	mov	cx, STYLUS_PUN_RIGHT_MARGIN
	mov	dx, STYLUS_PUN_ROW_2_B
	call	GrFillRect
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	;
	; Draw the outlines for the two rows
	;
	mov	dx, STYLUS_PUN_ROW_1_B
	call	GrDrawRect

	mov	ax, STYLUS_PUN_ROW_2_L
	mov	bx, dx
	mov	dx, STYLUS_PUN_ROW_2_B
	call	GrDrawRect

	mov	ax, STYLUS_PUN_LEFT_MARGIN
	mov	dx, STYLUS_PUN_ROW_2_B
	call	VisKeymapDrawPICGadgets

	.leave
	ret
VisKeymapDrawPunctuationOutlines	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawHWRGridOutlines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outlines for the HWRGrid keymap

CALLED BY:	VisKeymapRedraw

PASS:		^di	GState
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawHWRGridOutlines	proc	near
	uses	ax, bx, cx, dx
	.enter

	;
	; Blank out the area first
	;
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	clr	ax
	clr	bx
	mov	cx, STYLUS_PIC_KMP_WIDTH
	mov	dx, STYLUS_PIC_KMP_HEIGHT
	call	GrFillRect
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	clr	ax			; dx already set above
	call	VisKeymapDrawPICGadgets

	.leave
	ret
VisKeymapDrawHWRGridOutlines	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDrawPICGadgets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the dismiss button and the PenInputControl item groups.

CALLED BY:	VisKeymapDrawStylusBigKeyOutlines,
		VisKeymapDrawNumbersOutlines,
		VisKeymapDrawPunctuationOutlines
		VisKeymapDrawHWRGridOutlines
		KeyboardDrawStylusKeyOutlines

PASS:		^di	= GState
		ax	= left margin of our bounds
		dx	= bottom margin or our bounds
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDrawPICGadgets	proc	near
	uses	ax, bx, cx, dx
	.enter

	mov	cx, ax
	add	ax, STYLUS_PIC_KMP_L + STYLUS_PIC_KMP_WIDTH*0
	add	cx, STYLUS_PIC_KMP_L + STYLUS_PIC_KMP_WIDTH*5
	mov	bx, dx
	sub	bx, STYLUS_PIC_KMP_HEIGHT
	call	GrDrawRect
	dec	ax
	inc	cx
	inc	bx
	dec	dx
	call	GrDrawRect

	.leave
	ret
VisKeymapDrawPICGadgets	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a mouse click and turn it into a keyboard press message

CALLED BY:	InputMonitor

PASS:		*ds:si	= VisKeymapClass object
		ds:di	= VisKeymapClass instance data	
		cx, dx	= mouse coordinates of click
RETURN:		if a key was clicked on:
			di	= MSG_META_KBD_CHAR
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high = scan code
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapStartSelect	method dynamic VisKeymapClass, 
					MSG_META_START_SELECT
	uses	cx, dx, bp
	.enter

	call	VisKeymapGetKeyClicked
	jc	exit				; key not found

	mov	dx, ax				; save char in dx
	mov	bx, handle VisKeymapData
	call	MemLock
	mov	es, ax
	mov	ax, dx				; restore char to ax

	call	VisKeymapCheckIfSpecialKey
	mov	bx, ax				; es:bx = KSKI struct,if special
	mov	ax, dx				; restore char to ax
	jnc	notSpecial

	tst	es:[bx].KSKI_spKeyRoutine
	jz	notSpecial

	mov	cx, es:[bx].KSKI_params
	call	es:[bx].KSKI_spKeyRoutine
	jmp	unlockAndExit

	;
	; Just a regular key press, so send it off and undo any 
	; temporary states
	;
notSpecial:
	mov	cx, ax				; character in cx
	call	VisKeymapSendKeyPress

	mov	di, ds:[si]
	add	di, ds:[di].VisKeymap_offset
	tst	ds:[di].VKMI_currentState
	jz	unlockAndExit

	mov	cl, ds:[di].VKMI_tempStates
	not	cl				; remove any temporary
	andnf	ds:[di].VKMI_currentState, cl	;  states

	clr	cx				; add no add. states
	mov	ch, -1				; no KeyClick sound, as
	call	VisKeymapChangeState		;  we already played one

unlockAndExit:
	mov	bx, handle VisKeymapData
	call	MemUnlock

exit:
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
VisKeymapStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapSendKeyPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send off a key press to the flow object.

CALLED BY:	VisKeymapStartSelect

PASS:		*ds:si	= VisKeymapClass object
		ds:di	= VisKeymapClass instance data
		cs:bp	= Rectangle of keys bounds
		cx	= character to send
		
RETURN:		nothing
DESTROYED:	ax, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapSendKeyPress	proc	near
	uses	bx, bp, di, es
	.enter

	mov	di, ds:[di].VCGSI_gstate
	call	VisKeymapSetEnabledDisabledDrawMask
	call	VisKeymapInvertKey

	push	bp, di, si			; key ptr, obj lptr & GState
	mov	ax, MSG_META_KBD_CHAR
	clr	dx
	mov	dl, mask CF_FIRST_PRESS
	clr	bp
	clr	bx
	call	GeodeGetAppObject

	mov	ax, MSG_META_KBD_CHAR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

if 	KEY_CLICK_SOUNDS
	mov	ax, SST_KEY_CLICK
	call	UserStandardSound
endif
	;
	; Check if there is any pending MSG_META_START_SELECT (for any object)
	; in the event queue.  If so, don't sleep.
	;
	push	es
	segmov	es, dgroup, ax
	clr	es:[foundStartSelectMsg]	; reset flag
	mov	ax, MSG_META_START_SELECT
	mov	di, offset KMP_CheckDuplicateCB
	pushdw	csdi
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE \
			or mask MF_CUSTOM or mask MF_DISCARD_IF_NO_MATCH \
			or mask MF_MATCH_ALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst	es:[foundStartSelectMsg]
	pop	es
	jnz	noSleep

	mov	ax, 10				;Pause for 1/6 second
	call	TimerSleep 	

noSleep:
	mov	ax, MSG_META_KBD_CHAR
	mov	dl, mask CF_RELEASE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp, di, si			; key ptr, obj lptr & GState

	call	VisKeymapInvertKey

	.leave
	ret
VisKeymapSendKeyPress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KMP_CheckDuplicateCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to check for MSG_META_START_SELECT in queue.

CALLED BY:	INTERNAL, VisKeymapSendKeyPress (via ObjMessage)

	It looks like callback routines for MF_CUSTOM have the following
	parameters: (AY 5/24/94)

	PASS:	ds:bx	= HandleEvent of an event already on queue
		ax	= message of the new event
		cx,dx,bp = data in the new event
		si	= lptr of destination of new event
	RETURN:	bp	= new value to be passed in bp in new event
		di	= one of the PROC_SE_* values
	CAN DESTROY:	si

SIDE EFFECTS:	foundStartSelectMsg modified

PSEUDO CODE/STRATEGY:
	Speed is more important than code size.  Optimize the not-match case.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KMP_CheckDuplicateCB	proc	far
	.enter

	cmp	ds:[bx].HE_method, ax	; see if MSG_META_START_SELECT
	je	found
CheckHack <PROC_SE_CONTINUE eq 0>
	clr	di			; di = PROC_SE_CONTINUE
	ret
found:
	mov	si, es			; preserve es (faster than "uses es")
	segmov	es, dgroup, di
	mov	es:[foundStartSelectMsg], BB_TRUE
	mov	es, si			; restore es
	mov	di, PROC_SE_EXIT

	.leave
	ret
KMP_CheckDuplicateCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapGetKeyClicked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a mouse click on our object, determine (and return)
		which key they clicked on.

CALLED BY:	VisKeymapStartSelect

PASS:		*ds:si	= VisKeymapClass object
		ds:di	= VisKeymapClass instance data	
		cx, dx	= mouse coordinates of click
RETURN:		carry	= clear if key was clicked on
				ax = character of key
				cs:bp = Rectangle clicked in
			= set if not
DESTROYED:	bx, cx, dx, es

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapGetKeyClicked	proc	near
	uses	di, si
	.enter

	mov	bp, ds:[di].VKMI_desc.KMD_layoutOffset ; cs:bp is layout
	mov_tr	ax, cx
	clr	cx					; make sure ch is zero
	mov	cl, ds:[di].VKMI_desc.KMD_layoutLength

loopTop:
	cmp	ax, cs:[bp].R_left
	jl	nextKey
	cmp	ax, cs:[bp].R_right
	jg	nextKey
	cmp	dx, cs:[bp].R_top
	jl	nextKey
	cmp	dx, cs:[bp].R_bottom
	jle	foundKey

nextKey:
	add	bp, size Rectangle
	loop	loopTop
	stc
	jmp	exit

foundKey:
	push	si					; preserve our obj lptr
	sub	cl, ds:[di].VKMI_desc.KMD_layoutLength
	neg	cl					; cx is char position

	mov	si, ds:[di].VKMI_desc.KMD_layoutChars	; char array lptr
	mov	bx, handle VisKeymapData
	call	MemLock
	mov	es, ax
	mov	si, es:[si]				; dereference char array
	add	si, cx
	LocalGetChar	ax, essi
	call	MemUnlock

SBCS<	mov	ah, CS_BSW				>
SBCS<	cmp	al, C_SPACE				>
SBCS<	jae	gotIt					>
SBCS<	mov	ah, CS_CONTROL				>
SBCS<gotIt:						>
	pop	si					; restore our obj lptr
	call	VisKeymapHandleSubstitutions

	clc
exit:
	.leave
	ret
VisKeymapGetKeyClicked	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapHandleSubstitutions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dynamically stubstitute a character for another by 
		checking vardata.  Allows individual Keymap objects to
		have minor changes to standard layout.

CALLED BY:	VisKeymapGetKeyClicked

PASS:		ax	= character to check for a substitute
		*ds:si	= VisKeymapClass object
RETURN:		ax	= character substituted if necessary
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapHandleSubstitutions	proc	near
	uses	bx, cx
	.enter


	mov_tr	cx, ax				; save char in cx
	mov	ax, ATTR_VIS_KEYMAP_DYNAMIC_SUBSTITUTIONS
	call	ObjVarFindData
	mov_tr	ax, cx				; restore char to ax
	jnc	exit				; no substitutions

	clr	cx				; make sure ch is zero
	mov	cl, ds:[bx]			; get substitution count
	inc	bx				; inc past substition count
	jcxz	exit

	;
	; substitution loop.  Check all the substitution pairs for our
	; character.
	;
loopTop:
	cmp	ax, ds:[bx].KSS_actualChar
	je	substitute
	add	bx, size KeymapSubstitutionStruct
	loop	loopTop
	jmp	exit

substitute:
	mov	ax, ds:[bx].KSS_substitute

exit:
	.leave
	ret
VisKeymapHandleSubstitutions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapChangeState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the keyboard layout to a passed in state.

CALLED BY:	VisKeymapGetKeyClicked

PASS:		*ds:si	= VisKeymapClass object
		ds:di	= VisKeymapClass instance data
		es	= locked down VisKeymapData block
		cl	= KeymapStateBits
		ch	= zero to play a keyclick sound
RETURN:		nothing
DESTROYED:	bx, dx, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapChangeState	proc	near
	uses	ax, cx
	.enter

if 	KEY_CLICK_SOUNDS
	tst	ch
	jnz	noClick
	mov	ax, SST_KEY_CLICK
	call	UserStandardSound
noClick:
endif

	xor	ds:[di].VKMI_currentState, cl		; merge old/new states
							;  into currentState
	mov	cl, ds:[di].VKMI_currentState
	mov	bx, ds:[di].VKMI_descTable
	mov	bx, es:[bx]				; dereference state
	mov	ax, size KeymapDesc
	mul	cl
	add	bx, ax					; get our new keymap
	mov	ax, es:[bx].KMD_layoutChars
	mov	ds:[di].VKMI_desc.KMD_layoutChars, ax

	;
	; If anything other than the char layout is different we have to
	; redraw the outlines, otherwise we can just redraw the letters.
	;
	push	di, si
	mov	si, bx					; our source(also in bx)
	lea	di, ds:[di].VKMI_desc			; our dest
	mov	ax, di					; preserve dest in ax
	segxchg	ds, es
	mov	cx, size KeymapDesc
	repe	cmpsb
	mov	dx, -1					; assume letters only
	je	gotLettersOnlyFlag
	clr	dx
	;
	; dx is non-zero if all are then same
	;
gotLettersOnlyFlag:
	mov	si, bx					; restore source and
	mov	di, ax					;   dest
	mov	cx, size KeymapDesc
	rep	movsb
	segxchg	ds, es
	pop	di, si

	mov	di, ds:[di].VCGSI_gstate
	call	VisKeymapSetEnabledDisabledDrawMask
	call	VisKeymapRedraw

	.leave
	ret
VisKeymapChangeState	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapInvertKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a key

CALLED BY:	VisKeyboardStartSelect

PASS:		cs:bp	= Rectangle to invert
		^hdi	= GState
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapInvertKey	proc	near
	uses	ax, bx, cx, dx
	.enter

	call	GrSaveState
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor
	mov	al, MM_INVERT
	call	GrSetMixMode
	mov	ax, cs:[bp].R_left
	inc	ax				; fit it inside the border
	mov	bx, cs:[bp].R_top
	inc	bx				; fit it inside the border
	mov	cx, cs:[bp].R_right
	mov	dx, cs:[bp].R_bottom
	call	GrFillRect
	call	GrRestoreState

	.leave
	ret
VisKeymapInvertKey	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapChangeDisplayStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub routine to tell the PenInputControl to change displays.

CALLED BY:	VisKeymapStartSelect (through table)

PASS:		*ds:si	= VisKeymapClass object
		cx	= PenInputDisplayType to change to
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapChangeDisplayStub	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisKeymap_offset
	mov	di, ds:[di].VCGSI_gstate
	call	VisKeymapSetEnabledDisabledDrawMask
	call	VisKeymapInvertKey

	mov	ax, SST_KEY_CLICK
	call	UserStandardSound

	push	si
	mov	ax, MSG_GEN_PEN_INPUT_CONTROL_SET_DISPLAY
	mov	bx, segment GenPenInputControlClass 
	mov	si, offset GenPenInputControlClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	cx, di				; pass classed message in cx
	mov	dx, TO_OBJ_BLOCK_OUTPUT
	call	ObjCallInstanceNoLock

	.leave
	ret
VisKeymapChangeDisplayStub	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDismissPIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to dismiss the PenInputControl

CALLED BY:	VisKeymapStartSelect (through table)

PASS:		*ds:si	= VisKeymapClass object
		cs:bp	= Rectangle of key
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDismissPIC	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisKeymap_offset
	mov	di, ds:[di].VCGSI_gstate
	call	VisKeymapSetEnabledDisabledDrawMask
	call	VisKeymapInvertKey

	mov	ax, SST_KEY_CLICK
	call	UserStandardSound

	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
VisKeymapDismissPIC	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A stub routine to do nothing

CALLED BY:	VisKeymapStartSelect (through table)

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapDoNothing	proc	near
	ret
VisKeymapDoNothing	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeymapAddSubstituteChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a substitute character struct to the vardata of the
		object for dynamic substitution

CALLED BY:	MSG_VIS_KEYMAP_ADD_SUBSTITUTE_CHAR
PASS:		*ds:si	= VisKeymapClass object
		dx	= character to substitute
		bp	= substitution
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeymapAddSubstituteChar	method dynamic VisKeymapClass, 
					MSG_VIS_KEYMAP_ADD_SUBSTITUTE_CHAR
	.enter

	;
	; Check if we are adding it for the first time or appending
	;
	mov	ax, ATTR_VIS_KEYMAP_DYNAMIC_SUBSTITUTIONS
	call	ObjVarFindData
	jc	dataPresent

	;
	; if we are adding for the first time, simply put a one for the
	; # byte, point past it and we are ready to go.
	;
	or	ax, mask VDF_SAVE_TO_STATE
	mov	cx, size KeymapSubstitutionStruct + 1	; the 1 is the # byte
	call	ObjVarAddData
	mov	{byte} ds:[bx], 1
	inc	bx
	jmp	gotSpace

	;
	; for the case where data already exists, copy it out on to
	; the stack, reallocate the vardata to the size + one more
	; struct and write it back, incrementing the # byte and leaving
	; us pointed to the new struct.
	;
dataPresent:
	mov	ax, size KeymapSubstitutionStruct
	mul	{byte} ds:[bx]				; size of present data
	inc	ax					;  + # byte
	sub	sp, ax					; allocate our stack buf
	mov	di, sp					; start of stack buffer
	push	si					; preserve our obj lptr
	segmov	es, ss, cx
	mov	si, bx					; ds:si is our data
	mov	bx, di					; start of stack buffer
	mov	cx, ax					; size of data to copy
	rep	movsb

	;
	; allocate new vardata size and copy in
	;
	pop	si					; restore our obj lptr
	mov	di, bx					; start of stack buffer
	mov	cx, ax
	add	cx, size KeymapSubstitutionStruct
	mov	ax, ATTR_VIS_KEYMAP_DYNAMIC_SUBSTITUTIONS or \
				mask VDF_SAVE_TO_STATE
	call	ObjVarAddData
	push	si
	segxchg	ds, es
	mov	si, di					; ds:si is our stack
	inc	{byte} ds:[si]				; increment # byte
	mov	di, bx					; es:di is our vardata
	sub	cx, size KeymapSubstitutionStruct
	mov	ax, cx					; size of original data
	rep	movsb
	segmov	ds, es, bx				; restore ds
	mov	bx, di					; ds:bx is for new data
	pop	si
	add	sp, ax					; pop stack buffer

gotSpace:
	mov	ds:[bx].KSS_actualChar, dx
	mov	ds:[bx].KSS_substitute, bp

	.leave
	ret
VisKeymapAddSubstituteChar	endm



VisKeymapCode	ends
