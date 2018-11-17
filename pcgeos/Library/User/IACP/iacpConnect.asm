COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		iacpConnect.asm

AUTHOR:		Adam de Boor, Mar  9, 1993

ROUTINES:
	Name			Description
	----			-----------
    GLB IACPConnectToDocumentServer
				Connect to one or more servers on the
				indicated list.

    GLB IACPConnect		Connect to one or more servers on the
				indicated list.

    GLB IACPConnectCommon	Connect to one or more servers on the
				indicated list.

    GLB IACPConnectXIP		Connect to one or more servers on the
				indicated list.

    INT IACPAskUserForPermission
				Deal with launch-model cruft.

    INT IACPCheckAndLocateDocument
				See if the AppLaunchBlock mentions a
				document and locate its server object if it
				does.

    GLB IACPGetDocumentID	Figure the 48-bit ID for a data file,
				dealing with links.

 ?? none IACPGetDocumentConnectionFileID
				Returns the disk handle and 32-bit file ID
				of the file associated with an
				IACPConnection. If the passed connection
				was a normal (IACPConnect) connection,
				rather than a document
				(IACPConnectToDocumentServer) connection,
				an error is returned.

    GLB IACPGetDocumentIDXIP	Figure the 48-bit ID for a data file,
				dealing with links.

    INT IACPInstantiateServer	Create a server and wait for it to register

    INT IACPFindServerOwnedByCX	Locate a server object owned by the given
				geode.

    INT IACPLocateServerApp	Locate the application to serve a
				particular list.

    INT IACPLocateServerAppLow	Search the current directory for the server
				application.

    INT IACPLocateServerAppInIniFile
				Look in the [iacp] category for a key for
				the given token, filling in the necessary
				fields of the ALB if the key is found.

    INT IACPGenerateTokenKey	Generate the INI file key for a token.

    GLB IACPLocateServer	Locate the server application for a token.

    GLB IACPLocateServerXIP	Locate the server application for a token.

    GLB IACPLOCATESERVER	Locate the server application for a token.

    INT IACPBindUnbindCommon	Common code to save registers, setup the
				stack frame, generate the key, and set up
				registers for calling the InitFile code for
				binding & unbinding tokens.  NOTE: This is
				a coroutine, which calls its caller back
				right after the call to this routine. When
				the caller returns, this routine cleans up
				and then returns on behalf of the caller.

    GLB IACPBindToken		Associate a generic token with an
				executable under SP_APPLICATION or
				SP_SYS_APPLICATION

    GLB IACPBindTokenXIP	Associate a generic token with an
				executable under SP_APPLICATION or
				SP_SYS_APPLICATION

    GLB IACPBINDTOKEN		Associate a generic token with an
				executable under SP_APPLICATION or
				SP_SYS_APPLICATION

    GLB IACPUnbindToken		Remove the binding between a token and an
				application

    GLB IACPUnbindTokenXIP	Remove the binding between a token and an
				application

    GLB IACPUNBINDTOKEN		Remove the binding between a token and an
				application

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/ 9/93		Initial revision


DESCRIPTION:
	Code related to creating a connection
		

	$Id: iacpConnect.asm,v 1.1 97/04/07 11:47:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPConnectToDocumentServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to one or more servers on the indicated list.

CALLED BY:	(GLOBAL) and IACPConnectXIP

PASS:		ax	= IACPConnectFlags
		^lcx:bp	= client optr if IACPCF_CLIENT_OD_SPECIFIED
		bx - disk handle
		ds:dx = directory name
		ds:si = file name

RETURN:		carry set on error:
			ax	= IACPConnectError/GeodeLoadError
		carry clear if successful connection made:
			bp	= IACPConnection
			bx	= owner of first server to which you're
				  connected
			ax	= destroyed

DESTROYED:	bx, cx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10 jan 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPConnectToDocumentServer	proc	far
retVal		local	IACPConnection		push bp
connectFlags	local	IACPConnectFlags	push ax
clientHandle	local	hptr			push cx
clientChunk	local	lptr			push ax		; correct later

		mov	ax, bp			; client OD chunk

	uses	ds, es, di, si
	.enter

		mov	ss:[clientChunk], ax	; store client OD chunk

		mov	ss:[retVal], IACP_NO_CONNECTION	      ;how pessimistic.

	;
	;  See if the document's registered at all.
	;
		call	IACPGetDocumentID
		jc	done

	;
	;  Find the document in the document registry and track down
	;  its server.
	;
		call	IACPLockListBlockExcl
		clr	bx			; => don't check server
		call	IACPLocateDocument	; ax <- list elt #
		jnc	docNotFound		; not found, so use first app
						;  mode server

		mov	si, offset iacpDocArray
		call	ChunkArrayElementToPtr
		mov	si, ds:[di].IACPD_server.chunk
		mov	di, ds:[di].IACPD_server.handle

	;
	;  Pass it off to IACPConnect
	;

		push	ax			; save doc index
		mov	ax, IACPSM_NOT_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE
		push	bp			; save local ptr.
		mov	cx, ss:[clientHandle]
		mov	dx, ss:[clientChunk]
		mov	ax, mask IACPCF_FIRST_ONLY or IACPSM_NOT_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE
		test	ss:[connectFlags], mask IACPCF_CLIENT_OD_SPECIFIED
		jz	connect
		ornf	ax, mask IACPCF_CLIENT_OD_SPECIFIED
connect:
		call	IACPConnectCommon
		mov	di, bp			; di <- IACPConnection
		pop	bp			; ss:bp <- locals
		pop	si			; si <- doc index
		jc	done

	;
	;  Lock the connection down and stuff the document index into
	;  IACPCS_document.
	;
		
		mov	ss:[retVal], di

		call	IACPLockListBlockExcl
EC <		xchg	bp, di					>
EC <		call	IACPValidateConnection			>
EC <		xchg	bp, di					>
		mov	di, ds:[di]		; ds:di <- IACPConnectionStruct
		mov	ds:[di].IACPCS_document, si
		clc

unlockDone:
		call	IACPUnlockListBlockExcl

done:
		.leave
		ret

docNotFound:
		mov	ax, IACPCE_NO_SERVER
		stc
		jmp	unlockDone
IACPConnectToDocumentServer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to one or more servers on the indicated list.

CALLED BY:	(GLOBAL) and IACPConnectXIP
PASS:		es:di	= GeodeToken for list
		ax	= IACPConnectFlags
		^hbx	= AppLaunchBlock if server is to be launched,
			  should none be registered
		^lcx:dx	= client optr if IACPCF_CLIENT_OD_SPECIFIED
RETURN:		carry set on error:
			ax	= IACPConnectError/GeodeLoadError
		carry clear if successful connection made:
			bp	= IACPConnection
			bx	= owner of first server to which you're
				  connected
			cx	= number of servers connected to
			ax	= destroyed
		AppLaunchBlock freed, if passed non-zero
DESTROYED:	dx, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPConnect	proc	far
	uses	ds, si
	.enter
	mov	si, 0xffff
	call	IACPLockListBlockExcl
	call	IACPConnectCommon
	.leave
	ret
IACPConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPConnectCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to one or more servers on the indicated list.

CALLED BY:	(GLOBAL) and IACPConnectXIP

PASS:	For document (IACPConnectToDocumentServer) connection:

		^hdi:si = document server		
		ax	= IACPConnectFlags
		^lcx:dx	= client optr if IACPCF_CLIENT_OD_SPECIFIED
		ds	= locked IACPListBlock

	For normal (IACPConnect) connection:

		es:di	= GeodeToken for list
		ax	= IACPConnectFlags
		^hbx	= AppLaunchBlock if server is to be launched,
			  should none be registered
		^lcx:dx	= client optr if IACPCF_CLIENT_OD_SPECIFIED
		ds	= locked IACPListBlock

RETURN:		carry set on error:
			* IACPListBlock unlocked *
			ax	= IACPConnectError/GeodeLoadError
		carry clear if successful connection made:
			* IACPListBlock unlocked *
			bp	= IACPConnection
			bx	= owner of first server to which you're
				  connected
			cx	= number of servers connected to
			ax	= destroyed
		AppLaunchBlock freed, if passed non-zero

DESTROYED:	dx, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPConnectCommon	proc	far
retVal		local	IACPConnection		push bp
connectFlags	local	IACPConnectFlags	push ax
clientOD	local	optr			push cx, dx
alb		local	hptr			push bx
tokenPtr	local	fptr.GeodeToken		push es, di
docServer	local	optr			push di, si
justLaunched	local	word
listNum		local	word			; element of list w/in
						;  iacpListArray
