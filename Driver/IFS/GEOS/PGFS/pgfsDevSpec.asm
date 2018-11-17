COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pgfsDevSpec.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/27/94   	Initial version.

DESCRIPTION:
	

	$Id: pgfsDevSpec.asm,v 1.1 97/04/18 11:46:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish with the filesystem

CALLED BY:	GFSExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevExit	proc	far
		.enter
		.leave
		ret
GFSDevExit	endp

Resident	ends

Movable		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevMapDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring in the contents of the indicated directory

CALLED BY:	EXTERNAL
PASS:		dxax	= offset of directory

RETURN:		carry set on error:
			ax	= FileError
			es, di	= destroyed
		carry clear if ok:
			es:di	= first entry in the directory
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevMapDir	proc	near
		uses	ds, bx
		.enter
		call	PGFSMapOffsetFar
		.leave
		ret
GFSDevMapDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnmapDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unmap a directory

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnmapDir	equ PGFSUnmapLastOffset

Movable		ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevMapEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring in the extended attributes for a file.

CALLED BY:	EXTERNAL
PASS:		dxax	= offset of extended attributes
RETURN:		carry set on error:
			ax	= FileError for caller to return
		carry clear if ok:
			es:di	= GFSExtAttrs
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevMapEA	proc	far
		uses	ds, bx
		.enter
		call	PGFSMapOffset
		.leave
		ret
GFSDevMapEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnmapEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the extended attributes we read in last.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnmapEA	equ	PGFSUnmapLastOffset

Resident	ends

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevFirstEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the offset of the first extended attribute
		structure for this directory.

CALLED BY:	EXTERNAL
PASS:		dxax	= base of directory
		cx	= # directory entries in there
RETURN:		dxax	= offset of first extended attribute structure
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevFirstEA	proc	far
		uses	bx, si
		.enter
		movdw	bxsi, dxax
		mov	ax, size GFSDirEntry
		mul	cx
		adddw	dxax, bxsi
	;
	; Round the thing to a 256-byte boundary.
	; 
		adddw	dxax, <size GFSExtAttrs-1>
		andnf	ax, not (size GFSExtAttrs-1)
		
		.leave
		ret
GFSDevFirstEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevNextEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the start of the next GFSExtAttrs structure in
		a directory, given the offset of the current one

CALLED BY:	EXTERNAL
PASS:		dxax	= base of current ea structure
RETURN:		dxax	= base of next
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevNextEA	proc	near
		.enter
		add	ax, size GFSExtAttrs
		adc	dx, 0
		.leave
		ret
GFSDevNextEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevLocateEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the extended attrs for a file given the base of
		the directory that contains it, the number of entries
		in the directory, and the entry # of the file in the directory

CALLED BY:	EXTERNAL
PASS:		dxax	= base of directory
		cx	= # of entries in the directory
		bx	= entry # within the directory
RETURN:		dxax	= base of extended attrs
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevLocateEA	proc	near
		uses	cx, si
		.enter
		call	GFSDevFirstEA
		movdw	cxsi, dxax
		mov	ax, size GFSExtAttrs
		mul	bx
		adddw	dxax, cxsi
		.leave
		ret
GFSDevLocateEA	endp

Movable	ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive access to the filesystem

CALLED BY:	EXTERNAL

PASS:		al 	- GFSDevLockFlags
			es:bx - GFSFileEntry (if GDLF_FILE is set)
			es:si - DiskDesc (if GDLF_DISK set)

RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	5/1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevLock	proc	far
		uses	ds, bx, cx
		.enter
		call	LoadVarSegDS
		PSem	ds, fileSem
		test	al, mask GDLF_FILE
		jz	notFile

		mov	bx, es:[bx].GFE_socket
store:
		mov	ds:[curSocketPtr], bx
done:
		.leave
		ret
notFile:
		test	al, mask GDLF_DISK
		jz	done

	;
	; Hack!  Store the disk handle in dgroup, in case we ever use
	; it (open/close notification)
	;
		
		mov	ds:[gfsDisk], si
		push	si
		mov	si, es:[si].DD_drive
		mov	si, es:[si].DSE_private
		mov	bx, es:[si].PGFSPD_socketPtr
		pop	si
		jmp	store

GFSDevLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to the filesystem.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnlock	proc	far
		uses	ds, bx, ax
EC <		uses	si					>
		.enter
		pushf
		call	LoadVarSegDS
EC <		mov	ds:[curSocketPtr], -1			>
EC <		tst	ds:[fsMapped]				>
EC <		ERROR_NZ	SOMETHING_NOT_UNMAPPED		>
   		VSem	ds, fileSem, TRASH_AX_BX
		popf
		.leave
		ret
GFSDevUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read bytes from the filesystem

CALLED BY:	EXTERNAL
PASS:		dxax	= offset from which to read them
		cx	= number of bytes to read
		es:di	= place to which to read them
RETURN:		carry set on error:
			ax	= FileError
		carry clear if all bytes read
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevRead	proc	far
		
		uses	bx, cx, dx, di, si, bp, ds

		.enter

		mov	bp, cx		; number of bytes to move
mapLoop:
	;
	; Map in the initial data. Comes back with es:di = data, but we need
	; ds:si
	;
		push	es, di
		call	PGFSMapOffset
		mov	bl, ds:[bx].PGFSSI_flags
		segmov	ds, es, si
		mov	si, di
		pop	es, di
		jc	done
	;
	; Figure number of bytes to use from this bank.
	; 
		mov	cx, BANK_SIZE
		sub	cx, si		; cx <- # bytes to bank end
		cmp	cx, bp		; more than we need?
		jbe	moveIt		; no
		mov	cx, bp		; get only what we need
