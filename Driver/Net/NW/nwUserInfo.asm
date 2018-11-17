COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Novell NetWare Driver
FILE:		userInfo.asm


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version
	chungl	9/92		Added NetWareVerifyUserPassword

DESCRIPTION:
	This library allows PC/GEOS applications to access the Novell NetWare
	Applications Programmers Interface (API). This permits an application
	to send and receive packets, set up connections between nodes on the
	network, access Novell's "Bindery", which contains information about
	network users, etc.

RCS STAMP:
	$Id: nwUserInfo.asm,v 1.1 97/04/18 11:48:43 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetWareResidentCode
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareUserFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the DR_NET_USER_FUNCTION ops

CALLED BY:	NetWareStrategy

PASS:		al - NetUserFunction

RETURN:		see netDr.def

DESTROYED:	di

PSEUDO CODE/STRATEGY:
	This procedure is a fixed-code stub -- the real proc is
	NetWareUserRealFunction

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NetWareUserFunction	proc near
	call	NetWareUserRealFunction
	ret
NetWareUserFunction	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource

NetWareUserRealFunction	proc far
	.enter
	clr	ah
	mov	di, ax
	call	cs:[netUserFunctionTable][di]

	.leave
	ret
NetWareUserRealFunction	endp

netUserFunctionTable	nptr.near	\
	NetWareUserGetLoginName,
	NetWareUserGetFullName,
	NetWareUserEnumConnectedUsers,
	NetWareVerifyUserPassword,
	NetWareUserGetConnectionNumber,
	NetWareUserCheckIfInGroup,
	NetWareUserEnumUsers

.assert (segment NetWareUserGetLoginName eq @CurSeg) and \
	(segment NetWareUserGetFullName eq @CurSeg) and \
	(segment NetWareUserEnumConnectedUsers eq @CurSeg) and \
	(segment NetWareVerifyUserPassword eq @CurSeg) and \
	(segment NetWareUserGetConnectionNumber eq @CurSeg) and \
	(segment NetWareUserCheckIfInGroup eq @CurSeg) and \
	(segment NetWareUserEnumUsers eq @CurSeg)
.assert ($-netUserFunctionTable eq NetUserFunction)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareUserGetLoginName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the login name of the current user

CALLED BY:	NUF_GET_LOGIN_NAME

PASS:		ds:si - buffer to fill in

RETURN:		buffer filled in

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareUserGetLoginName	proc near
	uses	ds, si, cx
	.enter
	push	ds, si

	call	NetWareUserGetConnectionNumber
	call	NetWareGetConnectionInformation	; es:di -
						; NRepBuf_GetConnectionInfo
	segmov	ds, es
	lea	si, ds:[di].NREPBUF_GCI_objectName
	pop	es, di
	call	NetWareCopyNTString

	pushf
	mov	bx, ds:[NRR_handle]
	call	MemFree
	popf

	.leave
	ret
NetWareUserGetLoginName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareUserCheckIfInGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if user is in the group.

CALLED BY:	net library
PASS:		ds:si 	- fptr to asciiz user login name
		cx:dx	- fptr to group name
RETURN:		if user is in group:
			carry clear
		if user is not in group, or error:
			carry set
			ax = NetWareReturnCode, 0 if no error.
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/14/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareUserCheckIfInGroup	proc	near
groupName	local	fptr
buffer	local	128 dup	(byte)
	uses	ds,si,cx,dx,bp,bx
	.enter
	movdw	groupName, cxdx

	;
	; get the group ID's of groups I'm in.
	;
	mov	cx, ss
	lea	dx, buffer
	call	NetWareUserGetGroupsImIn
	tst 	al
	jnz 	error

	;
	; get group ID of group we're interested in.
	;
	lds	si, groupName
	mov	ax, NOT_USER_GROUP
	call	NetWareGetBinderyObjectID		;cx:dx is object ID
	jc	exit

	;
	; look for a match
	;
	clr 	ax			;count to 32
	lea	bx, buffer

again:
	cmp	ss:[bx], cx
	jne	next
	add	bx, 2
	cmp	ss:[bx], dx
	pushf
	sub	bx, 2
	popf
	jne	next

	;got match
	clc
	jmp	exit

next:
	add 	bx, 4
	inc	ax
	cmp	ax, 32
	jl	again

	;no match found
	clr	ax
	stc
exit:
	.leave
	ret

error:
	stc
	jmp exit

NetWareUserCheckIfInGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareUserGetGroupsImIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a 128-byte segment of the "GROUPS_I'M_IN" property.

