COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Net Library
FILE:		netServer.asm

AUTHOR:		Chung Liu, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------
	NetServerAttach		attach to server
	NetServerLogin		login to server using name and password
	NetServerLogout		logout from server
	NetServerGetNetAddr	net address of server
	NetServerGetWSNetAddr	net address of workstation.
	NetMapDrive		map drive letter to network directory.
	NetServerChangeUserPassword
	NetServerVerifyUserPassword
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 8/92		Initial revision


DESCRIPTION:
	This file contains the entry points of the net library that
	are server related.  The functions that belong here all have
	to be passed a server name, in addition to other arguments.

	$Id: netServer.asm,v 1.1 97/04/05 01:24:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetServerCode segment resource
	      

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetServerAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach to a server.

PASS:		ds:si = null terminated server name
RETURN:		al = return code (0 = successful)
DESTROYED:	nothing

NOTE:	This function does a NetWare style attach to the file server.
	Apparently no other network types have a similar "attach" concept.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetServerAttach	proc	far
	uses	di
	.enter
	mov	di, DR_NET_SERVER_ATTACH
	call	NetCallDriver
	.leave
	ret
NetServerAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetServerChangeUserPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check with the server if the password for the user is correct.

PASS:		ss:bx	- fptr to NetServerChangeUserPasswordFrame
RETURN:		al	- return code (0 if successful)
		ah 	- cleared to zero.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetServerChangeUserPassword	proc	far
	uses	di
	.enter
	mov	di, DR_NET_SERVER_CHANGE_USER_PASSWORD
	call	NetCallDriver
	.leave
	ret
NetServerChangeUserPassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetServerVerifyUserPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check with the server if the password for the user is correct.

PASS:		ds:si	- asciiz server name
		ax:bx	- asciiz login name
		cx:dx	- asciiz 
RETURN:		al	- return code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetServerVerifyUserPassword	proc	far
	uses	di
	.enter
	mov	di, DR_NET_SERVER_VERIFY_USER_PASSWORD
	call	NetCallDriver
	.leave
	ret
NetServerVerifyUserPassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetServerLogin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	login to named server
	
PASS:		ss:bx	- NetServerLoginFrame

RETURN:		al - return code

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetServerLogin	proc	far
	uses	di
	.enter
	mov	di, DR_NET_SERVER_LOGIN
	call	NetCallDriver
	.leave
	ret
NetServerLogin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetServerLogout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This call logs out the object from a file server, but
		does not detach the workstation.

PASS:		ds:si = asciiz name of server
RETURN:		al = 0 if successful
		     1 if couldn't find named server
DESTROYED:	nothing

NOTE:		NetWare logout does not detach.  Should we have the NetWare
		driver do a detach after logout?  This would make sense
		since login first does a attach if necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetServerLogout	proc	far
	uses	di
	.enter
	mov	di, DR_NET_SERVER_LOGOUT
	call	NetCallDriver
	.leave
	ret
NetServerLogout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetServerGetNetAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an address that uniquely identifies the calling
		workstation with respect to the server.

PASS:		ds:si	- asciiz server name
		cx:dx	- fptr to NovellNodeSocketAddrStruct to be filled
			  in with net address.
RETURN:		cx:dx	- unchanged, but filled in
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetServerGetNetAddr	proc	far
	uses	di
	.enter
	mov	di, DR_NET_SERVER_GET_NET_ADDR
	call	NetCallDriver
	.leave
	ret
NetServerGetNetAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetServerGetWSNetAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an address that uniquely identifies the calling
		workstation with respect to the server.

PASS:		ds:si	- asciiz server name
		cx:dx	- fptr to NovellNodeSocketAddrStruct to be filled
			  in with net address.
RETURN:		cx:dx	- unchanged, but filled in
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetServerGetWSNetAddr	proc	far
	uses	di
	.enter
	mov	di, DR_NET_SERVER_GET_WS_NET_ADDR
	call	NetCallDriver
	.leave
	ret
NetServerGetWSNetAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetGetStationAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the address for this workstation. (Unique everywhere.)

PASS:		nothing
RETURN:		cx,bx,ax	- address
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetGetStationAddress	proc	far
	uses	di
	.enter
	mov	di, DR_NET_GET_STATION_ADDRESS
	call	NetCallDriver
	.leave
	ret
NetGetStationAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetMapDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Permanently assign a workstation drive to a network 
		directory

PASS:		ds:si	- asciiz directory path (full or partial) 
			  on file server
                cx:dx   - asciiz name for drive
		bl	- drive letter (an ascii character)
RETURN:		al	- completion code
DESTROYED:	nothing
SIDE EFFECTS:	

NOTE:	This should become NetServerMapDrive, with the file server
	name passed in together with the other arguments.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetMapDrive	proc	far
	uses	di
	.enter
	mov	di, DR_NET_MAP_DRIVE
	call	NetCallDriver
	.leave
	ret
NetMapDrive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetUnmapDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo a drive mapping.

PASS:		bl	= ascii upper case drive letter
RETURN:		al	= completion code
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetUnmapDrive	proc	far
	uses	di
	.enter
	mov	di, DR_NET_UNMAP_DRIVE
	call	NetCallDriver
	.leave
	ret
NetUnmapDrive	endp

NetServerCode ends
