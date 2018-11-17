COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (gadgets code common to all specific UIs)
FILE:		copenButtonCommon.asm

ROUTINES:
	Name			Description
	----			------------
    INT OLButtonDetermineIfNewState 
				Draw this button if its state has changed
				since the last draw.

    INT OLButtonDrawLATERIfNewStateFar 
				Redraw the button, delaying the update via
				the UI queue, or until the next EXPOSE,
				whichever is appropriate.

    INT OLButtonDrawLATERIfNewState 
				Redraw the button, delaying the update via
				the UI queue, or until the next EXPOSE,
				whichever is appropriate.

    INT OLButtonActivate        This routine sends the ActionDescriptor for
				this trigger.

    INT OLButtonSendCascadeModeToMenuFar 
				Calls OLButtonSendCascadeModeToMenu

    INT OLButtonSendCascadeModeToMenu 
				Packages up a MSG_MO_MW_CASCADE_MODE
				message and sends it to the menu window
				object.

    INT OLButtonSaveStateSetBorderedAndOrDepressed 
				This procedure makes sure that this
				GenTrigger is drawn as depressed, which
				depending upon the specific UI might mean
				DEPRESSED (blackened) and/or BORDERED.

    INT OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW 
				This routine resets the DEPRESSED and
				BORDERED flags as necessary, and then
				immediately redraws the button if necessary

    INT OLButtonSaveBorderedAndDepressedStatus 
				Save the current BORDERED status of this
				button so that it can be
				restored. Basically, it is nearly
				impossible to tell wether a button at rest
				should be bordered or not, because buttons
				in pinned menus change.

    INT OLButtonRestoreBorderedAndDepressedStatus 
				Save the current BORDERED status of this
				button so that it can be
				restored. Basically, it is nearly
				impossible to tell wether a button at rest
				should be bordered or not, because buttons
				in pinned menus change.

    INT OLButtonEnsureMouseGrab This procedure makes sure that this button
				has the mouse grab (exclusive).

    INT OLButtonGrabExclusives  This procedure grabs some exclusives for
				the button object. Regardless of the carry
				flag, the gadget and default exclusives are
				grabbed.

    MTD MSG_META_GAINED_SYS_FOCUS_EXCL 
				This procedure is called when the window in
				which this button is located decides that
				this button has the focus exclusive.

    INT OLButtonSaveStateSetCursored 
				This routine tests if the button is pressed
				already, and if not, saves the button's
				current bordered and depressed state, and
				sets the new state, so that the button
				shows the cursored emphasis.

    MTD MSG_META_LOST_SYS_FOCUS_EXCL 
				This procedure is called when the window in
				which this button is located decides that
				this button does not have the focus
				exclusive.

    MTD MSG_VIS_LOST_GADGET_EXCL 
				HandleMem losing of gadget exclusive.  We
				MUST release any gadget exclusive if we get
				this method, for it is used both for the
				case of the grab being given to another
				gadget & when a window on which this gadget
				sits is being closed.

    MTD MSG_META_GAINED_DEFAULT_EXCL 
				This method is sent by the parent window
				(see OpenWinGupQuery) when it decides that
				this GenTrigger should have the default
				exclusive.

    INT CallMethodIfApplyOrReset 
				Calls passed method on itself if apply or
				reset button.

    MTD MSG_SPEC_NOTIFY_ENABLED We intercept these methods here to make
				sure that the button redraws and that we
				grab or release the master default
				exclusive for the window.

    MTD MSG_SPEC_NOTIFY_NOT_ENABLED 
				We intercept these methods here to make
				sure that the button redraws and that we
				grab or release the master default
				exclusive for the window.

    INT FinishChangeEnabled     We intercept these methods here to make
				sure that the button redraws and that we
				grab or release the master default
				exclusive for the window.

    INT OLButtonResetMasterDefault 
				Releases "Master Default" exclusive, if
				this button has it.

    MTD MSG_VIS_DRAW            Draw the button

    INT UpdateButtonState       Note which specific state flags have been
				set in order to use this information for
				later drawing optimizations. Also, notes
				the enabled/disabled state.

    INT OLButtonDrawMoniker     Draw the moniker for this button.

    MTD MSG_VIS_OPEN            Called when the button is to be made
				visible on the screen. Subclassed to check
				if this is a button in the title bar that
				required rounded edges.

    INT OLButtonReleaseMouseGrab 
				This procedure makes sure that this button
				has released the mouse grab (exclusive).

    INT OLButtonReleaseDefaultExclusive 
				This procedure releases the default
				exclusive for this button. The window will
				send a method to itself on the queue, so
				that if no other button grabs the default
				exclusive IMMEDIATELY, the master default
				for the window will grab it.

    INT OLButtonReleaseAllGrabs Intercept this method here to ensure that
				this button has released any grabs it may
				have.

    MTD MSG_SPEC_SET_LEGOS_LOOK Set the hints on a button according to the
				legos look requested, after removing the
				hints for its previous look. These hints
				are stored in tables that each different
				SpecUI will change according to the legos
				looks they support.

    MTD MSG_SPEC_GET_LEGOS_LOOK Get the legos look of an object

    MTD MSG_OL_BUTTON_SET_DRAW_STATE_UNKNOWN 
				This procedure marks the button as invalid
				so that next time it is drawn, no
				optimizations are attempted.

    MTD MSG_OL_BUTTON_SET_BORDERED 
				Makes the button bordered/unbordered.  This
				makes it possible for popup menus to
				broadcast a notification to all its button
				children to draw their borders when the
				window is pinned.

    MTD MSG_SPEC_CHANGE         Does a "change" for this button.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenButton.asm

DESCRIPTION:

	$Id: copenButtonCommon.asm,v 1.2 98/03/11 05:44:50 joon Exp $

------------------------------------------------------------------------------@
CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonDrawNOWIfNewState

CALLED BY:	OLButtonGenActivate
		OLButtonMouse
		OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW

DESCRIPTION:	Draw this button if its state has changed since the last draw.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

;IMPORTANT: THIS IS NOT A DYNAMIC METHOD HANDLER, SO DO NOT EXPECT DS:DI.

OLButtonDrawNOWIfNewState	method	OLButtonClass, MSG_OL_BUTTON_REDRAW


	call	OLButtonDetermineIfNewState
	jz	done			;skip if no state change...

	call	OpenDrawObject		;draw object and save new state

done:
	ret
OLButtonDrawNOWIfNewState	endp


OLButtonDetermineIfNewState	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	al, {byte}ds:[di].OLBI_specState ;get new state
	xor	al, ds:[di].OLBI_optFlags 	 ;compare to old state

	call	OpenCheckIfKeyboard		 ;no keyboard, ignore cursored
	jnc	dontCheckCursored		 ;   state.  -cbh 

if _OL_STYLE	;--------------------------------------------------------------
	test	al, mask OLBSS_BORDERED or \
		    mask OLBSS_DEPRESSED or \
		    mask OLBSS_DEFAULT or \
		    mask OLBSS_SELECTED
endif		;--------------------------------------------------------------

if _CUA_STYLE	;--------------------------------------------------------------

	;CUA/Motif: if inside a menu, or if is a menu button, ignore the
	;cursored flag, because we set the BORDERED/DEPRESSED flag to show
	;something as cursored.  (Don't ignore if a popup list, with a
	;OLBSS_MENU_DOWN_MARK.)

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
					mask OLBSS_MENU_RIGHT_MARK
	jz	10$			;skip if standard button...

dontCheckCursored:

	;menu button, or button in menu:

	test	al, mask OLBSS_BORDERED or \
		    mask OLBSS_DEPRESSED or \
		    mask OLBSS_DEFAULT or \
		    mask OLBSS_SELECTED
	jmp	short 20$

10$:	;standard button

	test	al, mask OLBSS_BORDERED or \
		    mask OLBSS_DEPRESSED or \
		    mask OLBSS_CURSORED or \
		    mask OLBSS_DEFAULT or \
		    mask OLBSS_SELECTED
20$:
endif		;--------------------------------------------------------------
	ret
OLButtonDetermineIfNewState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonDrawLATERIfNewState

DESCRIPTION:	Redraw the button, delaying the update via the UI queue,
		or until the next EXPOSE, whichever is appropriate.

CALLED BY:	OLButtonGainedFocusExcl
		OLButtonLostFocusExcl
		OLButtonGainedDefaultExclusive
		OLButtonLostDefaultExclusive

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLButtonDrawLATERIfNewStateFar	proc	far
	call	OLButtonDrawLATERIfNewState
	ret
OLButtonDrawLATERIfNewStateFar	endp

OLButtonDrawLATERIfNewState	proc	near
	call	OLButtonDetermineIfNewState
	jz	exit

	;if there is a MSG_META_EXPOSED event pending for this window,
	;just add this button to the invalid region. Sending a method
	;to the queue will not help, because when it arrives, its drawing
	;may be clipped.

	push	cx, dx, bp
	push	si
	call	VisQueryWindow		;find Window for this OLWinClass
	or	di, di			;is it realized yet?
	jz	useManual		;skip if not...

	mov	si, WIT_FLAGS		;pass which info we need back
	call	WinGetInfo		;get info on Window structure
	test	al, mask WRF_EXPOSE_PENDING	;will a MSG_META_EXPOSED arrive?
	jz	useManual		;skip if not...

	pop	si
	call	OpenGetLineBounds
	push	si


	clr	bp			;region is rectangular
	clr	si
	call	WinInvalReg
afterInval::
	pop	si
	jmp	short done

useManual:
	pop	si

	mov	ax, MSG_OL_BUTTON_REDRAW
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	
	call	ObjMessage
done:
	pop	cx, dx, bp
exit:
	ret
OLButtonDrawLATERIfNewState	endp

CommonFunctional ends
CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonPtr

DESCRIPTION:	HandleMem pointer movement across button

CALLED BY:	MSG_META_PTR

PASS:		ds:*si - instance data
		cx, dx  - location
		bp	- [ UIFunctionsActive | buttonInfo ]
		ax	- message #

RETURN:		ax = MouseReturnFlags
			MRF_PROCESSED	- event was process by the button
			MRF_REPLAY	- event was released by the button

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@


OLButtonPtr	method	OLButtonClass, MSG_META_PTR
	;if not in a menu and we do not yet have the mouse grab, it means that
	;the mouse is simply dragging across this control. IGNORE this event.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = SpecificInstance
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU  \
					or mask OLBSS_IN_MENU_BAR
	jz	stdButton		;skip if in not in menu...


	;CUA/Motif: a menu button can be selected even if the mouse button
	;is not pressed. Allow mouse to slide over control without un-selecting
	;button.

