COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlTabUtils.asm

AUTHOR:		John Wedgwood, Jan 22, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/22/92	Initial revision

DESCRIPTION:
	Utility routines for accessing tabs.

	$Id: tlTabUtils.asm,v 1.1 97/04/07 11:21:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TabGetPositionAndAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position and attributes of a tab.

CALLED BY:	CalcFieldPosition, FieldGetTabLeaderType, DrawTabLeader
PASS:		ss:bp	= LICL_vars w/:
				LICL_paraAttr set
		es:di	= Line
		es:dx	= Current field
			  (this is only passed if called from
			  CalcFieldPosition, hopefully not needed when
			  called from FieldGetTabLeaderType and DrawTabLeader)
		al	= TabReference
		ss:bx	= TOC_vars (if it is possible that no tab actually
			  exists)
			  (this is only passed if called from
			  CalcFieldPosition, hopefully not needed when
			  called from FieldGetTabLeaderType and DrawTabLeader)
		ss:bp	= LICL_vars (with LICL_theParaAttr)
RETURN:		cx	= Position of the tab on the line
		al	= TabAttributes
		bx	= tab spacing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There are a few cases:
		In Ruler:
			At left edge of line (no tab)
			At left margin (tab to left margin)
			Normal tabs
		Other:
			Default tabs
			Intrinsic tabs
			
			
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TabGetPositionAndAttributes	proc	far	uses	dx, si, ds
	.enter
	;
	; Set up a pointer to the ruler and grab the tab type...
	;
	segmov	ds, ss, si			; ds:si <- ptr to ruler
	lea	si, ss:[bp].LICL_theParaAttr
	mov	ah, al				; Save TabReference in ah

	ExtractField	byte, ah, TR_TYPE, al	; al <- tab type
						; ah <- reference number
	ExtractField	byte, ah, TR_REF_NUMBER, ah

	cmp	al, TRT_RULER			; Check for tab in ruler
	jne	other				; Branch if not

	cmp	ah, RULER_TAB_TO_LEFT_MARGIN	; Check for using left margin
	je	useLeftMargin

	cmp	ah, RULER_TAB_TO_PARA_MARGIN	; Check for using para margin
	je	useParaMargin

	cmp	ah, RULER_TAB_TO_LINE_LEFT	; Check for line-left
	je	useLineLeft

;-----------------------------------------------------------------------------
;			     Normal Tabs
;-----------------------------------------------------------------------------
	clr	cx				; cx <- # of tabs
	mov	cl, ds:[si].VTPA_numberOfTabs
	sub	cl, ah				; cx <- tab # to grab


	mov	ax, size Tab			; ax <- multiplier
	mul	cx				; ax <- offset to tab to get

	add	si, VTPA_tabList		; ds:si <- ptr to tab list
	add	si, ax				; ds:si <- ptr to the tab

	mov	cx, ds:[si].T_position		; cx <- position
	mov	al, ds:[si].T_attr		; al <- TabAttributes
	clr	bx
	mov	bl, ds:[si].T_lineWidth
	add	bl, ds:[si].T_lineSpacing
	shr	bx
	shr	bx
	shr	bx				; bx = spacing
	mov	ah, al
	and	ah, mask TA_TYPE		;if a right tab then spacing is
	cmp	ah, TT_RIGHT shl offset TA_TYPE	;positive else spacing
	jz	quit				;is negative
	neg	bx
quit:
	;
	; cx	= Position of tab
	; al	= TabAttributes
	;
	clr	ah
	.leave
	ret


;-----------------------------------------------------------------------------
;			  Tab to Left-Margin
;-----------------------------------------------------------------------------
useLeftMargin:
	;
	; The tab is not really a tab. It's one of those "fake" tabs that
	; we use to allow the user to tab from some position between the
	; paragraph margin and the left margin to the left-margin.
	;
	mov	cx, ds:[si].VTPA_leftMargin
	mov	al, TabAttributes<0,0,0,TT_LEFT>
