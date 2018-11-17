COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Qix
FILE:		qix.asm

AUTHOR:		John & Adam, Mar  25, 1991

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	j&a	3/23/91		Initial revision

DESCRIPTION:
	This is a specific screen-saver library to move a Qix around on the
	screen.
	
	$Id: qix.asm,v 1.1 97/04/04 16:46:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def

include	qix.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

QixApplicationClass	class	SaverApplicationClass

MSG_QIX_APP_DRAW				message
;
;	Draw the next line of the qix. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    QAI_numLines	word		QIX_DEFAULT_LINES
    QAI_doColor		BooleanByte	BB_FALSE
    QAI_object		QixObjectType	QOT_LINES
    QAI_speed		word		QIX_MEDIUM_SPEED
    QAI_numQixes	word		QIX_DEFAULT_QIXES

    QAI_timerHandle	hptr		0
    	noreloc	QAI_timerHandle
    QAI_timerID		word

    QAI_qixes		lptr.QixStruct	0	; array of structures describing
						;  the qixes we move around.
						;  Only allocated when saving.

    QAI_random		hptr		0	; Random number generator
						;  we use
	noreloc	QAI_random

QixApplicationClass	endc

QixProcessClass	class	GenProcessClass
QixProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	qix.rdef
ForceRef QixApp

udata	segment

udata	ends

idata	segment

QixProcessClass	mask CLASSF_NEVER_SAVED
QixApplicationClass

idata	ends

QixCode	segment resource

.warn -private
qixOptionTable	SAOptionTable	<
	qixCategory, length qixOptions
>
qixOptions	SAOptionDesc	<
	qixNumLinesKey,	size QAI_numLines, offset QAI_numLines
>, <
	qixDoColorKey, size QAI_doColor, offset QAI_doColor
>, <
	qixObjectKey, size QAI_object, offset QAI_object
>, <
	qixSpeedKey, size QAI_speed, offset QAI_speed
>, <
	qixNumQixesKey, size QAI_numQixes, offset QAI_numQixes
>
.warn @private
qixCategory	char	'qix', 0
qixNumLinesKey	char	'numLines', 0
qixDoColorKey	char	'doColor', 0
qixObjectKey	char	'object', 0
qixSpeedKey	char	'speed', 0
qixNumQixesKey	char	'numQixes', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QixLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= QixApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QixLoadOptions	method	dynamic	QixApplicationClass, 
					MSG_META_LOAD_OPTIONS
		uses	ax, es
		.enter

		segmov	es, cs
		mov	bx, offset qixOptionTable
		call	SaverApplicationGetOptions

		.leave
		mov	di, offset QixApplicationClass
		GOTO	ObjCallSuperNoLock
QixLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QixInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a single Qix

CALLED BY:	QixStart

PASS:		ax	= qix number
		*ds:si	= QixApplication object
		ds:bx	= QixApplicationInstance
		ds:di	= Qix to initialize
		SAI_bounds, QAI_random set

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QixInit		proc	near
		class	QixApplicationClass
		uses	ax, dx, cx, es, si
		.enter

		mov	ds:[di].QS_qixNum, al

		mov	ax, SVRT_RANDOM
		clr	cx

		push	bx
		segmov	es, ds

	;
	; First the vertical vectors.
	; 
		mov	cx, ds:[bx].SAI_bounds.R_top
		mov	dx, ds:[bx].SAI_bounds.R_bottom
		mov	si, ds:[bx].QAI_random

		mov	bx, (QIX_DELTA_BASE shl 8) or QIX_DELTA_MAX

		add	di, offset QS_y1
		call	SaverVectorInit

		add	di, offset QS_y2 - offset QS_y1
		call	SaverVectorInit
	
	;
	; Then the horizontal vectors.
	; 
		pop	bx
		push	bx
		mov	cx, ds:[bx].SAI_bounds.R_left
		mov	dx, ds:[bx].SAI_bounds.R_right
		mov	bx, (QIX_DELTA_BASE shl 8) or QIX_DELTA_MAX

		add	di, offset QS_x1 - offset QS_y2
		call	SaverVectorInit

		add	di, offset QS_x2 - offset QS_x1
		call	SaverVectorInit

		pop	bx
		sub	di, offset QS_x2

	;
	; Fetch the number of lines the user wants us to draw.
	;
		mov	ax, ds:[bx].QAI_numLines
		mov	ds:[di].QS_nlines, ax
	;
	; Use that to figure the total size of the line queue we maintain
	;
		mov	dx, size QixLine
		mul	dx
		mov	ds:[di].QS_queueSize, ax
	;
	; Initialize the queue tail and head pointers
	;
		mov	ds:[di].QS_last, 0
		mov	ds:[di].QS_first, 0
	;
	; First line is always drawn white, so we can more easily handle b&w
	; Qixes
	;
		mov	ds:[di].QS_lineq.QL_color, C_WHITE
		mov	ds:[di].QS_pixel, C_WHITE

		.leave
		ret
