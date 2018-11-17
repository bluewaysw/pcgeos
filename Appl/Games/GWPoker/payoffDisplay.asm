COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWorks Poker
FILE:		payoffDisplay.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	12/90		Initial Version

DESCRIPTION:


RCS STAMP:
$Id: payoffDisplay.asm,v 1.1 97/04/04 15:20:10 newdeal Exp $
------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	Objects/vTextC.def

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Object Class include files
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

PayoffDisplayClass	class	VisTextClass
MSG_PLAY_TUNE		message
MSG_SET_PLAY_TUNE		message
;pass - bp

MSG_STOP_FLASHING	message

MSG_COLOR_TOGGLE	message

MSG_FLASH		message
;
;	Turns the PayoffDisplay red and informs the game object of this
;	action.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_TURN_RED		message
;
;	Sets the object's styleRuns pointer to point at RedPayoffStyle,
;	whose text color is red.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_TURN_WHITE		message
;
;	Sets the object's styleRuns pointer to point at WhitePayoffStyle,
;	whose text color is white.

MSG_RESIZE_AND_VALIDATE	message
;
;	Object sets new dimensions, clears its VOF_GEOMETRY_INVALID bit,
;	and sends itself a MSG_VALIDATE
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SHOW_PAYOFF		message
;
;	Constructs the text string that the PayoffDisplay should
;	show out of the PDI_pokerHandName field and the
;	PTI_oddsGiven and PTI_oddsTaken fields.
;
;	PASS:		nothing
;
;	RETURN:		nothing

MSG_SET_ODDS		message
;
;	Sets the PDI_oddsGiven and PDI_oddsTaken fields
;
;	PASS:		cx = new PDI_oddsGiven
;			dx = new PDI_oddsTaken
;
;	RETURN:		nothing

	PDI_soundNumber		word
	PDI_pokerHandName	nptr		;text string describing the
						;name of the poker hand
						;represented by this display
						;(e.g. "Full House")

	PDI_oddsGiven		word
	PDI_oddsTaken		word
PayoffDisplayClass	endc

PAYOFF_PARA_ATTR =	( (0*2) shl offset VTDPA_LEFT_MARGIN ) or \
			( (0*2) shl offset VTDPA_PARA_MARGIN ) or \
			( (0*2) shl offset VTDPA_RIGHT_MARGIN ) or \
			( VTDDT_HALF_INCH shl offset VTDPA_DEFAULT_TABS ) or \
			( J_CENTER shl offset VTDPA_JUSTIFICATION )

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

	PayoffDisplayClass

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;		Code for PayoffDisplayClass
;------------------------------------------------------------------------------
CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PayoffDisplayShowPayoff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SHOW_PAYOFF handler for PayoffDisplayClass
		Constructs the text string that the PayoffDisplay should
		show out of the PDI_pokerHandName field and the
		PDI_oddsGiven and PDI_oddsTaken fields.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PayoffDisplayShowPayoff	method	PayoffDisplayClass, MSG_SHOW_PAYOFF
	sub	sp, 100
	mov	bp, sp
	push	ds:[di].PDI_oddsTaken
	push	ds:[di].PDI_oddsGiven	
	mov	bx, si
	mov	si, ds:[di].PDI_pokerHandName
	mov	si, ds:[si]
	segmov	es, ss, dx
	mov	di, bp

	;
	;	Read the name of the poker hand represented by this
	;	payoffDisplay into the display's text field
	;
copyName:
	cmp	{byte} ds:[si], 0
	jz	doneCopying
	movsb
	jmp	copyName

	;
	;	add in " pays XX to YY" to the text field, where
	;	XX is the number in ax and YY is the number in cx
	;
doneCopying:
	mov	si, offset PaysText
	mov	si, ds:[si]
paysLoop:
	lodsb
	tst	al
	jz	writeFirstNumber
	stosb
	jmp	paysLoop

writeFirstNumber:
	pop	ax
	call	WriteNum

	mov	si, offset ToText
	mov	si, ds:[si]
toLoop:
	lodsb
	tst	al
	jz	writeSecondNumber
	stosb
	jmp	toLoop

writeSecondNumber:
	pop	ax
	call	WriteNum

	clr	cx
	mov	byte ptr es:[di], cl			;trailing null

	;
	;	Now with dx:bp pointing at the proper string, we
	;	set the display's text to it
	;
	mov	si, bx
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	add	sp, 100
	ret
PayoffDisplayShowPayoff	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PayoffDisplaySetOdds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_SET_ODDS handler for PayoffDisplayClass
		Assigns the PayoffDisplay the 2 numbers it should print
		out in the "Whatever Hand pays XX to YY"

CALLED BY:	

PASS:		cx = odds given on this hand (XX above)
		dx = odds taken on this hand (YY above)
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PayoffDisplaySetOdds	method	PayoffDisplayClass, MSG_SET_ODDS
	mov	ds:[di].PDI_oddsGiven, cx
	mov	ds:[di].PDI_oddsTaken, dx

	mov	ax, MSG_SHOW_PAYOFF
	call	ObjCallInstanceNoLock
	ret
