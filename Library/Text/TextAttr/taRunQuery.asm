COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		taRunQuery.asm

ROUTINES:

	Name			Description
	----			-----------

	Routines available to the rest of the text object

   EXT	TA_GraphicRunLength	Return the number of characters before a
				graphic

   EXT	TA_CharAttrRunLengthAndInfo Return the number of characters in the same
				charAttr starting at a given position and return
				the font, point size and text charAttr for that
				position
   EXT	TA_CharAttrRunSetupGStateForCalc
				Set up the cached gstate for calculation
   EXT	TA_FillTextAttrForTextDraw Fill a TextAttr structure with the attr for
				this run

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

DESCRIPTION:
	This file contains the internal routines to handle charAttr, paraAttr and
type runs.  None of these routines are directly accessable outisde the text
object.

	$Id: taRunQuery.asm,v 1.1 97/04/07 11:18:59 newdeal Exp $

------------------------------------------------------------------------------@

Text segment resource

TextFixed	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_GraphicRunLength

DESCRIPTION:	Return the number of characters before the next graphic

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	dx.ax - offset into text

RETURN:
	dx.ax - number of characters until next graphic

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
TA_GraphicRunLength	proc	far
	uses	di
	.enter
	class	VisTextClass

EC <	call	T_AssertIsVisText					>

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_GRAPHICS
	jnz	multiple

	; one charAttr

	mov	dx, TEXT_ADDRESS_PAST_END_HIGH
	mov	ax, TEXT_ADDRESS_PAST_END_LOW
done:
	.leave
	ret

	; multiple charAttrs

multiple:
	call	GraphicRunMultiple
	jmp	done

TA_GraphicRunLength	endp

TextFixed	ends

;---

TextAttributes segment resource

GraphicRunMultiple	proc	far		uses bx, cx, si, ds
	.enter

	pushdw	dxax
	call	GetGraphicRunForPosition	;dx.ax = position
	call	RunArrayUnlock
	popdw	cxbx				;cx.bx = position passed

	subdw	dxax, cxbx			;dx.ax = runpos - passed

	.leave
	ret
GraphicRunMultiple	endp

TextAttributes ends

TextFixed	segment

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_GetCharAttrForPosition

DESCRIPTION:	Find charAttr for position

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	dx.ax - position
	cl - GetCharAttrForPositionTypes
	ss:bp - buffer for VisTextCharAttr

RETURN:
	dx.ax - number of consecutive characters

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
TA_GetCharAttrForPosition	proc	far	uses di, es
	.enter
	class	VisTextClass

EC <	cmp	cl, GetCharAttrForPositionTypes				>
EC <	ERROR_AE	VIS_TEXT_GET_CHAR_ATTR_FOR_POSITION_ILLEGAL_TYPE >

EC <	call	T_AssertIsVisText					>

	call	TextFixed_DerefVis_DI

	; set stuff from charAttr structure

	test	ds:[di].VTI_storageFlags,mask VTSF_MULTIPLE_CHAR_ATTRS
	jnz	multiple

	; one charAttr

	call	GetSingleCharAttr
	movdw	dxax, TEXT_ADDRESS_PAST_END
done:
	segmov	es, ss
	mov	di, bp
	call	CharAttrVirtualToPhysical

	.leave
	ret

	; multiple charAttrs

multiple:
	call	GetCharAttrMultiple
	jmp	done

TA_GetCharAttrForPosition	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CharAttrVirtualToPhysical

DESCRIPTION:	Convert a virtual charAttr to a physical charAttr

CALLED BY:	INTERNAL

PASS:
	dxax - number of characters that run is valid for
	*ds:si - text object
	es:di - virtual charAttr

RETURN:
	dxax - number of characters that run is valid for
	es:di - physical charAttr

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
CharAttrVirtualToPhysical	proc	far
	class	VisLargeTextClass

	push	di
	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	notSpecialDraftMode
	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITHOUT_STYLES
	jz	specialDraftMode
notSpecialDraftMode:
	test	ds:[di].VTI_state, mask VTS_SUBCLASS_VIRT_PHYS_TRANSLATION
	pop	di
	jz	done

	push	ax, cx, dx, bp
	mov	cx, es
	mov	dx, di
	mov	ax, MSG_VIS_TEXT_CHAR_ATTR_VIRTUAL_TO_PHYSICAL
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

done:
	ret

specialDraftMode:
	pop	di
	push	cx, si, bp, ds
	sub	sp, size VisTextCharAttr
	mov	bp, sp
	call	T_GetSystemCharAttr
	segmov	ds, ss
	mov	si, bp
	push	di
	mov	cx, (size VisTextCharAttr) / 2	
	rep	movsw
	pop	di
	add	sp, size VisTextCharAttr
	pop	cx, si, bp, ds
	movdw	dxax, TEXT_ADDRESS_PAST_END
	jmp	done

CharAttrVirtualToPhysical	endp

TextFixed	ends

;---

TextAttributes segment resource

GetCharAttrMultiple	proc	far	uses bx, cx, si, ds
	class	VisTextClass
	.enter

	pushdw	dxax

	mov	bx, offset VTI_charAttrRuns
	cmp	cl, GSFPT_MANIPULATION
	jz	charAttrRight

	push	ax
	mov	ax, ATTR_VIS_TEXT_CHAR_ATTR_INSERTION_TOKEN
	call	ObjVarFindData
	pop	ax
	jnc	noInsertionToken
	push	ds:[bx]
	mov	bx, offset VTI_charAttrRuns
	call	GetRunForPosition
	pop	bx
	jmp	charAttrCommon

