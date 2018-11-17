COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textMethodGeometry.asm

AUTHOR:		John Wedgwood, Oct 25, 1989

METHODS:
	Name			Description
	----			-----------
	MSG_VIS_TEXT_GET_MIN_WIDTH
	MSG_VIS_TEXT_CALC_HEIGHT
	MSG_VIS_TEXT_GET_LINE_HEIGHT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/25/89		Initial revision

DESCRIPTION:


	$Id: textMethodGeometry.asm,v 1.1 97/04/07 11:18:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextInstance segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetLineHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Temporary routine to make openlook work at least a bit.

CALLED BY:	Specific ui.
PASS:		*ds:si	= instance ptr.
RETURN:		ax	= height of a line in the font/charAttr of the first
			  character of the text.
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetLineHeight	method	VisTextClass, MSG_VIS_TEXT_GET_LINE_HEIGHT

	; We are going to be *so* tricky here and just use GrCreateState
	; if no cached gstate exists

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
EC <	test	ds:[bx].VTI_state, mask VTS_ONE_LINE			>
EC <	WARNING_Z	VIS_TEXT_GET_LINE_HEIGHT_CALLED_ON_MULTI_LINE_OBJECT>
	mov	di, ds:[bx].VTI_gstate
	tst	di
	pushf
	jnz	gotGState
	call	GrCreateState
	mov	ds:[bx].VTI_gstate, di
gotGState:

	;
	; Set up the gstate with the character attributes
	;
	clrdw	dxax			; dx.ax <- offset into text.
	call	TA_CharAttrRunSetupGStateForCalc

	;
	; Get the font height
	;
	push	si
	mov	si, GFMI_MAX_ADJUSTED_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics		;dx -> font height
	mov	ax, dx
	pop	si

	popf
	jnz	done
	call	GrDestroyState
	mov	ds:[bx].VTI_gstate, 0
done:

	ret
VisTextGetLineHeight	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetMinWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the minimum width that can be supported for the
		current text font and charAttr.

CALLED BY:	External.
PASS:		ds:*si = pointer to instance.
		ax     = MSG_VIS_TEXT_GET_MIN_WIDTH
		es     = segment containing VisTextClass.
RETURN:		cx     = minimum width.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetMinWidth	method dynamic	VisTextClass, MSG_VIS_TEXT_GET_MIN_WIDTH

	call	TextGStateCreate

	;
	; Set the gstate up with the first set of character attributes
	;
	clrdw	dxax				; dx.ax <- offset into text
	call	TA_CharAttrRunSetupGStateForCalc ; di <- gstate


	;
	; We need to be able to hold at least one character in the font.
	;
	push	si
	mov	si, GFMI_MAX_WIDTH or GFMI_ROUNDED
	call	GrFontMetrics			; dx <- max width
	pop	si

	;
	; Make sure that the width returned is at least the minimum
	;
	cmp	dx, VIS_TEXT_MIN_TEXT_FIELD_WIDTH
	jae	10$
	mov	dx, VIS_TEXT_MIN_TEXT_FIELD_WIDTH
10$:

	;
	; adjust for borders
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	cx
	mov	cl, ds:[di].VTI_lrMargin
	shl	cx
	add	cx,dx				; cx <- width with borders

	;
	; Nuke the gstate
	;
	call	TextGStateDestroy

	ret

VisTextGetMinWidth	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSimpleMinWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the minimum width that can be supported for the
		current text font and charAttr.  Can be used for text objects
		where you're not concerned about large borders and stuff
		like that.

		Will be combined with VisTextGetMinWidth for V2.0; I just
		want to keep things compatible in V1.1.  -cbh

CALLED BY:	External.
PASS:		ds:*si = pointer to instance.
		ax     = MSG_VIS_TEXT_GET_MIN_WIDTH
		es     = segment containing VisTextClass.
RETURN:		cx     = minimum width.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/15/89		Initial version
	cbh	12/ 6/90	Simple (no borders) version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; NOTE: This message is obscure and is *not* normally used in
	;	geometry calculations