QixInit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QASetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= QixApplication object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QASetWin	method dynamic QixApplicationClass, MSG_SAVER_APP_SET_WIN
		.enter
	;
	; Let the superclass do its little thing.
	; 
		mov	di, offset QixApplicationClass
		call	ObjCallSuperNoLock
	;
	; Now initialize our state. First comes the array of QixStructs
	; 
		mov	di, ds:[si]
		add	di, ds:[di].QixApplication_offset
		mov	cx, ds:[di].QAI_numQixes
		mov	ax, size QixStruct
		mul	cx
		mov_tr	cx, ax
		mov	al, mask OCF_IGNORE_DIRTY
		call	LMemAlloc

		mov	di, ds:[si]
		add	di, ds:[di].QixApplication_offset
		mov	ds:[di].QAI_qixes, ax
	;
	; Create a random number generator.
	; 
		call	TimerGetCount
		mov	dx, bx		; dxax <- seed
		clr	bx		; bx <- allocate a new one
		call	SaverSeedRandom
		mov	ds:[di].QAI_random, bx
	;
	; Now initialize all the qixes.
	; 
		
		mov	bx, di
		mov	di, ds:[di].QAI_qixes
		mov	di, ds:[di]
		mov	cx, ds:[bx].QAI_numQixes
		clr	ax		; qix #
qixLoop:		
		inc	ax		; next qix # (1-origin)
		call	QixInit
		add	di, size QixStruct
		loop	qixLoop
	;
	; We always draw in XOR mode for easy erasure.
	;
		mov	di, ds:[bx].SAI_curGState
		mov	ax, MM_XOR
		call	GrSetMixMode

	;
	; Start up the timer to draw a new line.
	;
		call	QixSetTimer
		.leave
		ret
QASetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QAUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= QixApplication object
		ds:di	= QixApplicationInstance

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QAUnsetWin	method dynamic QixApplicationClass, MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
		clr	bx
		xchg	bx, ds:[di].QAI_timerHandle
		mov	ax, ds:[di].QAI_timerID
		call	TimerStop
	;
	; Nuke the random number generator.
	; 
		clr	bx
		xchg	bx, ds:[di].QAI_random
		call	SaverEndRandom
	;
	; Free up the qix array.
	; 
		clr	ax
		xchg	ds:[di].QAI_qixes, ax
		call	LMemFree
	;
	; Call our superclass to take care of the rest.
	; 
		mov	ax, MSG_SAVER_APP_UNSET_WIN
		mov	di, offset QixApplicationClass
		GOTO	ObjCallSuperNoLock
QAUnsetWin	endm

;==============================================================================
;
;		    DRAWING ROUTINES
;
;==============================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QixSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	QASetWin, QADraw
PASS:		*ds:si	= QixApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QixSetTimer	proc	near
		class	QixApplicationClass
		uses	di
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].QixApplication_offset
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, ds:[di].QAI_speed
		mov	dx, MSG_QIX_APP_DRAW
		mov	bx, ds:[LMBH_handle]	; ^lbx:si <- destination

		call	TimerStart
		mov	ds:[di].QAI_timerHandle, bx
		mov	ds:[di].QAI_timerID, ax
		.leave
		ret
QixSetTimer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QixDrawOne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line for the passed Qix

CALLED BY:	QixDraw

PASS:		ds:bx	= Qix to update
		ds:bp	= QixApplicationInstance
		di	= gstate through which to draw

RETURN:		nothing
DESTROYED:	ax, dx, si, gstate line color

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<C_BLACK eq 0>
CheckHack	<CF_INDEX eq 0>

QixDrawOne	proc	near
		class	QixApplicationClass
		uses	cx
		.enter
	;
	; Change colors?
	;
		mov	si, ds:[bx].QS_last
		mov	al, ds:[bx].QS_pixel	;al <- last color used
		tst	ds:[bp].QAI_doColor
		jz	storeColor
noBlack:
		add	al, ds:[bx].QS_qixNum
		and	al, 0xf			;XXX: assumes 16 colors
		jz	noBlack			;XXX: assumes BLACK = 0
		mov	ds:[bx].QS_pixel, al	;update for next color
