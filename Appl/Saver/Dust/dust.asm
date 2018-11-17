COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dust.asm

AUTHOR:		Gene Anderson, Mar  7, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 7/93		Initial revision


DESCRIPTION:
	Code for dust screen-saver library

	$Id: dust.asm,v 1.1 97/04/04 16:48:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def

include	dust.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

DustApplicationClass	class	SaverApplicationClass

MSG_DUST_APP_DRAW				message
;
;	Draw the cloud of dust.  Sent by our timer
;
;	Pass:	nothing
;	Return:	nothing
;
    DAI_numMotes	word		DUST_DEFAULT_MOTES
    DAI_moteSize	byte		DUST_SIZE_MEDIUM
    DAI_smoothEdges	BooleanByte	BB_FALSE

    DAI_timerHandle	hptr		0
    	noreloc	DAI_timerHandle
    DAI_timerID		word

    DAI_random		hptr		0
	noreloc	DAI_random

    DAI_motes		lptr.MoteStruct
    DAI_heights		lptr.sdword

DustApplicationClass	endc

DustProcessClass	class	GenProcessClass
DustProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	dust.rdef
ForceRef DustApp

udata	segment

udata	ends

idata	segment

DustProcessClass	mask CLASSF_NEVER_SAVED
DustApplicationClass

idata	ends

DustCode	segment resource

.warn -private
dustOptionTable	SAOptionTable	<
	dustCategory, length dustOptions
>

dustOptions	SAOptionDesc	<
	dustNumMotesKey, size DAI_numMotes, offset DAI_numMotes
>,<
	dustMoteSizeKey, size DAI_moteSize, offset DAI_moteSize
>,<
	dustSmoothKey, size DAI_smoothEdges, offset DAI_smoothEdges
>
.warn @private
dustCategory	char	'dust', 0
dustNumMotesKey	char	'numMotes', 0
dustMoteSizeKey	char	'moteSize', 0
dustSmoothKey	char	'edges', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DustLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= DustApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DustLoadOptions	method	dynamic	DustApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs
	mov	bx, offset dustOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset DustApplicationClass
	GOTO	ObjCallSuperNoLock
DustLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DustAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures the screen isn't cleared on startup.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= DustApplication object

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/7/93		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DustAppGetWinColor	method dynamic DustApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its little thing.
	;
	mov	di, offset DustApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT
	ret
DustAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DustAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= DustApplication object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DustAppSetWin	method dynamic DustApplicationClass, MSG_SAVER_APP_SET_WIN
		.enter
	;
	; Let the superclass do its little thing.
	; 
	mov	di, offset DustApplicationClass
	call	ObjCallSuperNoLock
	;
	; Create a random number generator.
	; 
	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	ds:[di].DAI_random, bx
	;
	; Now initialize our state.  Note that the order is
	; significant, as we use the random number generator
	; for both of these, and initializing the mote array
	; affects the screen height array.
	;
	call	InitScreenHeightArray
	call	InitMoteArray
	;
	; Start up the timer to draw the first time
	;
	call	DustSetTimer
	.leave
	ret
DustAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitMoteArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the array of motes

CALLED BY:	DustAppSetWin()
PASS:		*ds:si - DustApplication object
RETURN:		DAI_motes - initialized array of MoteStruct
DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitMoteArray		proc	near
	class	DustApplicationClass
	uses	bx
	.enter

	;
	; Allocate the array
	;
	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	cx, ds:[di].DAI_numMotes
	mov	ax, size MoteStruct
	mul	cx
	mov_tr	cx, ax
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc

	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	ds:[di].DAI_motes, ax
	;
	; Initialize the motes
	;
	mov	bx, ax				;bx <- chunk of array
	mov	bx, ds:[bx]			;ds:bx <- ptr to array
	mov	cx, ds:[di].DAI_numMotes	;cx <- # of motes
moteLoop:
	call	InitMote
	add	bx, (size MoteStruct)		;ds:bx <- next mote
	loop	moteLoop			;loop while more motes

	.leave
	ret
InitMoteArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitMote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize one dust mote

