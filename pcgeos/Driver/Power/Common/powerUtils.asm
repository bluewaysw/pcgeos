COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Driver/Power/Common
FILE:		powerUtils.asm

AUTHOR:		Adam de Boor, May 10, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT CallRoutineInUI         Call a routine, but do it in the UI thread

    INT DisplayMessage          Display a message

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/10/93		Initial revision


DESCRIPTION:
	Utility routines that aren't logically a part of any particular
	facet of power management.
		

	$Id: powerUtils.asm,v 1.1 97/04/18 11:48:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DISPLAY_MESSAGES

Resident	segment	resource

ifndef	USE_IM_FOR_INITIAL_POLLING
USE_IM_FOR_INITIAL_POLLING	equ	FALSE
endif

if	USE_IM_FOR_INITIAL_POLLING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRoutineInIM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a routine, but do it in the IM thread

CALLED BY:	INTERNAL
PASS:		ax, bx, cx, dx, si	= data for routine
		di:bp	= fptr/vfptr routine to call
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	6/15/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallRoutineInIM	proc	near
	pusha

	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax

	call	ImInfoInputProcess	; bx = IM handle
	jmp	callRoutine

CallRoutineInIM	endp

endif	; USE_IM_FOR_INITIAL_POLLING

COMMENT @----------------------------------------------------------------------

FUNCTION:	CallRoutineInUI

DESCRIPTION:	Call a routine, but do it in the UI thread

CALLED BY:	INTERNAL

PASS:
	ax, bx, cx, dx, si, - data for routine
	dibp - offset of routine to call

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/22/93		Initial version

------------------------------------------------------------------------------@
CallRoutineInUI	proc	near
	pusha

	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax

	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo			;ax = ui handle
	mov_tr	bx, ax

callRoutine	label	near
	pushdw	dibp
	mov	bp, sp				;ss:bp = parameters
	mov	ax, MSG_PROCESS_CALL_ROUTINE
	mov	dx, size ProcessCallRoutineParams
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	call	ObjMessage

	add	sp, dx

	popa
	ret

CallRoutineInUI	endp

Resident	ends

;---

idata segment

;
; Queue to hold responses
;
messageResponseQueue	word	0
;
; Number of message dialogs displayed
;
messageCount		word	0

idata ends

Movable	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	DisplayMessage

DESCRIPTION:	Display a message

CALLED BY:	INTERNAL

PASS:
	ax - CustomDialogBoxFlags
	si - chunk handle of message (in StringsUI resource)

RETURN:
	carry set if not displayed

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/23/93		Initial version

------------------------------------------------------------------------------@
DisplayMessage		proc	far
	uses ax, bx, cx, dx, si, di, bp, ds
	.enter

	; deal with the event queue

	push	ax, si					; save flags & string

	mov	ax, dgroup
	mov	ds, ax
	mov	bx, ds:[messageResponseQueue]

	tst	bx
	jz	createQueue	; => need a queue

	; if there is a message in the queue then delete them and reduce
	; the count

queueLoop:
	call	GeodeInfoQueue
	tst	ax
	jz	afterQueue	; => empty queue

	call	QueueGetMessage
	mov_tr	bx, ax
	call	ObjFreeMessage

	mov	bx, ds:[messageResponseQueue]

	dec	ds:[messageCount]
	jnz	queueLoop	; => might be more

afterQueue:
	pop	ax, si					; restore flags & string

	; if there is a message being displayed then bail

	tst_clc	ds:[messageCount]
	jnz	error	; => prev. dialog still up

	; display the message in a dialog
	inc	ds:[messageCount]			; one more message

	push	ax, bx, dx, si, di, ds
	call	DisplayMessageLow		; destroy ax,bx,dx,si,di,ds
	pop	ax, bx, dx, si, di, ds
	stc						; return clear

error:
	cmc
	.leave
	ret

createQueue:
	; no event queue exists -- create one

	call	GeodeAllocQueue
	mov	ds:[messageResponseQueue], bx
	jmp	afterQueue

DisplayMessage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayMessageLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually throw up a dialog

CALLED BY:	INTERNAL
PASS:		ds	-> dgroup
		ax	-> CustomDialogBoxFlags
		bx	-> destination queue
		si	-> chunk handle of message (in StringsUI) to display
RETURN:		nothing
DESTROYED:	ax, bx, dx, si, di, ds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	7/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayMessageLow	proc	far
params	local	GenAppDoDialogParams
trigTab	local	StandardDialogResponseTriggerTable
	.enter

	; do a warning
	push	bx					; save queue
	mov	params.GADDP_dialog.SDP_customFlags, ax
	clr	bx
	clrdw	params.GADDP_dialog.SDP_stringArg1, bx
	clrdw	params.GADDP_dialog.SDP_stringArg2, bx
	clrdw	params.GADDP_dialog.SDP_helpContext, bx
	mov	trigTab.SDRTT_numTriggers, bx
	mov	params.GADDP_dialog.SDP_customTriggers.segment, ss
	lea	bx, trigTab
	mov	params.GADDP_dialog.SDP_customTriggers.offset, bx
	mov	params.GADDP_message, MSG_META_DUMMY

	pop	params.GADDP_finishOD.handle

	mov	bx, handle StringsUI
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	movdw	params.GADDP_dialog.SDP_customString, dssi

	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	mov	dx, size GenAppDoDialogParams
	mov	di, mask MF_CALL or mask MF_STACK
	push	bp
	lea	bp, params
	call	ObjMessage
	pop	bp

	mov	bx, handle StringsUI
	call	MemUnlock

	.leave
	ret
DisplayMessageLow	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PowerDoWarningBeep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the UI library and beep if it's there.

CALLED BY:	UTILITY

PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	7/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PowerDoWarningBeep	proc	far
		uses	dx
		.enter
	;
	; Is the UI loaded?
	;
		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo		; nukes dx
		tst	ax
		jz	done			; jump if no UI
	;
	; The UI's running.  Ask it to beep.
	;
		mov	bx, ax			; bx <- lib handle
		mov	ax, enum UserStandardSound
		call	ProcGetLibraryEntry	; bx:ax <- vfar ptr to routine

		mov	ss:[TPD_dataAX], SST_WARNING
		call	ProcCallFixedOrMovable
done:
		.leave
		ret
PowerDoWarningBeep	endp
endif

Movable	ends

endif
