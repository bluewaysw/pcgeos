COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS	
MODULE:		Novell NetWare Driver
FILE:		nwServer.asm

AUTHOR:		Chung Liu, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------
	NWServerAttach		Attach to server
	NWServerLogin		Login to server
	NWServerLogout		Logout from server
	NWServerAssignDrive	Assign a drive letter to a server
	NWServerGetNetAddr	get net address of server
	NWServerGetWSNetAddr	get net address of workstation
	NWServerVerifyUserPassword
	NWServerChangeUserPassword
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 8/92		Initial revision


DESCRIPTION:
	Code for server related NetWare stuff.
		

	$Id: nwServer.asm,v 1.1 97/04/18 11:48:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Internal/fileInt.def
include	Internal/interrup.def
include	Internal/geodeStr.def

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach to the given server.  If server is not in shell tables,
		add server to shell server table and connection ID table.

CALLED BY:	Net Library (?)
PASS:		ds:si 	- zero terminated server name string
RETURN:		al	- return code 
				0 - success
				1 - too many connections already (8 max.)
				2 - name too long
				(change these to a enum)
		dl	- connection ID of the attached server (1-8)
DESTROYED:	ah, dh
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- If server in shell tables, just attach, otherwise...

	- Get Novell net address (NovellNodeSocketAddrStruct) of server using
	  the NetWare ReadPropertyValue call.
	- Update shell tables (connection id table, and server name table).
	- call NetWare Attach.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWServerAttach	proc	near
	call 	NWServerAttachInternal
	ret
NWServerAttach	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWServerAttachInternal	proc	far
netAddr		local	NovellNodeSocketAddrStruct
serverName	local	fptr
serverNameLen	local	byte
emptySlot	local	byte
connIDTable	local	fptr
	uses	bx,cx,ds,si,es,di
	.enter
	movdw	serverName, dssi

	call	NWGetConnectionIDInternal
	tst 	dl
	jz	addToTables

	;server in shell tables already
	mov	emptySlot, dl
	jmp 	doAttach

addToTables:
	;count server name length
	clr	ax

countLoop:
	cmp	{byte} ds:[si], 0
	jz	countDone
	inc	si
	inc	ax
	cmp	ax, NW_BINDERY_OBJECT_NAME_LEN
	jb	countLoop
	mov	ax, 2		;error, name too long
	jmp 	error

countDone:

	mov	serverNameLen, al
	
	;get net address of server
	lds	si, serverName
	mov	cx, ss
	lea	dx, ss:[netAddr]

	call 	NWServerGetNetAddrInternal

	tst 	al		;too far for short jump
	jz      noError
	jmp	error

noError:	

	;get the connection id table
	call	NetWareGetConnectionIDTableInternal	;es:si = table
	movdw	connIDTable, essi
	mov	di, si

	;find an empty entry in the connection id table, where we
	;can add our own entry.
	mov	cx, 1

findSlot:
	tst	es:[si].NCITI_slotInUse
	jz	foundSlot
	inc 	cx
	add	si, size NetWareConnectionIDTableItem
	cmp	cx, 8	;eight entries in table
	jbe	findSlot
	mov	ax, 1		;error, too many connections
	jmp	error

foundSlot:
	;cx is empty slot
	mov	emptySlot, cl

	;figure out a order number (1-8) for this slot.
	;the order number is the sort order of network addresses.
	;
	; see NetWare doc. on how order numbers work.
	; this algorithm is copied from the ICLAS algorithm
	
	clr 	dx		;initial value for order number
	
	;args for MyMemCmp
	mov	cx, size NovellNodeSocketAddrStruct
	lds	si, connIDTable

	segmov	es, ss
	lea	di, ss:[netAddr]

	mov	bx, 8		;repeat for the whole table

findOrder:
	;find entries with smaller netAddr
	add	si, NCITI_serverAddress
	call	MyMemCmp	;if (connIDTable[bx].seq > netAddr)
	sub	si, NCITI_serverAddress
	tst	ax
	jge	contOrder

	;if my order number is smaller than the order number of an entry
	;with a smaller netAddr, then rearrange.
	cmp	dl, ds:[si].NCITI_serverOrderNumber
	jge	contOrder
	
	;rearrange order numbers
	mov	dl, ds:[si].NCITI_serverOrderNumber
	inc	{byte} ds:[si].NCITI_serverOrderNumber

contOrder:
	add	si, size NetWareConnectionIDTableItem
	dec	bx
	jnz	findOrder
	
	tst 	dl
	jnz	foundOrder

	;if my order number is still 0, then my order number will be the
	;biggest.  go through the table again, and this time look for 
	;the largest.  the order number will be largest + 1.

	mov	cx, 8		;repeat for whole table
	lds	si, connIDTable

biggestOrder:
	cmp	dl, ds:[si].NCITI_serverOrderNumber
	jge 	contBiggestOrder
	mov	dl, ds:[si].NCITI_serverOrderNumber

contBiggestOrder:		
	add	si, size NetWareConnectionIDTableItem
	loop	biggestOrder

	inc	dl	;dl is the desired order number

foundOrder:
	;dl is order number

	;set es:di = offset into unused entry	
	les	di, connIDTable
	mov	al, emptySlot		;numbering starts at 1.
	dec	al			;decrement to calc. offset
	mov	cx, size NetWareConnectionIDTableItem
	mul	cl
	add	di, ax

	;fill in the entry.
	mov	es:[di].NCITI_slotInUse, 0xff
	mov	es:[di].NCITI_serverOrderNumber, dl
	add	di, NCITI_serverAddress

	segmov	ds, ss
	lea	si, ss:[netAddr]

	mov	cx, size NovellNodeSocketAddrStruct
	rep	movsb 

	;now write server name into the shell's server name table,
	call	NetWareGetServerNameTableInternal
	
	;es:si = server name table
	;set es:di = offset into unused slot
	mov	al, emptySlot		;numbering starts at 1
	dec	al			;decrement to calc. offset
	mov	cx, NW_BINDERY_OBJECT_NAME_LEN + 1
	mul	cl
	mov	di, si
	add	di, ax

	lds	si, serverName

	;copy server name into server name table
	clr	cx
	mov	cl, serverNameLen
	rep	movsb 

doAttach:	
	;now call NetWare attach interrupt call.
	mov	dl, emptySlot
	mov	ax, NFC_ATTACH_TO_FILE_SERVER
	call	NetWareCallFunction
	clr	ah

	clr 	dx
	mov	dl, emptySlot
error:
	.leave
	ret
NWServerAttachInternal	endp
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerGetNetAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the NovellNodeSocketAddrStruct of the file server.

PASS:		ds:si 	- server name
		cx:dx	- pointer to a NovellNodeSocketAddrStruct to be
			  filled in.

RETURN:		cx:dx 	- filled in with the NovellNodeSocketAddrStruct of
			  the file server.
		al 	- NetWareReturnCode (0 = successful)

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWServerGetNetAddr 	proc 	near
	call 	NWServerGetNetAddrInternal
	ret
NWServerGetNetAddr 	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWServerGetNetAddrInternal	proc	far
netAddrPtr	local	fptr
serverName	local	fptr
serverNameLen	local	byte
bufferBlock	local	hptr		
reqBuf		local	fptr
repBuf		local	fptr					
	uses	bx, cx, dx, ds, es, di, si
	.enter
	
	;save arguments passed in
	movdw	serverName, dssi
	movdw	netAddrPtr, cxdx

	;count name length
	segmov	es,ds,di
	mov	di, si				;es:si = string
	mov	cx, -1
	clr 	al
	repne	scasb
	not	cx				;cx = length not including 0
	dec	cx				;cx = length without 0

	mov	serverNameLen, cl

	mov	bx, size NReqBuf_ReadPropertyValue
	mov	cx, size NRepBuf_ReadPropertyValue
	call	NetWareAllocRRBuffers		;returns ^hbx = block (locked)
						;es:si = request buffer
						;es:di = reply buffer
	segmov	ds, es
	mov	bufferBlock, bx
	movdw	reqBuf, dssi
	movdw	repBuf, esdi
	
	;stuff request buffer
	mov	{byte} ds:[si].NREQBUF_RPV_subFunc, 0x3d
	mov	ds:[si].NREQBUF_RPV_objectType, NOT_FILE_SERVER
	
	;copy in name of server
	clr	cx
	mov	cl, serverNameLen		;cx = count
	mov	{byte} ds:[si].NREQBUF_RPV_objectNameLen, cl
	lds	si, serverName			;ds:si = server name
	les	di, reqBuf
	add	di, NREQBUF_RPV_objectName	;es:di = dest. in req. buffer
	rep 	movsb
	
	;after copying the server name, es:di has been incremented to 
	;exactly where the next slot (segment number) is.
	mov	{byte} es:[di], NW_BINARY_OBJECT_PROPERTY_INITIAL_SEGMENT
	inc	di
	
	;propertyNameLength
	clr	cx
	mov	cl, (size nwBinderyObjPropName_NetAddress) 
	mov	{byte} es:[di], cl
	inc	di

	;copy property name
	;set ds:si = ascii table below
	;    es:di = destination in reply buffer
	;	cx = count
	segmov	ds, cs, ax
	mov	si, offset nwBinderyObjPropName_NetAddress
	rep	movsb
	
	;calculate length of request buffer
	;length = 8 bytes + length of object name + length of property name
	clr	cx
	mov	cl, serverNameLen
	add	cx, (size nwBinderyObjPropName_NetAddress) 
	add	cx, 8
	lds	si, reqBuf
	mov	ds:[si].NREQBUF_RPV_length, cx
	
	;call NetWare
	les	di, repBuf
	mov	ax, NFC_READ_PROPERTY_VALUE
	mov	dl, (NFC_READ_PROPERTY_VALUE and 0xff)
	segmov	es, ds
	call	NetWareCallFunctionRR	;call NetWare, passing RR buffer

	clr	ah
	test	al, 0
	jnz	done

	;copy property value to buffer
	lds	si, repBuf
	add	si, NREPBUF_RPV_propertyValue
	les	di, netAddrPtr
	mov	cx, (size NovellNodeSocketAddrStruct)
	rep	movsb

	mov	bx, bufferBlock
	call	MemUnlock
