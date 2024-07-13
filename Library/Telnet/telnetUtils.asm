COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS (Network Extensions)
MODULE:		TELNET Library
FILE:		telnetUtils.asm

AUTHOR:		Simon Auyeung, Jul 19, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
    EXT TelnetEntry		Entry point for Telnet library

    EXT TelnetControlStartRead	Start a reference to a control block

    EXT TelnetControlEndRead	End a reference to control block

    EXT TelnetControlStartWrite	Start an update of control block

    EXT TelnetControlEndWrite	End an update to the control block

    EXT TelnetControlDeref	Dereference segment of the control block
				that is locked

    EXT TelnetGetSocket		Get the socket associated with
				TelnetConnectionID

    EXT TelnetWriteCharRecvBuf	Write a character into the receiving buffer

    EXT TelnetCheckNotification	Check for any notification we may need to
				return to caller

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon		7/19/95   	Initial revision


DESCRIPTION:
	This file contains utility routines.
		

	$Id: telnetUtils.asm,v 1.1 97/04/07 11:16:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilsCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for Telnet library

CALLED BY:	(EXTERNAL) KERNEL
PASS:		di	= LibraryCallType
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
EC <	Allocate semaphore on entry to protect TelnetIDArray		>

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetEntry	proc	far
		ForceRef	TelnetEntry
		uses	ds, si, ax, bx
		.enter
	
if	ERROR_CHECK
	;
	; Ignore if we do not either attach or detach
	;
		cmp	di, LCT_ATTACH
		je	handleLibEntry
		cmp	di, LCT_DETACH
		jne	done
		
handleLibEntry:

		call	TelnetControlStartWrite	; ds <- TelnetControl segment
		mov	si, offset TelnetIDArray
		mov	si, ds:[si]		; ds:si <- TelnetIDArrayHeader
	;
	; If the lib is loaded, allocate the semaphore to protect
	; TelnetIDArray. If the lib is unloaded, deallocate that semaphore.
	;
		cmp	di, LCT_ATTACH
		je	attachLib
	
detachLib::
	;
	; We must be detaching. Free the semaphore we have allocated
	;
		cmp	di, LCT_DETACH		; we have to be detaching!
		ERROR_NE TELNET_LIB_ENTRY_ERROR
		mov	bx, ds:[si].TIDAH_sem
		tst	bx			; there must be a sem to free!
		ERROR_Z TELNET_LIB_ENTRY_ERROR
		call	ThreadFreeSem
		jmp	doneAttachDetach	
	
attachLib:
	;
	; Allocate the semaphore to protect exclusive access of
	; TelnetIDArray.
	;
		mov	bx, 1			; initially unlocked	
		call	ThreadAllocSem		; bx <- TelnetIDArray semaphore
		mov	ax, handle 0		; Assign sem owner to lib
		call	HandleModifyOwner	; ax destroyed
		mov	ds:[si].TIDAH_sem, bx
	
doneAttachDetach:
		call	TelnetControlEndWrite

done:
endif	; ERROR_CHECK
	
		clc				; always no error
		.leave
		ret
TelnetEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetControlStartRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a reference to a control block

CALLED BY:	(EXTERNAL) TelnetSend, TelnetSendCommand, TelnetSetStatus
PASS:		nothing
RETURN:		ds	= TelnetControl segment
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetControlStartRead	proc	far
		uses	ax, bx
		.enter
	;
	; Lock the block and return segment
	;
		pushf
		mov	bx, handle TelnetControl
		call	MemLockShared		; ax <- sptr of TelnetControl
		mov	ds, ax
		popf
		
		.leave
		ret
TelnetControlStartRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetControlEndRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a reference to control block

