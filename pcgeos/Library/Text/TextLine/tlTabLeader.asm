COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlTabLeader.asm

AUTHOR:		John Wedgwood, Feb 26, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/26/92	Initial revision

DESCRIPTION:
	Misc border related stuff.

	$Id: tlTabLeader.asm,v 1.1 97/04/07 11:20:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextBorder	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTabLeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a tab leader for a field.

CALLED BY:	CommonFieldDraw
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		es:di.bx= Field
		ss:bp	= CommonDrawParameters
		ax = TabLeader
RETURN:		nothing
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
	leaderType = LeaderFromTab(field.tab)
	if (leaderType != TL_NONE) {
	    if (field == firstField) {
		prevFieldEnd = 0
	    } else {
		pf = fieldOffset - sizeof(FieldInfo)
		prevFieldEnd = pf.position + pf.width
	    }
	    left  = lineLeft + prevFieldEnd
	    right = lineLeft + field.position
	    y     = line.baseline

	    if (left != right) {
		call leaderHandlerTable[leaderType]
	    }
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTabLeader	proc	far
	class	VisTextClass
	uses	bx, dx, di
	.enter	inherit	CommonFieldDraw

	;
	; If we are drawing a tab-leader then we clearly are drawing all the
	; characters in the field. Set the drawOffset to 0 so that all the
	; characters in things like the dot-leader get drawn.
	;
	push	di, ax				; Save line offset, TabLeader
	call	TextBorder_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_gstate		; di <- gstate
	clr	ax				; Draw everything
	call	GrSetTextDrawOffset		; Set the drawOffset
	pop	di, ax				; Restore line offset, TabLeader

	;
	; There is a tab leader. We need to compute the area it covers.
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
	; ax	= TabLeader
	; bx	= Offset to current field
	; cx	= End of previous field
	;
	add	cx, es:[di].LI_adjustment
	mov	dx, es:[di][bx].FI_position
	add	dx, es:[di].LI_adjustment

	;
	; Here's the various situations:
	;
	;			    tab stop
	;				|
	; LEFT TAB:			|
	;				|text
	;		[t.line][offset]|
	; (want leader to reach left side of tab line)
	;
	; RIGHT TAB:			|
	;			    text|
	;				|[offset][t.line]
	; (want leader to reach left side of text)
	;
	; CENTER TAB:			|
	;			      te|xt
	;		[t.line][offset]|
	; (want leader to reach min(left side of text, left side of tab line)
	;
	; DECIMAL TAB:			|
	;			    $100|00
	;		[t.line][offset]|
	; (want leader to reach min(left side of text, left side of tab line)
	;
	; If a left tab, we return the offset from the tab stop back to the
	; left side of the tab line.
	;
	; If a right tab then spacing is zero since tab line is drawn to right
	; of tab position (plus offset) and we want the tab leader to reach
	; the left side of the text.
	;
	; If a center or decimal tab, we return the offset from  the tab stop
	; back to the left side of the tab line, and let DrawTabLeader get the
	; minimum of that and the left side of the text.
	;
	; The left tab case can also be handled like the center/decimal tab
	; case since the min(left side of tab line, left side of text) is
	; going to be (left side of tab line).
	;
	; As a matter of fact, since we return the distance from the tab stop
	; to the right side of the tab line for the right tab case, we can
	; always use this:
	;
	; right side of tab leader = min(left side of text,
	;				tab stop position
	;				+ adjustment for tab line width
	;				+ adjustment for tab line offset)
	;
	; - brianc 11/3/94
	;
	push	ax, cx, bp			; save TabLeader, left, params
	mov	bp, params.CDP_liclVars		; ss:bp = LICL_vars
	mov	al, es:[di][bx].FI_tab		; al = TabReference
	call	TabGetPositionAndAttributes	; cx = position, bx = spacing
						;	al = TabAttributes
	add	cx, bx				; cx = left side of tab line
						; (right side for right tab)
	cmp	dx, cx				; left side of text < tab line?
	jbe	haveLeaderRight			; yes, leader only reaches text
	mov	dx, cx				; else, leader reaches tab line
haveLeaderRight:
	pop	ax, cx, bp			; ax = TabLeader, cx = left
						;	side of tab leader
						;	bp = params

	;
	; cx,dx	= Range to draw to
	; ax	= TabLeader
	;
	cmp	cx, dx			; check bounds
	jg	noLeader		; nothing to draw
	shl	ax, 1			; ax <- index into table of words
	mov_tr	bx, ax			; bx <- index into table of words
	call	cs:leaderHandlerTable[bx]	; Call the routine
noLeader:

	.leave
	ret
DrawTabLeader	endp

leaderHandlerTable	label	word
	word	offset	DrawTabLeaderNone	; Should never be called
	word	offset	DrawTabLeaderDot	; TL_DOT
	word	offset	DrawTabLeaderLine	; TL_LINE
	word	offset	DrawTabLeaderBullet	; TL_BULLET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTabLeaderNone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw nothing... This routine should never be reached

CALLED BY:	DrawTabLeader via leaderHandlerTable
PASS:		xxx
RETURN:		xxx
DESTROYED:	xxx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTabLeaderNone	proc	near
EC <	ERROR	-1							>
NEC <	.fall_thru							>
DrawTabLeaderNone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTabLeaderLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line tab-leader.

CALLED BY:	DrawTabLeader via leaderHandlerTable
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Left edge of area to draw the leader to
		dx	= Right edge of area to draw the leader to
		ss:bp	= Inheritable CommonDrawParameters
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTabLeaderLine	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter	inherit	DrawTabLeader
	
	push	cx, dx				; Save left, right
	
	;
	; Compute the Y position to draw at
	;
	CommonLineGetBLO			; dx.bl <- baseline
	ceilwbf	dxbl, dx			; dx <- baseline
	add	dx, params.CDP_drawPos.PWBF_y.WBF_int
	
	push	dx				; Save Y position to draw at
	
	;
	; Set the character attributes so we can use them for drawing the
	; line.
	;
	call	TextBorder_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_gstate		; di <- gstate

	movdw	dxax, gdfVars.GDFV_textOffset	; dx.ax <- offset to the TAB
	call	SetupGStateForDrawAtOffset	; Do the setup
	
	;
	; Copy the character attributes into the line attributes
	;
	call	GrGetTextColor			; al, bl, bh <- RGB
	mov	ah, CF_RGB
	call	GrSetLineColor
	
	mov	al, GMT_ENUM
	call	GrGetTextMask
	call	GrSetLineMask
	
	;
	; Draw the line
	;
	pop	bx				; bx <- Y position
	pop	ax, cx				; ax <- left
						; cx <- right
	
	call	GrDrawHLine			; Draw the line
	.leave
	ret
DrawTabLeaderLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTabLeaderBullet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bullet tab-leader.

CALLED BY:	DrawTabLeader via leaderHandlerTable
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Left edge of area to draw the leader to
		dx	= Right edge of area to draw the leader to
		ss:bp	= Inheritable CommonDrawParameters
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRepeatedStringParams	struc
    DRSP_string		dword			; String pointer
    DRSP_count		word			; Size of string
DrawRepeatedStringParams	ends

REPEATED_CHAR_COUNT	=	32

DrawTabLeaderBullet	proc	near
	uses	ax, bx
	.enter	inherit	DrawTabLeader

	;
	; Lock the resource containing the leader strings
	;
FXIP<	mov	bx, handle TabLeaderStringsXIP				>
FXIP<	call	MemLock				; ax <- seg		>
	sub	sp, size DrawRepeatedStringParams
	mov	bx, sp				; ss:bx <- parameters
FXIP<	mov	ss:[bx].DRSP_string.segment, ax				>
NOFXIP<	mov	ss:[bx].DRSP_string.segment, cs				>
	mov	ax, offset bulletString
	mov	ss:[bx].DRSP_string.offset, ax
	mov	ss:[bx].DRSP_count, REPEATED_CHAR_COUNT	
	call	DrawTabLeaderRepeatedString
FXIP<	mov	bx, handle TabLeaderStringsXIP				>
FXIP<	call	MemUnlock						>
	
	add	sp, size DrawRepeatedStringParams
	.leave
	ret

DrawTabLeaderBullet	endp

if _FXIP
TabLeaderStringsXIP	segment resource
endif

SBCS <bulletString	byte	REPEATED_CHAR_COUNT dup (C_BULLET)	>
if PZ_PCGEOS
	;
	; C_BULLET doesn't exist in SJIS, so we use an alternative.
	;
DBCS <bulletString	wchar	REPEATED_CHAR_COUNT dup (C_KATAKANA_MIDDLE_DOT)>
else
DBCS <bulletString	wchar	REPEATED_CHAR_COUNT dup (C_BULLET)	>
endif

if _FXIP
TabLeaderStringsXIP	ends
endif


;------------

DrawTabLeaderDot	proc	near
	uses	ax, bx
	.enter	inherit	DrawTabLeader

	;
	; Lock the resource containing the leader strings
	;
FXIP<	mov	bx, handle TabLeaderStringsXIP				>
FXIP<	call	MemLock				; ax <- seg		>
	sub	sp, size DrawRepeatedStringParams
	mov	bx, sp				; ss:bx <- parameters
FXIP<	mov	ss:[bx].DRSP_string.segment, ax				>
NOFXIP<	mov	ss:[bx].DRSP_string.segment, cs				>
	mov	ax, offset dotString
	mov	ss:[bx].DRSP_string.offset, ax
	mov	ss:[bx].DRSP_count, REPEATED_CHAR_COUNT
	call	DrawTabLeaderRepeatedString
FXIP<	mov	bx, handle TabLeaderStringsXIP				>
FXIP<	call	MemUnlock						>

	add	sp, size DrawRepeatedStringParams
	.leave
	ret

DrawTabLeaderDot	endp

if _FXIP
TabLeaderStringsXIP	segment resource
endif

SBCS <dotString	byte	REPEATED_CHAR_COUNT dup ('.')			>
DBCS <dotString	wchar	REPEATED_CHAR_COUNT dup ('.')			>

if _FXIP
TabLeaderStringsXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTabLeaderRepeatedString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a tab-leader consisting of a string to repeat.

CALLED BY:	DrawTabLeaderBullet, DrawTabLeaderDot
PASS:		*ds:si	= Instance ptr
		es:di	= Line
		cx	= Left edge of area to draw the leader to
		dx	= Right edge of area to draw the leader to
		ss:bp	= Inheritable CommonDrawParameters
		ss:bx	= DrawRepeatedStringParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTabLeaderRepeatedString	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, si, ds
	.enter	inherit	DrawTabLeader
	;
	; Compute the width of the area to fill
	;
	sub	dx, cx				; dx <- width
	mov	ax, dx				; ax <- width

	;
	; Compute the Y position to draw at
	;
	ceilwbf	es:[di].LI_blo, dx		; dx <- baseline
	add	dx, params.CDP_drawPos.PWBF_y.WBF_int

	push	cx, dx				; Save X/Y position

	push	ax				; Save width
	;
	; Set the gstate so that it has the character attribute appropriate for
	; the position in the text where the tab falls.
	;
	call	TextBorder_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_gstate		; di <- gstate
	
	movdw	dxax, gdfVars.GDFV_textOffset	; dx.ax <- offset to the TAB
	call	SetupGStateForDrawAtOffset	; Do the setup
	
	;
	; Set the gstate to draw text from the baseline.
	;
	mov	al, mask TM_DRAW_BASE
	mov	ah, mask TM_DRAW_OPTIONAL_HYPHENS or \
		    mask TM_DRAW_ACCENT or \
		    mask TM_DRAW_BOTTOM
	call	GrSetTextMode

	;
	; Set to no track-kerning.
	;
	clr	ax
	call	GrSetTrackKern

	;
	; Figure out how many dots we'll need to draw in order to make this
	; happen. To get this we divide the width (dx-cx) by the width
	; of a dot.
	;
	segmov	ds, ss:[bx].DRSP_string.segment, ax
	mov	si, ss:[bx].DRSP_string.offset	; ds:si <- string to use
	mov	cx, ss:[bx].DRSP_count		; cx <- size of string

	pop	dx				; Restore width
	push	cx				; Save string length

	clr	cx				; dx.cx <- width (WWFixed)
	mov	bx, dx				; bx.cx <- width (WWFixed)

	LocalGetChar ax, ds:[si], NO_ADVANCE	; ax <- character to use
SBCS <	clr	ah							>
	call	GrCharWidth			; dx.ah <- width of char
	clr	al				; dx.ax <- width of char
	xchg	dx, bx				; dx.cx <- width of area
						; bx.ax <- width of char

	call	GrUDivWWFixed			; dx.cx <- result
						; dx <- integer result

	pop	cx				; cx <- string length
	pop	ax, bx				; ax <- left edge
						; bx <- top edge
	call	GrMoveTo

drawLoop:
	;
	; Check for no more dots to draw
	; Pen position set to place to draw at
	; dx	= Number of characters to draw
	; cx	= String length
	; ds:si	= pointer to dot-string
	;
	tst	dx				; Check for none will fit
	jz	quit				; Branch if no dots will fit

	;
	; Figure out how many we *can* draw
	;
	push	cx				; Save string length

	cmp	dx, cx				; Check for more than in string
	jae	gotCount			; Branch if not
	mov	cx, dx				; Otherwise use as many as we can
gotCount:

	;
	; Draw as many as we can
	; ds:si	= Dot-string
	; cx	= Number to draw
	;
	call	GrDrawTextAtCP			; Draw some dots

	sub	dx, cx				; dx <- # left to draw
	pop	cx				; Restore string length
	jmp	drawLoop			; Loop to draw more

quit:
	.leave
	ret
DrawTabLeaderRepeatedString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupGStateForDrawAtOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a gstate for drawing characters at a given offset.

CALLED BY:	DrawTabLeaderRepeatedString, DrawTabLeaderLine
PASS:		*ds:si	= Instance
		dx.ax	= Offset to setup for
		di	= GState
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupGStateForDrawAtOffset	proc	far
	uses	ax, bx, cx, dx, si, ds
	.enter
	sub	sp, size TextAttr		; Allocate frame
	movdw	bxcx, sssp			; bx:cx <- ptr to frame

	;
	; Grab the attributes
	;
	push	di				; Save gstate
	mov	di, cx				; bx:di <- ptr to frame

        push    cx
	call	TA_FarFillTextAttrForDraw	; Fill the attribute structure
        pop     cx
	
	;
	; Set the gstate
	;
	movdw	dssi, bxdi			; ds:si <- ptr to frame

	pop	di				; Restore gstate
	call	GrSetTextAttr			; Set the attributes
	
	add	sp, size TextAttr		; Restore stack
	.leave
	ret
SetupGStateForDrawAtOffset	endp

TextBorder	ends