noInsertionToken:
	mov	bx, offset VTI_charAttrRuns
	call	TSL_IsParagraphStart
	jc	charAttrRight

	; if we're at the end of the text then use the attributes to the
	; right in case there is a run hanging out at the end

	movdw	cxdi, dxax			;save position
	call	TS_GetTextSize
	cmpdw	dxax, cxdi
	movdw	dxax, cxdi
	jz	charAttrRight

	call	GetRunForPositionLeft
	jmp	charAttrCommon
charAttrRight:
	call	GetRunForPosition
charAttrCommon:

	; ds:si = run, dx.ax = pos, bx = token

	call	GetElement
	call	RunArrayNext

	popdw	cxbx
	subdw	dxax, cxbx

	call	RunArrayUnlock

	.leave
	ret

GetCharAttrMultiple	endp

TextAttributes ends

COMMENT @----------------------------------------------------------------------

FUNCTION:	CharAttrRunSetupGStateForCalc

DESCRIPTION:	Set up the cached gstate for calculation

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisTextInstance
	dx.ax - offset into text

RETURN:
	di - gstate

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

TextInstance segment resource

TA_CharAttrRunSetupGStateForCalc	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, bp

EC <	call	T_AssertIsVisText					>

	; allocate local vars

	.enter

	sub	sp, size VisTextCharAttr
	mov	bp, sp

	mov	cl, GSFPT_MANIPULATION		;get charAttr to the right
	call	TA_GetCharAttrForPosition

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate

	; set the font and point size

	mov	cx, ss:[bp].VTCA_fontID
	mov	dx, ss:[bp].VTCA_pointSize.WBF_int
	mov	ah, ss:[bp].VTCA_pointSize.WBF_frac
	call	GrSetFont

	; set the text charAttr

	mov	al, ss:[bp].VTCA_textStyles
	mov	ah, 0xff
	call	GrSetTextStyle

	; set the track kerning
	mov	ax, {word} ss:[bp].VTCA_trackKerning
	call	GrSetTrackKern

	add	sp,size VisTextCharAttr

	.leave
	ret

TA_CharAttrRunSetupGStateForCalc	endp

TextInstance	ends

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_FillTextAttrForDraw

DESCRIPTION:	Fill a TextAttr structure with the attr for this run

CALLED BY:	EXTERNAL

PASS:
	*ds:si - text object
	bx:di - TextAttr structure
	dx.ax - position in the text
        cx    - VisTextExtendedStyles

RETURN:
	dx.ax - #characters in run

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/25/91		Initial version
        LES     6/13/00         Now returns extended styles

------------------------------------------------------------------------------@
TA_FarFillTextAttrForDraw	proc	far
	call	TA_FillTextAttrForDraw
	ret
TA_FarFillTextAttrForDraw	endp

TA_FillTextAttrForDraw	proc	near
	class	VisTextClass
	uses	bx, si, bp, es
	.enter

EC <	call	T_AssertIsVisText					>

	sub	sp, size VisTextCharAttr
	mov	bp, sp
	mov	es, bx			; set es:di -> passed buffer
	mov	cl, GSFPT_MANIPULATION	; get charAttr to the right
	call	TA_GetCharAttrForPosition	; Get charAttr information.
	pushdw	dxax			; Save # of chars

	;
	; Test for VA_FULLY_ENABLED being set or VTF_USE_50_PCT_TEXT_MASK being
	; clear.  If either is true, we'll be forcing the draw mask to SDM_50.
	;
	call	Text_DerefVis_SI
	test	ds:[si].VI_attrs, mask VA_FULLY_ENABLED
	stc				; assume doing 50 pct
	jz	5$
	test	ds:[si].VTI_features, mask VTF_USE_50_PCT_TEXT_MASK
	jz	5$
	stc				; set, do 50 pct
5$:
	pushf				; save fully enabled flag for later...

	;
	; set the font and point size
	;
	mov	ax, ss:[bp].VTCA_fontID
	mov	es:[di].TA_font, ax		; save font
	mov	ax, ss:[bp].VTCA_pointSize.WBF_int
	mov	es:[di].TA_size.WBF_int, ax	; save point size
	mov	al, ss:[bp].VTCA_pointSize.WBF_frac
	mov	es:[di].TA_size.WBF_frac, al
	mov	ax, {word} ss:[bp].VTCA_trackKerning
	mov	{word} es:[di].TA_trackKern, ax

	;
	; set the color, map mode
	;
	mov	ax, ss:[bp].VTCA_color.low
if USE_COLOR_FOR_DISABLED_GADGETS
	popf
	pushf
	jnc	8$			; not disabled, leave color same
	mov	ax, DISABLED_COLOR
8$:
endif
	mov	es:[di].TA_color.low, ax
	mov	ax, ss:[bp].VTCA_color.high
	mov	es:[di].TA_color.high, ax
	mov	ax, {word} ss:[bp].VTCA_pattern