done:
	.leave
	ret
NWServerGetNetAddrInternal	endp

nwBinderyObjPropName_NetAddress	char	\
					NWBinderyObjPropName_NetAddress
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerGetWSNetAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the net address of the calling workstation.

CALLED BY:	Net library
PASS:		ds:si 	- server name
		cx:dx	- pointer to a NovellNodeSocketAddrStruct to be
			  filled in.
RETURN:		cx:dx 	- filled in with the NovellNodeSocketAddrStruct of
			  the workstation.
		al 	- NetWareReturnCode (0 = successful)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	call NetWareUserGetConnectionNumber to obtain the workstation's 
	connection number.  then call NFC_GET_INTERNET_ADDRESS.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/27/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWServerGetWSNetAddr	proc 	near
	call 	NWServerGetWSNetAddrInternal
	ret
NWServerGetWSNetAddr	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWServerGetWSNetAddrInternal	proc	far
netAddrPtr	local	fptr
	uses	bx,cx,dx,es,si,ds,di
	.enter
	movdw	netAddrPtr, cxdx
	
	;
	; if not already attached, they call attach.
	;
	
	call 	NWGetConnectionIDInternal
	tst	dl
	jnz	gotConnectionID
	call	NWServerAttachInternal
	tst	al
	jz	gotConnectionID
	jmp	done				;attach failed
	
gotConnectionID:
	call	NWSetPreferredConnectionIDInternal	;set server to check with.
	
	;
	; allocate request/reply buffers
	;

	mov	bx, size NReqBuf_GetInternetAddress	
	mov	cx, size NRepBuf_GetInternetAddress	
	call	NetWareAllocRRBuffers
	push	bx

	;
	; get connection number
	;

	mov	ax, NFC_GET_CONNECTION_NUMBER
	call	NetWareCallFunction

	;
	; Fill in request buffer
	;

	mov	es:[si].NREQBUF_GIA_length, 4
	mov	es:[si].NREQBUF_GIA_subFunc, 0x13
	mov	es:[si].NREQBUF_GIA_connectionNumber, al

	;
	; call NetWare
	;

	mov	ax, NFC_GET_INTERNET_ADDRESS
	call	NetWareCallFunctionRR

	clr	ah
	tst	al
	jnz	done

	;
	; copy the return into the buffer that was passed in
	;
	
	segmov	ds, es, cx
	mov	si, di				
	add	si, offset NREPBUF_GIA_netAddr	;ds:si = netAddr returned
	les	di, netAddrPtr			

	mov	cx, size NovellNodeSocketAddrStruct
	rep	movsb
	
	;
	; free request/reply buffers
	;
	
	pop	bx
	call	MemUnlock

done:
	.leave
	ret
NWServerGetWSNetAddrInternal	endp
NetWareCommonCode	ends
					


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSetPreferredConnectionID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This call sets the preferred file server.

CALLED BY:	internal	
PASS:		dl = connection id (1-8) of preferred server, or
		     0 (unspecified.)
RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;NetWareResidentCode	segment resource
;NWSetPreferredConnectionID	proc	near
;	call 	NWSetPreferredConnectionIDInternal
;	ret
;NWSetPreferredConnectionID	endp
;NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWSetPreferredConnectionIDInternal	proc	far
	uses	ax
	.enter
	mov	ax, NFC_SET_PREFERRED_CONNECTION_ID
	call	NetWareCallFunction
	.leave
	ret
NWSetPreferredConnectionIDInternal	endp
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWGetConnectionID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the connection ID of the file server if the
		server is attached, otherwise return 0.

CALLED BY:	internal

PASS:		ds:si - asciiz name of server

RETURN:		dl - connection id of server (1-8)
		     or 0 if server is not attached.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Search through the server tables looking for a match.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;NetWareResidentCode	segment resource
;NWGetConnectionID	proc	near
;	call 	NWGetConnectionIDInternal
;	ret
;NWGetConnectionID	endp
;NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWGetConnectionIDInternal	proc	far
serverTable	local	fptr
connIDTable	local 	fptr
serverName	local	fptr		
	uses	ds,es,di,si,ax,cx
	.enter
	movdw	serverName, dssi

	call	NetWareGetServerNameTableInternal
	movdw	serverTable, essi

	call	NetWareGetConnectionIDTableInternal
	movdw	connIDTable, essi

	mov	cx, 1		;repeat for each entry of the table
	lds	si, serverTable
	les	di, connIDTable
findMatch:
	tst	es:[di].NCITI_slotInUse
	jz	contMatch		;empty slot, skip.

	;slot in use, see if there is a match
	push	es, di
	les	di, serverName

	;es:di = server name, ds:si = entry in server table
	call	MyStrCmp	
	pop	es, di

	tst 	ax	;ax = 0 if match
	jz	foundMatch

contMatch:
	add	si, NW_BINDERY_OBJECT_NAME_LEN + 1
	add	di, size NetWareConnectionIDTableItem
	
	inc	cx
	cmp	cx, 8
	jle	findMatch
	
	clr	cx		;not found

foundMatch:
	mov	dl, cl
	
	.leave
	ret
NWGetConnectionIDInternal	endp
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerVerifyUserPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check with the server if the password for the user is correct.

CALLED BY:	Net library
PASS:		ds:si	- asciiz server name
		ax:bx	- asciiz login name
		cx:dx	- asciiz 
RETURN:		ax	- return code
DESTROYED:	nothing

NOTE:	assumes that workstation is already attached to server.
	we need to have a way to find out if the workstation is already
	attached before we can drop this assumption.

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWServerVerifyUserPassword	proc	near
	call	NWServerVerifyUserPasswordInternal
	ret
NWServerVerifyUserPassword	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWServerVerifyUserPasswordInternal	proc	far
loginName	local	fptr
loginPasswd	local	fptr
bufferBlock	local	hptr
reqBuffer	local	fptr
repBuffer	local	fptr
nameLen		local	byte
passwdLen	local	byte
	uses	bx,cx,dx,ds,si,es,di
	.enter
	movdw	loginName, axbx
	movdw	loginPasswd, cxdx

	;
	; check if already attached.
	;

	call	NWGetConnectionIDInternal
	tst 	dl
	jnz	gotConnectionID

	;
	; not attached yet.  go attach.  
	; if attach fails, return with non-zero al.  
	;

	call	NWServerAttachInternal		;returns dl = connection ID
	tst	al
	jz	gotConnectionID
	mov	al, 1
	jmp	done				;attach failed

gotConnectionID:
	call	NWSetPreferredConnectionIDInternal  ;set server to login into

	;
	; allocate request/reply buffers
	;

	mov	bx, size NReqBuf_VerifyBinderyObjectPassword
	mov	cx, size NRepBuf_VerifyBinderyObjectPassword
	call 	NetWareAllocRRBuffers	
	movdw	reqBuffer, essi
	movdw	repBuffer, esdi
	mov	bufferBlock, bx

	;
	; copy in name
	;
	les	di, reqBuffer
	add	di, offset NREQBUF_VBOP_objectName	
	lds	si, loginName

	clr	dx				;length count = 0

copyName:	
	lodsb
	tst	al				;test for end of string
	jz	copyNameDone
	stosb
	inc	dx				;increment length count
	cmp	dx, NW_BINDERY_OBJECT_NAME_LEN
	jb	copyName			;check for max length

copyNameDone:
	mov	nameLen, dl

	;
	; copy in password
	;

	push	es, di				;position of passwd length
	inc	di
	lds	si, loginPasswd

	clr	dx				;length count = 0

copyPasswd:
	lodsb
	tst	al				;look for end of string
	jz 	copyPasswdDone
	stosb
	inc	dx				;increment passwd length
	cmp	dx, NW_BINDERY_OBJECT_PASSWORD_LEN
	jb	copyPasswd			;check for max passwd length

copyPasswdDone:
	mov	passwdLen, dl

	;
	; calculate buffer length.  total = nameLen + passwdLen + 7
	; max length is 181, so should fit in a byte.
	;
	add	dl, nameLen
	add	dl, 7

	lds	si, reqBuffer
	mov	ds:[si].NREQBUF_VBOP_length, dx

	;
	; fill in other slots in request buffer
	;
	mov	ds:[si].NREQBUF_VBOP_subFunc, 0x3F
	mov	ds:[si].NREQBUF_VBOP_objectType, NOT_USER
	mov	dl, nameLen
	mov	ds:[si].NREQBUF_VBOP_objectNameLen, dl
	pop	ds,si
	mov	dl, passwdLen
	mov	ds:[si], dl
	
	;
	; call NetWare
	;

	les	si, reqBuffer
	les	di, repBuffer
	mov	ax, NFC_VERIFY_BINDERY_OBJECT_PASSWORD
	call	NetWareCallFunctionRR
	clr	ah

	mov	bx, bufferBlock
	call	MemFree