CALLED BY:	NetWareUserCheckIfInGroup
PASS:		ds:si - fptr to asciiz user login name
		cx:dx - fptr to 128 byte buffer to fill in with property
RETURN:		buffer if filled with 32 16-byte group IDs.
		al - NetWareReturnCode, 0 if successful.
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/14/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
groupsImInProperty	char	"GROUPS_I'M_IN",0

NetWareUserGetGroupsImIn	proc	near

	uses	bp

	.enter


	sub	sp, size NetObjectReadPropertyValueStruct
	mov	bp, sp

	mov	ss:[bp].NORPVS_objectType, NOT_USER
	movdw	ss:[bp].NORPVS_objectName, dssi
	movdw	ss:[bp].NORPVS_buffer, cxdx
	mov	ss:[bp].NORPVS_propertyName.segment, cs
	mov	ss:[bp].NORPVS_propertyName.offset, \
			offset groupsImInProperty

	mov	ss:[bp].NORPVS_bufferSize,
			128

	mov	bx, bp
	call	NetWareObjectReadPropertyValue

	lea	sp, ss:[bp][size NetObjectReadPropertyValueStruct]

	.leave
	ret

NetWareUserGetGroupsImIn	endp





COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareUserGetConnectionNumber

DESCRIPTION:	This call returns the connection number that the requesting
		workstation uses to communicate with the default file server.

PASS:		nothing

RETURN:		cx	= connection number (1-250)

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version

------------------------------------------------------------------------------@

NetWareUserGetConnectionNumber	proc	near
	.enter

	mov	ah, (NFC_GET_CONNECTION_NUMBER shr 8)
	call	NetWareCallFunction		;returns ax = # (1-250)
						;cx = ascii chars for #

EC <	tst	al							>
EC <	ERROR_Z	NW_ERROR						>
EC <	cmp	al, NW_MAX_CONNECTION_NUMBER			>
EC <	ERROR_A	NW_ERROR						>

	mov_tr	cx, ax

	.leave
	ret
NetWareUserGetConnectionNumber	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareGetConnectionInformation

DESCRIPTION:	This call returns information about the object logged
		in as the specified connection number.

PASS:		cx	= connection number (1-250)

RETURN:		es:di	= NRepBuf_GetConnectionInfo (stored within
			a NetRequestReplyBufferStruct.)

			When you are done with this structure, use:

				mov	bx, es:[NRR_handle]
				call	MemFree

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version

------------------------------------------------------------------------------@

NetWareGetConnectionInformation	proc	near
	uses	cx, dx, ds, si, bp
	.enter

	mov	al, cl				;al = connection #
	mov	bx, size NReqBuf_GetConnectionInfo
	mov	cx, size NRepBuf_GetConnectionInfo
	call	NetWareAllocRRBuffers		;does not trash al
						;returns ^hbx = block (locked)
						;ds:si = request buffer
						;es:di = reply buffer

	mov	es:[si]+NREQBUF_GCI_logicalConnectionNum,al
					;save connection number in request buf.

	mov	ax, NFC_GET_CONNECTION_INFORMATION
	call	NetWareCallFunctionRR	;call NetWare, passing RR buffer

	.leave
	ret
NetWareGetConnectionInformation	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareGetUserFullName

DESCRIPTION:	return the full name of a user

PASS:		ds:si  - fptr to users login name
		cx:dx - buffer to fill in with real name

RETURN:		buffer filled in

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version
	chrisb	11/92		changed to use common routine

------------------------------------------------------------------------------@
identityProperty char "IDENTIFICATION",0

NetWareUserGetFullName	proc	near

	uses	cx,dx,bp

	.enter

	sub	sp, size NetObjectReadPropertyValueStruct
	mov	bp, sp

	mov	ss:[bp].NORPVS_objectType, NOT_USER
	movdw	ss:[bp].NORPVS_objectName, dssi
	movdw	ss:[bp].NORPVS_buffer, cxdx
	mov	ss:[bp].NORPVS_propertyName.segment, cs
	mov	ss:[bp].NORPVS_propertyName.offset, \
			offset identityProperty

	mov	ss:[bp].NORPVS_bufferSize,
			size NetUserFullName

	mov	bx, bp
	call	NetWareObjectReadPropertyValue

	mov	di, sp
	lea	sp, ss:[bp][size NetObjectReadPropertyValueStruct]

	.leave
	ret
NetWareUserGetFullName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareUserEnumConnectedUsers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the list of users connected to the network

CALLED BY:	Net library

