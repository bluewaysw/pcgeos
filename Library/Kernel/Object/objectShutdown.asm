COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		objShutdown.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	2/89		Updated DEATH & DESTROY

DESCRIPTION:
	This file contains routines to implement the meta class.

	$Id: objectShutdown.asm,v 1.1 97/04/05 01:14:36 newdeal Exp $

-------------------------------------------------------------------------------@

ObjectFile segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjInitDetach

DESCRIPTION:	Create and init for detaching an object

CALLED BY:	GLOBAL

PASS:
	*ds:si - object
	ax - message provoking this call (MSG_META_DETACH or
	     MSG_META_APP_SHUTDOWN)
	cx - caller ID
	dx:bp - optr for ACK

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjInitDetach	proc	far
	uses	ax, bx, cx, dx, bp, di
	.enter

	mov	di, MSG_META_DETACH_COMPLETE
	cmp	ax, MSG_META_DETACH
	je	findDetachData
EC <	cmp	ax, MSG_META_APP_SHUTDOWN				>
EC <	ERROR_NZ	BAD_DETACH_MSG					>
	mov	di, MSG_META_SHUTDOWN_COMPLETE
findDetachData:
	; check for DetachData already exists which means that we are called
	; from our superclass

	mov	ax, DETACH_DATA
	call	ObjVarFindData		;ds:bx = data entry if found
	jnc	new			;not found
EC <	cmp	ds:[bx].DDE_completeMsg, di				>
EC <	ERROR_NE	OBJ_SHUTDOWN_OR_DETACH_WHILE_OTHER_STILL_ACTIVE>

	inc	ds:[bx].DDE_ackCount	;add 1 to keep detaching disabled until
					; ObjEnableDetach is called
	jmp	done

new:

EC <	xchg	bx, dx						>
EC <	xchg	si, bp						>
EC <	call	ECCheckOD					>
EC <	xchg	bx, dx						>
EC <	xchg	si, bp						>

	; allocate temporary chunk for data

	push	cx
	mov	ax, DETACH_DATA
	mov	cx, size DetachDataEntry
	call	ObjVarAddData
					;start disabled
	mov	ds:[bx].DDE_ackCount, 1
	pop	ds:[bx].DDE_callerID		;incoming CX
	mov	ds:[bx].DDE_ackOD.handle,dx
	mov	ds:[bx].DDE_ackOD.chunk, bp	;incoming BP
	mov	ds:[bx].DDE_completeMsg, di

done:
	.leave

	ret

ObjInitDetach	endp
COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjIncDetach

DESCRIPTION:	Increment the ACK for an object

CALLED BY:	GLOBAL

PASS:
	*ds:si - object

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
	Tony	3/89		Initial version

------------------------------------------------------------------------------@
ObjIncDetach	proc	far
	uses	ax, bx
	.enter

	mov	ax, DETACH_DATA
	call	ObjVarFindData		;ds:bx = data entry if found
EC <	ERROR_NC	OBJ_TEMP_CHUNK_NOT_FOUND			>
	inc	ds:[bx].DDE_ackCount

	.leave
	ret

ObjIncDetach	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjEnableDetach

DESCRIPTION:	Acknowledge detach for an object

CALLED BY:	GLOBAL & MSG_META_ACK

PASS:
	*ds:si - object

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Doug	12/89		Changed to just send DETACH_COMPLETE when count
				reaches 0.

------------------------------------------------------------------------------@
ObjEnableDetach	method	MetaClass, MSG_META_ACK, MSG_META_SHUTDOWN_ACK
	uses	bx
	.enter

	push	ax
	mov	ax, DETACH_DATA
	call	ObjVarFindData		;ds:bx = data entry if found
	pop	ax
EC <	ERROR_NC	OBJ_TEMP_CHUNK_NOT_FOUND			>

	dec	ds:[bx].DDE_ackCount
	jnz	OAD_nonZero

	; Decremented to zero -- send DETACH_COMPLETE to the object
	; itself, passing the ackOD & callerID.

	push	ax, bx, cx, dx, si, di, bp, es
	mov	ax, ds:[bx].DDE_completeMsg

	mov	dx,ds:[LMBH_handle]			;dx:bp = our OD
	mov	bp,si
	mov	cx,ds:[bx].DDE_callerID			;data in cx
	mov	di,ds:[bx].DDE_ackOD.handle		;get OD in di:<stack>
	push	ds:[bx].DDE_ackOD.chunk
	call	ObjVarDeleteDataAt
	mov	bx, di					;ackOD in bx:si
	pop	si

	xchg	bx, dx			; Switch to have ackOD in dx:bp,
	xchg	si, bp			; This object in bx:si

	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, bx, cx, dx, si, di, bp, es

