COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	GEOS	
MODULE:		GDI Library - Common Code
FILE:		gdiUtils.asm

AUTHOR:		Todd Stumpf, Apr 30, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96   	Initial revision


DESCRIPTION:
	
		

	$Id: gdiUtils.asm,v 1.1 97/04/04 18:03:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIInitInterface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a passed interface

CALLED BY:	INTERNAL
PASS:		dx	-> mask of activeInterfaceMask to set if successful
		si	-> offset of actual HW init to call
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:
		Initializes hardware

PSEUDO CODE/STRATEGY:
		Call C routine that initializes hardware
		Look for errors
		On success, mark interface as active

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIInitInterface	proc	near
	uses	ds
	.enter

	;
	;  Get dgroup for us, and them...
	MOV_SEG	ds, <segment dgroup>

	;
	;  See if interface already active
	test	ds:[activeInterfaceMask], dx		; been here, done this?
	mov	ax, EC_INTERFACE_ALREADY_ACTIVE		; assume so
	stc
	jnz	done	; => Never again!  Never!

	;
	;  Call hardware specific handler...
	push	bx, cx, dx, es
							; ds -> dgroup
	call	si				; ax <- ErrorCode
						; bx, cx, dx, es trashed
	pop	bx, cx, dx, es

	;
	;  See if things went okay
	cmp	ax, EC_NO_ERROR				; are things okay?
	stc						; assume worst
	jne	done	; => things went wrong

	;
	;  Mark interface as initialized.
	or	ds:[activeInterfaceMask], dx		; clears carry

done:
	.leave
	ret
GDIInitInterface	endp


InitCode		ends

ShutdownCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIShutdownInterface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		dx	-> activeInterfaceMask for interface
		bx	-> offset to callback table
		si	-> HW routine to call
RETURN:		carry set on error
		ax	<- ErrorCode

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIShutdownInterface	proc	near

	uses	bx, ds
	.enter
	;
	;  Get dgroup for us, and them...
	MOV_SEG	ds, <segment dgroup>

	;
	;  Now, see if it's even active...
	test	ds:[activeInterfaceMask], dx		; check for activity
	mov	ax, EC_INTERFACE_NOT_INITIALIZED	; assume the worst
	stc
	jz	done	; => never active

	;
	;  Next, check for any registered callbacks
							; bx -> callback table
	call	GDICheckCallbacks		; carry set if active

	mov	ax, EC_CALLBACKS_STILL_ACTIVE
	jc	done	; => still going

	;
	;  Well, we're clear to shutdown, then.
	push	bx, cx, dx, es

							; ds -> dgroup
	call	si				; ax <- ErrorCode
	pop	bx, cx, dx, es

	;
	;  See if things are dead
	cmp	ax, EC_NO_ERROR				; things okay?
	stc						; assume not
	jne	done	; => Problems...

	;
	;  Mark interface as disabled.
	xor	ds:[activeInterfaceMask], dx		; clears carry

done:
	.leave
	ret
GDIShutdownInterface	endp

ShutdownCode		ends

CallbackCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIRegisterCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff a passed far pointer into the indicated table

CALLED BY:	INTERNAL
PASS:		dx:si	-> callback to register
		bx	-> offset of table for callback
RETURN:		ax <- ErrorCode
		bx <- slot index or ffffh if error
		carry set on error
DESTROYED:	flags only
SIDE EFFECTS:
		Places callback into table atomically

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIRegisterCallback	proc	far
	uses	cx, ds
	.enter

	MOV_SEG	ds, dgroup				; ds:bx <- table
	mov	cx, NUM_CALLBACK_SLOTS			; cx <- # of entries

	clr	ax
topOfLoop:
	cmp	ax, ds:[bx]
	je	checkSlot	; => check segment
checkForMatch:
	cmp	dx, ds:[bx]				; could slot match?
	je	checkFptr	; => check offset

noMatch:
	add	bx, 4
	loop	topOfLoop

	mov	bx, -1
	mov	ax, EC_CALLBACK_TABLE_FULL
	stc
done:
	.leave
	ret

checkSlot:
	;
	;  Offset was zero, see if segment is zero
	cmp	ds:[bx]+2, ax
	jne	checkForMatch	; => non-zero segment

	;
	;  We've found our empty slot.  Automically stuff it.
	INT_OFF
	movdw	ds:[bx], dxsi
	INT_ON

	;
	; Return the index of the slot. (starting from 0)
	mov	bx, NUM_CALLBACK_SLOTS
	sub	bx, cx	

	mov	ax, EC_NO_ERROR
	clc
	jmp	short done

checkFptr:
	;
	;  Segments of callbacks matched, see if offsets match
	cmp	si, ds:[bx]+2
	jne	noMatch

	mov	bx, -1
	mov	ax, EC_CALLBACK_ALREADY_PRESENT
	stc
	jmp	done


GDIRegisterCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIUnregisterCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister a callback routine

CALLED BY:	GDIPowerUnregister

PASS:		dx:si	-> fptr of callback to remove
		bx	-> offset powerCallbackTable

RETURN:		carry set if not found
		ax	-> error code

DESTROYED:	flags only

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIUnregisterCallback	proc	far
	uses	cx, bx, ds
	.enter

	MOV_SEG	ds, dgroup				; ds:bx <- table
	mov	cx, NUM_CALLBACK_SLOTS			; cx <- # of entries

topOfLoop:
	cmp	si, ds:[bx]				; could slot match?
	je	checkFptr	; => check segment

noMatch:
	add	bx, 4
	loop	topOfLoop

	mov	ax, EC_CALLBACKS_NOT_PRESENT
	stc
done:
	.leave
	ret