stuffPattern::
	mov	{word} es:[di].TA_pattern, ax

	;
	; set the gray screen
	;
	mov	al, ss:[bp].VTCA_grayScreen
	popf					; restore enabled flag
if not USE_COLOR_FOR_DISABLED_GADGETS
	jnc	10$				; Not doing 50%, branch
	mov	al, SDM_50			; else use the all-powerful 50%
10$:
endif
	mov	es:[di].TA_mask, al		; save draw mask

	;
	; set the text charAttr
	;
	mov	al, ss:[bp].VTCA_textStyles
	mov	ah, 0ffh
	mov	{word} es:[di].TA_styleSet, ax	; save charAttr

	;
	; set mode to text object defaults
	;
	mov	ax, mask TM_DRAW_BASE
	mov	{word} es:[di].TA_modeSet, ax	; save mode

	;
	; Set the font weight & width
	;
	mov	ax, {word}ss:[bp].VTCA_fontWeight
	mov	{word} es:[di].TA_fontWeight, ax

CheckHack <(offset VTCA_fontWidth) eq (offset VTCA_fontWeight)+1>
CheckHack <(offset TA_fontWidth) eq (offset TA_fontWeight)+1>
;=============================================================================

	popdw	dxax

	;
	; Check for any extended styles and return the carry set if there are
	mov	bp, ss:[bp].VTCA_extendedStyles

        ; Return the extended styles as well.
        mov     cx, bp

	add	sp, size VisTextCharAttr

	tst	bp				; (clears the carry)
	jz	quit				; Branch if none
	stc					; Signal: contains ext-styles
quit:

	.leave
	ret

TA_FillTextAttrForDraw	endp

TextFixed	segment
COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_GetParaAttrForPosition

DESCRIPTION:	Find paraAttr for position

CALLED BY:	INTERNAL

PASS:
	*ds:si	- VisTextInstance
	dx.ax	- position in text
	bx	- Y position (only needed for large objects)
	cx	- region number (only needed for large objects)
	di	- Height of line at that offset
	ss:bp	- buffer for VisTextCharAttr

RETURN:
	dx.ax - start of range covered by this paraAttr
	cx.bx - end of range covered by this paraAttr
	buffer - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
TA_GetParaAttrForPosition	proc	far	uses di, es
region		local	word	push	cx
yPosition	local	word	push	bx
lineHeight	local	word	push	di
	class	VisTextClass
	.enter

EC <	call	T_AssertIsVisText					>

	push	bp
	mov	bp, ss:[bp]

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	jnz	multiple

	; one paraAttr

	call	GetSingleParaAttr
	clr	ax			;return range -- whole object
	clr	dx
	mov	cx, TEXT_ADDRESS_PAST_END_HIGH
	mov	bx, TEXT_ADDRESS_PAST_END_LOW
	jmp	done

	; multiple paraAttrs

multiple:
	call	GetParaAttrMultiple

done:
	pop	bp				;recover frame pointer

	push	ax, bx, cx, dx
	mov	cx, region
	mov	bx, yPosition
	mov	dx, lineHeight

	segmov	es, ss
	mov	di, ss:[bp]
	call	ParaAttrVirtualToPhysical

	tst	ax				;test "valid for all" flag
	pop	ax, bx, cx, dx
	jz	exit
	clrdw	dxax
	movdw	cxbx, TEXT_ADDRESS_PAST_END

exit:
	.leave
	ret

TA_GetParaAttrForPosition	endp

TextFixed	ends

TextAttributes segment resource

GetParaAttrMultiple	proc	far	uses si, ds
	class	VisTextClass
	.enter

	mov	bx, offset VTI_paraAttrRuns
	call	GetRunForPosition

	; ds:si = run, dx.ax = pos, bx = token

	call	GetElement
	pushdw	dxax				;save position

	call	RunArrayNext

	movdw	cxbx, dxax			;cxbx = range end
	popdw	dxax				;dxax = range start

	call	RunArrayUnlock

	.leave
	ret

GetParaAttrMultiple	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetRunBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the bounds of the current run type

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextGetRunBoundsParams
RETURN:		nada
DESTROYED:	ax, bx, dx, si, bp, ds, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetRunBounds	proc	far	;MSG_VIS_TEXT_GET_RUN_BOUNDS
	mov	bx, ss:[bp].VTGRBP_type
	movdw	dxax, ss:[bp].VTGRBP_position
	movdw	esbp, ss:[bp].VTGRBP_retVal
	FALL_THRU	TA_GetRunBounds
VisTextGetRunBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TA_GetRunBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the bounds of the current run type

CALLED BY:	INTERNAL	VisTextGetRunBounds
				FindRangeForHyperlink

PASS:		*ds:si	= text object
		bx	= offset for run
		dx.ax	= position
		es:bp	= VisTextRange to fill in
RETURN:		es:bp	= VisTextRange filled with run bounds
DESTROYED:	ax, dx, si, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/15/94    	Broke out of VisTextGetRunBounds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TA_GetRunBounds	proc	far
		call	GetRunForPosition
		movdw	es:[bp].VTR_start, dxax
		call	RunArrayNext
		movdw	es:[bp].VTR_end, dxax	
		call	RunArrayUnlock
		ret
TA_GetRunBounds	endp

TextAttributes	ends

TextFixed	segment
COMMENT @----------------------------------------------------------------------

FUNCTION:	ParaAttrVirtualToPhysical

