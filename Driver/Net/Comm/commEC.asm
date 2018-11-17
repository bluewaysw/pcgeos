COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		commEC.asm

AUTHOR:		Gene Anderson, Apr 28, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/28/93		Initial revision


DESCRIPTION:
	

	$Id: commEC.asm,v 1.1 97/04/18 11:48:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment resource

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCommCheckESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that es:di is a valid pointer

CALLED BY:	EC
PASS:		es:di - ptr to verify
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCommCheckESDI		proc	far
	uses	ds, si
	.enter

	segmov	ds, es
	mov	si, di				;ds:si <- ptr to check
	call	ECCheckBounds

	.leave
	ret
ECCommCheckESDI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCommCheckDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that ds:si is a valid pointer

CALLED BY:	EC code
PASS:		ds:si - ptr to verify
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCommCheckDSSI		proc	far
	.enter

	call	ECCheckBounds

	.leave
	ret
ECCommCheckDSSI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCommCheckStreamVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a StreamVars structure is valid

CALLED BY:	EC code
PASS:		ss:bp - ptr to StreamVars
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCommCheckStreamVars		proc	far
	uses	ds, si
	.enter
	pushf

	movdw	dssi, ss:[bp].SV_serDrvr	;ds:si <- ptr to check
	call	ECCheckBounds
	test	ss:[bp].SV_sendSem, 0x000f
	ERROR_NZ COMM_ILLEGAL_SEMAPHORE
	test	ss:[bp].SV_ackSem, 0x000f
	ERROR_NZ COMM_ILLEGAL_SEMAPHORE

	popf
	.leave
	ret
ECCommCheckStreamVars		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCommCheckServerStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	verify a ServerStruct is valid

CALLED BY:	EC
PASS:		ss:bp - ptr to ServerStruct
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCommCheckServerStruct		proc	far
	uses	ds, si
	.enter
	pushf

	movdw	dssi, ss:[bp].SE_serDrvr	;ds:si <- ptr to check
	call	ECCheckBounds
	test	ss:[bp].SE_ackSem, 0x000f
	ERROR_NZ COMM_ILLEGAL_SEMAPHORE

	popf
	.leave
	ret
ECCommCheckServerStruct		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCommCheckPortStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	verify a PortStruct is valid

CALLED BY:	EC
PASS:		ds:di - ptr to PortStruct
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCommCheckPortStruct		proc	far
	uses	ds, si
	.enter

	pushf
	mov	si, di
	call	ECCommCheckDSSI

	cmp	ds:[di].PS_number, SerialPortNum
	ERROR_A COMM_BAD_PORT_STRUCT
	cmp	ds:[di].PS_baudRate, SerialBaud
	ERROR_A COMM_BAD_PORT_STRUCT

	test	ds:[di].PS_sendSem, 0x000f
	ERROR_NZ COMM_ILLEGAL_SEMAPHORE
	test	ds:[di].PS_ackSem, 0x000f
	ERROR_NZ COMM_ILLEGAL_SEMAPHORE

	mov	si, ds:[si].PS_socketArray
	mov	si, ds:[si]			;ds:si <- ptr to socket array
	call	ECCheckLMemChunk

	mov	si, ds:[di].PS_serDrvr.offset
	mov	ds, ds:[di].PS_serDrvr.segment	;ds:si <- ptr to check
	call	ECCheckBounds

	popf

	.leave
	ret
ECCommCheckPortStruct		endp

endif

Resident	ends
