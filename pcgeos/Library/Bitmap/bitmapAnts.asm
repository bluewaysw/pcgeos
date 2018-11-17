COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991, 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap
FILE:		bitmapAnts.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	2 jun 92	Initial Version

DESCRIPTION:
	This file contains the routines related to bitmap ants

RCS STAMP:

	$Id: bitmapAnts.asm,v 1.1 97/04/04 17:43:15 newdeal Exp $
------------------------------------------------------------------------------@
BitmapSelectionCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSpawnSelectionAnts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS handler for VisBitmapClass

		Starts a timer to send MSG_VIS_BITMAP_ADVANCE_SELECTION_ANTS

PASS:		*ds:si = SelectionTool object
		ds:di = SelectionTool instance
		
RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSpawnSelectionAnts	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS

	uses	cx, dx, bp
	.enter

	;
	;	If we already have a timer going, then there's no need to
	;	do anything.
	;
	cmp	ds:[di].VBI_antTimer, VIS_BITMAP_ANT_TIMER_PAUSED
	jae	doneShort

	;
	;  Let's copy the bitmap's path to the screen gstate
	;

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock
	tst	bp				;no gstate, no path
	jz	doneShort

	;
	;  Let's see if the gstate has a path
	;
	mov	di, bp				;bx <- backup gstate
	mov	ax, GPT_CURRENT		
	call	GrTestPath
	jc	doneShort

	mov	bx, di				;bx <- gstate
	clr	cx, dx				;copy path at offset 0,0

	;
	;  Set the path in the bitmap's screen gstate
	;
	mov	ax, MSG_VIS_BITMAP_GET_SCREEN_GSTATE
	call	ObjCallInstanceNoLock
	tst	bp
	jz	doneShort

	mov	di, bp				;di <- screen gstate
	call	CopyPath

	;
	;  If there's a fatbits window, then we're going to want to make
	;  a copy of the bitmap so we can draw ants into it (we don't want
	;  to mess with the main bitmap in case the document is saved).
	;

	call	VisBitmapCheckFatbitsActive
	jnc	startTimer

	push	bx					;save main gstate

	mov	ax, ATTR_BITMAP_INTERACTIVE_DISPLAY_KIT
	call	ObjVarFindData
	jnc	allocNew

	;
	;  Suck out the gstate
	;

	mov	di, ds:[bx].VBDK_gstate
	jmp	copyPathToDuplicate

doneShort:
	jmp	done

	;
	;  Create a new copy of the bitmap that we can draw ants to
	;

allocNew:
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock
	pop	ax					;main gstate
	tst	dx
	jz	startTimer

	push	ax					;save main gstate

	;
	;  Use the clipboard file for the backup bitmap
	;
	mov_tr	ax, dx					;ax <- source block
	call	ClipboardGetClipboardFile		;bx <- dest VM file
	mov	dx, bx					;dx <- dest VM file

	mov	bx, cx					;bx <- source file
	clr	bp
	call	VMCopyVMChain

	push	dx, ax					;save dup file, block
	mov     ax,TGIT_THREAD_HANDLE       ;get thread handle
	clr     bx                          ;...for the current thread
	call    ThreadGetInfo               ;ax = thread handle
	mov_tr  di,ax                       ;di = thread handle
	pop	bx, ax
	call	GrEditBitmap			;di <- gstate handle
	call	HackAroundWinScale

	mov_tr	dx, ax				;cx <- vm block

	mov	ax, ATTR_BITMAP_INTERACTIVE_DISPLAY_KIT
	mov	cx, size VisBitmapDisplayKit
	call	ObjVarAddData

	mov	ds:[bx].VBDK_bitmap, dx
	mov	ds:[bx].VBDK_gstate, di

copyPathToDuplicate:

	pop	bx					;bx <- main gstate
	clr	cx, dx					;no offset
	call	CopyPath

startTimer:
	;
	;	Set up a timer to send us MSG_MOVE_ANTS
	;