CUAS <	test	bp, (mask UIFA_SELECT) shl 8 	;are we dragging?	     >
CUAS <	jz	returnProcessed			;skip if not...		     >
	jmp	short handlePtrEvent

stdButton:
	;want to avoid grabbing the mouse if we don't own it.

	test	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
	jz	returnProcessed		;if do not have grab, ignore event...

handlePtrEvent:
if BUBBLE_HELP
	mov	ax, MSG_META_PTR
endif
	GOTO	OLButtonMouse	;process normally

returnProcessed:
	;we are not dragging: we are just sliding across the button.
	;no need to upset the button state.

	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret
OLButtonPtr	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonRelease

DESCRIPTION:	HandleMem SELECT or FEATURES release on button.  The Trigger OD
		is then sent off.

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si - instance data
		cx, dx  - mouse location
		bp	- [ UIFunctionsActive | buttonInfo ]
		ax	- message #

RETURN:		ax = MouseReturnFlags
			MRF_PROCESSED	- event was process by the button
			MRF_REPLAY	- event was released by the button

DESTROYED:	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@

OLButtonRelease	method	OLButtonClass, MSG_META_END_SELECT

if BUBBLE_HELP
	;
	; clear bubble help, if any
	;
	push	cx, dx, bp
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	call	OpenCheckBubbleMinTime
	jc	leaveHelp
	call	OLButtonDestroyBubbleHelp
leaveHelp:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
	jnz	leaveGrab
	call	VisReleaseMouse		
leaveGrab:
	;
	; if disabled, return processed -- we only got here because
	; of bubble help (normal case doesn't grab mouse for disabled
	; button)
	;
	call	OpenButtonCheckIfFullyEnabled
	pop	cx, dx, bp
	jc	continueProcessing
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret

continueProcessing:
endif

	test	bp, (mask UIFA_IN) shl 8	; see if in bounds
	jz	50$				;skip if not...

	;SELECT or MENU ended within button: trigger!

	push	cx, dx, bp
	clr	cx			;assume not double press
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_WAS_DOUBLE_CLICKED
	jz	10$
	and	ds:[di].OLBI_moreAttrs, not mask OLBMA_WAS_DOUBLE_CLICKED
	dec	cx			;else mark as a double press
10$:
	call	OpenDoClickSound	; doing sound, make a noise
	;
	; New, exciting code to sleep a little if we're in pen mode, so 
	; we can see an inverting button.  
	;
	call	SysGetPenMode		; ax = TRUE if penBased
	tst	ax
	jz	20$
	push	ds
	mov	ax, segment olButtonInvertDelay
	mov	ds, ax
	mov	ax, ds:[olButtonInvertDelay]
	pop	ds
	call	TimerSleep
20$:					; only called once from jz above
	call	OLButtonActivate

if SHORT_LONG_TOUCH
	call	EndShortLongTouch	; send out short/long message if needed
endif
	pop	cx, dx, bp

50$:
if BUBBLE_HELP
	mov	ax, MSG_META_END_SELECT
endif
	GOTO	OLButtonMouse
OLButtonRelease	endp

CommonFunctional	ends
CommonFunctional	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonActivate

DESCRIPTION:	This routine sends the ActionDescriptor for this trigger.

CALLED BY:	

PASS:		*ds:si	= instance data for object
		cl -- non-zero if from user double-click

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLButtonActivate	proc	far
	uses	si, es
	.enter

	mov	ax, MSG_GEN_TRIGGER_SEND_ACTION	;assume is GenTrigger
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IMMEDIATE_ACTION
	pushf				;save results

	;if this OLButtonClass object was fabricated to open a command window
	;or summons, then send MSG_OL_POPUP_OPEN directly to the window.

	mov	di, ds:[si]		;point to instance data
	les	di, ds:[di].MB_class	;set es:di = class table for object
	cmp	es:[di].Class_masterOffset, offset Vis_offset
					;is the specific part the highest-
					;level master class for this object?
	jne	sendMethod		;skip if not (has generic part)...

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;make sure that OLSetting is handling activation itself.
EC <	test	ds:[di].OLBI_specState, mask OLBSS_SETTING		 >
EC <	ERROR_NZ OL_ERROR						 >

	mov	si, ds:[di].OLBI_genChunk	;si = chunk handle of window
						;(is in same ObjectBlock)
	mov	ax, MSG_OL_POPUP_ACTIVATE	;bring up command window

sendMethod:
	popf				;get IS_IMMEDIATE test results
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or \
		    mask MF_FIXUP_DS
	jz	afterCheck		;skip if not immediate...

	;this is an IMMEDIATE ACTION trigger: use MF_CALL.

	mov	di, mask MF_CALL or mask MF_FIXUP_DS

afterCheck:
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage

	.leave
	ret
OLButtonActivate	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonMouse

DESCRIPTION:	Process current ptr & function state to determine whether
		a button should be up or down

CALLED BY:	MSG_META_START_SELECT

		OLButtonPtr
		OLButtonRelease

PASS:		ds:*si	- OLButton object
		cx, dx	- ptr position
		bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:		ax = MouseReturnFlags
			MRF_PROCESSED	- event was process by the button
			MRF_REPLAY	- event was released by the button
			clear		- event was ignored by the button

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@

OLButtonStartSelect	method	OLButtonClass, MSG_META_START_SELECT

if SHORT_LONG_TOUCH
	call	StartShortLongTouch	;start short/long touch
endif

OLButtonMouse	label	far

	test	bp, (mask UIFA_IN) shl 8 ; see if in bounds
	jz	notInBounds		 ;if not in bounds, then should be up.

				; is SELECT function still on?
	test	bp, (mask UIFA_SELECT) shl 8
	jz	short inBoundsNotPressed

inBoundsAndPressed:
	;Button has been pressed on. Before depressing it, see if enabled

	call	OpenButtonCheckIfFullyEnabled
if BUBBLE_HELP
	jc	continueProcessing
	cmp	ax, MSG_META_START_SELECT
	jne	notStartSelect
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP_JUST_CLOSED
	call	ObjVarDeleteData
	jnc	notStartSelect		; found and deleted
	call	VisGrabMouse
	call	OLButtonCreateBubbleHelp
notStartSelect:
	jmp	returnProcessed

continueProcessing:
else
	jnc	returnProcessed		;skip if not enabled...
endif

	; Set double-click flag if appropriate
	
	test	bp, mask BI_DOUBLE_PRESS
	jz	1$			
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLBI_moreAttrs, mask OLBMA_WAS_DOUBLE_CLICKED
1$:		
	
if	 _CASCADING_MENUS
	; if this button is in a menu and is in the process of being selected
	; (i.e., it is not yet depressed and/or bordered, but it is going to
	; be since it is calling OLButtonSaveStateSetBorderedAndOrDepressed
	; next) then send a message to the menu window indicating that this
	; button (since it is just a trigger) will not cause the menu to
	; cascade.
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	dontSendMessage

	test	ds:[di].OLBI_specState, mask OLBSS_BORDERED or \
					mask OLBSS_DEPRESSED
	jnz	dontSendMessage

	push	cx
	; Flags passed in cl: Not cascading, don't start grab.
	clr	cx
	call	OLButtonSendCascadeModeToMenu
	pop	cx
	
dontSendMessage:
endif	;_CASCADING_MENUS
	
	;if this button is not yet CURSORED or HAS_MOUSE_GRAB-ed, then save
	;the current bordered and depressed state, and set DEPRESSED and/or
	;BORDERED as required by specific UI.

	call	OLButtonSaveStateSetBorderedAndOrDepressed

	;grab gadget, focus, keyboard, mouse, and default exclusives
	;(As we gain the focus exclusive, will set the OLBSS_CURSORED flag,
	;and redraw the button.)

	stc				;set flag: grab everything
	call	OLButtonGrabExclusives

	;in case we already had the focus, check draw state flags again
	;(DO NOT DRAW USING THE QUEUE! Must draw button for quick mouse
	;press-release sequences)

	call	OLButtonDrawNOWIfNewState ;redraw button if have new state
	
	jmp	short returnProcessed

inBoundsNotPressed:
	;now reset the BORDERED and or DEPRESSED status to normal and REDRAW
	;(DO NOT DRAW USING THE QUEUE! Must draw button for quick mouse
	;press-release sequences)

	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW
	call	OLButtonReleaseMouseGrab
	jmp	short returnProcessed

;----------------------------------------------------------------------
notInBounds:
	;is SELECT function still on?
	test	bp, (mask UIFA_SELECT) shl 8
	jz	short notInBoundsNotPressed

notInBoundsIsPressed:
	;the user has dragged the mouse out of the button: draw as
	;un-depressed, but KEEP THE MOUSE GRAB to prevent interacting with
	;other controls (if is not in a menu or menu bar)

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = SpecificInstance
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
					mask OLBSS_IN_MENU_BAR
	jnz	isMenuNotInBoundsNotPressed	;skip if in menu or menu bar...

	;now reset the BORDERED and or DEPRESSED status to normal and REDRAW
	;(DO NOT DRAW USING THE QUEUE! Must draw button for quick mouse
	;press-release sequences)

	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW

returnProcessed:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
					; Say processed if ptr in bounds
	ret

isMenuNotInBoundsNotPressed:
	;moving off of a menu item: turn off cursored also, so that when
	;we get a LOST_FOCUS, we don't redraw again.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_CURSORED)

notInBoundsNotPressed:
	;now reset the BORDERED and or DEPRESSED status to normal and REDRAW
	;(DO NOT DRAW USING THE QUEUE! Must draw button for quick mouse
	;press-release sequences)

	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW
	call	OLButtonReleaseMouseGrab ;returns carry set if released grab
	jnc	returnProcessed		;skip if did not have grab...
					;(i.e. already un-depressed)

	;we just released the grab: replay this event

	mov	ax, mask MRF_REPLAY	; Replay this one, since we didn't
	ret
OLButtonStartSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start bubble help on MOVE_COPY

CALLED BY:	MSG_META_START_MOVE_COPY
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
		cx	= X position of mouse
		dx	= X position of mouse
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive
RETURN:		ax	= MouseReturnFlags
DESTROYED:	
SIDE EFFECTS:	
	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/1/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonStartMoveCopy	method	dynamic	OLButtonClass,
				MSG_META_START_MOVE_COPY
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP_JUST_CLOSED
	call	ObjVarDeleteData
	jnc	callsuper		; found and deleted
	call	VisGrabMouse
	call	OLButtonCreateBubbleHelp
