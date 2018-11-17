COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxFeedbackGlyph.asm

AUTHOR:		Adam de Boor, Sep  5, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 5/95		Initial revision


DESCRIPTION:
	Implementation of OutboxFeedbackGlyph
		

	$Id: outboxFeedbackGlyph.asm,v 1.1 97/04/05 01:21:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_OUTBOX_FEEDBACK

MailboxClassStructures	segment

	OutboxFeedbackGlyphClass

MailboxClassStructures	ends

OFG_FRAME_WIDTH		equ	99
OFG_FRAME_HEIGHT	equ	90

OFG_GLOBE_X		equ	24
OFG_GLOBE_Y		equ	33

OFG_FRAME_DELAY		equ	10

OFGFrameDesc	struct
    OFGFD_globe		word
    OFGFD_letter	word
    OFGFD_letterX	word
    OFGFD_letterY	word
OFGFrameDesc	ends



OutboxUICode	segment	resource

ofgFrames	OFGFrameDesc	\
	<Globe10Bitmap, Letter1Bitmap, 21, 77>,
	<Globe9Bitmap, Letter1Bitmap, 2, 66>,
	<Globe8Bitmap, Letter2Bitmap, 0, 41>,
	<Globe7Bitmap, Letter2Bitmap, 15, 16>,
	<Globe6Bitmap, Letter2Bitmap, 43, 9>,
	<Globe5Bitmap, Letter2Bitmap, 69, 20>,
	<Globe4Bitmap, Letter1Bitmap, 85, 39>,
	<Globe3Bitmap, Letter1Bitmap, 80, 55>,
	<Globe2Bitmap, 0, 0, 0>,
	<Globe1Bitmap, 0, 0, 0>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFGVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return how big we want to be

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= OutboxFeedbackGlyph object
		ds:di	= OutboxFeedbackGlyphInstance
		cx	= RecalcSizeArgs for width
		dx	= RecalcSizeArgs for height
RETURN:		cx	= width
		dx	= height
DESTROYED:	ax, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		we are inflexible

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFGVisRecalcSize method dynamic OutboxFeedbackGlyphClass, MSG_VIS_RECALC_SIZE
		.enter
		mov	cx, OFG_FRAME_WIDTH
		mov	dx, OFG_FRAME_HEIGHT
		.leave
		ret
OFGVisRecalcSize endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFGStartTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start up the timer for the next frame

CALLED BY:	(INTERNAL) OFGVisOpen,
			   OFGNextFrame
PASS:		*ds:si	= OutboxFeedbackGlyph
RETURN:		ds:di	= OutboxFeedbackGlyphInstance
		OFGI_timer, OFGI_timerID set
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFGStartTimer	proc	near
		class	OutboxFeedbackGlyphClass
		.enter
		mov	bx, ds:[LMBH_handle]
		mov	al, TIMER_EVENT_ONE_SHOT	
		mov	cx, OFG_FRAME_DELAY
		mov	dx, MSG_OFG_NEXT_FRAME
		call	TimerStart
		DerefDI	OutboxFeedbackGlyph
		mov	ds:[di].OFGI_timer, bx
		mov	ds:[di].OFGI_timerID, ax
		.leave
		ret
OFGStartTimer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFGVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If animated, begin animation.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= OutboxFeedbackGlyph object
		ds:di	= OutboxFeedbackGlyphInstance
		bp	= 0 if top window, else window for object to open on
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFGVisOpen	method dynamic OutboxFeedbackGlyphClass, MSG_VIS_OPEN
		uses	bp, ax
		.enter
		call	OFGStartTimer
		mov	ds:[di].OFGI_curFrame, 0
		.leave
		mov	di, offset OutboxFeedbackGlyphClass
		GOTO	ObjCallSuperNoLock
OFGVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFGVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut off the animation timer, if it's on

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= OutboxFeedbackGlyph object
		ds:di	= OutboxFeedbackGlyphInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFGVisClose	method dynamic OutboxFeedbackGlyphClass, MSG_VIS_CLOSE
		.enter
		
		push	ax
		clr	bx
		xchg	bx, ds:[di].OFGI_timer
		mov	ax, ds:[di].OFGI_timerID
		call	TimerStop
		pop	ax

		.leave

		mov	di, offset OutboxFeedbackGlyphClass
		GOTO	ObjCallSuperNoLock
OFGVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFGNextFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance to the next frame.

CALLED BY:	MSG_OFG_NEXT_FRAME
PASS:		*ds:si	= OutboxFeedbackGlyph object
		ds:di	= OutboxFeedbackGlyphInstance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFGNextFrame	method dynamic OutboxFeedbackGlyphClass, MSG_OFG_NEXT_FRAME
		mov	cx, ds:[di].OFGI_curFrame
		inc	cx
		cmp	cl, length ofgFrames
		jb	drawIt
		clr	cx
drawIt:
		clr	bp			; generate your own gstate
		clr	dl			; no special draw flags
		mov	ax, MSG_OFG_DRAW_FRAME
		call	ObjCallInstanceNoLock
	;
	; Start the timer if we're still open (which we can determine by
	; checking if VIS_CLOSE has set OFGI_timer to 0)
	;
		DerefDI	OutboxFeedbackGlyph
		tst	ds:[di].OFGI_timer
		jz	done
		call	OFGStartTimer
