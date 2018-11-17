COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		
FILE:		hopalong.asm

AUTHOR:		David Loftesness, Sep 19, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/11/91		Initial revision
	DaveL	12/9/91		made into hopalong
DESCRIPTION:
	Specific screen saver to do the hopalong algorithm

	$Id: hopalong.asm,v 1.1 97/04/04 16:49:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include type.def
include geos.def
include geosmacro.def
include errorcheck.def
include library.def
include localmem.def
include graphics.def
include gstring.def
include win.def
include	geode.def
include object.def
include event.def
include metaClass.def
include processClass.def
include	geodeBuild.def
include thread.def
include timer.def
include initfile.def

UseLib	ui.def
UseLib	options.def
UseLib	saver.def
UseLib	math.def

include	coreBlock.def

include character.def

include hopalong.def
;==============================================================================
;
;		  PUBLIC DECLARATION OF ENTRY POINTS
;
;==============================================================================

global	HopStart:far
global	HopStop:far
global	HopFetchUI:far
global	HopFetchHelp:far
global	HopSaveState:far
global	HopRestoreState:far
global	HopSaveOptions:far
global	HopDraw:far
;==============================================================================
;
;		       CONSTANTS AND DATA TYPES
;
;==============================================================================

;
; The different speeds we support
;
HOP_SLOW_DELTA_MAX		equ	5
HOP_MEDIUM_DELTA_MAX		equ	10
HOP_FAST_DELTA_MAX		equ	20
HOP_VERY_FAST_DELTA_MAX	equ	30
;
; The different sizes we support
;
HOP_VERY_LARGE_SIZE		equ	160
HOP_LARGE_SIZE		equ	80
HOP_MEDIUM_SIZE		equ	40
HOP_SMALL_SIZE		equ	25
;
; Timer speed
;
HOP_TIMER_SPEED		equ	1
;
; The state we save to our parent's state file on shutdown.
;
HopState	struc
    VS_speed		word
    VS_size		word
HopState	ends

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	hopalong.rdef

udata	segment

;
; Current window and gstate to use for drawing.
;
curWindow	hptr.Window
curGState	hptr.GState
curMagnif	word
sourceHandle	hptr
underHandle	hptr

winHeight	word
winWidth	word
xOrigin		word
yOrigin		word
aValue		word
bValue		word
cValue		word
oldAValue	word
oldBValue	word
oldCValue	word
randomStor1	word
randomStor2	word
xPoint		word
yPoint		word
newXPoint	word
;
; Timer we started for moving
;
curTimer	hptr.HandleTimer
curTimerID	word

udata	ends

idata	segment

hopCounter	word	0
curYOffset	word	0
curXOffset	word	0
curColor	byte	DK_BLUE
maxColor	byte	DK_RED
;
; Parameters for the Piece, saved and restored to and from our parent's state
; file.
;
Hopstate	HopState	<
    HOP_MEDIUM_DELTA_MAX,
    HOP_MEDIUM_SIZE
>

idata	ends

;==============================================================================
;
;		   EXTERNAL WELL-DEFINED INTERFACE
;
;==============================================================================
HopCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	Generic screen saver library
PASS:		cx	= window handle
		dx	= window height
		si	= window width
		di	= gstate handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version
	dl	12/6/91		yeah, so?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopStart	proc	far
	uses	ax, bx, cx, dx, ds, es
	.enter
	call	SaverInitBlank
	segmov	ds, dgroup, ax
	;
	; Save the window and gstate we were given for later use.
	;
	mov	ds:[curWindow], cx
	mov	ds:[curGState], di
	mov	ds:[winHeight], dx
	mov	ds:[winWidth], si
	;
	; Initialize vars
	;
	clr	ds:[hopCounter]
	;
	; Get the origin
	;
	shr	si, 1
	shr	dx, 1
	mov	ds:[xOrigin], si
	mov	ds:[yOrigin], dx
	;
	; Set up the floating point stack
	;
	mov	ax, FP_DEFAULT_STACK_ELEMENTS
	mov	bx, FLOAT_STACK_GROW
	call	FloatInit
	;
	; Start up the timer to do the first spot
	;
	call	HopSetTimer

	.leave
	ret
HopStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop drawing a Hop

CALLED BY:	Parent library
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version
	dl	12/6/91		Hmmm, well?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopStop	proc	far
	uses	ds, bx, ax
	.enter
	segmov	ds, dgroup, ax
	
	;
	; Stop the draw timer we started.
	;
	mov	bx, ds:[curTimer]
	mov	ax, ds:[curTimerID]
	call	TimerStop
	
	;
	; And mark the window and gstate as no longer existing.
	;
	clr	ax
	mov	ds:[curWindow], ax
	mov	ds:[curGState], ax

	.leave
	ret
HopStop	endp

HopCode		ends

HopInitExit	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopFetchUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the tree of options that affect how this thing
		performs.

CALLED BY:	Saver library
PASS:		nothing
RETURN:		^lcx:dx	= root of option tree to add
		ax	= first entry point stored in OD's in the tree
		bx	= last entry point stored in OD's in the tree
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopFetchUI	proc	far
	uses	bp, si, di, ds
	.enter

	;
	; Duplicate the block -- we have all the items send us methods, so
	; we don't need to save the handle around.
	;
	mov	bx, handle HopOptions
	mov	ax, handle saver	; owned by the saver library so it
					;  can get into a state file
	call	ObjDuplicateBlock

	;
	; Return the root in ^lcx:dx
	;
	mov	cx, bx
	mov	dx, offset HopRoot
	mov	ax, enum HopDraw		; first entry point used in OD's
	mov	bx, enum HopDraw		; last entry point used in OD's
	.leave
	ret
HopFetchUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopFetchHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the help tree

CALLED BY:	Saver library
PASS:		nothing
RETURN:		^lcx:dx	= root of help tree (cx == 0 for none)
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopFetchHelp	proc	far
	clr	cx				;cx <- no help
	ret
HopFetchHelp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add our little state block to that saved by the generic
		saver library.

CALLED BY:	SF_SAVE_STATE
PASS:		cx	= handle of block to which to append our state
		dx	= first available byte in the block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopSaveState	proc	far
		uses	cx, di, es, ds, si
		.enter
	;
	; Enlarge the block to hold our state information.
	;
		mov	bx, cx
		mov	ax, dx
		add	ax, size HopState + size word
		mov	ch, mask HAF_LOCK
		call	MemReAlloc
		jc	done
	;
	; Copy our state block to the passed offset within the block.
	;
		mov	es, ax
		mov	di, dx
		segmov	ds, dgroup, si
		mov	si, offset Hopstate
		mov	ax, size Hopstate
		stosw		; save the size of the saved state first
		xchg	cx, ax
		rep	movsb
	;
	; Done with the block, so unlock it.
	;
		call	MemUnlock
done:
		.leave
		ret
HopSaveState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore our little state block from that saved by the generic
		saver library.

CALLED BY:	SF_RESTORE_STATE
PASS:		cx	= handle of block from which to retrieve our state
		dx	= start of our data in the block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopRestoreState	proc	far
		uses	cx, di, es, ds, si
		.enter
	;
	; Lock down the block that holds our state information.
	;
		mov	bx, cx
		call	MemLock
		jc	done
		mov	ds, ax
	;
	; Copy our state block from the passed offset within the block.
	;
		segmov	es, dgroup, di
		mov	di, offset Hopstate
		mov	cx, size Hopstate
		mov	si, dx

		lodsw			; make sure the state is the right
					;  size.
		cmp	ax, cx
		jne	unlock		; if not, abort the restore
		rep	movsb
	;
	; Done with the block, so unlock it.
	;
unlock:
		call	MemUnlock
done:
		.leave
		ret