if 1
	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ANT_TIMER_PERIOD
	mov	dx, MSG_VIS_BITMAP_ADVANCE_SELECTION_ANTS
	call	TimerStart
else
	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_CONTINUAL
	mov	di, ANT_TIMER_PERIOD
	mov	cx, ANT_TIMER_DELAY
	mov	dx, MSG_VIS_BITMAP_ADVANCE_SELECTION_ANTS
	call	TimerStart
endif

	;
	;	Save the timer's handle away
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_antTimer, bx
	mov	ds:[di].VBI_antMaskOffset, offset AntMask1

	;
	;	Draw the first set of ants
	;
	mov	ax, MSG_VIS_BITMAP_DRAW_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	BitSet	ds:[di].VBI_undoFlags, VBUF_ANTS_DRAWN

done:
	.leave
	ret
VisBitmapSpawnSelectionAnts	endm

;
;	Here are the line masks that implement the selection ants. They are
;	essentially diagonal lines, 4 pixels wide, spaced four pixels apart.
;
AntMask1	label	byte
	word	AntMask2			;next mask
	db	11110000b
	db	01111000b
	db	00111100b
	db	00011110b
	db	00001111b
	db	10000111b
	db	11000011b
	db	11100001b

AntMask2	label	byte
	word	AntMask3			;next mask
	db	01111000b
	db	00111100b
	db	00011110b
	db	00001111b
	db	10000111b
	db	11000011b
	db	11100001b
	db	11110000b

AntMask3	label	byte
	word	AntMask4			;next mask
	db	00111100b
	db	00011110b
	db	00001111b
	db	10000111b
	db	11000011b
	db	11100001b
	db	11110000b
	db	01111000b

AntMask4	label	byte
	word	AntMask5			;next mask
	db	00011110b
	db	00001111b
	db	10000111b
	db	11000011b
	db	11100001b
	db	11110000b
	db	01111000b
	db	00111100b

AntMask5	label	byte
	word	AntMask6			;next mask
	db	00001111b
	db	10000111b
	db	11000011b
	db	11100001b
	db	11110000b
	db	01111000b
	db	00111100b
	db	00011110b

AntMask6	label	byte
	word	AntMask7			;next mask
	db	10000111b
	db	11000011b
	db	11100001b
	db	11110000b
	db	01111000b
	db	00111100b
	db	00011110b
	db	00001111b

AntMask7	label	byte
	word	AntMask8			;next mask
	db	11000011b
	db	11100001b
	db	11110000b
	db	01111000b
	db	00111100b
	db	00011110b
	db	00001111b
	db	10000111b

AntMask8	label	byte
	word	AntMask1			;next mask
	db	11100001b
	db	11110000b
	db	01111000b
	db	00111100b
	db	00011110b
	db	00001111b
	db	10000111b
	db	11000011b


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapDrawSelectionAnts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_DRAW_SELECTION_ANTS handler for VisBitmapClass

CALLED BY:	

PASS:		*ds:si = VisBitmapClass object
		ds:di = VisBitmapClass instance

RETURN:		nothing

DESTROYED:	ax, bx, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
	jon	Aug 8, 1991	revised to use passed gstate
	jon	2 jun 92	moved to VisBitmapClass, used cached gstate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDrawSelectionAnts	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_DRAW_SELECTION_ANTS

localAntMask	local	DrawMask

if FULL_EXECUTE_IN_PLACE
	uses	cx, dx, es
else
	uses	cx, dx
endif
	.enter

	;
	;  Copy the ant mask to our local mask
	;
	mov	bx, ds:[di].VBI_antMaskOffset
	mov	ax, {word}cs:[bx+2][0]
	mov	{word}localAntMask[0], ax
	mov	ax, {word}cs:[bx+2][2]
	mov	{word}localAntMask[2], ax
	mov	ax, {word}cs:[bx+2][4]
	mov	{word}localAntMask[4], ax
	mov	ax, {word}cs:[bx+2][6]
	mov	{word}localAntMask[6], ax

	mov	di, ds:[di].VBI_mainKit.VBK_gstate
	tst	di
	jz	done
	mov	ax, GPT_CURRENT
	call	GrGetPathBounds
	jc	done

	push	bp

