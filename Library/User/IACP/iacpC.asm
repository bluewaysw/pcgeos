COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	User Interface
MODULE:		IACP C Interface
FILE:		iacpC.asm

AUTHOR:		Adam de Boor, Oct 22, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/22/92	Initial revision


DESCRIPTION:
	C stubs for IACP functions
		

	$Id: iacpC.asm,v 1.1 97/04/07 11:47:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IACPCode	segment	resource

if FULL_EXECUTE_IN_PLACE
IACPCode  ends
UserCStubXIP    segment resource
endif

SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPREGISTERSERVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register an object as a server for the list with the
		given token.

CALLED BY:	(GLOBAL)
PARAMETERS:	void (GeodeToken *list, optr server, IACPServerMode mode,
		      IACPServerFlags flags)
		Note: "list" *can* be pointing to the movable XIP 
			code resource.

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPREGISTERSERVER proc	far
	CheckHack <segment IACPRegisterServer eq segment IACPUnregisterServer>
		C_GetTwoWordArgs ax, bx,   cx, dx   ; ax <- mode, bx <- flags
		mov	ah, bl
		mov	ss:[TPD_dataAX], ax
NOFXIP<		mov	ax, offset IACPRegisterServer			>
FXIP<		mov	ax, offset IACPRegisterServerXIP		>
		jmp	IACPRegisterUnregisterCommon
IACPREGISTERSERVER endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPUNREGISTERSERVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an object from the list of servers for a given list.

CALLED BY:	(GLOBAL)
PARAMETERS:	void (GeodeToken *list, optr server)
		Note: "list" *can* be pointing to the movable XIP 
			code resource.
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPUNREGISTERSERVER proc	far	list:fptr.GeodeToken, server:optr
	on_stack	retf
NOFXIP<		mov	ax, offset IACPUnregisterServer			>
FXIP<		mov	ax, offset IACPUnregisterServerXIP		>
IACPRegisterUnregisterCommon	label near
		uses	es, di
		.enter
	on_stack	es di bp retf

		les	di, ss:[list]
		movdw	cxdx, ss:[server]
NOFXIP<		mov	bx, vseg IACPUnregisterServer			>
FXIP<		mov	bx, vseg IACPUnregisterServerXIP		>
		call	ProcCallFixedOrMovable
		.leave
		ret
IACPUNREGISTERSERVER endp


if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
IACPCode  segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPREGISTERDOCUMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a document as being open.

CALLED BY:	(GLOBAL)
PARAMETERS:	void (optr server, word disk, dword fileID)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPREGISTERDOCUMENT proc	far	server:optr, disk:word, id:FileID
			on_stack	retf
		clc
regUnregDocCommon label near
		uses	si
		.enter
			on_stack	si bp retf
		movdw	bxsi, ss:[server]
		mov	ax, ss:[disk]
		movdw	cxdx, ss:[id]
		jc	unregister
		call	IACPRegisterDocument
done:
		.leave
		ret

unregister:
		call	IACPUnregisterDocument
		jmp	done
IACPREGISTERDOCUMENT endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPUNREGISTERDOCUMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note a document as closed.

CALLED BY:	(GLOBAL)
PARAMETERS:	void (optr server, word disk, dword fileID)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPUNREGISTERDOCUMENT proc	far
		stc
		jmp	regUnregDocCommon
IACPUNREGISTERDOCUMENT		endp


if FULL_EXECUTE_IN_PLACE
IACPCode  ends
UserCStubXIP    segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPCONNECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to one or more servers on the indicated list.

CALLED BY:	(GLOBAL)
PARAMETERS:	IACPConnection (GeodeToken *list, IACPConnectFlags flags,
			        MemHandle appLaunchBlock, optr client,
				word *numServersPtr)
		Note: "list" *can* be pointing to the movable XIP code
			resource.
RETURN:		if connection is successful, return value is non-zero and the
			number of servers to which the connection was made
			is stored in *numServersPtr
		if connection fails, return value is 0 (IACP_NO_CONNECTION) and
			the error (IACPConnectError or GeodeLoadError) is 
			stored in *numServersPtr
SIDE EFFECTS:	AppLaunchBlock is freed, if it was passed non-zero

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPCONNECT	proc	far	list:fptr.GeodeToken,
				flags:IACPConnectFlags,
				appLaunchBlock:hptr.AppLaunchBlock,
				client:optr,
				numServersPtr:fptr.word
		uses	es, di
		.enter
		les	di, ss:[list]
		mov	ax, ss:[flags]
		mov	bx, ss:[appLaunchBlock]
		movdw	cxdx, ss:[client]