checkFptr:
	;
	;  Segments of callbacks matched, see if offsets match
	cmp	dx, ds:[bx]+2
	jne	noMatch

	clrdw	ds:[bx]
	mov	ax, EC_NO_ERROR
	clc
	jmp	done

GDIUnregisterCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDICheckCallbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if callback table is empty

CALLED BY:	GDIShutdownInterface
PASS:		bx	-> offset to callback table
RETURN:		carry set if still active
DESTROYED:	nothing
SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Scan table looking for non-zero entry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDICheckCallbacks	proc	far
	uses	ax, cx, di, es
	.enter

	MOV_SEG	es, ds
	mov	di, bx
	clr	ax
	mov	cx, NUM_CALLBACK_SLOTS * 2		; size of table

	repz	scasw
	clc
	jz	done	; => All zeroes

	stc
done:
	.leave
	ret
GDICheckCallbacks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDICallCallbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call all registered callbacks with identical registers

CALLED BY:	INTERNAL
PASS:		di	-> offset of callback table to use
		bp	-> offset of in-between-callback to call
		si	-> SystemEventType

		ax, bx, cx, dx possible data
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDICallCallbacks	proc	near
		.enter

		call	GDICallAllSlots
	;
	;	Next call all slots for systemMonitor, it is a common
	;	callback table and should be called for all events.
	;
		mov	di, offset systemMonitorCallbackTable
		call	GDICallAllSlots

		.leave
		ret

GDICallCallbacks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDICallAllSlots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL: GDICallCallbacks
PASS:		di	-> offset of table to call
		bp	-> offset of in-between-callback to call
		si	-> SystemEventType

		ax, bx, cx, dx possible data
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	8/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDICallAllSlots	proc	near
	uses	es, si
	.enter

	xchg	di, si					; di <- SystemEventType
	;
	;  Get hands on callbacks
	MOV_SEG	es, dgroup				; es:si <- callbacks

	tstdw	es:[si]					; this slot empty?
	jz	checkSlot2	; => MT

	call	DWORD PTR es:[si]			; call callback
	call	bp					; let client know

checkSlot2:
	add	si, size fptr				; next!

	tstdw	es:[si]					; this slot taken?
	jz	checkSlot3	; => MT

	call	DWORD PTR es:[si]			; Yoohooo!
	call	bp					; *nudge* *nudge*

checkSlot3:
	add	si, size fptr				; Scoot down!

	tstdw	es:[si]					; Got any more?
	jz	done		; => MT

	call	DWORD PTR es:[si]			; * Surprise! *
	call	bp					; get the bill...

done:
	.assert NUM_CALLBACK_SLOTS eq 3

	.leave
GDINoCallback	label	near
	ret
		
GDICallAllSlots	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIHWGenerateEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		di	-> offset of callback table to call.
		ax, bx, cx, dx, si possible data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	8/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIHWGenerateEvents	proc	near
		uses	si
		.enter
		clr	si		; signify a hardware event
		call	GDIFilterEvents
		.leave
		ret
GDIHWGenerateEvents	endp

GDIFilterEventsFar	proc	far
		call	GDIFilterEvents
		ret
GDIFilterEventsFar	endp

GDIGetExclusiveFar	proc	far
		call	GDIGetExclusive
		ret
GDIGetExclusiveFar endp

GDIReleaseExclusiveFar	proc	far
		call	GDIReleaseExclusive
		ret
GDIReleaseExclusiveFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIFilterEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		si	-> registerID
		di	-> offset of callback table to use
		bp	-> offset of in-between-callback to call
		ax, bx, cx, dx possible data		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	8/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIFilterEvents	proc	near
		uses	ds, di, si
		.enter

		MOV_SEG	ds, dgroup

	;
	;	if there is no exclusive access, exAccessID = -1
	;
		cmp	ds:[exAccessID], -1
		je	setEventType

	;
	;	There is exclusive access set, now check the ID.
	;
		cmp	si, ds:[exAccessID]
		je	setEventType

	;
	;	Else disregard events!
	;
done:
		.leave
		ret

setEventType:
		cmp	di, offset keyboardCallbackTable
		jne	tryMouse
		mov	si, SET_KEYBOARD
		jmp	callCallback
		
tryMouse:
		cmp	di, offset pointerCallbackTable
		jne	tryPower
		mov	si, SET_POINTER
		jmp	callCallback
tryPower:
	;
	;	no error checking for now
	;
		mov	si, SET_POWER

callCallback:
		call	GDICallCallbacks
		jmp	done
		
GDIFilterEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIGetExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL
PASS:		si	-> registerID
RETURN:		ax	<- ErrorCode
		carry clear if successful
		carry set if get exclusive rejected
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	8/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIGetExclusive	proc	near
		uses	ds		
		.enter
	;
	;	exAccessID must be -1, that is nobody has yet got
	;	exclusive.
	;
		MOV_SEG	ds, dgroup
		cmp	ds:[exAccessID], -1
		jne	bail

		mov	ds:[exAccessID], si
		clc
		jmp	done
bail:
		stc
done:
		.leave
		ret
GDIGetExclusive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIReleaseExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		si	-> registerID
RETURN:		ax	<- ErrorCode
		carry clear if successful
		carry set if release fails
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	8/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIReleaseExclusive	proc	near
		uses	ds
		.enter
	;		;
	;	exAccessID should be the same as the ID that we want
	;	to release.
	;
		MOV_SEG	ds, dgroup
		cmp	si, ds:[exAccessID]
		jne	error

	;
	;	okay, we can release exclusive
	;
		mov	ds:[exAccessID], -1
		mov	ax, EC_NO_ERROR
		clc
done:
		.leave
		ret

error:
		mov	ax, EC_RELEASE_EXCLUSIVE_ERROR
		stc
		jmp	done
		
GDIReleaseExclusive	endp

CallbackCode		ends

















