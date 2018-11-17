COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		utilsCode.asm

AUTHOR:		Adam de Boor, May 24, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/24/94		Initial revision


DESCRIPTION:
	General non-resident utility routines
		

	$Id: utilsCode.asm,v 1.1 97/04/05 01:19:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilCode	segment	resource
UtilCodeDerefGen	proc	near
	class	GenClass
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
UtilCodeDerefGen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilDuplicateChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a copy of a chunk, right down to its ObjChunkFlags

CALLED BY:	(EXTERNAL)
PASS:		*ds:ax	= chunk to duplicate
RETURN:		*ds:ax	= new chunk
DESTROYED:	nothing
SIDE EFFECTS:	block/chunks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilDuplicateChunk proc	far
		uses	bx, cx, si, di
		.enter
	;
	; Figure the ObjChunkFlags to use in the allocation.
	; 
		mov	bx, ax
		test	ds:[LMBH_flags], mask LMF_HAS_FLAGS
		jz	getSize
		call	ObjGetFlags
getSize:
	;
	; Find the size of the source chunk and allocate the same amount.
	; 
		ChunkSizeHandle ds, bx, cx
		call	LMemAlloc	; *ds:ax <- new chunk
	;
	; Copy the data from the source to the dest chunk.
	; 
		push	es		; save here so it gets properly fixed
					;  up if == ds
		segmov	es, ds
		mov	si, ds:[bx]	; ds:si <- source
		mov	di, ax
		mov	di, ds:[di]	; es:di <- dest, of course
		shr	cx
		rep	movsw
		jnc	done
		movsb
done:
		pop	es
		.leave
		ret
UtilDuplicateChunk endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilSetMonikerFromTemplate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the moniker for the passed object with one generated
		from a template and the passed string.

CALLED BY:	(EXTERNAL) MDSetMessage
PASS:		*ds:si	= object to affect
		*ds:ax	= template moniker
		*ds:bx	= string with which to replace \1 in the template
RETURN:		ds	= fixed up
DESTROYED:	ax, di
SIDE EFFECTS:	previous moniker for the object is freed
		object's geometry and image will update after a queue delay

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilSetMonikerFromTemplate	proc	far
		class	GenClass
		Assert	chunk, ax, ds
		Assert	chunk, bx, ds
		Assert	objectPtr, dssi, GenClass

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		xchg	ds:[di].GI_visMoniker, ax
		tst	ax
		jz	mangleAction
		call	LMemFree		; free old moniker
mangleAction:
	;
	; Change the moniker of the object appropriately.
	; 
		mov	ax, bx			; *ds:ax <- verb
		FALL_THRU	UtilMangleCopyOfMoniker
UtilSetMonikerFromTemplate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilMangleCopyOfMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a copy of an object's moniker and use UtilMangleMoniker
		to adjust it, returning the copy as the object's moniker.

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= generic object
		*ds:ax	= string to replace the \1 in the current moniker
RETURN:		ds	= fixed up
		GI_visMoniker = replaced with handle of duplicate
DESTROYED:	nothing
SIDE EFFECTS:	object's geometry and image will update after a queue delay

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilMangleCopyOfMoniker proc	far
		uses	ax, di
		class	GenClass
		.enter
		Assert	objectPtr, dssi, GenClass
	;
	; Make a copy of the moniker.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].GI_visMoniker
		call	UtilDuplicateChunk
	;
	; Store its chunk back in.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].GI_visMoniker, ax
		.leave
		FALL_THRU	UtilMangleMoniker
UtilMangleCopyOfMoniker endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilMangleMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the \1 in the given generic object's moniker with
		the given string.

CALLED BY:	(EXTERNAL) OPSetMoniker, OSCSetMessage, OCPMcpSetCriteria
PASS:		*ds:si	= generic object
		*ds:ax	= string to replace the \1 in the current moniker
RETURN:		ds	= fixed up
DESTROYED:	es (if == ds on entry)
SIDE EFFECTS:	object's geometry and image will update after a queue delay

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilMangleMoniker proc	far
		uses	di, dx, cx, bx, bp, ax, es
		class	GenClass
		.enter
		Assert	objectPtr, dssi, GenClass


	;
	; *ds:ax is the transport string. Using the chunk handle, compute the
	; number of bytes we'll insert in place of the \1 char. We reduce the
	; chunk size by 2 chars because the null char won't be copied, and
	; we're replacing the \1 char.
	;
	; The result is left in DX
	; 
		push	ax
		mov_tr	di, ax
		ChunkSizeHandle	ds, di, dx
DBCS <		sub	dx, 4						>
SBCS <		dec	dx						>
SBCS <		dec	dx						>
	;
	; Deref our moniker.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GI_visMoniker
		mov	di, ds:[bx]
EC <		test	ds:[di].VM_type, mask VMT_GSTRING		>
EC <		ERROR_NZ MONIKER_MUST_BE_TEXT				>
		mov	ds:[di].VM_width, 0	; nuke any cached width,
						;  as we're about to invalidate
						;  it
	;
	; Compute the length of the text string, setting CX to the number of
	; characters and ES:DI to the first character.
	; 
		segmov	es, ds
		ChunkSizePtr	ds, di, cx
		sub	cx, offset VM_data.VMT_text
		add	di, offset VM_data.VMT_text
DBCS <		shr	cx						>
	;
	; Look for a \1 character within the moniker text, as the place holder
	; for the string.
	; 
		mov	ax, '\1'
		LocalFindChar
EC <		ERROR_NE MONIKER_MISSING_STRING_PLACEHOLDER		>
	;
	; Found it. Point back to the \1 and compute its offset within the
	; moniker and insert enough bytes at that offset to hold the string,
	; overwriting the \1.
	; 
		LocalPrevChar	esdi
		sub	di, ds:[bx]		; di <- offset w/in moniker
		mov_tr	ax, di			; (mov_tr+xchg used b/c it
						;  requires only 2 bytes, not 4)
	    ;
	    ; Adjust any mnemonic offset to keep it on the char it was on when
	    ; the moniker was defined.
	    ; 
			CheckHack <VMO_CANCEL lt VMO_MNEMONIC_NOT_IN_MKR_TEXT>
			CheckHack <VMO_CANCEL lt VMO_NO_MNEMONIC>

		mov	di, ds:[bx]
		cmp	({VisMonikerText}ds:[di].VM_data).VMT_mnemonicOffset, \
							VMO_CANCEL
		jae	insert			; jump if special cases
		sub	ax, offset VM_data.VMT_text	; ax = offset within
							;  text string