VisTextGetSimpleMinWidth	method dynamic	VisTextClass,
				MSG_VIS_TEXT_GET_SIMPLE_MIN_WIDTH

	call	TextGStateCreate

	;
	; Set up the gstate with the first set of character attributes
	;
	clrdw	dxax				; dx.ax <- offset into the text
	call	TA_CharAttrRunSetupGStateForCalc ; di <- gstate


	;
	; We need to be able to hold one of the largest character in the font.
	;
	push	si
	mov	si, GFMI_MAX_WIDTH or GFMI_ROUNDED
	call	GrFontMetrics			; dx <- max width
	pop	si

	;
	; adjust for borders
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	cx
	mov	cl, ds:[di].VTI_lrMargin
	shl	cx
	add	cx,dx				;cx <- width with borders

	;
	; Nuke the gstate
	;
	call	TextGStateDestroy

	ret

VisTextGetSimpleMinWidth	endm

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextGetAverageCharWidth --
		MSG_VIS_TEXT_GET_AVERAGE_CHAR_WIDTH for VisTextClass

DESCRIPTION:	Return the average character width

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - average character width
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@
VisTextGetAverageCharWidth	method	VisTextClass, \
				MSG_VIS_TEXT_GET_AVERAGE_CHAR_WIDTH
	call	TextGStateCreate

	clrdw	dxax
	call	TA_CharAttrRunSetupGStateForCalc

	push	si
	mov	si, GFMI_AVERAGE_WIDTH or GFMI_ROUNDED
	call	GrFontMetrics
	mov	cx, dx
	pop	si

	call	TextGStateDestroy
	ret

VisTextGetAverageCharWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextCalcHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the height the text would be if the width were
		changed.

		This routine is intended for small text objects only.

CALLED BY:	External.
PASS:		*ds:si	= Instance ptr
		cx	= Width to calculate for
		dx	= Non-zero if the result of this calculation should be
			  cached. (This really should only be done by the
			  geometry handling code in the specific UI).

			  Basically, if you don't want to affect the object as
			  it exists when this method is invoked, you want dx=0.

RETURN:		dx     = height of text given the width passed in cx
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We pass to TL_CommonLineCalculate a pointer to a line w/ 2 fields.
	When it asks us to add a field, we shift field2 down into the
	LI_firstField and return again.
	
	This simulates adding fields to a line without actually doing it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/15/89		Initial version
	cbh	10/12/92	Changed to not use dumb calculations for
				single line objects with attr runs.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextCalcHeight	method dynamic	VisTextClass, MSG_VIS_TEXT_CALC_HEIGHT

	mov	bx, di
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di
	mov	di, bx

