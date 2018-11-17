COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		
FILE:		

AUTHOR:		Doug, 8/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/90		Initial revision

DESCRIPTION:

	This file implements the setup screen summons object class, a
	subclass of GenSummons that serves to intercept all keyboard
	input, call auxiliary actions when opened, and other neat things.
		
	$Id: setupScreenClass.asm,v 1.1 97/04/04 16:28:08 newdeal Exp $

-------------------------------------------------------------------------------@

idata segment

; Declare the class record
	SetupScreenClass

; Variable to track the number of screens that have been put up. A screen
; refuses to come down if it's the only one on-screen.
numOnScreen	word	0

idata ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupScreenDismiss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the screen go away.

CALLED BY:	
PASS:		*ds:si	= object
		ds:di	= master-group data
		ds:bx	= Base structure of object
		ax	= method #
RETURN:		
DESTROYED:	bx, si, di, ds, es allowed

PSEUDO CODE/STRATEGY:
	 Send a MSG_GEN_GUP_INTERACTION_COMMAND with IC_Dismiss to the
	 superclass

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupScreenDismiss		method dynamic SetupScreenClass,
				MSG_SETUP_SCREEN_DISMISS
		uses	ax, cx
		.enter

	;
	; See if we're the only screen around. If so, refuse to go away.
	;
		dec	es:[numOnScreen]
		jnz	goAway
		inc	es:[numOnScreen]
		jmp	done
goAway:
		andnf	ds:[di].SSI_flags, not mask SSF_ON_SCREEN

	;
	; We're ok, so pass the method to our superclass to handle.
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock

done:

		.leave
		ret
SetupScreenDismiss		endm


COMMENT @----------------------------------------------------------------------

METHOD:		SetupScreenActivate

DESCRIPTION:	Intercept <CR> hit in summons

PASS:
	*ds:si - instance data
	es - segment of SetupScreenClass

	ax - MSG_GEN_ACTIVATE_INTERACTION_DEFAULT

RETURN:


DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/90		Initial version

------------------------------------------------------------------------------@
SetupScreenActivate	method	SetupScreenClass,
				MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
	.enter
					; If in the middle of changing screens, 
					; ignore requests to move to yet another
					; screen.
	test	ds:[di].SSI_flags, mask SSF_CHANGING_SCREENS
	jz	continue
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	jmp	short done
continue:
	add	di, offset SSI_enterAction
	call	SSCallAction
done:

	.leave
	ret

SetupScreenActivate	endm


COMMENT @----------------------------------------------------------------------

METHOD:		SetupScreenInitiate

DESCRIPTION:	Intercept GEN_INITIATE_INTERACTION, set flag to indicate
		changing screens, give queue-looping MOTIF a chance to 
		get the ptr image changed, & then actually initiate the
		sucker.

PASS:
	*ds:si - instance data
	es - segment of SetupScreenClass

	ax - MSG_GEN_INITIATE_INTERACTION

RETURN:


DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/90		Initial version

------------------------------------------------------------------------------@
SetupScreenInitiate	method	SetupScreenClass,
				MSG_GEN_INTERACTION_INITIATE
	.enter

	test	ds:[di].SSI_flags, mask SSF_ON_SCREEN
	jnz	doInputIgnore
	
	inc	es:[numOnScreen]
	ornf	ds:[di].SSI_flags, mask SSF_ON_SCREEN

doInputIgnore:

				; Starting screen change - send notification
				; to ourselves
	push	ax, cx, dx, bp
	mov	ax, MSG_SETUP_SCREEN_CHANGE_START
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

				; Force method on the queue, to allow
				; ptr image to change, then initiate interaction
	mov	ax, MSG_SETUP_SCREEN_REAL_INITIATE_INTERACTION
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
SetupScreenInitiate	endm



COMMENT @----------------------------------------------------------------------

METHOD:		SetupScreenRealInitiateInteraction

DESCRIPTION:	Perform the real initiation of this screen, now that
		the specific UI will have had time to change the ptr
		image to busy.

PASS:
	*ds:si - instance data
	es - segment of SetupScreenClass

	ax - MSG_SETUP_SCREEN_REAL_INITIATE_INTERACTION

RETURN:


DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

SetupScreenRealInitiateInteraction	method	SetupScreenClass,
			MSG_SETUP_SCREEN_REAL_INITIATE_INTERACTION
	.enter

	push	ax, cx, dx, bp, si
	add	di, offset SSI_initiateAction
	call	SSCallAction
	pop	ax, cx, dx, bp, si

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, offset SetupScreenClass
	CallSuper	MSG_GEN_INTERACTION_INITIATE

				; Screen change ending - send notification
				; to ourselves, forced via the queue so as
				; to flush out exposure of window, header
				; update, etc.
	mov	ax, MSG_SETUP_SCREEN_CHANGE_IN_PROGRESS
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
SetupScreenRealInitiateInteraction	endm



