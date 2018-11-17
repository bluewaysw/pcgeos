COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		pgfsRemove.asm

AUTHOR:		Adam de Boor, Sep 30, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/30/93		Initial revision


DESCRIPTION:
	Stuff for coping with the removal of a card.
		

	$Id: pgfsRemove.asm,v 1.1 97/04/18 11:46:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRHandleRemoval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the removed card is one we need

CALLED BY:	(EXTERNAL) PGFSCardServicesCallback
PASS:		cx	= socket
		dx	= info
		ds	= dgroup
RETURN:		carry set on error, clear on success
		ax	= CardServicesReturnCode
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSRHandleRemoval proc	near
		uses	bx, dx, bp
		.enter
		call	PGFSUCheckInUse		; ds:bx - PGFSSocketInfo
		jnc	done

		clr	dx			; card may be removed
		mov	bp, handle 0
		call	PCMCIAObjectToRemoval
		
		mov	ds:[bx].PGFSSI_conflict, mask PGFSCI_REMOVED or \
			mask PGFSCI_OBJECTION

		inc	ds:[numConflicts]
		jnz	done
		
		push	bx, si, cx, dx, di, bp
		mov	bx, cs
		mov	si, offset PGFSRConflictTimer
		mov	al, TIMER_ROUTINE_CONTINUAL
		mov	cx, 1*60		; check every second
		mov	di, cx			; di < -interval
		mov	dx, ds			; dx <- dgroup
		mov	bp, handle 0		; timer owned by us
		call	TimerStart
		mov	ds:[restartTimer], bx
		mov	ds:[restartTimerID], ax
		pop	bx, si, cx, dx, di, bp
done:

	;
	; Release the window we allocated
	;
		
		test	ds:[bx].PGFSSI_flags, mask PSF_WINDOW_ALLOCATED
		jz	afterRelease

		mov	dx, ds:[bx].PGFSSI_window
		call	PGFSReleaseWindow
afterRelease:
		andnf	ds:[bx].PGFSSI_flags, not (mask PSF_PRESENT \
				or mask PSF_WINDOW_ALLOCATED)
		mov	ax, CSRC_SUCCESS
		clc
		.leave
		ret
PGFSRHandleRemoval endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRConflictTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to cope with user choosing Restart option while files
		are in use. If EF_RESTART set in exit flags and 15 seconds have
		elapsed since last disk lock, perform a dirty shutdown

CALLED BY:	timer
PASS:		ax	= dgroup
RETURN:		nothing
DESTROYED:	anything
SIDE EFFECTS:	system may enter dirty shutdown

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSRConflictTimer proc	far
		.enter
		clr	bx			; set nothing, clear nothing
		call	SysSetExitFlags		; bl <- current flags
		test	bl, mask EF_RESTART
		jz	done
		
		mov	ax, SGIT_LAST_DISK_ACCESS
		call	SysGetInfo		; dxax <- systemCounter at
						;  last DiskLock
		mov_tr	cx, ax
		call	TimerGetCount		; bxax <- systemCounter
		subdw	bxax, dxcx		; bxax <- time since last access
						;  (in ticks)
		cmpdw	bxax, CID_RESTART_DELAY
		jb	done			; not yet, but soon...
		
	;
	; Change the restart to a reboot and get the hell out without closing
	; anything else down. The theory here is that we've done what we
	; can to cope with this abnormal situation (as evidenced by there
	; not having been any disk activity for the last 15 seconds or so)
	; and anything that could be saved has been saved. Anything that's not
	; saved now is doomed to corruption anyway, so a fast exit and machine
	; reboot won't harm anything.
	; 
		mov	bx, mask EF_RESET or (mask EF_RESTART shl 8)
		call	SysSetExitFlags
		mov	si, -1
		mov	ax, SST_PANIC
		call	SysShutdown
		.unreached
done:
		.leave
		ret
PGFSRConflictTimer endp
Resident	ends

ProcessCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRObjectionResolved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follow the dictates of our user.

CALLED BY:	DR_PCMCIA_OBJECTION_RESOLVED
PASS:		ds	= dgroup
		cx	= socket number
		dx	= PCMCIAObjectionResolution
RETURN:		carry set if told to clean up but can't
		carry clear if all ok.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSRObjectionResolved proc	far
		uses	ds, bx, cx, ax
		.enter
	;
	; First cope with conflict timer.
	; 
		call	PGFSUDerefSocket
		call	SysEnterCritical
		clr	al
		xchg	ds:[bx].PGFSSI_conflict, al
		test	al, mask PGFSCI_OBJECTION
		jz	checkMode
		
		dec	ds:[numConflicts]
		jns	checkMode
		
		push	bx
		clr	bx
		xchg	ds:[restartTimer], bx
		mov	ax, ds:[restartTimerID]
		call	TimerStop
		pop	bx

checkMode:
		call	SysExitCritical
		
			CheckHack <PCMOR_CLEAN_UP eq 0>
		tst_clc	dx
		jz	attemptCleanUp
	;
	; All access blocks were just released, so there's nothing more to do
	; here.
	;  
