COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Noodle
FILE:		noodle.asm

AUTHOR:		Chris Boyke

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	4/91		Initial revision

DESCRIPTION:	Noodle screen saver
	
	$Id: noodle.asm,v 1.1 97/04/04 16:46:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

include	noodle.def

;=============================================================================
;
;			OBJECT CLASSES
;
;=============================================================================

NoodleApplicationClass	class	SaverApplicationClass

MSG_NOODLE_APP_DRAW				message
;
;	Draw the next line of the noodle. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    NAI_speed		byte		NOODLE_MEDIUM_SPEED
    NAI_numLines	byte		NOODLE_DEFAULT_LINES
    NAI_numNoodles	byte		NOODLE_DEFAULT_NOODLES

    NAI_timerHandle	hptr		0
    	noreloc	NAI_timerHandle
    NAI_timerID		word
    NAI_random		hptr		0
	noreloc	NAI_random

NoodleApplicationClass	endc

NoodleProcessClass	class	GenProcessClass
NoodleProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	noodle.rdef
ForceRef NoodleApp

udata	segment

NoodleVars	struc
	NV_timer	word
	NV_pastFirstRound byte		; is set to true once we've
					; drawn at least numEchoes splines.
	NV_index	byte
	NV_index2	byte
NoodleVars	ends

noodleBlockHandle	hptr		; handle of the locked block
noodleBlockSegment	hptr		; segment of the locked block

windowWidth	word
windowHeight	word
curGState	hptr			; we can't pass instance data
numLines	byte
numNoodles	byte
random		word

;***************************************************************************
; The state information
;***************************************************************************

pointsRange	Range

noodleVars	NoodleVars

udata	ends

idata	segment

NoodleProcessClass	mask	CLASSF_NEVER_SAVED
NoodleApplicationClass

incrementsRange	Range	<<-NOODLE_MAX_INCREMENT, -NOODLE_MAX_INCREMENT> ,
			 < NOODLE_MAX_INCREMENT, NOODLE_MAX_INCREMENT> >

increments2Range Range <<-NOODLE_MAX_INCREMENT2, -NOODLE_MAX_INCREMENT2> ,
			< NOODLE_MAX_INCREMENT2, NOODLE_MAX_INCREMENT2> >

; Bit masks to mask out low-order bits

bitMasks	byte	3, 7, 15, 31, 63, 127

idata	ends

NoodleCode	segment resource

.warn -private
noodleOptionTable	SAOptionTable	<
	noodleCategory, length noodleOptions
>
noodleOptions	SAOptionDesc	<
	noodleSpeedKey, size NAI_speed, offset NAI_speed
>, <
	noodleNumNoodlesKey, size NAI_numNoodles, offset NAI_numNoodles
>, <
	noodleNumLinesKey,	size NAI_numLines, offset NAI_numLines
>
.warn @private
noodleCategory		char	'noodle', 0
noodleSpeedKey		char	'speed', 0
noodleNumNoodlesKey	char	'numNoodles', 0
noodleNumLinesKey	char	'numLines', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoodleLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= NoodleApplicationClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoodleLoadOptions	method dynamic NoodleApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs
	mov	bx, offset noodleOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset	NoodleApplicationClass
	GOTO	ObjCallSuperNoLock
NoodleLoadOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoodleAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate and get things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= NoodleApplicationClass object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoodleAppSetWin	method dynamic NoodleApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	; 

	mov	di, offset NoodleApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].NoodleApplication_offset

	;
	; Create a random number generator.
	; 

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].NAI_random, bx

	;
	;  Move all the app's instance data into idata, for now.
	;

	mov	es:[random], bx
	mov	bl, ds:[di].NAI_numLines
	mov	es:[numLines], bl
	mov	bl, ds:[di].NAI_numNoodles
	mov	es:[numNoodles], bl
	mov	bx, ds:[di].SAI_curGState
	mov	es:[curGState], bx

	;
	;  Initialize the noodle(s)
	;

	call	NoodleStart

	;
	; Start up the timer to draw a new line.
	;

	call	NoodleSetTimer

	ret
NoodleAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoodleAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= NoodleApplicationClass object
		ds:[di] = NoodleApplicationInstance
		es	= dgroup

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/21/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoodleAppUnsetWin	method dynamic NoodleApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN

	clr	es:[curGState]

	;
	; Stop the draw timer.
	; 

	clr	bx
	xchg	bx, ds:[di].NAI_timerHandle
	mov	ax, ds:[di].NAI_timerID
	call	TimerStop

	;
	;  Free up the noodle block
	;

	mov	bx, es:[noodleBlockHandle]
	call	MemFree

	;
	; Nuke the random number generator.
	; 

	clr	bx
	xchg	bx, ds:[di].NAI_random
	call	SaverEndRandom

	;
	; Call our superclass to take care of the rest.
	; 

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset NoodleApplicationClass
	GOTO	ObjCallSuperNoLock
NoodleAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoodleStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen -- set up the gstate, allocate
		and lock a block for storing the noodles

CALLED BY:	NoodleAppSetWin

PASS: 		ds:[di] = NoodleApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	4/91		Initial revision
	stevey	12/21/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoodleStart	proc	near	
	class	NoodleApplicationClass
	uses	ax,bx,cx,dx,si,es
	.enter

	mov	si, ds:[di].SAI_bounds.R_right
	sub	si, ds:[di].SAI_bounds.R_left
	mov	es:[windowWidth], si
	
	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	mov	es:[windowHeight], dx

	;
	; Make boundaries slightly bigger than screen (window)
	;

	mov	ax, SIZE_BEYOND_SCREEN

	add	si, ax
	add	dx, ax

	mov	es:[pointsRange].R_max.P_x, si
	mov	es:[pointsRange].R_max.P_y, dx

	neg	ax

	;
	; add offset to right and bottom bounds
	;

	mov	es:[pointsRange].R_min.P_x, ax	
	mov	es:[pointsRange].R_min.P_y, ax	

	clr	es:[noodleVars].NV_index
	clr	es:[noodleVars].NV_timer
	clr	es:[noodleVars].NV_pastFirstRound

	;
	;  Allocate a block for the noodles
	;

	mov	ax, size Noodle			; allocate a global
						; block
	mov	bl, ds:[di].NAI_numNoodles
	clr	bh
	mul	bx

	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc

	mov	es:[noodleBlockHandle], bx	 ; save handle & segment
	mov	es:[noodleBlockSegment], ax

	mov	cl, ds:[di].NAI_numNoodles
	clr	ch
	mov	es, ax				; es = noodle block
	clr	bx				; es[bx] = first noodle

init:
	call	InitNoodle			; initialize the noodles
	add	bx, size Noodle
	loop	init

	.leave
	ret
NoodleStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitNoodle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the noodle's color, point position,
		velocity, and path curve

CALLED BY:	NoodleStart

PASS:		ds:[di] = NoodleApplicationInstance
		es:[bx] = the noodle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	4/91		Initial version
	stevey	12/21/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitNoodle	proc	near	
	class	NoodleApplicationClass
	uses	bx,dx,bp
	.enter

	;
	; This bit here forces the "bright" colors on 16-color displays
	;

	mov	dx, NOODLE_MAX_COLOR-8
	push	bx
	mov	bx, ds:[di].NAI_random
	call	SaverRandom
	pop	bx

	add	dl, 9			; (from 9-15)
	mov	es:[bx].N_color, dl

	mov	dx, NOODLE_MAX_PATH_CURVE
	push	bx
	mov	bx, ds:[di].NAI_random
	call	SaverRandom
	pop	bx

	add	dx, NOODLE_MIN_PATH_CURVE
	mov	es:[bx].N_pathCurve, dl
	mov	bp, offset pointsRange

	push	bx
	add	bx, offset N_points
	call	InitPoints
	pop	bx

	push	bx
	add	bx, offset N_increments
	mov	bp, offset incrementsRange
	call	InitPoints
	pop	bx

	add	bx, offset N_increments2
	mov	bp, offset increments2Range
	call	InitPoints

	.leave
	ret
