COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textOptimizedUpdate.asm

AUTHOR:		John Wedgwood, Mar 11, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 3/11/92	Initial revision

DESCRIPTION:
	Code for doing an optimized update after a change in the text.

	$Id: textOptimizedUpdate.asm,v 1.1 97/04/07 11:18:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextUpdateOptimizations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt any possible optimizations for redrawing the text.

CALLED BY:	VisTextReplace
PASS:		*ds:si	= Instance ptr
		ss:bx	= LICL_vars filled in
		ss:bp	= VisTextReplaceParameters
RETURN:		carry clear if no optimizations worked.
		carry set if optimizations did work
			dx = End of line (place to put cursor)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    Checks the following conditions:
	- We can calculate
	- Only a single line needs updating (and no more)
	- An update isn't pending
	- The object isn't suspended
	- There is no backlog of kbd events
	- The line is left justified or is the last line of a full justified
	  paragraph.
	- The line doesn't end in an optional hyphen
	- The line didn't end in an optional hyphen before
	- The position of the change was at the end of the line
	- We did not both insert *and* delete text
	- If we are deleting and before the change, the last 
	  character was kerned or extended to its right
	- The last field is left justified

    These are actually checked in the calculation code so we don't need
    to handle them here.
	- The line hasn't changed from interacting with the line above it to
	  not interacting with the line above it.
	- The line hasn't changed from interacting with the line below it to
	  not interacting with the line below it.

    If they are all true, then we can draw the line in an optimized fashion.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextUpdateOptimizations	proc	far
	class	VisTextClass
	uses	ax, bx, cx, di, bp
	.enter
	call	TextCheckCanCalcNoRange	; If we can't calculate...
	jnc	10$
toQuitFailed:
	jmp	quitFailed		; Then we can't optimize
10$:

	;
	; Check for some special cases:
	;	- No update is needed (nothing changed)
	;	- Complete redraw needed (multiple lines changed)
	;	- Suspended object
	;	- Update is pending anyway
	;
	tst	ss:[bx].LICL_linesToDraw
	LONG jz	quitOptimized		; Branch if no update needed
	
	cmp	ss:[bx].LICL_linesToDraw, 1
	ja	toQuitFailed		; Branch if no optimization possible
	
	;
	; We now know that there is only one line that has changed.
	; Check for update pending (in which case this line will get redrawn
	; anyway) and at the same time check for the object being suspended
	; in which case we can't update the screen (the end-suspend must do
	; that).
	;
	call	Text_DerefVis_DI	; ds:di <- instance ptr
        test    ds:[di].VTI_intFlags, mask VTIF_UPDATE_PENDING or \
				      mask VTIF_SUSPENDED
	jnz	toQuitFailed		; Branch if no optimization possible

	; If we are not the focus then do not do an optimized redraw.  This
	; solve bugs in GrObj with us mashing the handles around the object

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	toQuitFailed
	
	;
        ; Make sure that there aren't any kbd events in the queue. By forcing
	; a complete update we will absorb these events more quickly.
        ;
ife     TEXT_IGNORE_BACKLOG
	call    CheckKbdBacklog		; Check for events in the queue
	jc	toQuitFailed		; Quit if there are some
endif

	;
	; Get the line flags, they may be useful.
	;
	mov	cx, ss:[bx].LICL_firstLineFlags

	;
	; Only left justified lines, or full justified lines that are the
	; last lines in a paragraph can be optimized.
	;
	mov	ax, ss:[bx].LICL_firstLineParaAttrs
	ExtractField word, ax, VTPAA_JUSTIFICATION, ax
	cmp	ax, J_LEFT		; Check for left
	je	justificationOK		; Branch if it is

	cmp	ax, J_FULL		; Check for full
	jne 	toQuitFailed		; Branch if it isn't (center/right)
	;
	; It's full justified. Make sure the line ends a paragraph.
	;
	test	cx, mask LF_ENDS_PARAGRAPH
	jz	toQuitFailed		; Branch if it doesn't

