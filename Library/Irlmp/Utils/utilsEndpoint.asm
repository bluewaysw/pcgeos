COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		utilsEndpoint.asm

AUTHOR:		Chung Liu, Mar  9, 1995

ROUTINES:
	Name			Description
	----			-----------
	UEInitTable
	UEAddToTable
	UERemoveFromTable
	UEFindUnusedLsapSe
	UtilsAllocEndpointLocked
	UtilsGetEndpointLocked
	UtilsGetEndpointLockedExcl
	UtilsFreeEndpoint
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95   	Initial revision


DESCRIPTION:
	Routines to manage IrLMP Connection Endpoints.

	$Id: utilsEndpoint.asm,v 1.1 97/04/05 01:08:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UEInitTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the endpoint block, and zero-initialize the 
		endpoint table in the lmem block's header.

CALLED BY:	(INTERNAL) UtilsInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UEInitTable	proc	near
	uses	es,di,ax,bx,cx
	.enter
	call	UtilsLoadDGroupES
	;
	; Allocate utilsEndpointBlock lmem block, to place all the 
	; IrlmpEndpoint structures we're going to have.
	;
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, size IrlmpEndpointBlockHeader
	call	MemAllocLMem			;bx = block handle
	mov	ax, mask HF_SHARABLE
	call	MemModifyFlags
	mov	es:[utilsEndpointBlock], bx
	;
	; zero-initialize the endpoint table.
	;	
	call	MemLockExcl
	mov	es, ax			;es:0 = IrlmpEndpointBlockHeader
	mov	di, offset IEBH_endpointTable
	mov	cx, size IrlmpEndpointByLsapTable
	clr	ax			;fill table with zeroes.
	rep	stosb
	call	MemUnlockExcl
	.leave
	ret
UEInitTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsFreeEndpointTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the endpoint block

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsFreeEndpointTable	proc	near
	uses	es, bx
	.enter
	call	UtilsLoadDGroupES
	clr	bx
	xchg	bx, es:[utilsEndpointBlock]
	call	MemFree
	.leave
	ret
UtilsFreeEndpointTable	endp

InitCode	ends

UtilsCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UEAddToTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the chunk handle of the new IrlmpEndpoint in the
		endpoint block's endpoint table.

