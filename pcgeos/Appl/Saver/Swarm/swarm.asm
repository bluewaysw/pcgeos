COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Swarm
FILE:		swarm.asm

AUTHOR:		John & Adam, Mar  25, 1991

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	j&a	3/23/91		Initial revision
	jim	3/29/90		Basically did a global replace qix -> swarm
				(well, a little more ;)
	stevey	12/14/92	port to 2.0

DESCRIPTION:
	This is a specific screen-saver library to move a Swarm around on the
	screen.

	$Id: swarm.asm,v 1.1 97/04/04 16:47:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def

include	swarm.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

SwarmApplicationClass	class	SaverApplicationClass

MSG_SWARM_APP_DRAW				message
;
;	Draw the next state of the swarm.  Sent by the timer.
;
;	Pass:	nothing
;	Return:	nothing
;

	SAI_numBees		word	SWARM_DEFAULT_BEES
	SAI_numWasps 		word	SWARM_DEFAULT_WASPS
	SAI_color 		byte	SC_MONO
	SAI_speed		word	SWARM_MEDIUM_SPEED
	SAI_clear	 	byte	FALSE
	SAI_swarmLength		word	SWARM_MAX_POINTS

	SAI_timerHandle	hptr		0
    		noreloc	SAI_timerHandle
	SAI_timerID		word	0

	SAI_random		hptr	0	; Random number generator
		noreloc	SAI_random
	SAI_swarmHan		hptr.SwarmStruct	0
		noreloc SAI_swarmHan

SwarmApplicationClass	endc

SwarmProcessClass	class	GenProcessClass
SwarmProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	swarm.rdef
ForceRef SwarmApp

udata	segment

udata	ends

idata	segment
idata	ends

SwarmClassStructures	segment	resource
SwarmApplicationClass	
SwarmProcessClass	mask	CLASSF_NEVER_SAVED
SwarmClassStructures	ends


SwarmCode	segment resource

.warn -private
swarmOptionTable	SAOptionTable	<
	swarmCategory, length swarmOptions
>
swarmOptions	SAOptionDesc	<
	swarmNumBeesKey, size SAI_numBees, offset SAI_numBees
>, <
	swarmNumWaspsKey, size SAI_numWasps, offset SAI_numWasps
>, <
	swarmColorKey, size SAI_color, offset SAI_color
>, <
	swarmSpeedKey, size SAI_speed, offset SAI_speed
>, <
	swarmClearKey, size SAI_clear, offset SAI_clear
>, <
	swarmLengthKey, size SAI_swarmLength, offset SAI_swarmLength
>
.warn @private
swarmCategory		char	'swarm', 0
swarmNumBeesKey		char	'numBees', 0
swarmNumWaspsKey	char	'numWasps', 0
swarmColorKey		char	'color', 0
swarmSpeedKey		char	'speed', 0
swarmClearKey		char	'clear', 0
swarmLengthKey		char	'length', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= SwarmApplicationClass object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwarmLoadOptions	method dynamic SwarmApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs
	mov	bx, offset swarmOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset SwarmApplicationClass
	GOTO	ObjCallSuperNoLock
SwarmLoadOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if we're clearing the screen or not.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= SwarmApplicationClass object
		ds:di	= SwarmApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwarmAppGetWinColor	method dynamic SwarmApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thang.
	;

	mov	di, offset SwarmApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].SwarmApplication_offset

	cmp	ds:[di].SAI_clear, TRUE
	je	done

	ornf	ah, mask WCF_TRANSPARENT

done:
	ret
SwarmAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= SwarmApplicationClass object
		ds:di	= SwarmApplicationClass instance data
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwarmAppSetWin	method dynamic SwarmApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	.enter
	;
	; Let the superclass do its little thing.
	; 

	mov	di, offset SwarmApplicationClass
	call	ObjCallSuperNoLock

;	Allocate a bunch of memory to hold the swarm data

	mov	ax, size SwarmStruct
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es, ax
	mov	es:[SS_blockHan], bx

	;
	; Now initialize our state.
	; 

	mov	di, ds:[si]
	add	di, ds:[di].SwarmApplication_offset
	mov	ds:[di].SAI_swarmHan, bx

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx			; dxax <- seed
	clr	bx			; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].SAI_random, bx

	clr	ah
	mov	al, ds:[di].SAI_color
	mov	es:[SS_color], ax	; keep it in dgroup (believe me)

	mov	ax, ds:[di].SAI_swarmLength
	mov	es:[SS_swarmLength], ax	; keep it in dgroup (believe me)

	push	si
	call	SwarmInit
	mov	si, es:[SS_curPos] 
	shl	si
	shl	si
	mov	bp, si
	call	DrawWaspAndBees

	pop	si			; *ds:si = SwarmApplication object
	call	SwarmSetTimer
	
	mov	bx, es:[SS_blockHan]
	call	MemUnlock

	.leave
	ret
SwarmAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quit saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= SwarmApplicationClass object
		ds:di	= SwarmApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwarmAppUnsetWin	method dynamic SwarmApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	;  Stop the draw timer.
	;

	clr	bx
	xchg	bx, ds:[di].SAI_timerHandle
	mov	ax, ds:[di].SAI_timerID
	call	TimerStop

	;
	; Free the me
	;
	clr	bx
	xchg	bx, ds:[di].SAI_swarmHan
	call	MemFree

	;
	;  Nuke the random number generator
	;

	clr	bx
	xchg	bx, ds:[di].SAI_random
	call	SaverEndRandom

	;
	;  Call our superclass.
	;

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset SwarmApplicationClass
	GOTO	ObjCallSuperNoLock
SwarmAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBzzzStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes a BzzzStruct

CALLED BY:	GLOBAL
PASS:		bx - velocity (both X & Y)
		dx - Y pos
		ax - X pos
		es:bp - ptr to BzzzStruct
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitBzzzStruct	proc	near	uses	bp, cx
	.enter
	mov	es:[bp].BS_vel.XYO_x, bx
	mov	es:[bp].BS_vel.XYO_y, bx

CheckHack<	offset BS_points eq 0>
;	Loop through all the points, and store the initial X/Y position there.

	mov	cx, SWARM_MAX_POINTS
initLoop:
	mov	es:[bp].P_x, ax
	mov	es:[bp].P_y, dx
	add	bp, size Point
	loop	initLoop
	.leave
	ret
InitBzzzStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	Generic screen saver library

PASS:		*ds:si	= SwarmApplication object
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version
	stevey	12/15/92	port to 2.0
	atw	1/24/94		Added code to allow trails

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwarmInit	proc	near
	class	SwarmApplicationClass
	uses	ax,bx,cx,dx,bp,ds
	.enter

	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left		; dx = width
	mov	es:[SS_width], dx

	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top		; dx = height
	mov	es:[SS_height], dx


	;
	; Fetch the number of bees the user wants us to draw.
	;

	mov	ax, ds:[di].SAI_numBees
	mov	es:[SS_nbees], ax
	mov	ax, ds:[di].SAI_numWasps
	mov	es:[SS_nwasps], ax

	mov	bp, ds:[di].SAI_curGState
	xchg	di, bp
	mov	al, CMT_DITHER
	call	GrSetLineColorMap
	xchg	di, bp					; ds:[di] = instance

	;
	; init position, velocity of wasps
	;

	mov	cx, es:[SS_nwasps]
	lea	bp, es:[SS_wasp]	;ES:BP <- ptr to wasp we are initing

waspLoop:
	mov	dx, 255			; take maximum
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	add	dx, SWARM_BORDER
	push	dx	
	mov	dx, es:[SS_height] 	; get height of screen
	sub	dx, SWARM_BORDER*2
	cmp	dx, 255				; needs to be less than 1 byte
	jb	haveSeed
	mov	dx, 255

haveSeed:
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	add	dx, SWARM_BORDER
	pop	ax
	clr	bx
	call	InitBzzzStruct
	add	bp, size BzzzStruct
	loop	waspLoop
	clr	es:[SS_curPos]

	; now do the same for the bees

	mov	cx, es:[SS_nbees]		; get # to init
	mov	bp, offset es:[SS_bees]		;ES:BP <- ptr to BzzzStruct to
						; initialize
beeLoop:
	mov	dx, 255
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	shl	dx, 1
	shl	dx, 1				; get # between 0 and 1024
tryXagain:
	cmp	dx, es:[SS_width]
	jb	haveX
	sub	dx, es:[SS_width]
	jmp	tryXagain
haveX:
	push	dx
	mov	dx, 255
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	shl	dx, 1
	shl	dx, 1				; get # between 0 and 1024
tryYagain:
	cmp	dx, es:[SS_height]
	jb	haveY
	sub	dx, es:[SS_height]
	jmp	tryYagain
haveY:
	push	dx

	mov	dx, 7
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	mov	bx, dx
	pop	dx
	pop	ax
	call	InitBzzzStruct
	add	bp, size BzzzStruct
	loop	beeLoop

	.leave
	ret
SwarmInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next Swarm.

CALLED BY:	MSG_SWARM_APP_DRAW

PASS:		*ds:si	= SwarmApplication object
		es	= dgroup

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
	jim	3/91		Initial version
	stevey	12/15/92	port to 2.0
	atw	1/24/94		Added code to allow trails

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwarmAppDraw	method	dynamic	SwarmApplicationClass, 
					MSG_SWARM_APP_DRAW
	.enter

	mov	bx, ds:[di].SAI_swarmHan
	tst	bx
	jnz	lockSwarmHan
toQuit:
	jmp	quit
lockSwarmHan:
	call	MemLock
	mov	es, ax
	tst	ds:[di].SAI_curGState
	jz	toQuit

	push	si				; save object chunk


	; age the arrays

updateCoords::
	mov	cx, es:[SS_nwasps]
	clr	bp
	mov	si, es:[SS_curPos]
	shl	si, 1
	shl	si, 1
	dec	es:[SS_curPos]
	jns	waspLoop
	mov	ax, es:[SS_swarmLength]
	dec	ax
	mov	es:[SS_curPos], ax
waspLoop:

;	SI <- offset of previous was position in array of positions.
;
;	Loop through each wasp, and make the new velocity be the old velocity
;	+ some random amount, and make the new position be the old position
;	incorporating the new velocity.

	mov	dx, SWARM_WASP_ACCEL
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	sub	dx, SWARM_WASP_ACCEL/2
	add	dx, es:[SS_wasp][bp].BS_vel.XYO_x
	CheckVelocity dx, SWARM_WASP_VELOCITY
	mov	es:[SS_wasp][bp].BS_vel.XYO_x, dx

CheckHack <size Point eq 4>

	add	dx, es:[SS_wasp][bp].BS_points[si].P_x
	cmp	dx, SWARM_BORDER
	jb	bounceX
	mov	ax, es:[SS_width]
	sub	ax, SWARM_BORDER+1
	cmp	dx, ax
	jb	saveX

bounceX:
	neg	es:[SS_wasp][bp].BS_vel.XYO_x
	add	dx, es:[SS_wasp][bp].BS_vel.XYO_x
saveX:
	push	dx

	mov	dx, SWARM_WASP_ACCEL
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	sub	dx, SWARM_WASP_ACCEL/2
	add	dx, es:[SS_wasp][bp].BS_vel.XYO_y
	CheckVelocity dx, SWARM_WASP_VELOCITY
	mov	es:[SS_wasp][bp].BS_vel.XYO_y, dx
	add	dx, es:[SS_wasp][bp].BS_points[si].P_y
	cmp	dx, SWARM_BORDER
	jb	bounceY
	mov	ax, es:[SS_height]
	sub	ax, SWARM_BORDER+1
	cmp	dx, ax
	jb	saveY

bounceY:
	neg	es:[SS_wasp][bp].BS_vel.XYO_y
	add	dx, es:[SS_wasp][bp].BS_vel.XYO_y

saveY:
	pop	ax			;X offset of new wasp position

	push	si			;Save offset of previous wasp position
	mov	si, es:[SS_curPos]	;SI <- offset to current wasp position
	shl	si, 1			; in array of positions
	shl	si, 1

;	Update the current point in the point array

	mov	es:[SS_wasp][bp].BS_points[si].P_x, ax
	mov	es:[SS_wasp][bp].BS_points[si].P_y, dx
	pop	si		        ;Restore ptr to previous wasp position

	add	bp, size BzzzStruct
	dec	cx
	jcxz	shakeBees
	jmp	waspLoop

shakeBees:
	;
	; shake up the bees.  Don't do this if there's only one bee,
	; as it causes the bee to get lost, and eventually crashes
	; with a divide overflow.
	;
	mov	dx, es:[SS_nbees]	; pick a random bee
	cmp	dx, 1
	je	updateBees
	
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	mov	ax, size BzzzStruct
	mul	dl
	mov_tr	bp, ax
	mov	dx, 4
	call	SaverRandom
	add	es:[SS_bees][bp].BS_vel.XYO_x, dx
	mov	dx, es:[SS_nbees]	; pick a random bee
	call	SaverRandom
	mov	ax, size BzzzStruct
	mul	dl
	mov_tr	bp, ax
	mov	dx, 4
	call	SaverRandom
	add	es:[SS_bees][bp].BS_vel.XYO_y, dx

	;
	; update all the bee positions
	;