callsuper:
	mov	di, offset OLButtonClass
	GOTO	ObjCallSuperNoLock
		
OLButtonStartMoveCopy	endm
endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End bubble help on MOVE_COPY

CALLED BY:	MSG_META_END_MOVE_COPY
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
		cx	= X position of mouse
		dx	= X position of mouse
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive
RETURN:		ax	= MouseReturnFlags
DESTROYED:	
SIDE EFFECTS:	
	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/1/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonEndMoveCopy	method	dynamic	OLButtonClass,
				MSG_META_END_MOVE_COPY
	push	ax
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	call	OpenCheckBubbleMinTime
	pop	ax
	jc	leaveHelp
	call	OLButtonDestroyBubbleHelp
leaveHelp:
	call	VisReleaseMouse		

	mov	di, offset OLButtonClass
	GOTO	ObjCallSuperNoLock
		
OLButtonEndMoveCopy	endm
endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonSendCascadeModeToMenuFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls OLButtonSendCascadeModeToMenu

CALLED BY:	OLItemMouse

PASS:		cl	= OLMenuWinCascadeModeOptions
			    OMWCMO_CASCADE
				True=Enable/False=Disable cascade mode.
			    OMWCMO_START_GRAB
			    	If TRUE, will take the grabs and take the gadget
				exclusive after setting the cascade mode.
			
		if OMWCMO_CASCADE = TRUE
		    ^ldx:bp = optr to submenu
		else
		    dx, bp are ignored
		    
		*ds:si	= button object
		
RETURN:		Nothing
DESTROYED:	cx, di
SIDE EFFECTS:	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLButtonSendCascadeModeToMenuFar	proc	far
	call	OLButtonSendCascadeModeToMenu
	ret
OLButtonSendCascadeModeToMenuFar	endp
endif	;_CASCADING_MENUS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonSendCascadeModeToMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Packages up a MSG_MO_MW_CASCADE_MODE message and sends
		it to the menu window object.

CALLED BY:	OLButtonMouse,
	 	OLMenuButtonHandleEvent,
		OLMenuButtonHandleMenuFunction,
		OLButtonSendCascadeModeToMenuFar
		
PASS:		cl	= OLMenuWinCascadeModeOptions
			    OMWCMO_CASCADE
				True=Enable/False=Disable cascade mode.
			    OMWCMO_START_GRAB
			    	If TRUE, will take the grabs and take the gadget
				exclusive after setting the cascade mode.
			
		if OMWCMO_CASCADE = TRUE
		    ^ldx:bp = optr to submenu
		else
		    dx, bp are ignored
		    
		*ds:si	= button object
		
RETURN:		Nothing
DESTROYED:	cx, di
SIDE EFFECTS:	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLButtonSendCascadeModeToMenu	proc	near
	uses	ax,bx
	.enter

if	 ERROR_CHECK
	;If ^ldx:bp should be valid, then ensure that it is valid and that
	;it points to an OLMenuWinClass object.
	; * * * DESTROYS: ax, bx, di.  DS may be fixed up. * * *
	
	test	cl, mask OMWCMO_CASCADE
	jz	skipTest			; not cascading, skip this
	push	cx, dx, bp, si
	
	movdw	bxsi, dxbp
	
	; ensure object has been built out
	; ^lbx:si points to object passed in as ^ldx:bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_META_DUMMY
	call	ObjMessage			; Destroys: ax, cx, dx, bp
	
	; check to be sure it is an OLMenuWinClass object
	mov	cx, segment OLMenuWinClass
	mov	dx, offset OLMenuWinClass
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjMessage			; Destroys: ax, cx, dx, bp
	ERROR_NC	OL_ERROR		; NOT OLMenuWinClass.. bad.
	
	pop	cx, dx, bp, si

skipTest:
endif	;ERROR_CHECK


	push	si
	
	mov	bx, segment OLMenuWinClass
	mov	si, offset OLMenuWinClass
	mov	ax, MSG_MO_MW_CASCADE_MODE
	; cl, and possibly dx & bp, are arguments to this message
	mov	di, mask MF_RECORD
	call	ObjMessage
	
	pop	si				; restore si for object ptr
	mov	cx, di				; cx <= ClassedEvent
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParentEnsureStack
	
	; MSG_MO_MW_CASCADE_MODE destroys ax, cx
	
	.leave
	ret
OLButtonSendCascadeModeToMenu	endp
endif	;_CASCADING_MENUS



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSaveStateSetBorderedAndOrDepressed

DESCRIPTION:	This procedure makes sure that this GenTrigger is
		drawn as depressed, which depending upon the specific
		UI might mean DEPRESSED (blackened) and/or BORDERED.

CALLED BY:	OLButtonMouse
		OLButtonActivate

PASS:		*ds:si	= instance data for object

RETURN:		ds, si, cx, dx, bp = same

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLButtonSaveStateSetBorderedAndOrDepressed	proc	far

	;see if already interacting with this button

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

if FOCUSED_GADGETS_ARE_INVERTED
	test	ds:[di].OLBI_specState, mask OLBSS_DEPRESSED or \
					mask OLBSS_HAS_MOUSE_GRAB
else
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED or \
					mask OLBSS_HAS_MOUSE_GRAB
