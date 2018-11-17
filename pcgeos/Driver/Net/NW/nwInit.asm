COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		NetWare Driver
FILE:		nwInit.asm

AUTHOR:		In Sik Rhee, Oct 22, 1992

ROUTINES:
	Name			Description
	----			-----------
	NetWareNukeVarsBlock
	NetWareGetIPXEntryPoint
	NetWareAttach		no longer used (DR_INIT)
	NetWareDetach		no longer used (DR_INIT)
	NetWareInitVarsBlock

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version


DESCRIPTION:
	
		
RCS STAMP:
	$Id: nwInit.asm,v 1.1 97/04/18 11:48:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			NetWareResidentCode
;------------------------------------------------------------------------------

NetWareResidentCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareNukeVarsBlock

DESCRIPTION:	

		MUST BE IN RESIDENT RESOURCE, AS IS CALLED BY DR_EXIT HANDLER,
		AND THIS IS A SYSTEM DRIVER.

CALLED BY:	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

if NW_SOCKETS

NetWareNukeVarsBlock	proc	near

EC <	call	ECCheckDGroupDS		;assert ds = dgroup		>

	clr	bx
	xchg	bx, ds:[nwVars]
	tst	bx
	jz	done

	call	MemFree
	
done:
	ret
NetWareNukeVarsBlock	endp

endif


NetWareResidentCode	ends

;------------------------------------------------------------------------------
;			NetWareInitCode
;------------------------------------------------------------------------------

NetWareInitCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareGetIPXEntryPoint

DESCRIPTION:	Call NetWare to ask what the entry point for IPX is.
		
PASS:		ds	= dgroup

RETURN:		es	= same
		carry set if could not initialize IPX (probably because
			it does not exist on this workstation)

DESTROYED:	all regs

PSEUDO CODE/STRATEGY:
	See page 4-10 of "NetWare System Calls - DOS".

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareGetIPXEntryPoint	proc	far
	uses	es
	.enter

	;Because we are calling through int 2Fh, we must grab DOS for our
	;exclusive use for a second

	call	SysLockBIOS

	;call int 2Fh

	mov	ax, NFC_GET_IPX_VECTOR	;7A00h
	int	NSI_GET_IPX_VECTOR	;int 2Fh

	cmp	al, NRC_GET_IPX_VECTOR_SUCCESSFUL
					;check completion code (0xFF)
	stc
	jne	releaseDOS		;skip if error (cy=1)...

	;save the address of the entry point in IPX which we will use
	;for all other calls.

EC <	call	ECCheckDGroupDS		;assert ds = dgroup		>

	mov	ax, es
	mov	ds:[ipxEntryPoint].high, ax
	mov	ds:[ipxEntryPoint].low, di
	clc				;no error

releaseDOS:
	;release DOS for use by others

	call	SysUnlockBIOS		;does not affect flags

	.leave
	ret
NetWareGetIPXEntryPoint	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareAttach

DESCRIPTION:	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

;OLD - MOVED TO DR_INIT HANDLER
;
;NetWareAttach	method	NetWareProcessClass, MSG_META_ATTACH
;
;	push	ax, cx, dx, bp, es
;
;if NW_VARS_BLOCK
;	;initialize a block on the global heap to hold our working
;	;variables.
;
;	call	NetWareInitVarsBlock
;endif
;
;	;call superclass (VERY important -- the field object must know
;	;that we are done starting up.)
;
;	pop	ax, cx, dx, bp, es
;	mov	di, offset NetWareProcessClass
;	CallSuper MSG_META_ATTACH
;
;	ret
;NetWareAttach	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareDetach

DESCRIPTION:	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

;OLD - MOVED TO DR_EXIT HANDLER
;
;NetWareDetach	method	NetWareProcessClass, MSG_META_DETACH
;
;	push	ax, cx, dx, bp, es
;
;if NW_SOCKETS
;	;close all remaining static and dynamic sockets
;
;	call	NetWareCloseAllSockets
;endif
;
;if NW_VARS_BLOCK
;	;nuke vars block
;
;	call	NetWareNukeVarsBlock
;endif
;
;	;call superclass
;
;	pop	ax, cx, dx, bp, es
;	mov	di, offset NetWareProcessClass
;	CallSuper MSG_META_DETACH
;	ret
;NetWareDetach	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareInitVarsBlock

DESCRIPTION:	Allocate an lmem block for our sockets, etc.

CALLED BY:	NetWareInit

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,si,bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

if NW_SOCKETS

NetWareInitVarsBlock	proc	far

EC <	call	ECCheckDGroupDS		;assert ds = dgroup		>

	;
	; See if we've already allocated a variables block (XXX: Why
	; would we have done that?)
	;

	tst	ds:[nwVars]
	jnz	done

	;
	; first, allocate a global memory block to hold our local
	; memory heap
	;

	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, size NWVarsBlockStruct
	call	MemAllocLMem

	mov	ds:[nwVars], bx

	;
	; Make sure the block knows who its owner is.  Otherwise, when
	; the app that started us exits, the block will be freed!
	;

	mov	ax, handle 0		; NW driver's geode handle
	call	HandleModifyOwner

if NW_SOCKETS

	;
	; Lock the LMem block so we can create a chunk array
	;

	call	MemLock
	push	bx, ds

	mov	ds, ax

	;now allocate the index chunk array, without any elements in it.
	;It will be resized as we add elements, as we encounter each new
	;row in the file.

	mov	bx, size NWSocketInfoStruct
	clr	al			;this might not be necessary
	clr	cx, si			;no extra space at start of array
	call	ChunkArrayCreate	;returns si = chunk array handle
	mov	ds:[NWVBS_socketArray], si
					;save handle of NLSocketInfoStruc
					;chunk array

	pop	bx, ds
	call	MemUnlock
endif

done:
	ret
NetWareInitVarsBlock	endp

endif

NetWareInitCode	ends