CALLED BY:	UtilsAllocEndpointLocked
PASS:		ds	= endpoint block segment (MemLockExcl'ed)
		cl	= IrlmpLsapSel		
		si	= lptr of IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ds:[di].IE_next is set correctly.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UEAddToTable	proc	near
	uses	di,cx,ax
	.enter
	mov	di, offset IEBH_endpointTable
	clr	ch
	shl	cx				;each entry is word sized
	add	di, cx				;ds:di = table entry for
						;  indicated LSAP-Sel

	mov	ax, si				;ax = lptr of IrlmpEndpoint
	xchg	ds:[di], ax			;cx = previous entry
	
	mov	di, ds:[si]			;ds:di = IrlmpEndpoint
	mov	ds:[di].IE_next, ax

	.leave
	ret
UEAddToTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UERemoveFromTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the IrlmpEndpoint from the enpoint table.

CALLED BY:	UtilsFreeEndpoint
PASS:		ds	= endpoint block, MemLockExcl'ed
		si	= lptr of IrlmpEndpoint
		cl	= IrlmpLsapSel for endpoint.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UERemoveFromTable	proc	near
	uses	ax,cx,ds,si,di
	.enter
	mov	di, offset IEBH_endpointTable
	clr	ch
	shl	cx				;each entry is word sized
	add	di, cx				;ds:di = table entry for 
						;  indicated LSAP-Sel

compareLoop:
	;
	; ds:di = table entry for LSAP-Sel, or IE_next of another endpoint.
	; si = lptr of IrlmpEndpoint to remove.
	;
	cmp	ds:[di], si
	je	foundEntry
	;
	; There is more than one IrlmpEndpoint with the same LSAP-Sel,
	; and the one we've got isn't the right one.  Follow the link
	; until we find it.
	;
	mov	di, ds:[di]			;di = lptr of another endpoint
	mov	di, ds:[di]			;ds:di = another endpoint
EC <	cmp	ds:[di].IE_next, 0				>
EC <	ERROR_Z IRLMP_ENDPOINT_TABLE_IS_CORRUPTED		>
	add	di, offset IE_next		;ds:di = IE_next of another
						;  endpoint.
	jmp	compareLoop

foundEntry:
	;
	; ds:di = entry for our lptr (could be IE_next of another endpoint)
	; si = lptr of IrlmpEndpoint to remove.
	;
	mov	si, ds:[si]			;ds:si = IrlmpEndpoint
	mov	ax, ds:[si].IE_next		;preserve link, if any.
	mov	ds:[di], ax			;outta there!
	.leave
	ret
UERemoveFromTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UEFindUnusedLsapSel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find unused LSAP-Sel in endpoint table.

CALLED BY:	UtilsAllocEndpointLocked
PASS:		ds	= endpoint block
RETURN:		carry clear if unused LSAP-Sel is found:
			cl	= IrlmpLsapSel
			ch	= 0
		carry set if all LSAPs are used:
			cx destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UEFindUnusedLsapSel	proc	near
	uses	ax,es,di
	.enter
	segmov	es, ds
	mov	di, offset IEBH_endpointTable
	add	di, size word			;skip LSAP 0
	clr	ax
	mov	cx, IRLMP_MAX_LEGAL_LSAP_SEL
	repne	scasw				;find first match
	jnz	notFound
	;
	; empty entry found.  di points one element beyond the match.
	;
	mov	cx, di
	sub	cx, offset IEBH_endpointTable
	shr	cx				;entries are word size
	dec 	cx				;cl = unused IrlmpLsapSel
EC <	call	ECCheckLsapSel					>
	clc
exit:
	.leave
	ret
notFound:
	stc
	jmp	exit
UEFindUnusedLsapSel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsAllocEndpointLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new IrlmpEnpoint chunk in the endpoint block.
		Add the chunk to the endpoint table.  Caller must
		MemUnlockShared the segment.

CALLED BY:	(EXTERNAL) IrlmpRegister
PASS:		cl	= IrlmpLsapSel (could be IRLMP_ANY_LSAP_SEL)
RETURN:		carry clear if okay:
			*ds:si	= new IrlmpEndpoint
			ds:di	= same as *ds:si
			cl	= IrlmpLsapSel (actual LSAP-Sel, if 
				  IRLMP_ANY_LSAP_SEL was passed in.)
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
					IE_NO_FREE_LSAP_SEL
			cx,ds,si,di destroyed			
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsAllocEndpointLocked	proc	far
	uses	bx,dx
	.enter
	
EC <	call	ECCheckLsapSel					>
	;
	; Lock down the endpoint block for modification.
	;
	call	UtilsLoadDGroupDS
	mov	bx, ds:[utilsEndpointBlock]
	call	MemLockExcl
	mov	ds, ax
	;
	; Do we need to make up an LSAP-Sel for the caller?	
	;
	cmp	cl, IRLMP_ANY_LSAP_SEL
	jne	gotLsap
	call	UEFindUnusedLsapSel		;cl = unused IrlmpLsapSel
	jc	error
gotLsap:
	;
	; cl = IrlmpLsapSel to use.
	; bx = handle of endpoint block
	; ds = segment of endpoint block
	;
	push	cx				;save desired LSAP-Sel
	mov	cx, size IrlmpEndpoint
	clr	ax				;no flags
	call	LMemAlloc			;ax = lptr of new IrlmEndpoint
	pop	cx				;cl = IrlmpLsapSel
	mov	si, ax				;*ds:si = IrlmpEndpoint
	mov	di, ds:[si]
	call	UEAddToTable	
	mov	ax, IE_SUCCESS
	clc
downgradeAndExit:
	pushf	
	call	MemDowngradeExclLock
	popf
	.leave
	ret
error:
	mov	ax, IE_NO_FREE_LSAP_SEL
	jmp	downgradeAndExit
UtilsAllocEndpointLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetEndpointLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the IrlmpEndpoint, given the chunk handle.
		Caller must MemUnlockShared the returned lmem segment.
CALLED BY:	(EXTERNAL) IrlmpUnregister, etc.
PASS:		si	= lptr of IrlmpEndpoint
RETURN:		*ds:si	= IrlmpEndpoint
		ds:di	= IrlmpEndpoint
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetEndpointLocked	proc	far
	uses	ax, bx
	.enter
	call	UtilsLoadDGroupDS
	mov	bx, ds:[utilsEndpointBlock]
	Assert	lmem, bx
	call	MemLockShared
	mov	ds, ax				;*ds:si = IrlmpEndpoint
	Assert	chunk, si, ds				
	mov	di, ds:[si]			;ds:di = IrlmpEndpoint
	.leave
	ret
UtilsGetEndpointLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetEndpointLockedExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the IrlmpEndpoint, given the chunk handle.
		Caller must MemUnlockExcl the returned lmem segment.
CALLED BY:	(EXTERNAL) IrlmpUnregister, etc.
PASS:		si	= lptr of IrlmpEndpoint
RETURN:		*ds:si	= IrlmpEndpoint
		ds:di	= IrlmpEndpoint
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetEndpointLockedExcl	proc	far
	uses	ax, bx
	.enter
	call	UtilsLoadDGroupDS
	mov	bx, ds:[utilsEndpointBlock]
	call	MemLockExcl
	mov	ds, ax				;*ds:si = IrlmpEndpoint
	Assert	chunk, si, ds					
	mov	di, ds:[si]			;ds:di = IrlmpEndpoint
	.leave
	ret
UtilsGetEndpointLockedExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsFreeEndpoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the endpoint with the specified lptr

CALLED BY:	(EXTERNAL) IrlmpUnregister
PASS:		si	= lptr of IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsFreeEndpoint	proc	far
	uses	ax,bx,cx,ds,si,di
	.enter
	call	UtilsLoadDGroupDS
	mov	bx, ds:[utilsEndpointBlock]
	tst	bx
	jz	alreadyFree
	Assert	lmem, bx
	call	MemLockExcl
	mov	ds, ax				;*ds:si = IrlmpEndpoint
EC <	Assert	chunk, si, ds						>
	mov	di, ds:[si]			;ds:[di] = IrlmpEndpoint
	mov	cl, ds:[di].IE_lsapSel		;cl = IrlmpLsapSel of endpoint
	call	UERemoveFromTable

	mov	ax, si				;ax = chunk handle
	call	LMemFree
	call	MemUnlockExcl
alreadyFree:
	.leave
	ret
UtilsFreeEndpoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetEndpointByLocalLsap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the first endpoint in the list with matching DLsapSel.

CALLED BY:	(INTERNAL) UtilsGetEndpointByLsaps
PASS:		ch	= dest. IrlmpLsapSel
RETURN:		carry clear if found:
			si	= lptr IrlmpEndpoint
		carry set if not found:
			si destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetEndpointByLocalLsap	proc	far
	uses	ax,bx,cx,ds,di
	.enter
	call	UtilsLoadDGroupDS
	mov	bx, ds:[utilsEndpointBlock]
	call	MemLockShared			;won't modify it.
	mov	ds, ax

	mov	di, offset IEBH_endpointTable
	clr	cl
	xchg	cl, ch				;cx = LsapSel 
	shl	cx				;entries are word-sized
	add	di, cx	
	mov	si, ds:[di]
	tst	si
	jz	notFound
	clc					;found

unlockAndExit:
	call	MemUnlockShared
	.leave
	ret

notFound:
	stc
	jmp	unlockAndExit
UtilsGetEndpointByLocalLsap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetEndpointByLsaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the endpoint corresponding to the LSAPs.

CALLED BY:	(EXTERNAL) IsapDataIndication
PASS:		ch	= dest. IrlmpLsapSel
		cl	= source IrlmpLsapSel
RETURN:		carry clear if found:
			si	= lptr IrlmpEndpoint
		carry set if not found:
			si destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetEndpointByLsaps	proc	far
	uses	ds,di,bx,cx
	.enter
	call	UtilsGetEndpointByLocalLsap	;si = lptr IrlmpEndpoint
	jc	exit
	;
	; Check if source LSAP matches. If not, traverse list looking for
	; match.
	;
	call	UtilsGetEndpointLocked		;ds:di = IrlmpEndpoint

testLoop:
	;
	; Compare cl (source LsapSel) with IE_destLsapID.ILI_lsapSel
	;
	mov	di, ds:[si]			;ds:di = IrlmpEndpoint
	cmp	cl, ds:[di].IE_destLsapID.ILI_lsapSel
	je	found
	mov	si, ds:[di].IE_next
	tst	si
	jnz	testLoop
	stc					;not found

unlockAndExit:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared			;flags preserved
exit:
	.leave
	ret
found:
	clc
	jmp	unlockAndExit
UtilsGetEndpointByLsaps	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsTestEndpointBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests the existence of the utilsEndpointBlock

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		Zero-flag set if block doesn't exist
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsTestEndpointBlock	proc	far
	uses	ds
	.enter

	call	UtilsLoadDGroupDS
	tst	ds:[utilsEndpointBlock]

	.leave
	ret
UtilsTestEndpointBlock	endp

UtilsCode	ends