endif
	jnz	10$			;skip if so...

	;Before we enforce a new state for the button, save the bordered
	;status into OLBI_optFlags so that we can restore when button is
	;released (since we don't know if we are in a pinned menu).
	;This saves us from all of this conditional logic crap at the end.

	call	OLButtonSaveBorderedAndDepressedStatus
					;does not trash bx, ds, si, di

10$:	;first let's decide which of the DEPRESSED and BORDERED flags
	;we are dealing with. Start by assuming this trigger is inside
	;a normal window:
	;	OPEN_LOOK:	assume B, set D
	;	MOTIF:		assume B, set D
	;	PM:		assume B, set D
	;	CUA:		assume B, set D
	;	RUDY:		assume B

if FOCUSED_GADGETS_ARE_INVERTED
	clr	bx
else
	mov	bx, mask OLBSS_DEPRESSED	;bx = flags to set
endif

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	haveFlags

	;this trigger is inside a menu:
	;	OPEN_LOOK:	set B, set D
	;			(OL: if in pinned menu, B will already be set)
	;	PM:		set B, set D
	;	MOTIF:		set B
	;	CUA:		set D
	;	MAC:		set D
	
	; If _BW_MENU_ITEM_SELECTION_IS_DEPRESSED is TRUE, the buttons
	; are depressed if we are in B&W.  If _ASSUME_BW_ONLY is true, then
	; we do not check confirm that we are in B&W mode, but just assume
	; that is the case. --JimG 5/5/94

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	mov	bx, mask OLBSS_DEPRESSED
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED and not _ASSUME_BW_ONLY
	call	OpenCheckIfBW
	jc	haveFlags			; if BW, we are done..
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED and (not _ASSUME_BW_ONLY)

if	 not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED or (not _ASSUME_BW_ONLY)
MO <	mov	bx, mask OLBSS_BORDERED					>
ISU <	mov	bx, mask OLBSS_DEPRESSED				>
endif	;(not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) or (not _ASSUME_BW_ONLY)

haveFlags:
	ORNF	ds:[di].OLBI_specState, bx

done:
	ret
OLButtonSaveStateSetBorderedAndOrDepressed	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW

DESCRIPTION:	This routine resets the DEPRESSED and BORDERED flags as
		necessary, and then immediately redraws the button if necessary

CALLED BY:	OLButtonMouse
		OLMenuButtonHandleMenuFunction
		OLMenuButtonHandleDefaultFunction
		OLMenuButtonGenActivate
		OLMenuButtonCloseMenu
		OLMenuButtonLeaveStayUpMode

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
	DO NOT DRAW USING THE QUEUE!
	Must draw button for quick mouse press-release sequences.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW	proc	far
	;restore BORDERED state from bit in OLBI_optFlags.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	call	OLButtonRestoreBorderedAndDepressedStatus
	call	OLButtonDrawNOWIfNewState ;redraw if state changed
	ret
OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSaveBorderedAndDepressedStatus
FUNCTION:	OLButtonRestoreBorderedAndDepressedStatus

DESCRIPTION:	Save the current BORDERED status of this button so that
		it can be restored. Basically, it is nearly impossible
		to tell wether a button at rest should be bordered or not,
		because buttons in pinned menus change.

PASS:		*ds:si	= instance data for object
		ds:di	= Spec instance data for object

RETURN:		ds, si, di = same

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonSaveBorderedAndDepressedStatus	proc	near

	;copy status flags from lower byte of OLBI_specState to higher byte.

	ANDNF	ds:[di].OLBI_specState, not \
			(mask OLBSS_WAS_BORDERED or mask OLBSS_WAS_DEPRESSED)

	mov	al, {byte} ds:[di].OLBI_specState	;get LOW BYTE
	ANDNF	al, mask OLBSS_BORDERED or mask OLBSS_DEPRESSED

	ORNF	{byte} ds:[di].OLBI_specState+1, al	;OR into HIGH BYTE

	ret
OLButtonSaveBorderedAndDepressedStatus	endp

OLButtonRestoreBorderedAndDepressedStatus	proc	far

	;restore status flags from higher byte of OLBI_specState to lower byte.

	ANDNF	ds:[di].OLBI_specState, not \
			(mask OLBSS_BORDERED or mask OLBSS_DEPRESSED)

	mov	al, {byte} ds:[di].OLBI_specState+1	;get HIGH BYTE
	ANDNF	al, mask OLBSS_BORDERED or mask OLBSS_DEPRESSED

	ORNF	{byte} ds:[di].OLBI_specState, al	;OR into LOW BYTE
done:
	ret
OLButtonRestoreBorderedAndDepressedStatus	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonEnsureMouseGrab

DESCRIPTION:	This procedure makes sure that this button has the
		mouse grab (exclusive).

CALLED BY:	OLMenuButtonHandleDefaultFunction
		OLButtonMouse

PASS:		*ds:si	= instance data for object

RETURN:		ds, si, cx, dx, bp = same

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonEnsureMouseGrab	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
	jnz	done			;skip if already have it...

	ORNF	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
						;set bit so we release later
	call	VisGrabMouse			;Grab the mouse for this button
done:
	ret
OLButtonEnsureMouseGrab	endp

CommonFunctional ends
CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonGrabExclusives

DESCRIPTION:	This procedure grabs some exclusives for the button object.
		Regardless of the carry flag, the gadget and default
		exclusives are grabbed.

CALLED BY:	OLButtonMouse

PASS:		*ds:si	= instance data for object
		carry set to grab focus, mouse, and keyboard grab also

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonGrabExclusives	proc	near

	pushf

if _CUA_STYLE	;-------------------------------------------------------
	;CUA: if this GenTrigger is not marked as the DEFAULT trigger,
	;and is not destructive, request the parent window that this
	;trigger be given a temporary default exclusive. (When parent window
	;sends this button a MSG_META_GAINED_DEFAULT_EXCL, it will pass a flag
	;so that this button does not redraw, because we are also taking the
	;FOCUS exclusive.)

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	10$			;skip if is destructive...

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
					mask OLBSS_IN_MENU_BAR or \
					mask OLBSS_SYS_ICON
	jnz	10$			;skip if default or nasty...

	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_TAKE_DEFAULT_EXCLUSIVE
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	call	CallOLWin		; call OLWinClass object above us

10$:
endif		;--------------------------------------------------------------

	;take gadget exclusive for UI window

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParent

	;see if we have been called by OLButtonMouse

	popf
	jnc	done			;skip if only need some exclusives...

	;now grab the mouse, BEFORE we grab the focus, because we want the
	;OLBSS_HAS_MOUSE_GRAB flag to be set before we gain the focus,
	;because we have already saved the BORDERED and DEPRESSED states,
	;and don't want to again!

	call	OLButtonEnsureMouseGrab	;grab mouse, if don't have already

if _CUA_STYLE	;------------------------------------------------------
	;MOTIF/PM/CUA:
	;If this is not a SYS_ICON or menu bar object, take FOCUS exclusive,
	;so other UI object will lose cursored emphasis. (Cannot navigate
	;to system icons, so don't allow them to take focus)

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
if _GCM
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_GCM_SYS_ICON
	jnz	15$			;skip if GCM icon (can navigate to it).
endif
if MENU_BAR_IS_A_MENU
	;
	; if menu bar is a menu, allow menu bar items to grab focus
	;
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
else
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON or \
					mask OLBSS_IN_MENU_BAR
endif
	jnz	20$			;skip if is icon or in menu bar...

15$::	;see if the FOCUS is currently on a VisText object or GenView object.
	;If on either, then DO NOT take the focus.
		
	call	OpenTestIfFocusOnTextEditObject
	jnc	20$			;skip if should not take focus...

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	20$			;in toolbox, do not take focus...

	;take the FOCUS exclusive. Also take keyboard exclusive, so will
	;receive non-system keyboard shortcuts directly from the Flow Object.

	call	MetaGrabFocusExclLow	;see OLButtonGainedFocusExcl

20$:
endif		;--------------------------------------------------------------

done:
	ret
OLButtonGrabExclusives	endp

CommonFunctional ends
CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonGainedSystemFocusExcl

DESCRIPTION:	This procedure is called when the window in which this button
		is located decides that this button has the focus exclusive.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonGainedSystemFocusExcl	method	dynamic OLButtonClass,
					MSG_META_GAINED_SYS_FOCUS_EXCL
if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	push	ax
endif

if FOCUSED_GADGETS_ARE_INVERTED
	test	ds:[di].OLBI_specState, mask OLBSS_DEPRESSED
else
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
endif
	jnz	done			;skip if already drawn as cursored...

if _GCM
;not necessary. EDS 7/12/90
;	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_GCM_SYS_ICON
;	jnz	10$			;skip if GCM icon (not menu related)..
endif

	;if this button is not yet CURSORED, then save the current bordered
	;and depressed state, and set DEPRESSED and/or BORDERED as required
	;by the specific UI.

	call	OLButtonSaveStateSetCursored
					;sets OLBSS_CURSORED

10$:	;grab the gadget and default exclusives
	clc				;pass flag: nothing else required.
	call	OLButtonGrabExclusives

;NOTE: TRY MOVING THIS LABEL LOWER TO MINIMIZE METHODS SENT

done:
	call	OLButtonDrawLATERIfNewState   ;send method to self on queue so
					      ;will redraw button if necessary
exit:

if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	pop	cx
	mov	dx, 1 or (1 shl 8)	      ;top, bottom margins for invert
	mov	ax, MSG_SPEC_NOTIFY_CHILD_CHANGING_FOCUS
	call	VisCallParent
endif
	ret
OLButtonGainedSystemFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonCreateBubbleHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create bubble help

CALLED BY:	OLButtonGainedSystemFocusExcl
PASS:		*ds:si	= OLButtonClass object
RETURN:		ds:di	= OLButtonClass instance data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 5/96    	Initial version
	Cassie	3/10/97    	Added bubble help delay

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonCreateBubbleHelp	proc	far
	uses	ax,bx,cx,dx,es,bp
	.enter

	push	ds
	mov	di, segment olBubbleOptions
	mov	ds, di
	mov	cx, ds:[olBubbleHelpDelayTime]	; cx = bubble help delay
	mov	bp, ds:[olBubbleHelpTime]	; bp = bubble help time
	test	ds:[olBubbleOptions], mask BO_HELP
	pop	ds
	jz	done				; CF = 0

	call	FindBubbleHelp
	jnc	done
	;
	; At this point,
	; 	ds:bx = ptr to help text
	; 	cx = bubble help delay
	; 	bp = bubble help time
	;
	jcxz	noDelay				; open bubble now!
		
	push	cx
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	mov	cx, size BubbleHelpData
	call	ObjVarAddData
	pop	cx
		
	clr	ax
	mov	ds:[bx].BHD_window, ax
	mov	ds:[bx].BHD_borderRegion, ax
	;
	; start timer
	;
	mov	ds:[bx].BHD_timer, 0	; in case no time out
	push	bx			; save vardata
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	dx, MSG_OL_BUTTON_BUBBLE_DELAY_TIME_OUT
	mov	bx, ds:[LMBH_handle]	; ^lbx:si = object
	call	TimerStart
	pop	di			; ds:di = vardata
	mov	ds:[di].BHD_timer, bx	; save timer handle
	mov	ds:[di].BHD_timerID, ax	; save timer ID

done:
	mov	di, ds:[si]			; redeference for lmem moves
	add	di, ds:[di].Vis_offset

	.leave
	ret

noDelay:
	mov	di, ds:[bx].offset
	mov	bx, ds:[bx].handle
	call	ObjLockObjBlock
	push	bx

	mov	es, ax
	mov	cx, ax
	mov	dx, es:[di]			; cx:dx = bubble help text
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	mov	bx, MSG_OL_BUTTON_BUBBLE_TIME_OUT
	call	OpenCreateBubbleHelp

	call	VisAddButtonPrePassive
		
	pop	bx
	call	MemUnlock
	jmp	done
		
OLButtonCreateBubbleHelp	endp

FindBubbleHelp	proc	far
	push	si, di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	call	OpenButtonCheckIfFullyEnabled
	mov	si, ds:[di].OLBI_genChunk
	mov	ax, ATTR_GEN_FOCUS_HELP
	jc	haveFocusHelpType
	mov	ax, ATTR_GEN_FOCUS_DISABLED_HELP
	call	ObjVarFindData
	jc	gotFocusHelp			; found disabled help
	mov	ax, ATTR_GEN_FOCUS_HELP		; no disabled help, try help
haveFocusHelpType:
	call	ObjVarFindData			; carry set if found
gotFocusHelp:
	pop	si, di
	ret
FindBubbleHelp	endp
endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonCreateBubbleHelpLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Really Create bubble help

CALLED BY:	OLButtonCreateBubbleHelp, OLButtonBubbleDelayTimeOut
PASS:		*ds:si	= OLButtonClass object
RETURN:		ds:di	= OLButtonClass instance data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	3/10/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonCreateBubbleHelpLow	proc	near
	uses	ax,bx,cx,dx,es,bp
	.enter

	push	ds
	mov	di, segment olBubbleOptions
	mov	ds, di
	mov	bp, ds:[olBubbleHelpTime]	; bp = bubble help time
	pop	ds

	call	FindBubbleHelp
EC <	ERROR_NC	-1					>
		
	mov	di, ds:[bx].offset
	mov	bx, ds:[bx].handle
	call	ObjLockObjBlock
	push	bx

	mov	es, ax
	mov	cx, ax
	mov	dx, es:[di]			; cx:dx = bubble help text
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	mov	bx, MSG_OL_BUTTON_BUBBLE_TIME_OUT
	call	OpenCreateBubbleHelp

	call	VisAddButtonPrePassive

	pop	bx
	call	MemUnlock

	mov	di, ds:[si]			; redeference for lmem moves
	add	di, ds:[di].Vis_offset

	.leave
	ret
OLButtonCreateBubbleHelpLow	endp
endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonDestroyBubbleHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy bubble help

CALLED BY:	OLButtonLostSystemFocusExcl, OLMenuButtonLostFocusExcl
PASS:		*ds:si	= OLButtonClass object
RETURN:		ds:di	= OLButtonClass instance data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonDestroyBubbleHelp	proc	far
	uses	ax,bx
	.enter

	call	VisRemoveButtonPrePassive

	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	call	OpenDestroyBubbleHelp

	mov	di, ds:[si]			; rederefence, just in case
	add	di, ds:[di].Vis_offset
done:
	.leave
	ret
OLButtonDestroyBubbleHelp	endp
endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonBubbleTimeOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bubble time out, close bubble

CALLED BY:	MSG_OL_BUTTON_BUBBLE_TIME_OUT
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonBubbleTimeOut	method dynamic OLButtonClass, 
					MSG_OL_BUTTON_BUBBLE_TIME_OUT
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	call	ObjVarFindData
	jnc	done
	mov	ds:[bx].BHD_timer, 0
	call	OLButtonDestroyBubbleHelp
done:
	ret
OLButtonBubbleTimeOut	endm
endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	object closing, close bubble

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/19/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonVisClose	method dynamic OLButtonClass, MSG_VIS_CLOSE
	push	ax
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	call	ObjVarFindData
	pop	ax
	jnc	done
	call	OLButtonDestroyBubbleHelp
done:
	; Ensure that we don't still have the mouse grabbed from either
	; START_SELECT or START_MOVE_COPY. -dhunter 2/23/2000
	call	VisReleaseMouse
	mov	di, offset OLButtonClass
	GOTO	ObjCallSuperNoLock
OLButtonVisClose	endm
endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonPrePassiveButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	if another click, close bubble help

CALLED BY:	MSG_META_PRE_PASSIVE_BUTTON
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
		bp low	= ButtonInfo
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonPrePassiveButton	method dynamic OLButtonClass, 
					MSG_META_PRE_PASSIVE_BUTTON
	test	bp, mask BI_PRESS
	jz	done
	call	OLButtonDestroyBubbleHelp
	;
	; prevent re-opening of bubble help
	;
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP_JUST_CLOSED
	clr	cx
	call	ObjVarAddData
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	cx, TEMP_OL_BUTTON_BUBBLE_HELP_JUST_CLOSED
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	clr	ax			; continue with mouse event
	ret
OLButtonPrePassiveButton	endm
endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonBubbleDelayTimeOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bubble delay time out, open bubble

CALLED BY:	MSG_OL_BUTTON_BUBBLE_DELAY_TIME_OUT
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonBubbleDelayTimeOut	method dynamic OLButtonClass, 
					MSG_OL_BUTTON_BUBBLE_DELAY_TIME_OUT
	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	call	ObjVarFindData
	jnc	done
	mov	ds:[bx].BHD_timer, 0
	call	OLButtonCreateBubbleHelpLow
done:
	ret
OLButtonBubbleDelayTimeOut	endm
endif	; BUBBLE_HELP


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSaveStateSetCursored

DESCRIPTION:	This routine tests if the button is pressed already,
		and if not, saves the button's current bordered and depressed
		state, and sets the new state, so that the button shows
		the cursored emphasis.

SEE ALSO:	OLButtonSaveStateSetBorderedAndOrDepressed

CALLED BY:	OLButtonGainedFocusExcl

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLButtonSaveStateSetCursored	proc	near

	;see if already interacting with this button

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

if FOCUSED_GADGETS_ARE_INVERTED
	test	ds:[di].OLBI_specState, mask OLBSS_DEPRESSED or \
					mask OLBSS_HAS_MOUSE_GRAB
else
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED or \
					mask OLBSS_HAS_MOUSE_GRAB
endif
	jnz	10$			;skip if so...

	;Before we enforce a new state for the button, save the bordered
	;status into OLBI_optFlags so that we can restore when button is
	;released (since we don't know if we are in a pinned menu).
	;This saves us from all of this conditional logic crap at the end.

	call	OLButtonSaveBorderedAndDepressedStatus
					;does not trash bx, ds, si, di

10$:	;now set the CURSORED flag

if not FOCUSED_GADGETS_ARE_INVERTED
	ORNF	ds:[di].OLBI_specState, mask OLBSS_CURSORED
endif

	;first let's decide which of the DEPRESSED and BORDERED flags
	;first let's decide which of the DEPRESSED and BORDERED flags
	;we are dealing with. Start by assuming this trigger is inside
	;a normal window:
	;	OPEN_LOOK:	set nothing (CURSORED flag shown independently)
	;	MOTIF:		set nothing (CURSORED flag shown independently)
	;	PM:		set nothing (CURSORED flag shown independently)
	;	CUA:		set nothing (CURSORED flag shown independently)
	;	RUDY:		set DEPRESSED, don't set CURSORED!

if FOCUSED_GADGETS_ARE_INVERTED
	mov	bx, mask OLBSS_DEPRESSED
else
	clr	bx				;bx = flags to set
endif

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	haveFlags

	;this trigger is inside a menu:
	;	OPEN_LOOK:	set B, set D
	;			(OL: if in pinned menu, B will already be set)
	;	PM:		set B, set D
	;	MOTIF:		set B
	;	CUA:		set D
	
	; If _BW_MENU_ITEM_SELECTION_IS_DEPRESSED is TRUE, the buttons
	; are depressed if we are in B&W.  If _ASSUME_BW_ONLY is true, then
	; we do not check confirm that we are in B&W mode, but just assume
	; that is the case. --JimG 5/5/94

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED
	mov	bx, mask OLBSS_DEPRESSED	
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED

if	 _BW_MENU_ITEM_SELECTION_IS_DEPRESSED and not _ASSUME_BW_ONLY
	call	OpenCheckIfBW
	jc	haveFlags			; if BW, we are done..
endif	;_BW_MENU_ITEM_SELECTION_IS_DEPRESSED and (not _ASSUME_BW_ONLY)

if	 not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED or (not _ASSUME_BW_ONLY)
MO <	mov	bx, mask OLBSS_BORDERED					>
ISU <	mov	bx, mask OLBSS_DEPRESSED				>
NOT_MO<	mov	bx, mask OLBSS_DEPRESSED				>
endif	;(not _BW_MENU_ITEM_SELECTION_IS_DEPRESSED) or (not _ASSUME_BW_ONLY)

haveFlags:
	ORNF	ds:[di].OLBI_specState, bx

done:
	ret
OLButtonSaveStateSetCursored	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonLostSystemFocusExcl

DESCRIPTION:	This procedure is called when the window in which this button
		is located decides that this button does not have the
		focus exclusive.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonLostSystemFocusExcl	method	dynamic OLButtonClass,
					MSG_META_LOST_SYS_FOCUS_EXCL
if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	push	ax
endif

if FOCUSED_GADGETS_ARE_INVERTED
	test	ds:[di].OLBI_specState, mask OLBSS_DEPRESSED
	jz	done			;skip if already drawn as not cursored
	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_DEPRESSED)
else
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
	jz	done			;skip if already drawn as not cursored
	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_CURSORED)
endif

	;if not the master default trigger, release the default exclusive
	;so that the master default can gain it.

	call	OLButtonReleaseDefaultExclusive

	;now reset the BORDERED and or DEPRESSED status to normal and REDRAW

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	call	OLButtonRestoreBorderedAndDepressedStatus

	;
	; Remove the known drawn state.   In keyboard-only systems, the
	; cursor interferes with the mnemonic underline, so the entire thing
	; should be redrawn.  (Changed to happen for all keyboard-only systems.)
	;
	call	OpenCheckIfKeyboardOnly
	jnc	10$
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLBI_optFlags, not mask OLBOF_DRAW_STATE_KNOWN
10$:

	call	OLButtonDrawLATERIfNewState   ;send method to self on queue so
					      ;will redraw button if necessary
done:

if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	pop	cx
	mov	dx, 1 or (1 shl 8)	      ;top, bottom margins for invert
	mov	ax, MSG_SPEC_NOTIFY_CHILD_CHANGING_FOCUS
	call	VisCallParent
endif
	ret
OLButtonLostSystemFocusExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonLostGadgetExcl -- MSG_VIS_LOST_GADGET_EXCL

DESCRIPTION:	HandleMem losing of gadget exclusive.  We MUST release any
		gadget exclusive if we get this method, for it is used both
		for the case of the grab being given to another gadget &
		when a window on which this gadget sits is being closed.

PASS:		*ds:si - instance data
		es - segment of MetaClass
		ax - MSG_VIS_LOST_GADGET_EXCL

RETURN:		nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version

------------------------------------------------------------------------------@

OLButtonLostGadgetExcl	method	dynamic OLButtonClass, MSG_VIS_LOST_GADGET_EXCL

	;release the mouse grab

	call	OLButtonReleaseMouseGrab

	;if this button has the FOCUS, let's assume that it will shortly
	;lose the focus, and so OLButtonLostFocusExcl will force it to
	;redraw. Otherwise, lets reset the button visually now!

if FOCUSED_GADGETS_ARE_INVERTED
	test	ds:[di].OLBI_specState, mask OLBSS_DEPRESSED
else
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
endif
	jnz	done			;skip if not cursored...

	;now reset the BORDERED and or DEPRESSED status to normal and REDRAW

					;pass ds:di
	call	OLButtonRestoreBorderedAndDepressedStatus
	call	OLButtonDrawLATERIfNewState
					;send method to self on queue so
					;will redraw button if necessary
done:
	ret
OLButtonLostGadgetExcl	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonGainedDefaultExclusive -- MSG_META_GAINED_DEFAULT_EXCL

DESCRIPTION:	This method is sent by the parent window (see OpenWinGupQuery)
		when it decides that this GenTrigger should have the
		default exclusive.

PASS:		*ds:si	= instance data for object
		ds:di	= ptr to intance data
		es	= class segment
		bp	= TRUE if this button should redraw itself,
			because it did not initiate this GAINED sequence, 
			and is not gaining any other exclusives that
			would cause it to redraw.

RETURN:		nothing

ALLOWED TO DESTROY:
                nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonGainedDefaultExclusive	method	static OLButtonClass,
						MSG_META_GAINED_DEFAULT_EXCL
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	call	OpenCheckDefaultRings
	jnc	done
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_DEFAULT
	jnz	done			;skip if already have default...

	ORNF	ds:[di].OLBI_specState, mask OLBSS_DEFAULT

	tst	bp			;check flag passed by OpenWinGupQuery
	jz	done			;skip if no need to redraw...

	call	OLButtonDrawLATERIfNewState   ;send method to self on queue so
					      ;will redraw button if necessary
done:
	.leave
	ret
OLButtonGainedDefaultExclusive	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonLostDefaultExclusive -- MSG_META_LOST_DEFAULT_EXCL

DESCRIPTION:	This method is sent by the parent window (see OpenWinGupQuery)
		when it decides that this GenTrigger should NOT have the
		default exclusive.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonLostDefaultExclusive	method	OLButtonClass,
						MSG_META_LOST_DEFAULT_EXCL
	call	OpenCheckDefaultRings
	jnc	done
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_DEFAULT
	jz	done			;skip if do not have default...

	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_DEFAULT

	call	OLButtonDrawLATERIfNewState   ;send method to self on queue so
					      ;will redraw button if necessary
done:
	ret
OLButtonLostDefaultExclusive	endp

CommonFunctional	ends
CommonFunctional	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonNavigate - MSG_SPEC_NAVIGATION_QUERY handler for
			OLButtonClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		cx:dx	= OD of object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		cx:dx	= OD of replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	OLButtonClass handler:
	    1) If this OLButtonClass object is subclassed GenItem,
	    we should not even get this query. The OLItemGroup
	    should have first received the query, and handled as a leaf
	    node (should not have sent to children).

	    2) similarly, if this OLButtonClass object is subclassed
	    by OLMenuButtonClass, we should not get this query.

	    3) Otherwise, this must be a GenTrigger object. As a leaf-node
	    in the subset of the visible tree which is traversed by this
	    query, this object must handle this method by calling a utility
	    routine, passing flags indicating whether or not this object
	    is focusable. (May be trigger in menu bar!)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonNavigate	method	OLButtonClass, MSG_SPEC_NAVIGATION_QUERY
	;ERROR CHECKING is in OLButtonNavigateCommon

	;see if this button is enabled (generic state may come from window
	;which is opened by this button)

	push	cx, dx

	call	OLButtonGetGenAndSpecState ;returns dh = VI_attrs
					   ;bx = OLBI_specState