done:
	.leave
	ret
NWServerVerifyUserPasswordInternal	endp
NetWareCommonCode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerChangeUserPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the user's password

CALLED BY:	Net library
PASS:		ss:bx	- NetServerChangeUserPasswordFrame
RETURN:		ax	- return code
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWServerChangeUserPassword	proc	near
	call	NWServerChangeUserPasswordInternal
	ret
NWServerChangeUserPassword	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWServerChangeUserPasswordInternal	proc	far
bufferBlock	local	hptr
reqBuffer	local	fptr
repBuffer	local	fptr
nameLen		local	byte
newPasswdLen	local	byte
oldPasswdLen	local	byte
	uses	bx,cx,dx,ds,si,es,di
	.enter
	
	;	
	; check if already attached.
	;

	lds	si, ss:[bx].NSCUPF_serverName
	call	NWGetConnectionIDInternal
	tst 	dl
	jnz	gotConnectionID

	;
	; not attached yet.  go attach.  
	; if attach fails, return with non-zero al.  
	;

	call	NWServerAttachInternal		;returns dl = connection ID
	tst	al
	jz	gotConnectionID
	mov	al, 1
	jmp	done				;attach failed

gotConnectionID:
	call	NWSetPreferredConnectionIDInternal  ;set server

	;
	; allocate request/reply buffers
	;
	push	bx
	mov	bx, size NReqBuf_ChangeBinderyObjectPassword
	mov	cx, size NRepBuf_ChangeBinderyObjectPassword
	call 	NetWareAllocRRBuffers	
	movdw	reqBuffer, essi
	movdw	repBuffer, esdi
	mov	bufferBlock, bx
	pop	bx
	;
	; copy in name
	;
	les	di, reqBuffer
	add	di, offset NREQBUF_CBOP_objectName	
	lds	si, ss:[bx].NSCUPF_userName

	clr	dx				;length count = 0

copyName:	
	lodsb
	tst	al				;test for end of string
	jz	copyNameDone
	stosb
	inc	dx				;increment length count
	cmp	dx, NW_BINDERY_OBJECT_NAME_LEN
	jb	copyName			;check for max length

copyNameDone:
	mov	nameLen, dl

	;
	; copy in old password
	;

	push	es, di				;position of passwd length
	inc	di
	lds	si, ss:[bx].NSCUPF_oldPassword

	clr	dx				;length count = 0

copyOldPasswd:
	lodsb
	tst	al				;look for end of string
	jz 	copyOldPasswdDone
	stosb
	inc	dx				;increment passwd length
	cmp	dx, NW_BINDERY_OBJECT_PASSWORD_LEN
	jb	copyOldPasswd			;check for max passwd length

copyOldPasswdDone:

	;
	; save password length for calculating buffer length later.
	; fill in old password length slot now.
	;
	mov	oldPasswdLen, dl
	pop	ds,si	
	mov	ds:[si], dl

	;
	; copy in new password
	;

	push	es, di				;position of passwd length
	inc	di
	lds	si, ss:[bx].NSCUPF_newPassword

	clr	dx				;length count = 0

copyNewPasswd:
	lodsb
	tst	al				;look for end of string
	jz 	copyNewPasswdDone
	stosb
	inc	dx				;increment passwd length
	cmp	dx, NW_BINDERY_OBJECT_PASSWORD_LEN
	jb	copyNewPasswd			;check for max passwd length

copyNewPasswdDone:
	mov	newPasswdLen, dl
	pop	ds,si
	mov	ds:[si], dl

	;
	; calculate buffer length.  
	; total = nameLen + oldPasswdLen + newPasswordLen + 6
	; max length is 181, so should fit in a byte.
	;
	clr	dh
	clr	cx
	mov	cl, nameLen
	add	dx, cx
	mov	cl, oldPasswdLen
	add	dx, cx
	add	dx, 6

	lds	si, reqBuffer
	mov	ds:[si].NREQBUF_CBOP_length, dx

	;
	; fill in other slots in request buffer
	;
	mov	ds:[si].NREQBUF_CBOP_subFunc, 0x40
	mov	ds:[si].NREQBUF_CBOP_objectType, NOT_USER
	mov	dl, nameLen
	mov	ds:[si].NREQBUF_CBOP_objectNameLen, dl
	
	;
	; call NetWare
	;

	les	si, reqBuffer
	les	di, repBuffer
	mov	ax, NFC_CHANGE_BINDERY_OBJECT_PASSWORD
	call	NetWareCallFunctionRR
	clr	ah

	mov	bx, bufferBlock
	call	MemFree
done:
	.leave
	ret
NWServerChangeUserPasswordInternal	endp
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerLogin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Login to server with name and password, optionally handling 
		the incredible task of re-mapping the boot drive if necessary,
		and re-opening all of the PC/GEOS executables and R/W files.

CALLED BY:	Net Library
	
PASS:		ss:bx	- NetServerLoginFrame
RETURN:		al 	- return code

DESTROYED:	nothing

BUGS AND SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/92	Initial version
	eds&jon	4/93		Added support for reopening files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;for each R/W file that we must reopen

NEC < MAX_RW_FILE_PATH_LENGTH		equ	128			>
EC  < MAX_RW_FILE_PATH_LENGTH		equ	80			>

NWReOpenFileInfo	struc
    NWROFO_fullPath	char	MAX_RW_FILE_PATH_LENGTH	dup (?)
						;full DOS path and DOS name
    NWROFO_ownerName	nptr			;offset to name of owner
    NWROFO_accessFlags	byte			;AccessFlags
    NWROFO_fileHandle	hptr			;file handle
NWReOpenFileInfo	ends

;The structure of our stack frame, which holds info for 4 files to reopen
;plus some other stuff. (Is inherited by routines we call.)

LoginFrame	struc
    LF_file1		NWReOpenFileInfo
    LF_file2		NWReOpenFileInfo
    LF_file3		NWReOpenFileInfo
    LF_file4		NWReOpenFileInfo
    LF_file5		NWReOpenFileInfo
if ERROR_CHECK
    LF_file6		NWReOpenFileInfo
    LF_file7		NWReOpenFileInfo
    LF_file8		NWReOpenFileInfo
    LF_file9		NWReOpenFileInfo
;   LF_file10		NWReOpenFileInfo
;   LF_file11		NWReOpenFileInfo
endif
    LF_loginName	fptr
    LF_loginPasswd	fptr		
    LF_bufferBlock	hptr
    LF_reqBuffer	fptr
    LF_repBuffer	fptr
    LF_nameLen		word
    LF_passwdLen	word		
    LF_kernelDGroup	word
    LF_bootDriveLetter	byte
    LF_bootDriveLetterNull byte		;null term, since we point to
					;LF_bootDriveLetter as a string.
    LF_netwareOffset	word
    LF_accessMode	FileAccessFlags
    LF_curGeodeName	char GEODE_NAME_SIZE dup (?)
    LF_connectionID	byte		;connection ID for server.
    LF_systemDisk		word
    LF_allocBlock		hptr
    LF_allocRequestBuffer	fptr
    LF_allocReplyBuffer		fptr
    LF_reopenFiles		byte
    LF_commandComBuf	fptr.char	; Buffer within primary command
					;  interpreter that holds path
					;  to COMMAND.COM that will be
					;  altered by netx
    LF_comspec		char MSDOS_PATH_BUFFER_SIZE dup(?)
    align word
LoginFrame	ends

;------

NetWareResidentCode	segment resource

NWServerLogin	proc	near
	call	NWServerLoginInternal
	ret
NWServerLogin	endp

NetWareResidentCode	ends

;------

NetWareCommonCode	segment resource

;this is the Wizard-specific login ID with no password.
schoolviewIDStr		char	"SCHOOLVIEW_ID"
schoolviewIDStrLen 	equ	$-schoolviewIDStr

NWServerLoginInternal	proc	far

	loginVars	local	LoginFrame

	uses	bx,cx,dx,si,di,ds,es

	.enter

	movdw	loginVars.LF_loginName, ss:[bx].NSLF_userName, dx
	movdw	loginVars.LF_loginPasswd, ss:[bx].NSLF_password, dx
	lds	si, ss:[bx].NSLF_serverName
	mov	cl, ss:[bx].NSLF_reopenFiles
	mov	loginVars.LF_reopenFiles, cl

	call	NWServerLoginComspecHackInit

	;
	; check if already attached.
	;

	call	NWGetConnectionIDInternal
	tst	dl
	jnz 	doLogin

	;
	; not attached yet.  call attach and get connection ID
	;

	call	NWServerAttachInternal	;returns dl = conn ID.
	tst	al
	jz	doLogin
	jmp	done			;al is not 0.

doLogin:
	;server is now attached, dl = connection ID
	mov	loginVars.LF_connectionID, dl
	call	NWSetPreferredConnectionIDInternal

	mov	bx, size NReqBuf_LoginToFileServer
	mov	cx, size NRepBuf_LoginToFileServer
	call	NetWareAllocRRBuffers	;ret: es:si = req. buffer
					;     es:di = reply buffer
					;     ^hbx  = buffer block
	mov	loginVars.LF_bufferBlock, bx
	movdw	loginVars.LF_reqBuffer, essi
	movdw	loginVars.LF_repBuffer, esdi

	;copy login name string
	;set es:di = destination for login name
	;    ds:si = login name string
	les	di, loginVars.LF_reqBuffer
	add	di, offset NREQBUF_LFS_objectName
	lds	si, loginVars.LF_loginName

	clr	dx		;length count = 0
