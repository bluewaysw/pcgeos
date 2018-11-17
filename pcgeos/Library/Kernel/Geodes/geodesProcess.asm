COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeProcess.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ProcessClass		Superclass of all processes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains routines to implement the process class.

	$Id: geodesProcess.asm,v 1.1 97/04/05 01:12:07 newdeal Exp $

------------------------------------------------------------------------------@

GLoad	segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcCreate

DESCRIPTION:	Make a new process given a core block.  This routine should
		not be called directly unless absolutely need be.

CALLED BY:	INTERNAL
		DoGeodeProcess

PASS:
	cx, dx - information to pass in init message
	ds - core block for new process (locked)
	al - priority for new process
	ah - flags:
		bits 7-0 - unused (pass 0)

	the new process' core block must have all fields set except the process
	variables:
		PH_eventQueue

RETURN:
	none (to calling process)
	State returned for new process:
		blocked on PH_eventQueue,
		MSG_META_ATTACH event sent to new process (which will wake
		up its first thread)

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Compute event queue variables
	Put the process on the eventWait queue
	Set the process' PH_currentPath to be that of its creator
	Send the process an init event

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Note that if the new process has a higher priority it will run before
	the old process returns from this routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Doug's code review added

-------------------------------------------------------------------------------@

ProcCreate	proc	near		uses es
	.enter

EC <	or	ah,ah							>
EC <	jz	PCP_1							>
EC <	ERROR	PCP_BAD_FLAGS						>
EC <PCP_1:								>

	LoadVarSeg	es

	push	ds			;save core block
	push	ax			;save priority
	inc	es:[geodeProcessCount]	;one more process exists

	; create an event queue for the process

	call	GeodeAllocQueue		;returns bx, send to ThreadCreate

	; put MSG_META_ATTACH in the queue

	mov	ax,MSG_META_ATTACH	;event type
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	; Create a thread for the process

					;bx = value to pass to new thread
	mov	bp,ds:[GH_geodeHandle]	;owner for thread
	mov	si,ds:[GH_resHandleOff]	;get first resource
	mov	si,ds:[si][2]		;si = handle of dgroup
	mov	dx,si			;save handle
	mov	di,es:[si].HM_size
	mov	si,es:[si].HM_addr	;si = segment
	mov	cl,4
	shl	di,cl			;di = offset

	; must set TPD_blockHandle of new thread

	mov	ds, si
	mov	ds:[TPD_blockHandle],dx

	; initialize the exception vectors for the new process.

	call	ThreadInitProcessExceptions

	; zero out all fields in the TPD_heap

	push	es, di
	mov	di, offset TPD_heap
	mov	cx, size TPD_heap / 2
	clr	ax
	segmov	es, ds
	rep	stosw
	pop	es, di

	; NOTE:
	; There is a potential syncronization problem here.  If we create the
	; thread before we set the resource HM_otherInfo fields up, we could
	; context switch to the new thread and die.  Unfortunatly, we cannot
	; set the resources up before we have the thread handle.
	;
	; We solve this by using TPD_callVector as a semaphore.  The new thread
	; blocks on this, and we V it after setting the resources correctly.
	; TPD_callVector is initialized to 0 by CreateThreadCommon.
	;
	; 2/23/92: TPD_callVector is no longer viable, as it can be corrupted
	; by the LCT_NEW_CLIENT_THREAD handlers for the geode's libraries.
	; Instead, CreateThreadCommon creates a 0-initialized semaphore just
	; above TPD_stackBot and adjusts TPD_stackBot accordingly. We use
	; that instead -- ardeb

	pop	ax			;recover priority
	push	ds:[TPD_stackBot]	;save offset where start semaphore
					; will be created
	push	ds			;save dgroup (stack segment)
	push	bx			;save queue handle

	mov	cx, seg kcode		;start thread at NewEventThread
	mov	dx, offset NewEventThread	; (objectProcess.asm)
	call	CreateThreadCommon	;start it! (send bx = queue handle)
	pop	ax			;ax = queue handle
	pop	dx			;dx = dgroup (stack segment)

	pop	di			; di <- start-semaphore offset
	pop	ds			;recover core block
	push	di			; save start-semaphore offset

	mov	es:[bx].HT_eventQueue,ax	;set event queue for the
						;thread in case somebody sends
						;an event to it before it gets
						;to ThreadAttachToQueue

	; we must make this queue owned by the new process, not by the executing
	; process or bad this will happen if this process exits first

	mov	di, ds:[GH_geodeHandle]		;save handle of first thread
	mov	es:[di].HM_otherInfo, bx	;in process handle

	mov_trash	di, ax		;di = queue handle (1-byte inst)
	mov	ax, ds:[GH_geodeHandle]
	mov	es:[di].HQ_owner, ax

	; before we let the thread start executing, we must go through the
	; resources and change the otherInfo field for any -1's we find
	; the -1's are stored by AllocateResource

	mov	ax, -1
	call	SubstituteRunningThread

	; wake the thread up

	mov	es, dx
	pop	bx			; es:bx <- start-semaphore
	VSem	es, [bx], TRASH_AX_BX, NO_EC

	.leave
	ret