HopRestoreState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save any extra options that need saving.

CALLED BY:	Generic saver library
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopSaveOptions	proc	far
		.enter
		clc
		.leave
		ret
HopSaveOptions	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing entry point for the kernel's benefit

CALLED BY:	kernel
PASS:		di	= LibraryCallTypes
		cx	= handle of client, if LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopEntry	proc	far
	clc		; no errors
	ret
HopEntry	endp

HopInitExit	ends

;==============================================================================
;
;		    DRAWING ROUTINES/ENTRY POINTS
;
;==============================================================================

HopCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	HopDraw, HopStart
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HopSetTimer	proc	near
		.enter
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, HOP_TIMER_SPEED
		mov	dx, enum HopDraw

		call	SaverStartTimer
		mov	ds:[curTimer], bx
		mov	ds:[curTimerID], ax

		.leave
		ret
HopSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of the screen Hoping
CALLED BY:	timer

PASS:		none
RETURN:		none
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/91		Initial version
	dl	12/6/91		Who's eca?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HopDraw	proc	far
	.enter

	segmov	ds, dgroup, ax
	mov	es, ax
	;
	; Make sure there is a GState to draw with
	;		
	mov	di, ds:[curGState]
	tst	di
	jz	quit
	;
	; See if we're ready to start over
	;
	tst	ds:[hopCounter]			;check for overflow
	jnz	doPlot
	;
	; Setup a,b,c
	;
	mov	dx, RANDOM_A_MAX
	call	SaverRandom
	mov	ds:[aValue], dx

	mov	dx, RANDOM_B_MAX
	call	SaverRandom
	mov	ds:[bValue], dx

	mov	dx, RANDOM_C_MAX
	call	SaverRandom
	mov	ds:[cValue], dx

	clr	ds:[xPoint]
	clr	ds:[yPoint]
	clr	ds:[newXPoint]
	mov	ds:[hopCounter], 1
doPlot:
	inc	ds:[curColor]
	mov	ah, COLOR_INDEX
	mov	al, ds:[curColor]
	call	GrSetAreaColor

	cmp	ds:[curColor], DK_RED
	jne	drawThePoint
	mov	ds:[curColor], BLACK

drawThePoint:
	mov	ax, ds:[xPoint]
	mov	bx, ds:[yPoint]
	add	ax, ds:[xOrigin]
	add	bx, ds:[yOrigin]
	call	GrDrawPoint

	;
	; calculate the new values
	;
	call 	FloatWordToFloat		; pushes old x value
						; in ax
	mov	ax, ds:[bValue]
	call	FloatWordToFloat

	call	FloatMultiply			; performs b*x

	mov	ax, ds:[cValue]
	call	FloatWordToFloat		; push c

	call	FloatSub			; b*x-c

	call	FloatAbs			; abs(b*x-c)

	call	FloatSqrt			; [abs(b*x-c)]^(1/2)

	mov	ax, ds:[yPoint]
	mov	ds:[newXPoint], ax
	cmp	ds:[xPoint], 0
	jl	negativeXValue
	call	FloatNegate			; -[abs(b*x-c)]^(1/2)
negativeXValue:
	mov	ax, ds:[yPoint]
	call	FloatWordToFloat
	call	FloatAdd
	
	call	FloatFloatToDword		; dx:ax <- new x value
	
	mov	ds:[newXPoint], ax

	mov	ax, ds:[aValue]			; y <- a - x
	sub	ax, ds:[xPoint]
	mov	ds:[yPoint], ax

	mov	ax, ds:[newXPoint]
	mov	ds:[xPoint], ax
	
;	inc	ds:[hopCounter]
done:
	;
	; Set another timer for next time.
	; 
	segmov	ds, dgroup, ax
	call	HopSetTimer
quit:

	.leave
	ret

HopDraw	endp

;==============================================================================
;
;		    UI ACTION HANDLER ENTRY POINTS
;
;==============================================================================

HopCode	ends