quitNoSpacing:
	clr	bx
	jmp	quit


;-----------------------------------------------------------------------------
;			  Tab to Para-Margin
;-----------------------------------------------------------------------------
useParaMargin:
	;
	; The tab is not really a tab. It's one of those "fake" tabs that
	; we use to allow the user to tab from some position between the
	; left margin and the paragraph margin to the para-margin.
	;
	mov	cx, ds:[si].VTPA_paraMargin
	mov	al, TabAttributes<0,0,0,TT_LEFT>
	jmp	quitNoSpacing


;-----------------------------------------------------------------------------
;				No Tab
;-----------------------------------------------------------------------------
useLineLeft:
	;
	; There isn't any tab at all. Use the left or paragraph margin,
	; whichever is appropriate for this line.
	;
	mov	cx, ds:[si].VTPA_leftMargin	; Assume left-margin
	
	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_STARTS_PARAGRAPH
	jz	gotMargin

	mov	cx, ds:[si].VTPA_paraMargin	; Use paragraph margin
gotMargin:

	mov	al, TabAttributes<0,0,0,TT_LEFT>
	jmp	quitNoSpacing


;-----------------------------------------------------------------------------
;				Other
;-----------------------------------------------------------------------------
other:
	;
	; The tab isn't in the ruler. It is either a default tab or else
	; it is an "intrinsic" tab.
	;
	cmp	ah, OTHER_INTRINSIC_TAB
	je	intrinsic
	
	cmp	ah, OTHER_ZERO_WIDTH_TAB
	je	zeroWidth

;-----------------------------------------------------------------------------
;			     Default Tab
;-----------------------------------------------------------------------------
	;
	; It is a default tab, compute a position.
	; ah	= default tab number
	;
	mov	al, ah				; ax <- default tab number
	clr	ah

						; cx <- width of default tabs
	mov	cx, ss:[bp].LICL_theParaAttr.VTMPA_paraAttr.VTPA_defaultTabs
	shl	cx
	shl	cx
	mul	cx				; ax <- position * 32.
	add	ax, 32/2			; round position
	mov	cl, 5
	shr	ax, cl
	
	mov	cx, ax				; cx <- position
	mov	al, TabAttributes<0,0,0,TT_LEFT>
	jmp	quitNoSpacing


;-----------------------------------------------------------------------------
;			    Intrinsic Tab
;-----------------------------------------------------------------------------
intrinsic:
	;
	; It's an intrinsic tab, take end of previous field and add
	; in the intrinsic width to get the new position.
	; ss:bp	= LICL_vars
	; es:di	= Line
	; es:dx	= Field
	;
if NO_TAB_IS_RIGHT_MARGIN
; see tlCommonCalc.asm for more of this fix
	;
	; attempt better intrinsic tab behavior - tab to right margin
	;
	mov	cx, ds:[si].VTPA_rightMargin
	dec	cx
else
	call	ComputeEndPrevField		; ax <- end of prev field
	mov	cx, ax				; cx <- end of prev field
	add	cx, TAB_INTRINSIC_WIDTH		; cx <- position for tab
endif
	mov	ax, TabAttributes<0,0,0,TT_LEFT>
	jmp	quitNoSpacing


;-----------------------------------------------------------------------------
;			    Zero Width
;-----------------------------------------------------------------------------
zeroWidth:
	;
	; It's a zero width tab. Something horrible happened to this line...
	;
	; ss:bp	= LICL_vars
	; es:di	= Line
	; es:dx	= Field
	;
	call	ComputeEndPrevField		; ax <- end of prev field
	mov	cx, ax				; cx <- end of prev field
	mov	ax, TabAttributes<0,0,0,TT_LEFT>
	jmp	quitNoSpacing
TabGetPositionAndAttributes	endp

TextFixed	ends