CALLED BY:	InitMoteArray()
PASS:		*ds:si - DustApplication object
		ds:bx - ptr to MoteStruct
RETURN:		carry - set if done
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitMote		proc	near
	uses	ax, cx, dx, di
	class	DustApplicationClass
	.enter

randomLoop:
	;
	; Get a random size
	;
	call	GetSizeForMote
	mov	ds:[bx].MS_size, cl		;store size
	;
	; Get a random x position
	;
	push	cx
	call	GetScreenWidth
	mov	ax, cx				;ax <- screen width
	pop	cx
	call	GetRandomNumber
	;
	; Keep the positions to a multiple of the dust size.
	; Decrementing the dust size works because our sizes
	; are powers of two.
	;
	mov	dx, cx				;dx <- size
	dec	dx				;dx <- size
	not	dx
	and	ax, dx				;limit to multiples
	;
	; If we're smoothing edges, find the local maximum
	;
	call	ShiftToLocalMax
	mov	ds:[bx].MS_position.P_x, ax	;save random x
	;
	; Get the current height at the position, and adjust it for one mote
	;
	push	bx
	call	GetHeightAtPosition
	cmp	bx, 0				;at top?
	jle	atTopReset			;branch if at top
	sub	bx, cx				;bx <- new height
	call	SetHeightAtPosition		;set new screen height
	mov	cx, bx				;cx <- height at position
	;
	; Get the color at the position
	;
	call	GetGState			;di <- handle of GState
	call	GetColorAtPosition		;dl <- Color
	;
	; Save the original color at the position
	;
	pop	bx
	mov	ds:[bx].MS_color, dl		;save color
	;
	; Save y position
	;
	mov	ds:[bx].MS_position.P_y, cx
	;
	; Nuke the old point
	;
	mov	dl, C_BLACK
	call	DrawMoteInColor
	;
	; And now the rest
	;
	clr	ds:[bx].MS_speed.P_x
	clr	ax
	mov	al, ds:[bx].MS_size		;ax <- size
	shl	ax, 1
	shl	ax, 1				;ax <- size * 4
	shl	ax, 1
	shl	ax, 1				;ax <- 2 bits of fraction
	call	GetRandomNumber
	mov	ds:[bx].MS_speed.P_y, ax
	clc					;carry <- not 'done'
quit:
	.leave
	ret

	;
	; We've reached the top with one point -- see if we're done
	;
atTopReset:
	pop	bx				;ds:bx <- MoteStruct
	call	CheckForScreenTop
	jc	quit				;branch if done
	jmp	randomLoop			;try again
InitMote		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForScreenTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we've reached the top

CALLED BY:	InitMote()
PASS:		*ds:si - DustApplication object
RETURN:		carry - set if reached top of screen
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForScreenTop		proc	near
	class	DustApplicationClass
	uses	cx, di
	.enter

	call	GetScreenWidth			;cx <- width of screen
	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	di, ds:[di].DAI_heights		;*ds:di <- array of heights
	mov	di, ds:[di]			;ds:di <- ptr to array
cmpLoop:
	cmp	{word}ds:[di], 0		;reached top?
	jg	notTop				;branch if reached top
	add	di, (size word)			;ds:di <- next entry
	loop	cmpLoop
	stc					;carry <- reached top
	jmp	done

notTop:
	clc					;carry <- haven't reached top
done:
	.leave
	ret
CheckForScreenTop		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShiftToLocalMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift from the position to its local maximum

CALLED BY:	InitMote()
PASS:		*ds:si - DustApplication object
		ax - x position
RETURN:		ax - x position, adjusted to local maximum
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShiftToLocalMax		proc	near
	uses	bx, cx, dx, di
	class	DustApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	cmp	ds:[di].DAI_smoothEdges, DST_POINTY
	je	done				;branch if not smoothing
	call	GetHeightAtPosition
	cmp	ds:[di].DAI_smoothEdges, DST_VERY_SMOOTH
	je	doVerySmooth
	;
	; Randomly look left or right first
	;
	push	ax
	mov	ax, 10				;ax <- random 0 to 9
	call	GetRandomNumber
	cmp	ax, 5
	pop	ax
	jbe	skipLeft			;look right first
	;
	; Unless we're at the left edge, check our left neighbor
	;