storeColor:
		mov	ds:[bx].QS_lineq[si].QL_color, al
	;
	; Set the line color to the current one.
	;
		mov	si, ds:[bx].QS_last
		clr	ax			;XXX: assumes COLOR_INDEX = 0
		mov	al, ds:[bx].QS_lineq[si].QL_color
		call	GrSetLineColor

		push	bx
	;
	; Move the line to draw by one delta.
	;
		lea	si, ds:[bx].QS_y2
		mov	bx, ds:[bp].QAI_random
		call	SaverVectorUpdate
		xchg	dx, ax

		add	si, offset QS_y1 - offset QS_y2
		call	SaverVectorUpdate
		push	ax

		add	si, offset QS_x2 - offset QS_y1
		call	SaverVectorUpdate
		xchg	cx, ax

		add	si, offset QS_x1 - offset QS_x2
		call	SaverVectorUpdate
	;
	; Draw the new line in the current color.
	;
		pop	bx
		mov	si, ds:[bp].QAI_object
		call	cs:drawRoutines[si]

		mov	si, bx		; save y1...
		pop	bx
		
	;
	; Store the current coordinates at the end of the line queue and
	; advance the tail pointer.
	;
		push	di
		mov	di, ds:[bx].QS_last
		mov	ds:[bx].QS_lineq[di].QL_bounds.R_left, ax
		mov	ds:[bx].QS_lineq[di].QL_bounds.R_top, si
		mov	ds:[bx].QS_lineq[di].QL_bounds.R_right, cx
		mov	ds:[bx].QS_lineq[di].QL_bounds.R_bottom, dx
		
		add	di, size QixLine
		cmp	di, ds:[bx].QS_queueSize
		jb	checkFirst
		clr	di
checkFirst:
	;
	; See if we've filled the queue.
	;
		mov	ds:[bx].QS_last, di
		cmp	di, ds:[bx].QS_first
		jne	done
		
	;
	; Queue is full -- erase the first line in the queue.
	;
		tst	ds:[bp].QAI_doColor	;doing color?
		jz	eraseLine		;branch if not color

		clr	ax			; XXX: COLOR_INDEX = 0
		mov	al, ds:[bx].QS_lineq[di].QL_color
		pop	di
		call	GrSetLineColor
		push	di
		
eraseLine:
		mov	di, ds:[bx].QS_first
		mov	ax, ds:[bx].QS_lineq[di].QL_bounds.R_left
		mov	si, ds:[bx].QS_lineq[di].QL_bounds.R_top
		mov	cx, ds:[bx].QS_lineq[di].QL_bounds.R_right
		mov	dx, ds:[bx].QS_lineq[di].QL_bounds.R_bottom
		
		pop	di
		xchg	bx, si

		push	si
		mov	si, ds:[bp].QAI_object
		call	cs:drawRoutines[si]
		pop	si

		xchg	bx, si
		push	di
	;
	; Adjust the head pointer.
	;
		mov	ax, ds:[bx].QS_first
		add	ax, size QixLine
		cmp	ax, ds:[bx].QS_queueSize
		jb	storeFirst
		clr	ax
storeFirst:
		mov	ds:[bx].QS_first, ax
done:
		pop	di
		.leave
		ret
QixDrawOne	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QixDraw<mumble>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a qix-related shape

CALLED BY:	QixDrawOne

PASS:		ds	= gstate handle
		(ax,bx,cx,dx) - bounds of qix box

RETURN:		nothing
DESTROYED:	si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

drawRoutines	nptr \
	QixDrawLines,
	QixDrawRectangles,
	QixDrawXs,
	QixDrawEllipses,
	QixDrawTriangles,
	QixDrawVs,
	QixDrawButterflies

QixDrawButterflies	proc	near
	call	GrDrawVLine
	xchg	ax, cx
	call	GrDrawVLine
	xchg	ax, cx
	FALL_THRU	QixDrawXs
QixDrawButterflies	endp

QixDrawXs	proc	near
	xchg	ax, cx
	call	GrDrawLine
	xchg	ax, cx
	FALL_THRU	QixDrawLines
QixDrawXs	endp

QixDrawLines	proc	near
	call	GrDrawLine
	ret
QixDrawLines	endp

QixDrawRectangles	proc	near
	call	GrDrawRect
	ret
QixDrawRectangles	endp

QixDrawEllipses	proc	near
	call	GrDrawEllipse
	ret
QixDrawEllipses	endp

QixDrawTriangles proc	near
	call	GrDrawHLine
	FALL_THRU	QixDrawVs
QixDrawTriangles endp

QixDrawVs	proc	near
	uses	ax, cx
	.enter

	mov	si, cx
	sub	si, ax				;si <- difference
	sar	si, 1				;si <- 1/2 difference
	push	cx
	mov	cx, ax
	add	cx, si				;cx <- middle
	call	GrDrawLine
	pop	ax				;ax <- right
	call	GrDrawLine

	.leave
	ret
QixDrawVs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QixDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next Qix line.

CALLED BY:	MSG_QIX_APP_DRAW

PASS:		*ds:si	= QixApplication object
		ds:di	= QixApplicationInstance

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
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QixDraw		method	dynamic QixApplicationClass, 
					MSG_QIX_APP_DRAW
		.enter

		mov	bp, di
		
		mov	di, ds:[di].SAI_curGState
		tst	di
		jz	done

		push	si
		mov	cx, ds:[bp].QAI_numQixes
		mov	bx, ds:[bp].QAI_qixes
		mov	bx, ds:[bx]
qixLoop:
		call	QixDrawOne
		add	bx, size QixStruct
		loop	qixLoop
		pop	si
	;
	; Set another timer for next time.
	; 
		call	QixSetTimer
done:
		.leave
		ret
QixDraw		endm


QixCode	ends