FXIP<	segmov	es, SEGMENT_CS, di			>
	mov	di, offset DrawSelectionAntsCB
FXIP<	pushdw	esdi					>
FXIP<	pushdw	esdi					>
NOFXIP<	pushdw	csdi					>
NOFXIP<	pushdw	csdi					>
	mov	di, C_BLACK
	push	di

	inc	cx
	inc	dx
	push	dx
	push	cx
	push	bx
	push	ax

	sub	sp, 6
	lea	ax, ss:[localAntMask]
	push	ax

	clr	ax
	push	ax

	mov	bp, sp

	mov	ax, MSG_VIS_BITMAP_DISPLAY_INTERACTIVE_FEEDBACK
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapEditBitmapParams

	pop	bp

done:
	.leave
	ret
VisBitmapDrawSelectionAnts	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSelectionAntsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		di - gstate
		ax - offset of ant mask

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 28, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSelectionAntsCB	proc	far

	uses	ds,si

	.enter

	call	GrSaveState

	mov_tr	si, ax				;si <- ant mask offset

	;
	;	Set draw mode to inverted so that ants don't destroy anything
	;
	mov	al, MM_INVERT
	call	GrSetMixMode

	clr	ax, dx
	call	GrSetLineWidth

	;
	;	Set the line mask to one of our special ant masks and
	;	draw our rectangle.
	;
	segmov	ds, ss				;ds:si = ant pattern
	mov	al, SDM_CUSTOM
	call	GrSetLineMask

	;
	;	Draw our ant rectangle
	;
	call	GrDrawPath			;draw the ants
	call	GrRestoreState

	.leave
	ret
DrawSelectionAntsCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapAdvanceSelectionAnts
b%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_ADVANCE_SELECTION_ANTS handler for
		VisBitmapClass

CALLED BY:	Timer set up in VisBitmapSpawnSelectionAnts

PASS:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		
RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisBitmapAdvanceSelectionAnts	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_ADVANCE_SELECTION_ANTS

localAntMask	local	DrawMask

if FULL_EXECUTE_IN_PLACE
	uses	es
endif
	.enter

	;
	;	Only advance if we have a valid timer
	;
	cmp	ds:[di].VBI_antTimer, VIS_BITMAP_ANT_TIMER_PAUSED
	jbe	done

if 1
	;
	;  Start up another timer
	;
	mov	bx, ds:[LMBH_handle]
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ANT_TIMER_PERIOD
	mov	dx, MSG_VIS_BITMAP_ADVANCE_SELECTION_ANTS
	call	TimerStart

	mov	ds:[di].VBI_antTimer, bx
endif

	;
	;	See if this is our "first" advance (ie., we need to
	;	draw instead of advance).
	;
	test	ds:[di].VBI_undoFlags, mask VBUF_ANTS_DRAWN
	jnz	advance

	;
	;	Just draw.
	;
	mov	ax, MSG_VIS_BITMAP_DRAW_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	BitSet	ds:[di].VBI_undoFlags, VBUF_ANTS_DRAWN

done:
	.leave
	ret

advance:
	;
	;	We need to advance the ants that are already drawn.
	;	To make it smooth, we calculate the new mask XOR the
	;	old mask, then draw that to screen, which will give
	;	us the new mask on screen with no unsightly flashing
	;
	push	ds, si
	mov	si, ds:[di].VBI_antMaskOffset
	mov	bx, cs:[si]				;bx <- new mask
	mov	ds:[di].VBI_antMaskOffset, bx

	;
	;  read the current ant mask into our buffer
	;
	inc	bx
	inc	bx
	inc	si
	inc	si
	segmov	ds, cs

	;
	;  Calculate the mask we want to draw = new XOR old
	;
	mov	di, bx			;ds:di <- new mask
	mov	bx, size DrawMask - 2
