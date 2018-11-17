COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonPosition.asm

AUTHOR:		John Wedgwood, Jan  3, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 3/92	Initial revision

DESCRIPTION:
	Common position related code.

	$Id: tlCommonPosition.asm,v 1.1 97/04/07 11:20:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineTextPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a text offset into a line and a pixel offset, compute
		the nearest possible valid position where the event at the
		pixel position could occur, not to exceed the passed offset.

CALLED BY:	SmallLineTextPosition, LargeLineTextPosition
PASS:		*ds:si	= Instance ptr
		es:di	= Line/field data
		cx	= Size of line/field data
		dx.ax	= Offset to line start
		bx	= Pixel offset to find
		On stack:
			Offset to stop calculating at
RETURN:		dx.ax	= Nearest character offset
		bx	= Pixel offset from left edge of the line
		carry set if the position is not right over the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (position <= line.adjustment) ||
	   (stopOffset <= line.start) {
	    /* Position falls before start of line */
	    return(line.start, line.adjustment, notOver)
	}
	
	/* Position falls after start of line */
	position   -= line.adjustment
	oldFieldEnd = line.adjustment
	curOffset   = line.start

    fieldLoop:
	if (no more fields) {
	    if (line.flags & (LF_ENDS_IN_CR | 
	    		      LF_ENDS_IN_COLUMN_BREAK |
			      LF_ENDS_IN_SECTION_BREAK)) {
	        return(curOffset-1, oldFieldEnd, notOver)
	    } else {
	        return(curOffset, oldFieldEnd, notOver)
	    }
	}
	
	if (position < field.position) {
	    /* Position is between this field and the previous one */
	    if (position-oldFieldEnd < field.position-position) {
		/* Closer to previous field */
		return(curOffset-1, oldFieldEnd, isOver)
	    } else {
	        /* Closer to current field */
		return(curOffset, field.position, isOver)
	    }
	}
	
	curOffset += field.nChars
	oldFieldEnd = field.position + field.width
	
	if (position < oldFieldEnd) ||
	   (curOffset >= stopOffset) {
	    /* Position is in this field */
	    return(FieldTextPosition(...), isOver)
	}
	
	field += sizeof(FieldInfo)
	goto fieldLoop

USAGE:	*ds:si	= Instance ptr
	es:di	= Field pointer
	cx	= Pointer to end of field data
	bx	= Pixel offset to find
	ax, dx	= Scratch
	Stack frame containing:
		stopOffset
		oldFieldEnd
		lineFlags
		spacePadding
		curOffset
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineTextPosition	proc	far	stopOffset:dword
	uses	cx, bp, di
curOffset	local	dword		push	dx, ax
adjustment	local	sword
oldFieldEnd	local	sword
lineFlags	local	LineFlags
spacePadding	local	dword
isOverLine	local	byte
	.enter
	;
	; Initialize the stack frame...
	;
	CommonLineGetAdjustment			; ax <- Adjustment amount
	mov	adjustment, ax			; Save it as field end
	
	call	CommonLineGetFlags		; ax <- LineFlags
	mov	lineFlags, ax			; Save the line flags
	
	CommonLineGetSpacePadding		; dx.ax <- Space padding
	movdw	spacePadding, dxax		; Save space padding
	
	add	cx, di				; cx <- ptr past line/field data
	
	clr	oldFieldEnd			; Initialize old field end

	;
	; Check for the case of the pixel offset falling before the first field
	;
	clr	isOverLine			; Assume position not over line

	cmp	bx, oldFieldEnd
	jle	returnFieldEnd
	
	mov	isOverLine, 1			; Assume position is over line

	;
	; Check for the case of the offset falling before the line
	;
	cmpdw	stopOffset, curOffset, ax
	jbe	returnFieldEnd

	;
	; The position is not before the start of the field.
	;
	lea	di, es:[di].LI_firstField	; es:di <- current field
