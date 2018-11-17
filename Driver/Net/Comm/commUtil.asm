COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Communication Driver
FILE:		CommUtil.asm

AUTHOR:		In Sik Rhee, 4/92

ROUTINES:
	Name			Description
	----			-----------
	strncpy				String copy
	VerifyAndGetPortStruct		get Port Structure for port token
	VerifyAndGetPortStructExcl	get Port Structure for port token
	VerifyAndGetSocketStruct 	get Socket Structure for socket token
	VerifyAndGetSocketToken		get Socket token for Socket ID

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/11/92		Initial revision


DESCRIPTION:
	Utility functions for use

	$Id: commUtil.asm,v 1.1 97/04/18 11:48:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	 segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copies a string given its size

CALLED BY:	GLOBAL
PASS:		ds:si - src
		es:di - dest
		cx - size
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	es:di must have space to fit ds:si string
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
strncpy	proc	far
	uses	cx,si,di
	.enter

EC <	call	ECCommCheckDSSI						>
EC <	call	ECCommCheckESDI						>
	jcxz	exit	
	shr	cx, 1
	jnc	5$
	movsb
5$:
	rep	movsw			;strcpy
EC <	dec	si							>
EC <	dec	di							>
EC <	call	ECCommCheckESDI						>
EC <	call	ECCommCheckDSSI						>
exit:
	.leave
	ret
strncpy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyAndGetPortStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure port token is valid and returns the PortStruct.

CALLED BY:	Comm.asm

PASS:		ax - port token

RETURN:		ax - Memory Handle (locked)
		carry set if error
		otherwise, ds:di - PortStruct

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyAndGetPortStruct	proc	far
	uses	bx,si
	.enter
		
	segmov	ds,dgroup,si
	mov	bx, ds:[lmemBlockHandle]
	push	bx
	push	ax				; port token #
	call	MemLockShared
	mov	si, ds:[portArrayOffset]	
	mov	ds, ax				;*ds:si - ChunkArray
	pop	ax				; port token
	call	ChunkArrayElementToPtr		; ds:di - PortStruct?
	pop	ax				; mem handle
	jc	exit
	cmp	ds:[di].PS_number, DELETED_PORT_NUMBER
	clc
	jnz	exit
	stc

exit:
EC< 	WARNING_C	PORT_NOT_FOUND 					>
	.leave
	ret
VerifyAndGetPortStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyAndGetSocketStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure socket token is valid and returns SocketStruct

CALLED BY:	Comm.asm
PASS:		bx - socket token
		ds:di - PortStruct of socket
RETURN:		carry set if error
		ds:di - SocketStruct
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyAndGetSocketStruct	proc	far
	uses	ax,si
	.enter
	mov	si, ds:[di].PS_socketArray	;*ds:si - Socket ChunkArray
	mov	ax, bx 				; socket token
	call	ChunkArrayElementToPtr		; ds:di - socket element
	jc	exit
	cmp	ds:[di].SS_portNum, DELETED_SOCKET_NUMBER
	clc
	jnz	exit
	stc
exit:
EC< 	WARNING_C	INVALID_SOCKET_NUMBER 	>
	.leave
	ret
VerifyAndGetSocketStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindSocketIDCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to match a given socket ID with an existing one.

CALLED BY:	ChunkArrayEnum
PASS:		ds:di - array element
		ax - socket ID
RETURN:		carry set if match, ax - token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindSocketIDCallBack	proc	far
	cmp	ds:[di].SS_socketID, ax
	clc
	jne	exit
	call	ChunkArrayPtrToElement	; ax - token
	stc
exit:
	ret
FindSocketIDCallBack	endp

Resident	ends

InitExitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyAndGetPortStructExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure port token is valid and returns the PortStruct.

CALLED BY:	Comm.asm
PASS:		ax - port token
RETURN:		ax - Memory Handle (locked Exclusive)
		carry set if error
		otherwise, ds:di - PortStruct
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyAndGetPortStructExcl	proc	near
	uses	bx,si
	.enter
	segmov	ds,dgroup,si
	mov	bx, ds:[lmemBlockHandle]
	push	bx
	push	ax				; port token #
	call	MemLockExcl
	mov	si, ds:[portArrayOffset]	
	mov	ds, ax				;*ds:si - ChunkArray
	pop	ax				; port token
	call	ChunkArrayElementToPtr		; ds:di - PortStruct?
	pop	ax				; mem handle
	jc	exit
	cmp	ds:[di].PS_number, DELETED_PORT_NUMBER
	clc
	jnz	exit
	;
	; The port requested has been deleted -- return an error
	;
	stc					;carry <- error
exit:
EC< 	WARNING_C	INVALID_PORT_NUMBER 	>
	.leave
	ret
VerifyAndGetPortStructExcl	endp

InitExitCode	ends
