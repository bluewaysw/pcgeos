COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Net
FILE:		netC.asm

AUTHOR:		Chung Liu, Sep 22, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial revision


DESCRIPTION:
	This file contains C interface routines for the net library

	$Id: netC.asm,v 1.1 97/04/05 01:24:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Net	segment resource

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetEnumConnectedUsers
C DESCRIPTION: 	Return a chunk array with a list of all users
C DECLARATION:	extern ChunkHandle _far _pascal
		    NetEnumConnectedUsers(NetEnumBufferType bt, MemHandle mh);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/3/93		Initial version
----------------------------------------------------------------------------@
NETENUMCONNECTEDUSERS	proc	far		bt:word,
						mh:hptr
	uses	bx, ds, si
enumParams		local	NetEnumParams
	.enter
	mov	bx, bt
	mov	enumParams.NEP_bufferType, bx

	mov	bx, mh
	call 	MemDerefDS

	push	bp
	lea	bp, ss:[enumParams]
	call	NetEnumConnectedUsers			;returns *ds:si = chunk array
	pop	bp

	mov	ax, si				;return the chunk handle of
						;the chunk array.
	.leave
	ret
NETENUMCONNECTEDUSERS	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetEnumUsers
C DESCRIPTION: 	Return a chunk array with a list of all users
C DECLARATION:	extern ChunkHandle _far _pascal
  			NetEnumUsers(NetEnumBufferType bt, MemHandle mh);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/3/93		Initial version
----------------------------------------------------------------------------@
NETENUMUSERS	proc	far		bt:word,
					mh:hptr
	uses	bx, ds, si
enumParams		local	NetEnumParams
	.enter
	mov	bx, bt
	mov	enumParams.NEP_bufferType, bx

	mov	bx, mh
	call 	MemDerefDS

	push	bp
	lea	bp, ss:[enumParams]
	call	NetEnumUsers			;returns *ds:si = chunk array
	pop	bp

	mov	ax, si				;return the chunk handle of
						;the chunk array.
	.leave
	ret
NETENUMUSERS	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetUserGetLoginName
C DESCRIPTION: 	Get current user's login name
C DECLARATION:	extern void _far _pascal
			NetUserGetLoginName(char *buffer)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version
----------------------------------------------------------------------------@
NETUSERGETLOGINNAME	proc	far		buffer:fptr
	uses	ds,si
	.enter
	lds	si, buffer
	call	NetUserGetLoginName
	.leave
	ret
NETUSERGETLOGINNAME	endp


COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetUserCheckIfInGroup

C DESCRIPTION: 	returns 0 if user is in group, -1 if not in group, or
		NetWareReturnCode if error.

C DECLARATION:	extern word
			_far _pascal NetUserCheckIfInGroup(char *userName,
							   char *groupName);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETUSERCHECKIFINGROUP	proc	far	userName:fptr,
					groupName:fptr
	uses	ds,es,bx,cx,dx,si
	.enter
	lds	si, userName
	movdw	cxdx, groupName
	call	NetUserCheckIfInGroup
	jc	fail
	mov	ax, 0
	jmp	exit
fail:
	tst	ax
	jnz	exit
	mov	ax, -1

exit:
	.leave
	ret
NETUSERCHECKIFINGROUP	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetVerifyUserPassword

C DESCRIPTION: 	returns NetWareReturnCode, which indicates how password
		matches user name.

C DECLARATION:	extern NetWareReturnCode
			_far _pascal NetVerifyUserPassword(char *userName,
							   char *password,
							   byte nameSize,
							   byte passwordSize);
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		Should not have to pass nameSize and passwordSize.
		The strings should be null terminated, and we should figure
		out the length ourselves.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETVERIFYUSERPASSWORD	proc	far	userName:fptr,
					password:fptr,
					nameSize:word, 	;actually byte
					passwordSize:word
	uses	es,bx,cx,dx,si,ds
	.enter
	mov	bx, nameSize
	mov	al, bl
	mov	bx, passwordSize
	mov	ah, bl
	lds	si, userName		;ds:si = name
	les	dx, password
	mov	cx, es			;cx:dx = password
	call	NetVerifyUserPassword	;returns al = NetWareReturnCode
	.leave
	ret
