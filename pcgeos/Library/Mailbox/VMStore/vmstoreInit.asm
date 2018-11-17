COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		vmstoreInit.asm

AUTHOR:		Adam de Boor, Apr 14, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/94		Initial revision


DESCRIPTION:
	Initialization code, of course.
		

	$Id: vmstoreInit.asm,v 1.1 97/04/05 01:20:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMStoreInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate or initialize the VM Store map for the library

CALLED BY:	(EXTERNAL) AdminInit
PASS:		bx	= handle of admin file
		ax	= handle of VMStore map (0 if none)
RETURN:		ax	= handle of VMStore map
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMStoreInit	proc	near
		uses	ds, si, bp, di, bx, cx
		.enter
EC <		call	ECVMCheckVMFile					>
		tst	ax
		jz	allocMap

EC <		push	cx, ax						>
EC <		call	VMInfo						>
EC <		ERROR_C	VM_STORE_HANDLE_INVALID				>
EC <		cmp	di, MBVMID_VM_STORE				>
EC <		ERROR_NE VM_STORE_HANDLE_INVALID			>
EC <		pop	cx, ax						>

		push	ax
   		call	VMLock
		mov	ds, ax

		Assert	lmem, bp
EC <		call	ECLMemValidateHeap				>

		mov	si, ds:[LMBH_offset]
EC <		call	ECLMemValidateHandle				>
		
		call	UtilFixChunkArray
		mov	bx, cs
		mov	di, offset VMStoreInitClean
		call	ChunkArrayEnum
		pop	ax
done:
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		.leave
		ret

allocMap:
	;
	; Allocate a general lmem heap in a VM block and set its UID to our
	; special value (for EC)
	; 
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx	; default header
		call	VMAllocLMem
		mov	cx, MBVMID_VM_STORE
		call	VMModifyUserID
	;
	; Lock the beastie down and create a NameArray to hold the entries.
	; 
		push	ax
		call	VMLock
		mov	ds, ax
		mov	bx, size VMStoreEntry - size NameArrayElement
		clr	cx, si, ax
		call	NameArrayCreate
		pop	ax
EC <		cmp	si, ds:[LMBH_offset]				>
EC <		ERROR_NE	VM_STORE_MAP_NOT_FIRST_CHUNK		>
		jmp	done
VMStoreInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMStoreInitClean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare an element of the vm store map for use in this
		session, wiping out whatever cruft is leftover from the
		previous session

CALLED BY:	(INTERNAL) VMStoreInit via ChunkArrayEnum
PASS:		ds:di	= VMStoreElement to reset
RETURN:		carry set to stop enumerating (always returned clear)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMStoreInitClean proc	far
		.enter
		cmp	ds:[di].VMSE_meta.NAE_meta.REH_refCount.WAAH_high,
				EA_FREE_ELEMENT
		je	done
		mov	ds:[di].VMSE_refCount, 0
		mov	ds:[di].VMSE_handle, 0
done:
		clc
		.leave
		ret
VMStoreInitClean endp

Init		ends