OAD_nonZero:
	.leave
	ret
ObjEnableDetach	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjDetachCompleted

DESCRIPTION:	Handle the fact that the detach has been completed for
		this object.  This is handled by sending a MSG_META_ACK to
		whoever requested that this object be detached.

CALLED BY:	GLOBAL

PASS:
	*ds:si - object
	cx	- callerID passed to ObjInitDetach
	dx:bp	- ackOD passed to ObjInitDetach

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Send MSG_META_ACK to ackOD passed to ObjInitDetach, passing:
			cx = callerID passed to ObjInitDetach,
			dx:bp = OD of this object;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Split this functionality out from
				MSG_META_ACK handler.

------------------------------------------------------------------------------@
ObjDetachCompleted	method	MetaClass, MSG_META_DETACH_COMPLETE
	mov	bx, ds:[LMBH_handle]	; bx:si is OD of this object
					; dx:bp is ackOD

	xchg	bx, dx			; Switch to have this obj in dx:bp,
	xchg	si, bp			; ackOD in bx:si

	mov	ax,MSG_META_ACK
				; Force this to be sent via queue, to give
				; a little more flush time :)
ODC_sendmethod label near		;USED BY "showcalls -s"
ForceRef	ODC_sendmethod
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
ObjDetachCompleted	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjShutdownCompleted

DESCRIPTION:	Handle the fact that the shutdown has been completed for
		this object.  This is handled by sending a MSG_META_SHUTDOWN_ACK
		to whoever requested that this object be shutdown.

CALLED BY:	GLOBAL

PASS:
	*ds:si - object
	cx	- callerID passed to ObjInitDetach
	dx:bp	- ackOD passed to ObjInitDetach

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Send MSG_META_SHUTDOWN_ACK to ackOD passed to ObjInitDetach, passing:
			cx = callerID passed to ObjInitDetach,
			dx:bp = OD of this object;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Split this functionality out from
				MSG_META_ACK handler.
	ardeb	10/16/92	Stolen from MSG_META_DETACH_COMPLETE

------------------------------------------------------------------------------@
ObjShutdownCompleted	method	MetaClass, MSG_META_SHUTDOWN_COMPLETE
	mov	bx, ds:[LMBH_handle]	; bx:si is OD of this object
					; dx:bp is ackOD

	xchg	bx, dx			; Switch to have this obj in dx:bp,
	xchg	si, bp			; ackOD in bx:si

	mov	ax,MSG_META_SHUTDOWN_ACK
				; Force this to be sent via queue, to give
				; a little more flush time :)
OSC_sendmethod label near		;USED BY "showcalls -s"
ForceRef	OSC_sendmethod
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
ObjShutdownCompleted	endm
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for MSG_META_DETACH.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= object
		cx	= caller ID
		dx:bp	= ack optr
RETURN:		nothing
DESTROYED:	bx...

PSEUDO CODE/STRATEGY:
		MSG_META_DETACH should, in general, always reach here, but what
		we do depends on whether the subclass has called
		ObjInitDetach or no. If it has, we need do nothing, as
		the MSG_META_ACK will be generated when the final MSG_META_ACK is
		received. If it has not, we queue the MSG_META_ACK ourselves.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjDetach	method dynamic MetaClass, MSG_META_DETACH
		.enter
		mov	ax, DETACH_DATA
		call	ObjVarFindData
		jc	ignore
		
		call	ObjDetachCompleted
EC <done:								>
NEC <ignore:								>
		.leave
		ret

; If we've reached here and there is detach data, the ack count damn well
; better not be 0, as that implies a DETACH_COMPLETE should have been
; already sent out and the DETACH_DATA nuked.
EC <ignore:								>
EC <		tst	ds:[bx].DDE_ackCount				>
EC <		ERROR_Z	GASP_CHOKE_WHEEZE				>
EC <		jmp	done						>
ObjDetach	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjAppShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for MSG_META_APP_SHUTDOWN.

CALLED BY:	MSG_META_APP_SHUTDOWN
PASS:		*ds:si	= object
		cx	= caller ID
		dx:bp	= ack optr
RETURN:		nothing
DESTROYED:	bx...

PSEUDO CODE/STRATEGY:
		MSG_META_APP_SHUTDOWN should, in general, always reach here,
		but what we do depends on whether the subclass has called
		ObjInitDetach or no. If it has, we need do nothing, as
		the MSG_META_SHUTDOWN_ACK will be generated when the final
		MSG_META_SHUTDOWN_ACK is received. If it has not, we queue
		the MSG_META_SHUTDOWN_ACK ourselves.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjAppShutdown	method dynamic MetaClass, MSG_META_APP_SHUTDOWN
		.enter
		mov	ax, DETACH_DATA
		call	ObjVarFindData
		jc	ignore
		
		call	ObjShutdownCompleted