if not _KBD_NAVIGATION
	;_CR_NAVIGATION might be true, so preserve navigation sequencing.
	clr	dh			;indicate this node is disabled.
endif

	mov	cx, bx
	clr	bl			;default: not root-level node, is not
					;composite node, is not focusable


	call	OpenCheckIfKeyboard
	jnc	haveFlags		;no keyboard, can't take focus. 4/20/93

	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	haveFlags		;in toolbox, do not take focus...

	;
	; If this button is a SYS_ICON (in the header area), then 
	; indicate that it is not FOCUSABLE.  Users can activate it
	; using the system menu.
	;
	test	cx, mask OLBSS_SYS_ICON
	jz	notSysIcon		;skip if is not a system icon...

if not _GCM
	jmp	haveFlags		; it's a system icon

else	; _GCM
	;
	; It's a sys icon.  Do something special if it's GCM.
	;
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_GCM_SYS_ICON
	jz	haveFlags		;skip if is not a GCM icon...
	jnz	focusableIfEnabledAndDrawable

endif	; _GCM

notSysIcon:

if not MENU_BAR_IS_A_MENU


	;
	; if this button has been placed in a menu bar, indicate 
	; that it is menu related
	;
	test	cx, mask OLBSS_IN_MENU_BAR
	jz	focusableIfEnabledAndDrawable

	ORNF	bl, mask NCF_IS_MENU_RELATED