NOFXIP<		call	IACPConnect					>
FXIP<		call	IACPConnectXIP					>
		mov	bx, sp
		les	di, {fptr}ss:[bx+offset numServersPtr+4]
		jc	error
		mov	es:[di], cx
		mov_tr	ax, bp
done:
		.leave
		ret
error:
		stosw
		clr	ax
		jmp	done
IACPCONNECT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPCONNECTTODOCUMENTSERVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to the server of the indicated file.

CALLED BY:	(GLOBAL)
PARAMETERS:	IACPConnection (const char _far *pathname,
				const char _far *filename,
				DiskHandle disk,
				IACPConnectFlags flags,
				optr client)

RETURN:		if connection is successful, return value is non-zero and the
			number of servers to which the connection was made
			is stored in *numServersPtr
		if connection fails, return value is 0 (IACP_NO_CONNECTION) and
			the error (IACPConnectError or GeodeLoadError) is 
			stored in *numServersPtr
SIDE EFFECTS:	AppLaunchBlock is freed, if it was passed non-zero

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPCONNECTTODOCUMENTSERVER	proc	far	pathname:fptr,
						filename:fptr,
						disk:word,
						flags:IACPConnectFlags,
						client:optr
						
tempPathname	local	PathName
tempFilename	local	FileLongName		
		uses	ds, si, di
		.enter
	;
	; Since these variables are messed with in IACPPrepStrings
	; we do this to get rid of warnings.
	;
		ForceRef	filename
		ForceRef	tempPathname
		ForceRef	tempFilename
	;
	; Make sure the strings are in the same segment
	;
		lea	di, pathname
		call	IACPPrepStrings		; ds:si <- filename
						; ds:dx = directory name
	;
	; Setup other parameters for the assembly call
	;
		push	bp			; for local vars
		mov	bx, ss:[disk]
		mov	ax, ss:[flags]
		movdw	cxbp, ss:[client]
		call	IACPConnectToDocumentServer
		mov_tr	ax, bp
		pop	bp			; restore for local vars

		.leave
		ret
IACPCONNECTTODOCUMENTSERVER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			IACPGETDOCUMENTID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the 48-bit ID for a data file, dealing with
		links.

CALLED BY:	(GLOBAL)
PARAMETERS:	dword _pascal IACPGetDocumentID(const char _far *pathname,
						const char _far *filename,
						DiskHandle *disk);

RETURN:		If successful returns a non-zero document id.

SIDE EFFECTS:	May change the disk handle passed in.  
                ie.  You pass in a StandardPath for the DiskHandle and
                it changes to a real disk handle.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	9 feb 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPGETDOCUMENTID	proc	far	pathname:fptr,
					filename:fptr,
					disk:fptr
tempPathname	local	PathName
tempFilename	local	FileLongName		
		uses	ds, si, di
		.enter
	;
	; Since these variables are messed with in IACPPrepStrings
	; we do this to get rid of warnings.
	;
		ForceRef	filename
		ForceRef	tempPathname
		ForceRef	tempFilename
	;
	; Make sure the strings are in the same segment
	;
		lea	di, pathname
		call	IACPPrepStrings		; ds:si <- filename
						; ds:dx = directory name
	;
	; Get the document id.
	;
		les	bx, ss:[disk]
		mov	bx, es:[bx]		; bx    <- disk handle
		call	IACPGetDocumentID
		mov_tr	bx, ax
		jnc	noError		

		mov	ax, FILE_NO_ID
		mov	dx, FILE_NO_ID
		clr	cx			; cx <- no disk handle
		jmp	done
noError:
		mov_tr	ax, dx
		mov	dx, cx
		mov	cx, bx			; cx <- disk handle
		clr	bx
done:
		lds	si, ss:[disk]
		mov	ds:[si], cx
		mov	ss:[TPD_error], bx
		.leave
		ret
IACPGETDOCUMENTID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPPrepStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine used to copy strings in the stack
		if they don't reside in the same segment.

CALLED BY:	IACPGETDOCUMENTID, IACPCONNECTTODOCUMENTSERVER
PASS:		di	= offset to pathname
		di+4	= offset to filename