NETVERIFYUSERPASSWORD	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetGetServerNameTable

C DESCRIPTION: 	returns a pointer to the first of 8 entries in the
		Server Name Table.
		Each entry is NW_USER_NAME_LENGTH bytes long,
		and can contain a null-terminated server name.

C DECLARATION:	extern char
			_far _pascal *NetGetServerNameTable();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETGETSERVERNAMETABLE	proc	far
	uses	ds, si
	.enter
	call	NetGetServerNameTable
	movdw	dxax, dssi
	.leave
	ret
NETGETSERVERNAMETABLE	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetGetConnectionIDTable

C DESCRIPTION: 	returns a pointer to the first of 8 entries in the
		Connection ID Table.

C DECLARATION:	extern NetwareConnectionIDTableItem
			_far _pascal *NetGetConnectionIDTable();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETGETCONNECTIONIDTABLE	proc	far
	uses	es, si
	.enter
	call	NetGetConnectionIDTable
	movdw	dxax, essi
	.leave
	ret
NETGETCONNECTIONIDTABLE	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetScanForServer

C DESCRIPTION: 	return information about a server

C DECLARATION:	extern NetWareReturnCode
			_far _pascal NetScanForServer(
					NetWareBinderyObjectID oldID,
					char *nameBuffer,
					NetWareBinderyObjectID *ID);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETSCANFORSERVER	proc	far	oldID:dword,
					nameBuffer:fptr,
					ID:fptr
	uses	ds,si,cx,dx
	.enter
	mov	cx, oldID.high
	mov	dx, oldID.low
	lds	si, nameBuffer
	call	NetScanForServer
	lds	si, ID
	mov	ds:[si].high, cx
	mov	ds:[si].low, dx

	.leave
	ret
NETSCANFORSERVER	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetGetDefaultConnectionID

C DESCRIPTION: 	return connection ID of default server

C DECLARATION:	extern NetWareConnectionID
			_far _pascal NetGetDefaultConnectionID(void);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETGETDEFAULTCONNECTIONID	proc	far
	.enter
	call	NetGetDefaultConnectionID
	.leave
	ret
NETGETDEFAULTCONNECTIONID	endp


COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetServerAttach

C DESCRIPTION: 	return connection ID of default server

C DECLARATION:	extern word
			_far _pascal NetServerAttach(char *server);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETSERVERATTACH	proc	far		server:fptr
	uses	ds,si
	.enter
	lds	si, server
	call	NetServerAttach
	.leave
	ret
NETSERVERATTACH	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetServerChangeUserPassword
C DESCRIPTION: 	Change the user's password
C DECLARATION:	extern word _far _pascal
			NetServerChangeUserPassword(char *server,
						    char *userName,
						    char *oldPassword,
						    char *newPassword);
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version
----------------------------------------------------------------------------@
NETSERVERCHANGEUSERPASSWORD	proc	far		server:fptr,
							userName:fptr,
							oldPassword:fptr,
							newPassword:fptr
	uses	bp,bx,dx
	.enter
	sub	sp, size NetServerChangeUserPasswordFrame
	mov	bx, sp
	movdw	ss:[bx].NSCUPF_serverName, server, dx
	movdw	ss:[bx].NSCUPF_userName, userName, dx
	movdw	ss:[bx].NSCUPF_oldPassword, oldPassword, dx
	movdw	ss:[bx].NSCUPF_newPassword, newPassword, dx
	call	NetServerChangeUserPassword
	add	sp, size NetServerChangeUserPasswordFrame
	.leave
	ret
NETSERVERCHANGEUSERPASSWORD	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetServerVerifyUserPassword
C DESCRIPTION: 	Check with server if password for user is correct.
C DECLARATION:	extern word
			_far _pascal NetServerVerifyUserPassword(char *server,
						   char *login, char *passwd)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version