checkLeftLoop:
	mov	dx, bx				;dx <- height here
	cmp	ax, 0				;at left edge?
	jle	skipLeft			;branch if at left
	dec	ax
	call	GetHeightAtPosition		;bx <- height to left
	cmp	bx, dx				;left higher?
	jg	checkLeftLoop			;branch if left is higher
	inc	ax
	jmp	done
skipLeft:

	;
	; Unless we're at the right edge, check our right neighbor
	;
	call	GetScreenWidth			;cx <- width of screen
checkRightLoop:
	mov	dx, bx				;dx <- height here
	cmp	ax, cx				;at right edge?
	jge	skipRight			;branch if right edge
	inc	ax
	call	GetHeightAtPosition		;bx <- height to right
	cmp	bx, dx				;right higher?4
	jg	checkRightLoop			;branch if right is higher
	dec	ax
skipRight:

done:

	.leave
	ret

doVerySmooth:
	;
	; Unless we're at the left edge, check our left neighbor
	;
smoothLeft:
	mov	dx, bx				;dx <- height here
	cmp	ax, 0				;at left edge?
	jle	done				;branch if at left
	dec	ax
	call	GetHeightAtPosition		;bx <- height to left
	cmp	bx, dx				;left higher or same?
	jge	smoothLeft			;branch if higher or same
	inc	ax
	jmp	done

ShiftToLocalMax		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeForMote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size for a new mote

CALLED BY:	InitMote()
PASS:		*ds:si - DustApplication object
RETURN:		cx - size for mote (DustSize)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeForMote		proc	near
	class	DustApplicationClass
	uses	ax, di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	cl, ds:[di].DAI_moteSize	;cl <- mote size
	cmp	cl, DUST_SIZE_RANDOM		;random size?
	jne	gotSize				;branch if not random
CheckHack <DUST_SIZE_LARGE eq 4>
CheckHack <DUST_SIZE_MEDIUM eq 2>
CheckHack <DUST_SIZE_SMALL eq 1>
	mov	ax, 3				;ax <- random 0-2
	call	GetRandomNumber
	mov	cl, al
	mov	al, 1
	shl	al, cl				;shift me jesus
	mov	cl, al				;cl <- DustSize
gotSize:
	clr	ch

	.leave
	ret
GetSizeForMote		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitScreenHeightArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initalize the array of screen heights

CALLED BY:	DustAppSetWin()
PASS:		*ds:si - DustApplication object
RETURN:		DAI_heights - array of sdword
DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitScreenHeightArray		proc	near
	class	DustApplicationClass
	uses	bx, es
	.enter

	;
	; Allocate the array
	;
	call	GetScreenWidth
	push	cx
	shl	cx, 1				;cx <- table of words
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc

	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	ds:[di].DAI_heights, ax
	;
	; Initialize the array to full screen
	;
	pop	cx
	mov	bx, ax				;bx <- chunk of array
	mov	ax, ds:[di].SAI_bounds.R_bottom	;ax <- full screen
	mov	di, ds:[bx]
	segmov	es, ds				;es:di <- ptr to array
	rep	stosw				;store me jesus

	.leave
	ret
InitScreenHeightArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScreenWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of our screen

CALLED BY:	UTILITY
PASS:		*ds:si - DustApplication object
RETURN:		cx - width of screen
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetScreenWidth		proc	near
	uses	di
	class	DustApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	cx, ds:[di].SAI_bounds.R_right
	sub	cx, ds:[di].SAI_bounds.R_left	;cx <- width

	.leave
	ret
GetScreenWidth		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRandomNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a random number

CALLED BY:	UTILITY
PASS:		*ds:si - DustApplication object
		ax - max value
