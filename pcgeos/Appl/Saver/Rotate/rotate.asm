COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		rotate.asm

AUTHOR:		Gene Anderson, May  10, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/10/93		Initial revision


DESCRIPTION:
	Code for rotate screen-saver library

	$Id: rotate.asm,v 1.1 97/04/04 16:49:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def
include backgrnd.def

UseLib	ui.def
UseLib	saver.def

include	rotate.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

RotateApplicationClass	class	SaverApplicationClass

MSG_ROTATE_APP_DRAW				message
;
;	Draw...sent by our timer
;
;	Pass:	nothing
;	Return:	nothing
;
    RAI_center		Point		<>
    RAI_radius		word		0
    RAI_angle		word		0
    RAI_bitmap		hptr		0
	noreloc RAI_bitmap

    RAI_timerHandle	hptr		0
    	noreloc	RAI_timerHandle
    RAI_timerID		word

    RAI_random		hptr		0
	noreloc	RAI_random

    RAI_doBackground	BooleanByte	BB_FALSE

RotateApplicationClass	endc

RotateProcessClass	class	GenProcessClass
RotateProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	rotate.rdef
ForceRef RotateApp

udata	segment

udata	ends

idata	segment

RotateProcessClass	mask CLASSF_NEVER_SAVED
RotateApplicationClass

idata	ends

RotateCode	segment resource

.warn -private
rotateOptionTable	SAOptionTable	<
	rotateCategory, length rotateOptions
>

rotateOptions	SAOptionDesc	<
	rotateBGKey,	size RAI_doBackground, offset RAI_doBackground
>
.warn @private

rotateCategory	char	'rotate', 0
rotateBGKey	char	'background', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= RotateApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateLoadOptions	method	dynamic	RotateApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs
	mov	bx, offset rotateOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset RotateApplicationClass
	GOTO	ObjCallSuperNoLock
RotateLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures the screen isn't cleared on startup.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= RotateApplication object

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateAppGetWinColor	method dynamic RotateApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its little thing.
	;
	mov	di, offset RotateApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT
	ret
RotateAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= RotateApplication object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateAppSetWin	method dynamic RotateApplicationClass, MSG_SAVER_APP_SET_WIN
		.enter
	;
	; Let the superclass do its little thing.
	; 
	mov	di, offset RotateApplicationClass
	call	ObjCallSuperNoLock
	;
	; Create a random number generator.
	; 
	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	mov	ds:[di].RAI_random, bx
if 0
	;
	; Initialize background if requested
	;
	call	InitBackground
endif
	;
	; Initialize the spot to rotate
	;
	call	InitRotateSpot
	;
	; Start up the timer to draw the first time
	;
	call	RotateSetTimer

	.leave
	ret
RotateAppSetWin	endm

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a random background bitmap if requested

CALLED BY:	RotateAppSetWin()
PASS:		*ds:si - RotateApplication object
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitBackground		proc	near
	class	RotateApplicationClass
bgFile	local	FileLongName
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	tst	ds:[di].RAI_doBackground	;draw background?
	jz	noBackground

	call	FilePushDir
	;
	; Go to the background bitmap directory
	;
	call	GotoBackgroundDirectory
	jc	quitError			;branch if error
	;
	; Choose a random background and open it
	;
	call	ChooseRandomBackground
	jc	quitError			;branch if error
	push	ds
	segmov	ds, ss
	lea	dx, ss:bgFile			;ds:dx <- ptr to filename
	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE or \
			mask VMAF_FORCE_READ_WRITE
	call	VMOpen
	pop	ds
	jc	quitError			;branch if error opening
	;
	; Draw the beast
	;
	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	mov	cx, ds:[di].SAI_bounds.R_right
	sub	cx, ds:[di].SAI_bounds.R_left	;cx <- width
	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top	;dx <- height
	call	GetGState			;di <- handle of GState
	mov	ax, SAVER_BITMAP_TILE		;ax <- SaverBitmapMode
	call	SaverDrawBGBitmap
	;
	; Clean up after ourselves
	;
	clr	al				;al <- errors OK
	call	VMClose
quitError:
	call	FilePopDir
noBackground:

	.leave
	ret
InitBackground		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoBackgroundDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the BACKGRND directory

CALLED BY:	InitBackground()
PASS:		none
RETURN:		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
backgroundDir	char	BACKGROUND_DIR, 0

