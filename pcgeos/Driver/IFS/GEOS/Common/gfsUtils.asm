COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gfsUtils.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	Device-independent utility routines.
		

	$Id: gfsUtils.asm,v 1.1 97/04/18 11:46:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Movable segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSReadEntireLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the full contents of a link into memory.

CALLED BY:	EXTERNAL
       		GFSMPReadLink
PASS:		es:di	= GFSDirEntry
RETURN:		carry clear if ok:
			ds, ^hbx= GFSLinkData, followed by saved disk, 
				  target path, and extra data. Block locked 
				  once
			ax	= destroyed
		carry set on error:
			ax	= FileError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSReadEntireLink proc	near
		uses	es, di, si, cx
		.enter
	;
	; Allocate room to hold the whole file.
	; 
		mov	ax, es:[di].GDE_size.low
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jnc	readData
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	err

readData:
		movdw	dxsi, es:[di].GDE_data
		mov	cx, es:[di].GDE_size.low
		mov	es, ax
		mov	ds, ax
		clr	di		; es:di <- destination
		mov_tr	ax, si		; dxax <- read offset
		call	GFSDevRead
		jnc	done
		call	MemFree
err:
		stc
done:
		.leave
		ret
GFSReadEntireLink endp
Movable ends

Resident segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCallPrimary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the primary FSD to do something for us.

CALLED BY:	INTERNAL
PASS:		di	= DOSPrimaryFSFunction to call
		etc.
RETURN:		whatever
DESTROYED:	bp before the call is made

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSCPFrame	struct
    GCPF_ds	sptr
    GCPF_vector fptr.far
GFSCPFrame	ends

GFSCallPrimary	proc	far
		.enter
		push	bx, ax, ds
		mov	bp, sp
		segmov	ds, dgroup, ax
		mov	bx, ds:[gfsPrimaryStrat].segment
		mov	ax, ds:[gfsPrimaryStrat].offset
		xchg	ax, ss:[bp].GCPF_vector.offset
		xchg	bx, ss:[bp].GCPF_vector.segment
		mov	ds, ss:[bp].GCPF_ds
		call	ss:[bp].GCPF_vector
		mov	bp, sp
		lea	sp, ss:[bp+size GFSCPFrame]
		.leave
		ret
GFSCallPrimary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSNotifyIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send open/close notification if required.

CALLED BY:	EXTERNAL (GFSAllocOp, GFSHandleOp)
PASS:		cxdx	= file ID
		ax	= FileChangeNotificationType
RETURN:		FILESYSTEM IS UNLOCKED
DESTROYED:	cx (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSNotifyIfNecessary proc	far
		uses	es, bx, si, ds, di
		.enter
		pushf
		call	FSDCheckOpenCloseNotifyEnabled
		jnc	unlockDone
	;
	; Count the number of references there are now to the file so we can
	; decide whether to notify or not.
	; 
		call	LoadVarSegDS
		segmov	es, ds
		mov	si, offset gfsFileTable - offset GFTB_next
		mov	di, cx
		clr	bx, cx			; no references so far
countRefBlockLoop:
		tst	es:[si].GFTB_next
		jz	checkRefCount
		mov	es, es:[si].GFTB_next
		mov	cx, length GFTB_entries
		mov	si, offset GFTB_entries
entryLoop:
		cmp	es:[si].GFE_refCount, 0
		je	nextEntry
		cmpdw	didx, es:[si].GFE_extAttrs
		jne	nextEntry
		add	bl, es:[si].GFE_refCount
nextEntry:
		add	si, size GFSFileEntry
		loop	entryLoop
		clr	si
		jmp	countRefBlockLoop

checkRefCount:
	;
	; Release the filesystem now so the code for FSDGenerateNotify
	; can be faulted in, if necessary.
	; 
		call	GFSDevUnlock
	;
	; bl = # references to the file
	; cx = 0
	; 
		cmp	ax, FCNT_CLOSE
		je	compareToGoal	; => need 0 references to notify
		inc	cx		; is open, so need 1 and only 1
					;  reference
compareToGoal:
		cmp	cx, bx
		jne	done		; => no notification required
	;
	; Now locate the disk registered for our drive.
	; 
		mov	cx, di
		mov	si, ds:[gfsDisk]
		tst	si
		jz	findDisk
haveDisk::
		call	FSDGenerateNotify
done:
		popf
		.leave
		ret
unlockDone:
		call	GFSDevUnlock
		jmp	done

findDisk:
PCMCIAEC <	ERROR	CANNOT_FIND_GFS_DISK				>
if not _PCMCIA
		push	ax
		call	FSDLockInfoShared
		mov	es, ax
		mov	si, offset FIH_diskList - offset DD_next
		mov	bx, ds:[gfsDrive]
findDiskLoop:
		mov	si, es:[si].DD_next
EC <		tst	si						>
EC <		ERROR_Z	CANNOT_FIND_GFS_DISK				>
		cmp	es:[si].DD_drive, bx
		jne	findDiskLoop
		call	FSDUnlockInfoShared
		pop	ax
		mov	ds:[gfsDisk], si
		jmp	haveDisk
endif

GFSNotifyIfNecessary endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadVarSegDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dgroupSeg	sptr	dgroup
LoadVarSegDS	proc	near
		.enter
		mov	ds, cs:[dgroupSeg]
		.leave
		ret
LoadVarSegDS	endp

Resident	ends
