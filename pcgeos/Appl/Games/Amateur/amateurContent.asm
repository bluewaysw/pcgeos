COMMENT @----------------------------------------------------------------------


PROJECT:	Amateur Night
MODULE:		amateurContent		
FILE:		amateurContent.asm

AUTHOR:		Chris Boyke	

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91			

DESCRIPTION:
	This file contains code to implement the "Content" object of
	peanut command.  This object receives input from the UI
	and performs the appropriate action / routing to the visible
	objects

	$Id: amateurContent.asm,v 1.1 97/04/04 15:12:27 newdeal Exp $
-----------------------------------------------------------------------------@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Relocate the clown moniker list

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentRelocate	method	dynamic	AmateurContentClass, 
						reloc
		uses	ax,cx,dx,bp
		.enter
		call	HackApp_RelocOrUnReloc
		.leave
		mov	di, offset AmateurContentClass
		call	ObjRelocOrUnRelocSuper
		ret
ContentRelocate	endm




COMMENT @---------------------------------------------------------------------
		ContentInitialize
------------------------------------------------------------------------------

SYNOPSIS:	Setup the Content object and the gameObjects block
		with proper data -- set the mouse pointer

CALLED BY:	ProcessClass on UI_OPEN_APPLICATION
PASS:		
RETURN:		nothing 
DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
ContentInitialize	method	dynamic AmateurContentClass, 
					MSG_CONTENT_INITIALIZE

	call	CalcClownSize

	; Set monikers for clowns

	call	ContentSetClownMonikers

	; Read the joke file 

	call	ContentReadJokeFile

	; create movable objects

	call	CreateObjects

	; Set the mouse pointer image

	push	si
	mov	cx, handle mousePtr
	mov	dx, offset mousePtr
	mov	ax, MSG_GEN_VIEW_SET_PTR_IMAGE
	clr	di
	mov	bx, handle AmateurView
	mov	si, offset AmateurView
	call	ObjMessage
	pop	si

	; Init the starting level

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].ACI_startAct, 1
	call	DisplayAct

	; Reset the score and pellets left displays (to deal with
	; restarting from state).

	call	ContentDisplayScore
	call	ContentDisplayPelletsLeft

	clr	cl
	call	EnableTriggers

	; Figure out the deal...
		
	mov	ax,MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	GenCallApplication
	mov	es:[displayType], ah

	mov	ax, MSG_CLOWN_SET_STATUS
	mov	cl, CS_ALIVE
	call	CallAllClowns

	call	SetColorInfo

	call	FindMonikers


	ret
ContentInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSetStartAct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the starting act for future games

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentSetStartAct	method	dynamic	AmateurContentClass, 
					MSG_CONTENT_SET_START_ACT
	mov	ds:[di].ACI_startAct, dx
	ret
ContentSetStartAct	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentCancelSetStartAct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Cancel setting the starting act for future games

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentCancelSetStartAct	method	dynamic	AmateurContentClass, 
					MSG_CONTENT_CANCEL_SET_START_ACT
	
	clr	bp			;not indeterminate
	mov	cx,ds:[di].ACI_startAct

	mov	bx,handle SetLevelRange
	mov	si,offset SetLevelRange

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_VALUE_SET_INTEGER_VALUE
	call	ObjMessage

	clr	cx			;not modified
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_VALUE_SET_MODIFIED_STATE
	call	ObjMessage

	mov	bx,handle SetLevelInteraction
	mov	si,offset SetLevelInteraction
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GEN_MAKE_NOT_APPLYABLE
	call	ObjMessage

	ret
ContentCancelSetStartAct	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentPauseGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Pause the game

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		nothing 

DESTROYED:	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentPauseGame	method	AmateurContentClass, 
					MSG_CONTENT_PAUSE_GAME

	mov	ds:[di].ACI_status, AGS_PAUSED
	mov	cl, mask TF_CONTINUE or mask TF_ABORT
	call	EnableTriggers
	call	DisplayPauseText

	ret
ContentPauseGame	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentAbortGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentAbortGame	method	dynamic	AmateurContentClass, 
					MSG_CONTENT_ABORT_GAME

	call	ContentStopTimer

	; Set all pellets/peanuts/clouds to "unused" status

	clr	al
	lea	bx, ds:[di].ACI_pellets
	mov	cx, MAX_MOVABLE_OBJECTS
resetLoop:
	mov	ds:[bx].HS_status, al
	add	bx, size HandleStruct
	loop	resetLoop

	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	mov	ds:[di].ACI_status, AGS_OVER

	;
	; Nuke the Abort and Pause triggers
	;
		
	clr	cl
	call	EnableTriggers

	ret
ContentAbortGame	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentContinueGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	continue a paused game.  If none paused, start a new one.

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentContinueGame	method	dynamic	AmateurContentClass, 
					MSG_CONTENT_CONTINUE_GAME
	uses	ax,cx,dx,bp
	.enter
	cmp	ds:[di].ACI_status, AGS_RUNNING
	je	done

	cmp	ds:[di].ACI_status, AGS_OVER
	je	startNew
	
	cmp	ds:[di].ACI_status, AGS_STOPPED
	je	startNew

	mov	cl, mask TF_PAUSE or mask TF_ABORT
	call	EnableTriggers

	mov	ds:[di].ACI_status, AGS_RUNNING
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	call	ContentStartTimer
done:
	.leave
	ret

startNew:
	call	ContentStartGame
	jmp	done

ContentContinueGame	endm




if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGetStartAct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the starting act from the UI and stick it in my
		ear.

CALLED BY:	ContentInitialize, ContentStartGame

PASS:		ds:di - content

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGetStartAct	proc near
	uses	ax,bx,si
	class	AmateurContentClass 
	.enter

	push	di
	mov	bx, handle Interface
	mov	si, offset SetLevelRange
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di

EC <	call	ECCheckContentDSDI		> 
	mov	ds:[di].ACI_startAct, dx

	; display it to the world

	call	DisplayAct

	.leave
	ret