DESCRIPTION:	Convert a virtual paraAttr to a physical paraAttr

CALLED BY:	INTERNAL

PASS:
	cx	- region number
	bx	- Y position in region
	dx	- Integer height of the line at that position
	*ds:si	- text object
	es:di	- virtual paraAttr

RETURN:
	ax - non-zero if this para attr is good for the entire document
	es:di - physical paraAttr
		VTR_{left,para,right}Margin - adjusted

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

* Adjust the margins of a paraAttr to reflect the constraints imposed
  by the vis bounds

* Adjust all positions from points*8 to points (except VTR_defaultTabs)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
ParaAttrVirtualToPhysical	proc	far
	class	VisLargeTextClass
	uses	bx, cx, dx, bp
	.enter

	push	dx				;save line height at <bx>

	push	di				;save pointer to virtual attrs
	call	TextFixed_DerefVis_DI		;ds:di <- instance
	
	;
	; Load up some default values for use later in the routine
	; dl	= VisTextStates
	; ax	= Non-zero if these attributes are good for the entire document
	;
	mov	dl, ds:[di].VTI_state
	clr	ax				;assume not valid for whole obj

	;
	; Check for draft mode
	;
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	notSpecialDraftMode
	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITHOUT_STYLES
	jnz	notSpecialDraftMode

	;
	; Special draft mode
	;
	; For draft mode we use some standard paragraph attributes
	; (reflected by VIS_TEXT_INITIAL_PARA_ATTR). 
	;
	; Below we expand these default attributes into a VisTextParaAttr 
	; structure and then copy that structure into the destination 
	; buffer that was passed to us on the stack.
	;
	pop	di				;es:di <- ptr to virtual attrs

	push	si, bp, ds			;save instance, ????
	sub	sp, size VisTextParaAttr
	mov	bp, sp				;ss:bp <- ptr to VisTextAttr

	mov	ax, VIS_TEXT_INITIAL_PARA_ATTR
	call	TextMapDefaultParaAttr		;map attributes into ss:bp

	segmov	ds, ss				;ds:si <- source attributes
	mov	si, bp

	push	di				;save dest offset
	mov	cx, (size VisTextParaAttr) / 2 
	rep	movsw				;copy attributes to destination
	pop	di				;restore dest offset
	add	sp, size VisTextParaAttr	;restore stack
	pop	si, bp, ds			;restore instance, ???

	;
	; For draft mode, there are no subclasses interested in mapping
	; the attributes.
	;
	clr	dx				;no sublcass in special draft
	
	;
	; For draft mode, the attributes are valid for the entire object
	;
	mov	ax, 1				;valid for entire object

	push	di				;put dest offset back on stack
						;so it can be popped below

notSpecialDraftMode:
	pop	di
	mov	bp, dx				;bp = VisTextStates to use
	pop	dx				;dx <- line height at <bx>

	;
	; ax	= Non-zero if the attributes are valid for the entire object
	; bp	= VisTextStates for the object
	;
	; cx	= Region
	; bx	= Y position in the region
	; dx	= Line height at <bx>
	;
	push	ax				;save valid flag

	push	di
	call	TextFixed_DerefVis_DI

	;
	; Compute width of object
	;
	mov_tr	ax, cx				;ax = region number

	mov	cx, ds:[di].VI_bounds.R_right
	sub	cx, ds:[di].VI_bounds.R_left	;cx = right - left
	
	;
	; For large objects (width of zero) we must look at the region
	;
	tst	cx
	jnz	gotWidth			;branch if no region to check

largeObject::
	;
	; We are in a large object that has regions. We need to get the width
	; of the region at this point, given the line height
	;
	mov_tr	cx, ax				;cx <- region
	
	push	bx				;save y position
	clr	bx				;not for bit-blt
	call	TR_RegionGetTrueWidth		;ax <- true width
	pop	bx				;restore y position

	push	ax				;save true width

	xchg	dx, bx				;dx <- y position
						;bx <- height of line at <dx>
	call	TR_RegionLeftRight		;ax <- left
						;bx <- right
	mov	cx, bx				;cx <- width
	sub	cx, ax

	pop	dx				;dx <- true width
	pop	di

	jmp	afterLRMarginAdjust


gotWidth:

	clr	ax
	mov	al, ds:[di].VTI_lrMargin
	shl	ax
	sub	cx, ax				;cx = width (considering bounds)

	clr	ax				;ax <- left edge
	mov	bx, cx				;bx <- right edge
	
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	skipOneLineRightEdge
	mov	bx, VIS_TEXT_ONE_LINE_RIGHT_MARGIN
skipOneLineRightEdge:

	mov	dx, cx				;dx <- true width
	pop	di