liclVars	local	LICL_vars
line		local	2 dup (LineInfo)
passedWidth	local	word
passedHeight	local	word
	.enter

	;
	; Check to see if the width we were passed is the same as the cached
	; width.
	;
	ceilwbf	ds:[di].VTI_height, bx		; bx <- last computed height
	mov	ax, ds:[di].VTI_lastWidth	; ax <- width for cached height

	cmp	cx, ax				; Check for same width
	LONG je	done				; Branch if same as cached

	;
	; The object has it's right margin defined by its visual bounds, we
	; must calculate.
	;
	mov	passedWidth, cx
	mov	passedHeight, dx
	push	ds:[di].VI_bounds.R_right	; Save old right edge

	;
	; Check for a simple one line object (no attr runs).  
	;
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	notOneLine

	mov	cx, MAX_COORD			; pass a large width if we`re
						; goint to do complicated 
						; calcs for one-liners
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS or \
					  mask VTSF_MULTIPLE_PARA_ATTRS
	jnz	notOneLine

	call	VisTextGetLineHeight		; dx <- height
	clr	bx
	jmp	common

notOneLine:
	;
	; The text object is not a one-line object. We need to do the complex
	; calculation. First we set the new right edge to the width passed
	; plus the current left edge.
	;
	add	cx, ds:[di].VI_bounds.R_left	; cx <- new right edge
	mov	ds:[di].VI_bounds.R_right, cx	; Save new right edge

	call	TextGStateCreate		; Make me a gstate

	;
	; Initialize the stack frame which we will need for calculation.
	;
	push	bp				; Save frame ptr
	segmov	es, ss, di			; es:di <- ptr to the line
	lea	di, line
						; cx <- size of line/field data
	mov	cx, size LineInfo + size FieldInfo

	lea	bp, liclVars			; ss:bp <- LICL_vars
	call	CalcHeightInitLICLVars

	clrwbf	dxbh				; dx.bh <- sum of line heights
	mov	ax, mask LF_ENDS_PARAGRAPH	; Flags for previous line
	
;-----------------------------------------------------------------------------
lineLoop:
	;
	; *ds:si= Instance ptr
	; ss:bp	= LICL_vars
	; es:di	= Pointer to the line
	; cx	= Size of line/field data
	; ax	= LineFlags for last line
	; dx.bh	= Sum of the line heights
	;
	; If previous line ended a paragraph
	;    Current line starts a paragraph
	; Else
	;    Current line has no flags of interest
	;
	clrwbf	es:[di].LI_hgt			; Set height and baseline to 0
	clrwbf	es:[di].LI_blo			;   before calculating

	test	ax, mask LF_ENDS_PARAGRAPH	; Check for prev ends paragraph
	jz	lastWasNotParaEnd		; Branch if it doesn't

	mov	ax, mask LF_STARTS_PARAGRAPH	; Is paragraph start
	jmp	gotLineFlags

lastWasNotParaEnd:
	clr	ax				; ax <- LineFlags to pass

gotLineFlags:
	
	;
	; Set up the ruler.
	;
	push	ax, dx				; Save LineFlags, hgt.high
	movdw	dxax, ss:[bp].LICL_range.VTR_start
	;
	; Since it's for small objects only, we can just use all zero's as the
	; values for region, yPos, lineHeight.
	;
	clr	ss:[bp].LICL_region
	clrwbf	ss:[bp].LICL_lineBottom
	clrwbf	ss:[bp].LICL_lineHeight

	call	T_EnsureCorrectParaAttr		; Force ruler to be up to date
	pop	ax, dx				; Restore LineFlags, hgt.high

	call	TL_CommonLineCalculate		; Sets line height
	addwbf	dxbh, es:[di].LI_hgt		; Update the height so far

	mov	ax, LICL_paraAttr.VTPA_borderFlags
	mov	LICL_prevLineBorder, ax

	incdw	ss:[bp].LICL_line		; Move to next line

	mov	ax, es:[di].LI_flags		; ax <- line flags
	test	ax, mask LF_ENDS_IN_NULL	; Check for done w/ object
	jz	lineLoop			; Loop if we're not
;-----------------------------------------------------------------------------

	pop	bp				; Restore frame ptr

	call	TextGStateDestroy		; Nuke gstate, we don't need it
	
	;
	; Hack to make one-liners come out right.  They seem to be off
	; by a pixel for some reason.  - cbh 10/12/92
	;
	call	TextInstance_DerefVis_DI	; ds:di <- instance ptr
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	common
	inc	dx

common:
	;
	; Store result
	; *ds:si= Instance ptr
	; dx.bh = height of object
	; On stack:
	;	Old right edge of object
	;	Passed width and flag
	;
	call	TextInstance_DerefVis_DI	; ds:di <- instance ptr
	
	;
	pop	ds:[di].VI_bounds.R_right	; Restore old right edge
	mov	cx, passedWidth
	tst	passedHeight			; Check to see if we want to
	jz	noSaveHeight			;    save the width/height
	;
	; If there are any lines then we biff them since we're stomping
	; on the height
	;
	; ... and we do the above for a good reason, that being that having
	; line structures that reflect one height and having a different
	; height stored is a bad thing.  (what we *really* want is some
	; "notiify geometry changing" message on which we would biff the
	; lines, but this does not exist so we do so here).
	;
	; the problem is that the height might not be changing, and if the
	; height does not change, we will not get a notigyGeometryValid
	; message and thus end up without line structures (a really bad
	; thing).
	;
	; our solution is to check to see if the height is changing and only
	; biff the line structures if it is.  this seems a bit chancy, but
	; seems to fix the bug of the moment (resizing desktop windows)

	cmpwbf	ds:[di].VTI_height, dxbh
	jz	afterBiffLines
	call	TL_LineStorageDestroy
afterBiffLines:

	call	TextInstance_DerefVis_DI
	mov	ds:[di].VTI_lastWidth, cx	; Save new width
	movwbf	ds:[di].VTI_height, dxbh	; Save height
noSaveHeight:
	ceilwbf	dxbh, cx			; bx <- integer size
	mov	bx, cx

	mov	cx, passedWidth
done:
	;
	; bx = height, not counting margins.
	; On stack:
	;
	clr	dx				; dx <- top/bottom margin
	mov	dl, ds:[di].VTI_tbMargin
	shl	dx, 1				; dx <- total vertical margin
	
	add	dx, bx				; Add in space for margin

	.leave
	pop	di
	call	ThreadReturnStackSpace
	ret
VisTextCalcHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcHeightInitLICLVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the LICL_vars for VisTextCalcHeight

CALLED BY:	VisTextCalcHeight
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcHeightInitLICLVars	proc	near
	uses	ax
	.enter
	;
	; In the EC code we start by setting everything to some hopefully bogus
	; value.
	;
EC <	push	ax, cx, di, es 						>
EC <	segmov	es, ss, di						>
EC <	mov	di, bp			; es:di <- ptr to dest		>
EC <	mov	al, 0xff		; al <- byte to store 		>
EC <	mov	cx, size LICL_vars	; cx <- # bytes to store	>
EC <	rep	stosb			; nuke me jesus			>
EC <	pop	ax, cx, di, es 						>
	
	;
	; First initialize the fields that we have space for...
	;
	movdw	LICL_paraAttrStart,-1		; ParaAttr aren't set
	mov	ss:[bp].LICL_calcFlags, 0	; Don't save results

	clr	ax
	mov	LICL_prevLineBorder, ax		; Initial border state
	clrdwf	ss:[bp].LICL_insertedSpace, ax
	clrdw	ss:[bp].LICL_line

	;
	; Set the start/end of the range.
	;
	clrdw	ss:[bp].LICL_range.VTR_start, ax
	call	TS_GetTextSize
	movdw	ss:[bp].LICL_range.VTR_end, dxax

	movcbx	ss:[bp].LICL_addFieldCallback, CalcHeightAddField
	movcbx	ss:[bp].LICL_truncateFieldsCallback, CalcHeightTruncateFields
	movcbx	ss:[bp].LICL_dirtyLineCallback, CalcHeightDirtyLine
	
	.leave
	ret
CalcHeightInitLICLVars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcHeightAddField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a field to a line... Well, not really.

CALLED BY:	TL_CommonLineCalculate
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		es:di	= Line
		cx	= Pointer past line/field data
		es:dx	= Field we want
RETURN:		es:di	= Line
		cx	= Pointer past line/field data
		es:dx	= Field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We don't actually add fields. Instead we shift 'field2' down
	over LI_firstField.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcHeightAddField	proc	far
	uses	cx, di, si, ds
	.enter
	lea	di, es:[di].LI_firstField	; es:di <- destination

	segmov	ds, es, si			; ds:si <- source
	lea	si, es:[di + size FieldInfo]

;;; Added 5/11/95 -jw
	mov	dx, si				; es:dx <- 2nd field
;;;
	mov	cx, size FieldInfo		; cx <- # of bytes to move
	
	rep	movsb				; Shift field2 into LI_firstField
	
	;
	; si	= Pointer past LI_firstField.
	;	  This is the position we want to return as the new field.
	;
;;;	mov	dx, si				; es:dx <- new field
;;; Removed 5/11/95 -jw   The right value is now set earlier in the code.
;;;			  This is the *wrong* value to use since 'si' has
;;;			  is now pointing past the field.
	.leave
	ret
CalcHeightAddField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcHeightTruncateFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Truncate fields at the end of a line... NOT

CALLED BY:	TL_CommonLineCalculate via LICL_truncateFieldsCallback
PASS:		xxx
RETURN:		xxx
DESTROYED:	xxx

PSEUDO CODE/STRATEGY:
	Since our line/fields aren't being stored anywhere we don't
	need to truncate a list of fields.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcHeightTruncateFields	proc	far
	ret
CalcHeightTruncateFields	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcHeightDirtyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dirty a line (NOT!)

CALLED BY:	TL_CommonLineCalculate via LICL_dirtyLineCallback
PASS:		xxx
RETURN:		xxx
DESTROYED:	xxx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcHeightDirtyLine	proc	far
	ret
CalcHeightDirtyLine	endp

TextInstance ends