endif	;(not MENU_BAR_IS_A_MENU)

focusableIfEnabledAndDrawable::
	;
	; Set this button as focusable if it is enabled and drawable
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	haveFlags			;not drawable, branch
	
	call	OpenButtonCheckIfFullyEnabled
	jnc	haveFlags
	ORNF	bl, mask NCF_IS_FOCUSABLE

haveFlags:
	;
	; call utility routine, passing flags to indicate that this is
	; a leaf node in visible tree, and whether or not this object can
	; get the focus. This routine will check the passed NavigationFlags
	; and decide what to respond.
	;
	pop	cx, dx
	mov	di, ds:[si]		;pass *ds:di = generic object
	add	di, ds:[di].Vis_offset	;which may contain relevant hints
	mov	di, ds:[di].OLBI_genChunk
	call	VisNavigateCommon
	ret
OLButtonNavigate	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a windw
		which has HINT_DEFAULT_FOCUS{_WIN}.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= OD of object with hint
		carry set if broadcast handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLButtonBroadcastForDefaultFocus	method	OLButtonClass, \
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_DEFAULT_FOCUS
	jz	done			;skip if not...

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	clr	bp
done:
	ret
OLButtonBroadcastForDefaultFocus	endm

CommonFunctional ends
CommonFunctional	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonMakeNotApplyable -- 
		MSG_OL_MAKE_NOT_APPLYALE for OLButtonClass

DESCRIPTION:	We get this when an apply or reset happens.  If this is an 
		APPLY/RESET type trigger, we'll disable it.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_MAKE_NOT_APPLYABLE

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/11/90		Initial version

------------------------------------------------------------------------------@


OLButtonMakeApplyable method OLButtonClass, MSG_OL_MAKE_APPLYABLE
	mov	ax, MSG_GEN_SET_ENABLED	;we'll enable if our button
	GOTO	CallMethodIfApplyOrReset
OLButtonMakeApplyable endm
		      
OLButtonMakeNotApplyable method OLButtonClass, MSG_OL_MAKE_NOT_APPLYABLE
	mov	ax, MSG_GEN_SET_NOT_ENABLED	;else disable it
	FALL_THRU  CallMethodIfApplyOrReset
OLButtonMakeNotApplyable endm

			 

COMMENT @----------------------------------------------------------------------

ROUTINE:	CallMethodIfApplyOrReset

SYNOPSIS:	Calls passed method on itself if apply or reset button.

CALLED BY:	OLButtonMakeApplyable, OLButtonMakeNotApplyable

PASS:		*ds:si -- handle of a button
		ax     -- method to call

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/12/90		Initial version

------------------------------------------------------------------------------@


CallMethodIfApplyOrReset	proc	far
	push	ax
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	call	ObjVarFindData
	pop	ax
	jnc	exit				;not found, done
	VarDataFlagsPtr	ds, bx, cx
	test	cx, mask VDF_EXTRA_DATA
	jz	exit
	cmp	{word} ds:[bx], IC_APPLY
	je	callIt
	cmp	{word} ds:[bx], IC_RESET
	jne	exit				;no match, branch
callIt:
EC <	mov	di, ds:[si]			;gen should match spec 	>
EC <	add	di, ds:[di].Vis_offset					>
EC <	cmp	si, ds:[di].OLBI_genChunk				>
EC <	ERROR_NE	OL_ERROR					>
   
	mov	dl, VUM_NOW			;else call a method on it
	GOTO	ObjCallInstanceNoLock
exit:
	ret
CallMethodIfApplyOrReset	endp

	
CommonFunctional	ends
ButtonCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonChangeEnabled -- MSG_SPEC_NOTIFY_ENABLED and
			MSG_SPEC_NOTIFY_NOT_ENABLED hander.

DESCRIPTION:	We intercept these methods here to make sure that the button
		redraws and that we grab or release the master default
		exclusive for the window.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLButtonNotifyEnabled	method	static	OLButtonClass,
			MSG_SPEC_NOTIFY_ENABLED		uses	bx, di
	.enter
if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
	call	OpenButtonCheckIfAlwaysEnabled	
	jc	exit
endif
	
	mov	di, offset OLButtonClass
	CallSuper	MSG_SPEC_NOTIFY_ENABLED
	
	call	FinishChangeEnabled
exit::
	.leave
	ret
OLButtonNotifyEnabled	endm


OLButtonNotifyNotEnabled	method	static	OLButtonClass,
			MSG_SPEC_NOTIFY_NOT_ENABLED	uses	bx, di
	.enter
if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
	call	OpenButtonCheckIfAlwaysEnabled	
	jc	exit				
endif	
	mov	di, offset OLButtonClass
	CallSuper	MSG_SPEC_NOTIFY_NOT_ENABLED
	
	call	FinishChangeEnabled
exit::
	.leave
	ret
OLButtonNotifyNotEnabled	endm


FinishChangeEnabled	proc	near
	push	ax, cx, dx, bp
	call	OLButtonGetGenAndSpecState
	test	dh, mask VA_FULLY_ENABLED
	jnz	isEnabled		;skip if enabled...

	;we are setting this button NOT enabled. First: if it is CURSORED,
	;force navigation to move onto the next object in this window.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_CURSORED
	jz	10$			;skip if not cursored...

	mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	call	VisCallParent

10$:	;in case this button has HINT_DEFAULT_DEFAULT_ACTION, release the master default
	;exclusive for this window. (If this button is not the master default,
	;this does nada). Do this BEFORE you release the DEFAULT exclusive.

	call	OLButtonResetMasterDefault

	;now, force the release of any other grabs that we might have.
	;(If this is the only object in the window, it will still have the
	;FOCUS and KBD grabs, so this is really important.)

	call	OLButtonReleaseAllGrabs
	jmp	short done

isEnabled:
	;this button is now enabled. If it has HINT_DEFAULT_DEFAULT_ACTION, request
	;the master default for this window.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_MASTER_DEFAULT_TRIGGER
					;HINT_DEFAULT_DEFAULT_ACTION present?
	jz	done			;skip if not...

	mov	cx, SVQT_SET_MASTER_DEFAULT

	mov	ax, MSG_VIS_VUP_QUERY
	mov	bp, ds:[LMBH_handle]	; pass ^lbp:dx = this object
	mov	dx, si
	call	CallOLWin		; call OLWinClass object above us

done:	;draw object and save new state
	pop	ax, cx, dx, bp
	clc				;return flag: allows Gen handler
exit:					;to continue
	ret
FinishChangeEnabled	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonResetMasterDefault

DESCRIPTION:	Releases "Master Default" exclusive, if this button has it.

CALLED BY:	INTERNAL
		OLButtonChangeEnabled
		OLButtonVisUnbuildBranch

PASS:		*ds:si	- OLButton

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Initial version
------------------------------------------------------------------------------@

OLButtonResetMasterDefault	proc	far	uses	bx, si
	.enter
	; In case this button has HINT_DEFAULT_DEFAULT_ACTION, release the master default
	; exclusive for this window. (If this button is not the master default,
	; this does nada). 
	;
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this OLButton
	mov	dx, si

	call	SwapLockOLWin		; If no OLWin class above us, done.
	jnc	done

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLWI_masterDefault.handle, bp	;set new master OD
	jne	afterResetMasterDefault
	cmp	ds:[di].OLWI_masterDefault.chunk, dx
	jne	afterResetMasterDefault

	mov	cx, SVQT_RESET_MASTER_DEFAULT
	mov	ax, MSG_VIS_VUP_QUERY
	call	ObjCallInstanceNoLock

afterResetMasterDefault:

	call	ObjSwapUnlock
done:
	.leave
	ret

OLButtonResetMasterDefault	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonQueryIsTrigger -- MSG_OL_BUTTON_QUERY_IS_TRIGGER
		for OLButtonClass

DESCRIPTION:	Respond to a query from an OLMenuItemGroup object in this
		visible composite (menu). The query is asking a specific child
		- are you a trigger (or sub-menu button)? If the sibling is not
		a trigger, it will not respond to the query, so the carry flag
		will return cleared.

PASS:		*ds:si - instance data
		es - segment of OLButtonClass
		ax - MSG_OL_BUTTON_QUERY_IS_TRIGGER
		cx, dx, bp -

RETURN:		carry - set if child can answer query
		cx = TRUE / FALSE

DESTROYED:	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	respond TRUE or FALSE

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version

------------------------------------------------------------------------------@

OLButtonQueryIsTrigger	method	OLButtonClass, MSG_OL_BUTTON_QUERY_IS_TRIGGER
	mov	cx, TRUE			;return = TRUE (is trigger)
	stc					;return query acknowledged
	ret