afterLRMarginAdjust:
	;
	; es:di	= Virtual paragraph attributes
	; ax	= Left edge of area
	; bx	= Right edge of area
	; cx	= Width of area
	; dx	= True width of area
	;

	; Convert the margins to pixel positions, store the new values and
	; keep the left and para margins

	push	ax				;save left edge
	mov	ax, offset VTPA_rightMargin
	call	RoundParaAttrPos
	mov	ax, offset VTPA_paraMargin
	call	RoundParaAttrPos
	mov	ax, offset VTPA_leftMargin
	call	RoundParaAttrPos		;ax = left margin
	pop	ax				;restore left edge

	push	bx				; save right edge of area

	;
	; The left, paragraph, and right margins can now be adjusted. 
	;
	; If the margins are greater than the indentation associated with
	; the region, then they are not affected. Otherwise they are set
	; to be the amount of the indentation.
	;
	
	;
	; The right margin is the distance from the right edge of the region,
	; assuming the square region. To figure this correctly, we need to
	; get the "true" width of the region in order to know where the
	; right edge was originally.
	;
	
	;
	; Since later we will be assuming that the right margin contains
	; the indent from the right edge of the area, we will want to store
	; in VTPA_rightMargin the distance to indent from the right edge
	; of the flow-region.
	;
	; This value is one of:
	;	rightIndent > rightMargin	:: rightMargin <- 0
	;	rightIndent < rightMargin	:: rightMargin <- rm - ri
	;
	sub	dx, bx				; dx <- right edge indent
						; Always positive or zero

	clr	bx				; Assume rIndent > rMargin
	cmp	dx, es:[di].VTPA_rightMargin
	jae	10$
	mov	bx, es:[di].VTPA_rightMargin	; bx <- rMargin - rIndent
	sub	bx, dx
10$:
	mov	es:[di].VTPA_rightMargin, bx	; Save temp right margin

	;
	; Adjust the left and paragraph margins
	;
	cmp	es:[di].VTPA_leftMargin, ax
	jae	20$
	mov	es:[di].VTPA_leftMargin, ax
20$:

	cmp	es:[di].VTPA_paraMargin, ax
	jae	30$
	mov	es:[di].VTPA_paraMargin, ax
30$:

	mov_tr	bx, es:[di].VTPA_paraMargin	;bx = para margin

	; check for one line object -- if so then replace the visual width
	; with the virtual width of a one line object

	test	bp, mask VTS_ONE_LINE
	jz	notOneLine
	mov	cx, VIS_TEXT_ONE_LINE_RIGHT_MARGIN
notOneLine:

	; compute the maximum legal value for the left and para margins

	sub	cx, VIS_TEXT_MIN_TEXT_FIELD_WIDTH	;cx = max left/para
	jae	notTooNarrow
	clr	cx
notTooNarrow:

	add	cx, ax				;cx = min margin setting

	; keep the left and para margins within bounds

	cmp	ax, cx
	jbe	leftOK
	mov	ax, cx
	mov	es:[di].VTPA_leftMargin, cx
leftOK:
	cmp	bx, cx
	jbe	paraOK
	mov	bx, cx
	mov	es:[di].VTPA_paraMargin, cx
paraOK:

	; find the greater of the left and para margins

	cmp	ax, bx
	jae	gotLeftPara
	mov_tr	ax, bx
gotLeftPara:
	;
	; compute the minimum legal right margin -- this is the greater
	; of the left and para margins plus the minimum field witdh
	; This cannot be wider than the object, however
	;
	; ax	= Greater of the *real* left and paragraph margins.
	;	  (That is, the real position of the margin as an offset
	;	   from the left edge of the region).
	; On Stack:
	;	Width of the object
	;
	add	ax, VIS_TEXT_MIN_TEXT_FIELD_WIDTH	;ax = min right margin
	pop	cx					;cx = object width
	cmp	ax, cx
	jbe	minimumRightIsLegal
	mov	ax, cx
minimumRightIsLegal:

	;
	; ax	= Minimum position for the right margin
	; cx	= Right edge of flow region
	;
	sub	cx, es:[di].VTPA_rightMargin

	;
	; cx	= right margin (right edge of object minus RM value)
	; ax	= minimum right margin (from left/para margins)
	;
	cmp	cx, ax
	jge	storeRightMargin		;sign compare in case cx < 0
	mov_tr	cx, ax
storeRightMargin:
	;
	; cx	= Value for right margin
	;
	mov	es:[di].VTPA_rightMargin, cx

	; convert tab positions

	clr	cx
	mov	cl, es:[di].VTPA_numberOfTabs
	jcxz	afterTabs
			CheckHack <(offset T_position eq 0)
	mov	ax, offset VTPA_tabList
tabLoop:
	push	ax
	call	RoundParaAttrPos
	pop	ax
	add	ax, size Tab
	loop	tabLoop
afterTabs:

	test	bp, mask VTS_SUBCLASS_VIRT_PHYS_TRANSLATION
	jz	noSubclass
	mov	cx, es
	mov	dx, di
	mov	ax, MSG_VIS_TEXT_PARA_ATTR_VIRTUAL_TO_PHYSICAL
	call	ObjCallInstanceNoLock
noSubclass:

	pop	ax

	.leave
	ret

ParaAttrVirtualToPhysical	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RoundParaAttrPos

DESCRIPTION:	Round a paraAttr position

CALLED BY:	INTERNAL

PASS:
	es:[di][ax] - position (points * 8)

RETURN:
	ax, es:[di][ax] - position rounded

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/25/91		Initial version

------------------------------------------------------------------------------@
RoundParaAttrPos	proc	near	uses bp
	.enter

	add	ax, di
	mov_tr	bp, ax
	mov	ax, es:[bp]
	add	ax, 4
	shr	ax
	shr	ax
	shr	ax
	mov	es:[bp], ax

	.leave
	ret

RoundParaAttrPos	endp

