COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Input Manager
FILE:		imMonitors.asm

AUTHOR:		Adam de Boor, Jan 28, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/28/91		Initial revision


DESCRIPTION:
	Code for handling the input chain (the bulk of the input manager).
		

	$Id: imMonitors.asm,v 1.1 97/04/05 01:17:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IMResident	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToIM
FUNCTION:	CallIM
FUNCTION:	MessageOutputOD

DESCRIPTION:	Call a given OD.  Pulled out to save bytes

CALLED BY:	INTERNAL

PASS:
	ax - method to send
	cx, dx, bp

RETURN:
	carry, ax, cx, dx, bp  - as per ObjMessage used below

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
------------------------------------------------------------------------------@


SendToIM	proc	far	uses	bx, si, di, ds
	.enter
	LoadVarSeg	ds, bx
	mov	bx, ds:[imThread]
	clr	si
	mov	di,mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret

SendToIM	endp


CallIM	proc	far	uses	bx, si, di, ds
	.enter
	LoadVarSeg	ds, bx
	mov	bx, ds:[imThread]
	clr	si
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret

CallIM	endp

	; pass: di = flags

MessageOutputOD	proc	far	uses	bx, si
	.enter
	mov	bx, ds:[outputOD.handle]
	mov	si, ds:[outputOD.chunk]
	call	ObjMessage		; off she goes...
	.leave
	ret

MessageOutputOD	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImMethodButtonReceipt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return reciept to IM of MSG_META_MOUSE_BUTTON's having been received
		by the UI.  Used to keep track of whether the User has gotten
		ahead of the UI.  Should ONLY be called by the UI's flow object.
			
CALLED BY:	EXTERNAL

PASS:		cx, dx, bp	- MSG_META_MOUSE_BUTTON event data

RETURN:

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
				
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	THIS ROUTINE DOES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	(INPUT_MESSAGE_RECEIPT)
ImMethodButtonReceipt	proc	far
	push	bx, ds
	mov	bx, segment idata
	mov	ds, bx

	; Decrement # of unprocessed events for this button.

	mov	bx, bp			; copy into bx
	and	bx, mask BI_BUTTON	; clear all but button #
	shl	bx, 1			; * 2
	mov	bx, ds:[bx].bpsTable	; lookup entry for button in
					;	buttonPressStatus
	dec	ds:[bx].BPS_unprocessed

	pop	bx, ds
	ret
ImMethodButtonReceipt	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImMethodKbdCharReceipt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return reciept to IM of MSG_META_KBD_CHAR's having been received
		by the UI.  Used to keep track of whether the User has gotten
		ahead of the UI.
			
CALLED BY:	EXTERNAL

PASS:		cx, dx, bp	- MSG_META_KBD_CHAR event data

RETURN:

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
				
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	THIS ROUTINE DOES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	(INPUT_MESSAGE_RECEIPT)
ImMethodKbdCharReceipt	proc	far
	push	ax, ds
	mov	ax, segment idata
	mov	ds, ax

	test	dl, mask CF_RELEASE	; see if keyboard release or not
	jz	10$		; skip if not
	dec	ds:[kbdReleasesUnprocessed]	; if so, dec release flag
	jmp	short 50$
10$:
	dec	ds:[kbdPressesUnprocessed]	; if not, dec press flag
50$:
	pop	ax, ds
	ret
ImMethodKbdCharReceipt	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessUserInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Processes all user input before sending on to the focus.
			Sends events through input monitors
			Sums pointer position data
		

CALLED BY:	EXTERNAL

PASS:		ax 	- event type
		cx, dx, bp, si - event data
		ds, es 	- data segment
		ss:sp 	- stack frame of Input Manager

PASSED TO MON:
		al 		- MF_DATA
		di		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data
		ds		- segment of Monitor being called
		bx		- offset within segment to Monitor
		ss:sp 		- stack frame of Input Manager

RETURNED FROM MON:
		al		- flags about result:
					MF_DATA		= data returned
					MF_MORE_TO_DO	= more to come
		di		- event type
		cx, dx, bp, si 	- event data
		ss:sp		- unchanged
		ah, bx, ds, es	- trashed


RETURN:		Nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds, es

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Add MSG_GADGET_REPEAT_PRESS back in here if we want the
		gadget repeat timer to go through the IM queue again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	8/88		Initial version
	doug	11/88		Revised for object orientation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessUserInput	method	IMClass, MSG_IM_PTR_CHANGE, 
		MSG_IM_BUTTON_CHANGE, MSG_IM_KBD_SCAN, 
		MSG_IM_PRESSURE_CHANGE, MSG_IM_DIRECTION_CHANGE, 
		MSG_META_NOTIFY, MSG_META_NOTIFY_WITH_DATA_BLOCK,
		MSG_IM_INK_TIMEOUT,
		MSG_META_KBD_CHAR,
if INK_DIGITIZER_COORDS
		MSG_META_EXPOSED,
		MSG_IM_READ_DIGITIZER_COORDS
else
		MSG_META_EXPOSED
endif

;	(Handle MSG_META_KBD_CHAR to allow keycaps to work)

; INPUT PROCESSING

	mov	di, ax			; setup event type to pass

					; We need the monitor chain
	PSem	ds, semMonChain, TRASH_AX_BX
	mov	bx, offset headMonitor
PUI_HaveData:				; Have data here, pass to next
					;	monitor in line
					; Move up to next monitor
	lds	bx, ds:[bx].M_nextMonitor

CallMon:
	push	ds			; save pointer to current
	push	bx			; 	monitor
					; Set flag showing we're in
					;	monitor
	ornf	ds:[bx].M_flags, mask MF_IN_MONITOR
					
	push	bx
	push	ds
	mov	bx, segment idata
	mov	ds, bx
					; Relinquish the monitor chain
	FastVSem1	ds, semMonChain, SMCV1, SMCV2, TRASH_AX_BX
	pop	ds
	pop	bx
				; CALL INPUT MONITOR

	mov	al, mask MF_DATA		; set this to allow easy
					;	default on part of
					;	monitor if it isn't
					;	interested in data
EC <	push	es			; support for segment checking	>
	call	ds:[bx].M_monRoutine	; Call INPUT MONITOR
EC <	pop	es							>

EC <	test	al, not (mask MF_REMOVE_WHEN_EMPTY or mask MF_REMOVE_IMMEDIATE or mask MF_MORE_TO_DO or mask MF_DATA)	>
EC <	ERROR_NZ	IM_BAD_FLAGS_RETURNED_FROM_MONITOR	>

	push	ax
	mov	ax, segment idata
	mov	ds, ax
					; We need the monitor chain
	FastPSem1	ds, semMonChain, SMCP1, SMCP2, TRASH_AX_BX
	pop	ax
	pop	bx			; restore pointer to current
	pop	ds			;	monitor
	mov	ah, ds:[bx].M_flags	; get old flags
					; Clear out old data bits

	andnf	ah, not (mask MF_MORE_TO_DO or mask MF_DATA or mask MF_IN_MONITOR)
	or	al, ah			; OR w/new flags (This way, we'll
					; combine monitor's & RemoveMonitor's
					; idea of when to remove when empty)

	mov	ds:[bx].M_flags, al	; Store new data
					; SEE if testing for removal
	test	al, mask MF_REMOVE_IMMEDIATE or mask MF_REMOVE_WHEN_EMPTY
	jnz	CheckForRemoval	; if so, branch out & check

