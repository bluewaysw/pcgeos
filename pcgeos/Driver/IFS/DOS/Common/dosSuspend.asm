COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosSuspend.asm

AUTHOR:		Adam de Boor, May 19, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT DOSSuspend		Prepare the system for entering stasis

    INT DOSUnsuspend		Bring the system out of stasis

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/19/92		Initial revision


DESCRIPTION:
	Functions to deal with DR_SUSPEND/DR_UNSUSPEND
		

	$Id: dosSuspend.asm,v 1.1 97/04/10 11:55:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	The minimum # of file slots that must be open in the base SFT for us
;	to allow ourselves to be suspended so the user doesn't get screwed by
;	running out of files and being unable to reload command.com and causing
;	the system to be halted. Applies only to MS DOS

MIN_FILES equ 10

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare the system for entering stasis

CALLED BY:	DR_SUSPEND
PASS:		cx:dx	= buffer in which to place reason for refusal
RETURN:		carry set if suspend refused:
			cx:dx	= filled with null-terminated string
		carry clear if ready for suspend
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		Unload int 24

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version
	ron	12/3/93		added interrupt stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSSuspend	proc	far
		uses	ds, si, es
		.enter
	;
	; Unhook critical error handling, so certain task-switch drivers
	; don't have to mess with the interrupt table...
	;
		call	LoadVarSegDS
		call	DOSUnhookCriticalError
if _MS
	;
	; For MS-DOS, we need to truncate the SFT to its original dimensions
	; after ensuring there are enough open slots to make suspending
	; viable.
	; 
		push	cx, dx
		call	LoadVarSegDS
		segmov	es, ds
		mov	di, offset sftStart - offset SFTBH_next
		clr	dx		; none free so far
blockLoop:
		lds	di, ds:[di].SFTBH_next
		cmp	di, NIL
		je	blockLoopDone
		mov	cx, ds:[di].SFTBH_numEntries
		lea	si, ds:[di].SFTBH_entries
entryLoop:
		tst	ds:[si].SFTE_refCount	; open?
		jnz	next			; referenced >= 1 time => open
		inc	dx			; nope. another free
next:
if _MS3
		add	si, es:[sftEntrySize]
else
		add	si, size SFTEntry
endif
		loop	entryLoop
	;
	; Was this the last original block?
	; 
		cmp	di, es:[sftInitEnd].offset
		jne	blockLoop
		mov	ax, ds
		cmp	ax, es:[sftInitEnd].segment
		jne	blockLoop
blockLoopDone:
		cmp	dx, MIN_FILES
		pop	cx, dx
		jb	noRoom
		
		mov	ax, NIL
		xchg	ds:[di].SFTBH_next.offset, ax
		mov	es:[sftFirstExtension].offset, ax
		mov	ax, NIL
		xchg	ds:[di].SFTBH_next.segment, ax
		mov	es:[sftFirstExtension].segment, ax
done:
		.leave
		ret
noRoom:
	;
	; Copy the error message into the passed buffer.
	; 
		segmov	ds, Strings, ax
		assume ds:Strings
		mov	si, ds:[tooFewFiles]
		assume ds:nothing
		mov	es, cx
		mov	di, dx
		push	cx
		ChunkSizePtr ds, si, cx
		rep	movsb
		pop	cx
	;
	; Return carry set to signal our displeasure.
	; 
		stc
		jmp	done

else	; DRI ---------------------------------------
	;
		clc
		.leave
		ret
endif
DOSSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the system out of stasis

CALLED BY:	DR_UNSUSPEND
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSUnsuspend	proc	far
if _MS
		uses	ds, es, ax, bx, cx, di
		.enter
	; 
	; Hook our critical int handler in again
	;
		segmov	ds, dgroup, ax
		call	DOSHookCriticalError
	;
	; Link our extended SFT into the original one.
	; XXX: in 1.2 we worried about the SFT having been extended while we
	; were out. I think such worries are pointless, however...
	; 
		call	LoadVarSegDS
		les	di, ds:[sftInitEnd]
		mov	ax, ds:[sftFirstExtension].offset
		mov	es:[di].SFTBH_next.offset, ax
		mov	ax, ds:[sftFirstExtension].segment
		mov	es:[di].SFTBH_next.segment, ax
		clc
		.leave
		ret
else	; DRI ------------------------------------------------------------
		push	es, ds, ax, bx, cx, di
		segmov	ds, dgroup, ax
		call	DOSHookCriticalError
		pop	es, ds, ax, bx, cx, di
		clc
		ret
endif
DOSUnsuspend	endp

Resident	ends
