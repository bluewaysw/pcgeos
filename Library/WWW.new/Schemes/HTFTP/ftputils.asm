COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1998.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Geobrowser
MODULE:		ftp
FILE:		ftputils.asm

AUTHOR:		Jeremy Broestl, Jul 19, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jeremyb 	7/19/98   	Initial revision


DESCRIPTION:
		
	This file contains the C-Stub for SocketGetMediumAddress.
	It's broken for brother, and the lib is frozen, so...

	$Id: ftputils.asm,v 1.1.1.1 98/07/19 19:00:35 jeremyb Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



include nsftp.def

FTPCStub	segment	resource


SetGeosConvention
global SOCKETGETMYADDRESS:far
SOCKETGETMYADDRESS		proc	far	domain:fptr.char,
						buffer:fptr.byte,
						bufsize:fptr.word,
						mau:fptr.MediumAndUnit
	uses	si,di,ds
	.enter

	movdw	dssi, bufsize
	;Assert	fptr dssi
	mov	cx, ds:[si]
	push	ds,si
	movdw	dssi, domain
	movdw	esdi, buffer
	movdw	dxax, mau
	call	SocketGetMediumAddress
	pop	ds,si
	mov	ds:[si], cx
	.leave
	ret    

SOCKETGETMYADDRESS endp



FTPCStub 	ends