COMMENT @----------------------------------------------------------------------

METHOD:		SetupScreenChangeStart

DESCRIPTION:	Notification that the user is changing screens

PASS:
	*ds:si - instance data
	es - segment of SetupScreenClass

	ax - MSG_SETUP_SCREEN_CHANGE_START

RETURN:


DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Initial version

------------------------------------------------------------------------------@
SetupScreenChangeStart	method	SetupScreenClass,
				MSG_SETUP_SCREEN_CHANGE_START

	; Shouldn't be non-zero yet, but keep our cool should it ever be
	; that way..
		test	ds:[di].SSI_flags, mask SSF_CHANGING_SCREENS
		jnz	done

	; Set flag indicating we're in the middle of
	; changing screens.
		or	ds:[di].SSI_flags, mask SSF_CHANGING_SCREENS

	;
	; Mark application as busy, so if cursor is up, it will
	; activate.  We need to use "completely busy", since "busy"
	; won't work over a modal interaction.  Who knows why?
	;
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
		call	GenCallApplication

done:
	ret
SetupScreenChangeStart	endm


COMMENT @----------------------------------------------------------------------

METHOD:		SetupScreenChangeInProgress

DESCRIPTION:	Notification that the screen change in progress has
		partially completed

PASS:
	*ds:si - instance data
	es - segment of SetupScreenClass

	ax - MSG_SETUP_SCREEN_CHANGE_IN_PROGRESS

RETURN:


DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Initial version

------------------------------------------------------------------------------@
SetupScreenChangeInProgress	method	SetupScreenClass,
				MSG_SETUP_SCREEN_CHANGE_IN_PROGRESS

				; Screen change ending - send notification
				; to ourselves, forced via the queue so as
				; to flush out kbd, ptr, button events.
	mov	ax, MSG_SETUP_SCREEN_CHANGE_END
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	ret
SetupScreenChangeInProgress	endm




COMMENT @----------------------------------------------------------------------

METHOD:		SetupScreenChangeEnd

DESCRIPTION:	Notification that the screen change in progress has
		completed

PASS:
	*ds:si - instance data
	es - segment of SetupScreenClass

	ax - MSG_SETUP_SCREEN_CHANGE_END

RETURN:


DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Initial version

------------------------------------------------------------------------------@
SetupScreenChangeEnd	method	SetupScreenClass,
				MSG_SETUP_SCREEN_CHANGE_END

	
	; Shouldn't be cleared yet, but keep our cool if somehow we
	; get in that state.
	test	ds:[di].SSI_flags, mask SSF_CHANGING_SCREENS
	jz	done

	; Clear flag indicating we're in the middle of
	; changing screens -- because we aren't anymore.
	and	ds:[di].SSI_flags, not mask SSF_CHANGING_SCREENS

	; Mark application as no longer busy
		
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	GenCallApplication
done:
	ret

SetupScreenChangeEnd	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupScreenFindMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a typed key matches any of our "mnemonics"

CALLED BY:	MSG_SPEC_CHECK_MNEMONIC
PASS:		*ds:si	= SetupScreenClass object
		ds:di	= SetupScreenInstance data
		es 	= segment of SetupScreenClass
		cx	= character value (ch is CharacterSet)
		dl	= CharFlags
		dh	= ShiftState
		bp.low	= ToggleState
		bp.high	= scan code
RETURN:		carry set if match found
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupScreenFindMnemonic	method dynamic SetupScreenClass, MSG_META_FUP_KBD_CHAR,
					MSG_GEN_FIND_KBD_ACCELERATOR
		.enter


	;
	; Ignore the kbd release
	;
		test	dl, mask CF_RELEASE
		jnz	done

ifdef	GPC_VERSION
	;
	; Check for RCtrl-LShift-F12, which switches back to the system
	; default video mode.
	;
SBCS <		cmp	cx, (CS_CONTROL shl 8) or VC_F12		>
DBCS <		cmp	cx, C_SYS_F12					>
		jne	notDefaultVideoKey
		cmp	dh, mask SS_RCTRL or mask SS_LSHIFT
		jne	notDefaultVideoKey
	;
	; Hot key is pressed.  Revert video settings and restart the system.
	;
		mov	bx, handle 0
		mov	ax, MSG_SETUP_REVERT_VIDEO
		clr	di
		call	ObjMessage

		jmp	consumed