ProcessData:
	test	al, mask MF_DATA		; Did monitor return data?
	jnz	PUI_HaveData		; if returning w/data, pass on
Backup:
					; Backup to previous Monitor
	lds	bx, ds:[bx].M_prevMonitor
CheckForData:
					; see if back to head
	cmp	ds:[bx].M_monRoutine.segment, 0
	je	Complete		; if so, processing done
	test	ds:[bx].M_flags, mask MF_MORE_TO_DO	; see if more
						; to fetch
	jz	Backup		; if not, keep going back
	mov	di, 0			; Show no data, just resend
					;	request
	jnz	CallMon		; When data found, loop to send
Complete:
					; Relinquish the monitor chain
	push	ds
	mov	ax, segment idata
	mov	ds, ax
	VSem	ds, semMonChain, TRASH_AX_BX
	pop	ds
	ret

	FastVSem2	ds, semMonChain, SMCV1, SMCV2, TRASH_AX_BX
	FastPSem2	ds, semMonChain, SMCP1, SMCP2, TRASH_AX_BX


CheckForRemoval:
	test	al, mask MF_REMOVE_IMMEDIATE	; See if immediately
	jnz	PUI_Remove		; if so, remove
					; else must be REMOVE_WHEN_EMPTY
	test	al, mask MF_MORE_TO_DO	; more to do?
	jnz	ProcessData		; if so, go ahead & process it
PUI_Remove:					; ELSE REMOVE MONITOR!
	push	es
	push	di
	call	UnlinkMonitor		; Unlink it from chain
					; V semaphore to let ImRemoveMonitor
	VSem	ds, [bx].M_semMonitor
					;	return to its caller with
					;	monitor free.
	mov	bx, es			; Copy es:di to ds:bx (previous)
	mov	ds, bx
	mov	bx, di
	pop	di
	pop	es
	test	al, mask MF_DATA		; Did monitor return w/data?
	jz	CheckForData	; if not, check previous
	jmp	PUI_HaveData	; if so, call next monitor


ProcessUserInput	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImAddMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		ds:bx	- pointer to Monitor structure to use
		al	- Monitor processing LEVEL (see description at
			  top of file)
		cx	- segment of monitor routine
		dx	- offset of monitor routine

RETURN:		bx	- handle for process of User Input Manager

PASSED TO MONITOR:
		al 		- MF_DATA
		di		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data
		ds		- segment of Monitor being called
		bx		- offset within segment to Monitor
		ss:sp 		- stack frame of Input Manager

RETURNED FROM MONITOR:
		al		- flags about result:
					MF_DATA		= data returned
					MF_MORE_TO_DO	= more to come
		di		- event type
		cx, dx, bp, si 	- event data
		ss:sp		- unchanged
		ah, bx, ds, es	- trashed

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImAddMonitor	proc	far		; MUST BE RESIDENT FOR SysNotify
	push	si
	push	di
	push	es

	push	ds
	mov	di, segment idata
	mov	ds, di
	PSem	ds, semMonChain, idata		; We need the monitor chain
	pop	ds

EC <	push	ax							>
EC <	mov	ax, ds							>
EC <	segmov	es, dgroup, si						>
EC <	mov	di, offset headMonitor					>
EC <checkLoop:								>
EC <	cmp	di, bx							>
EC <	jne	nextMonitor						>
EC <	cmp	si, ax							>
EC <	ERROR_E	IM_MONITOR_ALREADY_IN_MONITOR_CHAIN			>
EC <nextMonitor:							>
EC <	les	di, es:[di].M_nextMonitor				>
EC <	mov	si, es							>
EC <	tst	si							>
EC <	jnz	checkLoop						>
EC <	pop	ax							>

				; INIT Monitor data
				; store monitor routine address
	mov	ds:[bx].M_monRoutine.segment, cx
	mov	ds:[bx].M_monRoutine.offset, dx
	mov	ds:[bx].M_priority, al	; store priority position
	mov	ds:[bx].M_flags, 0	; init flags to 0

					; Init semaphore value to 0
	mov	ds:[bx].M_semMonitor.Sem_value, 0

					; ADD additional monitor
					; Set es:di be pointer to Mon,
					;	start at head

	mov	di, segment idata
	mov	es, di
	mov	di, offset headMonitor
15$:
	cmp	al, es:[di].M_priority	; compare w/priority here
	jb	AM_20			; if lower, insert here, branch
					; else move up to next pointer
	mov	cx, es:[di].M_nextMonitor.high
	or	cx, cx			; see if null next ptr
	jz	AM_30			; if so, jmp & append here
	mov	di, es:[di].M_nextMonitor.low
	mov	es, cx
	jmp	short 15$		; loop & continue search
AM_20:					; INSERT here
					; Back Up one monitor
	les	di, es:[di].M_prevMonitor

AM_30:					; APPEND here
					; set cx:si = next ptr
	mov	cx, es:[di].M_nextMonitor.high
	mov	si, es:[di].M_nextMonitor.low
					; es:di is last monitor
					; ds:bx is new monitor
					; cx:si is next monitor
					; Tack new monitor onto end of
					;	one we're pointing at
	mov	es:[di].M_nextMonitor.high, ds
	mov	es:[di].M_nextMonitor.low, bx
					; Set prev ptr for new mon
	mov	ds:[bx].M_prevMonitor.high, es
	mov	ds:[bx].M_prevMonitor.low, di
					; Set next ptr for new mon
	mov	ds:[bx].M_nextMonitor.high, cx
	mov	ds:[bx].M_nextMonitor.low, si
	or	cx, cx			; see if there is a next monitor
	jz	Done			; if not, done
					; ds:bx is new monitor
	mov	es, cx			; es:si is next monitor
					; Set prev ptr for next mon
	mov	es:[si].M_prevMonitor.high, ds
	mov	es:[si].M_prevMonitor.low, bx
Done:
	push	ds
	mov	bx, segment idata
	mov	ds, bx
					; Relinquish the monitor chain
	VSem	ds, semMonChain, TRASH_AX_BX

	mov	bx, ds:[imThread]	; Put our thread id into bx
	pop	ds
	pop	es
	pop	di
	pop	si
	ret

ImAddMonitor	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImRemoveMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a monitor from the linked list after it returns
		from executing, or, optionally, after it has no more data
		to return.  NOTE:  This routine should never be called from
		within a Monitor.  Only the routine owning the block of
		memory that the Monitor resides in should call this routine.