GotoBackgroundDirectory		proc	near
	uses	ax, bx, dx, ds
	.enter

	mov	bx, SP_USER_DATA		;bx <- StandardPath
	segmov	ds, cs
	mov	dx, offset backgroundDir	;ds:dx <- ptr to path name
	call	FileSetCurrentPath

	.leave
	ret
GotoBackgroundDirectory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseRandomBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose a random background from what's available

CALLED BY:	InitBackground()
PASS:		*ds:si - RotateApplication object
		ss:bp - inherited locals
RETURN:		carry - set if error
		ss:bgFile - name of background
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
fooBG	char	"Aqua", 0

ChooseRandomBackground		proc	near
	uses	ds, es, si, di
	class	RotateApplicationClass
	.enter	inherit	InitBackground

	segmov	ds, cs
	mov	si, offset fooBG
	segmov	es, ss
	lea	di, bgFile
	mov	cx, length fooBG
	rep	movsb

	clc					;carry <- no error

	.leave
	ret
ChooseRandomBackground		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitRotateSpot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the spot to rotate

CALLED BY:	RotateAppSetWin(), RotateDraw()
PASS:		*ds:si - RotateApplication object
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitRotateSpot		proc	near
	uses	di
	class	RotateApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	;
	; Get a random center
	;
	mov	ax, ds:[di].SAI_bounds.R_bottom
	sub	ax, ds:[di].SAI_bounds.R_top	;ax <- max #
	sub	ax, ROTATE_BITMAP_HEIGHT
	call	GetRandomNumber
	add	ax, ds:[di].SAI_bounds.R_top	;ax <- random y
	mov	ds:[di].RAI_center.P_y, ax
	mov	ax, ds:[di].SAI_bounds.R_right
	sub	ax, ds:[di].SAI_bounds.R_left	;ax <- max #
	call	GetRandomNumber
	add	ax, ds:[di].SAI_bounds.R_left	;ax <- random x
	mov	ds:[di].RAI_center.P_x, ax
	;
	; Get a random radius
	;
	mov	ax, ROTATE_MAX_RADIUS-ROTATE_MIN_RADIUS
	call	GetRandomNumber
	add	ax, ROTATE_MIN_RADIUS		;ax <- random radius
	mov	ds:[di].RAI_radius, ax
	;
	; Initialze the angle
	;
	clr	ds:[di].RAI_angle
	;
	; Draw a (hopefully) colorful dot to liven up gray areas
	;
	call	GetGState			;di <- GState handle
	mov	ax, 16
	call	GetRandomNumber
CheckHack <CF_INDEX eq 0>
	call	GrSetAreaColor
	;
	; Get the bitmap at the position specified, destroying the old
	; one if necessary.  The bitmap starts in a horizontal position,
	; so we only need to adjust the x position initially.
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	mov	cx, ds:[di].RAI_radius		;cx <- radius
	mov	ax, ds:[di].RAI_center.P_x
	sub	ax, cx
	mov	bx, ds:[di].RAI_center.P_y	;(ax,bx) <- (x,y) of source
	pop	di
	call	GrDrawPoint
if ROTATE_ANGLE_STOP eq 180
	shl	cx, 1				;cx <- width = radius*2
endif
	mov	dx, ROTATE_BITMAP_HEIGHT	;dx <- height
	call	GrGetBitmap			;bx <- bitmap, if any
	call	SetBitmapFreeOld

	.leave
	ret
InitRotateSpot		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRandomNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a random number

CALLED BY:	UTILITY
PASS:		*ds:si - RotateApplication object
		ax - max value
RETURN:		ax - random value between 0 and max-1
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRandomNumber		proc	near
	uses	bx, di, dx
	class	RotateApplicationClass
	.enter

	mov_tr	dx, ax				;dx <- max value
	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	mov	bx, ds:[di].RAI_random		;bx <- shme for random #s
	call	SaverRandom
	mov_tr	ax, dx				;ax <- random #

	.leave
	ret
GetRandomNumber		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get our GState

CALLED BY:	UTILITY
PASS:		*ds:si - RotateApplication object
RETURN:		di - handle of GState
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGState		proc	near
	class	RotateApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	mov	di, ds:[di].SAI_curGState	;di <- handle of GState

	.leave
	ret