nextServer	local	word			; element of server list to
;						;  examine next
serverList	local	word			; chunk of server list, to
						;  avoid frequent derefs of
						;  iacpListArray
forceConnect	local	byte			; non-zero if createConnection
						;  must always connect to
						;  server si regardless of
						;  mode.
askUser		local	byte
documentConnect	local	byte
geodeToken	local	GeodeToken
holdQueue	local	hptr			; hold-up queue for new
						;  connection
		uses	ds, es, di, si
		.enter
		ForceRef tokenPtr

		mov	ss:[documentConnect], 0
		cmp	si, 0xffff
		je	afterDoc
		
		mov	ss:[documentConnect], 0xff
		mov	ax, si

	;
	; Get the thread/process handle
	;
		mov	bx, di
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
		mov_tr	bx, ax
		call	MemOwner

		mov	ax, GGIT_TOKEN_ID
		segmov	es, ss
		lea	di, ss:[geodeToken]
		call	GeodeGetInfo

		movdw	ss:[tokenPtr], esdi

afterDoc:
		mov	{word}ss:[askUser], FALSE
			CheckHack <offset forceConnect eq offset askUser+1>
		mov	ss:[holdQueue], 0
	;
	; Change the AppLaunchBlock to be owned by the UI, so it doesn't go
	; away at an inopportune moment.
	; 
		tst	bx
		jz	findList
		push	ax
		mov	ax, handle 0
		call	HandleModifyOwner
		pop	ax
findList:
if 0		; the list block is now passed in locked.
		call	IACPLockListBlockExcl
endif

		tst	ss:[documentConnect]
		jnz	locateDocServer

		call	IACPFindList
		LONG jnc	toMaybeInstantiate
	;
	; Figure the number of servers registered with the list.
	; 
		push	di
		mov	si, offset iacpListArray
		call	ChunkArrayElementToPtr	; ds:di <- IACPList
		mov	si, ds:[di].IACPL_servers
		call	ChunkArrayGetCount	; cx <- # servers
		pop	di
		jcxz	toMaybeInstantiate

		clr	si
		mov	ss:[justLaunched],si
	;
	; If document in ALB, first priority is locating server w/doc open.
	; 
		call	IACPCheckAndLocateDocument
		jc	createConnection	; => found server for the
						;  thing (sets forceConnect
						;  and IACPCF_FIRST_ONLY)

;*
;* JON: Adam's message about needing to find the application object if
;*      IACPSM_USER_INTERACTIBLE was passed.
;*
	;
	; Set askUser if app-mode connection requested and AppLaunchBlock
	; passed and we're supposed to pay attention to the launch model.
	; 
		tst	bx
		jz	createConnection

		mov	dx, ss:[connectFlags]
		test	dx, mask IACPCF_OBEY_LAUNCH_MODEL
		jz	createConnection
EC <		test	dx, mask IACPCF_FIRST_ONLY		>
EC <		ERROR_Z	MUST_CONNECT_TO_FIRST_ONLY_IF_OBEYING_LAUNCH_MODEL >
EC <		andnf	dx, mask IACPCF_SERVER_MODE		>
EC <		cmp	dx, IACPSM_USER_INTERACTIBLE shl \
   				offset IACPCF_SERVER_MODE	>
EC <		ERROR_B	MUST_CONNECT_IN_APP_MODE_IF_OBEYING_LAUNCH_MODEL>

		mov	ss:[askUser], TRUE

createConnection:
	; Options:
	; 	- have doc: connect to server whose index is in si
	; 	- connect to only those servers in appropriate mode
	; 	- if none (doc server not) in appropriate mode, connect to
	;	  first only (doc server) & create queue to receive messages
	;	  until IACPFinishConnect is called.
	;
	; ax = index of IACPList element
	; bx = handle of ALB
	; si = index of optr to use if IACPCF_FIRST_ONLY set.
	; cx = number of servers on the list
	; bp = frame pointer
	; 

	;
	; Save the app launch block handle for notifying the servers.
	; 
		test	ss:[connectFlags], mask IACPCF_FIRST_ONLY
		jz	useAllServers
		jmp	allocConnection

locateDocServer:

		call	IACPFindList
		jnc	docNotFound

	;
	; Fetch the server OD from the document registry and locate its
	; index within the server list.
	; 

		mov	si, offset iacpListArray
		call	ChunkArrayElementToPtr	; ds:di <- IACPList
		mov	si, ds:[di].IACPL_servers

		push	ax
		movdw	cxdx, ss:[docServer]
		clr	ax
		mov	bx, cs
		mov	di, offset IACPFindServer
		call	ChunkArrayEnum
		mov_tr	si, ax
		pop	ax
EC <		WARNING_NC	SERVER_FOR_DOCUMENT_NOT_REGISTERED	>
		jnc	docNotFound

		ornf	ss:[connectFlags], mask IACPCF_FIRST_ONLY
		jmp	allocConnection

docNotFound:
		mov	ax, IACPCE_NO_SERVER

		call	IACPUnlockListBlockShared
		stc
		jmp	done

toMaybeInstantiate:
		jmp	maybeInstantiate

useAllServers:
		clr	si		; override index of server to use, as
					;  want all servers, thanks.
allocConnection:
		mov	ss:[nextServer], si
	;
	; Allocate the IACPConnectionStruct. The room for the server optrs will
	; be appended as each server is found.
	; 
		mov	ss:[listNum], ax; save list # for initializing after
					;  the LMemAlloc
		mov	cx, size IACPConnectionStruct
		call	LMemAlloc

		mov	ss:[retVal], ax
		mov_tr	bx, ax		; *ds:bx <- IACPConnectionStruct
		mov	bx, ds:[bx]

		mov	ds:[bx].IACPCS_holdQueue, 0
		mov	ds:[bx].IACPCS_document, CA_NULL_ELEMENT
	;
	; Link into list of connections for the list.
	; 
		mov	ax, ss:[listNum]; ax <- IACPList #
		mov	si, offset iacpListArray
		call	ChunkArrayElementToPtr

		inc	ds:[di].IACPL_numConnect
		mov	ax, ss:[retVal]
		xchg	ax, ds:[di].IACPL_connections
		mov	ds:[bx].IACPCS_next, ax
	;
	; Save server array handle away while it's convenient.
	; 
		mov	ax, ds:[di].IACPL_servers
		mov	ss:[serverList], ax
	;
	; Store the optr of the client object.
	; 
		push	bx
		movdw	bxsi, ss:[clientOD]
		test	ss:[connectFlags], mask IACPCF_CLIENT_OD_SPECIFIED
		jnz	haveClient
		clr	bx
		call	GeodeGetAppObject	; ^lbx:si <- app obj
haveClient:
EC <		call	ECCheckOD					>
		mov_tr	ax, bx
		pop	bx
		mov	ds:[bx].IACPCS_client.handle, ax
		mov	ds:[bx].IACPCS_client.chunk, si
	;
	; Loop through all servers looking for those in the appropriate mode
	; 
serverLoop:
		mov	ax, ss:[nextServer]
		mov	si, ss:[serverList]
		call	ChunkArrayElementToPtr	; ds:di <- IACPServer

		mov	dx, ss:[connectFlags]
		andnf	dl, mask IACPCF_SERVER_MODE
			CheckHack <offset IACPCF_SERVER_MODE eq 0>

		mov	dh, ds:[di].IACPS_mode	; dh <- this server's mode,
						;  so we know if we need to
						;  allocate a hold-up queue
	;
	; If this server's an IACPSM_NON_APPLICATION, then we don't
	; want to connect to it. 
	;
		tst	ss:[documentConnect]
		jnz	connectToThisOne

;;;		cmp	dh, IACPSM_NON_APPLICATION
;;;		je	nextServerLoop

		cmp	dl, dh
		jbe	checkUser		; server in higher or requested
						;  mode, so it's ok

	;
	; This one's in the wrong mode. If not forced to connect to it, don't
	; 
		tst	ss:[forceConnect]
		jz	nextServerLoop
		
checkUser:
		tst	ss:[askUser]
		jz	connectToThisOne
		
		call	IACPAskUserForPermission
		jc	serverLoop		; => user/system wants new copy,
						;  so go back to the start. All
						;  local vars have been suitably
						;  modified...