CALLED BY:	EXTERNAL

PASS:		ds:bx	- pointer to Monitor structure to remove
		al	- flags for removal.  One of the below flags should
			  be set:

			  MF_REMOVE_WHEN_EMPTY	equ	80h
			  MF_REMOVE_IMMEDIATE	equ	40h

			  Remove when empty option will wait until Monitor
			  has no more data to return before removing.  Remove
			  immediate will remove it as soon as it is not
			  processing data.

			  Bits 5-0 - must be 0
				  

RETURN:		ds:bx	- Monitor unlinked, not executing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImRemoveMonitor	proc	far		; MUST BE RESIDENT FOR SysNotify
	push	cx
	push	dx
	push	di
	push	es
					; We need the monitor chain, first
	push	ds
	mov	di, segment idata
	mov	ds, di
	PSem	ds, semMonChain, idata
	pop	ds

	; See if running monitor code, or if monitor has more to process.
	; IF SO, then let monitor be removed by ProcessUserInput.

	; NOTE:  These two tests MUST be performed separately due to
	; timing w/ProcessUserInput running of monitors

					; (This bit can't change even if
					; running)
	test	ds:[bx].M_flags, mask MF_IN_MONITOR
	jnz	RemoveLater		; if set, then remove later

					; if not in monitor, see if it
					; has more data to return
	test	ds:[bx].M_flags, mask MF_MORE_TO_DO
	jnz	RemoveLater		; if set, then remove later

	call	UnlinkMonitor		; Unlink it NOW.

					; Relinquish the monitor chain,
					; so ProcessUserInput can continue
	call	RelinquishMonitorChain
	jmp	short Done

RemoveLater:
					; Set flags to show removal has
					; been requested
	or	ds:[bx].M_flags, al

					; Relinquish the monitor chain,
					; so ProcessUserInput can continue
	call	RelinquishMonitorChain

					; & Block until monitor has been

	PSem	ds, [bx].M_semMonitor
Done:
	pop	es
	pop	di
	pop	dx
	pop	cx
	ret				; unlinked.

ImRemoveMonitor	endp


RelinquishMonitorChain	proc	near
	push	bx
	push	ds
	mov	bx, segment idata
	mov	ds, bx
					; Relinquish the monitor chain
	VSem	ds, semMonChain, TRASH_AX_BX
	pop	ds
	pop	bx
	ret

RelinquishMonitorChain	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlinkMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes monitor from Monitor double-linked list

CALLED BY:	ImRemoveMonitor, ProcessUserInput

PASS:		ds:bx	- pointer to monitor to unlink

RETURN:		ds:bx	- monitor unlinked
		es:di	- pointer to previous monitor
		Monitor list updated to remove monitor

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine may NOT be used to remove the header monitor.
		This allows us to assume that for any monitor being removed,
		the previous monitor linkage is correct.  The LAST monitor
		may be removed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version
	Doug	2/89		Fixed bug when removing last monitor

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnlinkMonitor	proc	far
	push	ds			; preserve ds
	push	si			; & si
					; set es:di to previous mon
	les	di, ds:[bx].M_prevMonitor
					; set ds:si to next mon
	lds	si, ds:[bx].M_nextMonitor


					; Link elements together
	mov	ax, es			; if there was no next monitor,
	or	ax, ax			;	can't update it's linkage.
	jz	50$			; so skip doing so.
	mov	es:[di].M_nextMonitor.high, ds
	mov	es:[di].M_nextMonitor.low, si
50$:	
					; We can always update the previous
					;	monitor's linkage.
	mov	ds:[si].M_prevMonitor.high, es
	mov	ds:[si].M_prevMonitor.low, di
	pop	si
	pop	ds
	ret

UnlinkMonitor	endp
		




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MONITORS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombineInputMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LEVEL 40 user input processing

		- INPUT COMBINATION.  Example: PTR CHANGE, BUTTON CHANGE,
		  DIRECTION & PRESSURE CHANGE events are "summed", to yield
		  the final versions of these events.  Input devices could
		  be mapped to other devices at this point (an
		  IM_MSG_PTR_CHANGE for the 2nd pointing device could be
		  mapped to be an MSG_PTR_2 type).  Determines whether
		  double-click has occurred

		  MSG_IM_PTR_CHANGE			MSG_META_MOUSE_PTR
		  MSG_IM_PRESSURE_CHANGE   ->		MSG_META_PRESSURE
		  MSG_IM_DIRECTION_CHANGE 		MSG_META_DIRECTION
		  MSG_IM_BUTTON_CHANGE			MSG_META_MOUSE_BUTTON

CALLED BY:	User Input Manager (As a Monitor)

PASSED TO MON:
		al 		- MF_DATA
		di 		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data
		ss:sp 		- stack frame of Input Manager


RETURN:		AL = MF_DATA, indicating data being returned
		di 		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data

		AL may return 0 if CONSUME_INPUT_IF_SCREEN_SAVER_ACTIVE.
		On responder, we need to discard input that unblanks the
		screen, so we just return 0 here to do that if screen
		was actually unblanked in MaybeUnblankScreens.

DESTROYED:	

PSEUDO CODE/STRATEGY:


	Ouput from pointing device drivers:
	-----------------------------------

		di	- MSG_IM_PTR_CHANGE
		cx	- mouse X position
		dx	- mouse Y position
		bp	- <yPosInfo><xPosInfo>
				?PosInfo:  Bit    7 = set if abs pos
		si	- driver handle


		di	- MSG_IM_BUTTON_CHANGE
		cx	- timestamp LO
		dx	- timestamp HI
		bp	- <0><buttonInfo>
			   buttonInfo:
				Bit     7 = set for press, clear for release
				Bits  1-0 = button #
		si	- driver handle

		

	Events sent to applications from UI:
	-----------------------------------

		di	- MSG_META_MOUSE_PTR
		cx	- mouse X position
		dx	- mouse Y position
		bp	- <shiftState><buttonInfo>
			   buttonInfo:
				Bits 5-2 = state of buttons 3-0
		si	- driver handle

		NOTES:		Position is relative to upper left hand corner
				of window that event is being sent to. If
				mouse movements occur faster than the 
				application can read them, consecutive
				WM_MOUSE_MOVE/WM_PRESSURE_CHANGE/
				WM_DIRECTION_CHANGE events will
				be reduced to the most recent event of each.



		di	- MSG_META_MOUSE_BUTTON
		cx	- mouseXPos
		dx	- mouseYPos
		bp	- <shiftState><buttonInfo>
			   buttonInfo:
				Bit    7 = set for press, clear for relase
				Bit    6 = set for doublepress
				Bits 5-2 = state of buttons 3-0
				Bits 1-0 = button # changing
		si	- window handle


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CombineInputMonitor	proc	far
	mov	ax, segment idata
	mov	ds, ax
