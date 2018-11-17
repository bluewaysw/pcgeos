COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		apmVerify.asm

AUTHOR:		Todd Stumpf, Aug  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94   	Initial revision


DESCRIPTION:
	
		

	$Id: apmVerify.asm,v 1.1 97/04/18 11:48:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMVerifySuspendWithUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the user wants to suspend

CALLED BY:	APMPollForWarnings

PASS:		si	-> reason not to suspend
		ds	-> dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Displays Sys-modal dialog box asking user
		if they really want to suspend, and displays
		reason why they should not.

PSEUDO CODE/STRATEGY:
		???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMVerifySuspendWithUserFar	proc	far
	call	APMVerifySuspendWithUser
	ret
APMVerifySuspendWithUserFar	endp

APMVerifySuspendWithUser	proc	near
dialogParams	local	GenAppDoDialogParams
	uses	ax, bx, cx, dx, si, di, es
	.enter
	mov	al, TRUE
	xchg	al, ds:[verifyDialog]

	cmp	al, TRUE
	je	done

	;
	;  Lock strings resource
	mov	bx, handle StringsUI
	call	MemLock				; ax <- segment
	mov	es, ax				; es <- segment

	;
	;  Set up the dialogParams
	mov	ax, ds:[responseQueue]
	mov	dialogParams.GADDP_finishOD.handle, ax

ifidn	HARDWARE_TYPE, <GPC1>
	mov	dialogParams.GADDP_dialog.SDP_customFlags, \
		CustomDialogBoxFlags <1, CDT_WARNING, GIT_NOTIFICATION,>

	mov	di, es:[si]			; Use the passed string directly
	movdw	dialogParams.GADDP_dialog.SDP_customString, esdi
else
	mov	dialogParams.GADDP_dialog.SDP_customFlags, \
		CustomDialogBoxFlags <1, CDT_WARNING, GIT_AFFIRMATION,>

	mov	di, offset PowerOffCustomString
	mov	di, es:[di]
	movdw	dialogParams.GADDP_dialog.SDP_customString, esdi
	mov	si, es:[si]
	movdw	dialogParams.GADDP_dialog.SDP_stringArg1, essi
endif	; HARDWARE_TYPE, <GPC1>

	clrdw	dialogParams.GADDP_dialog.SDP_helpContext
	mov	dialogParams.GADDP_message, \
			MSG_META_APP_VERIFY_SUSPEND_DIALOG_RESPONDED

	;
	;  Locate the UI's application object

	call	APMGetUIAppObject

	;
	;  Send it the message to put up the box.
	push	bp
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	mov	dx, size GenAppDoDialogParams
	lea	bp, dialogParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage	; ax, cx, dx, bp destroyed
	pop	bp

	;
	;  Mark dialog as active
	inc	ds:[waitingForResponse]

	;
	;  Unlock strings resource
	mov	bx, handle StringsUI
	call	MemUnlock
done:
	.leave
	ret
APMVerifySuspendWithUser	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetUIAppObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the optr of the UI's app object

CALLED BY:	APMVerifySuspendWithUser, APMSuspendMachine

PASS:		nothing 

RETURN:		^lbx:si - The UI's app object

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMGetUIAppObject	proc near
		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo
		mov_tr	bx, ax
		call	GeodeGetAppObject
		ret
APMGetUIAppObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMLFR_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for APMLookForResponse to return the
		arguments to the message sent back at the conclusion of
		the dialog

CALLED BY:	(INTERNAL) APMLookForResponse via MessageProcess

PASS:		cx	-> InteractionCommand of selected Trigger
		ax	-> response message
RETURN:		cx	<- InteractionCommand of selected Trigger
		ax	<- response message
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Just return.  Let the system do all the work.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMLFR_callback	proc	far
	ret
APMLFR_callback	endp

Resident		ends


Movable			segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMLookForResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Examine Response Queue and see if there is anything there

CALLED BY:	APMPollBattery