GetGState		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= RotateApplication object
		ds:di	= RotateApplicationInstance

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateAppUnsetWin	method dynamic RotateApplicationClass, MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
	clr	bx
	xchg	bx, ds:[di].RAI_timerHandle
	mov	ax, ds:[di].RAI_timerID
	call	TimerStop
	;
	; Nuke the random number generator.
	; 
	clr	bx
	xchg	bx, ds:[di].RAI_random
	call	SaverEndRandom
	;
	; Nuke the bitmap, if any
	;
	clr	bx				;bx <- no new bitmap
	call	SetBitmapFreeOld
	;
	; Call our superclass to take care of the rest.
	; 
	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset RotateApplicationClass
	GOTO	ObjCallSuperNoLock
RotateAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBitmapFreeOld
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our bitmap, and free any old bitmap

CALLED BY:	RotateAppUnsetWin(), InitRotateSpot()
PASS:		*ds:di - RotateApplication object
		bx - handle of bitmap to set (0 for none)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBitmapFreeOld		proc	near
	uses	bx, di
	class	RotateApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	xchg	bx, ds:[di].RAI_bitmap
	tst	bx				;any bitmap?
	jz	noBitmap			;branch if not
	call	MemFree
noBitmap:

	.leave
	ret
SetBitmapFreeOld		endp

;==============================================================================
;
;		    DRAWING ROUTINES
;
;==============================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	QASetWin, QADraw
PASS:		*ds:si	= RotateApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateSetTimer	proc	near
	class	RotateApplicationClass
	uses	di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ROTATE_TIMER_SPEED
	mov	dx, MSG_ROTATE_APP_DRAW
	mov	bx, ds:[LMBH_handle]	; ^lbx:si <- destination

	call	TimerStart
	mov	ds:[di].RAI_timerHandle, bx
	mov	ds:[di].RAI_timerID, ax
	.leave
	ret
RotateSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next Rotate line.

CALLED BY:	MSG_QIX_APP_DRAW

PASS:		*ds:si	= RotateApplication object
		ds:di	= RotateApplicationInstance

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
	eca	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateAppDraw		method	dynamic RotateApplicationClass, 
					MSG_ROTATE_APP_DRAW
	.enter

	;
	; Make sure there is a GState
	;
	tst	ds:[di].SAI_curGState
	jz	done
	;
	; Make sure there is a bitmap
	;
	tst	ds:[di].RAI_bitmap
	jz	newSpot

	push	si
	mov	si, di
	mov	di, ds:[si].SAI_curGState	;di <- handle of GState
	call	GrSaveState
	;
	; Update the screen.  Translate to (0,0) so we can rotate
	; about the center of circle.
	;
	clr	ax, cx
	mov	dx, ds:[si].RAI_center.P_x
	mov	bx, ds:[si].RAI_center.P_y
	call	GrApplyTranslation
	mov	dx, ds:[si].RAI_angle
	clr	cx				;dx.cx <- rotation
	call	GrApplyRotation
	;
	; Draw the beast
	;
	mov	bx, ds:[si].RAI_bitmap
	mov	cx, ds:[si].RAI_radius
	neg	cx
	clr	dx				;(cx,dx) <- (x,y) position
	call	LockAndDrawBitmap

	call	GrRestoreState
	pop	si
	;
	; Update the angle for next time
	;
	mov	di, ds:[si]
	add	di, ds:[di].RotateApplication_offset
	add	ds:[di].RAI_angle, ROTATE_ANGLE_INCREMENT
	cmp	ds:[di].RAI_angle, ROTATE_ANGLE_STOP
	ja	newSpot
	;
	; Set a timer for next time
	;
nextSpot:
	call	RotateSetTimer
done:
	.leave
	ret

newSpot:
	call	InitRotateSpot
	jmp	nextSpot
RotateAppDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockAndDrawBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock, draw, and unlock the bitmap

CALLED BY:	RotateAppDraw()
PASS:		bx - handle of bitmap
		(cx,dx) - (x,y) coords to draw bitmap at
		di - handle of GState
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockAndDrawBitmap		proc	near
	uses	ds, si
	.enter

	push	bx
	call	MemLock
	mov	ds, ax
	clr	si				; ds:si <- ptr to bitmap
	mov	ax, cx
	mov	bx, dx				; (ax,bx) <- (x,y) to draw at
	call	GrDrawBitmap
	pop	bx				; bx <- handle of bitmap
	call	MemUnlock

	.leave
	ret
LockAndDrawBitmap		endp

RotateCode	ends