EC <done:								>
NEC <ignore:								>
		.leave
		ret

; If we've reached here and there is detach data, the ack count damn well
; better not be 0, as that implies a SHUTDOWN_COMPLETE should have been
; already sent out and the DETACH_DATA nuked.
EC <ignore:								>
EC <		tst	ds:[bx].DDE_ackCount				>
EC <		ERROR_Z	GASP_CHOKE_WHEEZE				>
EC <		jmp	done						>
ObjAppShutdown	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_META_QUIT_ACK through the passed OD.

CALLED BY:	GLOBAL
PASS:		cx:dx <- return OD
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjQuit	method	MetaClass, MSG_META_QUIT
	mov	bx,cx			;^lBX:SI <- object to ack to
	mov	si,dx			;
	clr	cx			;No abort...
	mov	ax, MSG_META_QUIT_ACK	;Send ack.
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
ObjQuit	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjQuitAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle MSG_META_QUIT_ACK.  Deals with sending MSG_META_QUIT
		to active list items, if any.

CALLED BY:	GLOBAL
PASS:		dx - QuitLevel acknowledging (if a responding to a process)
		cx - abort flag (non-zero if you want to abort the quit)
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjQuitAck	method	MetaClass, MSG_META_QUIT_ACK
	tst	cx				; abort quit?
	LONG jne	finish			; yes
	;
	; if we are in the middle of a quit, we'll have a list of active list
	; items that we've sent MSG_META_QUIT to
	;
	mov	bp, si				; *ds:bp = object chunk
	mov	ax, TEMP_META_QUIT_LIST
	call	ObjVarFindData
	mov	ax, ds:[bx]
	jc	haveQuitList
	;
	; otherwise, look for an active list.  If we have one, we'll need to
	; send MSG_META_QUIT to each item on the list
	;
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData
	jnc	finish
	mov	di, ds:[bx].TMGCND_listOfLists
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, MGCNLT_ACTIVE_LIST
	clc					; do not create list
	call	GCNListFindListInBlock		; *ds:si = active list
	jnc	finish				; no active list
	;
	; we have an active list, create a new list to keep track of which
	; active list items we've sent MSG_META_QUIT to
	;	*ds:si = active list
	;
	push	si				; save active list
	mov	bx, size optr			; store just an optr
	mov	cx, 0				; no extra header space
	clr	si				; allocate new chunk
	clr	al				; not dirty (we'll be freeing it
						;	later)
	call	ChunkArrayCreate		; *ds:si = new array
	push	si				; save new array
	mov	si, bp				; *ds:si = object
	;
	; store the new list in vardata
	;
	mov	ax, TEMP_META_QUIT_LIST
	mov	cx, size word
	call	ObjVarAddData
	pop	ax				; *ds:ax = new array
	mov	ds:[bx], ax
	pop	si				; *ds:si = active list
	jmp	short haveQuitAndActiveList

	;
	; We have our list of active list items that we've sent MSG_META_QUIT
	; to.  Go through the actual active list and send MSG_META_QUIT to the
	; first item that we haven't sent MSG_META_QUIT to (this handles items
	; added during the quit process).  If we've sent MSG_META_QUIT to all
	; items, we can finish up our own quit handling.
	;	*ds:ax = quit list
	;
haveQuitList:
	push	ax				; save quit list
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData
NEC <	jnc	sentAllQuitsPop			; finished sending	>
EC <	ERROR_NC	META_INTERNAL_QUIT_PROBLEM			>
	mov	di, ds:[bx].TMGCND_listOfLists
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, MGCNLT_ACTIVE_LIST
	clc					; do not create list
	call	GCNListFindListInBlock		; *ds:si = active list
NEC <sentAllQuitsPop:							>
	pop	ax				; *ds:ax = quit list
NEC <	jnc	sentAllQuits			; finished sending	>
EC <	ERROR_NC	META_INTERNAL_QUIT_PROBLEM			>

haveQuitAndActiveList:
	;
	; go through active list
	;	*ds:si = active list
	;	*ds:ax = quit list
	;	*ds:bp = this object
	;
	mov	bx, cs
	mov	di, offset QuitActiveListCallback
	call	ChunkArrayEnum
	jc	exit				; MSG_META_QUIT was sent to
						;	an active list item.
						;	Exit and wait for the
						;	ACK.