PayoffDisplaySetOdds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PayoffDisplayScreenUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_TEXT_SCREEN_UPDATE handler for PayoffDisplayClass
		For some reason, these MSG_VIS_TEXT_SCREEN_UPDATE's get passed
		to an object even if that object has its VA_DRAWABLE
		bit cleared; I had to subclass to prevent this from
		happening.

CALLED BY:	

PASS:		same as superclass
		
CHANGES:	

RETURN:		same as superclass

DESTROYED:	

PSEUDO CODE/STRATEGY:
		if (VA_DRAWABLE) {
			pass the method on up to the superclass
		}
		else {
			clear the VTIF_UPDATE_PENDING bit
		}

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
PayoffDisplayScreenUpdate method PayoffDisplayClass, MSG_VIS_TEXT_SCREEN_UPDATE
	PointDi2 Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jnz	callSuper
	PointDi2 Vis_offset
	RESET	ds:[di].VTI_intFlags, VTIF_UPDATE_PENDING
	jmp	done
callSuper:
	mov	di, offset PayoffDisplayClass
	call	ObjCallSuperNoLock
done:
	ret
PayoffDisplayScreenUpdate	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PayoffDisplayFlash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_FLASH handler for PayoffDisplayClass
		Causes the PayoffDisplay to turn itself red if it was white
		(and vice versa), then draws itself.

CALLED BY:	

PASS:		nothing
		
CHANGES:

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		get game OD
		inform game object of intent to hilight
		create gstate
		turn self red
		draw self

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PayoffDisplayFlash	method	PayoffDisplayClass, MSG_FLASH
	;
	;	Create a GState
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	push	bp
	;
	;	Turn ourself red
	;
	mov	ax, MSG_COLOR_TOGGLE
	call	ObjCallInstanceNoLock

	;
	;	Show off our newly found redness
	;
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock

	pop	di
	call	GrDestroyState
	ret
PayoffDisplayFlash	endm

PayoffDisplayStopFlashing  method  PayoffDisplayClass, MSG_STOP_FLASHING
	mov	ax, MSG_TURN_RED
	call	ObjCallInstanceNoLock

	mov	ax, MSG_FLASH
	call	ObjCallInstanceNoLock
	ret
PayoffDisplayStopFlashing	endm

PayoffDisplayColorToggle	method	PayoffDisplayClass, MSG_COLOR_TOGGLE
	mov	ax, MSG_TURN_RED
	PointDi2 Vis_offset
	cmp	ds:[di].VTI_charAttrRuns, offset WhitePayoffStyle
	je	toggle
	mov	ax, MSG_TURN_WHITE
toggle:
	call	ObjCallInstanceNoLock
	ret
PayoffDisplayColorToggle	endm

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PayoffDisplayTurnRed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TURN_RED handler for PayoffDisplayClass
		Points the object's styleRuns pointer at the red
		style run.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PayoffDisplayTurnRed	method	PayoffDisplayClass, MSG_TURN_RED
	PointDi2 Vis_offset
	mov	ds:[di].VTI_charAttrRuns, offset RedPayoffStyle
	ret
PayoffDisplayTurnRed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PayoffDisplayTurnWhite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TURN_WHITE handler for PayoffDisplayClass
		Points the object's styleRuns pointer at the white
		style run.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PayoffDisplayTurnWhite	method	PayoffDisplayClass, MSG_TURN_WHITE
	PointDi2 Vis_offset
	mov	ds:[di].VTI_charAttrRuns, offset WhitePayoffStyle
	ret
PayoffDisplayTurnWhite	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PayoffDisplayValidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VALIDATE handler for PayoffDisplayClass
		A cheap way of getting the VOF_GEOMETRY_INVALID bit right
		so that the text will print out. I don't know why this works,
		but it does.

CALLED BY:	

PASS:		nothing
		
CHANGES:	

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		This shouldn't have to be done...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PayoffDisplayValidate	method	PayoffDisplayClass, MSG_RESIZE_AND_VALIDATE

	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

	PointDi2 Vis_offset
	ANDNF	ds:[di].VI_optFlags, not mask VOF_GEOMETRY_INVALID
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
PayoffDisplayValidate	endm

PayoffDisplayPlayTune	method	PayoffDisplayClass, MSG_PLAY_TUNE
	mov	dx, ds:[di].PDI_soundNumber
	CallMod	GameStandardSound
	ret

PayoffDisplayPlayTune	endm


PayoffDisplaySetPlayTune	method	PayoffDisplayClass, MSG_SET_PLAY_TUNE
	mov	ds:[di].PDI_soundNumber,bp
	call	ObjMarkDirty
	ret

PayoffDisplaySetPlayTune	endm


CommonCode	ends		;end of CommonCode resource

