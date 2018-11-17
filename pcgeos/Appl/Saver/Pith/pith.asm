COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pith.asm

AUTHOR:		Gene Anderson, Jun  3, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 3/93		Initial revision


DESCRIPTION:
	Pith & Moan screen-saver

	$Id: pith.asm,v 1.1 97/04/04 16:48:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def
UseLib	Objects/vTextC.def

include	pith.def
include pithMessage.asm

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

PithApplicationClass	class	SaverApplicationClass

MSG_PITH_APP_DRAW				message
;
;	Draw the next pithy saying.
;
;	Pass:	nothing
;	Return:	nothing
;
MSG_PITH_APP_ERASE				message
;
;	Erase the previous pithy saying.
;
;	Pass:	nothing
;	Return:	nothing
;

    PAI_duration	word
    PAI_position	PithPositionType
    PAI_border		word

    PAI_numMessages	word
    PAI_messageBuffer	hptr		0
	noreloc PAI_messageBuffer

    PAI_timerHandle	hptr		0
    	noreloc	PAI_timerHandle
    PAI_timerID		word
    PAI_random		hptr		0	; Random number generator
	noreloc	PAI_random

PithApplicationClass	endc

PithProcessClass	class	GenProcessClass
PithProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	pith.rdef
ForceRef PithApp

udata	segment

udata	ends

idata	segment

PithProcessClass	mask CLASSF_NEVER_SAVED
PithApplicationClass

idata	ends

PithCode	segment resource

.warn -private
pithOptionTable	SAOptionTable	<
	pithCategory, length pithOptions
>
pithOptions	SAOptionDesc	<
	pithDurationKey,	size PAI_duration, offset PAI_duration
>,<
	pithPositionKey,	size PAI_position, offset PAI_position
>,<
	pithBorderKey,		size PAI_border, offset PAI_border
>
.warn @private
pithCategory	char	'pith', 0
pithDurationKey	char	'duration', 0
pithPositionKey	char	'position', 0
pithBorderKey	char	'border', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= PithApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithLoadOptions	method	dynamic	PithApplicationClass, 
					MSG_META_LOAD_OPTIONS
		uses	ax, es
		.enter

		segmov	es, cs
		mov	bx, offset pithOptionTable
		call	SaverApplicationGetOptions

		.leave
		mov	di, offset PithApplicationClass
		GOTO	ObjCallSuperNoLock
PithLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= PithApplication object
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
PithSetWin	method dynamic PithApplicationClass, MSG_SAVER_APP_SET_WIN
		.enter
	;
	; Let the superclass do its little thing.
	; 
		mov	di, offset PithApplicationClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].PithApplication_offset
	;
	; Create a random number generator.
	; 
		call	TimerGetCount
		mov	dx, bx		; dxax <- seed
		clr	bx		; bx <- allocate a new one
		call	SaverSeedRandom
		mov	ds:[di].PAI_random, bx
	;
	; Initialize the message text object
	;
		call	PithInitText
	;
	; Initialize the messages
	;
		call	PithInitMessages
		mov	ds:[di].PAI_messageBuffer, bx
		mov	ds:[di].PAI_numMessages, cx
	;
	; Start up the timer to draw a new message
	;
		clr	cx			;cx <- timer length
		mov	dx, MSG_PITH_APP_DRAW	;dx <- message
		call	PithSetTimer

		.leave
		ret
PithSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithInitText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize our message text object

CALLED BY:	PithSetWin()
PASS:		*ds:si - PithApplication object
		ds:di - *ds:si
RETURN:		none
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithInitText		proc	near
		class	PithApplicationClass
		.enter

	;
	; Set any paragraph border
	;
		sub	sp, (size VisTextSetBorderBitsParams)
		mov	bp, sp
		mov	ax, ds:[di].PAI_border
		mov	ss:[bp].VTSBBP_bitsToSet, ax
		mov	ss:[bp].VTSBBP_bitsToClear, mask VisTextParaBorderFlags
		mov	ax, MSG_VIS_TEXT_SET_BORDER_BITS
		call	CallMessageTextAll
		add	sp, (size VisTextSetBorderBitsParams)
	;
	; Initialize the border shadow & spacing
	;
		sub	sp, (size VisTextSetBorderWidthParams)
		mov	bp, sp
		mov	ss:[bp].VTSBWP_width, PITH_BORDER_WIDTH*8
		mov	ax, MSG_VIS_TEXT_SET_BORDER_SHADOW
		call	CallMessageTextAll
		mov	ss:[bp].VTSBWP_width, PITH_BORDER_SPACING*8
		mov	ax, MSG_VIS_TEXT_SET_BORDER_SPACING
		call	CallMessageTextAll
		add	sp, (size VisTextSetBorderWidthParams)

		.leave
		ret
