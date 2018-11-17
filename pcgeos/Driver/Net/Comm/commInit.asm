COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Comm
FILE:		commInit.asm

AUTHOR:		Andrew Wilson, May 20, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/20/93		Initial revision

DESCRIPTION:
	Holds init code

	$Id: commInit.asm,v 1.1 97/04/18 11:48:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitExitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	driver init routine for Comm driver

CALLED BY:	CommInitStub()
PASS:		none
RETURN:		carry - set if error
DESTROYED:	ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		broke out from CommInit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommInit		proc	far
	uses	ax,bx,cx,dx,si
	.enter

	;
	; Allocate a block & init for the port chunk array
	;
	mov	bx, handle 0			; COMMDRV owns it
	mov	ax, 128				;initial block size
	mov	cx, (((mask HAF_LOCK)) shl 8) or \
			mask HF_SWAPABLE or mask HF_SHARABLE
	call	MemAllocSetOwner
	jc	quit				;branch if error
	mov	ds, ax
	mov	ax, LMEM_TYPE_GENERAL
	mov	dx, size LMemBlockHeader
	mov	cx, 2				;2 initial handles
	mov	si, 64				;initial heap size
	call	LMemInitHeap
	push	bx				;save block handle
	mov	bx, size PortStruct		;bx <- element size
	clr	cx				;cx <- no extra space
	clr	al				;al <- ObjChunkFlags
	clr	si				;si <- allocate chunk
	call	ChunkArrayCreate		; *ds:si - array
	pop	bx				;bx <- handle of port array
	;
	; Save the chunk and block handle for later access
	;
	segmov	ds,dgroup, ax	
	mov	ds:[portArrayOffset], si	;save chunk of port array
	mov	ds:[lmemBlockHandle], bx	;save block handle of array
	call	MemUnlock
	;
	; Register the Comm driver with the net library as a new domain
	;
	call	RegisterCommDriver
	clc					;carry <- no error
quit:
	.leave
	ret
CommInit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegisterCommDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers the COMM domain 

CALLED BY:	CommInit()
PASS:		none
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RegisterCommDriver	proc	near
	uses	dx, si
	.enter

	mov	cx, segment CommStrategy
	mov	dx, offset CommStrategy		;cx:dx <- strategy to register
	segmov	ds, cs
	mov	si, offset commDomainName	;ds:si <- ptr to domain name
	mov	bx, handle 0			;bx <- handle of Comm driver
	call	NetRegisterDomain

	.leave
	ret
RegisterCommDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	driver exit routine for Comm driver

CALLED BY:	CommExitStub
PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		broke out from CommExit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommExit		proc	far
	uses	ax, bx, cx, dx, di
	.enter

;	This can be called twice in the event of a dirty shutdown, so we
;	just exit if the lmemBlockHandle has already been freed.

	segmov	es,dgroup,si
	clr	bx
	xchg	bx, es:[lmemBlockHandle]
	tst	bx
	jz	exit

	push	bx
	call	MemLockExcl
	mov	ds,ax				
	mov	si, es:[portArrayOffset]	;*ds:si - ChunkArray
	mov	bx, cs
	mov	di, offset cs:ClosePortCallBack
	call	ChunkArrayEnum
	pop	bx
	call	MemFree				; free LMem Block
exit:
	.leave
	ret
CommExit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClosePortCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close all ports being enumerated

CALLED BY:	CommExitFar() via ChunkArrayEnum()
PASS:		*ds:si - array
		ds:di - element (PortStruct)
RETURN:		carry - set to abort
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	close stream for the port (thus sending a message to the callback
	routine)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClosePortCallBack	proc	far
	uses	es,ds
	.enter

	;
	; Is this a deleted port?
	;
	cmp	ds:[di].PS_number, DELETED_PORT_NUMBER
	je	exit

	call	ClosePortAndAwaitAck
	clc					;carry <- don't abort
exit:
	.leave
	ret
ClosePortCallBack	endp

InitExitCode	ends