----------------------------------------------------------------------------@
NETSERVERVERIFYUSERPASSWORD	proc	far		server:fptr,
							login:fptr,
							passwd:fptr
	uses	ds,si,bx,cx,dx
	.enter
	lds	si, server
	movdw	axbx, login
	movdw	cxdx, passwd

	call	NetServerVerifyUserPassword
	.leave
	ret
NETSERVERVERIFYUSERPASSWORD	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetServerLogin
C DESCRIPTION: 	login to named file server
C DECLARATION:	extern word
			_far _pascal NetServerLogin(char *server,
						    char *login,
						    char *passwd,
						    Boolean ropenFiles)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version
----------------------------------------------------------------------------@
NETSERVERLOGIN	proc	far		server:fptr,
					login:fptr,
					passwd:fptr,
					reopenFiles:word
	uses	bp,dx
	.enter

	sub	sp, size NetServerLoginFrame
	mov	bx, sp
	movdw	ss:[bx].NSLF_serverName, server, dx
	movdw	ss:[bx].NSLF_userName, login, dx
	movdw	ss:[bx].NSLF_password, passwd, dx
	mov	dx, reopenFiles
	mov 	ss:[bx].NSLF_reopenFiles, dl
	call	NetServerLogin
	add	sp, size NetServerLoginFrame
	clr	ah

	.leave
	ret
NETSERVERLOGIN	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetServerLogout
C DESCRIPTION: 	logout from named file server
C DECLARATION:	extern word
			_far _pascal NetServerLogout(char *server)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version
----------------------------------------------------------------------------@
NETSERVERLOGOUT	proc	far		server:fptr
	uses	ds, si, cx, dx
	.enter
	lds	si, server
	call	NetServerLogout
	.leave
	ret
NETSERVERLOGOUT	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetServerGetNetAddr

C DESCRIPTION: 	Get the net address of the server

C DECLARATION:	extern word _far _pascal
			NetServerGetNetAddr(char *server,
					    NovellNodeSocketAddr *np)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETSERVERGETNETADDR	proc	far		server:fptr,
						np:fptr
	uses	ds,si,bx
	.enter
	lds	si, server
	movdw	cxdx, np
	call	NetServerGetNetAddr
	.leave
	ret
NETSERVERGETNETADDR	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetServerGetWSNetAddr

C DESCRIPTION: 	get the net address of the workstation calling this function.

C DECLARATION:	extern word _far _pascal
			NetServerGetWSNetAddr(char *server,
					    NovellNodeSocketAddr *np)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETSERVERGETWSNETADDR	proc	far		server:fptr,
						np:fptr
	uses	ds,si,bx
	.enter
	lds	si, server
	movdw	cxdx, np
	call	NetServerGetWSNetAddr
	.leave
	ret
NETSERVERGETWSNETADDR	endp


COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetMapDrive

C DESCRIPTION: 	Permanently assign a workstation drive to a network
		directory

C DECLARATION:	extern word
			_far _pascal NetMapdrive(char letter, char *path,
						 char *driveName)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETMAPDRIVE	proc	far		letter:word,
					path:fptr,
					driveName:fptr
	uses	ds,si,bx
	.enter
	mov	bx, letter
	lds	si, path
	movdw	cxdx, driveName
	call	NetMapDrive
	.leave
	ret
NETMAPDRIVE	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetUnmapDrive

C DESCRIPTION: 	Permanently assign a workstation drive to a network
		directory

C DECLARATION:	extern word
			_far _pascal NetUnmapdrive(char letter)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETUNMAPDRIVE	proc	far		letter:word
	uses	ds,si,bx
	.enter
	clr	bx
	mov	bx, letter
	call	NetUnmapDrive
	clr	ah
	.leave
	ret
NETUNMAPDRIVE	endp


COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetGetConnectionNumber

C DESCRIPTION: 	returns the connection number the workstation uses to
		communicate with the default file server

C DECLARATION:	extern NetWareConnectionNumber
			_far _pascal NetGetConnectionNumber()

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/22/92		Initial version

----------------------------------------------------------------------------@
NETGETCONNECTIONNUMBER	proc	far
	uses	cx
	.enter
	call	NetGetConnectionNumber
	mov	ax, cx
	.leave
	ret
