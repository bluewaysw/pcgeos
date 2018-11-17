COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nwTextMessage.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/15/93   	Initial version.

DESCRIPTION:
	

	$Id: nwTextMessage.asm,v 1.1 97/04/18 11:48:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetWareInitCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareGrabAllAlerts

DESCRIPTION:	Tell NetWare that we do not want the Workstation Shell
		to display incoming Console Messages and Personal Messages
		on the 25th line of the character screen. Instead, we
		will assume that there's a GEOS app set up to poll for
		messages every few seconds or so...

CALLED BY:	NetWareInit

PASS:		nothing

RETURN:		nothing 

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareGrabAllAlerts	proc	far

	; Get the current status.  If it's "discard", then do nothing,
	; as user doesn't want to be bothered.

		mov	ah, high NFC_GET_BROADCAST_MODE
		call	NetWareCallFunction

		cmp	al, NMM_RETRIEVE_SERVER_DISCARD_USER
		je	done
		cmp	al, NMM_STORE_SERVER_DISCARD_USER
		je	done
		
		mov	ah, high NFC_SET_BROADCAST_MODE 
		mov	dl, NMM_STORE_SERVER_AND_USER
		call	NetWareCallFunction
done:
		ret
NetWareGrabAllAlerts	endp


NetWareInitCode	ends


NetWareResidentCode	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareReleaseAllAlerts

DESCRIPTION:	Tell NetWare that we want the Workstation Shell
		to display incoming Console Messages and Personal Messages
		on the 25th line of the character screen, as it normally would.

IMPORTANT:	This routine is called when a V1.2 task switcher is
		preparing to task switch. We MUST CLEANUP, and quickly!

		Due to the nature of the call to this routine, we must NOT:
		    - take too long
		    - attempt to grab any semaphores, or block for any reason
		    - call any routines which are not fixed.

	FOR 2.0: MUST BE IN RESIDENT RESOURCE, SINCE THIS IS
		A SYSTEM DRIVER.

CALLED BY:	NetWareDriverExit, NetWarePrepareForTaskSwitch

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareReleaseAllAlerts	proc	near

		mov	ah, high NFC_GET_BROADCAST_MODE
		call	NetWareCallFunction
		cmp	al, NMM_RETRIEVE_SERVER_DISCARD_USER
		je	done
		cmp	al, NMM_STORE_SERVER_DISCARD_USER
		je	done

	;
	; Restore messaging back to the normal state
	;

		mov	ah, high NFC_SET_BROADCAST_MODE
		mov	dl, NMM_RETRIEVE_SERVER_AND_USER
		call	NetWareCallFunction
done:
		ret
NetWareReleaseAllAlerts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareTextMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dispatch routine for NetTextMessageFunction calls

CALLED BY:	NetWareStrategy

PASS:		depends on function called

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareTextMessage	proc near
	call	NetWareRealTextMessage
	ret
NetWareTextMessage	endp

NetWareResidentCode	ends

NetWareCommonCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareRealTextMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the work, now that we're in a movable segment

CALLED BY:	NetWareTextMessage

PASS:		al - NetTextMessageFunction to call

RETURN:		values returned from called procedures

DESTROYED:	es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareRealTextMessage	proc far
	.enter

	clr	ah
	mov_tr	di, ax

EC <	cmp	di, NetTextMessageFunction				>
EC <	ERROR_AE NW_ERROR_INVALID_DRIVER_FUNCTION			>

	call	cs:[netWareTextMessageCalls][di]

	.leave
	ret
NetWareRealTextMessage	endp

netWareTextMessageCalls	nptr	\
	offset	NWTextMessageSend,
	offset	NWTextMessagePoll

.assert (size netWareTextMessageCalls eq NetTextMessageFunction )







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWTextMessageSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a text message to another user using Novell's
		text messaging API

CALLED BY:	NetWareRealTextMessage

PASS:		ds:si - user name
		cx:dx - message text.  Should be mapped to the DOS
			character set

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWTextMessageSend	proc near

	uses	ax,bx,cx,dx,di,si