OLButtonQueryIsTrigger	endm

ButtonCommon ends
ButtonCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonMetaExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle META_EXPOSED for bubble help window

CALLED BY:	MSG_META_EXPOSED
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if BUBBLE_HELP
OLButtonMetaExposed	method dynamic OLButtonClass, 
					MSG_META_EXPOSED
	mov	di, cx
	call	GrCreateState
	call	GrBeginUpdate

	mov	ax, TEMP_OL_BUTTON_BUBBLE_HELP
	call	ObjVarFindData
	jnc	endUpdate

	push	si
	mov	si, ds:[bx].BHD_borderRegion
	mov	si, ds:[si]
	clr	ax, bx
	call	GrDrawRegion
	pop	si

	call	FindBubbleHelp
	jnc	endUpdate

	mov	si, ds:[bx].offset
	mov	bx, ds:[bx].handle
	call	ObjLockObjBlock
	push	bx

	mov	ds, ax
	mov	si, ds:[si]		; ds:si = help text
	mov	ax, BUBBLE_HELP_TEXT_X_MARGIN
	mov	bx, BUBBLE_HELP_TEXT_Y_MARGIN
	clr	cx
	call	GrDrawText

	pop	bx
	call	MemUnlock

endUpdate:
	call	GrEndUpdate
	GOTO	GrDestroyState

OLButtonMetaExposed	endm
endif	; BUBBLE_HELP


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonDraw -- MSG_VIS_DRAW for OLButtonClass

DESCRIPTION:	Draw the button

PASS:		*ds:si - instance data
		es - segment of MetaClass
		ax - MSG_VIS_DRAW
		cl - DrawFlags:  DF_EXPOSED set if updating
		bp - GState to use

RETURN:		nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Call the correct draw routine based on the display type:

	if (black & white) {
		DrawBWButton();
	} else {
		DrawColorButton();
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

OLButtonDraw	method	dynamic OLButtonClass, MSG_VIS_DRAW
	;since this procedure can be called directly when the mouse button
	;is released, we want to make sure that the button is realized,
	;drawable, and not invalid.

					; make sure object is drawable
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	common			; if not, skip drawing it
					; make sure object is realized

if _HAS_LEGOS_LOOKS
	mov	bl, ds:[di].OLBI_legosLook
	push	bx
endif	; legos looks

	;get display scheme data
	mov	di, bp				;put GState in di

	push	cx, dx
	mov	ax, GIT_PRIVATE_DATA
	call	GrGetInfo			;returns ax, bx, cx, dx
	pop	cx, dx
if _HAS_LEGOS_LOOKS
	pop	bx
endif

	;al = color scheme, ah = display type, cl = update flag

	ANDNF	ah, mask DF_DISPLAY_TYPE	;keep display type bits
	cmp	ah, DC_GRAY_1			;is this a B&W display?

	mov	ch, cl				;Pass DrawFlags in ch
	mov	cl, al				;Pass color scheme in cl
						;(ax & bx get trashed)

	;CUA & MAC use one handler for Color and B&W draws.
	push	di				;save gstate
	;
	; pcv is in color, but uses some bw regions :)
if not _ASSUME_BW_ONLY 
MO <	jnz	color				;skip to draw color button... >
ISU <	jnz	color				;skip to draw color button... >
endif
bw:
						;draw black & white button
	CallMod	DrawBWButton

if ( _OL_STYLE or _MOTIF or _ISUI ) and ( not _ASSUME_BW_ONLY ) ;-------------
	jmp	short afterDraw

color:						;draw color button
if _HAS_LEGOS_LOOKS
	tst	bl
	jne	bw		; if not standard look draw in BW
endif
	CallMod	DrawColorButton
endif		;--------------------------------------------------------------

;	mov	bp, di				;
	
afterDraw:
	pop	bp				;restore gstate

common:					;both B&W and Color draws finish here:
					;copy generic state data from
					;GenTrigger object,set DRAW_STATE_KNOWN
	call	UpdateButtonState
	
	mov	di, bp				;pass gstate
	mov	al, SDM_100			;make sure these are correct
	call	GrSetAreaMask			;
	call	GrSetTextMask			;
	call	GrSetLineMask			
	ret
OLButtonDraw	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateButtonState

DESCRIPTION:	Note which specific state flags have been set in order to
		use this information for later drawing optimizations.
		Also, notes the enabled/disabled state.

CALLED BY:	OLButtonDraw, OLButtonSpecBuild, OLMenuButtonSetup

PASS:		ds:*si - object

RETURN:		ds:di = VisInstance
		carry set

DESTROYED:	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@
;see FALL_THROUGH above...

UpdateButtonState	proc	far
	class	OLButtonClass

	call	OLButtonGetGenAndSpecState
						;sets bx = OLBI_specState
						;dh = VI_attrs
	ANDNF	bl, OLBOF_STATE_FLAGS_MASK	;remove non-state flags,
						;including OLBOF_ENABLED

	call	OpenButtonCheckIfFullyEnabled	;use our special routine
	jnc	10$
	ORNF	bl, mask VA_FULLY_ENABLED	;or into OLButtonFlags
10$:
	ORNF	bl, mask OLBOF_DRAW_STATE_KNOWN	;set draw state known

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = SpecificInstance
	ANDNF	ds:[di].OLBI_optFlags, not (OLBOF_STATE_FLAGS_MASK \
						or mask OLBOF_ENABLED)
						;clear old state flags
	ORNF	ds:[di].OLBI_optFlags, bl	;and or new flags in
	stc
	ret
UpdateButtonState	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonDrawMoniker

DESCRIPTION:	Draw the moniker for this button.

CALLED BY:	DrawColorButton, DrawBWButton

PASS:		*ds:si	= instance data for object
		di	= GState
		al	= DrawMonikerFlags (justification, clipping)
		cx	= OLMonikerAttributes (window mark, cursored)
		dl	= X inset amount
		dh	= Y inset amount

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonDrawMoniker	proc	far
	class	OLButtonClass

	;Draw moniker offset in X and centered in Y

	sub	sp, size OpenMonikerArgs	;make room for args
	mov	bp, sp				;pass pointer in bp

EC <	call	ECInitOpenMonikerArgs	;save IDs on stack for testing	>

	mov	ss:[bp].OMA_gState, di		;pass gstate

	clr	ah				;high byte not used
	mov	ss:[bp].OMA_drawMonikerFlags, ax	;pass DrawMonikerFlags
	mov	ss:[bp].OMA_monikerAttrs, cx	;pass OLMonikerAttrs


	mov	bl, dh				;keep y inset here
	clr	dh				;x inset in dx
	clr	bh				;y inset in bx
	mov	ss:[bp].OMA_leftInset, dx	;pass left inset
	mov	ss:[bp].OMA_topInset, bx	;pass top inset 

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON or \
					mask OLBSS_IN_MENU_BAR
	jnz	17$
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	17$
	call	OpenCheckIfBW
	jnc	17$
	inc	dx
	inc	bx
17$:
	pop	di
endif
	mov	ss:[bp].OMA_rightInset, dx	;pass right inset
	mov	ss:[bp].OMA_bottomInset, bx	;pass bottom inset

	mov	bx, ds:[si]			;pass gen chunk in es:bx
	add	bx, ds:[bx].Vis_offset
	;
	; Hack in CGA to make mnemonics appear a little better in menus.
	; -cbh 2/15/92    CHECK BW FOR CUA LOOK
	;
	push	ds:[bx].VI_bounds.R_top		;is this the worst I've done?
	push	ds:[bx].VI_bounds.R_bottom

	call	OpenCheckIfCGA
	jnc	8$				;not CGA, branch
	call	OpenCheckIfKeyboardNavigation	;Check if using kbd mnemonics
	jnc	8$				;  if not, don't bother
	test	ds:[bx].OLBI_specState, mask OLBSS_IN_MENU_BAR		
	jz	8$
	dec	ds:[bx].VI_bounds.R_top		;is this the worst I've done?
	dec	ds:[bx].VI_bounds.R_bottom
8$:

	;
	; Center the moniker if desired.  (Not an option in Rudy.)
	;
	test	ds:[bx].OLBI_moreAttrs, mask OLBMA_CENTER_MONIKER
	jz	10$
	or	ss:[bp].OMA_drawMonikerFlags, J_CENTER shl offset DMF_X_JUST