CALLED BY:	(EXTERNAL) TelnetSend, TelnetSendCommand, TelnetSetStatus
PASS:		nothing
RETURN:		nothing 
DESTROYED:	non-EC: nothing (flags preserved)
		EC:	ds and es may be destroyed if they point at
			TelnetControl. (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetControlEndRead	proc	far
		uses	bx
		.enter
	;
	; Unlock the control block
	;
		mov	bx, handle TelnetControl
		call	MemUnlockShared		; nothing destroyed
	
		.leave
		ret
TelnetControlEndRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetControlStartWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start an update of control block

CALLED BY:	(EXTERNAL) TelnetClose, TelnetCreate, TelnetEntry,
		TelnetRecv, TelnetRecvLow
PASS:		nothing
RETURN:		ds	= TelnetControl block segment
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	3/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetControlStartWrite	proc	far
		uses	ax, bx
		.enter

		pushf
		mov	bx, handle TelnetControl
		call	MemLockExcl		; ax <- sptr of TelnetControl
		mov	ds, ax
		popf
		
		.leave
		ret
TelnetControlStartWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetControlEndWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End an update to the control block

CALLED BY:	(EXTERNAL) TelnetClose, TelnetCreate, TelnetEntry,
		TelnetRecv, TelnetRecvLow
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	3/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetControlEndWrite	proc	far
		uses	bx
		.enter

		mov	bx, handle TelnetControl
		call	MemUnlockExcl
	
		.leave
		ret
TelnetControlEndWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetControlDeref
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference segment of the control block that is locked

CALLED BY:	(EXTERNAL) ECCheckTelnetInfo, TelnetGetSocket
PASS:		nothing
RETURN:		ds	= Telnet control block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	3/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetControlDeref	proc	far
		uses	bx
		.enter

		mov	bx, handle TelnetControl
		call	MemDerefDS

		.leave
		ret
TelnetControlDeref	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetGetSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the socket associated with TelnetConnectionID

CALLED BY:	(EXTERNAL) TelnetRecvLow
PASS:		bx	= TelnetConnectionID
RETURN:		ax	= Socket
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetGetSocket	proc	far
		uses	bx, ds
		.enter

		call	TelnetControlDeref	; ds <- control segment
		mov	bx, ds:[bx]		; ds:bx <- TelnetInfo
		mov	ax, ds:[bx].TI_socket	; ax <- Socket
EC <		Assert_socket	ax					>

		.leave
		ret
TelnetGetSocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetWriteCharRecvBuf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a character into the receiving buffer

CALLED BY:	(EXTERNAL) TelnetControlReadyStateHandler,
		TelnetGroundStateHandler 
PASS:		es:bp	= target memory to write
		al	= character to write
		ds:dx	= fptr to TelnetInfo
RETURN:		bp	= updated to point to next memory location
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (not in mode of discarding data) {
		Copy char to target memory;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetWriteCharRecvBuf	proc	far
		uses	si
		.enter
EC <		Assert_fptr	dsdx					>
EC <		Assert_fptr	esbp					>
		mov	si, dx
EC <		cmp	al, TC_EOF					>
EC <		jb	cont						>
EC < check::								>
EC <		nop							>
EC < cont:								>
		BitTest	ds:[si].TI_status, TS_SYNCH_MODE
		jnz	discardData		; jmp if need to discard data
		mov	es:[bp], al		; copy byte to recv buf
		inc	bp			; advance ptr
	
discardData:
		.leave
		ret
TelnetWriteCharRecvBuf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetCheckNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for any notification we may need to return to caller

CALLED BY:	(EXTERNAL) TelnetOptionStartStateHandler
PASS:		ds:si	= TelnetInfo
RETURN:		carry set if there is notification
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We only look for remote echo option;
 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetCheckNotification	proc	far
		uses	ax
		.enter
EC <		Assert_chunkPtr	si, ds					>
	;
	; The only notification are remote echoing or remote not echoing
	;
		cmp	ds:[si].TI_currentOption, TOID_ECHO
		jne	noNotify

		mov	ax, TNT_REMOTE_ECHO_ENABLE
		cmp	ds:[si].TI_currentCommand, TOR_WILL
		je	setNotification

		mov	ax, TNT_REMOTE_ECHO_DISABLE
		cmp	ds:[si].TI_currentCommand, TOR_WONT
		jne	noNotify

setNotification:
		mov	ds:[si].TI_notification, ax

notify::
		stc
		jmp	done

noNotify:
		clc

done:
		.leave
		ret
TelnetCheckNotification	endp

UtilsCode	ends