PASS:		ds - segment of NetEnumCallbackData

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Connection numbers range from 1 to 100.
	For each connection number, see if a user is logged in with
	that number.  If so, return that user's name

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareUserEnumConnectedUsers	proc near
	uses	cx,dx,si,bp

	.enter

	;
	; Allocate the GetConnectionInfo buffer
	;

	mov	bx, size NReqBuf_GetConnectionInfo
	mov	cx, size NRepBuf_GetConnectionInfo
	call	NetWareAllocRRBuffers

	;
	; Store the address of the user name in the callback data
	; segment.
	;

	mov	ds:[NECD_curElement].segment, es
	lea	ax, es:[di].NREPBUF_GCI_objectName
	mov	ds:[NECD_curElement].offset, ax

	;
	; Count down from 100
	;

	mov	cx, 100
startLoop:
	mov	es:[si][NREQBUF_GCI_logicalConnectionNum], cl
					;save connection number in request buf.

	mov	ax, NFC_GET_CONNECTION_INFORMATION
	call	NetWareCallFunctionRR
	jc	next

	cmp	es:[di].NREPBUF_GCI_objectType, NOT_USER
	jne	next
	;
	; Now pass the user name to the callback routine
	;

	call	NetEnumCallback
next:
	loop	startLoop

	;
	; Free up our buffers, and scram!
	;
	call	NetWareFreeRRBuffers

	.leave
	ret
NetWareUserEnumConnectedUsers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareUserEnumUsers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all users.

CALLED BY:	Net library
PASS:		ds = segment of NetEnumCallbackData
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;this is already defined in nwPrint.asm
;wildcard	char 	'*',0

NetWareUserEnumUsers	proc	near
	uses	ax,bx,cx,dx,si,di,bp,es,ds
	.enter

        ;
        ; Allocate the request and reply buffers.  For the request
        ; buffer, we need to allocate enough space to hold a name as
        ; well.  The name we pass is just "*".
        ;

        mov     bx, size NReqBuf_ScanBinderyObject + size wildcard
        mov     cx, size NRepBuf_ScanBinderyObject
        call    NetWareAllocRRBuffers           ; es - segment of RR
                                                ; buffers
        ;
        ; Fill in the CallbackData fields
        ;

        mov     ds:[NECD_curElement].segment, es
        lea     ax, es:[di].NREPBUF_SBO_objectName
        mov     ds:[NECD_curElement].offset, ax

        ;
        ; Fill in fields of request buffer (the name field fits in a word)
        ;
        movdw   es:[si].NREQBUF_SBO_lastObjectID, -1
                CheckHack <size wildcard eq 2>
        mov     ax, {word} cs:[wildcard]
        mov     {word} es:[si].NREQBUF_SBO_objectName, ax

        mov     es:[si].NREQBUF_SBO_objectType, NOT_USER
        mov     es:[si].NREQBUF_SBO_objectNameLen, size wildcard-1

startLoop:

        ;
        ; Make the call
        ;

        mov     ax, NFC_SCAN_BINDERY_OBJECT
        call    NetWareCallFunctionRR

        ;
        ; If al nonzero, done (XXX: Figure out which errors are valid)
        ;

        tst     al
        jnz     done

        ;
        ; Call the callback routine to add our data to the caller's
        ; buffer.
        ;

        call    NetEnumCallback

        ;
        ; Copy the current object ID to the "last" object ID, so we
        ; can get the next object
        ;

        movdw   es:[si].NREQBUF_SBO_lastObjectID, \
                        es:[di].NREPBUF_SBO_objectID, ax
        jmp     startLoop

done:
        ;
        ; Free the request / reply buffers
        ;

        mov     bx, es:[NRR_handle]
        call    MemFree

	.leave
	ret
NetWareUserEnumUsers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareVerifyUserPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the password for the user is correct.
		Implements DR_NET_VERIFY_USER_PASSWORD.

CALLED BY:	the Net library

PASS:		dl - length of name string
		dh - length of password string
		ss:bp - NetVerifyPasswordParams

RETURN:		al - NetWareReturnCode

DESTROYED:	ah = 0

BUGS:		should add error checking to make sure strings
		are not too long, password is all upper-case, and
		there are no illegal characters.

		RR buffers are not being free'd!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareVerifyUserPassword	proc	near