if CONSUME_INPUT_IF_SCREEN_SAVER_ACTIVE
	;
	; by default, this routine is supposed to return mask MF_DATA in AL
	;
	mov	ds:returnMonitorFlag, mask MF_DATA	; a byte data
endif
					; Sum pointer data
	cmp	di, MSG_IM_PTR_CHANGE
	je	CIM_Ptr

	call	MaybeUnblankScreens	; for anything else, unblank the
					;  screens regardless of the contents
					;  of the event
if CONSUME_INPUT_IF_SCREEN_SAVER_ACTIVE
	;
	; on responder, input that unblanks the screen is to be ignored.
	; our cunning plan is to make this routine return 0 in AL so that
	; the input is ignored in that case. -SJ
	;
	jc	screenOn1		; screen was already on, return input
	clr	ds:returnMonitorFlag	; screen just unblanked, consume input
screenOn1:
endif
	cmp	di, MSG_IM_BUTTON_CHANGE
	je	CIM_Button
	cmp	di, MSG_META_KBD_CHAR
	je	CIM_Kbd

	tst	ds:[delayedRelease]
	jz	Nothing			;if no delayed release 
						;event to send

	mov	cx,ds:[delayedReleaseEvent].HE_cx	;restore data
	mov	dx,ds:[delayedReleaseEvent].HE_dx
	mov	bp,ds:[delayedReleaseEvent].HE_bp
	mov	si,ds:[delayedReleaseEvent].HE_OD.chunk
	mov	ds:[delayedRelease],0			;clear flag
	jmp	short CIM_Button			;do button

Nothing:
if CONSUME_INPUT_IF_SCREEN_SAVER_ACTIVE
	mov	al, ds:returnMonitorFlag
else
	mov	al, mask MF_DATA	; Return w/data
endif					; if none of the above, done
	ret

CIM_Button:				; BUTTON change
	call	ProcessButton
	jc	ButtonRet		;jmp if al already set
		
if CONSUME_INPUT_IF_SCREEN_SAVER_ACTIVE
	mov	al, ds:returnMonitorFlag ;we dont care about dragging and stuff
else					 ;above
	mov	al, mask MF_DATA ; Return w/data
endif

ButtonRet:
	ret

CIM_Kbd:				; KEYBOARD CHAR
	call	ProcessKbd

if CONSUME_INPUT_IF_SCREEN_SAVER_ACTIVE
	mov	al, ds:returnMonitorFlag
else
	mov	al, mask MF_DATA	; Return w/data
endif
	ret

CIM_Ptr:				; POINTER change

; SCREEN SAVER STUFF
; Move to COMBINE level to give screen saver a chance to consume it and
; thereby prevent wakeup.

					; There appears to be a real, live
					; user out there.  Let's kick off
					; the screen saver if true...

					; Test for "null" movement, which
					;  means it's something done by
					;  the program, not the user, so
					;  we shouldn't mess with the
					;  screen saver.
	push	cx
	push	dx
			; cx - x mouse pos
			; dx - y mouse pos
			; bp - flags for abs/relative
	test	bp, mask PI_absX
	jz	xRel
	sub	cx, ds:[pointerXPos]	; subtract off last position
xRel:
	test	bp, mask PI_absY
	jz	yRel
	sub	dx, ds:[pointerYPos]	; subtract off last position
yRel:
	or	cx, dx			; See if both zero...
	pop	dx
	pop	cx
	jz	continueAfterScreenSaver; if so, skip nudge.

	call	MaybeUnblankScreens	; carry set if screen saver is deactive

continueAfterScreenSaver:

			; cx - x mouse pos
			; dx - y mouse pos
			; bp - flags for abs/relative
			; si - driver handle
					; see if x is absolute
	clr	ds:[changeXPos]
	clr	ds:[changeYPos]
	test	bp, mask PI_absX
	jnz	P10
	mov	ds:[changeXPos], cx	; save the relative change
	add	cx, ds:[pointerXPos]	; add in relative amount
P10:
	mov	ds:[pointerXPos], cx	; store absolute amount

					; see if y is absolute
	test	bp, mask PI_absY
	jnz	P30
	mov	ds:[changeYPos], dx	; save the relative change
	add	dx, ds:[pointerYPos]	; add in relative amount
P30:
	mov	ds:[pointerYPos], dx	; store absolute amount

	mov	ds:[displayXPos], cx	; Store result to display pos
	mov	ds:[displayYPos], dx


	test	ds:[dragState], mask BI_B0_DOWN or mask BI_B1_DOWN or mask BI_B2_DOWN or mask BI_B3_DOWN
	jnz	P100		;jmp if potential drags happening
	

CMI_P50:				; Change event type to reflect
					;	changes
	mov	di, MSG_META_MOUSE_PTR
	mov	al, mask MF_DATA		; Return w/data
	mov	bl, ds:[buttonState]	; show state of all buttons
P60:
	mov	bh, ds:[shiftState]	; & state of keyboard
	mov	bp, bx			; put into bp	
	;
	; Even if CONSUME_INPUT_IF_SCREEN_SAVER_ACTIVE,
	; we don't need to worry about consuming pointer event.
	;
	ret

P100:
	clr	al			;pass button 0
	call	SetDragEventIfNecessary
	jc	P60			;jmp if need to send DRAG

	mov	al,1			;pass button 1
	call	SetDragEventIfNecessary
	jc	P60			;jmp if need to send DRAG

	mov	al,2			;pass button 2
	call	SetDragEventIfNecessary
	jc	P60			;jmp if need to send DRAG

	mov	al,3			;pass button 3
	call	SetDragEventIfNecessary
	jnc	CMI_P50			;jmp to send MSG_META_MOUSE_PTR
	jmp	P60			;jmp to send DRAG

CombineInputMonitor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaybeUnblankScreens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unblank the screens if they're currently blanked

CALLED BY:	CombineInputMonitor
PASS:		ds	= dgroup
RETURN:		carry set if screen was already on
		carry clr if screen was just turned on
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MaybeUnblankScreens proc	near
	uses	ax
	.enter

	movdw	ds:[sysCounterAtLastInput], ds:[systemCounter], ax

	mov	ax, ds:[screenSaver].SS_maxCount	; get current count
	xchg	ax, ds:[screenSaver].SS_curCount	; reset, get old count
		
;	tst	ax					; if 0, then restart
;	jne	done

	test	ds:[screenSaver].SS_state, mask SSS_ACTIVE
	stc	
	jz	done

	call	UnBlankScreens				; Wake up!

					; mark as not active
	and	ds:[screenSaver].SS_state, not mask SSS_ACTIVE
	clc
done:
	.leave
	ret
MaybeUnblankScreens endp