updateBees:
	mov	cx, es:[SS_nbees]
	clr	bp
	push	di

beeLoop:
	; SI <- offset into point array of previous (most recent) point
	; curPos = offset into point array of point we are adding.

	push	cx
	call	FindWaspLeader				; bx = wasp
	
	mov	ax, es:[SS_wasp][bx].BS_points[si].P_x
	mov	cx, es:[SS_wasp][bx].BS_points[si].P_y
	
	sub	ax, es:[SS_bees][bp].BS_points[si].P_x	; ax = dx
	sub	cx, es:[SS_bees][bp].BS_points[si].P_y	; cx = dy
	CalcDistance ax, cx, bx	;AX = waspXPos-beeXPos
				;CX = waspYPos-beeYPos
				;BX = AX+CX (not true distance, which is why 
				; the bees always overshoot the wasp instead
				; of landing on it)

	mov	di, SWARM_BEE_ACCEL
	imul	di
	idiv	bx		;
	add	ax, es:[SS_bees][bp].BS_vel.XYO_x
	CheckVelocity	ax, SWARM_BEE_VELOCITY
	mov	es:[SS_bees][bp].BS_vel.XYO_x, ax

	push	ax		;AX <- new X velocity
	mov	ax, SWARM_BEE_ACCEL
	imul	cx
	idiv	bx
	add	ax, es:[SS_bees][bp].BS_vel.XYO_y
	CheckVelocity	ax, SWARM_BEE_VELOCITY
	mov	es:[SS_bees][bp].BS_vel.XYO_y, ax

	pop	cx		;CX <- new X velocity
				;AX <- new Y velocity
	push	si
	add	cx, es:[SS_bees][bp].BS_points[si].P_x
	add	ax, es:[SS_bees][bp].BS_points[si].P_y
	mov	si, es:[SS_curPos]
	shl	si
	shl	si
	mov	es:[SS_bees][bp].BS_points[si].P_x, cx
	mov	es:[SS_bees][bp].BS_points[si].P_y, ax
	pop	si			
	add	bp, size BzzzStruct

	pop	cx
	dec	cx
	tst	cx
	LONG	jnz	beeLoop		; loop instruction was out of range

	pop	di
		
	; Draw new bees

	mov	bp, es:[SS_curPos]
	shl	bp
	shl	bp			;BP <- offset of current point
					;SI <- offset of prev point
	call	DrawWaspAndBees

	; Erase the old bees
	push	es:[SS_color]
	mov	es:[SS_color], SC_ERASE

	mov	si, es:[SS_curPos]
	dec	si
	jns	80$
	mov	si, es:[SS_swarmLength]
	dec	si
80$:
	mov	bp, si
	dec	si
	jns	90$
	mov	si, es:[SS_swarmLength]
	dec	si
90$:
	shl	bp			;BP <- offset of last point in arrary
	shl	bp
	shl	si			;SI <- offset of next-to-last pt in 
	shl	si			; array
	call	DrawWaspAndBees
	pop	es:[SS_color]
	pop	si			; *ds:si = SwarmApplication
	call	SwarmSetTimer		; for next time
	mov	bx, es:[SS_blockHan]
	call	MemUnlock
quit:
	.leave
	ret
SwarmAppDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindWaspLeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given bee offset "bp" return closest wasp offset "si"

CALLED BY:	SwarmAppDraw

PASS:		bp = bee
		si = offset into point array

RETURN:		bx = closest wasp

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	Jim	3/91			Initial version
	stevey	12/15/92		port to 2.0
	atw	1/24/94		Added code to allow trails

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindWaspLeader	proc	near
	uses	ax,si,cx,dx,di
	.enter

	; if only one wasp, there's no contest

	clr	bx
	mov	di, bx
	mov	dx, 0xffff			; init to a big number
	mov	cx, es:[SS_nwasps]

waspLoop:
	push	cx
	mov	ax, es:[SS_wasp][bx][si].BS_points.P_x
	sub	ax, es:[SS_bees][bp][si].BS_points.P_x	; ax = dx
	mov	cx, es:[SS_wasp][bx][si].BS_points.P_y
	sub	cx, es:[SS_bees][bp][si].BS_points.P_y	; cx = dy
	CalcDistance ax, cx, ax
	cmp	ax, dx					; see if closer
	ja	nextWasp
	mov	dx, ax
	mov	di, bx

nextWasp:
	pop	cx
	add	bx, size BzzzStruct
	loop	waspLoop
	mov	bx, di				; restore closest

done::
		.leave
		ret
FindWaspLeader	endp


