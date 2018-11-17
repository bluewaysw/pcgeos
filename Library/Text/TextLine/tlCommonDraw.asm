COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonDraw.asm

AUTHOR:		John Wedgwood, Jan  6, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 6/92	Initial revision

DESCRIPTION:
	Draw related stuff.

	$Id: tlCommonDraw.asm,v 1.1 97/04/07 11:21:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextDrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineDrawLastNChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line.

CALLED BY:	SmallLineDrawLastNChars, LargeLineDrawLastNChars
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Size of line/field data
		ss:bp	= CommonDrawParameters
		dx	= Number of characters at the end of the line to draw
			= 0 to draw the entire line
		ax	= TextClearBehindFlags
RETURN:		nothing
DESTROYED:	The position to draw at is nuked

PSEUDO CODE/STRATEGY:
	   If the TCBF_PRINT bit is *clear* (not printing) then line is
	   marked as no longer needing to be drawn

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineDrawLastNChars	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, bp
params	local	CommonDrawParameters
	.enter	inherit
	;
	; Check for line hidden... (height of zero)
	;
	tstwbf	es:[di].LI_hgt
	jz	abort
	
	test	ax, mask TCBF_PRINT
	jnz	skipDrawBitClear
	;
	; Mark line as not needing to be drawn.
	;
	and	es:[di].LI_flags, not mask LF_NEEDS_DRAW
skipDrawBitClear:

	;
	; Save the total number of characters at the end of the line to draw
	;
	mov	params.CDP_totalChars, dx
	
	;
	; Set the drawOffset to <dx>
	;
	tst	dx				; Check for optimized
	jz	skipSet				; Branch if not optimized

	push	di				; Save line offset
	call	DrawDerefGState			; di <- gstate
	mov	ax, dx				; ax <- # of characters
	call	GrSetTextDrawOffset		; Set the drawOffset
	pop	di				; Restore line offset
skipSet:

	;
	; Remove the left-offset from the position to draw
	;
	push	di				; Save line offset
	call	TextDraw_DerefVis_DI		; ds:di <- instance ptr
	mov	ax, ds:[di].VTI_leftOffset	; Account for left-offset
	add	params.CDP_drawPos.PWBF_x.WBF_int, ax
	pop	di				; Restore line offset


	sub	cx, size FieldInfo		; cx <- offset *to* last field

	mov	bx, offset LI_firstField	; bx <- offset to first field

	movdw	dxax, params.CDP_lineStart	; dx.ax <- line start

fieldLoop:
	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; bx	= Offset to field to draw
	; cx	= Offset to last field
	; dx.ax	= Start of the current field
	; ss:bp	= CommonDrawParameters
	;
	cmp	bx, cx				; Check for done
	ja	quit
	
	tst	params.CDP_totalChars		; Check for drawing everything
	jz	drawField			; Branch if we are
	cmp	bx, cx				; Check for on last field
	jne	afterDraw			; Branch if not

drawField:
	call	CommonFieldDraw			; Draw the single field

afterDraw:
	;
	; Move to the next field
	;
	add	ax, es:[di][bx].FI_nChars	; dx.ax <- offset to next field
	adc	dx, 0

	add	bx, size FieldInfo		; Move to next field
	jmp	fieldLoop			; Loop to do it

quit:
	;
	; Set the drawOffset to 0 if it was altered earlier.
	;
	tst	params.CDP_totalChars
	jz	skipRestore

	push	di				; Save line offset
	call	DrawDerefGState			; di <- gstate
	clr	ax				; Draw everything
	call	GrSetTextDrawOffset		; Set the drawOffset
	pop	di				; Restore line offset
skipRestore:

abort:
	.leave
	ret
CommonLineDrawLastNChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonFieldDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single field.

CALLED BY:	CommonLineDraw
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		es:di.bx= Field
		cx	= Offset to last field
		dx.ax	= Text offset to the start of the field
		ss:bp	= CommonDrawParameters with the following set:
				CDP_drawPos
				CDP_totalChars
RETURN:		nothing
DESTROYED:	X position is nuked

PSEUDO CODE/STRATEGY:
	nChars = field.nChars

	/*
	 * Draw any tab leader
	 */
	if (field.position != line.left) {
	    /* This field starts with a tab */
	    DrawTabLeader(line, field)
	    textOffset += 1
	    nChars -= 1
	}

	/*
	 * Set up space-padding for full justification.
	 */
