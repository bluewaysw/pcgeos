COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeInit.asm

ROUTINES:
	Name		Description
	----		-----------
   EXT	InitGeode		Initialize the GEODE module

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:
	This module initializes the GEODE module.  See manager.asm for
documentation.

	$Id: geodesInit.asm,v 1.1 97/04/05 01:12:02 newdeal Exp $

------------------------------------------------------------------------------@



COMMENT @----------------------------------------------------------------------

FUNCTION:	InitGeode

DESCRIPTION:	Initialize the GEODE module

CALLED BY:	EXTERNAL
		StartGEOS

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

------------------------------------------------------------------------------@

InitGeode	proc	near

	; put the kernel at the front of the geode list

;;;	inc	ds:[geodeCount]			;one geode (the kernel)

	mov	bx, handle 0
	mov	ds:[geodeListPtr], bx

	; Set up the next geode pointer. For XIP, this value is pre-set,
	; so just fetch the value
	;
	push	ds
	call	MemLock
	mov	ds, ax
NOAXIP<	mov	ds:[GH_nextGeode], 0					>
AXIP <	mov	di, ds:[GH_privData]					>
AXIP <	mov	si, ds:[GH_nextGeode]					>
	call	MemUnlock
	pop	ds

	; For XIP, it is CRUCIAL that this work be done before GeodePrivAlloc
	; is ever called. Clear the previous & next fields of the blocks
	; that will hold the kernel's private data & the next core block.
	; Also mark these blocks as being owned by the kernel.
	;
AXIP <	clr	ax							>
AXIP <	mov	ds:[di].HM_owner, bx		;set owner to be kernel	>
AXIP <	mov	ds:[di].HM_prev, ax					>
AXIP <	mov	ds:[di].HM_next, ax					>
KXIP <	mov	ds:[xipFirstCoreBlock], si	;store pre-allocated han>

;	On XIP systems, the kernel's coreblock lies in ROM, so the
;	GH_nextGeode field is pre-allocated. I don't really understand why
;	we need to nuke the HM_next/prev fields here, but we definitely
;	don't want to do it if the handle refers to the coreblock of an
;	item that is already in the XIP image...

FXIP <	cmp	si, LAST_XIP_RESOURCE_HANDLE				>
FXIP <	jbe	doNotModify						>
AXIP <	mov	ds:[si].HM_owner, bx		;set owner to be kernel	>
AXIP <	mov	ds:[si].HM_prev, ax					>
AXIP <	mov	ds:[si].HM_next, ax					>
FXIP <doNotModify:							>

	; Get geode private data offset to store GeodeHeapVars at.
	;
	mov	cx, (size GeodeHeapVars)/2
	call	GeodePrivAlloc
	mov	ds:[geodeHeapVarsOffset], bx

	ret
InitGeode	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReplaceMovableVector

DESCRIPTION:	Insert our own vector to handle interupts to call movable
		routines

CALLED BY:	INTERNAL
		InitGeode

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

ReplaceMovableVector	proc	far
	INT_OFF

	push	si, es

	clr	ax
	mov	es,ax			;point at bottom of memory

	; loop to set up all interrupts

	mov	cx,16
	mov	si, RESOURCE_CALL_VECTOR_BASE
RMV_loop:
	mov	ax, offset ResourceCallInt
	xchg	ax, es:[si].offset
	mov	ds:[oldResourceCalls][si-RESOURCE_CALL_VECTOR_BASE].offset,ax

	mov	ax, segment ResourceCallInt
	xchg	ax, es:[si].segment
	mov	ds:[oldResourceCalls][si-RESOURCE_CALL_VECTOR_BASE].segment,ax

	add	si,4
	loop	RMV_loop

	mov	ds:[installedMovableVectors], TRUE

	pop	si, es
	INT_ON
	ret

ReplaceMovableVector	endp