ContentGetStartAct	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentStartGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= AmateurContent`Class object
		ds:di	= AmateurContent`Class instance data
		es	= Segment of AmateurContent`Class.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentStartGame	method	AmateurContentClass, 
					MSG_CONTENT_START_GAME
	uses	ax,cx,dx,bp
	.enter

	mov	cl, mask TF_ABORT or mask TF_PAUSE
	call	EnableTriggers

	call	ContentStopTimer		; kill the old timer (if any)

	; Set instance variables

	mov	ds:[di].ACI_clownsLeft, NUM_CLOWNS
	mov	ds:[di].ACI_sound, ST_EXTRA_CLOWN
	mov	ax, ds:[di].ACI_startAct
	mov	ds:[di].ACI_act, ax
	cmp	ax,1
	jne	startingAtBonusLevel
	clrdw	dxax

setInitScore:
	movdw	ds:[di].ACI_score,dxax
	movdw	ds:[di].ACI_scoreLastAct,dxax

	; Set all clowns to "alive" status


	mov	ax, MSG_CLOWN_SET_STATUS
	mov	cl, CS_ALIVE
	call	CallAllClowns

	call	ContentPrepareNextAct

	.leave
	ret


startingAtBonusLevel:
	mov	cx,ax			;starting act
	dec	cx			;don't include level starting at
	clrdw	dxax			;initial score
nextLevel:
	call	ContentCalcMaxScoreForAct
	add	ax,bx
	adc	dx,0
	loop	nextLevel
	jmp	setInitScore

ContentStartGame	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentCalcMaxScoreForAct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the maximum score a player can get from a level
		if he destroyed all peanuts and tomatoes, saved all the
		clowns and used 1/2 of the pellets. This only works for
		levels in the ActTable.

CALLED BY:	INTERNAL
		ContentStartGame

PASS:		ds:si - AmateurContent
		cx - level

RETURN:		
		bx - max score for level

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentCalcMaxScoreForAct		proc	far
	uses	es,ax,dx,cx,si
	.enter

	mov	ax,cx					;act
	dec	ax					;1st act at 0 offset
	mov	cx,segment idata
	mov	es,cx
	clr	cx					;score
	mov	bx,size ActInfo
	mul	bx
	mov	si,ax
	add	si,offset ActTable

	mov	bx,es:[si].AI_peanuts
	mov	ax,SCORE_PEANUT_HIT
	mul	bx
	add	cx,ax
	mov	bx,es:[si].AI_tomatoes
	mov	ax,SCORE_TOMATO
	mul	bx
	add	cx,ax
	mov	bx,es:[si].AI_pellets
	shr	bx,1
	mov	ax,SCORE_PELLET_LEFT
	mul	bx
	add	cx,ax
	add	cx,(SCORE_CLOWN * 6) + (SCORE_CLOWN_ADDER * 15)

	mov	bx,cx

	.leave
	ret
ContentCalcMaxScoreForAct		endp




COMMENT @---------------------------------------------------------------------
		ContentStartTimer		
------------------------------------------------------------------------------

SYNOPSIS:	Start the timer

CALLED BY:	ContentStartGame

PASS:		ds:di - content object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

ContentStartTimer	proc	near
	uses	di
	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSDI		> 
EC <	call	ECCheckContentDSSI		> 

	cmp	ds:[di].ACI_status, AGS_RUNNING
	jne	20$
	call	ContentStopTimer		; kill old timer, if any
20$:
	mov	ds:[di].ACI_status, AGS_RUNNING

	mov	cx, INTERVAL_START_ACT
	mov	dx, MSG_TIMER_TICK
	call	ContentSetupTimer
	.leave
	ret
ContentStartTimer	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSetupTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a one-shot timer

CALLED BY:

PASS:		ds:di - content
		cx - timer interval
		dx - message to send to this content when timer expires

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSetupTimer	proc near	
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		>

	mov	al, TIMER_EVENT_ONE_SHOT	; Prepare timer
	mov	bx, handle GameObjects
	call	TimerStart
	mov	ds:[di].ACI_timerID, ax
	mov	ds:[di].ACI_timerHandle, bx
	.leave
	ret
ContentSetupTimer	endp




COMMENT @---------------------------------------------------------------------
		ContentStopTimer		
------------------------------------------------------------------------------

SYNOPSIS:	Stop the timer

CALLED BY:	Global
PASS:		-
RETURN:		-
DESTROYED:	-
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@


ContentStopTimer	proc	near
	uses	bx
	.enter

	class	AmateurContentClass 

EC <	call	ECCheckContentDSDI		> 

	clr	bx
	xchg	bx, ds:[di].ACI_timerHandle	; stop the timer
	tst	bx
	jz	markStopped
	mov	ax, ds:[di].ACI_timerID
	call	TimerStop
markStopped:
	mov	ds:[di].ACI_status, AGS_STOPPED

	.leave
	ret
ContentStopTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to reposition all the clowns and veggie blasters
		when the size changes

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of AmateurContentClass

		bp - handle of pane window
		cx - new window width
		dx - new window height
	
RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentViewSizeChanged	method dynamic AmateurContentClass, 
					MSG_META_CONTENT_VIEW_SIZE_CHANGED

	mov	di,offset AmateurContentClass
	call	ObjCallSuperNoLock

	clr	cx,dx
	mov	ax,MSG_VIS_SET_POSITION
	GOTO	ObjCallInstanceNoLock

ContentViewSizeChanged		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the clowns

CALLED BY:	ContentSubviewSizeChanged, ContentVisOpen

PASS:		ds:di - content

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSetPosition	method	dynamic	AmateurContentClass,
					MSG_VIS_SET_POSITION
	.enter

	mov	di, offset	AmateurContentClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	clr	bp
	mov	ax, MSG_VIS_RECALC_SIZE
	call	CallAllBitmaps		; bp <- total widths of all

	mov	ax, ds:[di].VCNI_viewWidth
	sub	ax, bp
	mov	bx, NUM_CLOWNS+1
	clr	dx
	div	bx

	sub	sp, size BitmapPositionParams
	mov	bp, sp
	mov	[bp].BPP_distBetween, ax
	mov	ax, ds:[di].VCNI_viewWidth
	mov	[bp].BPP_viewWidth, ax
	mov	ax, ds:[di].VCNI_viewHeight
	mov	[bp].BPP_viewHeight, ax
	clr	[bp].BPP_curPos

	mov	ax, MSG_VIS_SET_POSITION
	call	CallAllBitmaps

	add	sp, size BitmapPositionParams

	; Make sure we get another draw

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_GET_SIZE
	mov	si, offset LeftBlaster
	call	ObjCallInstanceNoLock

	mov	ds:[di].ACI_blasterHeight, dx

	.leave
	ret
ContentSetPosition	endm




COMMENT @---------------------------------------------------------------------
		ContentVisOpen
------------------------------------------------------------------------------

SYNOPSIS:	This procedure is the Content Class' method for opening
		the view, setting the gstate, and clearing some state
		variables. 

CALLED BY:	GLOBAL

PASS:		*ds:si - content

RETURN:		nothing 

DESTROYED: 	ax,cx,dx,bp

 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

ContentVisOpen	method	AmateurContentClass, MSG_VIS_OPEN


		push	di
		mov	di, offset AmateurContentClass
		call	ObjCallSuperNoLock
		pop	di

		mov	ax, MSG_VIS_VUP_CREATE_GSTATE  ; Create Graphics State
		call	ObjCallInstanceNoLock
		mov	es:[gstate], bp		;Save GState

		clr	cx, dx
		mov	ax, MSG_VIS_SET_POSITION
		GOTO	ObjCallInstanceNoLock
ContentVisOpen	endm


COMMENT @---------------------------------------------------------------------
		ContentDraw		
------------------------------------------------------------------------------

SYNOPSIS:	draw blasters, clowns

CALLED BY:	MSG_DRAW

PASS:		bp - gstate handle

RETURN:		
DESTROYED:	
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
ContentDraw	method		AmateurContentClass, MSG_VIS_DRAW
	

	; save the old gstate, and use the new one temporarily

	xchg	es:[gstate], bp

	; draw a rectangle in the bg color

	mov	cx, ds:[di].VCNI_viewWidth
	mov	dx, ds:[di].VCNI_viewHeight
	mov	ax, ds:[di].ACI_colorInfo.CI_background
	push	di
	mov	di, es:[gstate]
	call	GrSetAreaColor
	clr	ax
	clr	bx
	call	GrFillRect
	pop	di


	mov	ax, MSG_VIS_DRAW
	call	CallAllBitmaps

	; If game is over, draw game over text

	cmp	ds:[di].ACI_status, AGS_OVER
	jne	notOver
	call	DisplayGameOverText
notOver:
	cmp	ds:[di].ACI_status, AGS_PAUSED
	jne	done
	call	DisplayPauseText
done:

	
	xchg	es:[gstate], bp
	ret


ContentDraw	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawClowns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	redraw all the clowns

CALLED BY:	ContentDraw, ContentTimerTick

PASS:		ds:di - content 

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawClowns	proc near	
	class	AmateurContentClass 
	uses	bp
	.enter
EC <	call	ECCheckContentDSDI		> 
EC <	call	ECCheckContentDSSI		> 

	mov	ax, MSG_VIS_DRAW
	call	CallAllClowns

	.leave
	ret
DrawClowns	endp



COMMENT @---------------------------------------------------------------------
		ContentVisClose	
------------------------------------------------------------------------------

SYNOPSIS:	Destroy the Gstate and stop the timer

CALLED BY:	MSG_VIS_CLOSE

PASS:		-

RETURN:		-

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@


ContentVisClose	method	AmateurContentClass, MSG_VIS_CLOSE

	; call superclass
	push	di
	mov	di, offset AmateurContentClass
	call	ObjCallSuperNoLock
	pop	di

	; If the game is running, pause it

	cmp	ds:[di].ACI_status, AGS_RUNNING
	jne	afterPause
	call	ContentPauseGame

afterPause:

	; nuke the gstate

	clr	cx	
	xchg	cx, es:[gstate]
	jcxz	done
	mov	di, cx
	call	GrDestroyState	
done:
	ret
ContentVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentKBDChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle keyboard events

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentKBDChar	method	dynamic	AmateurContentClass, 
					MSG_META_KBD_CHAR
	uses	ax,cx,dx,bp
	.enter

	mov	bp, di		; instance ptr

	; Only pay attention to first presses

	test	dl, mask CF_FIRST_PRESS
	jz	done

	; ignore releases and repeat presses

	test	dl, mask CF_RELEASE or mask CF_REPEAT_PRESS
	jnz	done

	; See if it's off the left edge of the screen

	mov	al, cl
	mov	dl, cl
	mov	di, offset LeftPelletList
	mov	cx, length LeftPelletList
	repne	scasb
	je	leftBlaster

	mov	al, dl
	mov	di, offset RightPelletList
	mov	cx, length RightPelletList
	repne	scasb
	jne	done

	mov	di, bp
	mov	cx, ds:[di].ACI_mouse.P_x
	mov	dx, ds:[di].ACI_mouse.P_y
	call	ShootRightPellet
	jmp	done

leftBlaster:
	mov	di, bp
	mov	cx, ds:[di].ACI_mouse.P_x
	mov	dx, ds:[di].ACI_mouse.P_y
	call	ShootLeftPellet
done:
	.leave
	ret
ContentKBDChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShootRightPellet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		ds:di - content
		cx, dx - end position

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShootRightPellet	proc near
	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSDI		> 

	mov	ax, ds:[di].VCNI_viewWidth
	sub	ax, BLASTER_WIDTH
	call	ContentButtonCommon
	jnc	done

	mov	ax, MSG_BLASTER_DRAW_ALT_NEXT_TIME
	mov	si, offset RightBlaster
	call	ObjCallInstanceNoLock 

done:
	.leave
	ret
ShootRightPellet	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShootLeftPellet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shoot a pellet from the left of the screen

CALLED BY:

PASS:		ds:di - content
		cx, dx - position

RETURN:		nothing 
		

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShootLeftPellet	proc near
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		> 

	clr	ax
	call	ContentButtonCommon
	jnc	done

	mov	ax, MSG_BLASTER_DRAW_ALT_NEXT_TIME
	mov	si, offset LeftBlaster
	call	ObjCallInstanceNoLock 
done:
	.leave
	ret
ShootLeftPellet	endp


	



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Store the mouse position in case user presses a key

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentPtr	method	dynamic	AmateurContentClass, 
						MSG_META_PTR
	mov	ds:[di].ACI_mouse.P_x, cx
	mov	ds:[di].ACI_mouse.P_y, dx
	mov	ax, mask MRF_PROCESSED
	ret
ContentPtr	endm


	

COMMENT @-------------------------------------------------------------------
		ContentStartSelect
----------------------------------------------------------------------------

SYNOPSIS:	When a button is pressed, this message is sent to the
		content object from the UI.  The content tries to get
		a new pellet object going and sends it on its way.

CALLED BY:	

PASS:		cx, dx - x and y posn of button press
		*ds:si - AmateurContent instance data

RETURN:		ax - mask MRF_PROCESSED

DESTROYED:	cx, dx, bp
 
PSEUDO CODE/STRATEGY:
		Go through the pellet array, find the first free pellet
		Get its handle, and send that pellet a message to 
		shoot itself

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
	
ContentStartSelect	method AmateurContentClass, MSG_META_START_SELECT

	call	ShootLeftPellet
	mov	ax, mask MRF_PROCESSED
	ret

ContentStartSelect	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentButtonCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to handle a button or key press

CALLED BY:

PASS:		ax - left edge of blaster to shoot from

		ds:di - content
		cx, dx, - ending position

RETURN:		carry - SET if bullet fired

DESTROYED:	ax,bx,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentButtonCommon	proc near
	class	AmateurContentClass 
	uses	si, di

	.enter

	CheckHack <size PelletParams eq 5 * size word>

	push	ds:[di].ACI_colorInfo.CI_pellets
	push	dx
	push	cx
	mov	cx, ds:[di].VCNI_viewHeight
	sub	cx, ds:[di].ACI_blasterHeight
	add	cx, BLASTER_HOT_Y
	push	cx
	add	ax, BLASTER_HOT_X
	push	ax
	mov	bp, sp

	; Is the game running?  Then shame on the user!

	cmp	ds:[di].ACI_status, AGS_RUNNING
	jne	noFire

	tst	es:[gstate] 
	jz	noFire
	
	tst	ds:[di].ACI_actInfo.AI_pellets
	jz	noneLeft		; don't fire if no pellets left!

	mov	ax, MAX_PELLETS
	mov	bx, offset ACI_pellets
	call	FindFreeObject
	jnc	maxPellets

	; draw some lines at the current position

	call	DrawPelletMark

	ornf	ds:[di].ACI_display, mask DF_PELLETS_LEFT
	dec	ds:[di].ACI_actInfo.AI_pellets
	cmp	ds:[di].ACI_actInfo.AI_pellets, 5
	jge	afterFew
	mov	ds:[di].ACI_sound, ST_FEW_PELLETS

afterFew:
	mov	ds:[si].HS_status, 1	; we've found a pellet to shoot!
	mov	si, ds:[si].HS_handle
	mov	ax, MSG_MOVE_START
	call	ObjCallInstanceNoLock
	stc
done:
	lahf
	add	sp, size PelletParams
	sahf
	.leave
	ret

noneLeft:
	mov	ds:[di].ACI_sound, ST_NO_PELLETS
	jmp	noFire

maxPellets:
	mov	ds:[di].ACI_sound, ST_MAX_PELLETS_ON_SCREEN

noFire:
	clc
	jmp	done
ContentButtonCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPelletMark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a cross where the user pressed the button

CALLED BY:	ContentButtonCommon

PASS:		ss:bp - PelletParams
		ds:di - content
	
RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawPelletMark	proc near	
	uses	di
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		> 

	mov	ax, ds:[di].ACI_colorInfo.CI_pellets
	mov	di, es:[gstate]
	call	GrSetLineColor
	clrdw	dxax
	call	GrSetLineWidth
	mov	ax, ss:[bp].BP_end.P_x
	mov	bx, ss:[bp].BP_end.P_y
	mov	cx, ax
	mov	dx, bx

	sub	ax, PELLET_MARK_SIZE/2
	add	cx, PELLET_MARK_SIZE/2
	sub	bx, PELLET_MARK_SIZE/2
	add	dx, PELLET_MARK_SIZE/2
	call	GrDrawEllipse

	.leave
	ret
DrawPelletMark	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	handle right-mouse button press

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentStartMoveCopy	method	dynamic	AmateurContentClass, 
					MSG_META_START_MOVE_COPY

	call	ShootRightPellet
	mov	ax, mask MRF_PROCESSED
	ret
ContentStartMoveCopy	endm




COMMENT @-------------------------------------------------------------------
		FindFreeObject		
----------------------------------------------------------------------------

SYNOPSIS:	Starting at the array (address passed in), find a free
		object.
CALLED BY:	GameButtonPressed, EndPellet, etc.
PASS:		ax - max size of array
		bx - offset from start of GCI to array
		*ds:si - AmateurContent instance data 

RETURN:		carry set if found
		ds:si - address of array element

DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
FindFreeObject	proc	near
	.enter
EC <	call	ECCheckContentDSSI		> 
	mov	si, ds:[si]
	add	si, ds:[si].AmateurContent_offset
	add	si, bx

FFO_loop:
	tst	ds:[si].HS_status
	jz	found
	add	si, size HandleStruct
	dec	ax
	jnz	FFO_loop
	clc
done:
	.leave
	ret	
found:
	stc
	jmp	done

FindFreeObject	endp

	


COMMENT @-------------------------------------------------------------------
		ContentTimerTick		
----------------------------------------------------------------------------

SYNOPSIS:	Each time the timer ticks, Tell everything to move itself
CALLED BY:	MSG_TIMER_TICK

PASS:		cx:dx = tick count
		ds:di - AmateurContent instance data
		*ds:si  - AmateurContent object

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
ContentTimerTick  	method	AmateurContentClass, MSG_TIMER_TICK

locals	local	TimerTickVars
	.enter

	cmp	ds:[di].ACI_status, AGS_RUNNING
	LONG jne done
	
	tst	es:[gstate] 
	jz	done

	mov	cx, INTERVAL_STD_TIMER
	mov	dx, MSG_TIMER_TICK
	call	ContentSetupTimer	; set up the timer for another
					; go... 

	call	ContentDisplay

	mov	locals.TTV_callOnNotEnd, offset Stub
	mov	locals.TTV_callback, offset PelletMove
	mov	locals.TTV_callOnEnd, offset ContentStartCloud
	mov	locals.TTV_array, offset ACI_pellets
	mov	ax, MAX_PELLETS
	call	TimerTickLoop

	; Update peanuts
	mov	ax, MAX_PEANUTS	
	mov	locals.TTV_callback, offset PeanutMove
	mov	locals.TTV_callOnEnd, offset ContentEndPeanut
	mov	locals.TTV_array, offset ACI_peanuts
	call	TimerTickLoop

	; Update smart peanuts
	mov	ax, MAX_TOMATOES
	mov	locals.TTV_callback, offset TomatoMove
	mov	locals.TTV_callOnEnd, offset ContentEndTomato
	mov	locals.TTV_array, offset ACI_Tomatoes
	call	TimerTickLoop
	
	; Update clouds
	mov	ax, MAX_CLOUDS
	mov	locals.TTV_callOnEnd, offset ContentEndCloud
	mov	locals.TTV_callOnNotEnd, offset ContentSendCloudToPeanuts
	mov	locals.TTV_array, offset ACI_clouds
	mov	locals.TTV_callback, offset Cloud
	call	TimerTickLoop

	push	bp
	call	ContentSendPeanut		; send any new peanuts
	call	ContentSendTomato
	call	ContentCheckActEnd
	pop	bp

done:
	.leave
	ret

ContentTimerTick	endm




COMMENT @-------------------------------------------------------------------
		TimerTickLoop
----------------------------------------------------------------------------

SYNOPSIS:	Called by ContentTimerTick, sends events to movable objects
		in the current array
CALLED BY:	
PASS:		ax - number of items
		ds:di - content instance data
		*ds:si - Content object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx
		
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

TimerTickLoop	proc	near
	uses	si,di
	class	AmateurContentClass 
locals	local	TimerTickVars
	.enter	inherit 

EC <	call	ECCheckContentDSDI		>
EC <	call	ECCheckContentDSSI		> 

	mov	bx, locals.TTV_array	; current element
	add	bx, di

startLoop:
	push	ax, bx
	tst	ds:[bx].HS_status
	jz	next

	push	bx, di, si, bp
	mov	si, ds:[bx].HS_handle
	mov	bx, locals.TTV_callback
	call	bx
	pop	bx, di, si, bp

	jc	callOnEnd
	call	locals.TTV_callOnNotEnd
	jmp	next

callOnEnd:
	clr	ds:[bx].HS_status	; status is DONE
	call	locals.TTV_callOnEnd

next:
	pop	ax, bx
	add	bx, size HandleStruct
	dec	ax
	jnz	startLoop
	.leave
	ret
TimerTickLoop	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentEndTomato
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke a smart peanut

CALLED BY:

PASS:		ds:di - content

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentEndTomato	proc near	
	class	AmateurContentClass

EC <	call	ECCheckContentDSDI		> 
	dec	ds:[di].ACI_screenTomatoes
	GOTO	ContentEndPeanutCommon
ContentEndTomato	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentEndPeanut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End the trajectory of a normal peanut

CALLED BY:	ContentTimerTick

PASS:		ds:di - content

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentEndPeanut	proc near	
	class	AmateurContentClass 
	dec	ds:[di].ACI_screenPeanuts
	FALL_THRU	ContentEndPeanutCommon
ContentEndPeanut	endp





COMMENT @---------------------------------------------------------------------
		ContentEndPeanutCommon
------------------------------------------------------------------------------

SYNOPSIS:	set things up on the content side to end a peanut
		see if any clowns were hit, or if blasters need to 
		be redrawn.

CALLED BY:	TimerTickLoop (ContentTimerTick)	

PASS:		cx, dx = peanut position (x,y)
		bp - score to add if peanut died as result of an
		cloud. 
		ds:di - content

RETURN:		

DESTROYED:	nothing 
 
PSEUDO CODE/STRATEGY:
	If peanut cloudd up in the air, start an cloud.
	Otherwise, check if peanut cloudd on the ground.  If so,
	start an cloud.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
ContentEndPeanutCommon	proc	near
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		>
EC <	call	ECCheckContentDSSI		>

	; See if peanut cloudd high or low

	mov	ax, ds:[di].VCNI_viewHeight
	mov	bx, es:[clownHeight]
	shr	bx
	sub	ax, bx

	cmp	ax, dx
	jg	higherUp

	mov	ax, MSG_BITMAP_CHECK_PEANUT
	call	CallAllBitmaps
	jnc	done
	call	ContentStartCloud
	mov	ds:[di].ACI_sound, ST_CLOWN_HIT
	dec	ds:[di].ACI_clownsLeft
done:
	.leave
	ret

higherUp:
	call	ContentStartCloud
	jmp	done
ContentEndPeanutCommon	endp




COMMENT @-------------------------------------------------------------------
		ContentStartCloud
----------------------------------------------------------------------------

SYNOPSIS:	Set things up on the Content Side to initiate an 
		cloud instance
CALLED BY:	AmateurTimerTick
PASS:		cx, dx - position of cloud
		ds:di - content
RETURN:	
DESTROYED:	ax,bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
ContentStartCloud	proc	near	
	uses	di, si, bp
	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSDI		>

	mov	ax, MAX_CLOUDS
	mov	bx, offset ACI_clouds
	call	FindFreeObject	; returns array location in si
	jnc	done		; if not found, forget it

	inc	ds:[si].HS_status
	mov	ax, MSG_MOVE_START
	mov	si, ds:[si].HS_handle
	call	ObjCallInstanceNoLock
done:
	.leave
	ret

ContentStartCloud	endp




COMMENT @-------------------------------------------------------------------
		ContentSendCloudToPeanuts
----------------------------------------------------------------------------

SYNOPSIS:	Send data about the current cloud to all peanuts

CALLED BY:	

PASS:		cx, dx - position of cloud
		ax - size of cloud

		*ds:si - content


RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx
		
 
PSEUDO CODE/STRATEGY:	send a message to each active peanut to see
			if it should end itself and initiate an cloud

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

ContentSendCloudToPeanuts	proc near	
	uses	si,di,bp
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		>

	mov	bp, ax		; cloud size

	mov	ax, MAX_PEANUTS
	lea	bx, ds:[di].ACI_peanuts
	mov	si, SCORE_PEANUT_HIT
	call	SendCloudLoop

	mov	ax, MAX_TOMATOES
	lea	bx, ds:[di].ACI_Tomatoes
	mov	si, SCORE_TOMATO
	call	SendCloudLoop
	.leave
	ret
ContentSendCloudToPeanuts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendCloudLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loop thru the peanuts or smart peanuts, sending
		cloud info to each.  If there's a hit, update
		the score

CALLED BY:

PASS:		ss:bp - SendCloudVars
		ax - number of elements in array
		ds:bx - array of peanuts/smart peanuts
		

RETURN:		nothing 

DESTROYED:	ax,bx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendCloudLoop	proc near
	class	AmateurContentClass 
	.enter	inherit

startLoop:
	tst	ds:[bx].HS_status
	jz	next	
	
	push	si
	mov	si, ds:[bx].HS_handle
	call	PeanutNotifyCloud
	pop	si
	jnc	next

	add	ds:[di].ACI_score.low, si
	adc	ds:[di].ACI_score.high, 0
	ornf	ds:[di].ACI_display, mask DF_SCORE
next:
	add	bx, size HandleStruct
	dec	ax
	jnz	startLoop
	.leave
	ret
SendCloudLoop	endp






COMMENT @-------------------------------------------------------------------
		CreateObjects		
----------------------------------------------------------------------------

SYNOPSIS:	Create all the pellet, peanut, cloud objects
		needed by the program.
CALLED BY:	ContentVisOpen

PASS:		*ds:si - Content

RETURN:		

DESTROYED:	nothing 
		
 
PSEUDO CODE/STRATEGY:
		Allocate all the objects, storing their handles in the
		GCI arrays

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@

CreateObjects	proc	near
	uses	ax,bx,cx,dx,di,bp
	
	class	AmateurContentClass
	.enter

EC <	call	ECCheckContentDSDI		>
EC <	call	ECCheckContentDSSI		> 

	mov	di, offset AmateurPelletClass
	mov	bx, offset ACI_pellets
	mov	cx, MAX_PELLETS
	call	CreateObjectsOfClass
	
	mov	di, offset AmateurPeanutClass
	mov	bx, offset ACI_peanuts
	mov	cx, MAX_PEANUTS
	call	CreateObjectsOfClass

	mov	di, offset TomatoClass
	mov	bx, offset ACI_Tomatoes
	mov	cx, MAX_TOMATOES
	call	CreateObjectsOfClass

	mov	di, offset AmateurCloudClass
	mov	bx, offset ACI_clouds
	mov	cx, MAX_CLOUDS
	call	CreateObjectsOfClass
	.leave
	ret		
CreateObjects	endp


COMMENT @-------------------------------------------------------------------
		CreateObjectsOfClass		
----------------------------------------------------------------------------

SYNOPSIS:	create a single object
CALLED BY:	CreateObjects
PASS:		*ds:si - ContentObject
		es:di - class definition
		bx - offset to array (in GCI) in which to store handle

		bx - object block handle
		cx - number of objects to create 
RETURN:	
DESTROYED:	ax,bx,cx,dx,bp
 
REGISTER USAGE:
		cx - counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@


CreateObjectsOfClass	proc	near
	class 	AmateurContentClass
	.enter

startLoop:
	push	bx, cx, si
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate
	mov	ax, si			; chunk handle of new object
	pop	bx, cx, si

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	clr	ds:[bx][di].HS_status
	mov	ds:[bx][di].HS_handle, ax	; new chunk handle
	add	bx, size HandleStruct
	pop	di

EC <	call	ECCheckContentDSSI		>

	loop	startLoop

	.leave
	ret

CreateObjectsOfClass	endp


COMMENT @---------------------------------------------------------------------
		ContentSendPeanut
------------------------------------------------------------------------------

SYNOPSIS:	Send a new peanut

CALLED BY:	ContentTimerTick

PASS:		ds:di - AmateurContent instance data 
		*ds:si - AmateurContent object

RETURN:		nothing 

DESTROYED:	ax, bx, cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
ContentSendPeanut	proc	near
	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSDI		>
EC <	call	ECCheckContentDSSI		> 

	; set up stack frame to send to peanuts

	CheckHack <size PeanutParams eq 8 * size word>

	push	ax			; view Height (will be set
					; later)

	push	ds:[di].VCNI_viewWidth
	push	ds:[di].ACI_colorInfo.CI_trail
	push	ds:[di].ACI_colorInfo.CI_peanut
	push	ds:[di].ACI_actInfo.AI_speed
	push	ds:[di].ACI_actInfo.AI_maxScreenPeanuts
	push	ds:[di].ACI_screenPeanuts
	push	ds:[di].ACI_actInfo.AI_peanuts
	mov	bp, sp

	mov	ax, MAX_PEANUTS
	mov	bx, offset ACI_peanuts
	call	SendPeanutCommon

	; store updated values

	mov	ax, ss:[bp].MP_actPeanuts
	mov	ds:[di].ACI_actInfo.AI_peanuts, ax

	mov	ax, ss:[bp].MP_screenPeanuts
	mov	ds:[di].ACI_screenPeanuts, ax

	add	sp, size PeanutParams

	.leave
	ret
ContentSendPeanut	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSendTomato
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send off a smart peanut

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSendTomato	proc near	
	class	AmateurContentClass
	.enter
EC <	call	ECCheckContentDSDI		>
EC <	call	ECCheckContentDSSI		> 

	; set up stack frame to send to peanuts

	CheckHack <size PeanutParams eq 8 * size word>

	push	ax	; true value will be filled in later
	push	ds:[di].VCNI_viewWidth
	push	ds:[di].ACI_colorInfo.CI_trail
	push	ds:[di].ACI_colorInfo.CI_Tomato
	push	ds:[di].ACI_actInfo.AI_speed
	push	ds:[di].ACI_actInfo.AI_maxScreenTomatoes
	push	ds:[di].ACI_screenTomatoes
	push	ds:[di].ACI_actInfo.AI_tomatoes
	mov	bp, sp

	mov	ax, MAX_TOMATOES
	mov	bx, offset ACI_Tomatoes
	call	SendPeanutCommon

	; store updated values

	mov	ax, ss:[bp].MP_actPeanuts
	mov	ds:[di].ACI_actInfo.AI_tomatoes, ax

	mov	ax, ss:[bp].MP_screenPeanuts
	mov	ds:[di].ACI_screenTomatoes, ax

	add	sp, size PeanutParams

	.leave
	ret
ContentSendTomato	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendPeanutCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send either a peanut or a smart peanut

CALLED BY:

PASS:		ss:bp - PeanutParams
		*ds:si - content
		ds:di - content

		ax - size of array
		bx - offset in AmateurContent instance data to array 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendPeanutCommon	proc near	
	uses	di,si
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		> 

	mov	ax, ds:[di].VCNI_viewHeight
	mov	dx, es:[clownHeight]
	shr	dx, 1
	sub	ax, dx
	mov	[bp].MP_viewHeight, ax

	call	FindFreeObject
	jnc	done

	tst	ss:[bp].MP_actPeanuts 	; see if any more peanuts
	jz	done

	; See if the screen is currently full

	mov	ax, ss:[bp].MP_screenPeanuts
	cmp	ax, ss:[bp].MP_maxScreenPeanuts
	je	done

	; Increment the number of peanuts on-screen, decrement total
	; number for this act

	inc	ss:[bp].MP_screenPeanuts
	dec	ss:[bp].MP_actPeanuts

	; Send it the message
	inc	ds:[si].HS_status
	mov	si, ds:[si].HS_handle
	mov	ax, MSG_MOVE_START
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
SendPeanutCommon	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentCheckActEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Run through all data structures, see if everything is done

CALLED BY:

PASS:		*ds:si - Content object
		ds:di - content instance data

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentCheckActEnd	proc near	
	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSDI		>
EC <	call	ECCheckContentDSSI		> 


	; Make sure there aren't any objects moving

	mov	cx, MAX_MOVABLE_OBJECTS
	lea	bx, ds:[di].ACI_pellets

startLoop:
	tst	ds:[bx].HS_status
	jnz	done
	add	bx, size HandleStruct
	loop	startLoop
	
	call	ContentEndAct

done:
	.leave
	ret
ContentCheckActEnd	endp




COMMENT @---------------------------------------------------------------------
		ContentEndAct	
------------------------------------------------------------------------------

SYNOPSIS:	Give player bonus points for each unused pellet
		check for no clowns left -- if so, end game
		increment the "level" counter
		check for score going over multiples of 20,000.  If so,
		give player a random clown

CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	ax,bx,cx,dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	1/91		initial revision
---------------------------------------------------------------------------@
	
ContentEndAct	proc	near

	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSSI		> 
EC <	call	ECCheckContentDSDI		> 

	mov	ds:[di].ACI_status, AGS_BETWEEN_ACTS

	call	ContentStopTimer

	mov	ax, MSG_BITMAP_DRAW_IF_NEEDED
	call	CallAllBitmaps

	; Update score for remaining clowns

	call	ContentTallyClowns

	; Update score for extra pellets

	mov	cx, ds:[di].ACI_actInfo.AI_pellets
	jcxz	afterPellets

startLoop:
	adddw	ds:[di].ACI_score, SCORE_PELLET_LEFT
	dec	ds:[di].ACI_actInfo.AI_pellets
	call	ContentDisplayScore
	call	ContentDisplayPelletsLeft
	loop	startLoop

afterPellets:

	; Figure out if user gets a new clown

	movdw	dxax, ds:[di].ACI_scoreLastAct
	mov	cx, SCORE_EXTRA_CLOWN
	div	cx
	mov	bx, ax

	movdw	dxax, ds:[di].ACI_score
	div	cx

	sub	ax, bx		; number of extra clowns
	call	MakeClownsAlive

	; Figure out if game over

	tst	ds:[di].ACI_clownsLeft
	jnz	gameNotOver
	call	ContentGameOver
	jmp	done

gameNotOver:
	inc	ds:[di].ACI_act
	call	ContentPrepareNextAct

done:
	.leave
	ret
ContentEndAct	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentPrepareNextAct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start an act

CALLED BY:

PASS:		ds:di - content

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentPrepareNextAct	proc near	
	uses	di,si
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSDI		>
EC <	call	ECCheckContentDSSI		> 


	mov	ds:[di].ACI_status, AGS_BETWEEN_ACTS

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset 

	clr	ds:[di].ACI_screenPeanuts
	clr	ds:[di].ACI_screenTomatoes

	movdw	ds:[di].ACI_scoreLastAct, ds:[di].ACI_score, ax

	call	DisplayAct

	call	ContentSetActInfo

	; Set all pellets/peanuts/clouds to "unused" status

	clr	al
	lea	bx, ds:[di].ACI_pellets
	mov	cx, MAX_MOVABLE_OBJECTS
resetLoop:
	mov	ds:[bx].HS_status, al
	add	bx, size HandleStruct
	loop	resetLoop

	mov	bp, es:[gstate]
	mov	ax, MSG_VIS_DRAW
	call	ContentDraw

	call	ContentChooseJoke

	mov	cx, START_ACT_INTERVAL
	mov	dx, MSG_CONTENT_START_ACT
	call	ContentSetupTimer

	.leave
	ret
ContentPrepareNextAct	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGameOver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End the game

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGameOver	proc near	
	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSDI		> 

	mov	ds:[di].ACI_sound, ST_GAME_OVER
	call	ContentPlaySound

	mov	ds:[di].ACI_status, AGS_OVER
	call	DisplayGameOverText

	mov	ax, INTERVAL_GAME_OVER
	call	TimerSleep

	movdw	dxcx, ds:[di].ACI_score
	mov	ax, MSG_HIGH_SCORE_ADD_SCORE
	mov	bx, handle AmateurHighScore
	mov	si, offset AmateurHighScore
	clr	bp
	clr	di
	call	ObjMessage 
		
	;
	; Nuke the Abort and Pause triggers
	;
		
	clr	cl
	call	EnableTriggers

	.leave
	ret
ContentGameOver	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSetActInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the act data for the content for the current
		act. 

CALLED BY:

PASS:		ds:di - content
		es - idata  

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSetActInfo	proc near	
	uses	di,si
	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSDI		> 

	mov	ax, ds:[di].ACI_act
	dec	ax

	Min	ax, <MAX_ACT-1>
	mov	bx, size ActInfo
	mul	bx
	mov	si, ax
	add	si, offset ActTable
	lea	di, ds:[di].ACI_actInfo
	mov	cx, size ActInfo/2

	segxchg	ds, es, ax
	rep	movsw
	segxchg	ds, es, ax


	.leave
	ret
ContentSetActInfo	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetColorInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color information based on the display type.

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetColorInfo	proc near
	uses	ax,cx,di,si,es,ds
	class	AmateurContentClass 
	.enter
	
	
	mov	al, es:[displayType]
	andnf	al, mask DT_DISP_CLASS
	cmp	al, DC_GRAY_1 shl offset DT_DISP_CLASS
	jne	color
	
	mov	si, offset BWColorTable
	jmp	copy
color:
	mov	si, offset ColorColorTable
copy:
	lea	di, ds:[di].ACI_colorInfo
	segxchg	ds, es, cx
	mov	cx, size ColorInfo/2
	rep	movsw

	.leave
	ret
SetColorInfo	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckContentDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		*ds:si - content

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK

ECCheckContentDSSI	proc near	
	.enter
	pushf
	cmp	si, offset	ContentObject
	ERROR_NE	SI_NOT_POINTING_AT_CONTENT_OBJECT
	popf
	call	ECCheckObject
 	.leave
	ret
ECCheckContentDSSI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckContentDSDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckContentDSDI	proc near	
	uses	si
	.enter
	pushf
	assume	ds:GameObjects
	mov	si, ds:[ContentObject]
	add	si, ds:[si].Vis_offset
	cmp	si, di
	ERROR_NE DS_DI_NOT_POINTING_AT_CONTENT_OBJECT
	popf
	assume	ds:dgroup
 	.leave
	ret
ECCheckContentDSDI	endp




endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeClownsAlive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring a number of clowns back to life

CALLED BY:

PASS:		ax - number of clowns to restore (usually 1)

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeClownsAlive	proc near	
	uses	ax,bx,cx,dx,di,si,bp
	class	AmateurContentClass 
	.enter
EC <	call	ECCheckContentDSDI		>
EC <	call	ECCheckContentDSSI		>

outerLoop:
	tst	ax
	jz	done

	cmp	ds:[di].ACI_clownsLeft, NUM_CLOWNS
	je	done

	mov	ds:[di].ACI_sound, ST_EXTRA_CLOWN
	inc	ds:[di].ACI_clownsLeft
	dec	ax
	push	ax

findDeadClown:
	mov	dx, NUM_CLOWNS
	call	GameRandom
	mov	ax, MSG_CLOWN_GET_STATUS
	mov	bx, dx
	call	CallClown
	cmp	cl, CS_ALIVE
	je	findDeadClown

	; bx is number of clown to make alive

	mov	ax, MSG_CLOWN_SET_STATUS
	mov	cl, CS_ALIVE
	call	CallClown

	pop	ax
	jmp	outerLoop

done:
	call	DrawClowns

	.leave
	ret
MakeClownsAlive	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallClown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a message to a clown

CALLED BY:	MakeClownsAlive

PASS:		ax - message
		bx - clown #
		cx, dx, bp - message data

RETURN:		ax,cx,dx,bp - returned by clown 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallClown	proc near	
	uses	bx, si
	.enter
	shl	bx, 1
	mov	si, cs:clownTable[bx]
	call	ObjCallInstanceNoLock
	.leave
	ret
CallClown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallAllClowns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call all clowns 

CALLED BY:

PASS:		ax, cx, dx, bp - message data

RETURN:		ax, cx, dx, bp - returned from clowns

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

	CALLED ROUTINE:
		can destroy/modify cx,dx,bp


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallAllClowns	proc near	
	uses	bx, si
	.enter
	mov	bx, (offset clownTable) + (size clownTable)
	mov	si, offset clownTable
	call	CallObjects
	.leave
	ret
CallAllClowns	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallAllBitmaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call all blasters & clowns

CALLED BY:

PASS:		ax,cx,dx,bp - message data

RETURN:		ax,cx,dx,bp - returned from called object

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallAllBitmaps	proc near
	uses	bx,si
	.enter
	mov	bx, (offset bitmapTable) + (size bitmapTable)
	mov	si, offset bitmapTable
	call	CallObjects
	.leave
	ret
CallAllBitmaps	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallObjects	proc near
	.enter

startLoop:
	push	ax, si
	mov	si, cs:[si]
	call	ObjCallInstanceNoLock
	pop	ax, si
	jc	done
	add	si, 2
	cmp	si, bx
	jl	startLoop
done:

	.leave
	ret
CallObjects	endp




bitmapTable	word	\
	offset	LeftBlaster,
	offset	Clown0,
	offset	Clown1,
	offset	Clown2,
	offset	Clown3,
	offset	Clown4,
	offset	Clown5,
	offset	RightBlaster

clownTable	word	\
	offset	Clown0,
	offset	Clown1,
	offset	Clown2,
	offset	Clown3,
	offset	Clown4,
	offset	Clown5




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		cl - TriggerFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableTriggers	proc near	
	uses	ax,bx,cx,dx,di,si,bp
	.enter
	
	clr	bp
	mov	bx, handle Interface
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FORCE_QUEUE

startLoop:
	mov	si, cs:TriggerTable[bp]
	shl	cl
	jnc	disable
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	sendIt

disable:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
sendIt:
	push	ax, cx, dx, bp
	call	ObjMessage
	pop	ax, cx, dx, bp
	add	bp, 2
	cmp	bp, size TriggerTable
	jl	startLoop

	.leave
	ret
EnableTriggers	endp



TriggerTable	word	\
	offset	AbortTrigger,	
	offset	PauseTrigger,
	offset	ContinueTrigger





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentTallyClowns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add up scores for each remaining clown

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentTallyClowns	proc near	
	class	AmateurContentClass 
	.enter
	clr	ax
	push	ax		; CSP_scoreTally
	mov	ax, STD_TEXT_HEIGHT
	push	ax		; CSP_textHeight
	mov	ax, SCORE_CLOWN_ADDER
	push	ax		; CSP_scoreAdder
	mov	ax, SCORE_CLOWN
	push	ax		; CSP_score
	push	ds:[di].ACI_colorInfo.CI_Tomato
	mov	bp, sp

	mov	ax, MSG_CLOWN_TALLY_SCORE
	call	CallAllClowns
	mov	ax, ss:[bp].CSP_scoreTally
	clr	bx
	adddw	ds:[di].ACI_score, bxax
	add	sp, size ClownScoreParams
	.leave
	ret
ContentTallyClowns	endp




Stub	proc	near
	ret
Stub	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the display

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentDisplay	proc near	
	uses	bp
	class	AmateurContentClass 
	.enter

	call	ContentPlaySound

	mov	ax, MSG_BITMAP_DRAW_IF_NEEDED
	call	CallAllBitmaps

	test	ds:[di].ACI_display, mask DF_SCORE
	jz	afterDisplayScore
	call	ContentDisplayScore
	andnf	ds:[di].ACI_display, not mask DF_SCORE

afterDisplayScore:
	test	ds:[di].ACI_display, mask DF_PELLETS_LEFT
	jz	done
	call	ContentDisplayPelletsLeft
	andnf	ds:[di].ACI_display, not mask DF_PELLETS_LEFT
done:
	.leave
	ret
ContentDisplay	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentStartAct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Start the next act

PASS:		*ds:si	= GameContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentStartAct	method	dynamic	AmateurContentClass, 
					MSG_CONTENT_START_ACT
	uses	ax,cx,dx,bp
	.enter
	cmp	ds:[di].ACI_status, AGS_BETWEEN_ACTS
	jne	done

	mov	ds:[di].ACI_status, AGS_RUNNING

	push	si
	mov	cx, IC_DISMISS		
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	bx, handle JokeSummons
	mov	si, offset JokeSummons
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset 

	call	ContentStartTimer
	ornf	ds:[di].ACI_display, mask DF_PELLETS_LEFT or\
				mask DF_SCORE


done:
	.leave
	ret
ContentStartAct	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentLostKbd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops the game timers and temporarily pauses.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentLostKbd	method	dynamic AmateurContentClass, MSG_META_LOST_KBD_EXCL,
						MSG_META_LOST_SYS_TARGET_EXCL,
						MSG_META_LOST_SYS_FOCUS_EXCL
	mov	ax, MSG_CONTENT_TEMP_PAUSE
	call	ObjCallInstanceNoLock
	ret
	
ContentLostKbd	endm
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentGainedKbd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restarts the game timers.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	1/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentGainedKbd	method	dynamic AmateurContentClass, 
						MSG_META_GAINED_KBD_EXCL,
						MSG_META_GAINED_SYS_TARGET_EXCL,
						MSG_META_GAINED_SYS_FOCUS_EXCL
	mov	ax, MSG_CONTENT_END_TEMP_PAUSE
	call	ObjCallInstanceNoLock
	ret
ContentGainedKbd	endm		




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentTempPause
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentTempPause	method	dynamic	AmateurContentClass, 
					MSG_CONTENT_TEMP_PAUSE

	cmp	ds:[di].ACI_status, AGS_RUNNING
	jne	done
	mov	ds:[di].ACI_status, AGS_TEMP_PAUSED
done:
	ret
ContentTempPause	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentEndTempPause
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= AmateurContentClass object
		ds:di	= AmateurContentClass instance data
		es	= Segment of AmateurContentClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ContentEndTempPause	method	dynamic	AmateurContentClass, 
					MSG_CONTENT_END_TEMP_PAUSE


	cmp	ds:[di].ACI_status, AGS_TEMP_PAUSED
	jne	done
	call	ContentStartTimer	; will set status to RUNNING
done:
	ret
ContentEndTempPause	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentEndCloud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call all blasters, clowns to see if they should redraw
		selves. 

CALLED BY:

PASS:		cx, dx - position of cloud

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentEndCloud	proc near
	.enter
	mov	ax, MSG_BITMAP_CHECK_CLOUD
	call	CallAllBitmaps

	.leave
	ret
ContentEndCloud	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSetClownMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assign one moniker to each clown, making sure that all
		six are assigned

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSetClownMonikers	proc near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	mov	cx, NUM_CLOWNS
	mov	ax, MSG_CLOWN_SET_MONIKER

startLoop:

	; pick a clown to have this moniker

	mov	dx, NUM_CLOWNS
	call	GameRandom
	mov	bx, dx
	call	CallClown
	jc	startLoop	; carry.  Choose another clown
				; instead. 
	; Now, on to the next 

	loop	startLoop

	.leave
	ret
ContentSetClownMonikers	endp