TextFixed	ends

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_IsPositionAtParaAttrBoundry

DESCRIPTION:	Decide if a position falls at the start of a paraAttr run.

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	dx.ax - position

RETURN:
	carry - set if the position is at the start of a paraAttr run.

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/25/91		Initial version

------------------------------------------------------------------------------@

if 0

TextAttributes segment resource

TA_IsPositionAtParaAttrBoundry	proc	far	uses ax, bx, cx, dx, si, di, ds
	class	VisTextClass
	.enter

	push	dx, ax
	mov	bx, offset VTI_paraAttrRuns
	call	GetTokenForPosition
	pop	cx, bx				;cx.bx = passed position

	cmp	dx, cx
	jz	10$
	cmp	ax, bx
10$:
	stc
	jz	done
	clc
done:
	.leave
	ret

TA_IsPositionAtParaAttrBoundry	endp

TextAttributes ends

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_GetGraphicForPosition

DESCRIPTION:	Find a graphic element

CALLED BY:	GLOBAL

PASS:
	*ds:si - text object
	dxax - position in text
	ss:bp - buffer for VisTextGraphic

RETURN:
	buffer - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

TextGraphic segment resource

TA_GetGraphicForPosition	proc	near	uses ax, bx, cx, dx, si, di, ds
	.enter

	; find the correct run

EC <	pushdw	cxbp							>
EC <	pushdw	dxax							>
	call	GetGraphicRunForPosition	;bx = token
EC <	popdw	cxbp						>
EC <	cmpdw	dxax, cxbp						>
EC <	ERROR_NZ	NO_GRAPHIC_RUN_AT_GIVEN_POSITION		>
EC <	popdw	cxbp							>

	; get the element

	call	GetElement

EC <	cmp	ss:[bp].VTG_type, VisTextGraphicType			>
EC <	ERROR_AE	GRAPHIC_RUN_BAD_GRAPHIC_TYPE			>

	call	FarRunArrayUnlock

	.leave
	ret

TA_GetGraphicForPosition	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_CheckForVariableGraphics

DESCRIPTION:	See if an object has any variable graphics

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:
	carry - set if a variable graphics exists

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/13/92		Initial version

------------------------------------------------------------------------------@
TA_CheckForVariableGraphics	proc	near	uses ax, bx, cx, si, di, ds
	.enter

	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	call	FarRunArrayLock			;ds:si = run array, di = token
						;cx = count
	mov	bx, ds:[si].TRAE_token
	mov	dl, ds:[si].TRAE_position.WAAH_high

searchLoop:
	cmp	dl, TEXT_ADDRESS_PAST_END_HIGH
	clc
	jz	done

	push	si, di, ds
	mov_tr	ax, bx				;ax = token
	call	FarElementArrayLock
	call	ChunkArrayElementToPtr
	cmp	ds:[di].VTG_type, VTGT_VARIABLE
	call	FarElementArrayUnlock
	pop	si, di, ds
	stc
	jz	done

	call	FarRunArrayNext
	jmp	searchLoop

done:
	call	FarRunArrayUnlock

	.leave
	ret

TA_CheckForVariableGraphics	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisTextUpdateGraphicElement

DESCRIPTION:	Update a graphic element

CALLED BY:	EXTERNAL

PASS:
	*ds:si - text object
	ds:di - text instance
	ss:bp - new VisTextUpdateGraphicElementParams
		
RETURN:
	ax - UpdateGraphicReturnValue

DESTROYED:
	bx,si,di,ds,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	5/15/94		Initial version

------------------------------------------------------------------------------@
VisTextUpdateGraphicElement	proc	far	;MSG_VIS_TEXT_UPDATE_GRAPHIC_ELEMENT
	class	VisTextClass
	uses cx,dx
	.enter

EC <	call	T_AssertIsVisText					>

	push ds:[LMBH_handle], si		;save text's optr
	call	T_GetVMFile			
	push	bx				;save file handle

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cl, ds:[di].VTI_storageFlags	;get storage flags
		
EC <	mov	ax, ss:[bp].VTUGEP_flags				>
EC <	and	ax, not VisTextUpdateGraphicFlags			>
EC <	ERROR_NZ	VIS_TEXT_UPDATE_GRAPHIC_FLAGS_INVALID		>
		
	segmov	es, ss, ax		
	lea	di, ss:[bp].VTUGEP_graphic	;ds:di <- new graphic
	call	TG_CheckIfValidGraphicElement
	LONG	jc	error			;ax <- VTUGRV

	; get the graphic run
	push	cx				;save storage flags
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	movdw	dxax, ss:[bp].VTUGEP_position
	call	GetGraphicRunForPosition	;bx = token, di - run token
						; ds:si - run element
	pop	cx
EC <	cmpdw	dxax, ss:[bp].VTUGEP_position				>
EC <	ERROR_NZ	NO_GRAPHIC_RUN_AT_GIVEN_POSITION		>

	mov_tr	ax, bx				;ax = token
	call	RunArrayUnref
	push	bx, si, di
	;
	; get a pointer to the graphic element to be modified
	;
	call	FarElementArrayLock
	push	cx				;save storage flags
	call	ChunkArrayElementToPtr		;ds:di <- VisTextGraphic
	pop	cx				;cl <- storage flags
	;		
	; If this element has only one reference, or the caller wants all
	; graphic runs with this graphic to be updated, we can modify 
	; this element, else we need to add a new element and point this
	; graphic run at it.
	;
