COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		gameContent.asm

AUTHOR:		Chris Boyke, Martin Turon

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/8/92   	Initial version.
	martin	6/24/92		Added timer events
	martin	1/19/92		Added gstate creation/scaling

DESCRIPTION:	

	$Id: contentGame.asm,v 1.1 97/04/04 18:04:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentViewWinOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Creates a gstate for use by the game while the view is
		opened. 

CALLED BY:	GLOBAL

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es 	= dgroup
		ax	= message #
		cx	= width of view
		dx	= height of view
		bp 	= handle of window

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine resides at cs:0, and so if something is going
wrong in the update routine (register thrashing, etc.)
GameMoverUpdatePosition may jump here!!!  Needless to say, this is
no good!


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentViewWinOpened	method  GameContentClass, 
					MSG_META_CONTENT_VIEW_WIN_OPENED

		mov	bx, bp			; bx 	= window handle
		xchg	di, bx			; di 	= window handle
		call	GrCreateState		; ds:bx = instance data
		mov	ds:[bx].GCI_gstate, di
		cmp	ds:[bx].GCI_status, GS_MINIMIZED
		pushf

		mov	di, offset GameContentClass
		call	ObjCallSuperNoLock
	;
	; If the game was minimized, continue it.
	;
		popf
		jne	exit
		mov	ax, MSG_GAME_CONTENT_CONTINUE_GAME
		call	ObjCallInstanceNoLock
exit:
		ret

GameContentViewWinOpened	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentViewWinClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Destroys the gstate the was created by
		GameContentViewWinOpened.  The gstate field in
		instance data will be filled with zero.

CALLED BY:	GLOBAL

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		bp	= handle of view window that is going away
		
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentViewWinClosed	method	GameContentClass, 
					MSG_META_CONTENT_VIEW_WIN_CLOSED

		uses	bp
		.enter
	;
	; If the game is running, set it to be in the special
	; minimized state (paused).  This is so it will automatically
	; return to the running state when it is un-minimized.
	;
		cmp	ds:[di].GCI_status, GS_RUNNING
		jne	continue
		mov	ds:[di].GCI_status, GS_MINIMIZED
continue:

		clr	bx
		xchg	bx, ds:[di].GCI_gstate
		mov	di, bx
		call	GrDestroyState

		mov	di, offset GameContentClass
		.leave
		GOTO	ObjCallSuperNoLock

GameContentViewWinClosed	endm
		
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handles scaling the game's gstate whenever the view
		size is changed.

CALLED BY:	GLOBAL

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es 	= dgroup
		bp 	= handle of pane window
		cx 	= new window width, in document coords
		dx 	= new window height, in document coords

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentViewSizeChanged	method  GameContentClass, 
					MSG_META_CONTENT_VIEW_SIZE_CHANGED

		tst	ds:[di].GCI_baseHeight
		jz	done

		uses	ax, cx, dx, si, bp
		.enter

	;
	; Get GState, and clear its transformation matrix
	;
		mov	bp, di
		mov	di, ds:[di].GCI_gstate
		call	GrSetDefaultTransform
		mov	di, bp
	;
	; Calculate scale factor for current window size	
	;
		mov	bp, ds:[di].GCI_baseHeight

		mov	ax, dx
		clr	dx
		div	bp
		mov	bx, ax		;bx = integer(height / VIEW_HEIGHT)
		clr	ax			
		div	bp		;dx:ax = remainder / VIEW_HEIGHT
		xchg	ax, cx		;bx.cx = height / VIEW_HEIGHT

		mov	bp, ds:[di].GCI_baseWidth
		clr	dx
		idiv	bp
		mov	si, ax		;si = integer(width / VIEW_WIDTH)
		clr	ax
		div	bp		;dx:ax = remainder / VIEW_WIDTH
		mov	dx, si		;dx = integer(width / VIEW_WIDTH)
		xchg	ax, cx		;bx.ax = height / VIEW_HEIGHT
					;dx.cx = width / VIEW_WIDTH

	;
	; Scale the game's GState
	;
		mov	di, ds:[di].GCI_gstate
		call	GrApplyScale
	;
	; Perform deafult stuff
	;
		.leave	
