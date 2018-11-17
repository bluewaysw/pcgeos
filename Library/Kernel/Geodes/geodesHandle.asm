COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeHandle.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB GeodeForEach		Process the geodes list with a supplied
				callback function

    GLB GeodeFind		Find a GEODE given its name

    INT GF_callback		Find a GEODE given its name

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains routines to handle GEODEs.

	$Id: geodesHandle.asm,v 1.1 97/04/05 01:11:56 newdeal Exp $

-------------------------------------------------------------------------------@

GLoad	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeForEach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the geodes list with a supplied callback function

CALLED BY:	GLOBAL
		GeodeFind
PASS:		bx	= geode from which to start. 0 if entire geodes
			  list is to be traversed
		ax, cx, dx, bp = initial data to pass to callback
		di:si	= virtual far ptr to callback routine

RETURN:		ax, cx, dx, bp = as returned from last call

		If callback forces early termination of processing:
			carry set
			bx	= geode that callback was processing
			si	= next geode after that one (0 if end of list)

		Else:
			carry clear
			bx	= 0
			si	= undefined (is 0, but don't rely upon it.)

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		CALLBACK ROUTINE:
			Pass:	bx	= handle of geode to process
				es	= segment of core block (for kernel-
					  level callback routines) (locked)
				ax, cx, dx, bp = data as passed to GeodeForEach
					  or returned from previous callback
			Return:	carry - set to end processing
				ax, cx, dx, bp = data to send on or return
			Can Destroy: di, si, es, ds

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeForEach	proc	far	uses ds, es
callback	local	fptr.far
		.enter
	;
	; Save the callback's address after verifying its a valid pointer
	;
if ERROR_CHECK

FXIP<		push	bx						>
FXIP<		mov	bx, di						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx						>

endif

		mov	callback.segment, di
		mov	callback.offset, si

	;
	; Snag the geode semaphore for the whole thing.
	;

		call	FarPGeode

	;
	; bx <- handle of first geode to process
	;
		LoadVarSeg	ds
		tst	bx
		jnz	processLoop2	;skip if have starting geode handle...

		mov	si, ds:[geodeListPtr]
					;si = handle of first geode

processLoop:
		mov	bx, si

processLoop2:
	;
	; See if handle (now) zero => done processing
	;
		tst	bx		; (clears carry)
		jz	done
EC <		call	ECCheckGeodeHandle				>
	;
	; Call the callback routine, passing bx containing the geode handle so
	; it can be used to gather info about the geode.
	;
		push	ax
		call	MemLock
		mov	es, ax
		pop	ax

		push	es
AXIP <		push	ds						>

		push	bp
if FULL_EXECUTE_IN_PLACE
		pushdw	callback	;Push the callback function
		mov	bp, ss:[bp]	; recover bp passed to caller
		call	PROCCALLFIXEDORMOVABLE_PASCAL
else
		lea	si, callback	; ss:[si] = callback routine
		mov	bp, ss:[bp]	; recover bp passed to caller
		call	{dword}ss:[si]
endif
		mov	si, bp		; preserve returned bp
		pop	bp		; recover our frame pointer
		mov	ss:[bp], si	; store returned bp for possible
					;  return/next call

AXIP <		pop	ds						>
		pop	es
	;
	; Advance to the next if carry not returned set.
	;
		mov	si, es:[GH_nextGeode]
		call	MemUnlock
EC <		call	NullES						>

;	On XIP systems, where the kernel's coreblock is in fixed read-only
;	memory, and we cannot modify it, the first item in the XIP chain
;	will be bogus if the kernel is the only geode loaded.

AXIP <		pushf							>
AXIP <		tst	ds:[geodeCount]	; if geode count non-zero	>
AXIP <		jnz	doneXIP		; ..then we're OK		>
AXIP <		clr	si		; else next handle is bogus	>
AXIP <doneXIP:								>
AXIP <		popf							>
		jnc	processLoop
done:
	;
	; Release geode semaphore now processing is complete. Note: VGeode
	; doesn't touch the carry flag or any other register.
	; 
		call	FarVGeode
		.leave
		ret
GeodeForEach	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeFind

DESCRIPTION:	Find a GEODE given its name

CALLED BY:	GLOBAL
		UseLibraryLow

PASS:
	es:di - name to match
	ax - number of characters of name to match (8 for match name, 12 for
	     match name and name extension)
	cx - attributes to match
	dx - attributes to NOT match

RETURN:
	carry - set if GEODE found
	bx - handle of GEODE
	cx, dx - unchanged

DESTROYED:
	none

REGISTER/STACK USAGE:
	ds - GEODE on list

PSEUDO CODE/STRATEGY:
	Call GeodeForEach do do the work

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@
GeodeFind	proc	far	uses di, si
matchName	local	fptr.far
	.enter
	mov	matchName.offset, di
	mov	matchName.segment, es
	mov	di, SEGMENT_CS
	mov	si, offset GF_callback
	clr	bx			; Search entire list.
	call	GeodeForEach
	.leave
	ret
GeodeFind	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GF_callback

DESCRIPTION:	Find a GEODE given its name

CALLED BY:	INTERNAL
		GeodeFind via GeodeForEach

PASS:
	stack frame (bp) inherited from caller of GeodeForEach:
		matchName	local	fptr.far	; name to match
		fileType	local	word		; file type to match
							;  (0 to match all)

	ax - number of characters of name to match (8 for match name, 12 for
	     match name and name extension)
	bx - handle of geode being processed
	es - segment of geode's core block
	cx - attributes to match
	dx - attributes to NOT match

RETURN:
	carry - set if GEODE found
	bx - handle of GEODE
	cx, dx - unchanged

DESTROYED:
	may nuke es, ds, di, si

REGISTER/STACK USAGE:
	ds - GEODE on list

PSEUDO CODE/STRATEGY:
	Call FindGeodeLow do do the work

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	Adam	4/89		Added BP parameter
------------------------------------------------------------------------------@
GF_callback	proc	far	uses cx
matchName	local	fptr.far
	.enter	inherit

	;
	; Check the attributes first, since we need to use CX for comparing the
	; names...
	;
	mov	si, es:[GH_geodeAttr]
	test	si, dx		; any undesirables match? (clears carry)
	jnz	noMatch
	not	si
	test	si, cx		; any desired ones missing? (clears carry)
	jnz	noMatch		; at least one was 0 before...

	mov	cx, ax		; cx = # chars to check (carry already clear)
	mov	di, offset GH_geodeName
	lds	si, matchName
	repe	cmpsb
	clc
	jne	noMatch
	stc			; signal match (stop processing)
noMatch:
	.leave			; undo stack frame
	ret
GF_callback	endp

GLoad	ends