copyName:
	lodsb
	tst	al		;test for end of string
	jz	copyNameDone

	stosb
	inc 	dx		;increment count
	cmp	dx, NW_BINDERY_OBJECT_NAME_LEN
	jb	copyName	;max 47 characters

copyNameDone:
	mov	loginVars.LF_nameLen, dx
	
	;copy password
	;set es:di = destination for password
	;    ds:si = password string

	push	es, di		;save position of password length

	inc	di		;skip password length byte
	lds	si, loginVars.LF_loginPasswd

	clr 	dx		;passwd length = 0;
	
copyPasswd:
	lodsb
	tst	al		;look for end of string
	jz 	copyPasswdDone
	
	stosb
	inc	dx		;increment passwd length
	cmp	dx, NW_BINDERY_OBJECT_PASSWORD_LEN
	jb	copyPasswd	;check for max passwd length

copyPasswdDone:
	mov	loginVars.LF_passwdLen, dx

	;fill in other slots in request buffer
	les	di, loginVars.LF_reqBuffer

	;calculate buffer length
	;len = nameLen + passwdLen + 5

	mov	dx, 5
	add	dx, loginVars.LF_passwdLen
	add	dx, loginVars.LF_nameLen
	mov	es:[di].NREQBUF_LFS_length, dx
	mov	es:[di].NREQBUF_LFS_subFunc, 0x14
	mov	es:[di].NREQBUF_LFS_objectType, NOT_USER
	mov	dx, loginVars.LF_nameLen
	mov	es:[di].NREQBUF_LFS_objectNameLen, dl

	pop	es, di			;recover position of passwd length
	mov	dx, loginVars.LF_passwdLen
	mov	es:[di], dl

	;
	; only reopen files if asked to
	;
	mov	cl, loginVars.LF_reopenFiles
	tst	cl
	LONG jz	callNetWare

;------------------------------------------------------------------------------
buildFullPathAndFileNames::
	;
	;  Build the filenames for the swap and state files before closing
	;

	segmov	es, ss, ax			;es = stack frame segment
	segmov	ds, cs, ax

	mov	bx, file1_stdPath		;bx = StandardPath to base on
	mov	si, offset file1_name		;ds:si = source path name
	lea	di, loginVars.LF_file1.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file1.NWROFO_ownerName, offset file1_owner
	mov	loginVars.LF_file1.NWROFO_accessFlags, file1_flags
	clr	loginVars.LF_file1.NWROFO_fileHandle

	mov	bx, file2_stdPath		;bx = StandardPath to base on
	mov	si, offset file2_name		;ds:si = source path name
	lea	di, loginVars.LF_file2.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file2.NWROFO_ownerName, offset file2_owner
	mov	loginVars.LF_file2.NWROFO_accessFlags, file2_flags
	clr	loginVars.LF_file2.NWROFO_fileHandle

	mov	bx, file3_stdPath		;bx = StandardPath to base on
	mov	si, offset file3_name		;ds:si = source path name
	lea	di, loginVars.LF_file3.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	rep movsb		;  This one is special; just copy it straight
	mov	loginVars.LF_file3.NWROFO_ownerName, offset file3_owner
	mov	loginVars.LF_file3.NWROFO_accessFlags, file3_flags
	clr	loginVars.LF_file3.NWROFO_fileHandle

	mov	bx, file4_stdPath		;bx = StandardPath to base on
	mov	si, offset file4_name		;ds:si = source path name
	lea	di, loginVars.LF_file4.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file4.NWROFO_ownerName, offset file4_owner
	mov	loginVars.LF_file4.NWROFO_accessFlags, file4_flags
	clr	loginVars.LF_file4.NWROFO_fileHandle

	mov	bx, file5_stdPath		;bx = StandardPath to base on
	mov	si, offset file5_name		;ds:si = source path name
	lea	di, loginVars.LF_file5.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file5.NWROFO_ownerName, offset file5_owner
	mov	loginVars.LF_file5.NWROFO_accessFlags, file5_flags
	clr	loginVars.LF_file5.NWROFO_fileHandle

if ERROR_CHECK
	mov	bx, file6_stdPath		;bx = StandardPath to base on
	mov	si, offset file6_name		;ds:si = source path name
	lea	di, loginVars.LF_file6.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file6.NWROFO_ownerName, offset file6_owner
	mov	loginVars.LF_file6.NWROFO_accessFlags, file6_flags
	clr	loginVars.LF_file6.NWROFO_fileHandle

	mov	bx, file7_stdPath		;bx = StandardPath to base on
	mov	si, offset file7_name		;ds:si = source path name
	lea	di, loginVars.LF_file7.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file7.NWROFO_ownerName, offset file7_owner
	mov	loginVars.LF_file7.NWROFO_accessFlags, file7_flags
	clr	loginVars.LF_file7.NWROFO_fileHandle

	mov	bx, file8_stdPath		;bx = StandardPath to base on
	mov	si, offset file8_name		;ds:si = source path name
	lea	di, loginVars.LF_file8.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file8.NWROFO_ownerName, offset file8_owner
	mov	loginVars.LF_file8.NWROFO_accessFlags, file8_flags
	clr	loginVars.LF_file8.NWROFO_fileHandle

	mov	bx, file9_stdPath		;bx = StandardPath to base on
	mov	si, offset file9_name		;ds:si = source path name
	lea	di, loginVars.LF_file9.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file9.NWROFO_ownerName, offset file9_owner
	mov	loginVars.LF_file9.NWROFO_accessFlags, file9_flags
	clr	loginVars.LF_file9.NWROFO_fileHandle

if 0
	mov	bx, file10_stdPath		;bx = StandardPath to base on
	mov	si, offset file10_name		;ds:si = source path name
	lea	di, loginVars.LF_file10.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file10.NWROFO_ownerName, offset file10_owner
	mov	loginVars.LF_file10.NWROFO_accessFlags, file10_flags
	clr	loginVars.LF_file10.NWROFO_fileHandle

	mov	bx, file11_stdPath		;bx = StandardPath to base on
	mov	si, offset file11_name		;ds:si = source path name
	lea	di, loginVars.LF_file11.NWROFO_fullPath	;es:di = dest
	mov	cx, MAX_RW_FILE_PATH_LENGTH
	clr	dx
	call	FileConstructFullPath
	mov	loginVars.LF_file11.NWROFO_ownerName, offset file11_owner
	mov	loginVars.LF_file11.NWROFO_accessFlags, file11_flags
	clr	loginVars.LF_file11.NWROFO_fileHandle
endif
endif

findBootDrive::
	;Figure out which drive letter we were booted from. On networks,
	;will typically be F: or G:. At present, we are assuming that all of
	;the important system files were opened using this drive letter,
	;and we reopen all of them. In the future, we really should be remapping
	;ALL of the network drives that we have open files on. That will
	;also be important when the boot drive is not a network drive,
	;but some files have still been opened on network drives.

	mov	ax, SGIT_HANDLE_TABLE_SEGMENT
	call	SysGetInfo
	mov	loginVars.LF_kernelDGroup, ax
	mov	ax, SGIT_SYSTEM_DISK
	call	SysGetInfo			;ax = disk handle
	mov	loginVars.LF_systemDisk, ax
	mov	bx, ax
	call	DiskGetDrive			;al = Drive number (0-31)
	add	al, 'A'				;make it a drive letter
	mov	loginVars.LF_bootDriveLetter, al
	mov	loginVars.LF_bootDriveLetterNull, 0

grabSem::

	;
	;  Lock down all of the primary file system driver's resources
	;

	call	NWLockPrimaryFSDResources

	;
	;  Allocate request & reply buffers for allocating a permanent
	;  directory handle in NWReopenExtraneouslyClosedFiles. We're
	;  doing it here so we don't allocate any memory while the swap
	;  file is closed.
	;

	mov	bx, size NReqBuf_AllocPermDirHandle
	mov	cx, size NRepBuf_AllocPermDirHandle
	call	NetWareAllocRRBuffers	;ret: es:si = req. buffer
					;     es:di = reply buffer
					;     ^hbx  = buffer block

	mov	ss:[loginVars].LF_allocBlock, bx
	movdw	ss:[loginVars].LF_allocRequestBuffer, essi
	movdw	ss:[loginVars].LF_allocReplyBuffer, esdi

	;
	;  Figure out which file handles will need reopening *before* we
	;  login, etc., since identifiying the proper files requires locking
	;  down swappable core blocks, which might not be available once
	;  the swap file is closed...
	;

	call	FSDLockInfoExcl			;sets ax = FSInfoHeader
	push	ax				;save for later
	mov	es, ax
	mov	dx, ax
	mov	bx, offset netwareDrName	;cs:bx = geode name to find
	call	NWFindFSDriver			;es:si = FSD for NetWareFSD
	mov	ss:[loginVars].LF_netwareOffset, si
	clr	bx				;start with first file handle
	mov	di, cs				;di:si = callback
	mov	si, offset NWDetermineFilesToReopen_callback
	call	FileForEach			;or DosUtilFileForEach

	;
	; grab some very high-level semaphores that prevent anyone from
	; messing with file handles, FSInfoResource, and drives.
	;

	call	SysLockBIOS
	call	SysEnterCritical
	pop	es				;es = FSInfoHeader