params		local	nptr.NetVerifyPasswordParams	push bp
bufferBlock	local	hptr
reqBuffer	local	fptr.NReqBuf_VerifyBinderyObjectPassword
repBuffer	local	fptr.NRepBuf_VerifyBinderyObjectPassword
nameSize	local	byte
passwdSize	local 	byte
	uses	ds,es,si,di,bx,cx,dx
	.enter

	mov 	nameSize, dl
	mov	passwdSize, dh

	mov	bx, size NReqBuf_VerifyBinderyObjectPassword
	mov	cx, size NRepBuf_VerifyBinderyObjectPassword
	call 	NetWareAllocRRBuffers	;returns es:si = request buffer
					;	 es:di = reply buffer
					;	 ^hbx = locked block
					;               containing buffers

	segmov	ds, es

	mov	reqBuffer.segment, ds
	mov	reqBuffer.offset, si

	mov	repBuffer.segment, es
	mov	repBuffer.offset, di

	mov	bufferBlock, bx

	;object is a user
	mov	ds:[si].NREQBUF_VBOP_objectType, NOT_USER

	mov	ds:[si].NREQBUF_VBOP_objectNameLen, dl		;nameSize

	;we make es:di be the request buffer so it can be the destination
	;of stosb
	lea	di, es:[si].NREQBUF_VBOP_objectName	;es:di = dest. for name
	mov	si, ss:[params]
	lds	si, ss:[si].NVPP_loginName

	;copy the name into the request buffer
	clr	cx
	mov	cl, dl
	rep movsb

	;now es:di points to where the password length should
	;be stored in the request buffer.
	;
	;Note that the password length and password should be placed
	;immediately after the name, and NOT necessarily at
	;offset NREQBUF_VBOP_passwordLen
	mov	es:[di], dh			;passwdSize
	inc	di				;es:di = dest. for password
	mov	si, ss:[params]
	lds	si, ss:[si].NVPP_password

	;copy the password into the request buffer
	clr	cx
	mov	cl, dh
	push	di, cx
	rep movsb

	; force it to all upper-case there
	segmov	ds, es
	pop	si, cx
	call	LocalUpcaseString

	;calculate the size of the request buffer, and place size
	;in first word.  Size is:
	;
	;    	DESCRIPTION	BYTES
	;	-----------     -----
	;	buffer length	2
	;	subcode		1
	;	object type	2
	;	name length	1
	;	name		namesize
	;	password len	1
	;	password	passwordSize
	;	---------------------
	;	TOTAL = nameSize + passwordSize + 7
	;
	clr	ax
	mov	al, dl			; al <- name size
	add	al, dh			; += passwordSize
	add	al, offset NREQBUF_VBOP_objectName - \
			size NREQBUF_VBOP_length + 1

	mov	si, reqBuffer.offset	;ds:si = request buffer
	mov	ds:[si].NREQBUF_VBOP_length, ax		;request buffer size
	mov	di, repBuffer.offset	;es:di = reply buffer

	;call Verify Bindery Object Password
	mov	ax, NFC_VERIFY_BINDERY_OBJECT_PASSWORD
	mov	dl, 3Fh

	call	NetWareCallFunctionRR	;call NetWare, passing RR buffer
					;returns al = condition code
	clr	ah

	;unlock buffer block
	mov	bx, bufferBlock
	call	MemFree

	.leave
	ret
NetWareVerifyUserPassword	endp

NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareGetServerNameTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	This call returns a fptr to the shell's File Server Name Table.

	The File Server Name Table consists of eight entries (1 to 8)
	that are NW_USER_NAME_LENGTH bytes in length.
	Each entry in the FSNT can contain a null-terminated server name.
	To find out which entries in the name table are valid, look at
	the Connection ID Table. 
	ATTENTION: the File Server Name Table only contains the names
	of the servers that were attached.

CALLED BY:	Net library

PASS:		nothing

RETURN:		ds:si = pointer to shell's Server Name Table

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

BUGS:	
	This call returns a NetWare data structure, and when called 
	with EC Segment, will fail because ds will not be a valid GEOS
	segment on return.

	Should create a NetEnumAttachedServers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode 	segment	resource
NetWareGetServerNameTable	proc	near
	call 	NetWareGetServerNameTableInternal
	ret
NetWareGetServerNameTable	endp
NetWareResidentCode 	ends

NetWareCommonCode 	segment	resource
NetWareGetServerNameTableInternal	proc	far
	uses	ax
	.enter
	mov	ax, NFC_GET_FILE_SERVER_NAME_TABLE
	call	NetWareCallFunction
	segmov	ds, es, ax
	.leave
	ret
NetWareGetServerNameTableInternal	endp
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareGetConnectionIDTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This call returns a pointer to the shell's Connection
		ID Table.

CALLED BY:	Net library
PASS:		nothing
RETURN:		ds:si = Connection ID Table
DESTROYED:	nothing