EC <	cmp	ds:[di].VTG_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT>
EC <	ERROR_Z	TEXT_ATTRIBUTE_ELEMENT_IS_FREE				>
	tst	ds:[di].VTG_meta.REH_refCount.WAAH_high
	jnz	checkAddNew
	cmp	ds:[di].VTG_meta.REH_refCount.WAAH_low, 1
	je	modify				; only 1 element...
checkAddNew:		
	test	ss:[bp].VTUGEP_flags, mask VTUGF_NEW_ELEMENT
	jnz	addNew
modify:		
	;
	; copy the new graphic, less the RefElementHeader
	; into the VisTextGraphic element
	;
	push	cx				;save storage flags
	mov	cx, size RefElementHeader
	push	si
	segxchg	es, ds, ax 			;es:di <- destination graphic
	add 	di, cx				; es:di <- VTG_vmChain
	lea	si, ss:[bp].VTUGEP_graphic	;ds:si <- source graphic
	add	si, cx				; ds:si <- VTG_vmChain
	neg	cx		
	add	cx, size VisTextGraphic		;size of graphic less Ref
	rep	movsb
	pop	si				
	pop	cx				;restore storage flags
	;
	; mark the graphic element array dirty and unlock it
	;
	segmov	ds, es, ax			;*ds:si<- graphic element array
	test	cl, mask VTSF_LARGE
	jz	smallText
	call	HugeArrayDirty			;mark the huge array dirty
unlock:
	call	FarElementArrayUnlock

	pop	bx, si, di
	call	RunArrayReref
	call	FarRunArrayUnlock
	pop	bx				;clear file handle from stack
	mov	ax, UGRV_MODIFIED_ELEMENT
draw:
	pop	bx, si				;^lbx:si <- text object
	call	MemDerefDS			
	test	ss:[bp].VTUGEP_flags, mask VTUGF_RECALC
	jz	exit
	push	ax				;save the return value
	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	ObjCallInstanceNoLock
	pop	ax
exit:		
	.leave
	ret

smallText:
	call	ObjMarkDirty			;mark the chunk as dirty
	jmp	unlock

error:
	add	sp, 6				;clear the stack
	jmp	exit				;and leave

addNew:
	pushdw	ds:[di].VTG_vmChain		;save original VMChain
	;
	; Remove the reference for this graphic, as we are going to
	; change the token stored in the graphic run array to that of
	; the new graphic
	;
	clr	bx				; no callback, since element
						; won't be removed - it's
						; ref count is > 0
	call	ElementArrayRemoveReference
EC <	ERROR_C	VIS_TEXT_GRAPHIC_ELEMENT_FREED_UNEXPECTEDLY		>

	call	FarElementArrayUnlock
	popdw	axcx				;original graphic element
	pop	bx, si, di
	call	RunArrayReref			;ds:si <- run element
		
	pop	dx				;dx <- destination file
	;
	; add the new graphic element, point the old run at it
	;
	push	bp
	mov	bx, dx				;dx <- source file
	lea	bp, ss:[bp].VTUGEP_graphic	;ss:bp <- new graphic
	;
	; First, check that the passed VMChain is not the same as
	; the original VMChain.  If they are the same, make a copy
	; of the original for the new element.  Otherwise, when
	; AddGraphicElement is called, a new element may not be created
	; because the VMChains match.
	; 
	cmpdw	axcx, ss:[bp].VTG_vmChain
	jne	noCopy
	push	bp
	mov	bp, cx
	call	VMCopyVMChain
	mov	cx, bp
	pop	bp
	movdw	ss:[bp].VTG_vmChain, axcx
noCopy:		
	clr	ss:[bp].VTG_meta.REH_refCount.WAAH_high
	mov	ss:[bp].VTG_meta.REH_refCount.WAAH_low, 1
	call	AddGraphicElement		;bx <- token of elt added
	mov	ds:[si].TRAE_token, bx		;save the new token
	pop	bp

	call	FarRunArrayMarkDirty	
	call	FarRunArrayUnlock
	mov	ax, UGRV_CREATED_NEW_ELEMENT
	jmp	draw
		
VisTextUpdateGraphicElement	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TG_CheckIfValidGraphicElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a graphic element has any 
		obvious invalidities