RETURN:		ds:si	= filename
		ds:dx	= directory name
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ACJ	5/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPPrepStrings	proc	near		
		uses	ax, bx, cx, di, es
		.enter	inherit	IACPGETDOCUMENTID

	;
	; Load in the ptrs to the strings.
	;
		movdw	axdx, ss:[di]		; pathname
		movdw	bxsi, ss:[di-4]		; filename

	;
	; If the strings reside in the same segment, then
	; just procede as normal.  Otherwise we'll have to
	; copy them to the stack to make them in the same segment.
	;
		cmp	ax, bx
		mov	ds, ax
		jz	stringsInSameSeg

	;
	; Since the assembly routine expects the pathname and the filename
	; to be in the same segment, we copy the strings to the stack
	; and pass pointers to the copied strings.
	;
		; Precond:
		; ds:dx <- pathname
		xchg	si, dx			; ds:si <- pathname
						; bx:dx <- filename

		mov	cx, ss			; cx <- stack segment
		mov	es, cx			
		lea	di, ss:tempPathname	; es:di <- buffer
		LocalCopyString
		
		movdw	dssi, bxdx		; ds:si <- filename
		lea	di, ss:tempFilename	; es:di <- buffer
		LocalCopyString

		mov	ds, cx			; ds <- stack segment
		lea	dx, ss:tempPathname	; ds:bx <- pathname
		lea	si, ss:tempFilename	; ds:si <- filename

stringsInSameSeg:
		
		.leave
		ret
IACPPrepStrings	endp

if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
IACPCode  segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPFINISHCONNECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete a connection that's in limbo

CALLED BY:	(GLOBAL)
PARAMETERS:	void (IACPConnection connection, optr server)
SIDE EFFECTS:	Any messages queued pending switch to user-interactibility
		are delivered via the queue

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPFINISHCONNECT proc	far
		C_GetThreeWordArgs	ax, cx, dx, bx
		xchg	ax, bp
		call	IACPFinishConnect
		xchg	ax, bp
		ret
IACPFINISHCONNECT endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPSENDMESSAGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message through an IACP connection to all connected
		servers, or to the client, depending on which side is doing
		the sending.

CALLED BY:	(GLOBAL)
PARAMETERS:	word (IACPConnection connection, EventHandle msgToSend,
		      TravelOption, topt, EventHandle completionMsg,
		      IACPSide side)
RETURN:		the number of servers to which the message was actually
			sent. the completionMsg, if non-zero, will always
			be sent the number of times returned in *numServersPtr
			from IACPConnect, but not all servers may still be
			connected.
SIDE EFFECTS:	the recorded messages are freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPSENDMESSAGE	proc	far	connection:IACPConnection,
				msgToSend:hptr,
				topt:TravelOption,
				completionMsg:hptr,
				side:IACPSide
	on_stack	retf
		clc
IACPSENDMESSAGECOMMON label far
		.enter
	on_stack	bp retf
		mov	ax, ss:[side]
		mov	bx, ss:[msgToSend]
		mov	cx, ss:[completionMsg]
		mov	dx, ss:[topt]
		mov	bp, ss:[connection]
		jc	sendToServer
		call	IACPSendMessage
done:
		.leave
		ret
sendToServer:
		call	IACPSendMessageToServer
		jmp	done
IACPSENDMESSAGE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPSENDMESSAGEANDWAIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message through an IACP connection to all connected
		servers, or to the client, depending on which side is doing
		the sending, and wait for the other side to respond.

CALLED BY:	(GLOBAL)
PARAMETERS:	word (IACPConnection connection, EventHandle msgToSend,
		      TravelOption, topt, IACPSide side)
RETURN:		the number of servers to which the message was actually
			sent. the completionMsg, if non-zero, will always
			be sent the number of times returned in *numServersPtr
			from IACPConnect, but not all servers may still be
			connected.
SIDE EFFECTS:	the recorded messages are freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPSENDMESSAGEANDWAIT	proc	far	connection:IACPConnection,
				msgToSend:hptr,
				topt:TravelOption,
				side:IACPSide
		uses	di
		.enter

		mov	ax, ss:[side]
		mov	bx, ss:[msgToSend]
		clr	cx
		mov	dx, ss:[topt]
		mov	bp, ss:[connection]
		call	IACPSendMessageAndWait

		.leave
		ret
IACPSENDMESSAGEANDWAIT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPSENDMESSAGETOSERVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PARAMETERS:	word (IACPConnection connection, EventHandle msgToSend,
		      TravelOption, topt, EventHandle completionMsg,
		      word serverNum)