BUGS:	
	This call returns a pointer to a NetWare data structure, and
	when called with EC segment will fail because ds will not be
	a valid GEOS segment.

PSEUDO CODE/STRATEGY:
	The Connection ID Table consists of eight entries (1 to 8) that
	are 32 bytes in length.
	Each entry is a NetWareConnectionIDTableItem.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode 	segment	resource
NetWareGetConnectionIDTable	proc	near
	call 	NetWareGetConnectionIDTableInternal
	ret
NetWareGetConnectionIDTable	endp
NetWareResidentCode 	ends

NetWareCommonCode	segment	resource
NetWareGetConnectionIDTableInternal	proc	far
	uses	ax
	.enter
	mov	ax, NFC_GET_CONNECTION_ID_TABLE
	call	NetWareCallFunction
	segmov	ds, es, ax
	.leave
	ret
NetWareGetConnectionIDTableInternal	endp
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareScanForServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call Scan Bindery Object to look for a server.

CALLED BY:	Net library

PASS:		cx:dx	= NetWareBinderyObjectID of server returned in
			previous call.  On the first call to this procedure,
			set cx = dx = 0xffff.
		ds:si	= buffer into which the name of the server is
			copied and returned.

RETURN:		ds:si 	= buffer is stuffed with the null terminated name
			of a server.
		cx:dx	= NetWareBinderyObjectID for server returned.
		al	= NetWareReturnCode (0 = successful)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode 	segment	resource
NetWareScanForServer	proc	near
	call 	NetWareScanForServerInternal
	ret
NetWareScanForServer	endp
NetWareResidentCode 	ends

NetWareCommonCode	segment	resource
NetWareScanForServerInternal	proc	far
	uses	ds,si,es,di,bx
	.enter

	push	ds, si			;dest. for name string
	push 	dx
	push 	cx			;last object ID


	;allocate buffer space
	mov	bx, size NReqBuf_ScanBinderyObject
	mov	cx, size NRepBuf_ScanBinderyObject
	call	NetWareAllocRRBuffers	;es:si = req. buffer
					;es:di = reply buffer
					;^hbx  = locked block

	segmov	ds, es

	;setup request buffer
	pop	ds:[si].NREQBUF_SBO_lastObjectID.high
	pop	ds:[si].NREQBUF_SBO_lastObjectID.low
	mov	ds:[si].NREQBUF_SBO_objectType, NOT_FILE_SERVER
	mov	ds:[si].NREQBUF_SBO_objectNameLen, 1	;any/all servers
	mov	ds:[si].NREQBUF_SBO_objectName, '*'

	;call the netware function
	mov	ax, NFC_SCAN_BINDERY_OBJECT
	mov	dl, 37h
	segmov	es, ds
	call	NetWareCallFunctionRR
	clr	ah

	;copy server name into the buffer that was passed in.
	push 	es, di
	pop	ds, si			;ds:si = reply buffer
	mov	dx, si			;save the original offset
	add	si, NREPBUF_SBO_objectName
	pop	es, di			;es:di = dest. for name string

	mov	cx, NW_BINDERY_OBJECT_NAME_LEN
	rep movsb
	mov	{byte} es:[di], 0	;make sure name is null terminated

	;return the object ID
	mov	si, dx			;restore original offset
	mov	cx, ds:[si].NREPBUF_SBO_objectID.high
	mov	dx, ds:[si].NREPBUF_SBO_objectID.low

	;free reply buffer
	mov	bx, ds:[NRR_handle]
	call	MemFree
	.leave
	ret
NetWareScanForServerInternal	endp
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareGetDefaultConnectionID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This call returns the connection ID of the file server
		to which request packets are currently being sent.
		The default server is where the user gets logged into.

		Doc: NetWare System Calls -- DOS, page 17-11.
CALLED BY:	Net library
PASS:		ax	= NFC_GET_DEFAULT_CONNECTION_ID
RETURN:		al	= Connection ID of file server to which
			  packets are currently being sent (1 to 8)
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode 	segment	resource
NetWareGetDefaultConnectionID	proc	near
	call	NetWareGetDefaultConnectionIDInternal
	ret
NetWareGetDefaultConnectionID	endp
NetWareResidentCode 	ends

NetWareCommonCode	segment	resource
NetWareGetDefaultConnectionIDInternal	proc	far
	.enter
	mov	ax, NFC_GET_DEFAULT_CONNECTION_ID
	call	NetWareCallFunction
	clr	ah
	.leave
	ret
NetWareGetDefaultConnectionIDInternal	endp
NetWareCommonCode	ends