;##############################################################################
;##############################################################################
;	FROM THIS POINT FORWARD, ALL CODE AND DATA ACCESSED MUST BE RESIDENT,
;	AND YOU CANNOT CALL ANYTHING WHICH WILL GRAB THE SAME SEMAPHORES
;	AS THE ABOVE CODE. STAY TUNED FOR FURTHER UPDATES.
;##############################################################################
;##############################################################################

	;find the MegaFile FS driver, so that we can talk to it

	mov	bx, offset megafileDrName	;cs:bx = geode name to find
	call	NWFindFSDriver			;es:si = FSDriver for MegaFS
EC <	tst	si							>
EC <	ERROR_Z NW_ERROR_GASP_CHOKE_WHEEZE				>

	;Tell the MegaFile driver to close its megafile

	mov	di, DR_MFS_CLOSE_MEGAFILE
	call	es:[si].FSD_strategy
EC <	ERROR_C	NW_ERROR_CANNOT_CLOSE_MEGAFILE				>

	;
	;  Close all files opened by netware.
	;
	push	si
	mov	cx, ss:[loginVars].LF_netwareOffset
	mov	dx, es
	clr	bx				;start with first file handle
	mov	di, cs				;di:si = callback
	mov	si, offset NWClearOldSFNs_callback
	call	FileForEach			;or DosUtilFileForEach
	pop	si

if 0	; not needed, since we're locking it all down, anyways

	;
	;  Load the code necessary to reopen files and hope it doesn't
	;  get discarded before we actually need it...
	;

		push	bp
		mov	bp, ss:[loginVars].LF_netwareOffset
		mov	ah, FSAOF_REOPEN
		clr	cl				;don't do anything
		mov	di, DR_FS_ALLOC_OP
		call	es:[bp].FSD_strategy		;does not trash BX
							;returns AL, DX
		pop	bp
endif

	;first logout from the server to clean up drive mappings and whatever
	;other stuff.

	push	si, es
	mov	ax, NFC_LOGOUT_FROM_FILE_SERVER
	mov	dl, loginVars.LF_connectionID
	call	NetWareCallFunction
	pop	si, es
	
callNetWare:
	;call netware to login

	push	si, es

	les	si, loginVars.LF_reqBuffer
	les	di, loginVars.LF_repBuffer
	mov	ax, NFC_LOGIN_TO_FILE_SERVER
	call	NetWareCallFunctionRR

	pop	si, es				;es = FSInfoResource
						;es:si = FSDriver for MegaFS

	mov	cl, loginVars.LF_reopenFiles
	tst	cl
	LONG jz	done

;##############################################################################
;##############################################################################
;	ALL DRIVES MAPPED TO THAT SERVER HAVE BEEN NUKED, AND ALL FILES OPENED
;	ON THOSE DRIVES HAVE BEEN CLOSED.
;##############################################################################
;##############################################################################

	push	ax

	; WARNING: THIS SECTION IS WIZARD-SPECIFIC.  	
	;
	; If NFC_LOGIN_TO_FILE_SERVER failed, then we must login as
	; SCHOOLVIEW_ID, so that we will at least be able to remap drives 
	; and reopen files, preventing a horrible crash.
	;

	tst	al
	jz	loginSuccessful

	; check for the case where the password expired, but login 
	; was successful anyways due to a grace login.
	cmp	al, NRC_PASSWORD_EXPIRED		
	je	loginSuccessful

	push	es, si
	mov	ax, NFC_LOGOUT_FROM_FILE_SERVER
	mov	dl, loginVars.LF_connectionID
	call	NetWareCallFunction

	mov	bx, size NReqBuf_LoginToFileServer
	mov	cx, size NRepBuf_LoginToFileServer
	call	NetWareAllocRRBuffers	;ret: es:si = req. buffer
					;     es:di = reply buffer
					;     ^hbx  = buffer block
	push	si, di					
	; length = name length + passwd length + 5 = 18
	mov	es:[si].NREQBUF_LFS_length, 18
	mov	es:[si].NREQBUF_LFS_subFunc, low NFC_LOGIN_TO_FILE_SERVER
	mov	es:[si].NREQBUF_LFS_objectType, NOT_USER
	mov	{byte} es:[si].NREQBUF_LFS_objectNameLen, 13
	mov	di, si
	add	di, NREQBUF_LFS_objectName	;es:di = name buffer
	segmov	ds, cs
	mov	si, offset cs:[schoolviewIDStr]	;ds:si = "SCHOOLVIEW_ID"
	mov	cx, schoolviewIDStrLen
	rep	movsb
	clr	ax
	stosb					;password length
	pop	si, di
	segmov	ds, es

	mov	ax, NFC_LOGIN_TO_FILE_SERVER
	call	NetWareCallFunctionRR
	call	MemFree
	pop	es, si
	
	; if we even fail to login as SCHOOLVIEW_ID, then we're surely 
	; hosed.
EC <	tst	al							>
EC <	ERROR_NZ NW_ERROR_GASP_CHOKE_WHEEZE				>

loginSuccessful:
	;
	; Reopen all of the read-only and read/write files for GEOS
	;
	call	NWReopenExtraneouslyClosedFiles
	;
	;  Release the semaphores now that the file handle table is fixed up
	;
	call	SysExitCritical
	call	SysUnlockBIOS
	call	FSDUnlockInfoExcl
	;
	;  Unlock all of the primary file system driver's resources
	;
	call	NWUnlockPrimaryFSDResources

	call	NWServerLoginComspecHack

	mov	bx, loginVars.LF_bufferBlock
	call	MemFree
	mov	bx, loginVars.LF_allocBlock
	call	MemFree
	pop	ax

;##############################################################################
;##############################################################################
;	ALL IS WELL. HAVE A NICE DAY. :)
;##############################################################################
;##############################################################################

done:
	.leave
	ret
NWServerLoginInternal	endp

;The following is a list of special R/W files that we must reopen after
;reopening the megafile. (For the EC version only, there is also a list
;of executables included, in case you have them downloaded locally, and
;not in the megafile.)

NEC<LOGIN_NUMBER_OF_RWFILES	equ	5	>
EC< LOGIN_NUMBER_OF_RWFILES	equ	10	>

.assert (GEODE_NAME_SIZE eq 8)

file1_stdPath		equ	SP_TOP			;standard path
NEC <file1_name		char	"GEOS.INI", 0		;filename	>
EC < file1_name		char	"GEOSEC.INI", 0		;filename	>
file1_owner		char	"geos    "		;perm name of owner
file1_flags		equ	FILE_DENY_RW or FILE_ACCESS_RW

file2_stdPath		equ	SP_PRIVATE_DATA		;standard path
file2_name		char	"SWAP", 0		;filename
file2_owner		char	"geos    "		;perm name of owner
file2_flags		equ	FILE_DENY_RW or FILE_ACCESS_RW \
					or mask FFAF_EXCLUSIVE

file3_stdPath		equ	SP_NOT_STANDARD_PATH	;standard path
if ERROR_CHECK
file3_name		char	"\\LOGIN\\GEOWORKS.EC\\SYSOP\\PRIVDATA\\TOKEN_DA.000",0
else
file3_name		char	"\\LOGIN\\GEOWORKS\\SYSOP\\PRIVDATA\\TOKEN_DA.000",0
endif
file3_owner		char	"ui      "		;perm name of owner
file3_flags		equ	FILE_DENY_W or FILE_ACCESS_R

file4_stdPath		equ	SP_STATE		;standard path
file4_name		char	"UI_STATE.000", 0	;filename
file4_owner		char	"ui          "		;perm name of owner
file4_flags		equ	FILE_DENY_W or FILE_ACCESS_RW

file5_stdPath		equ	SP_STATE		;standard path
file5_name		char	"ISTARTUP.000", 0	;filename
file5_owner		char	"istartup"		;perm name of owner
file5_flags		equ	FILE_DENY_W or FILE_ACCESS_RW

if ERROR_CHECK

file6_stdPath		equ	SP_SYSTEM		;standard path
file6_name		char	"NET\\NWEC.GEO", 0	;filename
file6_owner		char	"nw      "		;perm name of owner
file6_flags		equ	FILE_DENY_W or FILE_ACCESS_R

file7_stdPath		equ	SP_SYS_APPLICATION	;standard path
file7_name		char	"LOGINEC.GEO", 0	;filename
file7_owner		char	"login   "		;perm name of owner
file7_flags		equ	FILE_DENY_W or FILE_ACCESS_R

file8_stdPath		equ	SP_SYS_APPLICATION	;standard path
file8_name		char	"ISTARTUP.GEO", 0	;filename
file8_owner		char	"istartup"		;perm name of owner
file8_flags		equ	FILE_DENY_W or FILE_ACCESS_R

file9_stdPath		equ	SP_SYSTEM		;standard path
file9_name		char	"NETEC.GEO", 0	;filename
file9_owner		char	"net     "		;perm name of owner
file9_flags		equ	FILE_DENY_W or FILE_ACCESS_R

if 0
file10_stdPath		equ	SP_SYSTEM		;standard path
file10_name		char	"NETEC.GEO", 0		;filename
file10_owner		char	"net     "		;perm name of owner
file10_flags		equ	FILE_DENY_W or FILE_ACCESS_R