PithInitText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= PithApplication object
		ds:di	= PithApplicationInstance

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithUnsetWin	method dynamic PithApplicationClass, MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
		clr	bx
		xchg	bx, ds:[di].PAI_timerHandle
		mov	ax, ds:[di].PAI_timerID
		call	TimerStop
	;
	; Free our message buffer if it exists
	;
		clr	bx
		xchg	bx, ds:[di].PAI_messageBuffer
		tst	bx			;any buffer?
		jz	skipFree		;branch if no buffer
		call	MemFree			;free me jesus
skipFree:
	;
	; Nuke the random number generator.
	; 
		clr	bx
		xchg	bx, ds:[di].PAI_random
		call	SaverEndRandom
	;
	; Call our superclass to take care of the rest.
	; 
		mov	ax, MSG_SAVER_APP_UNSET_WIN
		mov	di, offset PithApplicationClass
		GOTO	ObjCallSuperNoLock
PithUnsetWin	endm

;==============================================================================
;
;		    DRAWING ROUTINES
;
;==============================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw or erase a message

CALLED BY:	UTILITY
PASS:		*ds:si	= PithApplication object
		cx	= timer duration (in seconds)
		dx	= MSG_PITH_APP_DRAW or MSG_PITH_APP_ERASE
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithSetTimer	proc	near
		class	PithApplicationClass
		uses	di
		.enter

		push	dx
		mov	ax, 60
		mul	cx
		mov	cx, ax				;cx <- timer duration
		pop	dx
		mov	di, ds:[si]
		add	di, ds:[di].PithApplication_offset
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	bx, ds:[LMBH_handle]	; ^lbx:si <- destination

		call	TimerStart
		mov	ds:[di].PAI_timerHandle, bx
		mov	ds:[di].PAI_timerID, ax
		.leave
		ret
PithSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next Pith line.

CALLED BY:	MSG_PITH_APP_DRAW

PASS:		*ds:si	= PithApplication object
		ds:di	= PithApplicationInstance

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
	gene	6/3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithDraw		method	dynamic PithApplicationClass, 
					MSG_PITH_APP_DRAW
		.enter

		tst	ds:[di].SAI_curGState
		jz	done
	;
	; Set the color to something nice looking
	;
		call	PithSetTextColor
	;
	; Set the text to a random pithy saying
	;
		call	PithSetText
	;
	; Set the position and size of our pithy saying
	;
		call	PithSetTextPosSize
	;
	; Draw the beast
	;
		call	PithDrawText
	;
	; Set a timer for erasure
	; 
		mov	di, ds:[si]
		add	di, ds:[di].PithApplication_offset
		mov	cx, ds:[di].PAI_duration
		mov	dx, MSG_PITH_APP_ERASE	;dx <- message
		call	PithSetTimer
done:
		.leave
		ret
PithDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithSetTextColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color of our message text object

CALLED BY:	PithDraw()
PASS:		*ds:si - PithApplication object
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithSetTextColor		proc	near
		uses	bp
		.enter
	;
	; Choose a color
	;
		mov	ax, 15
		call	PithRandom
		inc	ax				;ax <- random color
			CheckHack <CF_INDEX eq 0>
	;
	; Set the text color
	;
		sub	sp, (size VisTextSetColorParams)
		mov	bp, sp				;ss:bp <- params
		mov	{word}ss:[bp].VTSCP_color.CQ_redOrIndex, ax
		mov	ax, MSG_VIS_TEXT_SET_COLOR
		call	CallMessageTextAll
	;
	; Set the border color to the same thing
	;
		mov	ax, MSG_VIS_TEXT_SET_BORDER_COLOR
		call	CallMessageTextAll
		add	sp, (size VisTextSetColorParams)

		.leave
		ret
PithSetTextColor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text to a random pithy saying

CALLED BY:	PithDraw()
PASS:		*ds:si - PithApplication object
RETURN:		none
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PithSetText		proc	near
		uses	si, bp
		class	PithApplicationClass
		.enter

	;
	; Choose a random saying
	;
		mov	di, ds:[si]
		add	di, ds:[di].PithApplication_offset
		mov	ax, ds:[di].PAI_numMessages
		tst	ax			;any messages?
		jz	done			;branch if not
		call	PithRandom
		shl	ax, 1			;ax <- index into lptrs
		add	ax, (size LMemBlockHeader)
		mov	bp, ax			;bp <- chunk of text
	;
	; Set the text
	;
		mov	dx, ds:[di].PAI_messageBuffer	;^ldx:bp <- text chunk
		clr	cx				;cx <- NULL-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		call	CallMessageText
done:

		.leave
		ret
PithSetText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithSetTextPosSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the position and size of our text object