justificationOK:

	;
	; It is impossible to optimize a line that ends in an auto-hyphen.
	;
	test	cx, mask LF_ENDS_IN_AUTO_HYPHEN or \
		    mask LF_ENDS_IN_OPTIONAL_HYPHEN
	jnz	toQuitFailed
	
	test	ss:[bx].LICL_firstLineOldFlags, mask LF_ENDS_IN_OPTIONAL_HYPHEN
	jnz	toQuitFailed

	;
	; There is no way (currently) to optimize lines which contain
	; extended styles.
	;
	test	cx, mask LF_CONTAINS_EXTENDED_STYLE
	jnz	toQuitFailed
	
	;
	; Check for last field ending in a non-left justified tab.
	;
	cmp	ss:[bx].LICL_firstLineLastFieldTabType, TT_LEFT
	jne	toQuitFailed
	
	;
	; Now we check to make sure that the position of the change is at
	; the end of the line. We do this by comparing the change position
	; with the last character on the line, not counting a page-break
	; or a <cr>.
	;
	movdw	dxax, ss:[bx].LICL_firstLineEndOffset
	test	cx, mask LF_ENDS_IN_CR or \
		    mask LF_ENDS_IN_COLUMN_BREAK or \
		    mask LF_ENDS_IN_SECTION_BREAK
	jz	gotEnd			; Branch if it doesn't
	
	;
	; If we are drawing control characters (ie: <cr>) then there is
	; no way we can do an optimized update
	;
	call	CheckDrawControlChars
	jc	toQuitFailed		; Branch if we are
	
	decdw	dxax			; Account for <CR>

gotEnd:
	subdw	dxax, ss:[bp].VTRP_insCount
	cmpdw	dxax, ss:[bp].VTRP_range.VTR_start
	LONG jne quitFailed		; Branch if change is not at end
	
	;
	; Figure out if we deleted or inserted text.
	;
	push	ax
	cmpdw	ss:[bp].VTRP_range.VTR_start, ss:[bp].VTRP_range.VTR_end, ax
	pop	ax
	je	noDelete		; Branch if no delete
	
	;
	; We did delete something. Make sure we didn't insert.
	;
	tstdw	ss:[bp].VTRP_insCount	; Check for insertion
	jnz	quitFailed		; Branch if we inserted

noDelete:
	;
	; We can do an optimized redraw. If we deleted, then the line is
	; shorter and we should clear from the end of the field to the end of
	; the line and then draw the field.
	;
	; If we inserted then we should draw the field.
	;
	; We need to make sure that the gstate is translated and clipped
	; correctly.
	;
	mov	cx, ss:[bx].LICL_firstLineRegion
	call	TR_RegionTransformGState; Transform and clip the gstate

	;
	; Assume we inserted and compute the number of characters to draw.
	;
	tstdw	ss:[bp].VTRP_insCount	; Check for insert/delete
	jnz	drawText		; Branch if insert only

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added  3/29/93 -jw
;
; If the line used to interact below or above, we can't do an optimized update.
;
	test	ss:[bx].LICL_firstLineOldFlags, mask LF_INTERACTS_ABOVE or \
						mask LF_INTERACTS_BELOW
	jnz	quitFailed
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	;
	; We deleted... Make sure that the last character wasn't kerned.
	;
	; *ds:si= Instance
	; ss:bx	= LICL_vars
	;
	test	ss:[bx].LICL_firstLineOldFlags, mask LF_LAST_CHAR_KERNED
	jnz	quitFailed


	;***** START HACK - Joon (4/28/95)
	; This is yet another hack to fix some greebles.  We make sure the
	; CF_HAVE_DRAWN flag is cleared here so LineWashBackground will clear
	; the entire line from top to bottom.  This flag is used in
	; TextDrawRegionCallback and TextScreenUpdateCallback so when we do a
	; full redraw, we've got a better chance of drawing everything
	; correctly.
	;
	andnf	ss:[bx].LICL_calcFlags, not mask CF_HAVE_DRAWN
	;***** END HACK	

	call	TL_LineClearFromEnd	; Clear after the end of the line
	
	;
	; Check to see if we need to draw. If the last character on the line
	; was kerned or if the last character extends outside the font box
	; then we can't do an optimized redraw.
	;
	mov	cx, -1			; Draw all the characters in the field

	;
	; Check for either of lastCharExtendsRight in which case we need to
	; draw the text of the line.
	;
	test	ss:[bx].LICL_firstLineOldFlags, mask LF_LAST_CHAR_EXTENDS_RIGHT
	jnz	drawChars		; Branch if extends past right

	;
	; Mark that the line does not need to be drawn.
	;
	push	bx			; Save frame ptr
	mov	di, ss:[bx].LICL_firstLine.low
	mov	bx, ss:[bx].LICL_firstLine.high

	clr	ax			; Bits to set
	mov	dx, mask LF_NEEDS_DRAW	; Bits to clear
	call	TL_LineAlterFlags	; Mark does not needs-redraw

	pop	bx			; Restore frame ptr
	
	jmp	quitOptimized		; Otherwise skip drawing the text