NEC <sentAllQuits:							>
	;
	; Else, all items on the active list have been sent a MSG_META_QUIT.
	; Remove the list of objects that have been sent a MSG_META_QUIT and
	; finish up the quit sequence by sending MSG_META_FINISH_QUIT to
	; ourselves (allowing someone to subclass it).
	;	*ds:ax = quit list
	;	*ds:bp = this object
	;
	call	LMemFree			; free quit list
	mov	si, bp				; *ds:si = this object
	mov	ax, TEMP_META_QUIT_LIST
	call	ObjVarDeleteData
	;
	; finish the quit sequence
	;	*ds:si = this object
	;
	clr	cx				;No abort.
finish:
	mov	ax, MSG_META_FINISH_QUIT	;Can be subclassed...
						;(GenApp does to notify process)
	call	ObjCallInstanceNoLock
exit:
	ret
ObjQuitAck	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuitActiveListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to send a MSG_META_QUIT to the next object
		on the active list to which we've not sent one already.

CALLED BY:	(INTERNAL) ObjQuitAck via ChunkArrayEnum
PASS:		*ds:si = active list
		ds:di = active list item
		*ds:ax = quit list
		*ds:bp = object with active list (object to ACK)
RETURN:		
		carry clear to continue enumeration (item has already been
			previously sent a MSG_META_QUIT)
		carry set to stop enumeration (item has been not been 
			previously sent a MSG_META_QUIT, so has just been
			sent a MSG_META_QUIT)
		ax, bp - unchanged
DESTROYED:	bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuitActiveListCallback	proc	far
	mov	cx, ds:[di].GCNLE_item.handle	; ^lcx:dx = active list item
	mov	dx, ds:[di].GCNLE_item.chunk
	;
	; check if this active list has been sent a MSG_META_QUIT already
	;	^lcx:dx = active list item
	;
	mov	si, ax				; *ds:si = quit list
	mov	bx, cs
	mov	di, offset CheckQuitListCallback
	call	ChunkArrayEnum			; carry set it item found
						; carry clear if item not found
	cmc					; carry clear if item found
						; carry set if item not found
	jnc	done				; item has already been sent
						;	a MSG_META_QUIT
	;
	; item has not been sent a MSG_META_QUIT yet, do so now.  Also must
	; add item to quit list.
	;	*ds:si = quit list
	;	^lcx:dx = item
	;	*ds:bp = object with active list (object to ACK)
	;
	call	ChunkArrayAppend		; add quit list element (ds:di)
	mov	({optr} ds:[di]).handle, cx		; save item
	mov	({optr} ds:[di]).chunk, dx
	mov	bx, cx				; ^lbx:si = item to send
	mov	si, dx				;	MSG_META_QUIT
	mov	ax, MSG_META_QUIT
	mov	cx, ds:[LMBH_handle]		; ACK back to this object
	mov	dx, bp
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	stc					; indicate that we've sent a
						;	MSG_META_QUIT and
						;	we should wait for the
						;	ACK
done:
	ret
QuitActiveListCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckQuitListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to look for an optr on the already-sent-
		a-MSG_META_QUIT list.

CALLED BY:	(INTERNAL) QuitActiveListCallback via ChunkArrayEnum
PASS:		*ds:si = quit list
		ds:di = quit list item
		^lcx:dx = item to search for
RETURN:		carry set if item matches (stops enumeration)
		carry clear if item doesn't match (continues enumeration)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckQuitListCallback	proc	far
	cmp	cx, ({optr} ds:[di]).handle
	jne	mismatch
	cmp	dx, ({optr} ds:[di]).chunk
	stc				; assume match, stops enumeration
	je	done			; match, stop enumeration (C set)
mismatch:
	clc				; no match, continue enumeration
done:
	ret
CheckQuitListCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjFinishQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle MSG_META_FINISH_QUIT.  Indicates end of quit sequence.

CALLED BY:	GLOBAL
PASS:		cx - abort flag (non-zero if you want to abort the quit)
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjFinishQuit	method	MetaClass, MSG_META_FINISH_QUIT
	mov	ax, TEMP_META_QUIT_LIST		; are we in the process of
						;	a quit sequence?
	call	ObjVarFindData			; carry set if found
	mov	ax, MSG_META_FINISH_QUIT	; assume not
	jnc	done				; no, nothing to do
	;
	; We are in a quit sequence.  If we are aborting, we must stop our
	; quitting sequence.  If not aborting, we just continue the quit
	; sequence.
	;	cx = abort flag
	;
	tst	cx
	jnz	abort
	mov	ax, MSG_META_QUIT_ACK		; else, continue our quit
						;	sequence
	GOTO	ObjCallInstanceNoLock

abort:
	; ds:[bx] = TEMP_META_QUIT_LIST vardata
	mov	ax, ds:[bx]
	call	LMemFree			; free quit list
	mov	ax, TEMP_META_QUIT_LIST
	call	ObjVarDeleteData
done:
	ret
ObjFinishQuit	endm

ObjectFile	ends