CALLED BY:	PithDraw()
PASS:		*ds:si - PithApplication object
RETURN:		none
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithSetTextPosSize		proc	near
		uses	bp
		class	PithApplicationClass
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].PithApplication_offset
	;
	; The width of our object is half the screen width
	;
		mov	ax, ds:[di].SAI_bounds.R_right
		sub	ax, ds:[di].SAI_bounds.R_left
		shr	ax, 1				;ax <- screen width/2
	;
	; Tell the text object to calculate its height based on the width
	;
		mov	cx, ax				;cx <- text width
		push	cx
		mov	dx, -1				;dx <- force calculation
		mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
		call	CallMessageText
		pop	cx
	;
	; Position the text appropriately
	;
		push	cx, dx
		cmp	ds:[di].PAI_position, PITH_POSITION_CENTERED
		je	centerText
	;
	; Set the position to something random
	;
		mov	ax, cx				;ax <- screen width/2
		call	PithRandom
		add	ax, ds:[di].SAI_bounds.R_left	;ax <- random left
		mov	cx, ax				;cx <- left pos
		mov	ax, ds:[di].SAI_bounds.R_bottom
		sub	ax, ds:[di].SAI_bounds.R_top
		sub	ax, dx				;ax <- amount left over
		jbe	badYSize			;branch if borrow or z
		call	PithRandom
		add	ax, ds:[di].SAI_bounds.R_top
gotPos:
		mov	dx, ax				;dx <- top pos
		mov	ax, MSG_VIS_SET_POSITION
		call	CallMessageText
		pop	cx, dx
	;
	; cx = Width for text object
	; dx = Height for text object
	;
		mov	ax, MSG_VIS_SET_SIZE
		call	CallMessageText

		mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
		call	CallMessageText

		.leave
		ret

	;
	; The text object is as tall or taller than the screen.
	; Position it at the top.
	;
badYSize:
		clr	ax
		jmp	gotPos

	;
	; The user wants the message centered
	;
centerText:
		shr	cx, 1				;cx <- left = width/4
		mov	ax, ds:[di].SAI_bounds.R_bottom
		sub	ax, ds:[di].SAI_bounds.R_top
		sub	ax, dx
		jbe	badYSize			;branch if borrow or z
		shr	ax, 1				;ax <- difference/2
		add	ax, ds:[di].SAI_bounds.R_top
		jmp	gotPos
PithSetTextPosSize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithDrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the text object

CALLED BY:	PithDraw()
PASS:		*ds:si - PithApplication object
RETURN:		none
DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithDrawText		proc	near
		uses	bp
		class	PithApplicationClass
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].PithApplication_offset
		mov	bp, ds:[di].SAI_curGState	;bp <- GState

		mov	cl, mask DF_EXPOSED or mask DF_PRINT
		mov	ax, MSG_VIS_DRAW
		call	CallMessageText

		.leave
		ret
PithDrawText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallMessageTextAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call our message text object with a range set to all

CALLED BY:	UTILITY
PASS:		ds - fixupable
		ax - message
		ss:bp - ptr to VisTextRange
		cx, dx - depends on message
RETURN:		ds - fixed up
		ax, cx, dx - depends on message
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallMessageTextAll		proc	near
		clrdw	ss:[bp].VTR_start
		movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END
		FALL_THRU	CallMessageText
CallMessageTextAll		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallMessageText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call our message text object

CALLED BY:	UTILITY
PASS:		ds - fixupable
		ax - message
		cx, dx, bp - depends on message
RETURN:		ds - fixed up
		ax, cx, dx, bp - depends on message
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallMessageText		proc	near
		uses	bx, si, di
		.enter

		mov	si, offset MessageTextObject
		mov	bx, handle MessageTextObject
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
CallMessageText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithAppErase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase any previous message

CALLED BY:	MSG_PITH_APP_ERASE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PithApplicationClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithAppErase		method dynamic PithApplicationClass,
						MSG_PITH_APP_ERASE
		mov	bp, di
		mov	di, ds:[bp].SAI_curGState
		tst	di
		jz	done
	;
	; Draw a large black rectangle
	;
		mov	ax, C_BLACK or (CF_INDEX shl 8)
		call	GrSetAreaColor

		mov	ax, ds:[bp].SAI_bounds.R_left
		mov	bx, ds:[bp].SAI_bounds.R_top
		mov	cx, ds:[bp].SAI_bounds.R_right
		mov	dx, ds:[bp].SAI_bounds.R_bottom
		call	GrFillRect
	;
	; Set a timer for the next drawing
	; 
		clr	cx			;cx <- timer duration
		mov	dx, MSG_PITH_APP_DRAW	;dx <- message
		call	PithSetTimer
done:
		ret
PithAppErase		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pick a random number

CALLED BY:	UTILITY
PASS:		ax - max number
		*ds:si - PithApplication object
RETURN:		ax - random number between 0 and max-1
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithRandom		proc	near
		uses	bx, dx, di
		class	PithApplicationClass
		.enter

		mov	dx, ax
		mov	di, ds:[si]
		add	di, ds:[di].PithApplication_offset
		mov	bx, ds:[di].PAI_random
		call	SaverRandom
		mov	ax, dx				;ax <- random #

		.leave
		ret
PithRandom		endp

PithCode	ends