RETURN:		the number of servers to which the message was actually
			sent. the completionMsg, if non-zero, will always
			be sent the number of times returned in *numServersPtr
			from IACPConnect, but not all servers may still be
			connected.
SIDE EFFECTS:	the recorded messages are freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPSENDMESSAGETOSERVER proc	far
		stc
		jmp	IACPSENDMESSAGECOMMON
IACPSENDMESSAGETOSERVER		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPSHUTDOWN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shutdown one side of an IACP connection

CALLED BY:	(GLOBAL)
PARAMETERS:	void (IACPConnection connection, optr server)
RETURN:		nothing
SIDE EFFECTS:	MSG_META_IACP_LOST_CONNECTION is sent to the other side
     		    of the connection, if it's still around.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPSHUTDOWN	proc	far
		C_GetThreeWordArgs ax, cx, dx, bx
		push	bp
		mov_tr	bp, ax
		call	IACPShutdown
		pop	bp
		ret
IACPSHUTDOWN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPSHUTDOWNALL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shutdown all connections open to or from the given object.

CALLED BY:	(GLOBAL)
PARAMETERS:	void (optr obj)
RETURN:		nothing
SIDE EFFECTS:	all connections in which the object has an interest are
     		    placed off-limits to it.
		lots of MSG_META_IACP_LOST_CONNECTION messages may be sent

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPSHUTDOWNALL	proc	far
		C_GetOneDWordArg cx, dx, ax, bx
		call	IACPShutdownAll
		ret
IACPSHUTDOWNALL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPPROCESSMESSAGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a received message.

CALLED BY:	(GLOBAL)
PARAMETERS:	void (optr oself, EventHandle msgToSend, TravelOption topt,
		      EventHandle completionMsg)
RETURN:		nothing
SIDE EFFECTS:	the messages are dispatched and, eventually, freed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPPROCESSMESSAGE proc	far	oself:optr, 
				msgToSend:hptr,
				topt:TravelOption,
				completionMsg:hptr
		uses	ds, si, di
		.enter
		movdw	bxsi, ss:[oself]
		mov	cx, ss:[msgToSend]
		mov	dx, ss:[topt]
		mov	bp, ss:[completionMsg]
		call	MemDerefDS
		call	IACPProcessMessage
		.leave
		ret
IACPPROCESSMESSAGE endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLOSTCONNECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for server objects to handle
		MSG_META_IACP_LOST_CONNECTION

CALLED BY:	(GLOBAL)
PARAMETERS:	void (optr oself, IACPConnection connection)
RETURN:		nothing
SIDE EFFECTS:	queue-flushing messages are sent out; the object will
     		    eventually receive a MSG_META_IACP_SHUTDOWN_CONNECTION

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/92 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPLOSTCONNECTION proc	far oself:optr, connection:IACPConnection
		uses	ds, si, di
		.enter
		mov_tr	di, ax
		movdw	bxsi, ss:[oself]
		mov	bp, ss:[connection]
		call	MemDerefDS
		call	IACPLostConnection
		.leave
		ret
IACPLOSTCONNECTION endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPCREATEDEFAULTLAUNCHBLOCK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an AppLaunchBlock one can pass to IACPConnect
		presuming the following defaults:
			- IACP will locate the app, given its token
			- initial directory should be SP_DOCUMENT
			- no initial data file
			- application will determine generic parent for
			  itself
			- no one to notify in event of an error
			- no extra data

CALLED BY:	(GLOBAL)
PARAMETERS:	MemHandle (GenProcessMessages appMode)
RETURN:		handle of AppLaunchBlock, or 0 if it couldn't be allocated
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPCREATEDEFAULTLAUNCHBLOCK proc	far
		C_GetOneWordArg	dx, ax, bx
		call	IACPCreateDefaultLaunchBlock
		mov	ax, 0
		jc	done
		mov_tr	ax, dx
done:
		ret
IACPCREATEDEFAULTLAUNCHBLOCK		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPGETSERVERNUMBER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PARAMETERS:	word IACPGetServerNumber(IACPConnection connection,
				         optr server)
RETURN:		0 if server not a server for the connection, else a number
		suitable for passing to IACPSendMessageToServer
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPGETSERVERNUMBER proc	far
		C_GetThreeWordArgs	ax, cx, dx, bx
		push	bp
		mov	bp, bx
		call	IACPGetServerNumber
		pop	bp
		ret
IACPGETSERVERNUMBER		endp

SetDefaultConvention

IACPCode	ends