10$:
	;
	; Clip monikers if desired.    (Always clip if menu down or right marks
	; are displayed.  -cbh 12/16/92
	;
	test	ds:[bx].OLBI_specState, (mask OLBSS_MENU_DOWN_MARK or \
					 mask OLBSS_MENU_RIGHT_MARK)
	jnz	15$

	test	ds:[bx].OLBI_moreAttrs, (mask OLBMA_CAN_CLIP_MONIKER_WIDTH or \
					 mask OLBMA_CAN_CLIP_MONIKER_HEIGHT)
	jz	20$
15$:
	or	ss:[bp].OMA_drawMonikerFlags, mask DMF_CLIP_TO_MAX_WIDTH
20$:
	mov	bx, ds:[bx].OLBI_genChunk
	segmov	es, ds				;pass *es:bx = generic object
						;which holds moniker.
	call	OpenDrawMoniker
EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>

	mov	bx, ds:[si]			;pass gen chunk in es:bx
	add	bx, ds:[bx].Vis_offset
	pop	ds:[bx].VI_bounds.R_bottom
	pop	ds:[bx].VI_bounds.R_top		;is this the worst I've done?

	add	sp, size OpenMonikerArgs	;dump args
	ret
OLButtonDrawMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when the button is to be made visible on the screen.
		Subclassed to check if this is a button in the title bar
		that required rounded edges.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
		bp	= 0 if top window, else window for object to open on

RETURN:		None
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
	Sadly enough, this seems to be the best place to do this check
	even though it will be done every time the window is opened.
	But this will not send a message to the window if the button
	is not in the title bar, or if it is and the special bit is
	already set.  Also, if the button is in the title bar, but
	does not have a rounded top corner, then an attribute is set
	so that we do not have to keep sending messages to the parent
	window.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_ROUND_THICK_DIALOGS

OLButtonVisOpen	method	dynamic	OLButtonClass,	MSG_VIS_OPEN
	push	bp				; save bp for call superclass
	
	; See if we have already set this special bit.
	
	test	ds:[di].OLBI_optFlags, mask OLBOF_HAS_ROUNDED_TOP_CORNER
	jnz	done				; already set, skip this
	
	; See if we have already checked this object, and there is no
	; need to continue because it is not special.
	
	mov	ax, ATTR_OL_BUTTON_NO_ROUNDED_TOP_CORNER
	call	ObjVarFindData
	jc	done				; no rounded corner needed,
						;   alredy checked
	
	; If this button is a sys icon or has asked to seek the title bar,
	; then check if it needs a rounded top corner
	
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jnz	checkWindow
	mov	ax, ATTR_OL_BUTTON_IN_TITLE_BAR
	call	ObjVarFindData
	jnc	done

checkWindow:
	; Check with parent to see if this button indeed needs to have
	; a rounded top corner.  Look up the vis tree till we find on
	; object of class OLWinClass
	; visual tree until we find an object of class OLWinClass.
	
	mov	cx, es
	mov	dx, offset OLWinClass
	; *ds:si points to self
	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock		; Destroys: ax, bp

	jnc	setNoRoundedTopCorner		; no object of such class
	
	; ^lcx:dx = object ptr for parent of correct class
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	push	si				; preserve handle to self
	mov	bx, cx
	mov	si, dx
	mov	cx, ds:[di].VI_bounds.R_left
	mov	dx, ds:[di].VI_bounds.R_right
	cmp	cx, dx
	je	setNoRoundedTopCornerPopSi	; no width, no rounded corner
	
	; bx:si points to parent of class OLWinClass
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_OL_WIN_SHOULD_TITLE_BUTTON_HAVE_ROUNDED_CORNER
	call	ObjMessage			; Destroys: ax?, cx, dx, bp

	pop	si				; handle to self
	jnc	setNoRoundedTopCorner		; Doesn't need rounded corner
	
	; Should have a rounded corner!
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	
	ornf	ds:[di].OLBI_optFlags, mask OLBOF_HAS_ROUNDED_TOP_CORNER
	tst	ax
	jz	done				; right corner, done.
	mov	ax, ATTR_OL_BUTTON_ROUNDED_TOP_LEFT_CORNER
	clr	cx				; no data
	call	ObjVarAddData
	
done:
	
	; Call superclass
	pop	bp				; restore arg for superclass
	mov	ax, MSG_VIS_OPEN
	mov	di, offset OLButtonClass
	GOTO	ObjCallSuperNoLock		; <= RETURN
	
setNoRoundedTopCornerPopSi:
	pop	si				; jumped before we could pop
	
	; Set the no rounded top corner attribute, and then exit.
setNoRoundedTopCorner:
	mov	ax, ATTR_OL_BUTTON_NO_ROUNDED_TOP_CORNER
	clr	cx				; no data
	call	ObjVarAddData
	jmp	done
OLButtonVisOpen	endm


endif	;_ROUND_THICK_DIALOGS



ButtonCommon ends
ButtonCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonReleaseMouseGrab

DESCRIPTION:	This procedure makes sure that this button has
		released the mouse grab (exclusive).

CALLED BY:	OLMenuButtonHandleDefaultFunction
		OLButtonMouse

PASS:		*ds:si	= instance data for object

RETURN:		ds, si, di, cx, dx, bp = same
		carry set if did release mouse grab

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonReleaseMouseGrab	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB
	jz	done			;skip if not (cy=0)...

	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_HAS_MOUSE_GRAB
	push	di
	call	VisReleaseMouse		;Release the mouse grab
	pop	di
	stc				;return flag: did release mouse

done:
	ret
OLButtonReleaseMouseGrab	endp

ButtonCommon ends
ButtonCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonReleaseDefaultExclusive

DESCRIPTION:	This procedure releases the default exclusive for this
		button. The window will send a method to itself on the
		queue, so that if no other button grabs the default exclusive
		IMMEDIATELY, the master default for the window will grab it.

PASS:		*ds:si - instance data
		es - segment of MetaClass

RETURN:		nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		Initial version

------------------------------------------------------------------------------@

OLButtonReleaseDefaultExclusive	proc	far
	;if this GenTrigger is not marked as the DEFAULT trigger,
	;and is not destructive, release the teporary default exclusive
	;we have been granted. Master Default MUST NOT do this.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	90$			;skip if destructive...

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
					mask OLBSS_IN_MENU_BAR
	jnz	90$			;skip if default or nasty...

	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_RELEASE_DEFAULT_EXCLUSIVE
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	call	CallOLWin		; call OLWinClass object above us
90$:
	ret
OLButtonReleaseDefaultExclusive	endp

ButtonCommon ends
ButtonCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonReleaseAllGrabs

DESCRIPTION:	Intercept this method here to ensure that this button
		has released any grabs it may have.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@


OLButtonReleaseAllGrabs	proc	far

	; Release Mouse, Default, & Focus exlcusives, if we have them.
	;
	call	OLButtonReleaseMouseGrab
	call	OLButtonReleaseDefaultExclusive
	call	MetaReleaseFocusExclLow
	ret

OLButtonReleaseAllGrabs	endp


if _HAS_LEGOS_LOOKS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBSpecSetLegosLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the hints on a button according to the legos look
		requested, after removing the hints for its previous look.
		These hints are stored in tables that each different SpecUI
		will change according to the legos looks they support.

CALLED BY:	MSG_SPEC_SET_LEGOS_LOOK
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		cl	= legos look
RETURN:		carry	= set if the look was invalid (new look not set)
			= clear if the look was valid (new look set)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLBSpecSetLegosLook	method dynamic OLButtonClass, 
					MSG_SPEC_SET_LEGOS_LOOK
	uses	ax, cx
	.enter
	;
	; Legos users pass in 0 as the base, we really want
	; this to map to the a hint, so we up it to 1.
	; We will dec it when in SPEC_GET_LEGOS_LOOK
	inc	cl

	clr	bx
	mov	bl, ds:[di].OLBI_legosLook
	cmp	bx, LAST_LEGOS_BUTTON_LOOK
	jbe	validExistingLook

	clr	bx		; make the look valid if it wasn't
EC<	WARNING	WARNING_INVALID_LEGOS_LOOK		>

validExistingLook:
	clr	ch
	cmp	cx, LAST_LEGOS_BUTTON_LOOK
	ja	invalidNewLook

	mov	ds:[di].OLBI_legosLook, cl
	;
	; remove hint from old look
	;
	shl	bx			; byte value to word table offset
	mov	ax, cs:[legosButtonLookHintTable][bx]
	tst	ax
	jz	noHintToRemove

	call	ObjVarDeleteData

	;
	; add hints for new look
	;
noHintToRemove:
	mov	bx, cx
	shl	bx			; byte value to word table offset
	mov	ax, cs:[legosButtonLookHintTable][bx]
	tst	ax
	jz	noHintToAdd

	clr	cx
	call	ObjVarAddData

noHintToAdd:
	clc
done:
	.leave
	ret

invalidNewLook:
	stc
	jmp	done
OLBSpecSetLegosLook	endm

	;
	; Make sure this table matches that in copenButtonCommon.asm.  The
	; only reason the table is in two places it is that I don't want
	; to be bringing in the ButtonCommon resource at build time, and it
	; is really a small table.
	; Make sure any changes in either table are reflected in the other
	;
legosButtonLookHintTable	label word
	word	0			; standard button has no special hint.
LAST_LEGOS_BUTTON_LOOK	equ ((($ - legosButtonLookHintTable)/(size word)) - 1)
CheckHack<LAST_LEGOS_BUTTON_LOOK eq LAST_BUILD_LEGOS_BUTTON_LOOK>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLBSpecGetLegosLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the legos look of an object

CALLED BY:	MSG_SPEC_GET_LEGOS_LOOK
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
RETURN:		cl	= legos look
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLBSpecGetLegosLook	method dynamic OLButtonClass, 
					MSG_SPEC_GET_LEGOS_LOOK
	.enter
	mov	cl, ds:[di].OLBI_legosLook
	;
	; We inc'd it in set.
	dec	cl
	.leave
	ret
OLBSpecGetLegosLook	endm


endif		; endif of _HAS_LEGOS_LOOKS

ButtonCommon ends
GadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSetDrawStateUnknown --
		MSG_OL_BUTTON_SET_DRAW_STATE_UNKNOWN

DESCRIPTION:	This procedure marks the button as invalid so that next
		time it is drawn, no optimizations are attempted.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonSetDrawStateUnknown	method	dynamic OLButtonClass, \
					MSG_OL_BUTTON_SET_DRAW_STATE_UNKNOWN
	ANDNF	ds:[di].OLBI_optFlags, not (mask OLBOF_DRAW_STATE_KNOWN)
	ret
OLButtonSetDrawStateUnknown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonSetBordered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes the button bordered/unbordered.  This makes it
		possible for popup menus to broadcast a notification to
		all its button children to draw their borders when the
		window is pinned.

CALLED BY:	MSG_OL_BUTTON_SET_BORDERED

PASS:		*ds:si	= instance data for object
		cx	= TRUE to make the button bordered, FALSE to not

RETURN:		*ds:si = same

DESTROYED:	ax, bx, cx, dx, bp, es, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	8/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _OL_STYLE	;---------------------------------------------------------------

OLButtonSetBordered	method	dynamic OLButtonClass, \
						MSG_OL_BUTTON_SET_BORDERED
	ANDNF	ds:[di].OLBI_specState, not (mask OLBSS_BORDERED)

	cmp	cx, FALSE
	je	10$

	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED

10$:
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid
	clc				;keeps VisIfFlagSetCallVisChildren quick
	ret
OLButtonSetBordered	endp

endif		;---------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonGetGenPart -- MSG_OL_BUTTON_GET_GEN_PART for
			OLButtonClass

DESCRIPTION:	This procedure returns the OD of the generic object which
		is associated with this button. For simple GenTriggers,
		the generic object is the button itself. For others,
		the generic object might be a GenInteraction or GenDisplay
		which has the moniker for the button.

PASS:		ds:*si	- instance data

RETURN:		^lcx:dx - OD of generic object

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/89		initial version

------------------------------------------------------------------------------@

OLButtonGetGenPart	method	OLButtonClass, MSG_OL_BUTTON_GET_GEN_PART
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].OLBI_genChunk	; get chunk holding gen data
	ret
OLButtonGetGenPart	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonChange -- 
		MSG_SPEC_CHANGE for OLButtonClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Does a "change" for this button.

PASS:		*ds:si 	- instance data
		es     	- segment of OLButtonClass
		ax 	- MSG_SPEC_CHANGE

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/ 1/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GadgetCommon ends
