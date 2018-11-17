COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Hopalong
FILE:		hopalong.asm

AUTHOR:		Jeremy Dashe, April 2nd, '91

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	3/23/91		Initial revision

DESCRIPTION:

	This is a specific screen-saver library ("Hopalong").

	$Id: hopalong.asm,v 1.1 97/04/04 16:45:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include	timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def
UseLib	math.def

include	hopalong.def

HopalongApplicationClass	class	SaverApplicationClass

MSG_HOPALONG_APP_DRAW			message
;
;	Pass: nothing
;	Return: nothing
;

	WAI_numColors	word	HOPALONG_DEFAULT_NUMBER_OF_COLORS
	WAI_iterations	word	HOPALONG_DEFAULT_ITERATIONS
	WAI_speed	word	HOPALONG_DEFAULT_SPEED
	WAI_clear	byte	TRUE

	WAI_timerHandle	hptr	0
		noreloc	WAI_timerHandle
	WAI_timerID	word
	WAI_random	hptr	0
		noreloc	WAI_random

HopalongApplicationClass	endc

HopalongProcessClass	class	GenProcessClass
HopalongProcessClass	endc

;=============================================================================
;
;				VARIABLES
;
;=============================================================================

include	hopalong.rdef
ForceRef HopalongApp

udata	segment

aValue		sword
bValue		sword
cValue		sword
xPoint		WWFixed
yPoint		WWFixed
newXPoint	WWFixed
hopCounter	word
curColor	byte
xOrigin		word
yOrigin		word

udata	ends

idata	segment

HopalongProcessClass	mask CLASSF_NEVER_SAVED
HopalongApplicationClass

hopColorTable	byte	\
	C_LIGHT_RED,
	C_BLUE,
	C_YELLOW,
	0

idata	ends

HopalongCode	segment resource

.warn -private
hopalongOptionTable	SAOptionTable	<
	hopalongCategory, length hopalongOptions
>
hopalongOptions	SAOptionDesc	<
	hopalongNumHopalongKey, size WAI_numColors, offset WAI_numColors
>, <
	hopalongLengthKey, size WAI_iterations, offset WAI_iterations
>, <
	hopalongSpeedKey, size WAI_speed, offset WAI_speed
>, <
	hopalongClearKey, size WAI_clear, offset WAI_clear
>

.warn @private
hopalongCategory		char	'hopalong', 0
hopalongNumHopalongKey	char	'numColors', 0
hopalongLengthKey		char	'iterations', 0
hopalongClearKey		char	'clear', 0
hopalongSpeedKey		char	'speed', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopalongLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= HopalongApplicationClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version
	dloft	2/11/94		converted to hopalong
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopalongLoadOptions	method dynamic HopalongApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	es
	.enter

	segmov	es, cs
	mov	bx, offset hopalongOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset HopalongApplicationClass
	GOTO	ObjCallSuperNoLock
HopalongLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopalongAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use, and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= HopalongApplicationClass object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version
	dloft	2/11/94		converted to hopalong
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopalongAppSetWin	method dynamic HopalongApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset HopalongApplicationClass
	call	ObjCallSuperNoLock

	;
	; Now initialize our state. 
	;
 
	mov	di, ds:[si]
	add	di, ds:[di].HopalongApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx				; dxax <- seed
	clr	bx				; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].WAI_random, bx

	;
	; Now initialize the variables and set the timer.
	;

	call	HopalongStart

	ret
HopalongAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopalongAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= HopalongApplicationClass object
		ds:di	= HopalongApplicationClass instance data

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version
	dloft	2/11/94		converted to hopalong
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopalongAppUnsetWin	method dynamic HopalongApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	;

	clr	bx
	xchg	bx, ds:[di].WAI_timerHandle
	mov	ax, ds:[di].WAI_timerID
	call	TimerStop

	;
	; Nuke the random number generator.
	;

	clr	bx
	xchg	bx, ds:[di].WAI_random
	call	SaverEndRandom

	;
	; Call our superclass to take care of the rest.
	;

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset HopalongApplicationClass
	GOTO	ObjCallSuperNoLock
HopalongAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopalongAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide whether to clear the screen or not.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= HopalongApplicationClass object
		ds:di	= HopalongApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopalongAppGetWinColor	method dynamic HopalongApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thing.
	;

	mov	di, offset HopalongApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].HopalongApplication_offset

	cmp	ds:[di].WAI_clear, TRUE
	je	done

	ornf	ah, mask WCF_TRANSPARENT
done:
	ret
HopalongAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopalongStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up our function constants and init variables.

CALLED BY:	HopalongAppSetWin

PASS:		*ds:si	= HopalongApplication object
		ds:di	= HopalongApplication instance data
		es	= dgroup

RETURN:		nothing
DESTROYED:	something

PSEUDO CODE/STRATEGY:
		heuristic for adjusting origin:

		* origin seems somehow related to size and sign of a -- try
		dividing a by 4 and adding to both x and y origins.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	2/11/94		Initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopalongStart	proc	near
	class	HopalongApplicationClass

	;
	; Setup a, b, c, x, y, counter
	;
		mov	bx, ds:[di].WAI_random

		mov	dx, RANDOM_B_MAX
		call	SaverRandom
		sub	dx, (RANDOM_B_MAX / 2)		; de-normalize
		mov	es:[bValue], dx

		mov	dx, RANDOM_C_MAX
		call	SaverRandom
		sub	dx, (RANDOM_C_MAX / 2)		; de-normalize
		mov	es:[cValue], dx

		mov	dx, RANDOM_A_MAX
		call	SaverRandom
		sub	dx, (RANDOM_A_MAX / 2)		; de-normalize
		mov	es:[aValue], dx

		sar	dx
		sar	dx				; amount to adjust
		neg	dx				; origin

		clrwwf	es:[xPoint]
		clrwwf	es:[yPoint]
		clrwwf	es:[newXPoint]
		mov	es:[xOrigin], 320
		add	es:[xOrigin], dx
		mov	es:[yOrigin], 200
		add	es:[yOrigin], dx
		mov	es:[hopCounter], 1

	;
	; Set the timer.
	;
		call	HopalongSetTimer
		ret
HopalongStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopalongAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next point

CALLED BY:	MSG_HOPALONG_APP_DRAW

PASS:		*ds:si	= HopalongApplication object
		ds:di	= HopalongApplication instance data
		es	= dgroup

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/25/91		Initial version
	jeremy	4/2/91		confounded with worms
	stevey	12/16/92	port to 2.0
	dloft	2/11/94		converted to hopalong
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopalongAppDraw	method	dynamic	HopalongApplicationClass,
						MSG_HOPALONG_APP_DRAW
		.enter

		tst	ds:[di].SAI_curGState
		LONG	jz	quit
	
		push	ds, si			; save object

		mov	cx, ds:[di].WAI_iterations
		clr	si

		mov	bx, ds:[di].WAI_random
		mov	di, ds:[di].SAI_curGState
		segmov	ds, es			; dgroup
resetColor:
		mov	si, offset hopColorTable; color index ptr
plotPoint:
	;
	; Change the current color
	;
		lodsb				; get color
		tst	al
		jz	resetColor		; reset if off end
changeIt:
		mov	ah, CF_INDEX
		call	GrSetAreaColor

drawThePoint:
		mov	ax, es:[xPoint].WWF_int
		mov	bx, es:[yPoint].WWF_int
		add	ax, es:[xOrigin]
		add	bx, es:[yOrigin]
		call	GrDrawPoint

		call	HopalongCalculateNewPoint

		loop	plotPoint	
	;	inc	es:[hopCounter]
done:
		pop	ds, si			; restore object

		call	HopalongSetTimer	; setup another timer
quit:
		.leave
		ret
HopalongAppDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopalongCalculateNewPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate new values for xPoint and yPoint

CALLED BY:	INT (HopalongAppDraw)
PASS:		es	= dgroup
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	es:[yPoint], es:[xPoint] modified

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	2/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopalongCalculateNewPoint		proc	near
	uses	ax, bx, cx, dx
		.enter


		movwwf	dxcx, es:[xPoint]
		mov	bx, es:[bValue]
;		mov	ax, -1			; assume bx is negative
;		tst	bx, ax
;		js	okay			; bx was negative
		clr	ax
okay:
		call	GrMulWWFixed		; dx:cx = b*x

		mov	bx, es:[cValue]		; bx clear
		subwwf	dxcx, bxax		; dx:cx = b*x-c
		tst	dx
		jns	haveAbs
		negwwf	dxcx			; dx:cx = abs(b*x-c)
haveAbs:
		call	GrSqrRootWWFixed	; dx:cx = [abs(b*x-c)]^1/2

		jlwwf	es:[xPoint], 0, negativeXValue, ax
						; sign(x)
		negwwf	dxcx			; dx:cx = -[abs(b*x-c)]^1/2
negativeXValue:
		movwwf	bxax, es:[yPoint]
		addwwf	bxax, dxcx		; done!
						; bxax = new X Value
		movwwf	dxcx, es:[xPoint]	; old x value
		movwwf	es:[xPoint], bxax

		mov	bx, es:[aValue]
		clr	ax
		subwwf	bxax, dxcx

		movwwf	es:[yPoint], bxax	; y = a - x



if 0
		mov	bx, es:[yPoint]

		mov	ax, es:[xPoint]
		call 	FloatWordToFloat	; pushes old x value
						; in ax
		mov	ax, es:[bValue]
		call	FloatWordToFloat

		call	FloatMultiply		; performs b*x

		mov	ax, es:[cValue]
		call	FloatWordToFloat	; push c

		call	FloatSub		; b*x-c

		call	FloatAbs		; abs(b*x-c)

		call	FloatSqrt		; [abs(b*x-c)]^(1/2)

		mov	ax, es:[yPoint]

		cmp	es:[xPoint], 0
		jl	negativeXValue
		call	FloatNegate		; -[abs(b*x-c)]^(1/2)
negativeXValue:
		mov	ax, es:[yPoint]
		call	FloatWordToFloat
		call	FloatAdd
	
		call	FloatFloatToDword	; dx:ax <- new x value
	
		mov	es:[newXPoint], ax

		mov	ax, es:[aValue]		; y <- a - x
		sub	ax, es:[xPoint]
		mov	es:[yPoint], ax

		mov	ax, es:[newXPoint]
		mov	es:[xPoint], ax
endif


		.leave
		ret
HopalongCalculateNewPoint		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HopalongSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer

CALLED BY:	HopalongStart, HopalongDraw

PASS:		*ds:si = HopalongApplication object

RETURN:		nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/19/91		Initial version.
	stevey	12/15/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HopalongSetTimer	proc near
	class	HopalongApplicationClass
	uses ax,bx,cx,dx,di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].HopalongApplication_offset

	mov	cx, ds:[di].WAI_speed
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	dx, MSG_HOPALONG_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si <- destination
	call	TimerStart

	mov	ds:[di].WAI_timerHandle, bx
	mov	ds:[di].WAI_timerID, ax

	.leave
	ret
HopalongSetTimer	endp


HopalongCode	ends