moveIt:
	;
	; Reduce overall count by the number of bytes being moved now, then
	; move them. 
	; 
		add	ax, cx
		adc	dx, 0		; point dx:ax to to start of
					; next bank
		sub	bp, cx

		pushf			; save Z flag from subtraction
		test	bl, mask PSF_16_BIT
		jz	moveBytes

		shr	cx
		rep	movsw
		jnc	afterMove
		movsb
afterMove:
EC <		call	PGFSUnmapLastOffset				>
		popf			; restore Z flag
		jnz	mapLoop

done:
		.leave
		ret

moveBytes:
		rep	movsb
		jmp	afterMove
GFSDevRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSUnmapLastOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unmap the thing we mapped before

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Don't actually do anything 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSUnmapLastOffset proc	far
if ERROR_CHECK
		uses	ds, ax
		.enter
		pushf
		call	LoadVarSegDS
		clr	ax
		xchg	ax, ds:[fsMapped]
		tst	ax
		ERROR_Z	NOTHING_MAPPED
		popf
		.leave
endif
		ret
PGFSUnmapLastOffset endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSDiskID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an error if the card is removed

CALLED BY:	GFSDiskID

PASS:		es:si - DriveStatusEntry

RETURN:		cx:dx - disk ID
		al

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 5/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSDiskID	proc near
		uses	ds, bx
		.enter
		call	LoadVarSegDS
		mov	bx, es:[si].DSE_private
		mov	bx, es:[bx].PGFSPD_socketPtr

		test	ds:[bx].PGFSSI_conflict, mask PGFSCI_REMOVED
		jnz	error
		movdw	cxdx, ds:[bx].PGFSSI_checksum
		mov	ax, MEDIA_FIXED_DISK shl 8
done:
		.leave
		ret
error:
		stc
		jmp	done
PGFSDiskID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSPowerOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on the power to the socket

CALLED BY:	GFSDiskLock

PASS:		es:bx - DriveStatusEntry

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

	Stolen from CIDFSStrategy

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 5/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSPowerOn	proc near
		uses	cx, ds
		.enter
		push	ax, bx
		call	LoadVarSegDS
		mov	bx, es:[bx].DSE_private
		mov	bx, es:[bx].PGFSPD_socketPtr
	;
	; The synchronization here is ugly. Because the conflict resolution
	; stuff may need to wake up a bunch of people, it does a VAllSem
	; followed by setting the Sem_value to 0 (both are done within a
	; single critical section). Because we could context-switch between
	; checking the _conflict variable and performing a PSem, ending up
	; with us blocked on the semaphore with _conflict set FALSE (i.e.
	; blocking until the next time the card is removed), we enter our
	; own critical section before checking the _conflict flag, leaving it
	; only after we've decremented Sem_value. We don't even check the result
	; of the decrement as we know that if _conflict is TRUE, we should
	; always block.
	;
	; Now, when ObjectionResolved performs its VAllSem, if there aren't
	; -Sem_value threads on the queue, Sem_queue will end up a positive
	; number that will keep us from blocking at all. If the conflict isn't
	; resolved before we block, it's just as if we'd done a normal PSem.
	; If the conflict is resolved before we block, we won't actually
	; block.
	;
	; While it's true that another conflict could arise after
	; the VAllSem is complete and before we block, which means that we
	; (or some other thread) won't actually block when we're supposed to,
	; and the counter will be off forever, I don't think I care enough
	; to worry about it.
	; 
		call	SysEnterCritical
		test	ds:[bx].PGFSSI_conflict, mask PGFSCI_REMOVED
		jz	continuePowerOn
	; 
	; check to see if the thread is the pcmcia
	; thread, if it is do not dec the semaphore. this is done to
	; prevent the pcmcia thread from blocking on the conflict and
	; then not being able to clear the conflict.
	; 
		cmp	ss:[TPD_processHandle], handle pcmcia
		je	continuePowerOn

		dec	ds:[bx].PGFSSI_conflictSem.Sem_value

		call	SysExitCritical

		mov	ax, ds		; ax:bx <- queue on which to block
		add	bx, offset PGFSSI_conflictSem.Sem_queue
		call	ThreadBlockOnQueue 
		jmp	continuePowerOn_CriticalExited

continuePowerOn:
		call	SysExitCritical

continuePowerOn_CriticalExited:
		pop	ax, bx
		mov	cx, -1
		call	PGFSPowerOnOffCommon
		.leave
		ret

PGFSPowerOn	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSPowerOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the power

CALLED BY:	GFSDiskUnlock

PASS:		es:bx - DriveStatusEntry

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 5/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSPowerOff	proc near
		uses	ds, cx
		.enter
		call	LoadVarSegDS
		clr	cx
		call	PGFSPowerOnOffCommon

		.leave
		ret
PGFSPowerOff	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSPowerOnOffCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the power driver

CALLED BY:	PGFSPowerOn, PGFSPowerOff

PASS:		cx - nonzero to turn power on, zero to power off
		ds - dgroup
		es:bx - DriveStatusEntry

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 5/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSPowerOnOffCommon	proc near
		tst	ds:[powerStrat].segment
		jz	done

		push	ax, bx, dx, di
		mov	ax, PDT_PCMCIA_SOCKET
		mov	bx, es:[bx].DSE_private
		mov	bx, es:[bx].PGFSPD_common.PCMDPD_socket
		mov	dx, mask PCMCIAPI_NO_POWER_OFF
		mov	di, DR_POWER_DEVICE_ON_OFF
		call	ds:[powerStrat]
		pop	ax, bx, dx, di
done:
		clc
		ret
PGFSPowerOnOffCommon	endp

Resident	ends