ProcCreate	endp

GLoad	ends



COMMENT @----------------------------------------------------------------------

FUNCTION:	SubstituteRunningThread

DESCRIPTION:	Search through resources, substituting any "HM_otherInfo"
		field found that matches the passed in value with the 
		replacement value.

CALLED BY:	INTERNAL
		ProcCreate, ProcessCreateUIThread(2), ThreadDestroy(2)

PASS:		ds	- core block of process (locked)
		ax	- Value to look for
		bx	- Value to substitute

RETURN:		ax	- # of substitutions made (used by ProcessCreateUIThread
			  first pass through with ax=bx=-2 to see if there is a
			  need for a UI thread)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/1/92		Pulled out from ProcCreate, optimized
------------------------------------------------------------------------------@

SubstituteRunningThread	proc	far	uses	cx, dx, bp, si, di, es
	.enter
	mov_trash	bp, ax		;keep value to look for in bp
	LoadVarSeg	es, ax
	clr	dx			;no subs yet
	mov	si,ds:[GH_resHandleOff]	;ds:si points at handles
	mov	cx,ds:[GH_resCount]	;cx is # of handles
resourceLoop:
	lodsw				;load handle
	mov_trash	di, ax		;check if run by "thread" we're looking
	cmp	es:[di].HM_otherInfo,bp	;	for... if so, change it.
	je	change
afterChange:
	loop	resourceLoop
	mov_trash	ax, dx		;return # of subs in ax
	.leave
	ret

change:
	mov	es:[di].HM_otherInfo,bx	;store new thread
	inc	dx			;one more substitution made
	jmp	short afterChange

SubstituteRunningThread	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	KillProcess

DESCRIPTION:	Remove a process after waiting for all other threads to exit.
		Send notification of exit to process' parent.

CALLED BY:	EXTERNAL
		ThreadDestroy

PASS:
	Must be called from first thread on a process
	ds - kernel variable segment
	es - process's core block (locked)

RETURN:
	ax - notification message to send
	bx - process to send it to (0 for none)
	cx - data to pass in cx

DESTROYED:
	dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Wait for all threads to exit
	Send exit event to parent

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	Tony	10/88		Comments from Doug's code review added
-------------------------------------------------------------------------------@

KillProcess	proc	near

	; send exit code to parent

	mov	bx,es:[GH_parentProcess]		;id of parent

	; make sure that the parent process still exists

	mov	al, ds:[bx].HG_type
	tst	al
	jz	KP_noParent
HMA <	cmp	al, SIG_UNUSED_FF					>
HMA <	je	KP_isMem						>
	cmp	al,SIG_NON_MEM
	jae	KP_noParent
HMA <KP_isMem:								>
	cmp	bx,ds:[bx].HM_owner
	jnz	KP_noParent
	push	ds
	mov	ds,ds:[bx].HM_addr
	test	ds:[GH_geodeAttr],mask GA_PROCESS
	pop	ds
	jnz	common

KP_noParent:
	clr	bx
common:
	mov	cx,ss:[TPD_processHandle]		;cx = process exiting
	mov	ax,MSG_PROCESS_NOTIFY_PROCESS_EXIT

	dec	ds:[geodeProcessCount]		;one fewer process
	andnf	es:[GH_geodeAttr],not mask GA_PROCESS

	ret

KillProcess	endp