ProcessButton	proc	near
			; cx - timer low
			; dx - timer high
			; bp - <0> <button info>
			; si - driver handle
	tst	ds:[leftHanded]
	jz	getButtonMask
	test	bp, 1 shl offset BI_BUTTON	; BUTTON_1/BUTTON_3?
	jnz	getButtonMask			; yes -- do nothing
	xornf	bp, 2 shl offset BI_BUTTON ; convert #2 into #0 and vice-versa.
					;  XXX: this doesn't do the right thing
					;  for a four-button mouse, but...

getButtonMask:
	mov	ax, bp			; copy from bp
	and	al, mask BI_BUTTON	; clear all but button #
	mov	bx, offset buttonConvTab
	xlatb				; convert to bitplace
	test	bp, mask BI_PRESS	; see if PRESS
	jnz	PB_5			; branch if press
	call	CheckForLostDrag
	LONG jc	PB_ret
	not	al			; complment to get AND mask
	and	ds:[buttonState], al	; clear bit, for release
	and	ds:[dragState],al	; clear drag bit for release
	jmp	short 50$		; skip to handle rest of release

PB_5:			; PRESS
	or	ds:[buttonState], al	; change to show press
	or	ds:[dragState],al

	mov	bx, bp			; copy into bx
	and	bx, mask BI_BUTTON	; clear all but button #
	shl	bx, 1			; * 2
	mov	bx, ds:[bx].bpsTable	; lookup entry for button in
					;	buttonPressStatus

			;START DRAG TIMER
	push	bx,cx,si
	mov	ax,TIMER_ROUTINE_ONE_SHOT
	mov	bx,segment ImForcePtrMethod
	mov	si,offset ImForcePtrMethod
	mov	cx,ds:[dragTime]
	call	TimerStart
	pop	bx,cx,si

					; Test for double-click here
					; First determine time period
					;	between clicks
					; t_now - t_then
	push	cx			; save orig values
	push	dx
	sub	cx, ds:[bx].BPS_pressTime.low    ; - t_then
	sbb	dx, ds:[bx].BPS_pressTime.high    ; - t_then
					; Update buttonPressInfo struct
	pop	ds:[bx].BPS_pressTime.high
	pop	ds:[bx].BPS_pressTime.low

	jnz	NoDouble		; if >10000h, no double
	cmp	cx, ds:[doubleClickTime]; see if within time req'ment
	ja	NoDouble		; if too big, no double click

					; NOW test movement
	mov	ax, ds:[bx].BPS_pressXPos	; get old position
	sub	ax, ds:[displayXPos]		; subtract new
	jns	10$
	neg	ax
10$:
	cmp	ax, ds:[doubleClickDistance]
	ja	NoDouble
	mov	ax, ds:[bx].BPS_pressYPos	; get old position
	sub	ax, ds:[displayYPos]		; subtract new
	jns	20$
	neg	ax
20$:
	cmp	ax, ds:[doubleClickDistance]
	ja	NoDouble
				; YES! a double-click
					; set double-click flag
	or	bp, mask BI_DOUBLE_PRESS
NoDouble:
				; Store press location in button struct
	mov	ax, ds:[displayXPos]
	mov	ds:[bx].BPS_pressXPos, ax
	mov	ax, ds:[displayYPos]
	mov	ds:[bx].BPS_pressYPos, ax
50$:
	mov	ax, bp
	or	al, ds:[buttonState]	; show state of all buttons
	mov	ah, ds:[shiftState]	; get shiftState
	mov	bp, ax
					; Change event tyee
	mov	di, MSG_META_MOUSE_BUTTON
	clc				;tell CombineInputMonitor to set al
PB_ret:
	mov	cx, ds:[displayXPos]	; Fetch pointer display pos
	mov	dx, ds:[displayYPos]
	ret

ProcessButton	endp


ProcessKbd	proc	near
ifdef	SYSTEM_SHUTDOWN_CHAR
;NOTE Hack to allow abort on ALT-CTRL-DEL.  We'll have to handle this better
;NOTE later, so that things can shut down.
; {
					; See if system RESET desired
	test	dl, mask CF_RELEASE
	jnz	20$

SBCS <	cmp	cx, (CS_CONTROL shl 8) or SYSTEM_SHUTDOWN_CHAR          >
DBCS <	cmp	cx, SYSTEM_SHUTDOWN_CHAR          			>

	jne	20$
	mov	ax, SST_REBOOT		; assume reboot
	tst	ds:[rebootOnReset]
	jnz	doShutdown		; yup

	mov	si, -1			; No message
	mov	ax, SST_DIRTY		;Assume this is the second reset.
	tst	ds:[alreadyReset]	;If so, do a dirty shutdown
	jnz	doShutdown
	mov	ds:[alreadyReset], TRUE

	mov	ax,SST_CLEAN_FORCED	; Force applications to shutdown
	
doShutdown:
	push	cx, dx, bp
	call	SysShutdown		; destroys everything but ds,es,si,di
	pop	cx, dx, bp
20$:
; }
endif	; SYSTEM_SHUTDOWN_CHAR
	test	dl, mask CF_STATE_KEY		; see if state key
	jz	Done			; if not, skip

	push	cx, dx, bp, si, di, es
	mov	di, DR_KBD_GET_KBD_STATE	; Let's find out new state
	call	ds:[kbdStrategy]		; call kbd strategy routine
	pop	cx, dx, bp, si, di, es
					; returns al = kbdShiftState
	mov	ds:[shiftState], al		; store locally
Done:
	ret

ProcessKbd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDragEventIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if a drag event needs to be sent for a given
		button.

CALLED BY:	INTERNAL
		CombineInputMonitor

PASS:		
	al - low 2 bits are button number, rest clear
	bp - time of current IM_PTR_CHANGE event
	ds - segment of idata
		ds:[displayXPos] position of current event
		ds:[displayYPos] position of current event
		ds:[dragState]
RETURN:		
	clc - event should not be sent

	stc - send that baby
		di - MSG_META_MOUSE_DRAG
		al - mask MF_DATA
		bl - button info
		bit for button is cleared in ds:[dragState]		

	don't destroy cx,dx,bp
	
DESTROYED:	
	ah,bx


PSEUDO CODE/STRATEGY:
	A drag event for a button should only be sent if	
	the corresponding bit in dragState is set and one of the following 
	is true.

	The distance between the button press and the position of this
	IM_PTR_CHANGE event is greater than ds:[dragDistance]

				OR

	The time elapsed between the pressing of the button and sending
	of this IM_PTR_CHANGE event is greater than ds:[dragTime]

	The time stored is only the low 14 bits of the time counter at the
	time the IM_PTR_CHANGE event is sent. This value doesn't wrap for
	over 4 minutes, so that shouldn't be a problem. But to calc the
	difference we must do the following.

		if ptr event time => press time
			diff = ptr event time - press time
		else
			diff = (ptr event time + (2^14) - 1 ) - press time

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDragEventIfNecessary	proc	near
	uses	bp,cx
	.enter
	mov	ah,al			;save button number in low 2 bits of ah
	mov	bx,offset buttonConvTab
	xlatb				;convert button # to bit place

	test	ds:[dragState],al
	jz	40$			;jmp if dragState not set for button

	clr	bh
	mov	bl,ah			;button number
	shl	bx,1			
	mov	bx,ds:[bx].bpsTable	;offset to button structure

		;CHECK DISTANCE

	mov	cx,ds:[displayXPos]
	sub	cx,ds:[bx].BPS_pressXPos ;cur pos - press pos
	tst	cx			;force difference to be positive
	jns	10$
	neg	cx