connectToThisOne:
	;
	; Found a server to connect to. Save the relevant things on the stack
	; while we make room in the connection structure.
	; 
		push	dx
		pushdw	ds:[di].IACPS_object
	;
	; Insert room for an optr at the end.
	; 
		mov	bx, ss:[retVal]
		ChunkSizeHandle ds, bx, ax
		xchg	ax, bx		; ax <- chunk, bx <- insert point
		mov	cx, size optr
		call	LMemInsertAt
	;
	; Store the optr at the end.
	; 
		mov_tr	di, ax
		mov	di, ds:[di]
		popdw	({optr}ds:[di][bx])
	;
	; See if we need to allocate a hold queue for this connection.
	; 
		pop	dx

		tst	ss:[documentConnect]
		jnz	checkFirstOnly

		cmp	dl, dh
		jbe	checkFirstOnly	; server in proper mode

		tst	ss:[holdQueue]
		jnz	checkFirstOnly	; queue already allocated
		
		call	GeodeAllocQueue
	;
	; Change ownership of queue to the UI, as it may need to outlast
	; the client calling IACPConnect.  -- Doug 3/18/93
	;
		mov	ax, handle 0
		call	HandleModifyOwner

		mov	ss:[holdQueue], bx

checkFirstOnly:
	;
	; If IACPCF_FIRST_ONLY set, stop looping, as we're connected to the
	; first viable candidate.
	; 
		test	ss:[connectFlags], mask IACPCF_FIRST_ONLY
		jnz	notifyServers

nextServerLoop:
	;
	; Advance to the next server in the list.
	; 
		mov	ax, ss:[nextServer]
		inc	ax
		mov	ss:[nextServer], ax

		mov	si, ss:[serverList]
		call	ChunkArrayGetCount
		cmp	ax, cx
		LONG jb	serverLoop
	;
	; Went all the way through the server array for the IACP list. See
	; if we actually connected to anything.
	; 
		mov	bx, ss:[retVal]
		ChunkSizeHandle	ds, bx, ax
		cmp	ax, size IACPConnectionStruct
		jne	notifyServers
	;
	; No. Forcibly connect to the first server in the list, making sure
	; we don't bug the user about it. The beast will have to switch to
	; app mode...
	; 
		mov	ss:[nextServer], 0
		mov	ss:[forceConnect], TRUE
		ornf	ss:[connectFlags], mask IACPCF_FIRST_ONLY
		mov	ss:[askUser], FALSE
		jmp	serverLoop

	;--------------------
notifyServers:
	;
	; We are now connected to all the servers to which we want to be
	; connected. Now we need to let them know the connection exists.
	; Note that sometimes this will force the thing into the lengthy
	; process of switching from engine mode to app mode. If we're in one
	; of these cases, we've already allocated a queue on which all
	; messages other than these new_connection messages will be held until
	; the switch is complete.
	; 

		mov	bx, ss:[retVal]
		ChunkSizeHandle	ds, bx, ax
		sub	ax, size IACPConnectionStruct
		shr	ax
		shr	ax		; ax <- # servers

		mov	si, ds:[bx]					
EC <		tst	ds:[si].IACPCS_holdQueue			>
EC <		jz	queueOK						>
EC <		cmp	ax, 1						>
EC <		ERROR_NE CANNOT_HOLD_UP_IACP_MESSAGES_FOR_MORE_THAN_ONE_SERVER>
EC <queueOK:								>

		push	ax			; save for return
		xchg	bx, si			; *ds:si <- connection

		mov	bx, ds:[bx].IACPCS_servers[0].handle
		call	MemOwner		; fetch owner of first server
						;  for return.
		push	bx

		mov	cx, ss:[alb]		; cx <- ALB handle, for both
						;  messages...

	;
	; 3/11/93: downgrade lock from exclusive to shared, but keep it shared
	; during the sending of notification so a server can't unregister.
	; 
		mov	bx, handle IACPListBlock
		push	ax			; will get trashed!!
		call	MemDowngradeExclLock
		pop	ax

		clr	di			; assume no completion msg
		jcxz	haveCompletionMsg	; => no ALB, so no c.m. needed

		mov	bx, cx			; bx <- ALB
		call	MemInitRefCount		; set ref count on block to the
						;  number of servers, so
						;  free msg can just call
						;  MemDecRefCount

		mov	ax, MSG_META_DEC_BLOCK_REF_COUNT
		clr	dx			; no second block
		mov	bx, handle 0
		mov	di, mask MF_RECORD
		call	ObjMessage		; di <- completion message
	;
	; 3/16/93: since the app isn't expecting this message, it won't wait
	; around for it to come back, which means it could go away before the
	; thing ever gets sent, leading to death. Soooo, since the dest of the
	; message is the ui, we change the thing to be owned by the ui as well.
	;  		-- ardeb
	;  
		mov_tr	ax, bx
		mov	bx, di
		call	HandleModifyOwner
haveCompletionMsg:
		push	bp			; save frame pointer, as we'll
						;  be abusing it momentarily

	;
	; Now set up the notification message.
	; 
		clr	bx, si			; null class for TO_SELF
		push	di			; save completion msg
		mov	ax, MSG_META_IACP_NEW_CONNECTION
		mov	dx, ss:[justLaunched]	; dx <- justLaunched flag
		mov	bp, ss:[retVal]		; bp <- connection
		mov	di, mask MF_RECORD
		call	ObjMessage
	;
	; Finally, send the message to the servers using standard
	; IACPSendMessage routine, after clearing the holdQueue variable
	; temporarily (since we've not returned the connection yet, this should
	; be safe to do).
	; 
		mov	bx, di
		pop	cx			; cx <- completion msg
		mov	dx, TO_SELF
		mov	ax, IACPS_CLIENT
		call	IACPSendMessage

		pop	bp			; bp <- frame pointer;
						;  connection loaded into bp
						;  by .leave
		tst	ss:[holdQueue]
		jz	doneOK
	;
	; Need to set the hold queue for the connection.
	; 
		mov	bx, handle IACPListBlock
		call	MemUpgradeSharedLock
		mov	ds, ax
		mov	si, ss:[retVal]
		mov	si, ds:[si]
		mov	ax, ss:[holdQueue]
EC <		tst	ax						>
EC <		jz	10$						>
EC <		xchg	bx, ax						>
EC <		call	ECCheckQueueHandle				>
EC <		xchg	bx, ax						>
EC <10$:								>
		mov	ds:[si].IACPCS_holdQueue, ax
		call	MemDowngradeExclLock

doneOK:
		pop	bx			; bx <- owner of first server
		pop	cx			; cx <- # servers

		call	IACPUnlockListBlockShared
		clc				; happiness
done:
		.leave
		ret

maybeInstantiate:
	;
	; es:di	= GeodeToken
	; ^hbx	= ALB/0
	; bp = frame pointer
	;
	; Release the IACPListBlock now so the system can continue about
	; its business while we go on a quest for the app.
	; 
		clr	cx			; instantiate if not already
						;  there by the time the
						;  semaphore is grabbed.
		call	IACPInstantiateServer
		jc	done
		jmp	createConnection
IACPConnectCommon	endp

if FULL_EXECUTE_IN_PLACE

IACPCommon	ends

ResidentXIP	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPConnectXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to one or more servers on the indicated list.

CALLED BY:	(GLOBAL)
PASS:		es:di	= GeodeToken for list
		ax	= IACPConnectFlags
		^hbx	= AppLaunchBlock if server is to be launched,
			  should none be registered
		^lcx:dx	= client optr if IACPCF_CLIENT_OD_SPECIFIED
RETURN:		carry set on error:
			ax	= IACPConnectError/GeodeLoadError
		carry clear if successful connection made:
			bp	= IACPConnection
			bx	= owner of first server to which you're
				  connected
			cx	= number of servers connected to
			ax	= destroyed
		AppLaunchBlock freed, if passed non-zero
DESTROYED:	dx, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPConnectXIP	proc	far
		uses	es, di
		.enter

		call	IACPCopyGeoTokenToStackESDI	;es:di = GeodeToken in stack
		call	IACPConnect		
		call	SysRemoveFromStack
		
		.leave
		ret
IACPConnectXIP	endp

ResidentXIP	ends

IACPCommon	segment	resource

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPAskUserForPermission
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with launch-model cruft.

CALLED BY:	(INTERNAL) IACPConnect
PASS:		ds:di	= IACPServer
		ss:bp	= inherited stack frame
RETURN:		carry set if new instance launched:
			ss:[nextServer]	= index of server
			ss:[forceConnect] = TRUE
			ss:[askUser]	= FALSE