InitNoodle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a set of 4 points based on a passed Range

CALLED BY:	InitNoodle

PASS:		es:[bx]	= points
		ds:[di] = NoodleApplicationInstance
		dgroup:[bp] = range

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version
	stevey	12/21/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitPoints	proc	near
	class	NoodleApplicationClass
	uses	bx,cx,dx,di,ds
	.enter

	xchg	di, bx		; es:[di] = points, ds:[bx] = instance
	mov	cx, 4
	mov	bx, ds:[bx].NAI_random

	segmov	ds, ss, dx	; ds = dgroup

initPoint:

IRP field, <P_x, P_y>
	mov	dx, ds:[bp].R_max.field
	call	SaverRandom
	tst	dl
	jnz	storeIt_&field
	inc	dl

storeIt_&field:
	mov	es:[di].field, dx
endm
	add	di, size Point
	loop	initPoint

	.leave
	ret
InitPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoodleAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw all the noodles

CALLED BY:	MSG_NOODLE_APP_DRAW

PASS:		*ds:si = NoodleApplication object
		ds:[di] = NoodleApplicationInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	For each noodle:

		I2 = (INDEX + 1) mod numEchoes
		if noodleTimerCount >= numEchoes
			erase noodle[I2]
		else
			increment noodleTimerCount
		Copy noodle[I] to noodle{I2] and recalculate new
		noodle at I2

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	I didn't have enough registers to do a straightforward
	port of his code, so I store all the NoodleApp instance
	data in idata variables in NoodleAppSetWin, so that he
	can access them easily here.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	4/91		Initial revision
	stevey	12/21/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoodleAppDraw	method	dynamic	NoodleApplicationClass,
					MSG_NOODLE_APP_DRAW

	push	ds:[LMBH_handle], si			; save OD

	tst	es:[curGState]
	LONG	jz	done

	mov	ds, es:[noodleBlockSegment]

	mov	al, es:[noodleVars].NV_index
	IncMod	al, es:[numLines]
	mov	es:[noodleVars].NV_index2, al

	mov	cl, es:[numNoodles]
	clr	ch
	clr	bp

startLoop:
	;
	; ES:BP - current noodle
	; See if need to erase old noodle	
	;
	mov	al, size CurveStruc
	mul	es:[noodleVars].NV_index2		; multiply by I2
	add	ax, offset N_points
	add	ax, bp
	mov	si, ax			; point to Points[I2]
	
	cmp	es:[noodleVars].NV_pastFirstRound, TRUE
	jne	afterErase

	;
	; erase old noodle (at I2)	
	;
	
	mov	al, C_BLACK
	call	NoodleDrawSpline

afterErase:
	;
	; Now, copy points at Index to I2
	;
	mov	di, si			; DS:DI = Points[I2]
	mov	al, size CurveStruc
	mul	es:[noodleVars].NV_index
	add	ax, offset N_points
	add	ax, bp
	mov	si, ax			; DS:SI = Points[I]
	push 	es, cx, di
	segmov	es, ds			; ES:DI = Points[I2]
	cld	

	;
	; Of course, this is a fucking hack:
	;

	mov	cx, size CurveStruc/2
	rep	movsw
	pop	es, cx, si		; (points[I2] now at DS:SI)

	;
	; Update and draw the new noodle
	;

	call	UpdateNoodleCurve
	mov	al, ds:[bp].N_color
	call	NoodleDrawSpline

	;
	; move on to next noodle
	;

	add	bp, size Noodle
	loop	startLoop

	;
	; Store I2 to I
	;

	mov	al, es:[noodleVars].NV_index2
	mov	es:[noodleVars].NV_index, al

	;
	; See if time to set "pastFirstRound"
	;

	inc	es:[noodleVars].NV_timer
	cmp	es:[noodleVars].NV_pastFirstRound, TRUE
	je	done
	
	;
	; If haven't passed first round, see if time to now:
	;

	mov	ax, es:[noodleVars].NV_timer
	cmp	al, es:[numLines]
	jl	done
	mov	es:[noodleVars].NV_pastFirstRound, TRUE