;-----------------------------------------------------------------------------
fieldLoop:
	;
	; *ds:si= Instance ptr
	; es:di	= Pointer to current field
	; cx	= Pointer past end of field data
	; bx	= Pixel position as offset from start of current field
	; oldFieldEnd = End of previous field
	; lineFlags   = Set for the current line
	; stopOffset  = Offset to stop computing at
	; curOffset   = Offset to start of current field
	;
	cmp	di, cx				; Check for end of fields
	je	calcFieldEnd			; Branch if no more fields
	
	;
	; Check for the position/offset falling between this field and the
	; previous one.
	;
	call	CommonFieldGetPosition		; ax <- position of field
	cmp	bx, ax				; Check for position between
	jb	betweenFields			; Branch if before field start

	;
	; It's somewhere after the start of the current field.
	;
	; Update the current offset to be after the end of this field.
	; Update the previous field end to be at the end of this field.
	;
	; We update these things even though we haven't really finished with
	; the current field. We do it because the new values are useful to 
	; have around and the old ones are of no use anymore.
	;
	; es:di	= Pointer to current field
	; ax	= Position of current field
	;
	mov	dx, ax				; dx <- current field position
	call	CommonFieldGetWidth		; ax <- width of field
	add	dx, ax				; dx <- position after field
	mov	oldFieldEnd, dx			; Save end of previous field

	push	ax				; Save field width
	call	CommonFieldGetNChars		; ax <- # of characters
	clr	dx
	adddw	curOffset, dxax			; Update the current offset
	pop	dx				; Restore field width (dx)
	
	;
	; Check for the position falling inside the current field.
	;
	cmp	bx, oldFieldEnd			; Check for inside this field
	jbe	inThisField

	push	ax				; Save # chars in field
	cmpdw	curOffset, stopOffset, ax	; Check for inside this field
	pop	ax				; Restore # chars in field
	jae	inThisField

	;
	; It's not in this field, it's somewhere later...
	;
	add	di, size FieldInfo		; es:di <- next field
	jmp	fieldLoop			; Loop to do next field
;-----------------------------------------------------------------------------

quit:
	;
	; dx.ax	= Offset into text to return
	; cx	= Pixel offset to return
	;
	mov	bx, cx				; Return offset in bx
	
	tst	isOverLine			; Clears the carry
	jnz	10$				; Branch if is over line
	stc
10$:
	.leave
	ret	@ArgSize


;-----------------------------------------------------------------------------
calcFieldEnd:
	;
	; The position is at the very end of the line. The problem here
	; is if the line ends in a <cr> then the position that we have
	; calculated as (field.pos + field.width) isn't useful because the
	; width includes space for the invisible <cr> character at the end
	;
	; The best thing we can do in this case is just force calculation
	; of the position.
	;
	clr	isOverLine			; Position is not over line

	test	lineFlags, mask LF_ENDS_IN_CR	; Check for ends in <cr>
	jz	returnFieldEnd			; Branch if it doesn't
	
	;
	; The special case outlined above is what we need to handle.
	; We need:
	;  Already set:
	;	*ds:si	= Instance ptr
	;	bx	= Pixel offset to find
	;	stopOffset = Offset to find
	;	curOffset  = Offset past end of the current field
	;
	;	es:di	= Last field
	;	ax	= Number of characters in the field
	;	dx	= Width of the current field
	;
	sub	di, size FieldInfo		; es:di <- last field

	call	CommonFieldGetWidth		; ax <- width of field
	mov	dx, ax				; dx <- width of field

	call	CommonFieldGetNChars		; ax <- # of characters

	jmp	inThisField			; Branch to compute position


;-----------------------------------------------------------------------------
returnFieldEnd:
	;
	; We want to return the end of the field unless:
	;	1) There are no more fields on the line
	;	2) The line ends in a CR or BREAK
	; If these are both true we return the character before the end
	;
	; es:di	= Pointer to current field
	; cx	= Pointer past end of line/field data
	; curOffset   = Offset to return (possibly end of line)
	; oldFieldEnd = Pixel offset to return
	;	
	cmp	di, cx				; Check for after last field
	jb	gotValues
	
	;
	; We want to check for the CR or BREAK...
	;
	test	lineFlags, mask LF_ENDS_IN_CR or \
			   mask LF_ENDS_IN_COLUMN_BREAK or \
			   mask LF_ENDS_IN_SECTION_BREAK
	jz	gotValues

	decdw	curOffset			; Use previous character

gotValues:
	movdw	dxax, curOffset			; dx.ax <- offset to return
	mov	cx, oldFieldEnd			; cx <- pixel offset
	jmp	quit


;-----------------------------------------------------------------------------
betweenFields:
	;
	; The position falls in that gap between fields (where the TAB is).
	; We need to figure out if the offset falls closer to the end of
	; the previous field or the start of the current one.
	;
	; es:di	= Pointer to current field
	; bx	= Position to find
	; ax	= Position of current field
	;
	mov	dx, bx				; dx <- distance to prev field
	sub	dx, oldFieldEnd

	sub	ax, bx				; ax <- distance to current
	
	cmp	dx, ax				; Find which is closer
	jbe	gotValues			; Branch if previous is closer

	;
	; We want to return the start of the current field.
	;
	add	ax, bx				; ax <- current field position
	mov	cx, ax				; cx <- position to return
	
	movdw	dxax, curOffset			; dx.ax <- offset to return
	incdw	dxax
	jmp	quit