NETGETCONNECTIONNUMBER	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetMsgOpenPort

C DESCRIPTION:  open a port for communication, return a port token.

C DECLARATION:	extern word
			_far _pascal NetMsgOpenPort(PortInfoStruct *portInfo)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/13/92	Initial version

----------------------------------------------------------------------------@
NETMSGOPENPORT	proc	far		portInfo:fptr
	uses	ds, si
	.enter
	mov	cx, size PortInfoStruct
	lds	si, portInfo
	call	NetMsgOpenPort
	mov	ax, bx
	.leave
	ret
NETMSGOPENPORT	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetMsgClosePort

C DESCRIPTION:  Close a 2-way communication port

C DECLARATION:	extern word
			_far _pascal NetMsgClosePort(word  PortToken)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/13/92	Initial version

----------------------------------------------------------------------------@
NETMSGCLOSEPORT	proc	far		PortToken:word
	.enter
	mov	bx, PortToken
	call	NetMsgClosePort
	.leave
	ret
NETMSGCLOSEPORT	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetMsgCreateSocket

C DESCRIPTION:  Create a socket for the port

C DECLARATION:	extern word
			_far _pascal NetMsgCreateSocket(word PortToken,
						word SocketID,
						void _far *Callback,
						word CallbackData)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/13/92	Initial version

----------------------------------------------------------------------------@
NETMSGCREATESOCKET	proc	far		PortToken:word,
						socketID:SocketID,
						destID:SocketID,
						Callback:fptr.far,
						CallbackData:word
	uses ds, si, di
	.enter
	mov	ax, size NetMsgCCallbackStruct
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	ds, ax
	movdw	ds:[NMCC_Callback], Callback, ax
	segmov	ds:[NMCC_Other], CallbackData, ax
	call	MemUnlock

	mov	dx, vseg CallbackIntercept
	mov	ds, dx
	mov	dx, offset cs:CallbackIntercept
	mov	si, bx			;SI <- extra data
	mov	bx, PortToken
	mov	cx, socketID
	push	bp
	mov	bp, destID
	call	NetMsgCreateSocket
	pop	bp
	.leave
	ret
NETMSGCREATESOCKET	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallbackIntercept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepts callback from NetLib to C function

CALLED BY:	CommServerLoop
PASS:		ds:si - buffer
		cx - size (if 0, socket destroyed)
		dx - extra data
		di - handle of mem buffer with NetMsgCCallbackStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/ 8/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallbackIntercept	proc	far
	uses	es
	.enter
	mov	bx, di
	call	MemLock			;Lock down data with our callback info
	mov	es, ax
	push	bx, cx			;Save handle of data and # bytes

	push	ds
	push	si
	push	cx
	push	dx			;Pass extra data
	push	es:[NMCC_Other]
	movdw	bxax, es:[NMCC_Callback]
	call	ProcCallFixedOrMovable

	pop	bx, cx
.assert SOCKET_DESTROYED eq 0
	jcxz	destroySocket
	call	MemUnlock
exit:
	.leave
	ret
destroySocket:
	call	MemFree
	jmp 	exit

CallbackIntercept	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetMsgDestroySocket

C DESCRIPTION:  Destroys a socket

C DECLARATION:	extern word
			_far _pascal NetMsgDestroySocket(word PortToken,
						word SocketToken)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/13/92	Initial version

----------------------------------------------------------------------------@
NETMSGDESTROYSOCKET	proc	far		PortToken:word,
						SocketToken:word
	.enter
	mov	bx, PortToken
	mov	dx, SocketToken
	call	NetMsgDestroySocket
	.leave
	ret
NETMSGDESTROYSOCKET	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetMsgSendBuffer

C DESCRIPTION:  Send a message

C DECLARATION:	extern word
			_far _pascal NetMsgSendBuffer(word PortToken,
						word SocketToken,
						word extraData,
						word SizeOfBuffer,
						char *Buffer)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/13/92	Initial version

