COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/DeskVis
FILE:		deskvisClass.asm
AUTHOR:		Brian Chin

ROUTINES:
	EXT	DeskVisExposed - handle MSG_META_EXPOSED
	EXT	DeskVisRedraw - handle MSG_REDRAW
	EXT	DeskVisWinDestroyed - handle MSG_META_CONTENT_VIEW_WIN_CLOSED

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

DESCRIPTION:
	This file contains the generic desktop visible object.

	$Id: cdeskvisClass.asm,v 1.1 97/04/04 15:01:15 newdeal Exp $

------------------------------------------------------------------------------@

PseudoResident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskVisExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw the visible object

CALLED BY:	MSG_META_EXPOSED

PASS:		ds:si - instance handle of DeskVis instance
		es - segment of Deskvis class
		cx - window handle

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskVisExposed	method	DeskVisClass, MSG_META_EXPOSED
	mov	bp, ds:[si]			; deref. instance handle
	mov	ds:[bp].DVI_window, cx		; save window for later
	mov	di, ds:[bp].DVI_gState		; get gState
	tst	di				; check if gState created yet
	jnz	DVE_gotGState			; if so, don't create again
	mov	di, cx				; else, 
	call	GrCreateState 		; create gState for window
	mov	cx, ss:[desktopFontID]		; set default font in gState
	mov	dx, ss:[desktopFontSize]
	clr	ah				; no fractional part
	call	GrSetFont
	mov	ds:[bp].DVI_gState, di		; save global gState
DVE_gotGState:
	call	GrBeginUpdate
	push	di				; save gState handle
	mov	bp, di
	mov	ax, MSG_DV_DRAW		; draw ourselves
	call	ObjCallInstanceNoLock
	pop	di				; restore gState handle
	call	GrEndUpdate
	ret
DeskVisExposed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskVisRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates desktop visible object after making changes to content

CALLED BY:	MSG_REDRAW

PASS:		*ds:si - DeskVis object
		ds:di - DeskVis instance data

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskVisRedraw	method	dynamic	DeskVisClass, MSG_REDRAW

	mov	si, di
	mov	di, ds:[si].DVI_gState		; get our gstate
	tst	di				; check if gstate valid
	jz	noWindow			; if not, do nothing

	push	ds:[si].DVI_window		; save window
	call	GrGetWinBounds			; ax, bx, cx, dx = bounds
	sub	cx, ax				; convert to window coords.
	sub	dx, bx
	clr	ax
	mov	bx, ax
	mov	bp, ax				; indicate rectangular region
	pop	di				; get window
	call	WinInvalReg			; invalidate it

noWindow:
	ret
DeskVisRedraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskVisViewWinClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with view window closing

CALLED BY:	MSG_META_CONTENT_VIEW_WIN_CLOSED

PASS:		ds:si - instance data of desk vis object
		^hbp	- Window that has been closed

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskVisViewWinClosed	method	DeskVisClass,
				MSG_META_CONTENT_VIEW_WIN_CLOSED
	mov	bx, ds:[si]			; deref. instance data
	mov	ds:[bx].DVI_window, 0		; make sure no window is saved
	mov	di, ds:[bx].DVI_gState		; get gState
	tst	di
	jz	DVWD_goneDaddyGone
	call	GrDestroyState
	mov	ds:[bx].DVI_gState, 0		; make sure no GState is saved
DVWD_goneDaddyGone:
	mov	di, offset DeskVisClass
	call	ObjCallSuperNoLock		; superclass, do your stuff
						;	(pass on window)
	ret
DeskVisViewWinClosed	endp


PseudoResident ends