done:
		ret
OFGNextFrame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFGDrawFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the indicated frame, recording it as our current

CALLED BY:	MSG_OFG_DRAW_FRAME
PASS:		*ds:si	= OutboxFeedbackGlyph object
		ds:di	= OutboxFeedbackGlyphInstance
		cl	= frame # to draw
		dl	= DrawFlags
		bp	= gstate to use, or 0 if should create one
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFGDrawFrame	method dynamic OutboxFeedbackGlyphClass, MSG_OFG_DRAW_FRAME
		.enter
		push	bp
		tst	bp
		jnz	haveState
		
		push	cx, dx
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		pop	cx, dx
haveState:
		mov	di, bp
		
		mov	ax, C_WHITE
		call	GrSetAreaColor
		
		push	cx

		push	dx
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		pop	bx				; bl <- DrawFlags

		test	bl, mask DF_EXPOSED
		jz	erasePrev
	;
	; When exposed, we wipe out the entire background.
	;

		mov	bx, bp
		call	GrFillRect
		jmp	drawNew

erasePrev:
	;
	; Erase the letter in the previous frame; the globe we'll just
	; draw over.
	;
	; ax = left
	; bp = top
	; di = gstate
	; 

		mov	bx, ds:[si]
		add	bx, ds:[bx].OutboxFeedbackGlyph_offset
		mov	bx, ds:[bx].OFGI_curFrame
		
		CheckHack <type ofgFrames eq 8>
		shl	bx
		shl	bx
		shl	bx
	;
	; Find the letter chunk and see if the letter was actually drawn.
	;
		push	ds, si, ax, bp
		mov	si, cs:[ofgFrames][bx].OFGFD_letter
		tst	si
		jz	erasePrevDone		; => nothing to erase
	;
	; It was. Adjust the left & top to be the left & top of the letter.
	;
		add	ax, cs:[ofgFrames][bx].OFGFD_letterX
		add	bp, cs:[ofgFrames][bx].OFGFD_letterY
	;
	; Find the right and bottom of the letter by adding in the width and
	; height of the bitmap
	;
		push	ax
		mov	bx, handle OutboxFeedbackData
		call	MemLock
		mov	ds, ax
		pop	ax
		mov	bx, bp
		mov	si, ds:[si]

		mov	cx, ax
		add	cx, ds:[si].B_width

		mov	dx, bx
		add	dx, ds:[si].B_height

		call	GrFillRect
	;
	; Release the bitmap block and recover various things.
	;
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
erasePrevDone:
		pop	ds, si, ax, bx		; *ds:si <- object
						; ax <- left, bx <- top
drawNew:
	;
	; Record current frame and index into the frames array
	;
	; ax = left of frame
	; bx = top of frame
	;
		pop	bp			; bp <- frame #
		mov	si, ds:[si]
		add	si, ds:[si].OutboxFeedbackGlyph_offset
		mov	ds:[si].OFGI_curFrame, bp

		CheckHack <type ofgFrames eq 8>
		shl	bp
		shl	bp
		shl	bp
	;
	; Lock down the block with the bitmaps in it.
	;
		push	bx, ax
		mov	bx, handle OutboxFeedbackData
		call	MemLock
		mov	ds, ax
		pop	bx, ax
	;
	; Draw the globe at the right place in the frame.
	;
		mov	si, cs:[ofgFrames][bp].OFGFD_globe
		mov	si, ds:[si]
		push	ax, bx
		add	ax, OFG_GLOBE_X
		add	bx, OFG_GLOBE_Y
		clr	dx		; dx <- no callback
		call	GrDrawBitmap
		pop	ax, bx
	;
	; Draw the letter at the right place in the frame.
	;
		mov	si, cs:[ofgFrames][bp].OFGFD_letter
		tst	si
		jz	done
		mov	si, ds:[si]
		add	ax, cs:[ofgFrames][bp].OFGFD_letterX
		add	bx, cs:[ofgFrames][bp].OFGFD_letterY
		call	GrDrawBitmap
done:
	;
	; Destroy the gstate if we created it.
	;
		pop	bp
		tst	bp
		jnz	exit
		call	GrDestroyState
exit:
		mov	bx, handle OutboxFeedbackData
		call	MemUnlock
		.leave
		ret
OFGDrawFrame	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OFGVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the current frame again

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= OutboxFeedbackGlyph object
		ds:di	= OutboxFeedbackGlyphInstance
		cl	= DrawFlags
		bp	= gstate to use
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OFGVisDraw	method dynamic OutboxFeedbackGlyphClass, MSG_VIS_DRAW
		.enter
		mov	dl, cl			; dl <- DrawFlags
		mov	cx, ds:[di].OFGI_curFrame
		mov	ax, MSG_OFG_DRAW_FRAME
		call	ObjCallInstanceNoLock
		.leave
		ret
OFGVisDraw	endm
OutboxUICode	ends


endif	; _OUTBOX_FEEDBACK