waspColors	byte	C_WHITE		; Mono
		byte	C_WHITE		; Rainbow
		byte	C_YELLOW	; Primary
		byte	C_YELLOW	; Blue&Gold
		byte	C_BLACK		; Erase
.assert	$-waspColors	eq	SwarmColor

colorTableList	nptr	MonoTable
		nptr	RainbowTable
		nptr	PrimaryTable
		nptr	BlueGoldTable
		nptr	EraseTable

.assert	$-colorTableList	eq	SwarmColor*2

;
;	Null-terminated table of color sequences
;

MonoTable	byte	C_WHITE
		byte	0

RainbowTable	byte	C_LIGHT_GREEN 	
;		byte	C_BLUE		ALL DARK COLORS TAKEN OUT
;		byte	C_GREEN 	
;		byte	C_CYAN 	
;		byte	C_RED 		
;		byte	C_VIOLET 	
;		byte	C_BROWN 		
;		byte	C_LIGHT_GRAY 	
;		byte	C_DARK_GRAY 	
		byte	C_LIGHT_CYAN 	
		byte	C_LIGHT_VIOLET 	
		byte	C_YELLOW 
PrimaryTable	byte	C_LIGHT_RED
BlueGoldTable	byte	C_LIGHT_BLUE
		byte	0
EraseTable	byte	-1
		byte	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawWaspAndBees
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw them all

CALLED BY:	SwarmAppSetWin, SwarmAppDraw

PASS:		ds:[di] = SwarmApplicationInstance
		si	= index of first point
		bp	= index of 2nd point
		es 	= segment of SwarmStruct

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		stevey	12/15/92	port to 2.0
	atw	1/24/94		Added code to allow trails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawWaspAndBees	proc	near
	class	SwarmApplicationClass
	uses	di
	.enter

	mov	di, ds:[di].SAI_curGState

	;
	; first draw the wasp in the appropriate color
	;

	mov	bx, es:[SS_color]
	clr	ax
	mov	al, cs:[bx][waspColors]
	cmp	al, -1
	jne	5$
	mov	al, C_BLACK

5$:
	mov	es:[SS_lastColor], al
	call	GrSetLineColor
	mov	cx, es:[SS_nwasps]
	push	si, bp

waspLoop:
	push	cx
	mov	ax, es:[SS_wasp][si].BS_points.P_x
	mov	bx, es:[SS_wasp][si].BS_points.P_y
	mov	cx, es:[SS_wasp][bp].BS_points.P_x
	mov	dx, es:[SS_wasp][bp].BS_points.P_y
	call	GrDrawLine

	pop	cx
	add	si, size BzzzStruct
	add	bp, size BzzzStruct
	loop	waspLoop
	pop	si, bp
		
	;
	; next, cycle through all the bees
	;

	mov	cx, es:[SS_nbees]

resetBeeColor:
	mov	bx, es:[SS_color]
	shl	bx, 1
	mov	bx, cs:[colorTableList][bx]	;CS:BP <- ptr to list
							; of colors
beeLoop:
	clr	ax
	mov	al, cs:[bx]
	tst	al				;If at end of table,
	jz	resetBeeColor			; go back to start.
	cmp	al, -1
	jnz	7$
	mov	al, C_BLACK
7$:
	cmp	al, es:[SS_lastColor]
	jz	drawBee

setColor::
	call	GrSetLineColor
drawBee:
	push	cx, bx
	mov	ax, es:[SS_bees][si].BS_points.P_x
	mov	bx, es:[SS_bees][si].BS_points.P_y
	mov	cx, es:[SS_bees][bp].BS_points.P_x
	mov	dx, es:[SS_bees][bp].BS_points.P_y
	call	GrDrawLine

	add	si, size BzzzStruct
	add	bp, size BzzzStruct
	pop	cx, bx
	inc	bx
	loop	beeLoop

	.leave
	ret
DrawWaspAndBees	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the one-shot timer

CALLED BY:	SwarmAppSetWin, SwarmAppDraw

PASS:		*ds:si	= SwarmApplication object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/19/91		Initial version.
	stevey	12/15/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwarmSetTimer	proc near	
	class	SwarmApplicationClass
	uses ax,bx,cx,dx
	.enter

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[di].SAI_speed
	mov	dx, MSG_SWARM_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination
	
	call	TimerStart
	mov	ds:[di].SAI_timerHandle, bx
	mov	ds:[di].SAI_timerID, ax

	.leave
	ret
SwarmSetTimer	endp

SwarmCode	ends