notDefaultVideoKey:
endif	; GPC_VERSION

	;
	; None of our mnemonics is modified at all
	;
		test	dh, not (mask SS_LSHIFT or mask SS_RSHIFT)
		jnz	ignore
ifdef	GPC_VERSION
	;
	; First check for 'Y', which is in the BSW set.
	;
		mov	bx, offset SSI_yesAction
SBCS <		cmp	cx, (CS_BSW shl 8) or C_CAP_Y			>
DBCS <		cmp	cx, C_LATIN_CAPITAL_LETTER_Y			>
		je	haveAction
SBCS <		cmp	cx, (CS_BSW shl 8) or C_SMALL_Y			>
DBCS <		cmp	cx, C_LATIN_SMALL_LETTER_Y			>
		je	haveAction
endif	; GPC_VERSION

	;
	; All lie in the control set
	;
SBCS <		cmp	ch, CS_CONTROL					>
SBCS <		jne	ignore						>
DBCS <		cmp	ch, CS_CONTROL_HB				>
DBCS <		jne	ignore						>
	;
	; Check for specifics.
	;
		mov	bx, offset SSI_escapeAction
SBCS <		cmp	cl, VC_ESCAPE		; ESC?			>
DBCS <		cmp	cx, C_SYS_ESCAPE				>
		je	haveAction
		
		mov	bx, offset SSI_f10Action
SBCS <		cmp	cl, VC_F10					>
DBCS <		cmp	cx, C_SYS_F10					>
		je	haveAction
		
ifdef	GPC_VERSION
		jmp	ignore
else
SBCS <		cmp	cl, VC_F3					>
DBCS <		cmp	cx, C_SYS_F3					>
		jne	ignore

		mov	ax, SST_CLEAN_FORCED
		call	SysShutdown
		jmp	consumed
endif	; GPC_VERSION

haveAction:
					; If in the middle of changing screens, 
					; ignore requests to move to yet another
					; screen.
		test	ds:[di].SSI_flags, mask SSF_CHANGING_SCREENS
		jz	continue
		mov	ax, SST_NO_INPUT
		call	UserStandardSound
		jmp	short done
continue:

		add	di, bx		; ds:di <- ActionDescriptor
		call	SSCallAction
consumed::
		stc
done:
		.leave
		ret
ignore:
		;
		; if VIS_FUP_KBD_CHAR, then send to superclass
		; else clc and return
		;
		cmp	ax, MSG_META_FUP_KBD_CHAR
		jnz	clear_and_exit

		mov	di, offset SetupScreenClass
		call	ObjCallSuperNoLock
		jmp	done

clear_and_exit:
		clc			; signal event not consumed
		jmp	done
SetupScreenFindMnemonic	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCallAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subroutine to send stuff through an ActionDescriptor

CALLED BY:	SetupScreenFindMnemonic, SetupScreenActivate
PASS:		ds:di	= ActionDescriptor address
		*ds:si	= SetupScreen object
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSCallAction	proc	near
		.enter
		mov	bx, ds:[di].AD_OD.handle
		mov	ax, ds:[di].AD_message
		mov	si, ds:[di].AD_OD.chunk
		clr	di		; allow instant response if run by
					;  same thread.  No need for call,
					;  however
		call	ObjMessage
		.leave
		ret
SSCallAction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupScreenDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw method for a screen so we can allow extra screen-specific
		draw actions and put up instructions for the user.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= SetupScreenClass object
		bp	= GState to use for drawing
		cl	= DrawFlags
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupScreenDraw	method	SetupScreenClass, MSG_VIS_DRAW
		.enter
	;
	; Call the superclass to draw all the kids
	;
		push	bp
		mov	di, offset SetupScreenClass
		CallSuper	MSG_VIS_DRAW
		pop	bp
	;
	; Now perform any extra drawing action required of the screen.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	
		mov	bx, ds:[di].SSI_extraDrawAction.segment
		mov	ax, ds:[di].SSI_extraDrawAction.offset
		tst	bx
		jz	done
		mov	di, bp		; di <- gstate
		call	ProcCallFixedOrMovable
done:
		.leave
		ret
SetupScreenDraw	endp

; Table of object chunks of template instruction strings to copy into screens,
; ordered according to SSInstructions mask, from high bit to low.

setupScreenInstructions	word	\
	offset promptCR,	;SSI_ENTER_TO_CONTINUE
ifdef	GPC_VERSION
	offset promptY,		;SSI_Y_TO_CONTINUE