drawText:
	;
	; *ds:si= Instance
	;
					; cx <- number of chars inserted
	mov	cx, ss:[bp].VTRP_insCount.low

drawChars:
	clr	ax			; No TextClearBehindFlags
	call	TL_LineDrawLastNChars	; Draw some number of characters

quitOptimized:
	mov	dx, ss:[bx].LICL_firstLineEnd
	stc				; Signal: Optimizations worked

quit:
	.leave
	ret


quitFailed:
	clc				; Signal: Unable to optimize
	jmp	quit
TextUpdateOptimizations	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckKbdBacklog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if there are kbd press events in the queue for this
		object.

CALLED BY:	TextUpdateOptimizations
PASS:		*ds:si	= Instance ptr
RETURN:		carry set if there are kbd events in the queue.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	TEXT_IGNORE_BACKLOG
CheckKbdBacklog	proc	near
	call	Text_PushAll

	mov	bx, ds:LMBH_handle		; ^lbx:si <- object.
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE or \
		    mask MF_CUSTOM or mask MF_DISCARD_IF_NO_MATCH or \
		    mask MF_MATCH_ALL
	push	cs				; Push callback routine.
	mov	ax, offset cs:KbdOMCallBack
	push	ax

	; Load cx with the number of keypresses to find in the queue.

	mov	cx, 4				; Assume no presses
	mov	ax, MSG_META_KBD_CHAR
	call	ObjMessage

	; cx == 0 if the number of presses you asked to find were actually
	;	  in the queue.

	tst	cx				; Clears carry.
	jnz	noPresses
	stc					; Signal there are presses.
noPresses:
	call	Text_PopAll
	ret
CheckKbdBacklog	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdOMCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for ObjMessage.

CALLED BY:	ObjMessage (callback via CheckKbdBacklog)
PASS:		ax, cx, dx, si, bp - event being sent.
		ds:bx = pointer to event in queue.
		cx - # of kbd events to find before quitting.
RETURN:		cx - decremented if a kbd event was found.
		di - flags:
			PROC_SE_CONTINUE - if cx != 0.
			PROC_SE_EXIT - if cx == 0.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdOMCallBack	proc	far
	cmp	ds:[bx].HE_method, MSG_META_KBD_CHAR
	jne	notKbdPress
	test	ds:[bx].HE_dx, mask CF_RELEASE
	jnz	notKbdPress

	; This is a kbd-char press.

	dec	cx				; One less to find.
notKbdPress:

	mov	di, PROC_SE_EXIT
	jcxz	done
	mov	di, PROC_SE_CONTINUE
done:
	ret
KbdOMCallBack	endp

Text	ends