DBCS <		shr	ax			; ax = char offset	>
		cmp	al, ({VisMonikerText}ds:[di].VM_data).VMT_mnemonicOffset
		jae	mnemonicOK		; jump if mnemonic at or before
						;  insert point
DBCS <		shr	dx			; dx = # chars		>
		add	({VisMonikerText}ds:[di].VM_data).VMT_mnemonicOffset, dl
EC <		ERROR_C	MONIKER_TOO_LONG				>
EC <		cmp	({VisMonikerText}ds:[di].VM_data).VMT_mnemonicOffset, \
							VMO_CANCEL>
EC <		ERROR_AE	MONIKER_TOO_LONG			>
DBCS <		shl	dx			; dx = # bytes		>
mnemonicOK:
DBCS <		shl	ax			; ax = byte offset	>
		add	ax, offset VM_data.VMT_text	; ax = offset within
							; chunk
insert:
		xchg	ax, bx			; ax <- chunk, bx <- ins. offset
		mov	cx, dx			; cx <- # bytes to insert
		call	LMemInsertAt
	;
	; Point es:di back at the \1 in the moniker.
	; 
		xchg	ax, bx
		mov_tr	di, ax
		add	di, ds:[bx]
	;
	; Copy the string in there, sans null character
	; 
		pop	ax
		push	si
		mov	si, ax
		mov	si, ds:[si]
		inc	cx			; adjust size up one char to
						;  account for \1 being nuked