10$:
	cmp	cx,ds:[dragDistance]	;cmp difference to max
	ja	send			;jmp if difference beyond max

	mov	cx,ds:[displayYPos]
	sub	cx,ds:[bx].BPS_pressYPos;cur pos - press pos
	tst	cx			;for difference to be positive
	jns	20$
	neg	cx
20$:
	cmp	cx,ds:[dragDistance]	;cmp difference to max
	ja	send			;jmp if diff beyond max

		;CHECK TIME

	andnf	bp, mask PI_time 		;only the time
	mov	cx,ds:[bx].BPS_pressTime.low
	andnf	cx, mask PI_time		;same number of time bits
	cmp	bp,cx				;see comment in header
	jge	30$
	add	bp,16383		;16383 = (2^14)-1
30$:
	sub	bp,cx
	cmp	bp,ds:[dragTime]
	jnb	send
40$:
	clc				;no need to send
done:
	.leave
	ret

send:
	not	al			;not the of mask of button bit
	andnf	ds:[dragState],al	;unarm drag on button
	mov	di,MSG_META_MOUSE_DRAG
	mov	al, mask MF_DATA
	mov	bl,ah			;button number
	or	bl,ds:[buttonState]	;return button info in bl
	stc				;send that baby
	jmp	done

SetDragEventIfNecessary		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForLostDrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if we need to send a drag event before we send
		the release event.

CALLED BY:	INTERNAL
		ProcessButton

PASS:		
	bp - button info
	cx - low word of time of button event
	ds - segment of dgroup
		ds:[displayXPos] position of current button event
		ds:[displayYPos] position of current button event
		ds:[dragState]
		
RETURN:		
	clc - no lost drag

	stc - send a lost drag
		di - MSG_META_MOUSE_DRAG
		al - mask MF_MORE_TO_DO
		bp - button info
		bit for button is cleared in ds:[dragState]		
		ds:[delayedRelease] - 1
		ds:[delayedReleaseEvent] - delayed event data
DESTROYED:	
	nothing