calcMaskLoop:
	mov	ax, ds:[di][bx]		;ax <- new
	xor	ax, ds:[si][bx]		;ax <- new XOR old
	xchg	di, bx			;di <- offset, 'cause [bp][bx] isn't
					;a legal addressing mode
	
	mov	{word}localAntMask[di], ax
	xchg	di, bx			;dss:di <- new, bx <- offset
	tst	bx
	jle	afterCalcMaskLoop
	dec	bx
	dec	bx
	jmp	calcMaskLoop

afterCalcMaskLoop:
	pop	ds,si				;*ds:si <- obj

	mov	di, bp				;ss:di <- locals
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock
	xchg	bp, di				;ss:bp <- locals
						;di <- main gstate
	tst	di
	jz	done

	mov	ax, GPT_CURRENT
	call	GrGetPathBounds

	push	bp

FXIP<	segmov	es, SEGMENT_CS, di			>
	mov	di, offset DrawSelectionAntsCB
FXIP<	pushdw	esdi					>
FXIP<	pushdw	esdi					>
NOFXIP<	pushdw	csdi					>
NOFXIP<	pushdw	csdi					>
	mov	di, C_BLACK
	push	di

	inc	cx
	inc	dx
	push	dx
	push	cx
	push	bx
	push	ax

	sub	sp, 6
	lea	ax, ss:[localAntMask]
	push	ax

	clr	ax
	push	ax

	mov	bp, sp

	mov	ax, MSG_VIS_BITMAP_DISPLAY_INTERACTIVE_FEEDBACK
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapEditBitmapParams
	pop	bp
	jmp	done
VisBitmapAdvanceSelectionAnts	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapMakeSureNoSelectionAnts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_MAKE_SURE_NO_SELECTION_ANTS

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapMakeSureNoSelectionAnts	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_MAKE_SURE_NO_SELECTION_ANTS
	.enter

	;
	;	If no ants, we're done already
	;
	test	ds:[di].VBI_undoFlags, mask VBUF_ANTS_DRAWN
	jz	done

	;
	;	Draw the ants again to erase them
	;
	mov	ax, MSG_VIS_BITMAP_DRAW_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	;
	;	Indicate that the ants have been erased
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	BitClr	ds:[di].VBI_undoFlags, VBUF_ANTS_DRAWN
	
done:
	.leave
	ret
VisBitmapMakeSureNoSelectionAnts	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapKillSelectionAnts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_KILL_SELECTION_ANTS handler for VisBitmapClass

PASS:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		
RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapKillSelectionAnts	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_KILL_SELECTION_ANTS
	.enter
	;
	;	Kill the ant timer
	;
	clr	bx
	xchg	bx, ds:[di].VBI_antTimer
	cmp	bx, VIS_BITMAP_ANT_TIMER_PAUSED
	jbe	done

if 0	; we've switched to a one-shot

	clr	ax	
	call	TimerStop

endif

	;
	;	Erase ants. May have to account for any
	;	MSG_VIS_BITMAP_ADVANCE_SELECTION_ANTS that may be in
	;	the queue...
	;
	mov	ax, MSG_VIS_BITMAP_MAKE_SURE_NO_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	;
	;  Destroy the copied gstate and bitmap is they exist
	;

	mov	ax, ATTR_BITMAP_INTERACTIVE_DISPLAY_KIT
	call	ObjVarFindData
	jnc	done

	clr	di
	xchg	di, ds:[bx].VBDK_gstate
	tst	di
	jz	destroyVarData

	mov	al, BMD_KILL_DATA
	call	GrDestroyBitmap

destroyVarData:
	mov	ax, ATTR_BITMAP_INTERACTIVE_DISPLAY_KIT
	call	ObjVarDeleteData
	
done:
	.leave
	ret
VisBitmapKillSelectionAnts	endm

BitmapSelectionCode	ends