done:
	pop	bx, si
	call	MemDerefDS			; restore NoodleApp OD

	call	NoodleSetTimer

	ret
NoodleAppDraw	endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	UpdateNoodleCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the increments to the points in the current noodle
		Every time INDEX is zero, also add the increments2 to 
		the increments.

CALLED BY:	DrawOneNoodle

PASS:		ds:bp = current noodle
		ds:si = current set of noodle points

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNoodleCurve	proc	near	
	uses ax,bx,si,di,bp
	.enter

	mov	di, si
	lea	si, ds:[bp].N_increments

	push	bp
	mov	bp, offset pointsRange
	call	UpdatePoints
	pop	bp

	mov	ax, es:[noodleVars].NV_timer
	mov	bl, ds:[bp].N_pathCurve
	clr	bh
	add	bx, offset bitMasks
	andnf	al, es:[bx]
	tst	al
	jnz	done

	lea	di, ds:[bp].N_increments
	lea	si, ds:[bp].N_increments2

	mov	bp, offset incrementsRange
	call	UpdatePoints

done:
	.leave
	ret
UpdateNoodleCurve	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	UpdatePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upate the Point at ds:[di] by adding its values to those
		of the point in ds:[si].
		Make sure the new points lie within the range
		(ax, bx) (signed), otherwise negate the corresponding
		increment

CALLED BY:	NoodleAppDraw

PASS:		ds:[di] - set of 4 points to update
		ds:[si] - set of 4 increments 
		es:[bp] - Range

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePoints	proc	near	
	uses ax,bx,cx,dx,si,di
	.enter

	mov	cx, 4

startLoop:

	push	cx
	IRP field, <P_x, P_y >
	mov	cx, ds:[di].field
	add	cx, ds:[si].field
	cmp	cx, es:[bp].R_min.field
	jl	fixInc_&field		 ; too small?  fix the increment
	cmp	cx, es:[bp].R_max.field 	; too large?
	jg	fixInc_&field		; YES:  fix the increment
	mov	ds:[di].field, cx	; NO: store the value
	jmp	done_&field

fixInc_&field:
	neg	ds:[si].field

done_&field:
endm
	pop	cx
	add	si, size Point
	add	di, size Point
	loop	startLoop
	.leave
	ret

UpdatePoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoodleDrawSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the GrDrawSpline routine

CALLED BY:	NoodleAppDraw

PASS:		ds:si - bezier curve to draw
		es - dgroup
		al - color 

RETURN:		nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/12/91		Initial version.
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoodleDrawSpline	proc near	
	uses ax,cx,di
	.enter
	mov	di, es:[curGState]
	
	mov	ah, CF_INDEX
	call	GrSetLineColor

	mov	al, NOODLE_SPLINE_ACCURACY
	mov	cx, 4
	call	GrDrawSpline
	.leave
	ret
NoodleDrawSpline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoodleSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	NoodleAppSetWin, NoodleAppDraw

PASS:		*ds:si = NoodleApplication

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoodleSetTimer	proc	near
	class	NoodleApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].NoodleApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	clr	ch
	mov	cl, ds:[di].NAI_speed
	mov	dx, MSG_NOODLE_APP_DRAW
	mov	bx, ds:[LMBH_handle]
	call	TimerStart

	mov	ds:[di].NAI_timerHandle, bx
	mov	ds:[di].NAI_timerID, ax

	.leave
	ret
NoodleSetTimer	endp

NoodleCode	ends

