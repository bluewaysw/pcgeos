COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		fades
FILE:		fades.asm

AUTHOR:		Gene Anderson, Sep 11, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/11/91		Initial revision

DESCRIPTION:
	fades & wipes specific screen-saver library

	$Id: fades.asm,v 1.1 97/04/04 16:44:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

;==============================================================================
;
;		       CONSTANTS AND DATA TYPES
;
;==============================================================================

include	fades.def

;=============================================================================
;
;			OBJECT CLASSES
;
;=============================================================================

FadesApplicationClass	class	SaverApplicationClass

MSG_FADES_APP_DRAW			message
;
;	Start drawing the fade (sent by timer).
;
;	Pass:	nothing
;	Return:	nothing
;

	FAI_speed	word		SAVER_FADE_MEDIUM_SPEED
	FAI_type	word		FADE_WIPE_TO_0000
	FAI_timerHandle	hptr		0
		noreloc	FAI_timerHandle
	FAI_timerID	word		0

FadesApplicationClass endc

FadesProcessClass	class	GenProcessClass
FadesProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	fades.rdef
ForceRef FadesApp

udata	segment

udata	ends

idata	segment

FadesProcessClass	mask	CLASSF_NEVER_SAVED
FadesApplicationClass

idata	ends

FadesCode	segment resource

.warn -private
fadesOptionTable	SAOptionTable	<
	fadesCategory, length fadesOptions
>
fadesOptions	SAOptionDesc	<
	fadesSpeedKey, size FAI_speed, offset FAI_speed
>, <
	fadesTypeKey, size FAI_type, offset FAI_type
>

.warn @private
fadesCategory	char	'fades', 0
fadesSpeedKey	char	'speed', 0
fadesTypeKey	char	'type', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FadesLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= FadesApplicationClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FadesLoadOptions	method dynamic FadesApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs
	mov	bx, offset	fadesOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset	FadesApplicationClass
	GOTO	ObjCallSuperNoLock
FadesLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FadesAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate to use, and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= FadesApplicationClass object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FadesAppSetWin	method dynamic FadesApplicationClass, 
					MSG_SAVER_APP_SET_WIN

	;
	; Let the superclass do its little thing.
	; 

	mov	di, offset FadesApplicationClass
	call	ObjCallSuperNoLock

	;
	;  Do the fade.
	;

	mov	di, ds:[si]
	add	di, ds:[di].FadesApplication_offset
	call	FadesStart

	ret
FadesAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FadesAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the window is transparent.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= FadesApplicationClass object
		ds:di	= FadesApplicationClass instance data

RETURN:		ax = WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FadesAppGetWinColor	method dynamic FadesApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thing.
	;

	mov	di, offset	FadesApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT

	ret
FadesAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FadesStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	FadesAppSetWin

PASS:		ds:[di] = FadesApplicationInstance

RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FadesStart	proc	near
	class	FadesApplicationClass
	;
	;  We fade to black
	;

	mov	bp, di				; bp = instance data
	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	mov	di, bp				; di = instance data

	;
	;  Fade me jesus
	;

	clrdw	axbx				; window left & top
	mov	cx, ds:[di].SAI_bounds.R_right	; cx <- window right
	mov	dx, ds:[di].SAI_bounds.R_bottom	; dx <- window bottom
	mov	si, ds:[di].FAI_type		; si <- FadeTypes
	cmp	si, FADE_WIPE_TO_LTRB
	jbe	doFadeWipe

	;
	; A "normal" fade or wipe -- table drive it...
	;

	sub	si, FADE_WIPE_TO_LTRB+1
	shl	si, 1				; table of words
	mov	bp, cs:fadeRoutines[si]		; bp <- routine to call
	mov	si, ds:[di].FAI_speed		; si <- SaverFadeSpeeds
	mov	di, ds:[di].SAI_curGState	; di = gstate
	call	bp

done:
	ret

doFadeWipe:

	mov	bp, ds:[di].FAI_type		; bp <- SaverWipeTypes
	mov	si, ds:[di].FAI_speed		; si <- SaverFadeSpeeds
	mov	di, ds:[di].SAI_curGState	; di = gstate
	call	SaverFadeWipe

	jmp	short	done
FadesStart	endp

CheckHack <FADE_WIPE_TO_0000 eq 0>
CheckHack <FADE_WIPE_TO_LTRB eq 15>
CheckHack <FADE_PATTERN eq 16>

fadeRoutines	nptr \
	FadePatternFade

FadePatternFade	proc	near
	call	SaverFadePatternFade
	ret
FadePatternFade	endp

FadesCode	ends