;-----------------------------------------------------------------------------
inThisField:
	;
	; The position is somewhere in the current field.
	;
	; *ds:si= Instance ptr
	; es:di	= Pointer to current field
	; cx	= Pointer past last field
	;
	; Figure out the space-padding to use when we call 
	; CommonFieldTextPosition(). If this is the last field then we use
	; whatever is in spacePadding. Otherwise we use zero.
	;
	sub	cx, size FieldInfo		; cx <- ptr to last field
	cmp	cx, di				; Check for on last field
	je	gotSpacePadding
	
	;
	; It's not the last field. Set the space-padding to zero.
	;
	clrdw	spacePadding
gotSpacePadding:
	
	;
	; spacePadding = Space-padding to use for this field
	; stopOffset   = Offset to find
	; bx	       = Pixel offset to find
	;
	; curOffset    = Offset past the end of the field
	; ax	       = Number of characters in the field
	; dx	       = Width of the current field
	;
	; We convert the offset and pixel-offset so that they are relative to
	; the current field and then we work from there.
	;
	sub	curOffset.low, ax		; curOffset <- start of field
	sbb	curOffset.high, 0

	mov	ax, oldFieldEnd			; ax <- field start
	sub	ax, dx
	
	;
	; We need to pass some stuff on the stack to CommonFieldTextPosition:
	;	Space padding
	;	Pixel offset
	;	Max number of chars to check
	;	Offset to field start
	;
	; ax	= Start of field (pixel offset)
	; curOffset = Start of field (text offset)
	;
	push	ax				; Save start of field

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Changed,  3/29/93 -jw
; Lies all lies, if the field starts with a tab we won't know. In the case
; just called to my attention, a field starting with a <tab> where the tabstop
; is a right-justified one, and where the field is too wide for the space,
; will have a starting position of zero.
;
;	;
;	; Check for the field starting with a tab. If it does then it will
;	; have a pixel offset that is non-zero.
;	;
;	tst	ax				; Check for starts with tab
;
; We need a better check for the field containing a TAB. We use the
; comparison you see here in the hyphenation code to detect if a field starts
; with a hyphen. This value denotes that the field is flush with the left
; edge of the line.
;
	cmp	es:[di].FI_tab, RULER_TAB_TO_LINE_LEFT
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	jz	noTabStart			; Branch if it doesn't

	;
	; The field does start with a tab. We need to increment the 
	; text offset.
	;
	incdw	curOffset			; Advance current offset

 noTabStart:

	sub	bx, ax				; bx <- pixel offset into field
	mov	dx, bx				; dx <- pixel offset into field

	movdw	cxbx, stopOffset		; cx.bx <- place to stop
	subdw	cxbx, curOffset			; cx.bx <- offset into field

	;
	; Start pushing parameters...
	;
	pushdw	curOffset			; Pass start of field
	pushdw	cxbx				; Pass max # of chars to use
	push	dx				; Pass pixel offset
	pushdw	spacePadding			; Pass space padding

	;
	; *ds:si= Instance
	; es:di	= Field
	; On stack:
	;	(dword) Space padding
	;	 (word) Pixel offset to start of field
	;	(dword) Max # of chars to check
	;	(dword) Start of field
	;
	call	CommonFieldTextPosition		; ax <- offset into field
						; cx <- pixel offset into field
	pop	dx				; Restore field start, frame
	
	;
	; dx	= Pixel offset to start of field
	; ax	= Text offset into field where position was found
	; curOffset = Text offset to start of field
	;
	add	cx, dx				; cx <- pixel offset into line
	
	add	ax, curOffset.low		; dx.ax <- text offset into line
	mov	dx, curOffset.high
	adc	dx, 0
	jmp	quit
	
CommonLineTextPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonFieldTextPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the offset

CALLED BY:	CommonLineTextPosition
PASS:		*ds:si	= Instance ptr
		es:di	= field 
		On stack (pushed in this order):
			(dword) Offset to the start of the field
				   after the TAB if a TAB is the first char
			(dword) Max number of chars to use
			 (word) Pixel offset to find
			(dword) Space-Padding for the field
RETURN:		ax	= Text offset into the field
		cx	= Pixel offset into the field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonFieldTextPosition	proc	far	\
					spacePadding:dword,
					pixelOffset:word,
					maxChars:dword,
					fieldStart:dword
	uses	bx, dx, di, bp