userName	local	fptr.char	push	ds, si
message		local	fptr.char	push	cx, dx

	.enter

	;
	; Convert the message to the DOS character set, for Gene's
	; benefit...  We have the unfortunate side effect that we're
	; munging the caller's data, but who cares???
	;

	mov	ds, cx
	mov	si, dx
	clr	cx
	mov	ax, '_'
	call	LocalGeosToDos


	;
	; Get connection number from name
	;

	mov	bx, size NReqBuf_GetObjectConnectionNumbers
	mov	cx, size NRepBuf_GetObjectConnectionNumbers
	call	NetWareAllocRRBuffers
	mov	es:[si].NREQBUF_GOCN_objectType, NOT_USER

	push	si, di			; request, reply buffers
	lea	di, es:[si].NREQBUF_GOCN_objectName

	lds	si, ss:[userName]

	;
	; Copy the name in, and see how long it is
	;

	call	NetWareCopyStringButNotNull	; cx - length

	pop	si, di			; request, reply buffers
	mov	es:[si].NREQBUF_GOCN_objectNameLen, cl
	mov	ax, NFC_GET_OBJECT_CONNECTION_NUMBERS
	call	NetWareCallFunctionRR

	;
	; Just snarf the first connection number.  If the user's
	; logged in more than once, too bad...
	;

	mov	dl, es:[di].NREPBUF_GOCN_connections[0]

	call	NetWareFreeRRBuffers
	jc	done

	;
	; Now, send the message.  This request buffer is a DOG to set
	; up...
	;

	;
	; Fetch the message length
	;

	les	di, ss:[message]
	clr	al
	mov	cx, -1
	repne	scasb
	not	cx
	dec	cx			; length of message minus NULL
	;
	; Allocate the buffers
	;

	push	cx
	mov	bx, size NReqBuf_SendBroadcastMessage + 2
	add	bx, cx
	mov	cx, size NRepBuf_SendBroadcastMessage
	call	NetWareAllocRRBuffers
	pop	cx

	;
	; Fill in the request buffer.  We only send to one connection
	;

	mov	es:[si].NREQBUF_SBM_connectionCount, 1
	push	si, di

	lea	si, es:[si].NREQBUF_SBM_connectionList
	mov	es:[si], dl			; connection #
	inc	si
	mov	es:[si], cl			; message length

	lea	di, es:[si+1]
	lds	si, ss:[message]

	call	NetWareCopyStringButNotNull
	pop	si, di

	;
	; Now, send it
	;
	mov	ax, NFC_SEND_BROADCAST_MESSAGE
	call	NetWareCallFunctionRR

	call	NetWareFreeRRBuffers
done:
	.leave
	ret
NWTextMessageSend	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWTextMessagePoll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Poll the server for a message, stuffing it in the
		provided buffer

CALLED BY:	NetWareRealTextMessage

PASS:		ds:si - buffer to fill.  Buffer must be at least
		NET_TEXT_MESSAGE_BUFFER_SIZE bytes.

RETURN:		carry SET if message available,
			ax = NET_STATUS_OK
		carry clear otherwise
			ax - destroyed

DESTROYED:	es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWTextMessagePoll	proc near

	uses	bx,cx,dx,di,si,ds

callerBuffer	local	fptr.char	push	ds, si

	.enter


	;allocate a global block to hold our request and reply buffers

	mov	bx, size NReqBuf_GetBroadcastMessage
	mov	cx, size NRepBuf_GetBroadcastMessage

	call	NetWareAllocRRBuffers	; es:si - request buf
					; es:di - reply buf

					;pass ah = function code, al = subfunc.
	push	es:[NRR_handle]		;save handle of reply buffer

	mov	ax, NFC_GET_BROADCAST_MESSAGE
	call	NetWareCallFunctionRR	;call NetWare, passing RR buffer
	jc	doneCLC

	;
	; is there a message?
	;

EC <	call	ECNetWareCheckRRBufferES ;assert es = Request/Reply Buffer >

	mov	cl, es:[di].NREPBUF_GBM_messageLength
	clr	ch			;cx = size of message, from
					;reply buffer
	jcxz	done

EC <	cmp	cx, NET_TEXT_MESSAGE_BUFFER_SIZE			>
EC <	ERROR_A STRING_BUFFER_OVERFLOW					>

	;
	; localize this ascii string, because we are in DOS-land, ya know.
	;

	add	di, offset NREPBUF_GBM_message
	
	segmov	ds, es
	mov	si, di			;pass: ds:si = message

	mov	ax, '_'			;default character
	call	LocalDosToGeos

	;
	; Copy the string out to the caller's buffer.  Novell didn't
	; null-terminate it, so we have to do that ourselves (jeesh!)
	;

	les	di, ss:[callerBuffer]
	rep	movsb
	clr	al
	stosb
	stc
	mov	ax, NET_STATUS_OK
		
done:
	pop	bx			;^hbx = reply buffer
	pushf
	call	MemFree
	popf

	.leave
	ret

doneCLC:
	clc
	jmp	done

NWTextMessagePoll	endp



NetWareCommonCode	ends