if (field == lastFieldOffset) {
	    GState.spacePadding = line.spacePad
	    /*
	     * Account for field ending in cr of page-break
	     */
	    if (line.flags & (LF_ENDS_IN_CR | 
	    		      LF_ENDS_IN_COLUMN_BREAK |
			      LF_ENDS_IN_SECTION_BREAK) {
		nChars -= 1
	    }
	} else {
	    GState.spacePadding = 0
	}

	/*
	 * Now draw the field in pieces
	 */
	pos = field.position

	while (nChars > 0) {
	    /*
	     * Compute the amount to draw in the first chunk
	     */
	    gDist = DistanceToNextGraphic(textOffset)
	    if (gDist > nChars) {
		gDist = nChars
	    }

	    /*
	     * Draw up to the next graphic (or end of field)
	     */
	    if (gDist > 0) {
		pos        += DrawTextField(..., gDist, ...)
		nChars     -= gDist
		textOffset += gDist
	    }

	    /*
	     * Draw any embedded graphic
	     */
	    if (nChars > 0) {
		pos        += DrawGraphic(..., textOffset, ...)
		nChars     -= 1
		textOffset += 1
	    }
	}

USAGE:	es:di	= Line
	es:di.bx= Field
	cx	= Offset to last field

	On stack:
		nChars	= Number of characters left to draw
		tOffset	= Offset of next piece of text to draw

	ax, dx	= Scratch

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonFieldDraw	proc	near
	class	VisTextClass
	uses	ax, cx, dx, bp
params	local	CommonDrawParameters
gdfVars	equ	params.CDP_gdfVars
	.enter	inherit
	;
	; Initialize the local variables.
	;
	movdw	params.CDP_tOffset, dxax	; Save starting offset
	mov	ax, es:[di][bx].FI_nChars	; Save number of chars in field
	mov	params.CDP_nChars, ax

	;
	; Draw any tab-leader. We only do this if the field isn't at the
	; left edge of the line. (field.position != 0)
	; If it's at the left edge of the line then it is the first field on
	; the line and doesn't start with a tab.
	;
	cmp	es:[di][bx].FI_tab, (TRT_RULER shl offset TR_TYPE) or \
				    RULER_TAB_TO_LINE_LEFT
	je	noTab				; Branch if no tab

	;
	; There is a tab at the start of the field. We draw the tab leader
	; and after that we draw one less character and we increase the 
	; text-offset by one.
	;
	; Before calling DrawTabLeader we check to see that there is really
	; a tab leader.  This prevents the TextBorder resource from being
	; loaded unecessarily.
	;
	push	ax, cx
	call	FieldGetTabLeaderType		; ax <- tab leader type
						; cx <- spacing
	cmp	ax, TL_NONE
	jz	notabLeader
	
	;
	; We still don't know if the tab-leader is required... If we are
	; only drawing a certain number of characters at the end of the field
	; and if the <tab> doesn't fall in that set of characters we can skip
	; this part.
	;
	mov	dx, params.CDP_totalChars	; dx <- total to draw
	tst	dx				; Check for drawing ita ll
	jz	drawTabLeader			; Branch if we are

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; We assume that the only way we could ever get here is if we are doing
; an optimized redraw at the end of the line (CDP_totalChars != 0).
; Since we don't support drawing more than one character at the end of
; the line, we are assured of being in the last field, therefore we need
; to take into account the possible existence of a line-terminating
; character (cr, page-break, section-break) as part of this test to see
; if we need to draw the tab-leader.
;
; This fixes a bug where if you have a tab with a leader, and you're on a
; line that contains nothing but a <cr> at the end and you hit <tab>, the
; leader doesn't redraw.
;				 4/14/93 -jw
	test	es:[di].LI_flags, mask LF_ENDS_IN_CR or \
				  mask LF_ENDS_IN_COLUMN_BREAK or \
				  mask LF_ENDS_IN_SECTION_BREAK
	jz	gotCount
	inc	dx				; Account for line-break char
gotCount:
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	sub	dx, es:[di][bx].FI_nChars	; Compare against count
	js	notabLeader			; Branch if fewer to draw than
						;    there are in the field
drawTabLeader:
	;
	; We are drawing at least as many characters as there are in this field
	; therefore we must include the tab-leader.
	;
	call	DrawTabLeader			; Draw the tab-leader

notabLeader:
	pop	ax, cx

	;
	; Draw the <TAB> character if we are showing control chars
	;
	call	DrawHiddenTabCharacter

	;
	; Reduce the number of characters and advance our offset so that
	; we don't draw the tab character at the start of the field
	;
	dec	params.CDP_nChars		; One less character to draw
	incdw	params.CDP_tOffset		; Start one character later
noTab:
	;
	; Set up the space-padding and check for the line ending in a cr or 
	; page-break.
	;
	call	SetupSpacePadding		; Set up space-padding in gstate
	jnc	noHiddenLastChar		; Branch if not last field

	test	es:[di].LI_flags, mask LF_ENDS_IN_CR or \
				  mask LF_ENDS_IN_COLUMN_BREAK or \
				  mask LF_ENDS_IN_SECTION_BREAK
	jz	noHiddenLastChar		; Branch if no page-break, etc

	;
	; The line ends in a cr or page-break. We don't want to draw it,
	; unless of course we are drawing control-characters.
	;
	call	CheckDrawControlChars		; Check for drawing ctrl-chars
	jc	noHiddenLastChar		; Branch if we are

	dec	params.CDP_nChars		; One less character to draw
noHiddenLastChar:

	;
	; Time to do the drawing...
	;
	; Initialize the GDF_vars that can be set up outside the loop.
	; We copy in:
	;	- The OD of the text object
	;	- The X position of the field
	;	- The Y position of the line (line-left + field-left)
	;	- The baseline-offset of the line
	;	- The style-callback routine
	;	- Text offset to start of field
	;
	movdw	gdfVars.GDFV_other, dssi

	movwbf	gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x, \
		params.CDP_drawPos.PWBF_x, ax
	mov	ax, es:[di][bx].FI_position
	add	gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int, ax

	movwbf	gdfVars.GDFV_saved.GDFS_drawPos.PWBF_y, \
		params.CDP_drawPos.PWBF_y, ax

	movwbf	gdfVars.GDFV_saved.GDFS_baseline, es:[di].LI_blo, ax

	;
	; Set the limit - the minimum of the lineEnd and the right edge of the
	; region.
	;
	push	cx, dx, bx
	mov	cx, params.CDP_region
	mov	dx, params.CDP_drawPos.PWBF_y.WBF_int
	mov	bx, es:[di].LI_hgt.WBF_int	;BX <- height
	call	TR_RegionLeftRight		;BX <- right edge of reg
if SIMPLE_RTL_SUPPORT
	mov	params.CDP_flip, ax
	add	params.CDP_flip, bx
endif
	mov_tr	ax, bx				;AX <- right edge of reg
	cmp	ax, es:[di].LI_lineEnd
	jb	storeLimit
	mov	ax, es:[di].LI_lineEnd
storeLimit:
	pop	cx, dx, bx
	mov	gdfVars.GDFV_saved.GDFS_limit, ax

	movcbx	gdfVars.GDFV_styleCallback, FieldDrawStyleCallback

	movdw	gdfVars.GDFV_textOffset, params.CDP_tOffset, ax

	mov	dx, cx				; ax <- offset to last field
drawLoop:
	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; bx	= Offset to the field
	; dx	= Offset to last field
	; GDF_vars completely set up
	; CommonDrawParameters with:
	;	nChars  = Number of characters to draw
	; GState is set up with space-padding
	;
	push	dx				; Save offset past fields
	movdw	dxax, gdfVars.GDFV_textOffset	; dx.ax <- current position
	call	DistanceToNextGraphic		; cx <- distance to next graphic
						; (-1 means no graphic nearby)
	cmp	cx, params.CDP_nChars		; Check for close graphic
	jbe	gotCharCount			; Branch if close graphic
	mov	cx, params.CDP_nChars		; cx <- number to draw
gotCharCount:
	pop	dx				; Restore offset past fields

	;
	; cx holds the number of characters to draw before the next graphic
	; is encountered.
	;
	jcxz	afterTextDraw			; Branch if next char == graphic

	;
	; We have a range of text to draw.
	; Fill in the rest of the GDF_vars:
	;	- Number of characters to draw (in cx)
	;	- Offset of the start of the text
	;
	mov	gdfVars.GDFV_saved.GDFS_nChars, cx
	
	;
	; Set up the "draw optional hyphen" flag.
	;
	call	SetOptionalHyphenFlag

	;
	; Set up the "draw auto-hyphen" flag
	;
	call	SetAutoHyphenFlag

	;
	; *ds:si= Instance ptr
	; ss:bp	= CommonDrawParameters with GDF_vars filled in
	;
	push	bp, di				; Save frame ptr, ptr
	call	DrawDerefGState			; di <- gstate

if SIMPLE_RTL_SUPPORT
	push	di
	call	TextDraw_DerefVis_DI		; ds:di <- instance ptr
	test	ds:[di].VTI_features, mask VTF_RIGHT_TO_LEFT
	pop	di
	je	notRTL
	call	RTLDrawTextField	; testing at the moment
	jmp	pastRTLDraw
notRTL:
	lea	bp, gdfVars
	call	GrDrawTextField
pastRTLDraw:
else
	lea	bp, gdfVars			; ss:bp <- GDF_vars
	call	GrDrawTextField
endif

	;
	; Updated:
	;	GDFV_saved.GDFS_drawPos	- Set to end of text piece drawn
	;	GDFV_textOffset		- Updated to be past text drawn
	;	
	pop	bp, di				; Restore frame ptr

	mov	ax, gdfVars.GDFV_textPointer.segment ; ax <- text segment
	call	TS_UnlockTextPtr		; Release the old text

	;
	; Update the number of characters left after the draw
	;
	sub	params.CDP_nChars, cx		; Update number left to draw
	add	gdfVars.GDFV_textOffset.low, cx
	adc	gdfVars.GDFV_textOffset.high, 0
	
afterTextDraw:
	;
	; Draw any embedded graphic
	;
	tst	params.CDP_nChars		; Check for any graphic
	jz	endLoop				; Branch if none

	;
	; There is an embedded graphic
	;
	call	DrawEmbeddedGraphic		; dx.al <- width of graphic

	dec	params.CDP_nChars		; One less character
	incdw	gdfVars.GDFV_textOffset		; Advance the offset
	jmp	drawLoop			; Loop to draw more text

endLoop:
	.leave
	ret
CommonFieldDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetOptionalHyphenFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the 'draw optional hyphen' flag in the gstate if required.

CALLED BY:	CommonFieldDraw
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
		es:di	= Line
		bx	= Offset to current field
		dx	= Offset to last field
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetOptionalHyphenFlag	proc	near
	class	VisTextClass
	uses	ax, di
	.enter	inherit	CommonFieldDraw
	;
	; Check to see if we are drawing all the remaining characters in the
	; field.
	;
	mov	ax, params.CDP_nChars
	cmp	ax, gdfVars.GDFV_saved.GDFS_nChars
	jne	setNoOptHyphen
	
	;
	; See if this is the last field on the line.
	;
	cmp	bx, dx
	jne	setNoOptHyphen
	
	;
	; See if the line ends in an optional hyphen.
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_OPTIONAL_HYPHEN
	jz	setNoOptHyphen

	mov	al, mask TM_DRAW_OPTIONAL_HYPHENS ; Set this
	clr	ah				; Clear nothing

setFlag:
	call	DrawDerefGState			; di <- gstate
	call	GrSetTextMode			; Set the mode

	.leave
	ret

setNoOptHyphen:
	clr	al				; Set nothing
	mov	ah, mask TM_DRAW_OPTIONAL_HYPHENS ; Clear this
	jmp	setFlag
SetOptionalHyphenFlag	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAutoHyphenFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the GDFSF_AUTO_HYPHEN flag if the line ends in an 
		auto-hyphen. 

CALLED BY:	CommonFieldDraw
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
		es:di	= Line
		bx	= Offset to current field
		dx	= Offset to last field
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tyj	11/6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetAutoHyphenFlag	proc	near
	class	VisTextClass
	uses	ax, di
	.enter	inherit	CommonFieldDraw
	;
	; Check to see if we are drawing all the remaining characters in the
	; field.
	;
	mov	ax, params.CDP_nChars
	cmp	ax, gdfVars.GDFV_saved.GDFS_nChars
	jne	setNoAutoHyphen
	
	;
	; See if this is the last field on the line.
	;
	cmp	bx, dx
	jne	setNoAutoHyphen
	
	;
	; See if the line ends in an auto-hyphen
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_AUTO_HYPHEN
	jz	setNoAutoHyphen
	mov	gdfVars.GDFV_saved.GDFS_flags, mask HF_AUTO_HYPHEN

exit:
	.leave
	ret

setNoAutoHyphen:
	and	gdfVars.GDFV_saved.GDFS_flags, not (mask HF_AUTO_HYPHEN)
	jmp	exit
SetAutoHyphenFlag	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHiddenTabCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a TAB character at a tab-stop if we are drawing
		control characters.

CALLED BY:	CommonFieldDraw
PASS:		*ds:si	= Instance
		es:di	= Line
		es:di.bx= Field
		cx	= Offset to last field
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawHiddenTabCharacter	proc	near
	class	VisTextClass
	.enter	inherit CommonFieldDraw

	call	CheckDrawControlChars		; Check for drawing ctrl-chars
	jnc	quit				; Branch if not

;-----------------------------------------------------------------------------
	push	ax, bx, cx, dx, di
	;
	; We are drawing control characters, draw a tab character.
	;
	; First we compute the right edge of the previous field.
	;
	clr	cx			; Assume first field
	cmp	bx, offset LI_firstField
	je	gotPrevFieldEnd		; Branch if first field

	;
	; This isn't the first field. Compute the right edge of the previous one
	;
	push	bx			; Save field offset
	sub	bx, size FieldInfo	; es:di.bx <- previous field
	mov	cx, es:[di][bx].FI_position
	add	cx, es:[di][bx].FI_width
	pop	bx			; Restore field offset

gotPrevFieldEnd:
	;
	; We have the end of the previous field.
	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; bx	= Offset to current field
	; cx	= End of previous field
	;
	add	cx, es:[di].LI_adjustment
	
	;
	; Draw the tab character at x-position cx.
	;
	; Compute the Y position to draw at.
	;
	CommonLineGetBLO			; dx.bl <- baseline
	ceilwbf	dxbl, dx			; dx <- baseline
	add	dx, params.CDP_drawPos.PWBF_y.WBF_int
	
	;
	; cx	= X position to draw the thing at
	; dx	= Y position to draw it at
	;
	push	dx				; Save Y position
	call	DrawDerefGState			; di <- gstate
	movdw	dxax, gdfVars.GDFV_textOffset	; dx.ax <- offset to the TAB
	call	SetupGStateForDrawAtOffset	; Do the setup
	pop	bx				; Restore Y position into bx
	
	;
	; Draw the character
	;
	mov	ax, cx				; ax <- x position
						; bx contains y position
	mov	dx, C_TAB			; dx <- character
						; di contains gstate
	call	GrDrawChar			; Draw the tab

	pop	ax, bx, cx, dx, di
;-----------------------------------------------------------------------------
quit:
	.leave
	ret
DrawHiddenTabCharacter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FieldGetTabLeaderType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the tab-leader type for a given field.

CALLED BY:	DrawTabLeader
PASS:		es:di	= Line
		es:di.bx= Field
		ss:bp	= Inheritable stack frame
RETURN:		ax	= TabLeader
		cx	= spacing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FieldGetTabLeaderType	proc	near	uses	bx, dx, bp, di
	.enter	inherit	CommonFieldDraw
	;
	; We have to do a few gyrations to make this work...
	;
	mov	cx, bx				; Save field pointer

	;
	; Get stack frame
	;
	mov	bx, params.CDP_liclVars		; ss:bx <- LICL_vars

	;
	; Copy parameters from one frame to the other, using ax as scratch
	;
	
	;
	; Y position to draw at
	;
	mov	ax, params.CDP_drawPos.PWBF_y.WBF_int ; ax <- Y position of draw
	mov	ss:[bx].LICL_lineBottom.WBF_int, ax
	clr	ss:[bx].LICL_lineBottom.WBF_frac

	;
	; Height of line
	;
	ceilwbf	es:[di].LI_hgt, ax		; ax <- line height
	mov	ss:[bx].LICL_lineHeight.WBF_int, ax
	clr	ss:[bx].LICL_lineHeight.WBF_frac

	;
	; Region in which we are operating
	;
	mov	ax, params.CDP_region		; ax <- region
	mov	ss:[bx].LICL_region, ax

	;
	; Get the offset into the buffer
	;
	movdw	dxax, params.CDP_tOffset	; dx.ax <- true start

	;
	; Set up the pointer to the frame for the call to get paragraph attrs
	;
	mov	bp, bx				; ss:bp <- frame ptr
	movdw	LICL_paraAttrStart, -1		; Force paraAttr to be loaded
	call	T_EnsureCorrectParaAttr		; Set up paragraph attributes

	;
	; Now get the tab position and attributes, first we must restore
	; the field pointer.
	;
	mov	bx, cx				; Restore field pointer
	mov	al, es:[di][bx].FI_tab		; al <- tab reference
	call	TabGetPositionAndAttributes	; cx <- position
						; al <- TabAttributes
						; bx <- spacing
	ExtractField	byte, al, TA_LEADER, al	; al <- TabLeader
	mov	cx, bx				; cx <- spacing

	.leave
	ret
FieldGetTabLeaderType	endp

TextDrawCode ends

TextBorder segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineWashParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wash out the area behind a line with the paragraph color

CALLED BY:	CommonLineClearArea
PASS:		*ds:si	= Instance
		ds:di	= Instance
		ss:bp	= LICL_vars with LICL_line set
		dx	= 0 to inset all edges before clearing
			= non-zero to inset all but left edge
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineWashParagraph	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter

	mov	di, ds:[di].VTI_gstate

	; set the color and other attributes

	movdw	bxax, LICL_paraAttr.VTPA_bgColor
	call	GrSetAreaColor

	mov	al, LICL_paraAttr.VTPA_bgGrayScreen
	call	GrSetAreaMask

	mov	ax, {word} LICL_paraAttr.VTPA_bgPattern
	tst	ax
	pushf
	jz	10$
	call	GrSetAreaPattern
10$:

	push	LICL_rect.R_left
	push	LICL_rect.R_top
	push	LICL_rect.R_right
	push	LICL_rect.R_bottom
	test	LICL_paraAttr.VTPA_borderFlags, mask VTPBF_LEFT \
					or mask VTPBF_TOP \
					or mask VTPBF_RIGHT or mask VTPBF_BOTTOM
	jz	20$
	call	InsetBGColorAreaForBorder
20$:

	call	FillLICLRect

	pop	LICL_rect.R_bottom
	pop	LICL_rect.R_right
	pop	LICL_rect.R_top
	pop	LICL_rect.R_left

	popf
	jz	30$
	clr	ax
	call	GrSetAreaPattern
30$:

	.leave
	ret
LineWashParagraph	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	InsetBGColorAreaForBorder

DESCRIPTION:	Inset the rectangle for the BG color for the border

CALLED BY:	INTERNAL

PASS:
	ss:bp - LICL_vars:
		LICL_paraAttr - set
		LICL_rect - bg color rect

RETURN:
	LICL_rect - updated

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
InsetBGColorAreaForBorder	proc	near	uses si
	.enter

	call	CalcRealBorder			;returns dx = border flags

	; push left and right by shadow size

	push	dx
	mov	cx, mask VTPBF_LEFT
	call	GetBorderInfo			;returns ax = total
	sub	si, ax
	add	LICL_rect.R_left,si
	pop	dx

	push	dx
	mov	cx, mask VTPBF_TOP
	call	GetBorderInfo			;returns ax = total
	add	LICL_rect.R_top,si
	pop	dx

	push	dx
	mov	cx, mask VTPBF_BOTTOM
	call	GetBorderInfo			;returns ax = total
	sub	LICL_rect.R_bottom,si
	pop	dx

	mov	cx, mask VTPBF_RIGHT
	call	GetBorderInfo			;returns ax = total
	sub	LICL_rect.R_right,si

	.leave
	ret
InsetBGColorAreaForBorder	endp

TextBorder ends

TextDrawCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSpacePadding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up space-padding for a field in the gstate

CALLED BY:	CommonFieldDraw
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		es:di.bx= Field
		cx	= Offset to last field
RETURN:		carry set if this is the last field on the line
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSpacePadding	proc	near
	class	VisTextClass
	uses	bx, dx, di, si
	.enter
	mov	si, ds:[si]			; ds:si <- instance ptr
	add	si, ds:[si].Vis_offset
	xchg	di, si				; ds:di <- instance ptr
						; es:si <- line
	mov	di, ds:[di].VTI_gstate		; di <- gstate

	;
	; Set up space-padding for the field. We do this only for the last
	; field on the line. (field == lastFieldOffset, bx == cx)
	;
	cmp	bx, cx				; Check for last field on line
	jne	setToNoPadding			; Branch if not last field

	movwbf	dxbl, es:[si].LI_spacePad	; dx.bl <- space padding

	stc					; Signal: last field on line

setPadding:
	pushf					; Save "last field" flag
	call	GrSetTextSpacePad		; Set the space padding
	popf					; Restore "last field" flag
	.leave
	ret

setToNoPadding:
	clrwbf	dxbl				; No space padding

	clc					; Signal: not last field
	jmp	setPadding
SetupSpacePadding	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DistanceToNextGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the distance to the next graphic.

CALLED BY:	CommonFieldDraw
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start looking from
RETURN:		cx	= Distance to next graphic
			= -1 if no graphic is within 65,535 characters of
			  the text-offset
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DistanceToNextGraphic	proc	near
	uses	ax, dx
	.enter
	call	TA_GraphicRunLength		; dx.ax <- distance to graphic
	;
	; We now have 32 bit offset to the next graphic. We want to convert
	; this to a meaningful 16 bit offset
	;
	mov	cx, ax				; Assume only 16 bits
	tst	dx				; Check for 32
	jz	gotOffset
	mov	cx, -1				; Use largest 16 bit number
gotOffset:
	.leave
	ret
DistanceToNextGraphic	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawEmbeddedGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an embedded graphic.

CALLED BY:	CommonFieldDraw
PASS:		*ds:si	= Instance ptr
		es:di.bx= Field
		ss:bp	= Inheritable CommonDrawParameters
		GDFS_drawPos	- Position to draw at
		GDFV_textOffset	- Offset at which the graphic lies
RETURN:		GDFV_saved.GDFS_drawPos.PWBF_x updated to be past the graphic
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawEmbeddedGraphic	proc	near
	uses	ax, bx, cx, dx, di
	class	VisTextClass
params	local	CommonDrawParameters
	.enter	inherit
	;
	; Move to the right location for drawing.
	;

if SIMPLE_RTL_SUPPORT
	push	di
	call	TextDraw_DerefVis_DI		; ds:di <- instance ptr
	test	ds:[di].VTI_features, mask VTF_RIGHT_TO_LEFT
	pop	di
	je	DEG_notRTL
	call	DrawEmbeddedGraphicRTL
	jmp	done
DEG_notRTL::
endif

	mov	ax, gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int
	mov	bx, gdfVars.GDFV_saved.GDFS_drawPos.PWBF_y.WBF_int

	call	DrawDerefGState			; di <- gstate
	call	GrMoveTo			; Go there

	;
	; dx.ax <- offset to graphic
	;
	movdw	dxax, gdfVars.GDFV_textOffset

	;
	; Put simply, we never need to draw a graphic character if we are
	; doing an optimized redraw (ie: drawing only the last few characters
	; on a line) unless the graphic is the last character on the line.
	;
	tst	params.CDP_totalChars
	jz	drawGraphic
	
	cmp	params.CDP_nChars, 1
	jne	skipOverGraphic

drawGraphic:
	;
	; Set the gstate up with the right attributes.
	;
	call	SetGStateAttributesForGraphicDraw

	;
	; Draw the graphic.
	;
	mov	bx, gdfVars.GDFV_saved.GDFS_baseline.WBF_int
	call	TG_GraphicRunDraw	; cx <- width
					; dx <- height
quit:
	;
	; Update the X position.
	;
	add	gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int, cx
if SIMPLE_RTL_SUPPORT
done:
endif
	.leave
	ret

skipOverGraphic:
	call	TG_GraphicRunSize	; cx <- width
	jmp	quit			; Update position
DrawEmbeddedGraphic	endp


if SIMPLE_RTL_SUPPORT
DrawEmbeddedGraphicRTL	proc	near
	class	VisTextClass
params	local	CommonDrawParameters
	.enter	inherit
	;
	; Move to the right location for drawing.
	;
	mov	ax, gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int
	mov	bx, gdfVars.GDFV_saved.GDFS_drawPos.PWBF_y.WBF_int
	neg	ax
	add	ax, params.CDP_flip

	call	DrawDerefGState			; di <- gstate

	push	ax
	movdw	dxax, gdfVars.GDFV_textOffset
	call	SetGStateAttributesForGraphicDraw
	call	TG_GraphicRunSize	; cx <- width
	pop	ax
	sub	ax, cx

	call	GrMoveTo			; Go there

	;
	; dx.ax <- offset to graphic
	;
	movdw	dxax, gdfVars.GDFV_textOffset

	;
	; Put simply, we never need to draw a graphic character if we are
	; doing an optimized redraw (ie: drawing only the last few characters
	; on a line) unless the graphic is the last character on the line.
	;
	tst	params.CDP_totalChars
	jz	drawGraphicRTL
	
	cmp	params.CDP_nChars, 1
	jne	skipOverGraphicRTL

drawGraphicRTL:
	;
	; Set the gstate up with the right attributes.
	;
	call	SetGStateAttributesForGraphicDraw

	;
	; Draw the graphic.
	;
	mov	bx, gdfVars.GDFV_saved.GDFS_baseline.WBF_int
	call	TG_GraphicRunDraw	; cx <- width
					; dx <- height
quitRTL:
	;
	; Update the X position.
	;
	add	gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int, cx

	.leave
	ret

skipOverGraphicRTL:
	call	TG_GraphicRunSize	; cx <- width
	jmp	quitRTL			; Update position
DrawEmbeddedGraphicRTL	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGStateAttributesForGraphicDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the gstate with text attributes suitable for drawing
		a graphic.

CALLED BY:	DrawEmbeddedGraphic
PASS:		*ds:si	= Instance
		dx.ax	= Offset to graphic
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGStateAttributesForGraphicDraw	proc	near
	class	VisTextClass
	uses	ax, bx, dx, di, si, ds
tAttr	local	TextAttr
	.enter
	mov	bx, ss				; bx:di <- ptr to attributes
	lea	di, tAttr

        push    cx
	call	TA_FarFillTextAttrForDraw	; set all the attributes
						; dx.ax <- # of chars
        pop     cx
	
	call	DrawDerefGState			; di <- gstate
	
	mov	ds, bx				; ds:si <- ptr to attributes
	lea	si, tAttr

	clrwbf	ds:[si].TA_spacePad		; No space padding in graphics
	
	call	GrSetTextAttr			; Set the attributes
	.leave
	ret
SetGStateAttributesForGraphicDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFillLICLRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill the rectangle defined by LICL_rect.

CALLED BY:	Utility
PASS:		ss:bp	= LICL_vars
		di	= GState
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFillLICLRect	proc	near
	mov	ax,LICL_rect.R_left
	mov	bx,LICL_rect.R_top
	mov	cx,LICL_rect.R_right
	mov	dx,LICL_rect.R_bottom
	call	GrFillRect
	ret
DrawFillLICLRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FieldDrawStyleCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of characters in the next style run.

CALLED BY:	GrDrawTextField
PASS:		ss:bp	= GDF_vars
		bx:di	= TextAttr buffer to fill in
		si	= Offset into the field
		cx	= 0, if this is the first call.
RETURN:		Buffer pointed at by bx:di filled in
		cx	= Number of characters in this run
		ds:si	= Pointer to the text at offset si in the field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FieldDrawStyleCallback	proc	far
	uses	ax, dx, di
	.enter
	;
	; Check to see if we need to unlock the old text pointer
	;
	jcxz	firstCall

	push	si
	mov	ax, ss:[bp].GDFV_textPointer.segment ; ax <- text segment
	lds	si, ss:[bp].GDFV_other		; *ds:si = instance ptr.
	call	TS_UnlockTextPtr		; Release the old text
	pop	si
firstCall:

	;
	; Compute the offset into the text
	;
	clr	dx
	mov	ax, si				; dx.ax <- offset into the field
	adddw	dxax, ss:[bp].GDFV_textOffset	; dx.ax <- offset into field

	push	ax				; Save low word of offset
	lds	si, ss:[bp].GDFV_other		; *ds:si <- instance ptr.
	call	TS_LockTextPtr			; ds:si <- ptr to text
						; ax <- # after pointer
						; cx <- # before pointer
	mov	cx, ax				; cx <- # after pointer
	pop	ax				; Save low word of offset

	;
	; Fill in all the attributes
	;
	push	ax, cx, dx, ds, si		; Save offset, text ptr
	lds	si, ss:[bp].GDFV_other		; *ds:si <- instance ptr
	call	TA_FarFillTextAttrForDraw	; dx.ax <- # of chars

	mov_tr	cx, ax				; cx <- # of characters
	tst	dx				; if nChars <= 64K, then done
	jz	gotNumChars
	mov	cx, 0xffff			; else use 64K-1 chars
gotNumChars:
						; Carry set if has ext-style
	pop	ax, di, dx, ds, si		; Restore offset, text ptr

	;
	; cx	= # of characters in this style
	; di	= # of characters of text after offset
	;
	; We want to return the minimum of the number of characters in this
	; style and the number of characters in this hunk.
	;
	cmp	cx, di				; Branch if more total chars
	jbe	gotCount			;    than style
	mov	cx, di				; Else use total count
gotCount:
	.leave
	ret
FieldDrawStyleCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineClearBehind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the area behind a line of text.

CALLED BY:	SmallLineClearBehind, LargeLineClearBehind
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		al	= TextClearBehindFlags
		ss:bp	= LICL_vars structure with these set:
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
			    if paraAttr invalid
				LICL_paraAttrStart = -1

			   Also:
				LICL_region
				LICL_lineBottom
				LICL_lineHeight
RETURN:		Paragraph attributes set for this line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineClearBehind	proc	near
	uses	dx
	.enter
	clr	dx			; No suggestion for right edge
	call	CommonLineClearArea
	.leave
	ret
CommonLineClearBehind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineClearArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the area behind a line of text.

CALLED BY:	CommonLineClearBehind
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		dx	= Suggested left edge for the clear (0 if none)
		al	= TextClearBehindFlags
		ss:bp	= LICL_vars structure with these set:
				LICL_lineStart
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
			    if paraAttr invalid
				LICL_paraAttrStart = -1

			   Also:
				LICL_region
				LICL_lineBottom
				LICL_lineHeight
RETURN:		paragraph attributes set for this line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineClearArea	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di, si
	.enter
	movdw	ss:[bp].LICL_line, bxdi		; Save line

	push	ax, dx				; Save flags, line-end
	movdw	dxax, ss:[bp].LICL_lineStart	; dx.ax <- line start
	call	T_EnsureCorrectParaAttr		; Make sure ruler is up to date
	pop	ax, dx				; Restore flags, line-end

	call	GetBorderAndFlags		; Set the border and line flags
	call	TextDraw_DerefVis_DI		; ds:di <- instance ptr
	;
	; ss:bp	= LICL_vars with ruler, border-flags, and line-flags set
	; ax	= TextClearBehindFlags
	; ds:di	= Instance
	;
	call	ComputeLineBounds		; Fill in LICL_rect
	
	;
	; Use the suggested value for the left edge, if there is one.
	;
	tst	dx
	jz	gotRect
	;
	; if text is left-offset (scrolled single-line text),
	; we must account for it -- brianc 2/26/96
	;
	call	TextDraw_DerefVis_DI		; ds:di <- instance ptr
	add	dx, ds:[di].VTI_leftOffset
	mov	LICL_rect.R_left, dx
gotRect:

	;
	; Check for a line height of zero (ie: hidden)
	;
	mov	cx, LICL_rect.R_top
	cmp	cx, LICL_rect.R_bottom
	je	abort
	
;-----------------------------------------------------------------------------
;			   Background Wash
;-----------------------------------------------------------------------------
	;
	; if transparent and responding to a MSG_VIS_DRAW, skip wash color
	;
	test	al, mask TCBF_PRINT		; If printing we skip the wash
	jnz	afterBGWash
	
	;
	; If we are not responding to a draw then we are redrawing as a
	; result of a text change and we must wash.
	;
	test	al, mask TCBF_MSG_DRAW
	jz	forceBGWash

	test	ds:[di].VTI_features, mask VTF_TRANSPARENT
	jnz	afterBGWash

forceBGWash:
	;
	; Draw the entire line in the wash color.
	; Set the color and mask for the draw.
	;
	call	LineWashBackground		; Wash out the line
afterBGWash:

;-----------------------------------------------------------------------------
;			    Convert to line bounds
;-----------------------------------------------------------------------------
	;
	; Get the left and right bounds of the paragraph area
	;
	tst	dx				; Check for got left edge
	jnz	gotLeft				; Branch if we do have it
	mov	cx, LICL_paraAttr.VTPA_leftMargin
	cmp	cx, LICL_paraAttr.VTPA_paraMargin
	jbe	5$
	mov	cx, LICL_paraAttr.VTPA_paraMargin
5$:
	mov	LICL_rect.R_left, cx		; Save left
gotLeft:

	mov	cx,LICL_paraAttr.VTPA_rightMargin ;ax = right
	mov	LICL_rect.R_right, cx		; Save right

;-----------------------------------------------------------------------------
;			    Paragraph Wash
;-----------------------------------------------------------------------------
	;
	; Set up the paragraph color and color map mode.  If the wash color
	; and the paragraph background color are the same, we can skip this
	;
	mov	cl, LICL_paraAttr.VTPA_bgGrayScreen
	cmp	cl, SDM_0
	jz	afterParaWash

	movdw	bxcx, LICL_paraAttr.VTPA_bgColor
	cmpdw	bxcx, ds:[di].VTI_washColor
	je	afterParaWash

	call	LineWashParagraph
afterParaWash:

;-----------------------------------------------------------------------------
;			    Page and Column Break
;-----------------------------------------------------------------------------

	test	al, mask TCBF_PRINT
	pushf					; Save "is printing" flag
	;
	; Draw any of the following which might be on this line:
	; (Listed in the order they should be drawn)
	;	- Text-background color
	;	- Underlines
	;	- Boxed text
	;	- Button text
	;
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line
	call	TL_LineGetFlags			; ax <- LineFlags

	popf					; Restore "is printing" flag
	jnz	afterBreak			; Branch if printing

	;
	; Draw any section or column break.
	;
	call	DrawColumnOrSectionBreak
afterBreak:

;-----------------------------------------------------------------------------
;			    Extended Styles
;-----------------------------------------------------------------------------
	
	;
	; Check for the line containing any of these styles
	;
	test	ax, mask LF_CONTAINS_EXTENDED_STYLE
	jz	afterExtendedStyles		; Branch if no extended styles
	call	DrawAllExtendedStyles
afterExtendedStyles:


abort:
	.leave
	ret
CommonLineClearArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawColumnOrSectionBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is easy... draw a line from the right edge of the line
		to the right edge of the region.

CALLED BY:	CommonLineClearArea
PASS:		*ds:si	= Instance
		ax	= LineFlags
		ss:bp	= LICL_vars w/ these set:
				LICL_region
				LICL_rect.R_top/bottom set for the line
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawColumnOrSectionBreak	proc	near
	class	VisTextClass

	test	ax, mask LF_ENDS_IN_COLUMN_BREAK or mask LF_ENDS_IN_SECTION_BREAK
	jz	quit
	
	push	ax, bx, cx, dx, di

	push	ax
	mov	ax, ATTR_VIS_TEXT_DONT_DRAW_BREAKS
	call	ObjVarFindData
	pop	ax
	jc	noDraw
	
	push	ax				; Save line flags

	;
	; There's a break. Figure the edges...
	;
	mov	cx, ss:[bp].LICL_region		; cx <- region
	mov	dx, LICL_rect.R_top		; dx <- top
	mov	bx, LICL_rect.R_bottom		; bx <- height
	sub	bx, dx
	call	TR_RegionLeftRight		; ax <- left
						; bx <- right
	
	mov	LICL_rect.R_left, ax		; Set left/right
	mov	LICL_rect.R_right, bx
	
	mov	ax, LICL_rect.R_bottom		; Set top
	dec	ax
	mov	LICL_rect.R_top, ax
	
	;
	; Draw the break.
	;
	call	DrawDerefGState			; di <- gstate

	mov	ax, C_BLACK
	call	GrSetAreaColor

	pop	cx				; Restore LineFlags

	mov	al, SDM_100			; Assume section break
	test	cx, mask LF_ENDS_IN_SECTION_BREAK
	jnz	gotBreakMask
	mov	al, SDM_62_5
gotBreakMask:
	call	GrSetAreaMask
	
	call	DrawFillLICLRect

noDraw:
	pop	ax, bx, cx, dx, di
quit:
	ret
DrawColumnOrSectionBreak	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeLineBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the bounds of the line.

CALLED BY:	CommonLineClearArea
PASS:		*ds:si	= Instance
		ds:di	= Instance
		ss:bp	= LICL_vars
RETURN:		LICL_rect set to line bounds
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeLineBounds	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter
	;
	; Compute the line left/top
	;
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line
	call	TL_LineGetTop			; dx <- top
	mov	LICL_rect.R_top, dx		; Save top

	;
	; Compute the bottom
	;
	mov	bx, ss:[bp].LICL_line.high	; bx.di <- line
	call	TL_LineGetHeight		; dx.bl <- height
	ceilwbf	dxbl, dx			; dx <- height
	add	dx, LICL_rect.R_top		; dx <- bottom
	mov	LICL_rect.R_bottom, dx		; Save bottom
	
	;
	; Compute the region left/right bounds
	;
	mov	bx, ss:[bp].LICL_line.high	; bx.di <- line
	call	TR_RegionFromLine		; cx <- region
	
	mov	dx, LICL_rect.R_top		; dx <- y position
	mov	bx, LICL_rect.R_bottom		; bx <- height
	sub	bx, LICL_rect.R_top
	call	TR_RegionLeftRight		; ax <- left, bx <- right
	
	mov	LICL_rect.R_left, ax		; Save left/right bounds
	mov	LICL_rect.R_right, bx
	.leave
	ret
ComputeLineBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineWashBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wash out the area behind a line with the background color.

CALLED BY:	CommonLineClearArea
PASS:		*ds:si	= Instance
		ds:di	= Instance
		ss:bp	= LICL_vars with LICL_line set
		dx	= Zero to use left edge of region
			= Non-Zero for clear from dx->right edge
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineWashBackground	proc	near
	uses	ax, bx, cx

	;
	; No need to erase background if forced to draw by interact below.
	;
	test	ss:[bp].LICL_calcFlags, mask CF_FORCED_DRAW_VIA_INTERACT_BELOW
	jnz	exit

	.enter
	;
	; Draw the rectangle
	;
	mov	ax, LICL_rect.R_top		; ax <- top
	mov	bx, LICL_rect.R_bottom		; bx <- bottom

	;
	; When drawing multiple lines, don't erase bottom of previous line
	; unless we're the first line.
	;
	test	ss:[bp].LICL_calcFlags, mask CF_HAVE_DRAWN
	jz	10$

	inc	ax				; don't erase previous bottom
10$:
	inc	bx				; erase current bottom

						; dx = left edge to clear from
	mov	cx, ss:[bp].LICL_region		; cx <- segment
	call	TR_RegionClearSegments		; Clear the area
	.leave
exit:
	ret
LineWashBackground	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBorderAndFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get border info and line-flags.

CALLED BY:	CommonLineClearArea
PASS:		*ds:si	= Instance ptr
		bx.di	= line
		ss:bp	= LICL_vars with paraAttr filled in.
RETURN:		LICL_prevLineB* set
		LICL_nextLineB* set
		LICL_lineFlags set
		LICL_paraAttr still set for this line.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBorderAndFlags	proc	near
	uses	ax
	.enter
	;
	; if there is any border for this line, calculate border stuff
	;
	test	LICL_paraAttr.VTPA_borderFlags, mask VTPBF_LEFT \
					or mask VTPBF_TOP or \
					mask VTPBF_RIGHT or mask VTPBF_BOTTOM
	jz	noBorder
	call	GetPrevNextBorder
noBorder:
	
	;
	; Get the flags
	;
	call	TL_LineGetFlags			; ax <- flags
	mov	ss:[bp].LICL_lineFlags, ax	; Save flags
	.leave
	ret
GetBorderAndFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw all the text.

CALLED BY:	SmallLineDraw, LargeLineDraw
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Size of line/field data
		ss:bp	= CommonDrawParameters
		ax	= TextClearBehindFlags
RETURN:		nothing
DESTROYED:	The position to draw at is nuked

PSEUDO CODE/STRATEGY:
	   If the TCBF_PRINT bit is *clear* (not printing) then line is
	   marked as no longer needing to be drawn

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineDraw	proc	near
	uses	dx
	.enter
	clr	dx		; Draw it all
	call	CommonLineDrawLastNChars
	.leave
	ret
CommonLineDraw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineClearFromEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For now just clear the entire line.

CALLED BY:	SmallLineClearFromEnd, LargeLineClearFromEnd
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars w/ LICL_firstLine* set

			   Also:
				LICL_region
				LICL_lineBottom
				LICL_lineHeight
RETURN:		Paragraph attributes set for the first line
		LICL_lineStart set for first line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineClearFromEnd	proc	near
	uses	ax, bx, dx, di
	.enter
	;
	; Allocate and initialize the stack frame.
	;
	movdw	ss:[bp].LICL_lineStart, ss:[bp].LICL_firstLineStartOffset, ax
	movdw	LICL_paraAttrStart, -1		; Signal: no para-attr yet

	movdw	bxdi, ss:[bp].LICL_firstLine
	mov	dx, ss:[bp].LICL_firstLineEnd
	
	;
	; LICL_lineBottom needs to hold the bottom of the last line
	; 	which happens to be the top of this line.
	;
	; LICL_lineHeight needs to hold the line height
	;
	movwbf	ss:[bp].LICL_lineBottom, ss:[bp].LICL_firstLineTop, ax
	movwbf	ss:[bp].LICL_lineHeight, ss:[bp].LICL_firstLineHeight, ax

	;
	; Clear from the end.
	;
	clr	al				; No TextClearBehindFlags
	call	CommonLineClearArea		; Clear the space
	.leave
	ret
CommonLineClearFromEnd	endp

TextDrawCode	ends

TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDrawControlChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we are drawing control characters

CALLED BY:	CommonFieldDraw, DrawHiddenTabCharacter
PASS:		*ds:si	= Instance
RETURN:		carry set if we are drawing control characters
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDrawControlChars	proc	far
	class	VisTextClass
	uses	ax, di
	.enter
	call	DrawDerefGState			; di <- gstate
	
	call	GrGetTextMode			; al <- TextMode bits
	
	test	al, mask TM_DRAW_CONTROL_CHARS	; Check for drawing ctrl-chars
	jz	quit				; Branch if not (carry clear)
	stc					; Signal: we are
quit:
	.leave
	ret
CheckDrawControlChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDerefGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the gstate for a text object.

CALLED BY:	Utility
PASS:		*ds:si	= Instance
RETURN:		di	= GState
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDerefGState	proc	far
	class	VisTextClass

	mov	di, ds:[si]			; di <- gstate handle
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate
	ret
DrawDerefGState	endp

TextFixed	ends

if SIMPLE_RTL_SUPPORT
TextDrawCode	segment	resource

RTLDrawTextField	proc	far
	uses	bp, ax
	.enter	inherit	CommonFieldDraw
	mov	ax, TD_RIGHT_TO_LEFT
	call	GrSetTextDirection

	; Flip the drawing position
	mov	ax, gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int
	neg	ax
	add	ax, params.CDP_flip
	mov	gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int, ax

	push	bp
	lea	bp, gdfVars			; ss:bp <- GDF_vars
	call	GrDrawTextField
	pop	bp

	mov	ax, TD_LEFT_TO_RIGHT
	call	GrSetTextDirection

	; Flip the final drawing position
	mov	ax, gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int
	neg	ax
	add	ax, params.CDP_flip
	mov	gdfVars.GDFV_saved.GDFS_drawPos.PWBF_x.WBF_int, ax
	.leave
	ret
RTLDrawTextField	endp


TextDrawCode	ends
endif