done:
		mov	di, offset GameContentClass
		GOTO	ObjCallSuperNoLock

GameContentViewSizeChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DESCRIPTION:	Draw the text, if any

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es	= Segment of GameContentClass.
		bp	- gstate handle

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentVisDraw	method	dynamic	GameContentClass, 
					MSG_VIS_DRAW
	.enter
	call	GameContentDisplayText
	mov	ax, MSG_VIS_DRAW
	mov	di, offset GameContentClass
	call	ObjCallSuperNoLock
	.leave
	ret
GameContentVisDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentStartGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Start a new game.  Set the status in the instance
		data, and update the UI

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es	= Segment of GameContentClass.

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.
	martin	6/24/92		Ported to library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentStartGame	method	dynamic	GameContentClass, 
					MSG_GAME_CONTENT_START_GAME

		call	GameContentTimerStop
		FALL_THRU	StartContinueCommon		

GameContentStartGame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartContinueCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start or continue a game

CALLED BY:	GameContentStartGame, GameContentContinueGame

PASS:		ds:di - GameContentClass object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/17/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartContinueCommon	proc far
		class	GameContentClass

		mov	ds:[di].GCI_status, GS_RUNNING

		call	GameContentUpdateUI

		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock

	;
	; Cause the first timer tick to come in after the redraw occurs
	;

		mov	ax, MSG_GAME_CONTENT_TIMER_TICK
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		GOTO	ObjMessage 
StartContinueCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentPauseGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Pause the game

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es	= Segment of GameContentClass.

RETURN:		nothing 
DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.
	martin	6/24/92		Ported to library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentPauseGame	method	GameContentClass, 
					MSG_GAME_CONTENT_PAUSE_GAME

	mov	ds:[di].GCI_status, GS_PAUSED
	call	GameContentTimerStop
	GOTO	GameContentUpdateStatus

GameContentPauseGame	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentAbortGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es	= Segment of GameContentClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.
	martin	6/24/92		Ported to library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentAbortGame	method	dynamic	GameContentClass, 
					MSG_GAME_CONTENT_ABORT_GAME
	mov	ds:[di].GCI_status, GS_STOPPED
	call	GameContentTimerStop
	GOTO	GameContentUpdateStatus
GameContentAbortGame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentContinueGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	continue a paused game.  If none paused, start a new one.

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es	= Segment of GameContentClass.

RETURN:		

DESTROYED:	bx, cx, dx 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	2/11/92   	Initial version.
	martin	6/11/94		Improved GCI_status handling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentContinueGame	method	dynamic	GameContentClass, 
					MSG_GAME_CONTENT_CONTINUE_GAME

	cmp	ds:[di].GCI_status, GS_MINIMIZED
	je	continue

	cmp	ds:[di].GCI_status, GS_PAUSED
	jne	exit

continue:
	mov	ds:[di].GCI_status, GS_RUNNING
	call	GameContentTimerStart
	call	GameContentUpdateStatus
	GOTO	StartContinueCommon
exit:
	ret

GameContentContinueGame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentGameOver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= GameContentClassClass object
		ds:di	= GameContentClassClass instance data
		es	= Segment of GameContentClassClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentGameOver	method	dynamic	GameContentClass, 
					MSG_GAME_CONTENT_GAME_OVER
	
	mov	ds:[di].GCI_status, GS_GAME_OVER
	call	GameContentTimerStop
	FALL_THRU	GameContentUpdateStatus

GameContentGameOver	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentUpdateStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send notification to the UI that the status has
		changed.  Draw the appropriate text in the center of
		the field. 

CALLED BY:	Start/Abort/Continue etc.

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentUpdateStatus	proc far
	class	GameContentClass

	.enter

	call	GameContentUpdateUI
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, ds:[di].GCI_gstate
	tst	bp
	jz	done
	call	GameContentDisplayText
done:
	.leave
	ret
GameContentUpdateStatus	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentDisplayText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Display either "game over" or "game paused"