gtpVars		local	GTP_vars
	.enter
	;
	; Initialize the kernel routines stack frame
	;
	movdw	gtpVars.GTPL_object, dssi
	movdw	gtpVars.GTPL_style.TMS_fieldStart, fieldStart, ax
	
	movcb	gtpVars.GTPL_style.TMS_styleCallBack, \
					FieldTextPositionCharAttrCallback
	movcb	gtpVars.GTPL_style.TMS_graphicCallBack, \
					FieldTextPositionGraphicCallback

	movdw	dxbx, spacePadding		; dx.bx <- space padding
	call	CommonFieldSetupGState		; di <- gstate to use

	mov	cx, maxChars.low		; cx <- # chars to check
	mov	dx, pixelOffset			; dx <- pixel offset

	jcxz	noCharacters			; Branch if no characters

	push	bp, ds				; Save frame ptr, instance
	lea	bp, gtpVars			; ss:bp <- frame for kernel
	;
	; cx	= # of characters to check
	; dx	= Pixel offset into the field
	; di	= GState to use
	; ss:bp	= GTP_vars structure
	;
	call	GrTextPosition			; cx <- nearest valid char
						; dx <- nearest valid position
						; ds <- last text segment
	mov	ax, ds				; ax <- segment of last text
	pop	bp, ds				; Restore frame ptr, instance
	
	call	TS_UnlockTextPtr		; Release the old text

returnValues:
	mov	ax, cx				; Return offset in ax
	mov	cx, dx				; Return pixel offset in cx
	.leave
	ret	@ArgSize

noCharacters:
	clr	dx				; dx <- offset
	jmp	returnValues
CommonFieldTextPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FieldTextPositionCharAttrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Character attribute callback routine for text position.

CALLED BY:	GrTextPosition
PASS:		ss:bp	= pointer to GTP_vars structure on stack
		ds	= Segment address of old text pointer
		di	= Offset from field start
RETURN:		TMS_textAttr filled in
		ds:si	= Pointer to the text
		cx	= # of valid characters
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FieldTextPositionCharAttrCallback	proc	far
	uses	ax, bx, dx, bp
	.enter
	;
	; Check to see if we need to unlock the old text pointer
	;
	mov	ax, ds				; ax <- text segment
	lds	si, ss:[bp].GTPL_object		; *ds:si = instance ptr.
	
	tst	di				; Branch if this is the first
	jz	firstCall			;   callback
	call	TS_UnlockTextPtr		; Release the old text
firstCall:

	;
	; Compute the offset into the text object
	;
	clr	dx				; dx.ax <- offset into field
	mov	ax, di
	adddw	dxax, ss:[bp].TMS_fieldStart	; dx.ax <- offset into object

	;
	; Get a pointer to the text
	;
	push	ax				; Save low word of offset
	call	TS_LockTextPtr			; ds:si <- ptr to the text
						; ax <- # of characters
	mov	cx, ax				; cx <- # of characters
	pop	ax				; Restore low word of offset

	;
	; ds:si	= Pointer to text
	; cx	= Number of characters after ds:si
	; ss:bp	= TMS_xxx
	;
	; Fill in all the attributes, we need:
	;	*ds:si	= Instance
	;	bx:di	= Pointer to TextAttr structure
	;	dx.ax	= Offset into text (already set)
	;
	push	cx, di, ds, si			; Save:	Num chars after ds:si
						;	Offset to start of run
						;	Pointer to text
	lds	si, ss:[bp].GTPL_object		; *ds:si <- text instance
	mov	bx, ss				; bx:di <- ptr to attributes
	lea	di, ss:[bp].TMS_textAttr

	call	TA_FarFillTextAttrForDraw	; dx.ax <- # of chars

	mov_tr	cx, ax				; cx <- # of characters
	tst	dx				; if nChars <= 64K, then done
	jz	gotNumChars
	mov	cx, 0xffff			; else use 64K-1 chars
gotNumChars:
						; Carry set if has ext-style
	pop	bp, di, ds, si			; Rstr:	Num chars after ds:si
						;	Offset to start of run
						;	Pointer to text
	;
	; ds:si	= Pointer to text
	; cx	= Number of characters in this style
	; bp	= # of characters after the text pointer
	;
	; We want to return the minimum of the number of characters in this
	; style and the number of characters in this hunk.
	;
	cmp	cx, bp				; Branch if more total chars
	jbe	gotCount			;    than style
	mov	cx, bp				; Else use total count
gotCount:
	.leave
	ret
FieldTextPositionCharAttrCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FieldTextPositionGraphicCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Graphic callback routine.

CALLED BY:	GrTextPosition
PASS:		ss:bp	= pointer to GTP_vars structure on stack
		ds:si	= pointer into text after C_GRAPHIC
RETURN:		cx	= height of the graphic
		dx	= width of the graphic
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FieldTextPositionGraphicCallback	proc	far
	uses	ax, si, ds
	.enter
	lds	si, ss:[bp].GTPL_object		; *ds:si = instance ptr.

	clr	dx
	mov	ax, ss:[bp].GTPL_charCount	; dx.ax <- offset into the text
	adddw	dxax, ss:[bp].TMS_fieldStart	; dx.ax <- offset into object
	decdw	dxax				; Move before graphic

	call	TG_GraphicRunSize		; cx <- width, dx <- height.
	xchg	cx, dx				; Need them exchanged.
	.leave
	ret
FieldTextPositionGraphicCallback	endp


TextFixed	ends