PASS:		ds	-> dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Clears waitingForResponse byte

PSEUDO CODE/STRATEGY:
		Examine queue for event, if no event, return
		If event, get segment to handle table,
			use event as the handle it is,
			examine the returned CX value (the
			response)
		Act on response
		free the handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMLookForResponse	proc	far
	uses	ds
	.enter
	pusha
	mov	bx, ds:[responseQueue]
	call	GeodeInfoQueue		; ax <- # of events

	tst	ax
	jnz	readResponse

if	APM_VERSION ge 0x0101		; v1.1 or above
if	RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE
	; Need to check if it is the verify dialog that's on screen.
	tst	ds:[verifyDialog]
	jz	done			; => not verify suspend dialog
endif	; RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE
	;
	; Need to tell the APM BIOS that we are still waiting for a response.
	;
	mov	bx, APMDID_ALL_BIOS_DEVICES
	mov	cx, APMS_REQUEST_PROCESSING
	CallAPM	APMSC_SET_DEVICE_STATE
endif	; APM_VERSION ge 0x0101

done:
	popa
	.leave
	ret
readResponse:

	;
	;  Wow.  They responded.  Isn't that cool!

	;  Clear the response flag, get the event and see what it is.
	dec	ds:[waitingForResponse]

	call	QueueGetMessage		; ax <- message (event)
	mov_tr	bx, ax				; bx <- message

	;
	;  Get the InteractionCommand response and destroy the message
	;
	mov	ax, segment APMLFR_callback		; in fixed resource
	push	ax
	mov	ax, offset APMLFR_callback
	push	ax
	clr	si
	call	MessageProcess		; cx <- response, ax <- msg

if	RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE
	cmp	ax, MSG_META_APP_VERIFY_SUSPEND_DIALOG_RESPONDED
	je	verifySuspend

	;
	; Unlock the string block that was locked when the dialog was put up.
	;
	mov	bx, handle StringsUI
	call	MemUnlock

	;
	; Re-suspend only if the user replied "Yes" (IC_YES) or a timeout
	; occurred (IC_NULL).
	;
	cmp	cx, IC_NO
	je	done			; => Don't suspend again
	BitSet	ds:[powerDownOnIdle], AOIS_SUSPEND
		CheckHack <ISRT_SUSPEND eq 0>
	clr	bp			; bp = ISRT_SUSPEND
	call	APMSendSuspendResumeGCN
	jmp	done

verifySuspend:
endif	; RESUSPEND_IF_REBOOTED_WHILE_IN_SUSPEND_MODE

	clr	ds:[verifyDialog]

ifidn	HARDWARE_TYPE, <GPC1>
	;
	; The only possible user response is IC_OK.  Also, we don't allow
	; suspending at this point.  So inform the APM BIOS and then exit.
	;
	mov	bx, APMDID_ALL_BIOS_DEVICES
	mov	cx, APMS_REQUEST_REJECTED
	CallAPM	APMSC_SET_DEVICE_STATE
	jmp	done
else
	;
	;  Did they indicate that we should suspend?
if	APM_VERSION ge 0x0101		; v1.1 or above
	cmp	cx, IC_YES
	je	suspend

	mov	bx, APMDID_ALL_BIOS_DEVICES
	mov	cx, APMS_REQUEST_REJECTED
	CallAPM	APMSC_SET_DEVICE_STATE
	jmp	done

suspend:
else
	cmp	cx, IC_YES
	jne	done
endif	; APM_VERSION ge 0x0101

	;
	;  The user responded that they want to suspend.
	;  Ok.  Let them.
	ornf	ds:[powerDownOnIdle], mask AOIS_SUSPEND
		CheckHack <ISRT_SUSPEND eq 0>
	clr	bp			; bp = ISRT_SUSPEND
	call	APMSendSuspendResumeGCN
	call	InitFileCommit
	jmp	short done
endif	; HARDWARE_TYPE, <GPC1>
APMLookForResponse	endp

Movable		ends