DESTROYED:	ax, bx, cx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPAskUserForPermission proc	near
		uses	es, di, dx
		.enter	inherit IACPConnectCommon
		test	ds:[di].IACPS_flags, mask IACPSF_MULTIPLE_INSTANCES
		LONG jz	done		; => must use this instance

	;
	; Check the ALB to see if there's an override.
	; 
		mov	bx, ss:[alb]
		call	MemLock
		mov	es, ax
		test	es:[ALB_launchFlags], 
				mask ALF_OVERRIDE_MULTIPLE_INSTANCE
		call	MemUnlock
		LONG jnz useThisOne
	;
	; Check the current launch model.
	; 
	CheckHack <UILM_TRANSPARENT lt UILM_MULTIPLE_INSTANCES and \
		   UILM_SINGLE_INSTANCE lt UILM_MULTIPLE_INSTANCES and \
		   UILM_GURU gt UILM_MULTIPLE_INSTANCES>

		segmov	es, dgroup, ax
		cmp	es:[uiLaunchModel], UILM_MULTIPLE_INSTANCES
		LONG jb	useThisOne
		LONG ja	launchNew
	;
	; Need to ask the user. First figure the prompt string to use.
	; 
		call	MemLock
		mov	es, ax		; es <- ALB
		mov	si, offset openDocInRunningApp
		mov	di, offset ALB_dataFile
SBCS <		tst	{char}es:[di]					>
DBCS <		tst	{wchar}es:[di]					>
		jnz	haveStrings
		
		tst	es:[ALB_appRef].AIR_diskHandle
		jnz	haveServerSoGetName
	;
	; Want server name, but nothing in the ALB for it, so search for the
	; thing in the normal way.
	; 
		push	ds
		segmov	ds, es
		les	di, ss:[tokenPtr]
		
		call	IACPLocateServerApp

		segmov	es, ds		; es <- ALB again
		pop	ds
		jnc	haveServerSoGetName
	;
	; Couldn't find server, so we won't be able to launch the thing even
	; if the user asks us to. Just use the one already known.
	; 
		call	MemUnlock
		jmp	useThisOne

haveServerSoGetName:
	;
	; Find the end of the path to the application.
	; 
		mov	di, offset AIR_fileName
		mov	cx, -1
SBCS <		clr	al						>
DBCS <		clr	ax						>
		LocalFindChar			;repne scasb/scasw
		not	cx
		LocalPrevChar esdi
	;
	; Look for the final backslash in the name.
	; 
		mov	al, '\\'		;OK for DBCS (ah==0)
		std
		LocalFindChar 			;repne scasb/scasw
		cld
		jne	pointToStart	; => di points to char before
					;  AIR_fileName
	;
	; found backslash -- di points below it, and we need it to point
	; after it, so we need two increments, not just one.
	; 
		LocalNextChar esdi
pointToStart:
		LocalNextChar esdi

		mov	si, offset appAlreadyRunning