CALLED BY:	VisTextUpdateGraphicElement
PASS:		es:di - VisTextGraphic
RETURN:		carry clear if graphic is valid
		    ax - destroyed
		carry set if invalid
		    ax - UpdateGraphicReturnValue
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TG_CheckIfValidGraphicElement		proc	near
	uses	cx
	.enter
	;	
	; check for valid graphic type and graphic flags
	;
	mov	ax, UGRV_INVALID_GRAPHIC_TYPE
	cmp	es:[di].VTG_type, VisTextGraphicType
	LONG	jae	error
	mov	ax, es:[di].VTG_flags		
	and	ax, not VisTextGraphicFlags
	mov	ax, UGRV_INVALID_GRAPHIC_FLAGS
	LONG	jnz	error
		
	cmp	es:[di].VTG_type, VTGT_GSTRING
	jne	notGString

	;
	; gstring graphics can't have null size
	;
	mov	ax, es:[di].VTG_size.XYS_width
	or	ax, es:[di].VTG_size.XYS_height
	mov	ax, UGRV_INVALID_GSTRING_SIZE
	LONG	jz	error
	;
	; Check the VTG_vmChain field.  From vTextC.def:
	; 	 VTG_vmChain		dword
	;
	; 	This is a dword value to pass to the VMChain routines.
	; 	If only the low word is 0, then the high word is a VM handle
	;
	; 	If both are non-zero, it is  a DB item (high word is group
	; 	low word is item)
	;
	; 	If the high word is 0, then the low word is an LMemChunk.
	;
	; 	If both are 0, then there is no data.
	;
	; I don't think a gstring can ever be stored in an LMemChunk, 
	; because when a graphic run is deleted, VMFreeVMChain is called
	; on the value in VTG_vmChain, and I don't think it will work if
	; it contains a chunk handle. So treat that as an error.
	;
	tst	es:[di].VTG_vmChain.high
	mov	ax, UGRV_INVALID_GSTRING_VMCHAIN_HANDLE
	LONG	jz	error
	mov	ax, es:[di].VTG_vmChain.high
	;
	; What about a gstring in a DBItem?
	;
	mov	cx, es:[di].VTG_vmChain.low
	tst	cx
	LONG	jnz	noError
	;	
	; its in a vm chain - make sure the chain is valid
	;
	push	di
	call	VMInfo
	pop	di
	mov	ax, UGRV_INVALID_GSTRING_VMCHAIN
	jc	error
	jmp	noError
		
notGString:
EC <	cmp	es:[di].VTG_type, VTGT_VARIABLE				>
EC <	ERROR_NE	GRAPHIC_RUN_BAD_GRAPHIC_TYPE			>
	;
	; check for valid variable type
	;
	mov	ax, UGRV_INVALID_VARIABLE_TYPE
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_type, VisTextVariableType
	jae	error
	;
	; variable graphics don't use VMChains (see VisTextVariableType
	; definition in geoworks.def)
	;
	; Actually, this is no longer true.  Condo VTVT_HOTSPOT graphics
	; do have gstrings in vmChains, they just don't ever get drawn
	;
;;	mov	ax, UGRV_INVALID_VARIABLE_VMCHAIN_HANDLE
;;	cmpdw	es:[di].VTG_vmChain, 0
;;	jnz	error
	;
	; check for a valid ManufacturerID (see geode.def)
	;
	mov	ax, UGRV_INVALID_VARIABLE_MANUFACTURER_ID
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_manufacturerID, \
		MANUFACTURER_ID_DATABASE_LAST
	ja	error
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_manufacturerID, \
		MANUFACTURER_ID_DATABASE_FIRST
	jae	noError
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_manufacturerID, \
		ManufacturerID
	jae	error
	;
	; check that the graphic contains valid private data
	; (see VisTextVariableType definition in geoworks.def)
	;
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_type, \
		VTVT_CONTEXT_SECTION		;don't check privdata for
	ja	noError				; context_name, hotspot types
	mov	ax, VisTextNumberType
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_type, \
		VTVT_CREATION_DATE_TIME
	jb	doTheCheck
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_type, \
		VTVT_STORED_DATE_TIME
	ja	doTheCheck
	mov	ax, DateTimeFormat

doTheCheck:
	cmp	{word}es:[di].VTG_data.VTGD_variable.VTGV_privateData, ax
	mov	ax, UGRV_INVALID_VARIABLE_PRIVATE_DATA
	jae	error
	;
	; we can do more checking for VTVT_STORED_DATE_TIME
	;
	cmp	es:[di].VTG_data.VTGD_variable.VTGV_type, \
		VTVT_STORED_DATE_TIME
	jne	noError
	cmp	{word}es:[di+2].VTG_data.VTGD_variable.VTGV_privateData, \
		FileDate
	jae	error	
	cmp	{word}es:[di+4].VTG_data.VTGD_variable.VTGV_privateData, \
		FileTime
	jae	error	
noError:
	clc
done:
	.leave
	ret

error:
	stc
	jmp	done
TG_CheckIfValidGraphicElement		endp

TextGraphic ends


TextStorageCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_GetGraphicElement

DESCRIPTION:	Get a graphic elemement

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - buffer
	ax - element

RETURN:
	buffer - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/28/92		Initial version

------------------------------------------------------------------------------@
TA_GetGraphicElement	proc	near	uses bx, cx, si, di, ds
	.enter

	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	call	FarRunArrayLock
	mov	bx, ax
	call	GetElement
	call	FarRunArrayUnlock

	.leave
	ret

TA_GetGraphicElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_AddGraphicElement

DESCRIPTION:	Add a graphic element

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - VisTextGraphic
	bx - source file

RETURN:
	ax - token

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/28/92		Initial version

------------------------------------------------------------------------------@
TA_AddGraphicElement	proc	near	uses bx, dx, si, di, ds
	.enter

	mov	dx, bx				;dx = source file
	call	T_GetVMFile
	push	bx
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	call	FarRunArrayLock
	pop	bx				;bx = dest file
	call	AddGraphicElement
	mov_tr	ax, bx				;ax = token
	call	FarRunArrayUnlock

	.leave
	ret

TA_AddGraphicElement	endp

TextStorageCode ends

Text	ends