----------------------------------------------------------------------------@
NETMSGSENDBUFFER	proc	far		PortToken:word,
						SocketToken:word,
						extraData:word,
						SizeOfBuffer:word,
						Buffer:fptr
	uses	si, bp, di, ds
	.enter
	mov	bx, PortToken
	mov	dx, SocketToken
	mov	cx, SizeOfBuffer
	lds	si, Buffer
	mov	bp, extraData
	call	NetMsgSendBuffer
	.leave
	ret
NETMSGSENDBUFFER	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetMsgSetTimeOut

C DESCRIPTION:  Set Timeout value for socket

C DECLARATION:	extern word
			_far _pascal NetMsgSetTimeOut(word PortToken,
						word SocketToken,
						word TimeOut)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/13/92	Initial version

----------------------------------------------------------------------------@
NETMSGSETTIMEOUT	proc	far		PortToken:word,
						SocketToken:word,
						TimeOut:word
	.enter
	mov	bx, PortToken
	mov	dx, SocketToken
	mov	cx, TimeOut
	call	NetMsgSetTimeOut
	.leave
	ret
NETMSGSETTIMEOUT	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetOpenSem

C DESCRIPTION:  Open a network semaphore.

C DECLARATION:	extern MemHandle _pascal
		    NetOpenSem(char *semName,
		    	       int initValue,
			       word pollIntervalTicks);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	4/26/93		Initial version

----------------------------------------------------------------------------@
NETOPENSEM	proc	far		semName:fptr,
					initValue:word,
					pollIntervalTicks:word
	uses	ds,si,cx,dx
	.enter
	lds	si, semName
	mov	cx, initValue
	mov	dx, pollIntervalTicks
	clr	bx
	call	NetOpenSem
	jc	error
	mov	ax, cx
exit:
	.leave
	ret
error:
	clr	ax
	jmp	exit
NETOPENSEM	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetPSem

C DESCRIPTION:  Open a network semaphore.

C DECLARATION:	extern Boolean _pascal
		    NetPSem(MemHandle semHandle, word timeoutTicks)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	4/26/93		Initial version

----------------------------------------------------------------------------@
NETPSEM	proc	far				semHandle:hptr,
						timeoutTicks:word
	uses	cx,dx
	.enter
	mov	cx, semHandle
	mov	dx, timeoutTicks
	call	NetPSem
	jc	error
exit:
	mov	ax, -1
	.leave
	ret
error:
	clr	ax
	jmp	exit
NETPSEM	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetVSem

C DESCRIPTION:  Open a network semaphore.

C DECLARATION:	extern void _pascal NetVSem(MemHandle semHandle)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	4/26/93		Initial version

----------------------------------------------------------------------------@
NETVSEM	proc	far			semHandle:hptr
	uses	cx
	.enter
	mov	cx, semHandle
	call	NetVSem
	.leave
	ret
NETVSEM	endp

COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetCloseSem

C DESCRIPTION:  Open a network semaphore.

C DECLARATION:	extern void _pascal NetCloseSem(MemHandle semHandle)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	4/26/93		Initial version

----------------------------------------------------------------------------@
NETCLOSESEM	proc	far			semHandle:hptr
	uses	cx
	.enter
	mov	cx, semHandle
	call	NetCloseSem
	.leave
	ret
NETCLOSESEM	endp


COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetPrintSetBannerStatus

C DESCRIPTION:  Turn banner printing on/off

C DECLARATION:	extern void _pascal NetPrintSetBannerStatus(int status);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	7/26/93		Initial version

----------------------------------------------------------------------------@
NETPRINTSETBANNERSTATUS	proc far	status:word
		.enter
		mov	ax, status
		call	NetPrintSetBannerStatus

		.leave
		ret
NETPRINTSETBANNERSTATUS	endp


COMMENT @--------------------------------------------------------------------

C FUNCTION:	NetPrintSetTimeout

C DESCRIPTION:  Set the capture timeout value

C DECLARATION:	extern void _pascal NetPrintSetTimeout(int timeout);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	7/26/93		Initial version

----------------------------------------------------------------------------@
NETPRINTSETTIMEOUT	proc far	timeout:word
		.enter

		mov	ax, timeout
		call	NetPrintSetTimeout

		.leave
		ret
NETPRINTSETTIMEOUT	endp



C_Net 	ends