RETURN:		ax - random value between 0 and max-1
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRandomNumber		proc	near
	uses	bx, di, dx
	class	DustApplicationClass
	.enter

	mov_tr	dx, ax				;dx <- max value
	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	bx, ds:[di].DAI_random		;bx <- shme for random #s
	call	SaverRandom
	mov_tr	ax, dx				;ax <- random #

	.leave
	ret
GetRandomNumber		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHeightAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height at the specified position

CALLED BY:	UTILITY
PASS:		*ds:si - DustApplication object
		ax - x position
RETURN:		bx - y position for passed x
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHeightAtPosition		proc	near
	uses	ax, di
	class	DustApplicationClass
	.enter

	shl	ax, 1				;ax <- table of words
	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	di, ds:[di].DAI_heights		;*ds:di <- array of heights
	mov	di, ds:[di]			;ds:di <- ptr to array
	add	di, ax				;ds:di <- ptr to element
	mov	bx, ds:[di]			;bx <- height at position

	.leave
	ret
GetHeightAtPosition		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHeightAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the height at the specified position

CALLED BY:	UTILITY
PASS:		*ds:si - DustApplication object
		ax - x position
		bx - y position for passed x
		cx - # of points to set for (ie. mote size)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHeightAtPosition		proc	near
	uses	ax, bx, cx, dx, di, es
	class	DustApplicationClass
	.enter

	push	ax
	shl	ax, 1				;ax <- table of words
	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	dx, ds:[di].SAI_bounds.R_right	;dx <- right side
	mov	di, ds:[di].DAI_heights		;*ds:di <- array of heights
	;
	; Figure out where to store the value
	;
	mov	di, ds:[di]			;ds:di <- ptr to array
	add	di, ax				;ds:di <- ptr to element(s)
	mov	ax, bx				;ax <- height
	;
	; Make sure we're not going to store too many
	;
	pop	bx				;bx <- start x position
	sub	dx, cx				;dx <- right side - size
	cmp	bx, dx				;off right side?
	jb	numOK				;branch if not off side
	sub	bx, dx				;bx <- amount past
	sub	cx, bx				;cx <- adjust # to store
numOK:
	segmov	es, ds
	rep	stosw				;set me jesus

	.leave
	ret
SetHeightAtPosition		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get our GState

CALLED BY:	UTILITY
PASS:		*ds:si - DustApplication object
RETURN:		di - handle of GState
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGState		proc	near
	class	DustApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	di, ds:[di].SAI_curGState	;di <- handle of GState

	.leave
	ret
GetGState		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetColorAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get color at the specified position

CALLED BY:	UTILITY
PASS:		di - handle of GState
		(ax,bx) - position
RETURN:		dl - Color
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetColorAtPosition		proc	near
	uses	ax, bx
	.enter

	call	GrGetPoint			;get RGB value + color
	mov	dl, ah				;dl <- Color

	.leave
	ret
GetColorAtPosition		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DustAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= DustApplication object
		ds:di	= DustApplicationInstance

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DustAppUnsetWin	method dynamic DustApplicationClass, MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
	clr	bx
	xchg	bx, ds:[di].DAI_timerHandle
	mov	ax, ds:[di].DAI_timerID
	call	TimerStop
	;
	; Nuke the random number generator.
	; 
	clr	bx
	xchg	bx, ds:[di].DAI_random
	call	SaverEndRandom
	;
	; Nuke our arrays of motes and screen heights
	;
	mov	ax, ds:[di].DAI_motes
	call	LMemFree
	mov	ax, ds:[di].DAI_heights
	call	LMemFree
	;
	; Call our superclass to take care of the rest.
	; 
	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset DustApplicationClass
	GOTO	ObjCallSuperNoLock
DustAppUnsetWin	endm

;==============================================================================
;
;		    DRAWING ROUTINES
;
;==============================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DustSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	QASetWin, QADraw
PASS:		*ds:si	= DustApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DustSetTimer	proc	near
	class	DustApplicationClass
	uses	di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, DUST_TIMER_SPEED
	mov	dx, MSG_DUST_APP_DRAW
	mov	bx, ds:[LMBH_handle]	; ^lbx:si <- destination

	call	TimerStart
	mov	ds:[di].DAI_timerHandle, bx
	mov	ds:[di].DAI_timerID, ax
	.leave
	ret
DustSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DustAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next Dust line.

CALLED BY:	MSG_QIX_APP_DRAW

PASS:		*ds:si	= DustApplication object
		ds:di	= DustApplicationInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DustAppDraw		method	dynamic DustApplicationClass, 
					MSG_DUST_APP_DRAW
	.enter

	;
	; Make sure there is a GState
	;
	tst	ds:[di].SAI_curGState
	jz	done
	;
	; Update the dust
	;
	mov	cx, ds:[di].DAI_numMotes	;cx <- # of dust motes
	mov	ax, ds:[di].SAI_bounds.R_bottom	;ax <- bottom of screen
	mov	bx, ds:[di].DAI_motes
	mov	bx, ds:[bx]			;ds:bx <- ptr to array of motes
	mov	di, ds:[di].SAI_curGState	;di <- handle of GState
moteLoop:
	;
	; Erase the current position (draw in XOR)
	;
	mov	dl, C_BLACK			;dl <- Color
	call	DrawMoteInColor
	;
	; Update the mote speed and position
	;
	push	ax
	clr	ax
	mov	al, ds:[bx].MS_size		;ax <- size
	shl	ax, 1				;ax <- size / 2 (2 bits of frac)
	add	ds:[bx].MS_speed.P_y, ax	;faster, faster!

	mov	ax, ds:[bx].MS_speed.P_y	;ax <- y speed
	shr	ax, 1
	shr	ax, 1				;2 bits of fraction
	add	ds:[bx].MS_position.P_y, ax	;update y position
	mov	ax, ds:[bx].MS_speed.P_x	;ax <- x speed
	shr	ax, 1
	shr	ax, 1				;2 bits of fraction
	add	ds:[bx].MS_position.P_x, ax	;update x position
	pop	ax
	;
	; See if we've gone off the screen
	;
	cmp	ds:[bx].MS_position.P_y, ax	;off bottom?
	ja	resetMote			;branch if off bottom
	;
	; Draw the mote at the new position
	;
	mov	dl, ds:[bx].MS_color		;dl <- Color
	call	DrawMoteInColor
nextMote:
	;
	; Loop for more motes
	;
	add	bx, (size MoteStruct)		;ds:bx <- ptr to next mote
	loop	moteLoop
	;
	; Set another timer for next time.
	; 
	call	DustSetTimer
done:
	.leave
	ret

	;
	; The mote has gone off screen -- reset it to
	; something exciting and new (you know, "The Love Mote" :-)
	;
resetMote:
	call	InitMote
	jnc	nextMote			;branch if set
	;
	; There is no more stuff.  Clear the screen to account
	; for any motes still falling or any greebles from partial
	; pieces of stuff left behind.
	;
	mov	di, ds:[si]
	add	di, ds:[di].DustApplication_offset
	mov	ax, ds:[di].SAI_bounds.R_left
	mov	bx, ds:[di].SAI_bounds.R_top
	mov	cx, ds:[di].SAI_bounds.R_right
	mov	dx, ds:[di].SAI_bounds.R_bottom	;(ax,bx,cx,dx) <- bounds
	mov	di, ds:[di].SAI_curGState	;di <- handle of GState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrFillRect
	jmp	done
DustAppDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMoteInColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a mote in its specified color

CALLED BY:	DustAppDraw()
PASS:		ds:bx - ptr to MoteStruct
		dl - Color to draw in
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMoteInColor		proc	near
	uses	ax, bx, cx, dx
	.enter

	mov	ah, CF_INDEX
	mov	al, dl
	call	GrSetAreaColor
	mov	cl, ds:[bx].MS_size		;cl <- size
	mov	ax, ds:[bx].MS_position.P_x
	mov	bx, ds:[bx].MS_position.P_y
	clr	ch
	mov	dx, cx
	add	cx, ax				;cx <- right
	add	dx, bx				;dx <- bottom
	call	GrFillRect

	.leave
	ret
DrawMoteInColor		endp

DustCode	ends