CALLED BY:	GameContentVisDraw

PASS:		bp - gstate handle

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentDisplayText	proc near
	uses	bx, si
	class	GameContentClass 
	.enter
	mov	bl, ds:[di].GCI_status
	clr	bh
	shl	bx
	mov	si, cs:DisplayTextTable[bx]
	tst	si
	jz	done
	call	DisplayTextCentered
done:
	.leave
	ret
GameContentDisplayText	endp


DisplayTextTable	word	\
	0,				; GS_NULL
	GamePausedText,			; GS_PAUSED
	0,				; GS_TEMP_PAUSED
	0,				; GS_MINIMIZED
	0,				; GS_RUNNING
	0,				; GS_RESTARTING
	GameOverText,			; GS_GAME_OVER
	GameOverText			; GS_STOPPED

.assert length DisplayTextTable eq GameStatus
	




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayTextCentered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Display text in the center of the content's window

CALLED BY:	DisplayPauseText

PASS:		ds:di - content
		si - chunk handle of text (in StringsUI) to display

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayTextCentered	proc near	
	uses	ax,bx,cx,dx,di,si,bp,ds,es
	class	GameContentClass 
	.enter

	push	ds:[di].VCNI_viewWidth
	push	ds:[di].VCNI_viewHeight

	mov	di, bp			; gstate handle

	mov	ax, C_WHITE
	call	GrSetAreaColor

	mov	ax, C_BLACK
	call	GrSetLineColor
	mov	dx, 1
	clr	ax
	call	GrSetLineWidth
	mov	ax, C_BLACK
	call	GrSetTextColor


	; Get width of game over string

	mov	bx, handle StringsUI
	call	MemLock
	mov	es, ax

	clr	cx
	mov	si, es:[si]
	segxchg	ds, es
	call	GrTextWidth
	segxchg	ds, es
	mov	bp, dx
	shr	bp
	add	bp, HORIZ_TEXT_MARGIN
	
	pop	bx		; view height
	pop	ax		; view width

	shr	ax, 1
	shr	bx, 1

	mov	cx, ax
	mov	dx, bx

	sub	ax, bp
	add	cx, bp

	sub	bx, TEXT_HEIGHT + VERT_TEXT_MARGIN
	add	dx, VERT_TEXT_MARGIN


	push	si
	mov	si, 5
	call	GrFillRoundRect
	call	GrDrawRoundRect
	pop	si

	segxchg	ds, es
	add	ax, HORIZ_TEXT_MARGIN
	add	bx, VERT_TEXT_MARGIN
	clr	cx
	call	GrDrawText
	segxchg	ds, es

	mov	bx, handle StringsUI
	call	MemUnlock
	.leave
	ret
DisplayTextCentered	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the UI, and any other objects hanging around
		on notification lists out there...

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es	= Segment of GameContentClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentUpdateUI	proc	near

	uses	ax,bx,cx,dx
	.enter

	mov	ax, cs:[UpdateTable].UTE_size
	call	AllocNotifyBlock
	jc	done

	call	cs:[UpdateTable].UTE_routine

	; Now, update the UI controller

	mov	cx, cs:[UpdateTable].UTE_gcnListType
	mov	dx, cs:[UpdateTable].UTE_notificationType
	call	GameContentUpdateController

done:
	.leave
	ret
GameContentUpdateUI	endp



UpdateTable	UpdateTableEntry	\
	<GameContentUpdateStatusControl,
	 size GameStatusNotificationBlock,
	 GAGCNLT_GAME_STATUS_CHANGE,
	 GWNT_GAME_STATUS_CHANGE>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentUpdateStatusControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Stick the current status in the notification
		block 

CALLED BY:	GameContentUpdateUI

PASS:		bx - handle of GameStatusNotificationBlock
		ds:di - GameContent instance data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentUpdateStatusControl	proc near
	uses	ax,es
	class	GameContentClass 
	.enter
	call	MemLock
	mov	es, ax
	mov	al, ds:[di].GCI_status
	mov	es:[GSNB_status], al
	call	MemUnlock
	.leave
	ret