PSEUDO CODE/STRATEGY:
	Consider this:
	The user clicks, moves less than the dragDistance but keeps the
	button pressed for at least the dragTime and then releases. 
	However, the input manager is backlogged and doesn`t start 
	processing the button press until after the user has released.
	Since the dragDistance wasn't violated we are depending upon the
	timer started when processing the button press to send us a ptr
	event after the dragTime has passed. But since the release has
	already happened, it will be in the queue before the timer 
	generated ptr event. And if the button is released we don't send
	a drag event when the ptr event comes in. Got it. So, upon the
	release we check and see if we need to send the drag event 
	before the release event. If so, we save the release event data, 
	send of the drag event and tell the monitor chain to come back
	to us so we can then send the release event. Yeah.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	of course not

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForLostDrag		proc	near
	push	bx,ax,bp
	mov	ax,bp
	and	al, mask BI_BUTTON	;clear all but button #
	mov	bp,cx			;low word of time
	call	SetDragEventIfNecessary	
	pop	ax,bp
	jnc	done
	mov	ds:[delayedRelease],1	;flag that one has been delayed
	mov	ds:[delayedReleaseEvent].HE_cx,cx
	mov	ds:[delayedReleaseEvent].HE_dx,dx
	mov	ds:[delayedReleaseEvent].HE_bp,bp
	mov	ds:[delayedReleaseEvent].HE_OD.chunk,si
	mov	bh,ds:[shiftState]
	mov	bp,bx
	mov	al,mask MF_MORE_TO_DO or mask MF_DATA
done:
	pop	bx
	ret
CheckForLostDrag		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    		PtrPerturbMonitor	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PTR is made to perform snap/ratchet operations, and/or 
		confined to some region (rectangle only?)

CALLED BY:	ProcessUserInput

PASS:		
		al 		- MF_DATA
		di 		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data
		ss:sp 		- stack frame of Input Manager

RETURN:		
		al 		- MF_DATA, indicating data being returned
		di 		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data

DESTROYED:	?

PSEUDO CODE/STRATEGY:
		If (mouse is constrained) && 
		   (mousePos = outside constraining box) then
		    Move x pos within constraints;
		    Move y pos within constraints;
		    drawnPosition = mousePosition;
		    Send MSG_META_LEAVE_CONSTRAIN;
		Else if (mouse is ratcheted) &&
			(mouse is within snap distance of a ratchet) then
		    Move x pos to ratchet (if applicable);
		    Move y pos to ratchet (if applicable);
		Else
		    Do nothing;
		    
KNOWN BUGS/SIDE EFFECTS/IDEAS:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PtrPerturbMonitor	proc	far
	push	ax
	mov	ax, segment idata
	mov	ds, ax
	pop	ax

	cmp	di, MSG_META_MOUSE_PTR
	jne	90$			; If not ptr pos, skip
	test	ds:[constrainFlags], mask CF_CONSTRAINING
	jz	90$			; If not constraining, skip
	clr	ax
	cmp	cx, ds:[constrainXMin]	; If constraining, check if mouse is
	jge	10$		 	;    outside of the constraining box
	mov	cx, ds:[constrainXMin]	;    If so, then move it to the border
	or	ax, PTR_LEAVE_LEFT
10$:
	cmp	cx, ds:[constrainXMax]
	jle	20$		 	
	mov	cx, ds:[constrainXMax]
	or	ax, PTR_LEAVE_RIGHT
20$:
	mov	ds:[pointerXPos], cx	
	cmp	dx, ds:[constrainYMin]
	jge	30$		 	
	mov	dx, ds:[constrainYMin]
	or	ax, PTR_LEAVE_TOP
30$:
	cmp	dx, ds:[constrainYMax]
	jle	40$		 	
	mov	dx, ds:[constrainYMax]
	or	ax, PTR_LEAVE_BOTTOM
40$:
	mov	ds:[pointerYPos], dx	
	cmp	ax, 0				; Check if ptr tried to leave
	jz	90$				;   constrain
	cmp	ds:[constrainOD].handle, 0	; If OD=0, don't send anything
	jz	90$
	push	bx, cx, dx, bp, si, di		; Save mouse info & event
	mov	bx, ds:[constrainOD].handle
	mov	si, ds:[constrainOD].chunk	; Get constrain OD
	mov	cx, ax				; Pass which edge its leaving
	mov	ax, MSG_META_LEAVE_CONSTRAIN	; Send LEAVE_CONSTRAIN message
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bx, cx, dx, bp, si, di
90$:
	mov	al, mask MF_DATA		; return something!
	ret
PtrPerturbMonitor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LEVEL 100 user input processing. Unloads result of input
		chain to whatever process has set itself up to receive
		the output of the IM (Should be the UI).

		- INPUT DATA SENT TO OUTPUT PROCESS

CALLED BY:

PASS:		al 		- MF_DATA
		di 		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data
		ss:sp 		- stack frame of Input Manager



RETURN:		AL = 0, indicating no more to come, & Nothing being returned
		es unchanged

PSEUDO CODE/STRATEGY:
		If MSG_META_MOUSE_PTR {
			Limit ptr to screen limits
			If ptr has moved from last drawn position {
				store new drawn position vars;
				move ptr;
			}
			If grab not requesting ptr movement, don't pass on to
				next monitor;
			Send event to outputProcess using custom combine 
				routine to compress PTR data;
		} elsif MSG_META_MOUSE_BUTTON {
			Increment # of unprocessed events regarding this button
		} else send EVENT to outputProcess;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


OutputMonitor	proc	far
	push	ax
	mov	ax, segment idata
	mov	ds, ax
	pop	ax

EC <	cmp	di, MSG_META_EXPOSED					>
EC <	ERROR_E	MSG_META_EXPOSED_NOT_HANDLED_ON_INPUT_MANAGER_THREAD	>
	cmp	di, MSG_META_MOUSE_PTR
	je	OutputPtr			; PROCESS PTR EVENTS HERE
	GOTO	OutputNonPtr		; SEND ALL OTHER EVENTS TO
						; OutputNonPtr

				; ADJUST PTR TO PTR LIMITS
CMI_PL_10:
	sub	cx, ds:[screenXMin]
	sub	ds:[changeXPos], cx
	mov	cx, ds:[screenXMin]
	mov	ds:[pointerXPos], cx	; Store back to ptr pos
	jmp	short P110
CMI_PL_20:
	sub	cx, ds:[screenXMax]
	sub	ds:[changeXPos], cx
	mov	cx, ds:[screenXMax]
	mov	ds:[pointerXPos], cx	; Store back to ptr pos
	jmp	short P120
CMI_PL_30:
	sub	dx, ds:[screenYMin]
	sub	ds:[changeYPos], dx
	mov	dx, ds:[screenYMin]
	mov	ds:[pointerYPos], dx
	jmp	short P130
CMI_PL_40:
	sub	dx, ds:[screenYMax]
	sub	ds:[changeYPos], dx
	mov	dx, ds:[screenYMax]
	mov	ds:[pointerYPos], dx
	jmp	short P140

OutputPtr:
if	(QUIET_PTR_SUPPORT)
				; Ptr event, not yet sent to UI
	or	ds:[ptrOptFlags], mask POF_UNSENT
endif


				; LIMIT PTR TO SCREEN LIMITS

	cmp	cx, ds:[screenXMin]
	jl	CMI_PL_10
P110:
	cmp	cx, ds:[screenXMax]
	jg	CMI_PL_20
P120:
	cmp	dx, ds:[screenYMin]
	jl	CMI_PL_30
P130:
	cmp	dx, ds:[screenYMax]
	jg	CMI_PL_40
P140:

				; UPDATE ANY SCREEN XOR

	test	ds:[screenXorState], mask SXS_IN_MOVE_RESIZE
	jz	AfterScreenXor
	call	OutputUpdateScreenXor
	mov	ds:[pointerXPos], cx	; update pointer x & y position
	mov	ds:[pointerYPos], dx	; (may have changed)
	
AfterScreenXor:

				; UPDATE PTR IMAGE

					; cx, dx are current display position
	cmp	cx, ds:[drawnXPos]
	jne	DrawPtr			; If change, update ptr image
	cmp	dx, ds:[drawnYPos]
	je	AfterPtrDrawn		; If no change at all, done
DrawPtr:

	mov	ds:[drawnXPos], cx	; update last drawn position vars
	mov	ds:[drawnYPos], dx
	mov	ax, cx
	mov	bx, dx
	call	CallMovePtr		; move ptr on screen, via video driver
	mov	bx, ds:[pointerWin]	; get root window pointer is on
	call	WinMovePtr		; call window routine for enter/leave

AfterPtrDrawn:

if	(QUIET_PTR_SUPPORT)
				; DECIDE WHETHER TO SEND PTR EVENT

				; see if in mode of always sending mouse
	test	ds:[mouseMode], mask PM_ON_ENTER_LEAVE
	jz	SendPtr		; if so, branch to send it.

				; see if new position causes enter/leave
	call	TestForPtrChange
	jc	SendPtr		; if so, send

				; see if we should go ahead & send anyway
	test	ds:[ptrOptFlags], mask POF_SEND_NEXT
	jz	OutputDone	; if not, then don't send - save the poor
				; 	UI from unecessary PTR events
SendPtr:
				; Change flags to show up to date, any
				; "send next" requests fulfilled
	and	ds:[ptrOptFlags], not (mask POF_UNSENT or mask POF_SEND_NEXT)
endif
				; Store last sent ptr position
	mov	ds:[lastSentXPos], cx
	mov	ds:[lastSentYPos], dx

				; SEND EVENT FOR PTR

	push	cs		;push custom vector on stack
	mov	ax, offset IMResident:CombineMouseEvent
	push	ax
				; Get output OD
	mov	ax, di
	mov	bx, ds:[outputOD.handle]
	mov	si, ds:[outputOD.chunk]
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE or \
			mask MF_CUSTOM or mask MF_CAN_DISCARD_IF_DESPERATE \
			or mask MF_CHECK_LAST_ONLY
	call	ObjMessage		; off she goes...
	mov	di,ax
OutputDone::
	clr	al		; NOTHING MORE TO COME
	ret

OutputMonitor	endp


;
; Custom combination routine for ptr events, called by ObjMessage in
; OutputMonitor above.
;
CombineMouseEvent	proc	far
	cmp	ds:[bx].HE_method, MSG_META_MOUSE_PTR
	jne	cantUpdate

	cmp	ds:[bx].HE_bp, bp	; same button info?
	jne	cantUpdate		; nope, can't combine!

	mov	ds:[bx].HE_cx, cx	; update event
	mov	ds:[bx].HE_dx, dx	; update event
	mov	di, PROC_SE_EXIT	; show we're done
	ret

cantUpdate:
	mov	di, PROC_SE_STORE_AT_BACK	; just put at the back.
	ret
CombineMouseEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputNonPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	OutputMonitor for non-ptr events.

CALLED BY:

PASS:		al 		- MF_DATA
		di 		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data
		ss:sp 		- stack frame of Input Manager



RETURN:		AL = 0, indicating no more to come, & Nothing being returned
		es unchanged

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OutputNonPtr	proc	far
	class	IMClass
					; Check for button method
	cmp	di, MSG_META_MOUSE_BUTTON	; requires special handling
	je	handleButton
					; Or keyboard method
	cmp	di, MSG_META_KBD_CHAR	; requires special handling
	je	handleKbd

	cmp	di, MSG_IM_INK_TIMEOUT	;If this is an Ink timeout method,
	LONG je	exit			; it must've come in after the UI has
					; exited from pen mode.

					; else handle other non-ptr
	clr	bx			; can't discard if desperate
	clr	si			; nothing to inc to show partially
					; 	processed.
	jmp	SendNonPtr		; send it!


handleKbd:
					; Before sending any kbd events,
					; make sure UI will have correct
					; implied window
	call	WinEnsureChangeNotification

	;***** HACK
	;	If this is a repeat press and if there are few handles left
	;	then drop it

	test	dl, mask CF_REPEAT_PRESS
	jz	10$
	cmp	ds:[loaderVars].KLV_handleFreeCount,
					REPEAT_PRESS_HANDLE_THRESHHOLD
	LONG jb	afterSend
10$:

	; We don't want to discard first presses, since that would prevent
	; users from doing anything (like quitting an app) on a keyboard only
	; system once we get the "Low on handles" SysNotify. - Joon (7/12/94)

if	SINGLE_STEP_PROFILING
	test	dl, mask CF_RELEASE
	jz	continue
	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	continue
	cmp	cl, 'a'
	jz	startIt
	cmp	cl, 'A'
	jnz	tryStop
startIt:
	call	StartSingleStepping
	jmp	continue
tryStop:
	cmp	cl, 'z'
	jz	stopIt
	cmp	cl, 'Z'
	jnz	continue
stopIt:
	call	StopSingleStepping
continue:
endif
	clr	bx
					; Allow discarding if desparate
;	mov	bx, mask MF_CAN_DISCARD_IF_DESPERATE

if	(INPUT_MESSAGE_RECEIPT)
	test	dl, mask CF_RELEASE	; see if keyboard release or not
	jz	kbdPress		; skip if not
	mov	si, offset kbdReleasesUnprocessed ; if so, inc release flag
	jmp	SendNonPtr
kbdPress:
	mov	si, offset kbdPressesUnprocessed ; if so, inc press flag
endif
	jmp	SendNonPtr

handleButton:
					; Before sending any button events,
					; make sure UI will have correct
					; implied window
	call	WinEnsureChangeNotification
	; Inc # of unprocessed events regarding this button.  Every time
	; a button event leaves the IM, we inc the variable for this button.
	; The UI, when it receives button events, calls ImButtonReceipt to
	; acknowledge reciept of the button, which decrements the value.  This
	; way we can keep track of whether or not there are unprocessed events
	; for a particular button.

	mov	bx, bp			; copy into bx
	and	bx, mask BI_BUTTON	; clear all but button #
	shl	bx, 1			; * 2
	mov	bx, ds:[bx].bpsTable	; lookup entry for button in
					;	buttonPressStatus

if	(INPUT_MESSAGE_RECEIPT)
	mov	si, bx			; setup ds:si to be variable ito inc
	add	si, offset BPS_unprocessed
	push	si			; preserve this offset
endif

	; Stop constraining if terminating button has changed

	test	ds:[constrainFlags], mask CF_CONSTRAINING
	jz	80$			; skip if not constraining
	mov	ax, bp
	and	al, mask BI_BUTTON
	mov	bx, offset buttonConvTab
	xlatb				; convert to bitplace
					; see if we should end constrain
					; on that change
	test	ax, ds:[constrainButtonFlags]
	jz	80$			; skip if not
					; If so, end constrain.
	and	ds:[constrainFlags], not mask CF_CONSTRAINING
80$:

	; Now check for XOR stuff

	test	ds:[screenXorState], mask SXS_IN_MOVE_RESIZE
	jz	noXor
	push	bp			; CHECK XOR END: Save the button state
	test	ds:[xorBoxFlag], mask XF_NO_END_MATCH_ACTION
	jnz	109$			; no end match action, continue
	test	ds:[xorBoxFlag], mask XF_END_MATCH_ACTION
	jz	100$			; Check the nature of the end condition
	and	bp, mask BI_PRESS or mask BI_DOUBLE_PRESS or mask BI_BUTTON
					; Match action: get just button chg info
					; See if this matches the xor end cond
	xor	bp, word ptr ds:[xorButtonFlag]
	jnz	109$			;    If not, continue
	jmp	short ONP_105		;    If so, stop move/resize
100$:
	and	bp, mask BI_B3_DOWN or mask BI_B2_DOWN or mask BI_B1_DOWN \
			or mask BI_B0_DOWN
					; Match state: get just button states
					; See if this matches the xor end cond
	xor	bp, word ptr ds:[xorButtonFlag]
	jnz	109$			;    If not, continue
ONP_105:					; END SCREEN XOR:
	push	cx, dx
	call	ImDoStopScreenXor	;    and stop the screen xor
					; ### Possibly add code here to 
					; send MSG_META_END_XOR to process.
	pop	cx, dx
109$:
	pop	bp			; Recover the button state

	cmp	cx, ds:[drawnXPos]	; cx, dx are current display position
	jne	120$		 	; if change, update ptr image
	cmp	dx, ds:[drawnXPos]
	je	noXor			; if no change at all, done
120$:
	mov	cx, ds:[drawnXPos]	; move the pointer to the drawn pos
	mov	dx, ds:[drawnYPos]	;   to handle cases where button actions
	mov	ax, cx			;   change mouse pos (but aren't 
	mov	bx, dx			;   affected by MOVEPTR above)
	call	CallMovePtr		; & move ptr on screen
noXor:

if	(INPUT_MESSAGE_RECEIPT)
	pop	si			; get back offset to inc to show
					; unprocessed.
endif
					; Allow discarding if desparate
	clr	bx			; Don't allow discarding for button
					; operations (To tricky to keep
					; UI gadgetry happy)

SendNonPtr:
				; if si is non-zero, ds:[si] is variable to
				; inc if event is successfully sent.

				; bx is zero or MF_CAN_DISCARD_IF_DESPARATE,
				; as appropriate

				; SEND EVENT FOR NON PTR
				; Get output OD
	mov	ax, di
	mov	di, bx		; get MessageFlags to use
	or	di, mask MF_FORCE_QUEUE	; Require send via queue
	call	MessageOutputOD		; Notify output OD of this change
afterSend:

if	(INPUT_MESSAGE_RECEIPT)
	cmp	di, MESSAGE_NO_HANDLES
	je	continue		; if no handles, event isn't in UI
					;	queue, skip
	tst	si
	jz	continue		; if nothing to increment, skip
	inc	{word} ds:[si]		; Increment "Unprocessed" variable,
					; so we know there's another of
					; that even type in the UI queue
continue:
endif

exit:
	mov	di,ax
	clr	al		; NOTHING MORE TO COME
	ret

OutputNonPtr	endp


IMResident	ends