DBCS <		inc	cx						>
		rep	movsb
		pop	si
	;
	; Set the moniker using GEN_USE_VIS_MONIKER, after zeroing GI_visMoniker
	; (so the method doesn't think this is a NOP), to make sure the geometry
	; and image updates happen properly.
	; 
		DerefDI	Gen
		clr	cx
		xchg	ds:[di].GI_visMoniker, cx
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		call	ObjCallInstanceNoLock
		.leave
		ret
UtilMangleMoniker endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilReplaceFirstMarkerInTextChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to replace a \1 marker in the text chunk
		of a text object with the null-terminated text in a chunk
		pointed to by an optr

CALLED BY:	(EXTERNAL) OSCSetMessage
PASS:		*ds:si	= GenText object
		^lcx:dx	= string to store
RETURN:		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilReplaceFirstMarkerInTextChunk proc far
		uses	ax
		.enter
		mov	ax, '\1'
		call	UtilReplaceMarkerInTextChunk
		.leave
		ret
UtilReplaceFirstMarkerInTextChunk endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilReplaceMarkerInTextChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to replace a marker in the text chunk
		of a text object with the null-terminated text in a chunk
		pointed to by an optr

CALLED BY:	(EXTERNAL) OSCSetMessage
PASS:		*ds:si	= GenText object
		^lcx:dx	= string to store
		ax	= marker to look for ('\1', '\2', '\3' etc)
RETURN:		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilReplaceMarkerInTextChunk proc	far
		uses	es, di, cx, dx, bx, ax, bp
		.enter
SBCS <		Assert	e, ah, 0					>
		Assert	objectPtr, dssi, GenTextClass
	;
	; Look for the \1 in the text chunk of the template text object
	; 
		push	cx, si
		call	UCFindMarkerCommon
EC <		ERROR_NZ TEXT_TEMPLATE_MISSING_PLACEHOLDER	>
	;
	; Compute the position of that character so we can replace it.
	; 
   		LocalPrevChar	esdi
		sub	di, ds:[si]
DBCS <		shr	di						>
		
		pop	cx, si			; ^lcx:dx <- replacement string
						; *ds:si <- text object
		sub	sp, size VisTextReplaceParameters
	;
	; Set the start and end position of the replace to be just the \1
	; character we found.
	; 
		mov	bp, sp
		mov	ss:[bp].VTRP_range.VTR_start.low, di
		mov	ss:[bp].VTRP_range.VTR_start.high, 0
		inc	di
		mov	ss:[bp].VTRP_range.VTR_end.low, di
		mov	ss:[bp].VTRP_range.VTR_end.high, 0
	;
	; Ask the text object to figure the number of chars in the string.
	; 
		mov	ss:[bp].VTRP_insCount.low, 0
		mov	ss:[bp].VTRP_insCount.high, INSERT_COMPUTE_TEXT_LENGTH
	;
	; Tell it where the string is (optr reference type)
	; 
		mov	ss:[bp].VTRP_textReference.TR_type, TRT_OPTR
		movdw	ss:[bp].VTRP_textReference.TR_ref.TRU_blockChunk.TRBC_ref, \
			cxdx
	;
	; No special flags.
	; 
		mov	ss:[bp].VTRP_flags, 0
	;
	; Perform the replacement.
	; 
		mov	dx, size VisTextReplaceParameters
		mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
		call	ObjCallInstanceNoLock
		add	sp, size VisTextReplaceParameters
		.leave
		ret
UtilReplaceMarkerInTextChunk endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCheckIfMarkerExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to check if a marker exists in the text chunk
		of a text object

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= GenText object
		ax	= marker to look for ('\1', '\2', '\3' etc)
RETURN:		ZF set if marker exists
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCheckIfMarkerExists	proc	far
	uses	si, di, es
	.enter

	call	UCFindMarkerCommon

	.leave
	ret
UtilCheckIfMarkerExists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UCFindMarkerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to locate a marker in the text chunk of a text
		object

CALLED BY:	(INTERNAL) UtilReplaceMarkerInTextChunk,
			   UtilCheckIfMarkerExists
PASS:		*ds:si	= GenText object
		ax	= marker to look for ('\1', '\2', '\3' etc)
RETURN:		*ds:si	= text chunk
		es	= ds
		ZF set if marker exists
			es:di	= char after marker
		ZF clear otherwise
			di destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/10/96    	Initial version (extracted from
				UtilReplaceMarkerInTextChunk)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UCFindMarkerCommon	proc	near
		uses	cx
		class	GenTextClass
		.enter

		segmov	es, ds
		mov	si, ds:[si]
		add	si, ds:[si].GenText_offset
		mov	si, ds:[si].GTXI_text

		Assert	chunk, si, ds

		mov	di, ds:[si]
		ChunkSizePtr	ds, di, cx
DBCS <		shr	cx						>
		LocalFindChar

		.leave
		ret
UCFindMarkerCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilReplaceFirstMarkerInStringChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to replace a \1 marker in the string chunk
		with the null-terminated string in a chunk pointed to by an
		optr.

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= string containing the marker
		^lcx:dx	= string to replace
RETURN:		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0	; nobody currently uses it.
UtilReplaceFirstMarkerInStringChunk	proc	far
	uses	ax, bx, cx, si, di, es
	.enter

	;
	; Compute the number of bytes we'll insert in place of the \1 char.
	; We reduce the chunk size by 2 chars because the null char won't be
	; copied, and we're replacing the \1 char.
	;
	mov	bx, cx
	call	ObjLockObjBlock
	mov	es, ax
	ChunkSizeHandle	es, dx, cx
	Assert	ae, cx, <2 * size TCHAR>
SBCS <	dec	cx							>
SBCS <	dec	cx			; cx = # bytes to insert	>
DBCS <	sub	cx, 2 * size wchar					>
	push	bx			; save hptr for re-deref

	;
	; Resize original string.
	;
	push	cx			; save # bytes to insert
	segmov	es, ds
	mov	di, ds:[si]
	call	LocalStringLength
	LocalLoadChar	ax, '\1'
	LocalFindChar
EC <	ERROR_NZ STRING_TEMPLATE_MISSING_PLACEHOLDER			>
	sub	di, ds:[si]
	mov	bx, di			; insert after marker
	dec	di			; di = offset of marker
DBCS <	dec	di							>
	mov	ax, si
	pop	cx			; cx = # bytes to insert
	push	ds:[LMBH_flags]
	BitClr	ds:[LMBH_flags], LMF_RETURN_ERRORS
	call	LMemInsertAt
	pop	ds:[LMBH_flags]

	;
	; Replace the marker.
	;
	add	di, ds:[si]		; es:di = marker
	call	MemDerefStackDS		; *ds:dx = replacing string
	mov	si, dx
	mov	si, ds:[si]
	inc	cx			; cx = # bytes to copy
DBCS <	inc	cx							>
	rep	movsb

	call	UtilUnlockDS

	.leave
	ret
UtilReplaceFirstMarkerInStringChunk	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilFormatDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a FileDate + FileTime into a newly-allocated lmem chunk

CALLED BY:	(EXTERNAL)
PASS:		bx	= FileTime
		ax	= FileDate
		cx	= UtilFormatDateTimeFormat
		ds	= lmem block in which to place the result
RETURN:		*ds:ax	= resulting string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilFormatDateTime proc	far
		uses	si, di, cx
		.enter
	;
	; Error-check the arguments as much as possible.
	; 
		Assert	etype, cx, UtilFormatDateTimeFormat
		Assert	lmem, ds:[LMBH_handle]
	;
	; Allocate room for two maximally-sized dates/times + the biggest
	; separator string we allow to go between the two.
	; 
		push	ax, cx
		mov	cx, 2*DATE_TIME_BUFFER_SIZE + MAILBOX_MAX_DATE_SEPARATOR * size TCHAR
		clr	ax
		call	LMemAlloc
		mov_tr	si, ax
		pop	ax, cx
	;
	; Point es:di to the buffer for the duration.
	; 
		push	es, si
		segmov	es, ds
		mov	di, ds:[si]
		
	;
	; If the timestamp is now/forever, produce a special string.
	; 
			CheckHack <MAILBOX_NOW eq 0>
		mov	si, bx
		or	si, ax
		mov	si, offset uiNow
		jz	isSpecial	; jump if MAILBOX_NOW
		cmpdw	bxax, MAILBOX_ETERNITY
		mov	si, offset uiEternity
		je	isSpecial
	;
	; Figure the format to use based on what we received in CX.
	; 
		cmp	cx, UFDTF_SEND
		mov	si, offset uiSend
		je	doSend

		cmp	cx, UFDTF_RETRY
		jne	doDate
	;
	; Use Retry instead of date, then use short form for the rest.
	;
doRetry::
		mov	si, offset uiRetry
doSend:
		push	ax
		call	copyStaticString
		pop	ax
		mov	cx, UFDTF_SHORT_FORM
		jmp	dateDone

doDate:
		CheckHack <UFDTF_SHORT_FORM eq 0>
		mov	si, DTF_MD_SHORT
		jcxz	haveDateFormat
		mov	si, DTF_LONG_NO_WEEKDAY
haveDateFormat:
	;
	; Format the thing and advance beyond the result.
	; 
		push	cx
		call	LocalFormatFileDateTime
DBCS <		shl	cx		; cx = # of bytes		>
		add	di, cx
		pop	cx

dateDone:
	;
	; Figure the separator to use.
	; 
		mov	si, offset uiShortDateSeparator
		jcxz	haveSeparator
		mov	si, offset uiLongDateSeparator
haveSeparator:
	;
	; Lock down our string block and copy the separator string in,
	; minus the null terminator.
	; 
		push	ax, cx
		call	copyStaticString
		pop	ax, cx
	;
	; The time always appears the same, regardless of whether we're doing
	; long- or short-form.
	;
	; 11/14/94: on tiny systems, use 24-hour time for short form -- ardeb
	; 
		segmov	ds, dgroup, si
		assume	ds:dgroup
		mov	si, DTF_HM
			CheckHack <DS_TINY eq 0>
		test	ds:[uiDisplayType], mask DT_DISP_SIZE
		jnz	haveTimeFormat
		jcxz	switchTo24Hour
haveTimeFormat:
		call	LocalFormatFileDateTime
done:
		segmov	ds, es		; return DS fixed up, please
		assume	ds:nothing
		pop	es, ax		; restore ES, *ds:ax <- result string
		.leave
		ret

switchTo24Hour:
		mov	si, DTF_HM_24HOUR
		jmp	haveTimeFormat

isSpecial:
	;
	; The timestamp is for now/eternity, so copy that string in instead.
	; 
		cmp	cx, UFDTF_RETRY
		jne	doNowOrForever
	;
	; Retry with time eternity means message sent only on request,
	; else it is waiting for medium to become available.
	;
		cmp	si, offset uiEternity
		mov	si, offset uiUponRequest
		je	doNowOrForever
		mov	si, offset uiWaitingString

doNowOrForever:
		call	copyStaticString
		jmp	done

	;--------------------
	; Copy a string from ROStrings into our buffer.
	;
	; Pass:
	; 	si	= chunk handle of string to copy
	; 	es:di	= buffer
	; Return:
	; 	es:di	= pointing to null char
	; Destroyed:
	; 	ax, ds, cx, si
copyStaticString:
		push	bx
		mov	bx, handle ROStrings
		call	MemLock
		mov	ds, ax
		assume	ds:segment ROStrings

		mov	si, ds:[si]
		ChunkSizePtr ds, si, cx
		rep	movsb

		LocalPrevChar	esdi

		call	MemUnlock
		assume	ds:nothing
		pop	bx
		retn
UtilFormatDateTime endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilRegisterFileChangeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange for a callback routine to be called whenever there's
		a change in the filesystem.

CALLED BY:	(EXTERNAL)
PASS:		ax	= callback data
		cx:dx	= vfptr of routine to call:
			  Pass:
				ax	= callback data
				dx	= FileChangeNotificationType (never
					  FCNT_BATCH)
				es:di	= FileChangeNotificationData
			  Return:
			  	nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none here

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilRegisterFileChangeCallback proc	far
		uses	bp, ax
		.enter
		Assert	vfptr, cxdx
		mov_tr	bp, ax
		mov	ax, MSG_MA_REGISTER_FILE_CHANGE
		call	UtilSendToMailboxApp
		.leave
		ret
UtilRegisterFileChangeCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetFutureFileDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a FileDate & FileTime record for some time in the
		future by extending the current date & time by an amount.

CALLED BY:	(EXTERNAL)
PASS:		cl	= # minutes extension
		ch	= # hours extension
RETURN:		dx	= FileTime
		ax	= FileDate
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetFutureFileDateTime proc	far
		uses	bx, si
		.enter
		Assert	b, cl, 60
		Assert	b, ch, (254-23-1); can't handle carry out of hour
					 ;  addition (ch might be adjusted up
					 ;  1 if minutes overflow, so...)

		mov	si, cx		; save extension...
	;
	; Fetch "now"
	; 
		call	TimerGetDateAndTime
	;
	; Adjust the minutes by the requested amount.
	; 
		xchg	cx, si		; cl <- minute extension, preserve
					;  "now" hours (ch)
		add	dl, cl
		cmp	dl, 60		; over an hour?
		jb	adjustHours	; => no
		inc	ch		; another hour to adjust
		sub	dl, 60

adjustHours:
	;
	; Adjust the hours by the requested amount.
	; 
		xchg	cx, si		; cl <- weekday, ch <- hours
		xchg	dx, si		; dh <- hour adjustment
		add	ch, dh

		cmp	ch, 24		; gone into the next day (or beyond)?
		jb	formFDAT	; => no
	;
	; We've gone beyond a day, so we now have to up the day of the month
	; accordingly.
	; 
normalizeHourLoop:
		sub	ch, 24
		jb	hoursNormal
		
		inc	bh		; advance to next day. we'll normalize
					;  this in a moment
		jmp	normalizeHourLoop

hoursNormal:
		add	ch, 24		; get hours back into the day
		
	;
	; Now cope with possibly having wrapped into the next month. Note that
	; with the restriction of approx. 10 days max adjustment in the hours,
	; we don't have to loop here, as we don't have any months of < 10 days
	; 
		push	cx		; save hours
		call	LocalCalcDaysInMonth	; ch <- actual # days in current
						;  month (bl, ax)
		cmp	ch, bh
		jae	dayNormal	; => still within the current month
		
		sub	bh, ch		; wrap to next month's day
		inc	bl		; advance month
		cmp	bl, 12		; gone into the next year?
		jbe	dayNormal	; no

		mov	bl, 1		; january here we come...
		inc	ax		; in the new year, no less
dayNormal:
		pop	cx		; ch <- hours
formFDAT:
		mov	dx, si		; dl <- minutes, dh <- seconds
	;
	; Create the FileDate record first, as we need to use CL to the end...
	; 
		sub	ax, 1980	; convert to fit in FD_YEAR
			CheckHack <offset FD_YEAR eq 9>
		mov	ah, al
		shl	ah		; shift year into FD_YEAR
		mov	al, bh		; install FD_DAY in low 5 bits
		
		mov	cl, offset FD_MONTH
		clr	bh
		shl	bx, cl		; shift month into place
		or	ax, bx		; and merge it into the record
		xchg	dx, ax		; dx <- FileDate, al <- minutes,
					;  ah <- seconds
		xchg	al, ah
	;
	; Now for FileTime. Need seconds/2 and both AH and AL contain important
	; stuff, so we can't just sacrifice one. The seconds live in b<0:5> of
	; AL (minutes are in b<0:5> of AH), so left-justify them in AL and
	; shift the whole thing enough to put the MSB of FT_2SEC in the right
	; place, which will divide the seconds by 2 at the same time.
	; 
		shl	al
		shl	al		; seconds now left justified
		mov	cl, (8 - width FT_2SEC)
		shr	ax, cl		; slam them into place, putting 0 bits
					;  in the high part
	;
	; Similar situation for FT_HOUR as we need to left-justify the thing
	; in CH, so just shift it up and merge the whole thing.
	; 
		CheckHack <(8 - width FT_2SEC) eq (8 - width FT_HOUR)>
		shl	ch, cl
		or	ah, ch
		xchg	dx, ax		; ax <- date, dx <- time
					;  (corresponds to C FileDateAndTime
					;  declaration, ya know)
		.leave
		ret
UtilGetFutureFileDateTime endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilSendToMailboxApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the mailbox application object. message
		is not force-queued nor are any segments fixed up

CALLED BY:	(EXTERNAL)
PASS:		ax	= message
		cx, dx, bp = message data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilSendToMailboxApp proc	far
		uses	bx, si, di
		.enter
		mov	bx, handle MailboxApp
		mov	si, offset MailboxApp
		clr	di
		call	ObjMessage
		.leave
		ret
UtilSendToMailboxApp endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCallMailboxApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a method in the mailbox application object.

CALLED BY:	(EXTERNAL)
PASS:		ax	= message
		cx, dx, bp = message data
		di	= MessageFlags to use (MF_CALL will be set by this
			  routine)
RETURN:		di	= MessageError
		ax, cx, dx, bp returned by message called
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCallMailboxApp proc	far
		uses	bx, si
		.enter
		mov	bx, handle MailboxApp
		mov	si, offset MailboxApp
		ornf	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
UtilCallMailboxApp endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilForceQueueMailboxApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force-queue a message to the mailbox application object.

CALLED BY:	(EXTERNAL)
PASS:		ax	= message
		cx, dx, bp = message data
		di	= MessageFlags to use (MF_FORCE_QUEUE will be set by
			  this routine)
RETURN:		di	= MessageError
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilForceQueueMailboxApp proc	far
		uses	bx, si
		.enter
		mov	bx, handle MailboxApp
		mov	si, offset MailboxApp
		ornf	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret
UtilForceQueueMailboxApp endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilAddToMailboxGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an object to a GCN list on the mailbox application object

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= object to add
		ax	= MailboxGCNListType to which to add it
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilAddToMailboxGCNList proc	far
		push	di, bx
		mov	bx, MSG_META_GCN_LIST_ADD
		clr	di
		GOTO_ECN	UCAddRemoveGCNListCommon, bx, di
UtilAddToMailboxGCNList endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilAddToMailboxGCNListSync
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an object to a GCN list on the mailbox application object,
		waiting for that addition to complete before returning

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= object to add
		ax	= MailboxGCNListType to which to add it
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilAddToMailboxGCNListSync proc	far
		push	di, bx
		mov	bx, MSG_META_GCN_LIST_ADD
		mov	di, mask MF_CALL
		GOTO_ECN	UCAddRemoveGCNListCommon, bx, di
UtilAddToMailboxGCNListSync endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilRemoveFromMailboxGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an object from a GCN list on the mailbox application 
		object

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= object to remove
		ax	= MailboxGCNListType from which to remove it
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilRemoveFromMailboxGCNList proc	far
		push	di, bx
		mov	bx, MSG_MA_GCN_LIST_REMOVE
		clr	di
		GOTO_ECN	UCAddRemoveGCNListCommon, bx, di
UtilRemoveFromMailboxGCNList endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilRemoveFromMailboxGCNListSync
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an object from a GCN list on the mailbox application 
		object and wait for it to be removed

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= object to remove
		ax	= MailboxGCNListType from which to remove it
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilRemoveFromMailboxGCNListSync proc	far
		push	di, bx
		mov	bx, MSG_MA_GCN_LIST_REMOVE
		mov	di, mask MF_CALL
		FALL_THRU_ECN	UCAddRemoveGCNListCommon, bx, di
UtilRemoveFromMailboxGCNListSync endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UCAddRemoveGCNListCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the mailbox application object to add or
		remove the given object from the given GCN list

CALLED BY:	(INTERNAL) UtilAddToMailboxGCNList,
			   UtilRemoveFromMailboxGCNList
PASS:		*ds:si	= object to add/remove
		ax	= MailboxGCNListType to/from which to add/remove
		bx	= message to send to the app object
			  (MSG_META_GCN_LIST_ADD/MSG_META_GCN_LIST_REMOVE)
		di	= mask MF_CALL or 0

		saved on stack (to be popped by us in non-ec):
		sp ->	bx
			di
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	as expected

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UCAddRemoveGCNListCommon proc	ecnear
		uses	ax, cx, dx, si, bp
		.enter
	;
	; Set up the MAGCNListParams for the message.
	; 
		push	bx
		mov	bx, ds:[LMBH_handle]
		push	bx			; push the optr handle while
						;  we've got it
		call	MemOwner
		mov	bp, sp
			CheckHack <MAGCNLP_owner eq MAGCNListParams-2>
		xchg	ss:[bp+2], bx		; bx <- message, set
						;  MAGCNLP_owner

		CheckHack <GCNLP_optr eq MAGCNListParams-6>
		push	si
		CheckHack <GCNLP_ID eq MAGCNListParams-10>
		mov	cx, MANUFACTURER_ID_GEOWORKS
		push	ax, cx
	;
	; Send the message to the app object.
	; 
		mov	bp, sp			; ss:bp <- params
		mov	dx, size MAGCNListParams; dx <- param size
		cmp	bx, MSG_MA_GCN_LIST_REMOVE
		je	haveParamSize
		mov	dx, size GCNListParams
haveParamSize:
	;
	; MF_CALL is not an option here, as we get called on the main ui
	; thread, which isn't allowed to call.
	;
	; MF_INSERT_AT_FRONT is not an option here, as quick-succession
	; add/remove sequences (as happen when an outbox control panel is
	; brought up for some medium for which there are no messages pending)
	; then get handled out of order, resulting in bad ODs being left on
	; the outbox_change list.
	;
		mov_tr	ax, bx			; ax <- msg
		ornf	di, mask MF_STACK or mask MF_FIXUP_DS
		mov	bx, handle MailboxApp
		mov	si, offset MailboxApp
		call	ObjMessage
	;
	; Clear the stack
	; 
		add	sp, size MAGCNListParams
		.leave
	;
	; Pop the bx saved by the caller.
	; 
		FALL_THRU_POP	bx, di
		ret
UCAddRemoveGCNListCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilLoadTransportDriverWithError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to load a transport driver, letting the user know
		if we can't

CALLED BY:	(EXTERNAL) OTrMain
PASS:		cxdx	= MailboxTransport of driver to load
RETURN:		carry set if couldn't load:
			ax	= GeodeLoadError
			bx	= destroyed
		carry clear if loaded:
			ax	= destroyed
			bx	= driver handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilLoadTransportDriverWithError proc	far
		.enter
		call	MailboxLoadTransportDriver
		.leave
		ret
UtilLoadTransportDriverWithError endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilLocateFilenameInPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the name of a file at the end of a pathname

CALLED BY:	(EXTERNAL)
PASS:		es:di	= pathname to scan (null-terminated)
RETURN:		es:di	= filename at the end of pathname (es unchanged)
		cx	= size of filename (including null)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Find the character after the last backslash in the string.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilLocateFilenameInPathname	proc	far
	uses	ax
	.enter

	Assert	fptr, esdi

	LocalStrLength	includeNull	;es:di = char after null
	push	di			; save offset of char after null
	LocalPrevChar	esdi		; es:di = C_NULL
	mov	ax, C_BACKSLASH
	std
	LocalFindChar			; es:di = char before last backslash
	cld
	jne	noBackslash
	LocalNextChar	esdi		; es:di = last backslash

noBackslash:
	LocalNextChar	esdi		; es:di = filename
	pop	cx
	sub	cx, di			; cx = size incl. null

	Assert	fptr, esdi

	.leave
	ret
UtilLocateFilenameInPathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilInteractionComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to bring the dialog box down *after* having performed
		whatever action was being performed. We cannot use the
		GA_SIGNAL_INTERACTION_COMPLETE attribute because that causes
		the box to come down *before* the action, meaning we release
		our message and have nothing with which to work. Alas.

CALLED BY:	(EXTERNAL) ODSendMessage, ODDeleteMessage
PASS:		*ds:si	= GenInteraction object
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilInteractionComplete	proc	far
		uses	bp
		.enter
	;
	; Bring the dialog box down, please.
	; 
		mov	cx, IC_INTERACTION_COMPLETE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjCallInstanceNoLock
		.leave
		ret
UtilInteractionComplete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCreateDialogFixupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call UserCreateDialog and make sure DS is fixed up on return

CALLED BY:	(EXTERNAL)
PASS:		^lbx:si	= root of dialog to duplicate
		ds	= fixup-able segment
RETURN:		^lbx:si	= duplicated dialog
		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCreateDialogFixupDS proc	far
		uses	ax
		.enter
		push	ds:[LMBH_handle]
		call	UserCreateDialog
		mov_tr	ax, bx
		pop	bx
		call	MemDerefDS
		mov_tr	bx, ax
		.leave
		ret
UtilCreateDialogFixupDS endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCopyChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the chunk pointed to by ^lbx:si into the lmem block
		pointed to by ds.

CALLED BY:	(EXTERNAL) MTCopyMonikerList, MTCopyVerb
PASS:		ds	= destination block
		^lbx:si	= chunk to copy
RETURN:		*ds:si	= duplicate
		es	= fixed up, if same as DS on entry
DESTROYED:	nothing
SIDE EFFECTS:	DS and chunks within it may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCopyChunk	proc	far
		uses	cx
		.enter
		clr	cx
		call	UtilCopyChunkWithHeader
		.leave
		ret
UtilCopyChunk	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCopyChunkWithHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the chunk pointed to by ^lbx:si into the lmem block
		pointed to by ds, leaving room for a cx-byte header at
		the start of the destination chunk

CALLED BY:	(EXTERNAL)
PASS:		ds	= destination block
		^lbx:si	= chunk to copy
		cx	= header size (may be 0)
RETURN:		*ds:si	= duplicate
		es	= fixed up, if same as DS on entry
DESTROYED:	nothing
SIDE EFFECTS:	DS and chunks within it may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCopyChunkWithHeader	proc	far
		uses	cx, di, ax, dx
		.enter
EC <		call	ECLMemValidateHeap				>
EC <		call	ECCheckLMemHandle				>
	;
	; Lock down the source block, but put its segment into ES, since we
	; need DS for the allocation.
	; 
		mov	dx, es		; preserve ES
		call	ObjLockObjBlock		; use this instead of MemLock
						;  to (a) make sure we're on
						;  the right thread if it is
						;  an object block, and (b)
						;  avoid getting incorrect
						;  warnings if the block is
						;  an object block run by this
						;  thread.
		mov	es, ax
EC <		push	ds						>
EC <		mov	ds, ax						>
EC <		call	ECLMemValidateHandle				>
EC <		pop	ds						>
	;
	; Figure the size of the source chunk and allocate a like-sized chunk.
	; 
		mov	di, cx			; remember header size
		ChunkSizeHandle	es, si, cx
		add	cx, di
		mov	es, dx			; allow passed-in ES to be
						;  fixed up, if necessary
		clr	al
		call	LMemAlloc			;ax = handle of chunk
		mov	dx, es
		call	MemDerefES		; re-deref, in case src blk is
						;  the same as dest blk
	;
	; Deref both chunks, swapping ES and DS for the move
	; 
		sub	cx, di			; cx <- # bytes to move
		mov	bx, ax
		add	di, ds:[bx]		; di <- past header
		segxchg	ds, es
		mov	si, ds:[si]		; ds:si <- src data
	;
	; Move words (both pointers should be aligned...), with final byte,
	; if necessary.
	; 
		shr	cx
		rep	movsw
		jnc	done
		movsb
done:
		mov	bx, ds:[LMBH_handle]	; bx <- source block, again
		mov_tr	si, ax
		segmov	ds, es			; *ds:si <- result
		call	MemUnlock		; release source block
		mov	es, dx			; return passed-in ES
EC <		call	ECLMemValidateHeap				>
		.leave
		ret
UtilCopyChunkWithHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilNewDataDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the driver has a custom error string and register
		it if so.

CALLED BY:	(EXTERNAL) DMap module
PASS:		ds:si	= driver name
		cxdx	= MailboxStorage token
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds all allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilNewDataDriver proc	far
		.enter
	;
	; Get the driver's attributes to see if the thing has an error string
	; for us to use.
	;
		call	AdminGetDataDriverMap
		push	ax
		call	DMapGetAttributes
		test	ax, mask MBDC_CUSTOM_ERROR_STRING
		pop	ax
		jz	done
	;
	; It does. Attempt to load the driver.
	;
		call	DMapLoad
		jc	done			; couldn't load. In theory, we
						;  should register a load
						;  callback to get the string,
						;  but that would still leave
						;  us without the string should
						;  the next load fail. I dunno.
		
	;
	; Call the driver, thanks.
	;
		push	ds, cx, dx
		call	GeodeInfoDriver		; ds:si <- DriverInfoStruct
		mov	di, DR_MBDD_GET_CUSTOM_ERROR_STRING
		call	ds:[si].DIS_strategy	; ^lcx:dx <- error string
	;
	; Call the DMap module to store the string.
	;
		movdw	bxsi, cxdx
		pop	ds, cx, dx
		call	DMapStoreErrorMsg
	;
	; Unload the driver.
	;
		call	DMapUnload
done:
		.leave
		ret
UtilNewDataDriver endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilChangeClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the class of an object in preparation for removing
		a reference to a geode that may cause the object's current
		class to go away.

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= object to change
		es:di	= ancestor class to which to change it
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	object may shrink as data for the subclass are deleted

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilChangeClass	proc	far
		uses	ax, bx
		.enter
EC <		call	ObjIsObjectInClass				>
EC <		ERROR_NC CANNOT_CHANGE_TO_NON_ANCESTOR_CLASS		>
	;
	; avoid death when ObjCallSuperNoLock checks our object class
	; and finds that the block to which our class pointer points is
	; gone... we know it's gone and heartily approve of it. first shrink
	; the master part to be the size of our master part (not our subclass's)
	; and then adjust our object class.
	;
	; In the non-ec this ensures that there is no window of vulnerability
	; where the block that used to hold the class pointer might get
	; overwritten and throw off vardata searches, etc.
	;
	; XXX: in theory, if Class_masterOffset is 0 we should just perform
	; the necessary LMemDeleteAt based on the passed class's instanceSize
	; and the object's current instance size, or something. In practice,
	; we don't do anything nearly so fancy, as we only ever use this for
	; stuff with a non-zero master offset.
	; 
		mov	ax, es:[di].Class_instanceSize
		mov	bx, es:[di].Class_masterOffset

EC <		push	di, es						>
EC <		mov	di, ds:[si]					>
EC <		les	di, ds:[di].MB_class				>
EC <		cmp	bx, es:[di].Class_masterOffset			>
EC <		ERROR_NE CANNOT_REMOVE_MASTER_LEVELS_WHEN_CHANGING_CLASS>
EC <		pop	di, es						>
		call	ObjResizeMaster

		mov	bx, ds:[si]
		movdw	ds:[bx].MB_class, esdi
		.leave
		ret
UtilChangeClass endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilDoConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a confirmation box via UserStandardDialogOptr.

CALLED BY:	(EXTERNAL)
PASS:		si	= chunk handle of string to use (in ROStrings)
RETURN:		ax	= InteractionCommand
DESTROYED:	ds/es, if object block
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilDoConfirmation	proc	far

	mov	ax, CustomDialogBoxFlags <1, CDT_QUESTION, GIT_AFFIRMATION, 0>
	push	bx
	clr	bx			; no custom triggers
	GOTO_ECN UtilDoDialog, bx

UtilDoConfirmation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilDoError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up an error box via UserStandardDialogOptr.

CALLED BY:	(EXTERNAL)
PASS:		si	= chunk handle of string to use (in ROStrings)
RETURN:		ax	= InteractionCommand
DESTROYED:	ds/es, if object block
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilDoError	proc	far

	mov	ax, CustomDialogBoxFlags <1, CDT_ERROR, GIT_NOTIFICATION, 0>
	push	bx
	clr	bx			; no custom triggers
	GOTO_ECN UtilDoDialog, bx

UtilDoError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilDoErrorParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up an error box via UserStandardDialogOptr with
		a parameterized error string.

CALLED BY:	(EXTERNAL)
PASS:		si	= chunk handle of string to use (in ROStrings)
		bx:cx	= optr of parameter string
		ax	= response message to be sent to MailboxProcess
				0 to send nothing
RETURN:		nothing
DESTROYED:	ax, ds/es (if object block)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Not really worth the effor to share code with UtilDoDialog.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/ 3/96    	Initial version
	AY	4/29/96		Changed it to non-blocking

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilDoMultiResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a multiple response box via UserStandardDialogOptr.

CALLED BY:	(EXTERNAL)
PASS:		si	= chunk handle of question string to use (in ROStrings)
		bx:cx	= fptr(not vfptr) to StandardDialogResponseTriggerTable
RETURN:		ax	= InteractionCommand
DESTROYED:	ds/es, if object block
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilDoMultiResponse	proc	far

	mov	ax, CustomDialogBoxFlags \
			<1, CDT_QUESTION, GIT_MULTIPLE_RESPONSE, 0>
	push	bx
	FALL_THRU_ECN	UtilDoDialog, bx

UtilDoMultiResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up a dialog box via UserStandardDialogOptr.

CALLED BY:	(INTERNAL) UtilDoConfirmation, UtilDoError, UtilDoMultiResponse
PASS:		si	= chunk handle of string to use (in ROStrings)
		ax	= CustomDialogBoxFlags to use in UserStandardDialogOptr
		bx:cx	= fptr for SDOP_customTriggers (bx = 0 if none)
RETURN:		ax	= InteractionCommand
DESTROYED:	ds/es, if object block
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilDoDialog	proc	ecnear
	uses	bp
	.enter

		CheckHack <offset SDOP_customFlags eq 0>
	sub	sp, size StandardDialogOptrParams - size SDOP_customFlags
	push	ax			; push SDOP_customFlags
	mov	bp, sp
	mov	ss:[bp].SDOP_customString.handle, handle ROStrings
	mov	ss:[bp].SDOP_customString.chunk, si
	clr	ax			; just for using czr
	czr	ax, ss:[bp].SDOP_stringArg1.handle
	czr	ax, ss:[bp].SDOP_stringArg2.handle
	movdw	ss:[bp].SDOP_customTriggers, bxcx
	czr	ax, ss:[bp].SDOP_helpContext.segment
	call	UserStandardDialogOptr	; ax = InteractionCommand response

	.leave
	FALL_THRU_POP	bx
	ret
UtilDoDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilUpdateAdminFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the admin file onto the disk.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilUpdateAdminFile	proc	far
	uses	ax,bx
	.enter

	pushf

	call	MailboxGetAdminFile
	call	VMUpdate
EC <	jnc	ok							>
EC <	cmp	ax, VM_UPDATE_BLOCK_WAS_LOCKED				>
EC <	WARNING_NE ADMIN_FILE_CANT_BE_UPDATED				>
EC <ok:									>
	cmp	ax, VM_UPDATE_BLOCK_WAS_LOCKED
	jne	done

	;
	; VMUpdate failed.  Queue a message to try again later.
	;
	push	di, bp
	mov	ax, MSG_MA_UPDATE_ADMIN_FILE_URGENT
	clr	bp
	;
	; We use MF_CHECK_DUPLICATE only as an optimization to save some
	; handles.  It doesn't hurt even if we don't check-duplicate.
	;
	; We don't care whether the duplicate carries a zero or non-zero bp.
	;
	mov	di, mask MF_CAN_DISCARD_IF_DESPERATE or mask MF_CHECK_DUPLICATE
	call	UtilForceQueueMailboxApp
	pop	di, bp

done:
	popf

	.leave
	ret
UtilUpdateAdminFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilClearBlacklistIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear phone blacklist if message via CELL_MODEM

CALLED BY:	(EXTERNAL)
			OCMLSendMessage
			OCMLSendUponRequestMessages
PASS:		ax - medium token for message
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilCode	ends

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilFixHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the CAH_curOffset field in all chunk arrays in a huge
		array back to zero.

CALLED BY:	(EXTERNAL) AdminFixRefCounts
PASS:		^vbx:di	= huge array
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	huge array marked dirty

PSEUDO CODE/STRATEGY:
	Go thru the chunk arrays by going thru the first elements in all
	chunk arrays.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilFixHugeArray	proc	near
curElt	local	dword
	uses	ax, cx, dx, si, ds
	.enter

	;
	; Even though nobody currently performs any enum on the
	; HugeArrayDirEntry array, we still fix it anyway.
	;
	call	HugeArrayLockDir
	mov	ds, ax
	mov	si, ds:[HAD_dir]
	call	UtilFixChunkArray
	call	HugeArrayUnlockDir

	clrdw	dxax			; start at 1st elt of 1st carray

cArrayLoop:
	movdw	ss:[curElt], dxax
	call	HugeArrayLock		; ds = seg, ax = # elts in this carray
	tst	ax
	jz	done			; => no more elts, no more carrays
	mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si = ChunkArrayHeader
	call	UtilFixChunkArray
	call	HugeArrayDirty		;;; Do we really need this?
	call	HugeArrayUnlock
	clr	dx			; dxax = # elts in this array
	adddw	dxax, ss:[curElt]	; advance to 1st elt in next carray
	jmp	cArrayLoop

done:
EC <	call	ECCheckHugeArray					>

	.leave
	ret
UtilFixHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilFixChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the CAH_curOffset field in the chunk array back to zero.

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= chunk array in a VM block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	array block marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilFixChunkArrayFar	proc	far
	call	UtilFixChunkArray
	ret
UtilFixChunkArrayFar	endp

UtilFixChunkArray	proc	near
	uses	di
	.enter

	mov	di, ds:[si]
	andnf	ds:[di].CAH_curOffset, 0	; 4 bytes
	call	UtilVMDirtyDS
EC <	Assert	ChunkArray, dssi					>

	.leave
	ret
UtilFixChunkArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilFixTwoChunkArraysInBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix the chunk arrays at the first and second chunks in an
		lmem block.

CALLED BY:	(EXTERNAL)
PASS:		^vbx:ax	= lmem block whose first and second chunks are the
			  arrays
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	array block marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilFixTwoChunkArraysInBlock	proc	near

	stc				; fix two
	GOTO	UFixChunkArrayInBlockCommon

UtilFixTwoChunkArraysInBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilFixOneChunkArrayInBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix the chunk array at the first chunk in an lmem block.

CALLED BY:	(EXTERNAL)
PASS:		^vbx:ax	= lmem block whose first chunk is the array
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	array block marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilFixOneChunkArrayInBlock	proc	near

	clc				; fix one
	FALL_THRU UFixChunkArrayInBlockCommon

UtilFixOneChunkArrayInBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UFixChunkArrayInBlockCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix one or two chunk array in an lmem block.

CALLED BY:	(INTERNAL) UtilFixOneChunkArrayInBlock
			   UtilFixTwoChunkArraysInBlock
PASS:		^vbx:ax	= lmem block containing the chunk array(s)
		carry clear if to fix one, set if to fix two
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	array block marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UFixChunkArrayInBlockCommon	proc	near
	uses	ax, si, bp, ds
	.enter

	pushf
	call	VMLock
	mov	ds, ax
	mov	si, ds:[LMBH_offset]
	call	UtilFixChunkArray

	popf
	jnc	unlock
	inc	si
	inc	si			; *ds:si = second array
	call	UtilFixChunkArray

unlock:
	call	VMUnlock

	.leave
	ret
UFixChunkArrayInBlockCommon	endp

Init	ends