GameContentUpdateStatusControl	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocNotifyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Allocate the block of memory that will be used to
		update the UI.

CALLED BY:	GameContentUpdateUI

PASS:		ax - size to allocate

RETURN:		bx - block handle
		carry set if unable to allocate

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Initialize to zero 	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocNotifyBlock	proc near	
	uses	cx
	.enter
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT) shl 8
	call	MemAlloc
	jc	done
	mov	ax, 1
	call	MemInitRefCount
	clc
done:
	.leave
	ret
AllocNotifyBlock	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentUpdateController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Low-level routine to update a UI controller

CALLED BY:	GameContentUpdateUI

PASS:		bx - Data block to send to controller, or 0 to send
		null data (on LOST_SELECTION) 
		cx - GenAppGCNListType
		dx - NotifyStandardNotificationTypes

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentUpdateController	proc near	
	uses	di,si,bp
	.enter

	; create the event

	call	MemIncRefCount			;one more reference
	push	bx, cx, si
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	bp, bx				; data block
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx, cx, si

	; Create messageParams structure on stack

	mov	dx, size GCNListMessageParams	; create stack frame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	push	bx				; data block
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	
	; If data block is null, then set the IGNORE flag, otherwise
	; just set the SET_STATUS_EVENT flag

	mov	ax,  mask GCNLSF_SET_STATUS
	tst	bx
	jnz	gotFlags
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
gotFlags:
	mov	ss:[bp].GCNLMP_flags, ax
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	mov	bx, ds:[LMBH_handle]
	call	MemOwner			; bx <- owner
	clr	si

	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx				; data block
	
	add	sp, size GCNListMessageParams	; fix stack
	call	MemDecRefCount			; we're done with it 
	.leave
	ret
GameContentUpdateController	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= GameContentClass object
		ds:di	= GameContentClass instance data
		es	= Segment of GameContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameContentVisOpen	method	dynamic	GameContentClass, 
					MSG_VIS_OPEN
	.enter
	call	GameContentUpdateUI

	mov	di, offset GameContentClass
	call	ObjCallSuperNoLock
	.leave
	ret
GameContentVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameContentTimerStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Start the timer

CALLED BY:	GameContentStartGame, GameContentTimerTick

PASS:		*ds:si	= GameContentClass object

RETURN:		nothing 

DESTROYED:	ax, bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/24/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentTimerStart		proc	near

		class	GameContentClass 

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset

		mov	cx, ds:[di].GCI_timerInterval
		mov	dx, MSG_GAME_CONTENT_TIMER_TICK
		mov	al, TIMER_EVENT_ONE_SHOT	; Prepare timer
		mov	bx, ds:[LMBH_handle]		
		call	TimerStart
		mov	ds:[di].GCI_timerID, ax
		mov	ds:[di].GCI_timerHandle, bx

		ret
GameContentTimerStart		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GameContentTimerStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Stop the timer

CALLED BY:	GLOBAL

PASS:		ds:di 	= GameContentClass instance data

RETURN:		nothing
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentTimerStop		proc	near

	class	GameContentClass 

	uses	ax, bx
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	clr	bx
	xchg	bx, ds:[di].GCI_timerHandle	; stop the timer
	tst	bx
	jz	done
	mov	ax, ds:[di].GCI_timerID
	call	TimerStop
done:
	.leave
	ret
GameContentTimerStop		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameContentTimerTick		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Each time the timer ticks, Tell everything to move itself

CALLED BY:	MSG_GAME_CONTENT_TIMER_TICK

PASS:		cx:dx	= tick count
		ds:di	= GameContent instance data
		*ds:si	= GameContent object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/24/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GameContentTimerTick  	method	dynamic	GameContentClass, 
					MSG_GAME_CONTENT_TIMER_TICK

	cmp	ds:[di].GCI_status, GS_RUNNING
	jne	done
	call	GameContentTimerStart	; set up the timer for another
					; go... 	
done:
	ret

GameContentTimerTick		endm



ContentCode	ends