file11_stdPath		equ	SP_SYSTEM		;standard path
file11_name		char	"NETEC.GEO", 0		;filename
file11_owner		char	"net     "		;perm name of owner
file11_flags		equ	FILE_DENY_W or FILE_ACCESS_R

endif

;IMPORTANT: DO NOT ADD THE KERNEL OR ANY OF THE FS DRIVERS TO THIS LIST!
;You see: normally we have all of the kernel and FS driver code available for
;swapping in, once we have opened the megafile. However, if your kernel
;and/or FS drivers are local, they will NOT be reopened until we start to
;scan this list, which may be too late.

endif

;pass	es = FSInfoHeader (locked)
;	bx = offset to geode name to look for

NWFindFSDriver	proc	near
	uses	ds
	.enter

	segmov	ds, cs, ax		;ds:si = the name we are looking for
	mov	di, es:[FIH_fsdList]	;es:di = FSDriver structure for 1st FSD

megaSearchLoop:
	;see if this is the FSD that we want

	push	di
	add	di, offset FSD_name	;es:di = name of this FSD
	mov	si, bx			;ds:si = geode name we are looking for
	mov	cx, GEODE_NAME_SIZE
	repe	cmpsb
	pop	di
	mov	si, di
	je	done			;skip if found it...

	mov	di, es:[di].FSD_next	;es:di = [214znext FSDriver structure
	tst	di
	jnz	megaSearchLoop

	mov	si, di			;si = 0

done:
	.leave
	ret
NWFindFSDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerLoginComspecHackInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare for the horrible hack that will occur once we're
		logged in again, when we will restore the buffer within the
		command interpreter that holds the path to COMMAND.COM,
		which NETX biffed during our logout.

CALLED BY:	(INTERNAL) NWServerLoginInternal
PASS:		ss:bp	= inherited frame
RETURN:		LF_commandComBuf, LF_comspec set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nwComspecStr	char	'COMSPEC', 0
NWServerLoginComspecHackInit proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter	inherit	NWServerLoginInternal
	;
	; Assume we won't be able to find it.
	; 
	mov	ss:[loginVars].LF_commandComBuf.segment, 0
	;
	; First find out what COMSPEC is currently, so we can use that to
	; find the buffer within the command interpreter.
	; 
	segmov	ds, cs
	segmov	es, ss
	mov	si, offset nwComspecStr
	lea	di, ss:[loginVars].LF_comspec
	mov	cx, size LF_comspec
	call	SysGetDosEnvironment
	jnc	findInterpreter
	jmp	done

findInterpreter:
	;
	; Now walk the PSP chain looking for one whose parent is itself. This
	; is the primary command interpreter.
	; 
	mov	ah, MSDOS_GET_PSP
	call	FileInt21		; bx <- PSP

findInterpreterLoop:
	mov	ax, bx
	mov	es, bx			; es <- PSP to check
	mov	bx, es:[PSP_parentId]	; bx <- next PSP
	cmp	bx, ax			; same as this one?
	jne	findInterpreterLoop	; no -- keep looking
	
	;
	; ES is now the segment of the resident portion of the command
	; interpreter. Search through at most 64K looking for what's in the
	; COMSPEC variable we received. If it's not there, we assume there's
	; nothing we need to do.
	; 
	clr	cx
	mov	bx, size ProgramSegmentPrefix-1
	segmov	ds, ss
findLoop:
	inc	bx		; advance to next byte in command.com
	lea	si, ss:[loginVars].LF_comspec
	mov	di, bx
compareLoop:
	lodsb
	scasb
	jne	compareDone
	tst	al
	jnz	compareLoop

compareDone:
	loopne	findLoop

	movdw	ss:[loginVars].LF_commandComBuf, esbx
done:
	.leave
	ret
NWServerLoginComspecHackInit endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerLoginComspecHack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we found the buffer in the primary interpreter, restore
		its contents from our COMSPEC variable (see above)

CALLED BY:	(INTERNAL) NWServerLoginInternal
PASS:		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWServerLoginComspecHack proc	near
	uses	ax, si, di, ds, es
	.enter	inherit	NWServerLoginInternal
	tst	ss:[loginVars].LF_commandComBuf.segment
	jz	done
	;
	; Always copy the thing in (up to and including the null byte), as if
	; it hasn't changed, this causes no harm, and if it has changed, we
	; want it changed back again.
	; 
	les	di, ss:[loginVars].LF_commandComBuf
	segmov	ds, ss
	lea	si, ss:[loginVars].LF_comspec
copyLoop:
	lodsb
	stosb
	tst	al
	jnz	copyLoop
done:
	.leave
	ret
NWServerLoginComspecHack endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWReopenExtraneouslyClosedFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This routine is responsible for re-opening the files
		that were closed by logging in.

Pass:		es	= FSInfoResource (locked exclusively)
		ss:bp	= NWReOpenFrame (list of files to reopen)
		es:si	= FSDriver for the MegaFile FS driver

Return:		es, bp = same

Destroyed:	all others

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 16, 1993 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NWReopenExtraneouslyClosedFiles	proc	far
	uses	bp, es

	loginVars	local	LoginFrame

	.enter	inherit

;##############################################################################
;##############################################################################
;	REMINDER: BY THIS POINT,
;	ALL DRIVES MAPPED TO THAT SERVER HAVE BEEN NUKED, AND ALL FILES OPENED
;	ON THOSE DRIVES HAVE BEEN CLOSED.
;##############################################################################
;##############################################################################

	push	si

;------------------------------------------------------------------------------
remapBootDrive::
	;we must immediately re-map the drive that we booted from

	push	es

	mov	bx, ss:[loginVars].LF_allocBlock
	movdw	dssi, ss:[loginVars].LF_allocRequestBuffer
	movdw	esdi, ss:[loginVars].LF_allocReplyBuffer

LENGTH_SYS_LOGIN_PATH_NAME	equ	9

	push	bx
	mov	cx, LENGTH_SYS_LOGIN_PATH_NAME	;length of string, no null term

	mov	ds:[si].NREQBUF_APDH_subfunc, 
			low NFC_ALLOC_PERMANENT_DIRECTORY_HANDLE
	mov	ds:[si].NREQBUF_APDH_dirHandle, 0

	mov	al, loginVars.LF_bootDriveLetter
	mov	ds:[si].NREQBUF_APDH_driveLetter, al

	mov	ds:[si].NREQBUF_APDH_pathLength, cl

	add	cx, offset NREQBUF_APDH_path - size NREQBUF_APDH_length
	mov	ds:[si].NREQBUF_APDH_length, cx

	mov	ds:[si].NREQBUF_APDH_path+0, 'S'
	mov	ds:[si].NREQBUF_APDH_path+1, 'Y'
	mov	ds:[si].NREQBUF_APDH_path+2, 'S'
	mov	ds:[si].NREQBUF_APDH_path+3, ':'
	mov	ds:[si].NREQBUF_APDH_path+4, 'L'
	mov	ds:[si].NREQBUF_APDH_path+5, 'O'
	mov	ds:[si].NREQBUF_APDH_path+6, 'G'
	mov	ds:[si].NREQBUF_APDH_path+7, 'I'
	mov	ds:[si].NREQBUF_APDH_path+8, 'N'
	mov	ds:[si].NREQBUF_APDH_path+9, 0

	mov	ax, NFC_ALLOC_PERMANENT_DIRECTORY_HANDLE
	call	NetWareCallFunction
EC <	tst	al			;die if we can't remap that drive >
EC <	ERROR_NZ NW_ERROR_CANNOT_REMAP_LOGIN_DRIVE			  >

	pop	bx

	; moved MemFree out of the critical section due to the random
	; logout crash
	; call	MemFree
	pop	es
	pop	si

;##############################################################################
;##############################################################################
;	WE NOW HAVE THE LOGIN DRIVE MAPPED. WE MUST REOPEN THE MEGAFILE
;	NEXT, BUT ONLY USING CODE THAT IS RESIDENT.
;##############################################################################
;##############################################################################

reopenMegaFile::
	; Call the MegaFile driver so it can re-open its files

	mov	di, DR_MFS_REOPEN_MEGAFILE
	call	es:[si].FSD_strategy
EC <	ERROR_C	NW_ERROR_CANNOT_REOPEN_MEGAFILE				>

;##############################################################################
;##############################################################################
;	THE MEGAFILE HAS BEEN REOPENED, SO WE CAN CALL NON-RESIDENT CODE
;	RESOURCES THAT ARE IN GEODES IN THAT FILE. THE NEXT STEP IS TO
;	MAKE SURE THAT PC/GEOS REALLY KNOWS ABOUT THIS NEW DRIVE LETTER.
;	(I guess this was not necessary when re-opening the megafile.)
;##############################################################################
;##############################################################################

findNetware::
	;find the MegaFile FS driver, so that we can talk to it

	mov	bx, offset netwareDrName	;cs:bx = geode name to find
	call	NWFindFSDriver			;es:si = FSDriver for NetWareFSD
EC <	tst	si							>
EC <	ERROR_Z NW_ERROR_GASP_CHOKE_WHEEZE				>

if 0	;------------removed because it forces the swap file to be read:

;	ERROR_C CANNOT_READ_SWAP_FILE
;	(login:0) 50 => w
;	  1: near FatalError(), bootBoot.asm:633
;	  2:  far AppFatalError(), bootBoot.asm:633
;	* 3:  far DiskReadPage(), disk.asm:539
;	  4:  far SwapRead(), swap.asm:498
;	  5: near DiskSwapIn(), disk.asm:249
;	  6:  far DiskStrategy(), disk.asm:177
;	  7: near CallSwapDriver(), heapSwap.asm:914
;	  8:  far MemSwapInLow(), heapSwap.asm:812
;	  9: near MemSwapIn(), heapSwap.asm:743
;	 10: near FullLockNoReload(), heapLow.asm:180
;	 11: near NearLock(), heapHigh.asm:853
;	 12: near NearPLock(), heapHigh.asm:759
;	 13:  far MemPLock(), heapHigh.asm:745
;	 14: near LockGCNBlock(), lmemGCNList.asm:1412
;	 15:  far GCNListSend(), lmemGCNList.asm:1183
;	 16:  far GCNListRecordAndSend(), lmemGCNList.asm:1115
;	 17:  far ResourceCallInt(), geodesResource.asm:1848
;	 18: near FSDNotifyDriveCommon(), fsdDrive.asm:482
;	 19: near FSDNotifyDriveCreated(), fsdDrive.asm:398
;	 20:  far FSDInitDrive(), fsdDrive.asm:284

	;
	; call FSDInitDrive to tell the rest of the system 
	; that we just added a new drive.
	;

	mov	ah, MEDIA_FIXED_DISK
	mov	al, loginVars.LF_bootDriveLetter
	sub	al, 'A'
 	clr     bx                      ; no private data
	mov     cx, DriveExtendedStatus <
                                0,              ; drive may be available over
                                                ;  net
                                0,              ; drive not read-only
                                0,              ; drive cannot be formatted
                                0,              ; drive not an alias
                                0,              ; drive not busy
                                <
                                    1,          ; drive is present
                                    0,          ; assume not removable
                                    1,          ; assume is network
                                    DRIVE_FIXED ; assume fixed
                                >
                        >
	mov	dx, si				;dx <- driver offset
	push	dx				;save netware offset
	push	ds
	segmov	ds, ss, si			;ds:si = string for drive
						;letter
THIS CODE IS DISABLED (SEE THE CONDITIONAL ABOVE)

	lea	si, loginVars.LF_bootDriveLetter
	call	FSDInitDrive
	pop	ds
	pop	cx				;cx <- netware FSD offset
else
	mov	cx, si				;cx <- netware FSD offset
endif

;##############################################################################
;##############################################################################
;	NOW WE HAVE TO REOPEN OUR LIST OF FILES.
;##############################################################################
;##############################################################################

clearOldSFNs::
	mov	dx, es				;pass dx = FSInfoHeader
						;pass ss:bp = rwFileList

if 0	;moved up...
	;
	;  Clear out the old SFN stuff
	;

	clr	bx				;start with first file handle
	mov	di, cs				;di:si = callback
	mov	si, offset NWClearOldSFNs_callback
	call	FileForEach			;or DosUtilFileForEach
endif

openNewFiles::
	;
	;  Reopen the new files
	;

	clr	bx				;start with first file handle
	mov	di, cs				;di:si = callback
	mov	si, offset NWReOpenFiles_callback
	call	FileForEach			;or DosUtilFileForEach

;##############################################################################
;##############################################################################
;	ALMOST HOME FREE; WE STILL OWN FAR TOO MANY SEMAPHORES.
;	RETURN TO CLEAN THAT UP...
;##############################################################################
;##############################################################################

	.leave
	ret
NWReopenExtraneouslyClosedFiles	endp

megafileDrName	char	"megafile"		;8 character geode name
netwareDrName	char	"netware "		;8 character geode name


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWClearOldSFNs_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Clears out the old entries in the dosFileTable

Pass:		bx	= file handle (from FileForEach)
		cx 	= NetWare FSD offset
		dx	= FSInfoResource (locked exclusively)
		ss:bp	= NWReOpenFrame (list of files to reopen)

Return:		bx, dx, ss:bp = same

		carry clear to continue processing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 16, 1993 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NWClearOldSFNs_callback	proc	far
	uses	ax, bx, cx, dx, bp, di, si, ds, es
	.enter

	;
	;  If the file was opened by netware, close it. We do this by
	;  comparing the file's disk's drive's fsd against the passed fsd
	;

	mov	es, dx
	mov	si, ds:[bx].HF_disk		;es:si <- DiskDesc
	mov	bp, es:[si].DD_drive		;es:bp <- DriveStatusEntry
	mov	bp, es:[bp].DSE_fsd		;es:bp <- FSD
	cmp	bp, cx
	jne	nextFile

	;
	;  the file was opened by netware, so tell the primary FSD to forget
	;  about it
	;

	mov	ah, FSHOF_FORGET
	mov	di, DR_FS_HANDLE_OP
	call	es:[bp].FSD_strategy

nextFile:
	clc
	.leave
	ret
NWClearOldSFNs_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWReOpenFiles_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Determines whether the passed file handle is one of the
		"special" ones that needs to be reopened. The known
		special files are:

			* the swap file
			* the istartup state file
			* the shared TOKEN.DB file

Pass:		bx	= file handle (from FileForEach)
		cx	= offset of netware FSD
		dx	= FSInfoResource (locked exclusively)
		ss:bp	= NWReOpenFrame (list of files to reopen)

Return:		bx, dx, ss:bp = same

		carry clear to continue processing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 16, 1993 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWReOpenFiles_callback	proc	far

		loginVars	local	LoginFrame

		uses	ax, bx, cx, dx, bp, di, si, ds, es
		.enter	inherit

	;
	; See if this file is one of the one's we want to reopen
	;

		segmov	ds, ss, ax
		mov	cx, LOGIN_NUMBER_OF_RWFILES
		lea	si, loginVars.LF_file1	;ss:si = first NWReOpenFileInfo
						;		structure
searchLoop:

		tst	ds:[si].NWROFO_fileHandle
		jz	checkNextFileInList

		cmp	bx, ds:[si].NWROFO_fileHandle
		je	openFile

checkNextFileInList:
		add	si, size NWReOpenFileInfo
		loop	searchLoop

nextFileHandle:
		clc

		.leave
		ret

openFile::
	;
	; Reopen this file:
	;	ds:[si].NWROFO_fullPath	= name
	;	bx			= file handle

		push	bx
		mov	es, dx				;es = FSInfoHeader

		.assert (offset NWROFO_fullPath eq 0)

		mov	dx, si				;ds:dx = path name
		mov	si, loginVars.LF_kernelDGroup
		mov	ds, si

	;
	; We want to use the system disk no matter what
	;
		mov	si, ss:[loginVars].LF_systemDisk
		mov	ds:[bx].HF_disk, si
		mov	cl, ds:[bx].HF_sfn		;pass old sfn to DOS
		mov	al, ds:[bx].HF_accessFlags
		and	al, mask FFAF_MODE
		mov	cl, 0xff			;do it!
		mov	ah, FSAOF_REOPEN

		push	bp
		mov	bp, es:[si].DD_drive
		mov	bp, es:[bp].DSE_fsd

		segmov	ds, ss, di			;ds:dx <- name

		mov	di, DR_FS_ALLOC_OP
		call	es:[bp].FSD_strategy		;does not trash BX
							;returns AL, DX

EC<		ERROR_C	NW_ERROR_COULDNT_REOPEN_CLOSED_FILE	>

		pop	bp
		pop	bx

	;
	;  Store the new values in the file handle
	;

		mov	di, loginVars.LF_kernelDGroup
		mov	ds, di

		mov	ds:[bx].HF_sfn, al
		mov	ds:[bx].HF_private, dx
		jmp	nextFileHandle
NWReOpenFiles_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWDetermineFilesToReopen_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Determines whether the passed file handle is one of the
		"special" ones that needs to be reopened. The known
		special files are:

			* the swap file
			* the istartup state file
			* the shared TOKEN.DB file

Pass:		bx	= file handle (from FileForEach)
		cx	= offset of netware FSD
		dx	= FSInfoResource (locked exclusively)
		ss:bp	= NWReOpenFrame (list of files to reopen)

Return:		bx, dx, ss:bp = same

		carry clear to continue processing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 16, 1993 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWDetermineFilesToReopen_callback	proc	far

		loginVars	local	LoginFrame

		uses	ax, bx, cx, dx, bp, di, si, ds, es
		.enter	inherit

	;
	; first make sure that this file was initially opened from a NetWare-
	; managed drive.
	;

		mov	ax, loginVars.LF_kernelDGroup
		mov	ds, ax

		mov	es, dx				;es = FSInfoHeader
		mov	di, ds:[bx].HF_disk		;di = disk handle
		tst	di
		LONG jz	nextFileHandle			;skip if is primary
							;IFS driver...

		mov	di, es:[di].DD_drive		;es:di <- DSE
		mov	di, es:[di].DSE_fsd		;di <- FSD
		cmp	di, ss:[loginVars].LF_netwareOffset
		LONG jne nextFileHandle			;skip if not NW...

getFileAccessFlagsAndOwnersName::
	;
	; now see if this is a read/write file
	;

		mov	al, ds:[bx].HF_accessFlags
		mov	ss:[loginVars].LF_accessMode, al	;save in case
								;we reopen
	;
	;  Get the file's owner's name so we can compare it against
	;  our list
	;
	
		push	bx				;save file handle
		segmov	es, ss, ax			;es:di = buffer
		lea	di, ss:[loginVars].LF_curGeodeName
		call	MemOwner			;bx <- geode
		mov	ax, GGIT_PERM_NAME_ONLY
		call	GeodeGetInfo
		pop	bx				;bx <- file handle

compareToListOfFiles::
	;
	; See if this owner's name (and EXACT AccessFlags) matches
	;

		segmov	ds, ss, ax
		mov	cx, LOGIN_NUMBER_OF_RWFILES
		lea	si, loginVars.LF_file1	;ss:si = first NWReOpenFileInfo
						;		structure

searchLoop:
	;
	; for each known file in our list, see if the access flags match
	;
		mov	al, ss:[loginVars].LF_accessMode
		cmp	al, ds:[si].NWROFO_accessFlags
		jne	checkNextFileInList		;skip if wrong flags...

checkName::
	;
	; and see if the owner's filename matches
	;
		push	ds, si, cx, di
		mov	si, ds:[si].NWROFO_ownerName
		segmov	ds, cs, ax
		mov	cx, GEODE_NAME_SIZE
		repe	cmpsb
		pop	ds, si, cx, di
		je	openFile			;skip if matches...

  checkNextFileInList:
		add	si, size NWReOpenFileInfo
		loop	searchLoop

EC<		ERROR	FILE_OPENED_BY_NETWARE_BUT_NOT_IN_LIST_OF_FILES_TO_REOPEN >
NEC<		jmp	short nextFileHandle			>

openFile::
	;
	; Mark this file as one to be reopened
	;	ds:[si].NWROFO_fullPath	= name
	;	bx			= file handle
	;
		mov	ds:[si].NWROFO_fileHandle, bx

nextFileHandle:
		clc

		.leave
		ret
NWDetermineFilesToReopen_callback	endp

if 1


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWLockPrimaryFSDResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		es - segment of FSInfoResource

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWLockPrimaryFSDResources	proc	near
	uses	ax, bx, cx, si, es, ds
	.enter

	call	FSDLockInfoExcl
	mov	es, ax

	mov	ax, SGIT_HANDLE_TABLE_SEGMENT
	call	SysGetInfo
	mov	ds, ax

	mov	bx, es:[FIH_primaryFSD]		;es:bx <- FSD
	mov	bx, es:[bx].FSD_handle		;bx <- primary FSD core block

	push	bx				;save handle for unlocking

	call	MemLock
	mov	es, ax				;es <- GeodeHeader

	mov	cx, es:[GH_resCount]
	mov	si, es:[GH_resHandleOff]

lockLoop:
	;
	;  We want to lock the block if it's either discardable or
	;  swapable
	;
	mov	bx, es:[si]			;bx <- resource handle

	test	ds:[bx].HM_flags, mask HF_DISCARDABLE or mask HF_SWAPABLE
	jz	afterLock

	call	MemLock

afterLock:
	add	si, size hptr
	loop	lockLoop

	pop	bx				;bx <- core block
	call	MemUnlock

	call	FSDUnlockInfoExcl

	.leave
	ret
NWLockPrimaryFSDResources	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWUnlockPrimaryFSDResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		es - segment of FSInfoResource

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWUnlockPrimaryFSDResources	proc	near
	uses	ax, bx, cx, si, es, ds
	.enter

	call	FSDLockInfoExcl
	mov	es, ax

	mov	ax, SGIT_HANDLE_TABLE_SEGMENT
	call	SysGetInfo
	mov	ds, ax

	mov	bx, es:[FIH_primaryFSD]		;es:bx <- FSD
	mov	bx, es:[bx].FSD_handle		;bx <- primary FSD core block

	push	bx				;save handle for unlocking

	call	MemLock
	mov	es, ax				;es <- GeodeHeader

	mov	cx, es:[GH_resCount]
	mov	si, es:[GH_resHandleOff]

lockLoop:
	;
	;  We want to lock the block if it's either discardable or
	;  swapable
	;
	mov	bx, es:[si]			;bx <- resource handle

	test	ds:[bx].HM_flags, mask HF_DISCARDABLE or mask HF_SWAPABLE
	jz	afterUnlock

	call	MemUnlock

afterUnlock:
	add	si, size hptr
	loop	lockLoop

	pop	bx				;bx <- core block
	call	MemUnlock

	call	FSDUnlockInfoExcl

	.leave
	ret
NWUnlockPrimaryFSDResources	endp

endif

NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWServerLogout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This call logs out the object from a file server, but
		does not detach the workstation.

CALLED BY:	net library
PASS:		ds:si = asciiz name of server
RETURN:		al = 0 if successful
		     1 if couldn't find named server
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWServerLogout	proc	near
	call 	NWServerLogoutInternal
	ret
NWServerLogout	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWServerLogoutInternal	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	call	NWGetConnectionIDInternal
	tst	dl
	jnz	doLogout
	mov 	al, 1
	jmp 	done

doLogout:
	mov	ax, NFC_LOGOUT_FROM_FILE_SERVER
	call	NetWareCallFunction

done:
	.leave
	ret
NWServerLogoutInternal	endp
NetWareCommonCode	ends
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWMapDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Permanently assign a workstation drive to a network 
		directory

CALLED BY:	Net library
PASS:		ds:si	- asciiz directory path (full or partial) 
			  on file server
		cx:dx	- asciiz name for drive
		bl	- drive letter (an ascii character)
RETURN:		al	- completion code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Call the IFS Netware driver to do the actual work. This is
	necessary because we need to notify GEOS of the new drive,
	and to do so we need kernel data structures.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWMapDrive	proc	near
	call	NWMapDriveInternal
	ret
NWMapDrive	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWMapDriveInternal	proc	far
driveName	local	fptr
dirPath		local	fptr
if 0		
dosPath		local	255 dup (char)		
endif		
	uses	cx,dx,es,ds,si,di
	.enter
	movdw	dirPath, dssi
	movdw	driveName, cxdx
	push	bx

	segmov	es, cs
	lea	di, nwDriverName
	mov	ax, 8
	mov 	cx, mask GA_DRIVER
	clr	dx
	call	GeodeFind		;sets carry if geode found
					;^hbx = geode
	jc	driverFound
	jmp	error
	
driverFound:
	call	GeodeInfoDriver		;returns ds:si = DriverInfoStruct
	
if 0
	;
	; maybe user passed a vitual geos filename
	; try getting dos name
	lds	dx, dirPath
	mov	ax, FEA_DOS_NAME
	segmov	es, ss
	lea	di, dosPath
	mov	cx, 255
	call 	FileGetPathExtAttributes
	
	jc	geosFilename

	;
	; use dos name instead
	;

	les	ax, dosPath
	jmp	callDriver

geosFilename:
endif	
	les	ax, dirPath

	movdw	cxdx, driveName
	pop	bx

	mov	di, DR_NETWARE_MAP_DRIVE
	call	ds:[si].DIS_strategy

exit:		
	.leave
	ret
error:
	jmp 	exit	
NWMapDriveInternal	endp
nwDriverName	char	"netware ", 0
NetWareCommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWUnmapDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo a drive mapping in GEOS and NetWare.

CALLED BY:	Net Library
PASS:		bl 	= ascii upper case drive letter
		al	= completion code
RETURN:		al	= NetWareReturnCode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWUnmapDrive	proc	near
	call	NWUnmapDriveInternal
	ret
NWUnmapDrive	endp
NetWareResidentCode	ends

NetWareCommonCode	segment resource
NWUnmapDriveInternal	proc	far
	uses	bx,cx,dx,si,di,bp
	.enter

	;
	; delete the drive in Geos
	; SKIP BECAUSE IN THE WIZARD QUICK LOGIN CASE WE DON'T WANT 
	; GEOS TO KNOW THE DRIVE WENT AWAY!
	sub	bl, 'A'			;need drive number instead of letter
if 0
	mov	al, bl
	call 	FSDDeleteDrive
	jc	exit
endif	
	;
	; delete the mapping in NetWare. First, get the directory handle
	; for the mapping. Then deallocate that directory handle.
	;

	clr	dx
	mov 	dl, bl
	mov	ax, NFC_GET_DIRECTORY_HANDLE
	call	FileInt21

	;al = dir handle, ah = NWDriveFlags
	;
	;check status flags to make sure that drive is network drive

	and	ah, mask NWDF_TYPE
	cmp	ah, NWDT_FREE
	jz	error			;drive wasn't mapped.

	mov	bx, size NReqBuf_DeallocDirectoryHandle
	mov	cx, size NRepBuf_DeallocDirectoryHandle
	call	NetWareAllocRRBuffers		;returns ^hbx = block (locked)
						;es:si = request buffer
						;es:di = reply buffer
	segmov	ds, es
	push	bx

	;ds:si = request buffer; ds:di = reply buffer
	mov	ds:[si].NREQBUF_DDH_subFunc, 14h
	mov	ds:[si].NREQBUF_DDH_dirHandle, al
	segmov	es, ds			;es:di = reply buffer
	mov	ax, NFC_DEALLOC_DIRECTORY_HANDLE
	call	FileInt21
	tst	al
	jnz	freeAndError
	pop	bx
	call	MemFree

exit:	
	.leave
	ret

freeAndError:
	pop	bx
	call	MemFree
error:
	stc
	jmp	exit

NWUnmapDriveInternal	endp
NetWareCommonCode	ends