endif	; GPC_VERSION
	offset promptEscPrev,	;SSI_ESC_TO_RETURN_TO_PREV
	offset promptSelVideo,	;SSI_F10_TO_CHANGE_VIDEO
	offset promptRevVideo,	;SSI_F10_TO_REVERT_VIDEO
	offset promptSelMouse,	;SSI_F10_TO_CHANGE_MOUSE
	offset promptSelPrinter,;SSI_F10_TO_CHANGE_PRINTER
	offset promptEscEnterLater,	;SSI_ESC_ENTER_LATER
	offset promptExit	;SSI_F3_TO_EXIT_TO_DOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupScreenSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add instruction strings to the screen based on the bitmask
		in the instance data.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We don't need an unbuild function b/c these screens never
		come down until we're about to exit...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/90		Initial version
	cassie	4/28/93		don't add anything if no instructions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupScreenSpecBuild	method	SetupScreenClass, MSG_SPEC_BUILD
		.enter
		push	ax, cx, dx, bp, si, es
	;
	; Check if there are any instructions to be added.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		tst	ds:[di].SSI_instructions
		jz	noInstructions

	;
	; Copy in the interaction to hold the instructions.
	;
		push	si
		segmov	es, ds		; es <- screen's block

		mov	bx, handle ScreenTemplates
		call	ObjSwapLock	; bx <- screen's block, ds <- template
					;  block segment
		
		mov	cx, bx
		mov	dx, si		; We are its parent

		mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
		mov	si, offset SpaceBox
		mov	ax, MSG_GEN_COPY_TREE
		call	ObjCallInstanceNoLockES
		pop	dx
		push	dx

		mov	si, offset InstructionsBox
		mov	ax, MSG_GEN_COPY_TREE
		call	ObjCallInstanceNoLockES	; cx:dx <- new object
	;
	; Now figure which instruction glyph displays to copy in by shifting
	; the bitmask out one bit at a time and copying the appropriate
	; GenGlyph into the screen's block as a child of the interaction
	; we just copied in.
	; 
		pop	si		; recover screen object
		mov	di, es:[si]
		add	di, es:[di].Gen_offset
ifdef	GPC_VERSION
		mov	ax, es:[di].SSI_instructions
else
		mov	al, es:[di].SSI_instructions
endif	; GPC_VERSION
		mov	di, offset setupScreenInstructions
		mov	cx, length setupScreenInstructions
copyLoop:
ifdef	GPC_VERSION
		shl	ax
else
		shl	al
endif	; GPC_VERSION
		jnc	next
		push	ax, cx, dx
		mov	cx, bx		; cx:dx <- parent 
		mov	si, cs:[di]	; ds:si <- template
		mov	ax, MSG_GEN_COPY_TREE
		mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
		call	ObjCallInstanceNoLockES
		pop	ax, cx, dx
next:
		inc	di
		inc	di
		loop	copyLoop
		
	;
	; Unlock the template block now we've copied out of it what we need.
	; 
		call	ObjSwapUnlock

noInstructions:
	;
	; Pass it on to our superclass first to perform the necessary Vis
	; operations.
	; 
		pop	ax, cx, dx, bp, si, es

		mov	di, offset SetupScreenClass
		CallSuper	MSG_SPEC_BUILD
		.leave
		ret
SetupScreenSpecBuild	endp


;
;COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;		SetupScreenDismiss
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;SYNOPSIS:	Field a request to make this screen go away.
;
;CALLED BY:	MSG_GEN_DISMISS_INTERACTION
;PASS:		*ds:si	= SetupScreen object
;RETURN:		nothing
;DESTROYED:	ax, bx, cx, dx, si, di, bp, es, ds
;
;PSEUDO CODE/STRATEGY:
;		
;
;KNOWN BUGS/SIDE EFFECTS/IDEAS:
;		
;
;REVISION HISTORY:
;	Name	Date		Description
;	----	----		-----------
;	ardeb	10/24/90	Initial version
;	dloft	5/7/92		port to 2.0
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;SetupScreenDismiss method	SetupScreenClass, MSG_GEN_GUP_INTERACTION_COMMAND
;		.enter
;	;
;	; See if we're the only screen around. If so, refuse to go away.
;	;
;		dec	es:[numOnScreen]
;		jnz	goAway
;		inc	es:[numOnScreen]
;		jmp	done
;goAway:
;		andnf	ds:[di].SSI_flags, not mask SSF_ON_SCREEN
;	;
;	; We're ok, so pass the method to our superclass to handle.
;	;
;		mov	ax, MSG_GEN_INTERACTION_DISMISS
;		mov	di, offset SetupScreenClass
;		CallSuper	MSG_GEN_INTERACTION_DISMISS
;done:
;		.leave
;		ret
;SetupScreenDismiss endp