done:
		.leave
		ret
attemptCleanUp:
	;
	; Notify anyone with anything to do with any drive from this socket.
	; They should, in theory, stop using the thing.
	; 
		call	PGFSRNotifyRemoval
	;
	; Wait a while for the in-use count on the socket to drop to
	; 0, sleeping for several seconds between checks. Return carry
	; set if count doesn't reach 0 after a reasonable amount of
	; time.
	; 
		call	PGFSUDerefSocket

	;
	; Delete all of the fonts so that any fonts on the pcmcia card
	; to be removed, will not be in use.
	;
		call	PGFSRDeleteFonts
		
		mov	cx, CID_CLEAN_UP_NUM_RETRIES
cleanUpWaitLoop:
		tst_clc	ds:[bx].PGFSSI_inUseCount
		jz	done

		mov	ax, CID_CLEAN_UP_DELAY
		call	TimerSleep	; wait another interval
		loop	cleanUpWaitLoop

		stc			; couldn't clean up.
					; Tell the user this.
		jmp	done
PGFSRObjectionResolved endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRCloseSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete any drives we manage, since there are no references
		to them.

CALLED BY:	DR_PCMCIA_CLOSE_SOCKET
PASS:		cx	= socket number
		ds 	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	drives get biffed, standard paths removed, etc.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSRCloseSocket proc	far
		uses	ax, si, bx
		.enter
		call	PGFSRNotifyRemoval

		call	PGFSUDerefSocket

		call	PGFSRDeleteStdPath

		mov	al, ds:[bx].PGFSSI_drive
		call	FSDDeleteDrive

		call	PGFSRRestoreFonts
		.leave
		ret
PGFSRCloseSocket endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRRestoreFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try to restore any fonts that were deleted from the
	system when the card was removed, in case they are still
	somewhere else in the font path.

CALLED BY:	PGFSRCloseSocket
PASS:		ds:bx - PGFSSocketInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Goes throught the deletedFonts array of handles to lists of
fonts and calls FontDrAddFonts with that list.  calculates the number
of fonts in the list by dividing the size of the list by the size of
FileLongName. (This should work)
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSRRestoreFonts	proc	near
		uses	ax,bx,cx,dx,di
		.enter

	;
	; get the block of fonts to add back in
	;
		mov	di, bx
		clr	bx
		xchg	bx, ds:[di].PGFSSI_deletedFonts
		tst	bx
		jz	done
	;
	; get the number of names if the list
	;
		mov	ax,MGIT_SIZE
		call	MemGetInfo
		clr	dx
		mov	cx, size FileLongName
		div	cx				;ax <- num fonts names
		mov	cx, ax
	
	;
	; add the fonts back
	;
		call	FontDrAddFonts
		call	MemFree
done:
		.leave
		ret
PGFSRRestoreFonts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRNotifyRemoval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the world know any drive in the socket is going away.

CALLED BY:	(INTERNAL)
PASS:		cx	= socket number
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	stuff be sent out

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSRNotifyRemoval proc	near
		uses	dx
		.enter
		mov	dx, handle 0
		call	PCMCIANotifyRemoval
		.leave
		ret
PGFSRNotifyRemoval endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRDeleteStdPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove any std path we added.

CALLED BY:	PGFSRCloseSocket
PASS:		ds:bx - PGFSSocketInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/14/93		Initial version
	ardeb	10/4/93		Stolen from FATFS driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSRDeleteStdPath proc	near
		uses	ax
		.enter
		test	ds:[bx].PGFSSI_flags, mask PSF_HAS_SP_TOP
		jz	done
		mov	al, ds:[bx].PGFSSI_drive
		call	PCMCIADeleteStdPath
		andnf	ds:[bx].PGFSSI_flags, not mask PSF_HAS_SP_TOP
done:
		.leave
		ret
PGFSRDeleteStdPath endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRDeleteFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete the fonts for each partition on the card.

CALLED BY:	PGFSRObjectionResolved
PASS:		ds:bx - PGFSSocketInfo
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	saves the lists of fonts deleted in the global
		deletedFonts array .

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSRDeleteFonts	proc	near
		uses	ax, bx, cx
		.enter
		test	ds:[bx].PGFSSI_flags, mask PSF_HAS_FONTS
		jz	done
	;
	; call PCMCIADeleteFonts to delete the fonts, then save the
	; list of deleted fonts returned.
	;
		mov	al, ds:[bx].PGFSSI_drive
		push	bx
		call	PCMCIADeleteFonts
		mov_tr	ax, bx			; list of font filenames
		pop	bx
		jc	notDeleted

	;
	; Save the list of deleted fonts (?)
	;
		
		mov	ds:[bx].PGFSSI_deletedFonts, ax
notDeleted:
		andnf	ds:[bx].PGFSSI_flags, not mask PSF_HAS_FONTS

done:		
		.leave
		ret
PGFSRDeleteFonts	endp


ProcessCode	ends