haveStrings:
	; es:di = \1 for string
	; *Strings:si = message string
	; 
		push	bp
		sub	sp, size StandardDialogParams
		mov	bp, sp
		movdw	ss:[bp].SDP_stringArg1, esdi
		mov	bx, handle Strings
		call	MemLock
		mov	es, ax
		assume	es:Strings
		mov	ax, es:[si]
		movdw	ss:[bp].SDP_customString, esax
		mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags <
			1,			; CDBF_SYSTEM_MODAL
			CDT_QUESTION,		; CDBF_DIALOG_TYPE
			GIT_AFFIRMATION,	; CDBF_INTERACTION_TYPE
		0>
		clr	ss:[bp].SDP_helpContext.segment
		; XXX: deadlock potential here if called, e.g., from process
		; thread while app obj of process is attempting to register or
		; some such.
		call	UserStandardDialog

		call	MemUnlock
		pop	bp
		mov	bx, ss:[alb]
		call	MemUnlock
		assume	es:nothing
	;
	; If the answer was no (don't use the already-running copy), launch a
	; new instance.
	; 
		cmp	ax, IC_NO
		jne	useThisOne
launchNew:
		les	di, ss:[tokenPtr]
		mov	bx, ss:[alb]
		mov	cx, TRUE		; force instantiation
		call	IACPInstantiateServer
		cmc
		jnc	done

		mov	ss:[listNum], ax	; list might have moved...
		mov	ss:[nextServer], si	; store server number
		mov	ss:[askUser], FALSE	; don't ask the user next time
		mov	ss:[forceConnect], TRUE	; always connect to this thing
done:
		.leave
		ret
useThisOne:
		clc
		jmp	done
IACPAskUserForPermission endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPCheckAndLocateDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the AppLaunchBlock mentions a document and locate its
		server object if it does.

CALLED BY:	(INTERNAL) IACPConnect
PASS:		ds	= IACPListBlock
		^hbx	= AppLaunchBlock
		ax	= element # of IACPList within iacpListArray
		ss:bp	= inherited stack frame
RETURN:		carry set if document mentioned and registered:
			ss:[forceConnect]	= true
			IACPCF_FIRST_ONLY set in connectFlags
			si	= index of IACPServer entry in list of servers
				  for the list
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPCheckAndLocateDocument proc	near
		uses	es, ax, bx
		.enter	inherit IACPConnectCommon
		
		tst	bx
		LONG jz	done		; (carry clear)

		mov	ss:[listNum], ax	; save for later
		call	MemLock
		mov	es, ax
		cmp	es:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION
		je	checkDoc
		tst_clc	es:[ALB_appMode]
		jnz	unlockFail
checkDoc:
		tst_clc	es:[ALB_dataFile][0]
		jnz	getDataFileID
unlockFail:
		call	MemUnlock
		jmp	done

getDataFileID:
EC <		test	ss:[connectFlags], mask IACPCF_FIRST_ONLY	>
EC <		ERROR_Z	FIRST_ONLY_MUST_BE_SET_IF_DOCUMENT_SPECIFIED	>
		push	ds, si, bx
		mov	ds, ax
		mov	dx, offset ALB_path
		mov	si, offset ALB_dataFile
		mov	bx, ds:[ALB_diskHandle]
		call	IACPGetDocumentID	; ax <- disk handle, cxdx <- id
		pop	ds, si, bx
		call	MemUnlock
		jc	bleah

		clr	bx			; => don't check server
		call	IACPLocateDocument	; ax <- list elt #
		jnc	done			; not found, so use first app
						;  mode server

	;
	; Fetch the server OD from the document registry and locate its
	; index within the server list.
	; 
		mov	si, offset iacpDocArray
		call	ChunkArrayElementToPtr
		movdw	cxdx, ds:[di].IACPD_server
		
		mov	ax, ss:[listNum]
		mov	si, offset iacpListArray
		call	ChunkArrayElementToPtr
		mov	si, ds:[di].IACPL_servers
		clr	ax
		mov	bx, cs
		mov	di, offset IACPFindServer
		call	ChunkArrayEnum
EC <		WARNING_NC	SERVER_FOR_DOCUMENT_NOT_REGISTERED	>
		jnc	bleah			; server won't be able to
						;  handle the doc, but it'll
						;  be better able to whine at
						;  the user about it.
	;
	; Return the beastie's index in si, flagging the connection to that
	; server as being mandatory, regardless of mode.
	; 
		mov_tr	si, ax
		mov	ss:[forceConnect], TRUE
		stc
done:
		.leave
		ret
bleah:
		clr	si		; return si 0, as it was passed
					;  (also clears carry)
		jmp	done
IACPCheckAndLocateDocument		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPGetDocumentID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the 48-bit ID for a data file, dealing with
		links.

CALLED BY:	(GLOBAL) IACPCheckAndLocateDocument
PASS:		ds:dx	= directory in which file resides
		bx	= disk on which file resides
		ds:si	= file name
RETURN:		carry set on error
			ax	= FileError
			cx, dx	= destroyed
		carry clear if successful:
			ax	= disk handle
			cxdx	= FileID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDataFileIDParams	struct
    GDFIDP_fead		FileExtAttrDesc	3 dup(<>)
    GDFIDP_attrs	FileAttrs
    			even
    GDFIDP_disk		word
    GDFIDP_id		FileID
GetDataFileIDParams	ends

IACPGetDocumentID proc	far
		uses	ds, di, es, bp, bx, si
		.enter
	;
	; Allocate room for the 6 bytes that make up the id
	; 
		sub	sp, size GetDataFileIDParams
	;
	; Allocate room for the two FileExtAttrDescs and fill them in.
	; Disk handle comes back in low word, with file ID in high 2 words
	; 
	; 
		mov	bp, sp

		mov	ss:[bp].GDFIDP_fead[0*FileExtAttrDesc].FEAD_attr,
				FEA_DISK
		lea	di, ss:[bp].GDFIDP_disk
		movdw	ss:[bp].GDFIDP_fead[0*FileExtAttrDesc].FEAD_value, ssdi
		mov	ss:[bp].GDFIDP_fead[0*FileExtAttrDesc].FEAD_size,
				size word
		
		mov	ss:[bp].GDFIDP_fead[1*FileExtAttrDesc].FEAD_attr,
				FEA_FILE_ID
		lea	di, ss:[bp].GDFIDP_id
		movdw	ss:[bp].GDFIDP_fead[1*FileExtAttrDesc].FEAD_value, ssdi
		mov	ss:[bp].GDFIDP_fead[1*FileExtAttrDesc].FEAD_size,
				size FileID

		mov	ss:[bp].GDFIDP_fead[2*FileExtAttrDesc].FEAD_attr,
				FEA_FILE_ATTR
		lea	di, ss:[bp].GDFIDP_attrs
		movdw	ss:[bp].GDFIDP_fead[2*FileExtAttrDesc].FEAD_value, ssdi
		mov	ss:[bp].GDFIDP_fead[2*FileExtAttrDesc].FEAD_size,
				size FileAttrs
	;
	; Push to directory in the ALB.
	; 
		call	FilePushDir
		call	FileSetCurrentPath
		
		jc	fail
	;
	; Get the extended attrs for the data file.
	; 
		lea	di, ss:[bp].GDFIDP_fead
		segmov	es, ss
		mov	ax, FEA_MULTIPLE
		mov	cx, length GDFIDP_fead
		mov	dx, si
		call	FileGetPathExtAttributes
haveAttrs:
		jc	fail
		
		test	ss:[bp].GDFIDP_attrs, mask FA_LINK
		jnz	getTargetAttrs

		call	FilePopDir
	;
	; Clear off the FEADs
	; 
		lea	sp, ss:[bp].GDFIDP_disk
	;
	; Pop the return values off the stack.
	; 
		CheckHack <GDFIDP_disk eq GetDataFileIDParams-6>
		pop	ax
		popdw	cxdx
done:
		.leave
		ret
fail:
		call	FilePopDir
		lea	sp, ss:[bp+size GetDataFileIDParams]
		jmp	done

getTargetAttrs:
	;
	; Blech. File is a link. Construct the actual path and get its
	; attributes instead.
	; 
		mov	ax, size PathName
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jc	noMem
		push	bx
		mov	es, ax
		clr	di			; es:di <- buffer
						; ds:si = tail
		clr	bx			; use cwd
		mov	cx, size PathName	; cx <- buffer size
		clr	dx			; no drive name
		call	FileConstructActualPath
		jc	linkStuffDone

	;
	; Switch to root of disk with actual path.
	; 
		segmov	ds, cs
		mov	dx, offset rootPath
		call	FileSetCurrentPath
	;
	; Fetch the attributes for the actual path, now.
	; 
		segmov	ds, es
		clr	dx			; ds:dx <- actual path
		segmov	es, ss
		lea	di, ss:[bp].GDFIDP_fead	; es:di <- attr array
		mov	cx, length GDFIDP_fead
		mov	ax, FEA_MULTIPLE
		call	FileGetPathExtAttributes

linkStuffDone:
		pop	bx
		pushf			; save error flag
		call	MemFree
		popf
		jmp	haveAttrs

noMem:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	fail

LocalDefNLString rootPath <C_BACKSLASH, 0>
IACPGetDocumentID endp

if 0	; needs the document registry to be an element array, coming soon.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			IACPGetDocumentConnectionFileID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the disk handle and 32-bit file ID of the file
		associated with an IACPConnection. If the passed connection
		was a normal (IACPConnect) connection, rather than a
		document (IACPConnectToDocumentServer) connection, an error
		is returned.

PASS:		bp - the IACPConnection

RETURN:		carry clear if successful
			bx - disk handle
			cxdx - 32-bit file ID

		carry set if error

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	31 jan 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPGetDocumentConnectionFileID	proc	far
		uses	ax, bp, di, si
		.enter

		call	IACPLockListBlockExcl
EC <		call	IACPValidateConnection			>
		mov	bp, ds:[bp]		; ds:bp <- IACPConnectionStruct
		mov	ax, ds:[bp].IACPCS_document
		cmp	ax, CA_NULL_ELEMENT
		stc				; assume not doc.
		jz	unlockBlock

		mov	si, offset iacpDocArray
		call	ChunkArrayElementToPtr	; carry set properly for return

		mov	bx, ds:[di].IACPD_disk
		movdw	cxdx, ds:[di].IACPD_id

unlockBlock:
		call	IACPUnlockListBlockExcl

		.leave
		ret
IACPGetDocumentConnectionFileID	endp

endif

if FULL_EXECUTE_IN_PLACE

IACPCommon	ends

ResidentXIP	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPGetDocumentIDXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the 48-bit ID for a data file, dealing with
		links.

CALLED BY:	(GLOBAL) IACPCheckAndLocateDocument
PASS:		ds:dx	= directory in which file resides
		bx	= disk on which file resides
		ds:si	= file name
RETURN:		carry set on error
			ax	= FileError
			cx, dx	= destroyed
		carry clear if successful:
			ax	= disk handle
			cxdx	= FileID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPGetDocumentIDXIP	proc	far
		uses	si, ds, es
		.enter
	;
	; Copy the directory and file name onto the stack
	;
		segmov	es, ds, cx		;es:si = ptr to filename
		clr	cx			;cx = null-terminated str
		call	SysCopyToStackDSSI	;ds:si = filename on stack
		push	si			;save offset to filename
		segmov	ds, es, si
		mov	si, dx			;ds:si = ptr to dir str
		call	SysCopyToStackDSSI	;ds:si = dir str on stack
		mov	dx, si			;ds:dx = dir str on stack
		pop	si			;ds:si = filename on stack

	; Make the real call
		call	IACPGetDocumentID

	;
	; Restore the stack
		call	SysRemoveFromStack
		call	SysRemoveFromStack
		.leave
		ret
IACPGetDocumentIDXIP	endp

ResidentXIP	ends

IACPCommon	segment	resource

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPInstantiateServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a server and wait for it to register

CALLED BY:	(INTERNAL) IACPConnect
PASS:		es:di	= GeodeToken
		^hbx	= ALB or 0
		cx	= non-zero to force instantiation, else this will
			  check one last time, after grabbing
			  iacpInstantiateSem, before performing the load.
		*ss:[alb] = same
		bp	= inherited frame pointer
RETURN:		carry set on error:
			ax	= IACPConnectError
			any passed ALB freed
		carry clear if ok:
			ax	= IACPList element #
			si	= offset of server record in list
			ds	= locked IACPListBlock
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPInstantiateServer proc	near
		.enter	inherit IACPConnectCommon
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
			
		call	IACPUnlockListBlockExcl

		tst	bx
		jnz	haveALB
		mov	ax, IACPCE_NO_SERVER
		stc
		jmp	exit

haveALB:
	;
	; See if the caller provided the path to the application, as indicated
	; by a non-zero disk handle.
	; 
		call	MemLock
		mov	ds, ax
		tst	ds:[ALB_appRef].AIR_diskHandle
		jnz	haveApp
		call	IACPLocateServerApp	; (frees ALB on error)
		LONG jc	exit
		; XXX: HERE'S WHERE ONE MIGHT HOOK INTO THE NETWORK, BUT NEED
		; SOME INDICATION BACK FROM IACPLocateServerApp THAT IT'S
		; TAKEN CARE OF THE CONNECTION
haveApp:
		call	MemUnlock
		segmov	ds, dgroup, ax
		PSem	ds, iacpInstantiateSem

		jcxz	checkForServer

doInstantiate:
		mov	bx, ss:[alb]
		call	IACPDuplicateALB; dx <- old, bx <- new
		xchg	bx, dx

	; NEED TO DUPLICATE ALB FOR NOTIFICATION HERE.

		clr	ah		; launch now
		clr	cx		; use launch method in ALB
		mov	si, -1		; get path from ALB
		call	UserLoadApplication
		jc	loadFailed
	;
	; Now that app's been loaded, wait for it to register.
	; 
		mov	cx, bx		; cx <- geode handle
waitLoop:
	;
	; Block on iacpInstantiateQueue. We'll get woken up each time a
	; server registers anywhere.
	; 
		mov	ax, dgroup
		mov	bx, offset iacpInstantiateQueue
		call	ThreadBlockOnQueue
	;
	; Gain exclusive access to the list block and look for the list again.
	; 
checkForServer:
		call	IACPLockListBlockExcl	; ds <- IACPListBlock
		call	IACPFindList
		jc	foundList

waitNext:
		call	IACPUnlockListBlockExcl	; ds <- garbage
		jcxz	doInstantiate
		jmp	waitLoop

foundList:
	;
	; Look for a server object that's owned by the app we started.
	; 
		mov	dx, ax		; save list elt #, but still need it in
					;  ax for ElementToPtr...
		push	di
		mov	si, offset iacpListArray
		call	ChunkArrayElementToPtr
		mov	si, ds:[di].IACPL_servers
		mov	bx, cs
		mov	di, offset IACPFindServerOwnedByCX
		clr	ax		; start at 0
		call	ChunkArrayEnum
		pop	di
		jnc	waitNext	; => no server owned by app, so keep
					;  waiting
	;
	; Found one. Its index is in AX. Now go establish the connection.
	; 
		mov_tr	si, ax		; si <- index of server to use if
					;  IACPCF_FIRST_ONLY
		jcxz	instantiateDone	; => server was registered before we
					;  got a chance to load it, so not
					;  justLaunched
		mov	ss:[justLaunched], TRUE
instantiateDone:
		mov_tr	ax, dx		; ax <- IACPList elt #
		clc
		jmp	done

loadFailed:
	;
	; Couldn't load the server app. Clean up and boogie, returning
	; GeodeLoadError we got back as our own error code.
	; 
		mov	bx, ss:[alb]	; bx <- duplicate ALB
		call	MemFree		; nuke it
		stc
done:
	;
	; Release the instantiation semaphore, making sure ds is pointing
	; to the right place. Doesn't affect carry flag or AX
	; 
		push	ds
		segmov	ds, dgroup, cx
		VSem	ds, iacpInstantiateSem
		pop	ds
exit:
		.leave
		ret
IACPInstantiateServer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPFindServerOwnedByCX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate a server object owned by the given geode.

CALLED BY:	(INTERNAL) IACPConnect via ChunkArrayEnum
PASS:		*ds:si	= array of server optrs
		ds:di	= optr to check
		ax	= element # for this optr
		cx	= handle of geode a server of which we're seeking
RETURN:		carry set if this optr is owned by the geode
			ax	= element # of this optr
		carry clear if not:
			ax	= element # of the next optr
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPFindServerOwnedByCX proc	far
		uses	bx
		.enter
		clc
		jcxz	done		; => geode not loaded, so take any
					;  server

		mov	bx, ds:[di].handle
		call	MemOwner
		cmp	bx, cx
		je	done
		inc	ax
		stc
done:
		cmc
		.leave
		ret
IACPFindServerOwnedByCX endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLocateServerApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the application to serve a particular list.

CALLED BY:	(INTERNAL) IACPConnect
PASS:		ds	= locked AppLaunchBlock into which to store our
			  results
		bx	= handle of same
		es:di	= GeodeToken for the app.
RETURN:		carry set if couldn't locate it:
			ax	= IACPCE_CANNOT_FIND_SERVER
			ALB freed
		carry clear if it's there:
			ds:[ALB_appRef].AIR_diskHandle,
			ds:[ALB_appRef].AIR_fileName both set
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		fill this in later

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumRetVal	struct
    ERV_attr	FileAttrs
    ERV_flags	GeosFileHeaderFlags
    ERV_name	FileLongName
EnumRetVal	ends

iacpLocateServerReturnAttrs	FileExtAttrDesc \
	<FEA_FILE_ATTR, ERV_attr, size ERV_attr>,
	<FEA_FLAGS, ERV_flags, size ERV_flags>,
	<FEA_NAME, ERV_name, size ERV_name>,
	<FEA_END_OF_LIST>

EnumParams	struct
    EP_common	FileEnumParams
    EP_matchAttrs	FileExtAttrDesc	<FEA_GEODE_ATTR>,
					<FEA_TOKEN>,
					<FEA_END_OF_LIST>
EP_GEODE_ATTR	equ	0*size FileExtAttrDesc
EP_TOKEN	equ	1*size FileExtAttrDesc
EP_EOL		equ	2*size FileExtAttrDesc
EnumParams	ends

IACPLocateServerApp proc	near
		uses	dx, es, di, si, bp, bx, cx
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		call	FilePushDir

	;
	; Check in the .ini file for the token, first, on the assumption that
	; it's faster than searching the filesystem, but not slow enough to
	; get in the way (since we expect most calls to be for non-generic
	; tokens that won't be in the .ini file).
	; 
		call	IACPLocateServerAppInIniFile
		jnc	done

		mov	ax, SP_APPLICATION		; switch to appl dir.
		call	FileSetStandardPath

		mov	dx, ds
		call	IACPLocateServerAppLow
		jnc	done
	;
	; Not in main application tree, so check in sysappl.
	; 
		mov	ax, SP_SYS_APPLICATION
		call	FileSetStandardPath
		
		mov	dx, ds
		call	IACPLocateServerAppLow
done:
		call	FilePopDir

		.leave
	;
	; Free the AppLaunchBlock on error.
	; 
		jnc	exit
		call	MemFree
		stc
exit:
		ret
IACPLocateServerApp endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLocateServerAppLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the current directory for the server application.

CALLED BY:	(INTERNAL) IACPLocateServerApp, self
PASS:		es:di	= token for which to search.
		dx	= locked AppLaunchBlock into which to store the
			  results.
RETURN:		carry set if didn't find it:
			ax	= IACPCE_CANNOT_FIND_SERVER
		carry clear if found:
			ALB_appRef filled in
			es, di, ax = destroyed
DESTROYED:	bx, bp, cx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPLocateServerAppLow proc	near	uses	ds
		.enter
		push	dx		; save ALB segment

if FULL_EXECUTE_IN_PLACE
	;
	; Copy the iacpLocateServerReturnAttrs table to stack
	;
		push	ds, si
		segmov	ds, cs, cx
		mov	si, offset iacpLocateServerReturnAttrs	;ds:si = iacpLocateServerReturnAttrs table
		mov	cx, (size EnumRetVal) * (length iacpLocateServerReturnAttrs)
		call	SysCopyToStackDSSI
endif
		
		sub	sp, size EnumParams
		mov	bp, sp
		mov	ss:[bp].EP_common.FEP_searchFlags, 
			mask FESF_GEOS_EXECS or mask FESF_DIRS
if FULL_EXECUTE_IN_PLACE
		mov	ss:[bp].EP_common.FEP_returnAttrs.segment, ds
		mov	ss:[bp].EP_common.FEP_returnAttrs.offset, si
else
		mov	ss:[bp].EP_common.FEP_returnAttrs.segment, cs
		mov	ss:[bp].EP_common.FEP_returnAttrs.offset, 
				offset iacpLocateServerReturnAttrs
endif
		mov	ss:[bp].EP_common.FEP_returnSize, size EnumRetVal
		mov	ss:[bp].EP_common.FEP_matchAttrs.segment, ss
		lea	bx, ss:[bp].EP_matchAttrs
		mov	ss:[bp].EP_common.FEP_matchAttrs.offset, bx
		mov	ss:[bp].EP_common.FEP_bufSize, FE_BUFSIZE_UNLIMITED
		mov	ss:[bp].EP_common.FEP_skipCount, 0

	;
	; Matched file must have GA_PROCESS and GA_APPLICATION set in 
	; its Geode Attributes record.
	; 
		mov	ss:[bp].EP_matchAttrs[EP_GEODE_ATTR].FEAD_attr,
				FEA_GEODE_ATTR
		mov	ss:[bp].EP_matchAttrs[EP_GEODE_ATTR].FEAD_value.offset,
				mask GA_PROCESS or mask GA_APPLICATION
		mov	ss:[bp].EP_matchAttrs[EP_GEODE_ATTR].FEAD_value.segment,
				0
		mov	ss:[bp].EP_matchAttrs[EP_GEODE_ATTR].FEAD_size,
				size GeodeAttrs

	;
	; It must also match the token we've got on the stack.
	; 
		mov	ss:[bp].EP_matchAttrs[EP_TOKEN].FEAD_attr,
				FEA_TOKEN
		mov	ss:[bp].EP_matchAttrs[EP_TOKEN].FEAD_value.offset,
				di
		mov	ss:[bp].EP_matchAttrs[EP_TOKEN].FEAD_value.segment,
				es
		mov	ss:[bp].EP_matchAttrs[EP_TOKEN].FEAD_size,
				size GeodeToken

	;
	; Mark the end of the match attributes
	; 
		mov	ss:[bp].EP_matchAttrs[EP_EOL].FEAD_attr,
				FEA_END_OF_LIST


		call	FileEnum
		lea	sp, ss:[bp+size EnumParams]	; clear the rest of our
							;  stuff off the stack
							;  (FileEnum cleared the
							;  FileEnumParams, but
							;  left our own data)
if FULL_EXECUTE_IN_PLACE
	;
	; Restore the stack and registers
	;
		call	SysRemoveFromStack
		pop	ds, si
endif
		pop	dx			; dx <- ALB segment
	;
	; If no files found, return carry set + error code.
	; 
checkNoneFound:
		stc
		mov	ax, IACPCE_CANNOT_FIND_SERVER
		jcxz	done
	;
	; First look for a file in the buffer. We'll deal with directories
	; on a second pass through the result, but if the app is here, we want
	; to find it ASAP.
	; 
		call	MemLock
		mov	ds, ax
		push	cx
		clr	si
locateFileLoop:
		test	ds:[si].ERV_attr, mask FA_SUBDIR
		jz	gotIt
		add	si, size EnumRetVal
		loop	locateFileLoop

	;
	; No files, so try each directory in turn.
	; 
		pop	cx
		clr	si
trySubdirsLoop:
		push	bx, cx, si
	;
	; Push to this subdirectory.
	; 
		test	ds:[si].ERV_attr, mask FA_LINK
		stc
		jnz	nextSubdir		; don't descend into a link,
						;  as the thing could be
						;  recursive
		call	FilePushDir
		push	dx
		lea	dx, ds:[si].ERV_name
		clr	bx			; => relative path
		call	FileSetCurrentPath
		pop	dx			; dx <- ALB segment for
						;  recursion
		call	IACPLocateServerAppLow
		call	FilePopDir
nextSubdir:
		pop	bx, cx, si
		jnc	nukeEnumBlock		; => found it, so biff block we
						;  were looking through
	;
	; Advance to next directory in the block.
	; 
		add	si, size EnumRetVal
		loop	trySubdirsLoop

		call	MemFree
		jmp	checkNoneFound		; (cx is 0, so go set
						;  carry and error code and
						;  boogie)
gotIt:
	;
	; Copy the one file found into the buffer, preceded by the current
	; directory.
	; 
		inc	sp		; discard file count
		inc	sp
		push	bx
		mov	es, dx
		mov	di, offset ALB_appRef.AIR_fileName
		clr	bx, dx
		lea	si, ds:[si].ERV_name
		mov	cx, size AIR_fileName
		call	FileConstructFullPath
		segmov	ds, es
		mov	ds:[ALB_appRef].AIR_diskHandle, bx
		pop	bx
nukeEnumBlock:
		call	MemFree
		clc
done:
		.leave
		ret
IACPLocateServerAppLow endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLocateServerAppInIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look in the [iacp] category for a key for the given token,
		filling in the necessary fields of the ALB if the key is
		found.

CALLED BY:	(INTERNAL) IACPLocateServerApp
PASS:		ds, ^hbx= locked ALB
		es:di	= token being sought
		cwd pushed, so can safely change dirs here
RETURN:		carry clear if found:
			ALB_appRef.AIR_diskHandle,
			ALB_appRef.AIR_fileName filled in
		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
iacpCatStr	char	'iacp', 0

IACPLocateServerAppInIniFile proc near
keyStr		local	(UHTA_NULL_TERM_BUFFER_SIZE+5) dup(char)
		uses	ax, bx, cx, dx, ds, si, es, di
	ForceRef	keyStr	; used in IACPGenerateTokenKey
		.enter
	;
	; First generate the key, using the four token chars, a comma, and the
	; decimal version of the manufacturer's ID. The null-terminated result
	; is left in keyStr.
	; 
		call	IACPGenerateTokenKey
	;
	; Now check the [iacp] category for a path below WORLD or SYSTEM/SYSAPPL
	; under that key. The result is left in AIR_fileName
	; 
		segmov	es, ds
		mov	di, offset ALB_appRef.AIR_fileName
		segmov	ds, cs
		mov	si, offset iacpCatStr
		push	bp
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				(size AIR_fileName shl offset IFRF_SIZE)
		call	InitFileReadString
		pop	bp
		jc	done
	;
	; Figure whether the thing is under WORLD or SYSTEM/SYSAPPL. This
	; also verifies the thing actually exists, of course.
	; 
		mov	ax, SP_APPLICATION
		mov	bx, ax			; bx <- disk handle, in case
						;  it exists
		call	FileSetStandardPath
		movdw	dsdx, esdi		; ds:dx <- file to check
		call	FileGetAttributes
		jnc	found

		mov	ax, SP_SYS_APPLICATION
		mov	bx, ax
		call	FileSetStandardPath
		call	FileGetAttributes
		jc	done
found:
		test	cx, mask FA_SUBDIR	; just in case...
		stc
		jnz	done
		mov	es:[ALB_appRef.AIR_diskHandle], bx
		clc
done:
		.leave
		ret
IACPLocateServerAppInIniFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPGenerateTokenKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the INI file key for a token.

CALLED BY:	(INTERNAL) IACPLocateServerAppInIniFile,
       			   IACPBindToken,
			   IACPUnbindToken
PASS:		es:di	= GeodeToken
		ss:bp	= inherited frame with first variable defined as:
			keyStr	local	(UHTA_NULL_TERM_BUFFER_SIZE+5) dup(char)
RETURN:		null-terminated string left in keyStr
		cx:dx	= keyStr
DESTROYED:	cx, es, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPGenerateTokenKey proc	far
keyStr		local	(UHTA_NULL_TERM_BUFFER_SIZE+5) dup(char)
		uses	ax
		.enter	inherit	near
		movdw	({dword}ss:[keyStr]), es:[di].GT_chars, ax
		mov	ss:[keyStr][4], ','
		mov	ax, es:[di].GT_manufID
		lea	di, ss:[keyStr][5]
		segmov	es, ss
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE or mask UHTAF_SBCS_STRING
		call	UtilHex32ToAscii
		mov	cx, ss
		lea	dx, ss:[keyStr]
		.leave
		ret
IACPGenerateTokenKey endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLocateServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the server application for a token.

CALLED BY:	(GLOBAL) and IACPLocateServerXIP
PASS:		es:di	= GeodeToken for application
RETURN:		carry set if no such application found
			bx	= destroyed
		carry clear if application found:
			^hbx	= AppInstanceReference with AIR_diskHandle
				  and AIR_fileName filled in
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPLocateServer proc	far
		uses	ds, ax, cx
		.enter
		Assert	fptr, esdi

			CheckHack <offset ALB_appRef eq 0>
		mov	ax, size AppInstanceReference
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	done		; => can't allocate, so can't find

		mov	ds, ax
		call	IACPLocateServerApp
		jc	done		; => no such app; block already freed

		call	MemUnlock	; unlock and return success
done:
		.leave
		ret
IACPLocateServer endp


if FULL_EXECUTE_IN_PLACE
IACPCommon  ends
ResidentXIP    segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLocateServerXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the server application for a token.

CALLED BY:	(GLOBAL) for XIP system
PASS:		es:di	= GeodeToken for application
		Note: es:di *can* be pointing to the movable XIP code
			resource.
RETURN:		carry set if no such application found
			bx	= destroyed
		carry clear if application found:
			^hbx	= AppInstanceReference with AIR_diskHandle
				  and AIR_fileName filled in
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPLocateServerXIP	proc	far
		push	cx, di, es
		mov	cx, size GeodeToken
		call	SysCopyToStackESDI		;es:di = data on stack
		call	IACPLocateServer
		call	SysRemoveFromStack		;release stack space
		pop	cx, di, es
		ret
IACPLocateServerXIP		endp


ResidentXIP    ends
IACPCommon  segment resource
endif

if FULL_EXECUTE_IN_PLACE
IACPCommon  ends
UserCStubXIP    segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLOCATESERVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the server application for a token.

CALLED BY:	(GLOBAL)
PARAMS:		MemHandle (const GeodeToken *)
		Note: "GeodeToken" *can* be pointing to the movable XIP 
			code resource.

RETURN:		0 if server not found, else handle of AppInstanceReference
		block with AIR_diskHandle and AIR_fileName filled in.
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPLOCATESERVER proc	far
		C_GetOneDWordArg	ax, bx,  cx, dx
		push	es, di
		movdw	esdi, axbx
NOFXIP<		call	IACPLocateServer				>
FXIP<		call	IACPLocateServerXIP				>
		jnc	done
		clr	bx
done:
		pop	es, di
		mov_tr	ax, bx
		ret
IACPLOCATESERVER endp

if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
IACPCommon  segment resource
endif

IACPCommon	ends

TokenUncommon	segment	resource

iacpCatStr2	char	'iacp', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPBindUnbindCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to save registers, setup the stack frame,
		generate the key, and set up registers for calling the
		InitFile code for binding & unbinding tokens.
		
		NOTE: This is a coroutine, which calls its caller back right
		after the call to this routine. When the caller returns, this
		routine cleans up and then returns on behalf of the caller.

CALLED BY:	(INTERNAL) IACPBindToken, IACPUnbindToken
PASS:		es:di	= GeodeToken
		ds:dx	= value to pass pack in es:di
RETURN:		not directly
DESTROYED:	ax
SIDE EFFECTS:	init file modified, but not committed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPBindUnbindCommon proc near
keyStr		local	(UHTA_NULL_TERM_BUFFER_SIZE+5) dup(char)
		uses	es, di, cx, dx, ds, si, bx
	ForceRef	keyStr	; used in IACPGenerateTokenKey
		.enter
	;
	; Make sure token is valid.
	; 
		Assert	fptr, esdi

		movdw	axbx, esdi		; pass token in ax:bx for
						;  bind...
	;
	; Generate the key from the token.
	; 
		mov	si, dx			; preserve dx
		call	IACPGenerateTokenKey	; cx:dx <- key
	;
	; Arrange registers for call to InitFile routines.
	; 	es:di	<- ds:dx from entry
	; 	cx:dx	<- key string
	; 	ds:si	<- category string
	; Also:
	; 	ax:bx	= token
	; 
		movdw	esdi, dssi		; es:di <- string to write
						;  (for bind)
		segmov	ds, cs
		mov	si, offset iacpCatStr2	; ds:si <- category
	;
	; Call our caller back again. It's a far routine...
	; 
		push	cs
		call	{nptr}ss:[bp+2]	; di = MSN_NEW/REMOVE_IACP_BINDING

	;
	; Let Mailbox subsystem know this has happened.  di has just been
	; setup by our caller.
	;
		mov	es, ax			; es:bx <- GeodeToken
		mov	dx, es:[bx].GT_manufID
		mov	cx, {word}es:[bx].GT_chars[2]
		mov	bx, {word}es:[bx].GT_chars[0]
		mov	si, SST_MAILBOX
		call	SysSendNotification

		.leave
	;
	; Discard our return address and return for the caller.
	; 
		inc	sp
		inc	sp
		retf
IACPBindUnbindCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPBindToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Associate a generic token with an executable under
		SP_APPLICATION or SP_SYS_APPLICATION

CALLED BY:	(GLOBAL) and IACPBindTokenXIP
PASS:		es:di	= GeodeToken
		ds:dx	= path of application under SP_APPLICATION or
			  SP_SYS_APPLICATION
		Note: The fptrs *can* be pointing to the movable XIP 
			code resource.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	string is written to the ini file, but the ini file is *not*
     		committed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPBindToken	proc	far
		Assert	fptr, dsdx
		call	IACPBindUnbindCommon	; calls us back with everything
						;  setup properly
		call	InitFileWriteString
	;
	; Let Mailbox subsystem know this has happened. All registers are fair
	; game here, having been saved by IACPBindUnbindCommon
	; 
		mov	di, MSN_NEW_IACP_BINDING

		ret
IACPBindToken 	endp

if FULL_EXECUTE_IN_PLACE
TokenUncommon  ends
ResidentXIP    segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPBindTokenXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Associate a generic token with an executable under
		SP_APPLICATION or SP_SYS_APPLICATION

CALLED BY:	(GLOBAL) for XIP system
PASS:		es:di	= GeodeToken
		ds:dx	= path of application under SP_APPLICATION or
			  SP_SYS_APPLICATION
		Note: The fptrs *can* be pointing to the movable XIP 
			code resource.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	string is written to the ini file, but the ini file is *not*
     		committed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPBindTokenXIP	proc	far
		uses	ds, dx, es, di, cx
		.enter
		mov	cx, size GeodeToken	;cx = size to copy
		call	SysCopyToStackDSDX	;ds:dx = data on stack
		clr	cx			;cx = null-terminated str
		call	SysCopyToStackESDI	;es:di = data on stack
		call	IACPBindToken		;call the real routine
		call	SysRemoveFromStack	;release stack space
		call	SysRemoveFromStack
		.leave
		ret
IACPBindTokenXIP		endp


ResidentXIP    ends
TokenUncommon  segment resource
endif

if FULL_EXECUTE_IN_PLACE
TokenUncommon  ends
UserCStubXIP    segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPBINDTOKEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Associate a generic token with an executable under
		SP_APPLICATION or SP_SYS_APPLICATION

CALLED BY:	(GLOBAL)
PARAMS:		void (const GeodeToken *token, const char *app);
		Note: The fptrs *can* be pointing to the movable XIP 
			code resource.

SIDE EFFECTS:	string is written to the in ifile, but the ini file is not
		committed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
IACPBINDTOKEN	proc	far	token:fptr.GeodeToken,
				app:fptr.char
		uses	es, di, ds
		.enter
		les	di, ss:[token]
		lds	dx, ss:[app]
NOFXIP<		call	IACPBindToken					>
FXIP<		call	IACPBindTokenXIP				>
		.leave
		ret
IACPBINDTOKEN 	endp

if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
TokenUncommon  segment resource
endif

SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPUnbindToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the binding between a token and an application

CALLED BY:	(GLOBAL) and IACPUnbindTokenXIP
PASS:		es:di	= GeodeToken to unbind
		Note: es:di *can* be pointing to the movable XIP 
			code resource.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	key is deleted from the ini file, but the ini file is *not*
		committed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPUnbindToken proc	far
		call	IACPBindUnbindCommon	; calls us back with everything
						;  setup properly
		call	InitFileDeleteEntry
	;
	; Let Mailbox subsystem know this has happened. All registers are fair
	; game here, having been saved by IACPBindUnbindCommon
	; 
		mov	di, MSN_REMOVE_IACP_BINDING

		ret
IACPUnbindToken endp

if FULL_EXECUTE_IN_PLACE
TokenUncommon  ends
ResidentXIP    segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPUnbindTokenXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the binding between a token and an application

CALLED BY:	(GLOBAL) in XIP system
PASS:		es:di	= GeodeToken to unbind
		Note: es:di *can* be pointing to the movable XIP 
			code resource.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	key is deleted from the ini file, but the ini file is *not*
		committed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPUnbindTokenXIP	proc	far
		uses	es, di, cx
		.enter
		mov	cx, size GeodeToken	;cx = size to copy
		call	SysCopyToStackESDI	;ds:di = data on stack
		call	IACPUnbindToken		;call the real routine
		call	SysRemoveFromStack	;release stack space
		.leave
		ret
IACPUnbindTokenXIP		endp


ResidentXIP    ends
TokenUncommon  segment resource
endif

if FULL_EXECUTE_IN_PLACE
TokenUncommon  ends
UserCStubXIP    segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPUNBINDTOKEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the binding between a token and an application

CALLED BY:	(GLOBAL)
PARAMS:		void (const GeodeToken *)
		Note: The fptr *can* be pointing to the movable XIP 
			code resource.

SIDE EFFECTS:	key is deleted from the ini file, but the ini file is *not*
		committed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPUNBINDTOKEN proc	far
		C_GetOneDWordArg	ax, bx,	 cx, dx
		push	es, di
		movdw	esdi, axbx
NOFXIP<		call	IACPUnbindToken					>
FXIP<		call	IACPUnbindTokenXIP				>
		pop	es, di
		ret
IACPUNBINDTOKEN endp

if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
TokenUncommon  segment resource
endif


TokenUncommon	ends
