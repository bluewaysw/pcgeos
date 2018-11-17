COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Novell NetWare Library
FILE:		userInfo.asm


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version

DESCRIPTION:
	This library allows PC/GEOS applications to access the Novell NetWare
	Applications Programmers Interface (API). This permits an application
	to send and receive packets, set up connections between nodes on the
	network, access Novell's "Bindery", which contains information about
	network users, etc.

RCS STAMP:
	$Id: netUserInfo.asm,v 1.1 97/04/05 01:24:59 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetUserInfoCode
;------------------------------------------------------------------------------

NetUserInfoCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetUserGetLoginName

DESCRIPTION:	This call gets the current user's login name

PASS:		ds:si - fptr to buffer to hold user name

RETURN:		carry - set if error
		ds:si - buffer filled in

DESTROYED:	nothing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version
	chrisb  10/92		changed name for new API

------------------------------------------------------------------------------@

NetUserGetLoginName	proc	far
	uses	di
	.enter

	mov	di, DR_NET_USER_FUNCTION
	mov	al, NUF_GET_LOGIN_NAME
	call	NetCallDriver

	.leave
	ret
NetUserGetLoginName	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetUserCheckIfInGroup

DESCRIPTION:	This call checks if the user is in the group

PASS:		ds:si - ftpr to asciiz user name
		cx:dx - ftpr to asciiz group name

RETURN:		carry clear if user is in group.
		carry set if error, or user is not in group.
			ax - NetError, or 0 if no error.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version
	chrisb  10/92		changed for new API
------------------------------------------------------------------------------@

NetUserCheckIfInGroup	proc	far
	uses	di
	.enter

	mov	di, DR_NET_USER_FUNCTION
	mov	al, NUF_CHECK_IF_IN_GROUP
	call	NetCallDriver

	.leave
	ret
NetUserCheckIfInGroup	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	NetUserGetFullName

DESCRIPTION:	This call returns the full name of a user on the network

PASS:		ds:si - login name of user
		cx:dx - fptr to buffer to hold user's full name

RETURN:		carry set if error
			ax - NetError

DESTROYED:	ax, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version
	chrisb  10/92		changed for new API
------------------------------------------------------------------------------@

NetUserGetFullName	proc	far
	uses	di
	.enter

	mov	di, DR_NET_USER_FUNCTION
	mov	al, NUF_GET_FULL_NAME
	call	NetCallDriver

	.leave
	ret
NetUserGetFullName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetGetDefaultConnectionID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This call returns the connection ID of the file server
		to which request packets are currently being sent.  
		The default server is where the user gets logged into.

		Doc: NetWare System Calls -- DOS, page 17-11.
CALLED BY:	Net library
PASS:		nothing
RETURN:		al	= Connection ID of file server to which
			  packets are currently being sent (1 to 8)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetGetDefaultConnectionID	proc	far
	uses	di
	.enter
	;call the specific network driver

	mov	di, DR_NET_GET_DEFAULT_CONNECTION_ID
	call	NetCallDriver
	
	.leave
	ret
NetGetDefaultConnectionID	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetGetConnectionNumber

DESCRIPTION:	This call returns information about the object logged
		in as the specified connection number.

PASS:		nothing

RETURN:		cx	= connection number (1-250)

DESTROYED:	nothing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version

------------------------------------------------------------------------------@

NetGetConnectionNumber	proc	far
	uses	di
	.enter

	mov	di, DR_NET_USER_FUNCTION
	mov	al, NUF_GET_CONNECTION_NUMBER
	call	NetCallDriver

	.leave
	ret
NetGetConnectionNumber	endp

				

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetVerifyUserPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the password for the user is correct.

PASS:		dl - length of name string
		dh - length of password string
		ds:si - fptr to name string.  The name can be 1 to 47
			characters long.  Only printable characters can
			be used.  The name cannot include spaces or the
			following characters: / \ : ; , * ?
			
		es:di - fptr to password string.
		
RETURN:		ax - NetWareReturnCode (0 = successful)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetVerifyUserPassword	proc	far
	uses	di, bp
	.enter
	
	push	es, di,			; NVPP_password
		ds, si			; NVPP_loginName
		CheckHack <NVPP_password eq 4 and NVPP_loginName eq 0 and \
				NetVerifyPasswordParams eq 8>

	mov	bp, sp

	;call the specific network driver
	
	mov	di, DR_NET_USER_FUNCTION
	mov	al, NUF_VERIFY_PASSWORD
	call	NetCallDriver
	
	mov	bp, sp
	lea	sp, ss:[bp+size NetVerifyPasswordParams]
	
	.leave
	ret
NetVerifyUserPassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetGetServerNameTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DESCRIPTION:	This call returns a fptr to the shell's File Server
		Name Table.


PASS:		nothing

RETURN:		ds:si = pointer to shell's Server Name Table

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The File Server Name Table consists of eight entries (1 to 8)
	that are NW_USER_NAME_LENGTH bytes in length.  
	Each entry in the FSNT can contain a null-terminated server name.  

	To find out which entries in the name table are valid, look at
	the Connection ID Table.  I don't know what to look at yet,
	but when I'll do I'll come back and put it here.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetGetServerNameTable	proc	far
	uses	di
	.enter
	
	mov	di, DR_NET_GET_SERVER_NAME_TABLE
	call	NetCallDriver
	.leave
	ret
NetGetServerNameTable	endp
			

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetGetConnectionIDTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This call returns a pointer to the shell's Connection 
		ID Table.

PASS:		nothing

RETURN:	es:si = Connection ID Table

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The Connection ID Table consists of eight entries (1 to 8) that
	are 32 bytes in length.  
	Each entry is a NetWareConnectionIDTableItem.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetGetConnectionIDTable	proc	far
	uses	di
	.enter
	
	mov	di, DR_NET_GET_CONNECTION_ID_TABLE
	call	NetCallDriver
	
	.leave
	ret
NetGetConnectionIDTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetScanForServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Call Scan Bindery Object to look for a server.
		To get a list of all servers available, call this sequentially,
		until return code is NRC_NO_SUCH_OBJECT.

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

PSEUDO CODE/STRATEGY:
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetScanForServer	proc	far
	uses	di
	.enter
	
	mov	di, DR_NET_SCAN_FOR_SERVER
	call	NetCallDriver
	
	.leave
	ret
NetScanForServer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetEnumConnectedUsers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an enumeration of all the users connected to
		the network

CALLED BY:	GLOBAL

PASS:		ss:bp - NetEnumParams
		if NEP_bufferType = chunk array
			ds - segment of lmem block to hold chunk array

RETURN:		*ds:si - chunk array

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetEnumConnectedUsers	proc far
	uses	di
	.enter
	mov	di, DR_NET_USER_FUNCTION
	mov	al, NUF_ENUM_CONNECTED_USERS
	call	NetEnum

	.leave
	ret
NetEnumConnectedUsers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetEnumUsers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all users.

CALLED BY:	GLOBAL
PASS:		ss:bp - NetEnumParams
		if NEP_bufferType = chunk array
			ds = segment of lmem block to hold chunk array
RETURN:		*ds:si = chunk array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetEnumUsers	proc	far
	uses	di
	.enter
	mov	di, DR_NET_USER_FUNCTION
	mov	al, NUF_ENUM_USERS
	call	NetEnum
	.leave
	ret
NetEnumUsers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetTextMessageSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to a user

CALLED BY:	GLOBAL

PASS:		ds:si - user name
		cx:dx - fptr to message to send (null-term)

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetTextMessageSend	proc far
	uses	ax,di
	.enter

	mov	di, DR_NET_TEXT_MESSAGE_FUNCTION
	mov	al, NTMF_SEND_MESSAGE
	call	NetCallDriver

	.leave
	ret
NetTextMessageSend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetTextMessagePoll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Poll for incoming messages

CALLED BY:	GLOBAL

PASS:		ds:si - buffer of at least
		NET_TEXT_MESSAGE_BUFFER_SIZE to be filled in if
		there's an incoming message

RETURN:		if message:
			carry set, buffer filled in
		else
			carry clear


DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Does not return errors to the caller.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetTextMessagePoll	proc far
		uses	ax,di
		.enter

		mov	di, DR_NET_TEXT_MESSAGE_FUNCTION
		mov	al, NTMF_POLL_FOR_MESSAGE
		call	NetCallDriver
		jnc	done		
		cmp	ax, NET_STATUS_OK
		stc
		je	done
		clc
done:
		.leave
		ret
NetTextMessagePoll	endp




			
NetUserInfoCode	ends

