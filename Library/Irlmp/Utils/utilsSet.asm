COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		utilsSet.asm

AUTHOR:		Chung Liu, Mar 20, 1995

ROUTINES:
	Name			Description
	----			-----------
	UtilsCreateSet
	UtilsDestroySet
	UtilsClearSet
	UtilsAddToSet
	UtilsRemoveFromSet
	UtilsRemoveFromSetCallback
	UtilsEnumSet
	UtilsCountSet
	UtilsMemberpSet
	UtilsMemberpSetCallback
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95   	Initial revision


DESCRIPTION:
	Routines to create and manage sets of IrlmpEndpoint.

	$Id: utilsSet.asm,v 1.1 97/04/05 01:08:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilsCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsCreateSetFixupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a set of endpoints

CALLED BY:	(EXTERNAL) IAFInitialize, ICFInitialize
PASS:		ds	= lmem segment
RETURN:		si	= set handle (lptr ChunkArray)
		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsCreateSetFixupDS	proc	far
	uses	es,ax,bx,cx
	.enter
	push	ds:[LMBH_handle]

	call	UtilsLoadDGroupES
	mov	bx, es:[utilsEndpointBlock]
	push	bx
	call	MemLockExcl
	mov	ds, ax				;ds = endpoint block
	mov	bx, size lptr
	clr	ax, cx, si
	call	ChunkArrayCreate		;*ds:si = array
	pop	bx
	call	MemUnlockExcl

	pop	bx
	call	MemDerefDS
	.leave
	ret
UtilsCreateSetFixupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsDestroySet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the endpoint set.

CALLED BY:	(EXTERNAL) IAFExit
PASS:		si	= set handle (lptr ChunkArray)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsDestroySet	proc	far
	uses	es,ax,bx,ds
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsEndpointBlock]
	call	MemLockExcl
	mov	ds, ax				;*ds:si = set chunk array
	mov	ax, si				;*ds:ax = lmem block to free
	call	LMemFree
	call	MemUnlockExcl
	.leave
	ret
UtilsDestroySet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsClearSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all endpoints from the set.

CALLED BY:	(EXTERNAL)
PASS:		si	= set handle (lptr ChunkArray)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsClearSet	proc	far
	uses	es,ds,ax,bx
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsEndpointBlock]
	call	MemLockExcl
	mov	ds, ax				;*ds:si = set array
	call	ChunkArrayZero
	call	MemUnlockExcl
	.leave
	ret
UtilsClearSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsAddToSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add endpoint to set.

CALLED BY:	(EXTERNAL) 
		IFConnectRequestActive
		IFConnectRequestStandby
		IFConnectRequestUConnect
		IUAddRequestingEndpoint
PASS:		si	= set handle (lptr ChunkArray)
		ax	= lptr IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsAddToSet	proc	far
elt		local	lptr		push ax
	uses	es,ds,di,ax,bx
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsEndpointBlock]
	push	bx
	call	MemLockExcl
	mov	ds, ax				;*ds:si = set array

	call	ChunkArrayAppend		;ds:di = new element
	mov	ax, ss:[elt]
	mov	ds:[di], ax

	pop	bx
	call	MemUnlockExcl
	.leave
	ret
UtilsAddToSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsRemoveFromSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove element from endpoint set.

CALLED BY:	(EXTERNAL)
		IFDisconnectRequest
		IURemoveRequestingEndpoint
PASS:		si	= set handle (lptr ChunkArray)
		ax	= lptr.IrlmpEndpoint to remove from set.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsRemoveFromSet	proc	far
elt		local	lptr		push ax
	uses	es,ds,ax,bx,di
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsEndpointBlock]
	push	bx
	call	MemLockExcl
	mov	ds, ax				;*ds:si = set array

	mov	ax, ss:[elt]
	mov	bx, cs
	mov	di, offset UtilsRemoveFromSetCallback
	call	ChunkArrayEnum

	pop	bx
	call	MemUnlockExcl
	.leave
	ret
UtilsRemoveFromSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsRemoveFromSetCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to remove endpoint lptr from array

CALLED BY:	UtilsRemoveFromSet via ChunkArrayEnum
PASS:		*ds:si	= chunk array
		ds:di	= element
		ax	= lptr of endpoint to remove
RETURN:		carry set when endpoint found.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsRemoveFromSetCallback	proc	far
	.enter
	cmp	ds:[di], ax
	je	remove
	clc
exit:
	.leave
	ret
remove:
	call	ChunkArrayDelete
	stc
	jmp	exit
UtilsRemoveFromSetCallback	endp

if FULL_EXECUTE_IN_PLACE
UtilsCode	ends
ResidentXIP	segment	resource
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsEnumSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ChunkArrayEnum through the set.

CALLED BY:	(EXTERNAL)
		IFConnectConfirm
		IFDisconnectIndication
		IFStatusIndication
		IFStatusConfirm
		IFResetIndication

PASS:		bx:di	= callback
		si	= lptr of set
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsEnumSet	proc	far
callback	local	fptr		push bx, di
	uses	es,ds,ax,bx
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsEndpointBlock]
	push	bx
	call	MemLockShared
	mov	ds, ax				;*ds:si = set array

	movdw	bxdi, ss:[callback]
	call	ChunkArrayEnum

	pop	bx
	call	MemUnlockShared
	.leave
	ret
UtilsEnumSet	endp

if FULL_EXECUTE_IN_PLACE
ResidentXIP	ends
UtilsCode	segment	resource
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsCountSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get number of elements in set.

CALLED BY:	(EXTERNAL) IFDisconnectRequest
PASS:		si	= lptr of set
RETURN:		cx	= number of elements in set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsCountSet	proc	far
	uses	es,ds,ax,bx
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsEndpointBlock]
	call	MemLockShared
	mov	ds, ax				;*ds:si = set array
	call	ChunkArrayGetCount		;cx = number of elements
	call	MemUnlockShared
	.leave
	ret
UtilsCountSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsMemberpSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if element is member of set.

CALLED BY:	(EXTERNAL)
PASS:		si	= set handle (lptr ChunkArray)
		ax	= lptr IrlmpEndpoint
RETURN:		if element is in set:
			carry set
		else:
			carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsMemberpSet	proc	far
elt		local	lptr		push ax
	uses	es,ds,ax,bx,di
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsEndpointBlock]
	push	bx
	call	MemLockShared
	mov	ds, ax				;*ds:si = set array

	mov	ax, ss:[elt]
	mov	bx, cs
	mov	di, offset UtilsMemberpSetCallback
	call	ChunkArrayEnum

	pop	bx
	call	MemUnlockShared			;flags preserved
	.leave
	ret
UtilsMemberpSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsMemberpSetCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to check if endpoint lptr is member of set.

CALLED BY:	UtilsMemberpSet via ChunkArrayEnum
PASS:		*ds:si	= chunk array
		ds:di	= element
		ax	= lptr of endpoint to remove
RETURN:		carry set when endpoint found (aborts enum)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsMemberpSetCallback	proc	far
	.enter
	cmp	ds:[di], ax
	je	found
	clc
exit:
	.leave
	ret
found:	
	stc
	jmp	exit
UtilsMemberpSetCallback	endp

UtilsCode	ends

