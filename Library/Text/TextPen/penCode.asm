COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Config
MODULE:		
FILE:		penCode.asm

AUTHOR:		Andrew Wilson, Feb 14, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/14/92		Initial revision

DESCRIPTION:
	Contains code to handle pen support for text object

	$Id: penCode.asm,v 1.1 97/04/07 11:21:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PenCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetHWRFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text filters for handwriting recognition. This is
		done via a method so app writers can subclass this.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetHWRFilter	proc	far
	class	VisTextClass
	libHandle	local	hptr
	.enter

;	Ensure we disable character ranges if either a VisTextFilter
;	or custom filter has been provided.

	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	mov	cl, ds:[di].VTI_filters
	tst	cl				;If any filter are present
	jnz	disable				;then we have ranges to diaable
	mov	ax, ATTR_VIS_TEXT_CUSTOM_FILTER
	call	ObjVarFindData
	jnc	exit

disable:
;	Disable the ranges appropriate for this filter

	call	UserGetHWRLibraryHandle
	mov	libHandle, ax

	call	DisableTextRanges

;	Set up a callback to filter out inappropriate characters (disabling
;	char ranges may not be enough, or may not have been possible for
;	certain filters).

FXIP<	mov	ax, SEGMENT_CS						>
FXIP<	push	ax							>
	mov	ax, offset FilterChar
FXIP<	push	ax							>
NOFXIP<	pushdw	csax							>
	push	ds:[LMBH_handle], si		;Save ptr to object data

	CallHWRLibrary	HWRR_SET_CHAR_FILTER_CALLBACK
exit:
	.leave
	Destroy	ax, cx, dx, bp
	ret
VisTextSetHWRFilter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilterChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called by the HWR code - it gets a bunch of
		data, and returns a character that it chooses from the data.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
;	Set the code convention to be pascal, by default.
;
	SetGeosConvention

FilterChar	proc	far	numChoices:word, firstPoint:word, lastPoint:word, charChoices:fptr.word, callbackData:optr
	ForceRef	firstPoint
	ForceRef	lastPoint

	uses	es, ds, si, di
	.enter	

	movdw	bxsi, callbackData
	call	MemDerefDS		;*DS:SI <- VisTextObject
EC <	call	T_AssertIsVisText					>

	mov	cx, numChoices
	jcxz	noChoices

EC <	cmp	cx, 200							>
EC <	ERROR_A	TOO_MANY_CHAR_CHOICES					>

	les	di, charChoices

;	Scan through char choices until we find one that isn't filtered.

nextChar:
	mov	ax, es:[di]
	call	TF_CheckIfCharFiltered
	jnc	exit
	add	di, size word
	loop	nextChar
noChoices:
	clr	ax			;No valid character choices
exit:
	.leave
	ret
FilterChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableTextRanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables the text ranges associated with the passed filter

CALLED BY:	GLOBAL
PASS:		cl - VisTextFilter
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableTextRanges	proc	near
	.enter	inherit	VisTextSetHWRFilter
	
	test	cl, mask VTF_NO_SPACES
	jz	noDisableSpaces

	push	cx
	mov	ax, C_SPACE
	push	ax
	push	ax
	CallHWRLibrary	HWRR_DISABLE_CHAR_RANGE
	pop	cx

noDisableSpaces:

	test	cl, mask VTF_NO_TABS
	jz	noDisableTabs

	push	cx
	mov	ax, C_TAB
	push	ax
	push	ax
	CallHWRLibrary	HWRR_DISABLE_CHAR_RANGE
	pop	cx

noDisableTabs:

	andnf	cl, mask VTF_FILTER_CLASS
	clr	ch

;	For most of the filters, it is not practical (or possible?) to disable
;	every character that would be filtered out. Our goal is to disable
;	some subset of the characters to help out the recognizer, not to
;	provide a perfect filter.


	mov_tr	ax, cx			;AX <- VisTextFilterClass
	mov	di, offset filters
	segmov	es, cs
	mov	cx, length filters
	repne	scasw
	jne	noCall			;Branch if no handler for the class
	call	cs:[di][filterRouts-(filters+2)]
noCall:

	mov	ax, ATTR_VIS_TEXT_CUSTOM_FILTER
	call	ObjVarFindData
	jnc	exit

;
;	Scan through the array of VisTextCustomFilterData structures, and
;	disable the associated ranges.
;


	mov	bx, ds:[bx]
	mov	bx, ds:[bx]		;DS:BX <- array
	ChunkSizePtr	ds, bx, dx	;DX <- # bytes in item
.assert	size VisTextCustomFilterData eq 4
	shr	dx
	shr	dx			;DX <- # items in table.
	jz	exit			;If no items, exit (no filter)

loopTop:
	push	bx, dx
	push	ds:[bx].VTCFD_startOfRange
	push	ds:[bx].VTCFD_endOfRange
	CallHWRLibrary HWRR_DISABLE_CHAR_RANGE
	pop	bx, dx
	add	bx, size VisTextCustomFilterData
	dec	dx
	jnz	loopTop
exit:
	.leave
	ret
DisableTextRanges	endp

filters	word	\
	VTFC_ALPHA,
	VTFC_NUMERIC,
	VTFC_SIGNED_NUMERIC,
	VTFC_SIGNED_DECIMAL,
	VTFC_FLOAT_DECIMAL

filterRouts	nptr	\
		DisableNonAlpha,
		DisableNonNumeric,
		DisableNonSignedNumeric,
		DisableNonSignedDecimal,
		DisableNonFloat

.assert	length filterRouts eq length filters
.assert	size filterRouts eq size filters



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableNonAlpha
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables non-alpha chars.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableNonAlpha	proc	near
	.enter	inherit	DisableTextRanges

;	Disable all but A-Z, a-z, and extended chars.

	mov	ax, C_SPACE+1
	push	ax
	mov	ax, 'A'-1
	push	ax
	CallHWRLibrary	HWRR_DISABLE_CHAR_RANGE
	
	mov	ax, 'Z'+1
	push	ax
	mov	ax, 'a'-1
	push	ax
	CallHWRLibrary	HWRR_DISABLE_CHAR_RANGE
	
	mov	ax, 'z'+1
	push	ax
	mov	ax, 0x7f
	push	ax
	CallHWRLibrary	HWRR_DISABLE_CHAR_RANGE
	.leave
	ret
DisableNonAlpha	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableNonNumeric
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable non numeric range

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableNonNumeric	proc	near
	.enter	inherit	DisableTextRanges
	mov	ax, C_SPACE+1
	push	ax
	mov	ax, '0'-1
	push	ax
	CallHWRLibrary	HWRR_DISABLE_CHAR_RANGE

	mov	ax, '9'+1
	push	ax
	mov	ax, 0xff
	push	ax
	CallHWRLibrary	HWRR_DISABLE_CHAR_RANGE
	.leave
	ret
DisableNonNumeric	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableNonSignedNumeric
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable all but numerals and +-

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableNonSignedNumeric	proc	near
	.enter	inherit	DisableTextRanges
	call	DisableNonNumeric


;	Disable all but 0-9, -, +

	mov	ax, '-'
	push	ax
	push	ax
	CallHWRLibrary	HWRR_ENABLE_CHAR_RANGE
	
	mov	ax, '+'
	push	ax
	push	ax
	CallHWRLibrary	HWRR_ENABLE_CHAR_RANGE	
	.leave
	ret
DisableNonSignedNumeric	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableNonSignedDecimal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables non-numerics and decimals

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableNonSignedDecimal	proc	near
	.enter	inherit	DisableTextRanges
	call	DisableNonSignedNumeric

	call	LocalGetNumericFormat

	push	cx			;Enable the decimal point
	push	cx
	CallHWRLibrary	HWRR_ENABLE_CHAR_RANGE

	.leave
	ret
DisableNonSignedDecimal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableNonFloat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables non-numerics and decimals

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableNonFloat	proc	near
	.enter	inherit	DisableTextRanges
	call	DisableNonSignedDecimal

	mov	cx, 'e'			;Enable E/e (scientific notation shme)
	push	cx
	push	cx
	CallHWRLibrary	HWRR_ENABLE_CHAR_RANGE

	mov	cx, 'E'
	push	cx
	push	cx
	CallHWRLibrary	HWRR_ENABLE_CHAR_RANGE
	.leave
	ret
DisableNonFloat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoHWR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes a handle to a block of ink, and 
		converts it into text, and returns this text in a block

CALLED BY:	GLOBAL
PASS:		bx - block with Ink
		cx - VisTextHWRFlags
		*ds:si - ptr to VisText object
		es:di - ptr to context (not used unless 
			VTHWRF_USE_PASSED_CONTEXT set in CX)
RETURN:		cx - block with text
		   or 0 if nothing recognized
		   or -1 if it was a gesture
       			DX - GestureType
		bx - unchanged
DESTROYED:	dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoHWR	proc	near		uses	ax, es, bp
	class	VisTextClass
	context		local	fptr.HWRContext \
			push	es, di
	blockHandle	local	hptr	\
			push	bx

	flags		local	VisTextHWRFlags	\
			push	cx

	libHandle	local	hptr		;Used by CallHWRLibrary macro
	.enter

EC <	test	cx, not mask VisTextHWRFlags				>
EC <	ERROR_NZ	BAD_VIS_TEXT_HWR_FLAGS				>

;	Begin the interaction with the HWR library

	call	UserGetHWRLibraryHandle
	tst	ax			;Exit if no HWR library loaded 
	LONG jz	errorExit		; (not in pen mode?)
	mov	libHandle, ax

	CallHWRLibrary	HWRR_BEGIN_INTERACTION
	tst	ax
	LONG jnz errorExit		;If error, exit

	CallHWRLibrary	HWRR_RESET

	test	flags, mask VTHWRF_NO_CONTEXT
	jnz	noContext
	test	flags, mask VTHWRF_USE_PASSED_CONTEXT
	jz	defaultContext

;	Use the context that has been passed in

	pushdw	context
	CallHWRLibrary	HWRR_SET_CONTEXT

	jmp	noContext

defaultContext:
	push	bp
	mov	ax, MSG_VIS_TEXT_SET_HWR_CONTEXT
	call	ObjCallInstanceNoLock
	pop	bp
noContext:

;	Setup the filter

	push	bp
	mov	ax, MSG_VIS_TEXT_SET_HWR_FILTER
	call	ObjCallInstanceNoLock
	pop	bp

;	Pass the points off to the HWR library

	mov	bx, blockHandle
	call	MemLock

	mov	es, ax
	push	es:[IH_count]
	mov	di, offset IH_data		;ES:DI <- ptr to Ink data
	pushdw	esdi

	CallHWRLibrary	HWRR_ADD_POINTS

	mov	bx, blockHandle
	call	MemUnlock

	CallHWRLibrary	HWRR_DO_MULTIPLE_CHAR_RECOGNITION
	mov_tr	cx, ax			;CX <- handle of block with string

;	End the interaction with the HWR library

	push	cx, dx
	CallHWRLibrary	HWRR_END_INTERACTION
	pop	cx, dx

exit:
	.leave
	ret
errorExit:
	clr	cx
	jmp	exit
DoHWR	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureRangeValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that the passed range is valid by padding it with 
		spaces, if necessary.

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextRange
		*ds:si - text object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureRangeValid	proc	near	uses	dx
	.enter
	call	TS_GetTextSize
	subdw	dxax, ss:[bp].VTR_start
	jc	getNumSpaces
	clr	ax
exit:
	.leave
	ret
getNumSpaces:
	neg	ax			;AX = # spaces to add
	jmp	exit

EnsureRangeValid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendSpaces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends spaces to the text

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
		cx - # spaces to append
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendSpaces	proc	near	uses	ax, cx, dx, bp, es, di
	.enter
EC <	cmp	cx, 50							>
EC <	ERROR_AE	APPENDING_TOO_MANY_SPACES			>
	sub	sp, cx
	segmov	es, ss
	mov	di, sp

	push	cx, di
	mov	al, C_SPACE
	rep	stosb
	pop	cx, di

;	Add the spaces to the object

	push	cx
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp			; ss:bp <- frame
	movdw	ss:[bp].VTRP_range.VTR_start, TEXT_ADDRESS_PAST_END
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	clr	ss:[bp].VTRP_insCount.high
	mov	ss:[bp].VTRP_insCount.low, cx
	mov	ss:[bp].VTRP_flags, mask VTRF_FILTER or \
				    mask VTRF_USER_MODIFICATION or \
				    mask VTRF_DO_NOT_SEND_CONTEXT_UPDATE
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	movdw	ss:[bp].VTRP_pointerReference,esdi
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock
	add	sp, size VisTextReplaceParameters
	pop	cx
	add	sp, cx

	.leave
	ret

AppendSpaces	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine handles ink blocks sent from the application.

CALLED BY:	GLOBAL
PASS:		ds:di - VisText object
		bp	handle to data block
		dx	notification type
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextNotifyWithDataBlock	proc	far
	class	VisTextClass	
	push	ax, cx, dx, bp
	mov	bx, bp			;BX <- data block
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_TEXT_REPLACE_GESTURE
	je	doGestureReplace
	cmp	dx, GWNT_TEXT_REPLACE_WITH_HWR
	je	doInkReplace	
	cmp	dx, GWNT_INK
	je	cont
	cmp	dx, GWNT_INK_GESTURE
	jne	callSuper
cont:

EC <	test	ds:[di].VTI_state, mask VTS_EDITABLE			>
EC <	ERROR_Z	INK_RECEIVED_BY_NON_EDITABLE_OBJECT			>

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	call	TextMakeFocusAndTarget

	cmp	dx, GWNT_INK_GESTURE
	jne	cont2
	call	InsertGesture
	jmp	restoreStack
cont2:

;	Mark the application as busy while we do HWR processing
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	UserCallApplication

	call	MemIncRefCount	;Inc the ref count so the block won't get freed
				; until the MSG_VIS_TEXT_DO_HWR frees it.

	sub	sp, size VisTextReplaceWithHWRParams
	mov	bp, sp
	mov	ss:[bp].VTRWHWRP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	clr	ss:[bp].VTRWHWRP_flags
	mov	ss:[bp].VTRWHWRP_ink, bx
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_HWR
	call	ObjCallInstanceNoLock
	add	sp, size VisTextReplaceWithHWRParams

markNotBusy::
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserCallApplication

restoreStack:
	pop	di
	call	ThreadReturnStackSpace

callSuper:
	pop	ax, cx, dx, bp
	mov	di, offset VisTextClass
	GOTO	ObjCallSuperNoLock

doGestureReplace:

	call	DoGestureReplace
	jmp	callSuper
doInkReplace:
	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	push	es
	call	MemIncRefCount
	call	MemLock
	mov	es, ax
	mov	di, es:[IH_count]
.assert	size InkPoint	eq	4
	shl	di
	shl	di
	add	di, size InkHeader	;ES:DI <- ptr to ReplaceWithHWRData
	
	sub	sp, size VisTextReplaceWithHWRParams
	mov	bp, sp
	movdw	ss:[bp].VTRWHWRP_range.VTR_start, es:[di].RWHWRD_range.VTR_start, ax
	movdw	ss:[bp].VTRWHWRP_range.VTR_end, es:[di].RWHWRD_range.VTR_end, ax
	mov	ss:[bp].VTRWHWRP_ink, bx
	mov	ss:[bp].VTRWHWRP_flags, mask VTHWRF_USE_PASSED_CONTEXT
	push	ds, si
	segmov	ds, es
	segmov	es, ss
	lea	si, ds:[di].RWHWRD_context
	lea	di, es:[bp].VTRWHWRP_context
	mov	cx, size HWRContext
	rep	movsb
	pop	ds, si
	call	EnsureRangeValid	;If the range starts beyond the text
					; append spaces to make it valid
	call	VisTextReplaceWithHWR
	add	sp, size VisTextReplaceWithHWRParams
	pop	es
	jmp	restoreStack
VisTextNotifyWithDataBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceWithHWR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs HWR on the passed ink block

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
		ss:bp - VisTextReplaceWithHWRParams
		ax - # spaces to insert, *or* MSG_VIS_TEXT_REPLACE_WITH_HWR
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceWithHWR	proc	far		;MSG_VIS_TEXT_REPLACE_WITH_HWR
	class	VisTextClass
	mov	bx, ss:[bp].VTRWHWRP_ink ;BX <- handle of ink
	mov	cx, ss:[bp].VTRWHWRP_flags

	push	bx

	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	doExit


;	Call Handwriting Recognition code here:

	segmov	es, ss
	lea	di, ss:[bp].VTRWHWRP_context
	call	DoHWR
	jcxz	giveBeepAndExit		;

	mov	bx, cx
	mov_tr	cx, ax
	call	MemLock
	mov	es, ax
	tst	{byte}es:[0]
	jnz	addText

	call	MemFree			;Free the text block

giveBeepAndExit:			;Beep, to inform the user that no chars
		mov	ax, SST_NOTIFY		; were recognized.
	call	UserStandardSound

doExit:
	pop	bx
	GOTO	MemDecRefCount

addText:

;	Replace the selection with the recognized text 
;	CX <- # spaces to append before doing HWR
;		 (or MSG_VIS_TEXT_REPLACE_WITH_HWR)
;	SS:BP - VisTextReplaceWithHWRParams



	mov	ax, offset InkString
	call	TU_StartChainIfUndoable

	sub	sp, size VisTextReplaceParameters
	mov	di, sp			; ss:di <- frame

	movdw	ss:[di].VTRP_range.VTR_start, ss:[bp].VTRWHWRP_range.VTR_start, ax
	movdw	ss:[di].VTRP_range.VTR_end, ss:[bp].VTRWHWRP_range.VTR_end, ax
	mov	bp, di			;SS:BP <- frame

	jcxz	noAppendSpaces
	cmp	cx, MSG_VIS_TEXT_REPLACE_WITH_HWR
	je	noAppendSpaces

	call	AppendSpaces

	movdw	ss:[bp].VTRP_range.VTR_start, TEXT_ADDRESS_PAST_END
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	
noAppendSpaces:

	mov	ss:[bp].VTRP_insCount.high, INSERT_COMPUTE_TEXT_LENGTH
	mov	ss:[bp].VTRP_insCount.low, 0
	mov	ss:[bp].VTRP_flags, mask VTRF_FILTER or \
				    mask VTRF_USER_MODIFICATION
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	mov	ss:[bp].VTRP_pointerReference.segment,es
	clr	ss:[bp].VTRP_pointerReference.offset
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock
	add	sp, size VisTextReplaceParameters

	call	TU_EndChainIfUndoable

	call	MemFree			;Free up the recognized text
	jmp	doExit

VisTextReplaceWithHWR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoGestureReplace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure deals with a gesture replace message
		from the HWR grid.  It takes the the text range passed
		in the ReplaceWithGestureData and replaces it with the
		data passed in ReplaceWithGestureData

CALLED BY:	
PASS:		bx - handle to ReplaceWithGestureData
RETURN:		nothing
DESTROYED:	si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoGestureReplace	proc	near   
	uses	ax,bx,dx,es,bp
	.enter
	call	MemLock
	jc	exit
	mov	es, ax
	mov	dx, es:[RWGD_gestureType]
	push	bx
	mov	bx, dx
EC <	cmp	bx, GestureType				>
EC <	ERROR_A	VIS_TEXT_INVALID_GESTURE				>
	shl	bx, 1			; index into our nptr table
	call	cs:[handleGestureReplaceTable][bx]

	pop	bx
	call 	MemUnlock
exit:		
	.leave
	ret
DoGestureReplace	endp

;
; these procedures can destroy the following regesters:
; ax, bx, cx, dx, si, di
;
handleGestureReplaceTable	nptr	\
	GestureReplaceNull,	; GT_NO_GESTURE
	GestureReplaceNull,	; GT_DELETE_CHARS
	GestureReplaceNull,	; GT_SELECT_CHARS
	GestureReplaceNull,	; GT_V_CROSSOUT
	GestureReplaceNull,	; GT_H_CROSSOUT
	GestureReplaceNull,	; GT_BACKSPACE
	GestureReplaceChar,	; GT_CHAR
	GestureReplaceNull,	; GT_STRING_MACRO
	GestureReplaceNull,	; GT_IGNORE_GESTURE
	GestureReplaceNull,	; GT_COPY
	GestureReplaceNull,	; GT_PASTE
	GestureReplaceNull,	; GT_CUT
	GestureReplaceChar,	; GT_MODE_CHAR
	GestureReplaceReplaceLastChar	; GT_REPLACE_LAST_CHAR
	

.assert( (length handleGestureReplaceTable) eq GestureType )


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureReplaceNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	function place holder until handler for gestures from
		the hwr grid for this gesture type are implemented.

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureReplaceNull	proc	near
	.enter
	.leave
	ret
GestureReplaceNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureReplaceChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	replaces the passed range with the passed char. If the
		gesture type is GT_MODE_CHAR, then it supresses filtering

CALLED BY:	(PRIVATE)DoGestureReplace
PASS:		es:0	- prt to ReplaceWithGestureData
		*ds:si	= VisTextObject
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureReplaceChar	proc	near
	.enter

	mov	ax, offset InkString
	call	TU_StartChainIfUndoable

	sub	sp, size VisTextReplaceParameters
	mov	bp, sp			; ss:di <- frame

	;
	; do not filter this modification if it is a mode char
	;
	cmp	es:[RWGD_gestureType], GT_MODE_CHAR
	mov	ss:[bp].VTRP_flags, mask VTRF_USER_MODIFICATION
	je	noFilter
	or	ss:[bp].VTRP_flags, mask VTRF_FILTER 
noFilter:
	movdw	ss:[bp].VTRP_range.VTR_start, es:[RWGD_range].VTR_start, ax
	movdw	ss:[bp].VTRP_range.VTR_end, es:[RWGD_range].VTR_end, ax

	call 	EnsureRangeValid	; ax <- number of spaces to
					; append
	mov	cx, ax	
	jcxz	noAppendSpaces
	call	AppendSpaces

	movdw	ss:[bp].VTRP_range.VTR_start, TEXT_ADDRESS_PAST_END
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	
noAppendSpaces:

	mov	ss:[bp].VTRP_insCount.high,  0
	mov	ss:[bp].VTRP_insCount.low, 1
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	mov	ss:[bp].VTRP_pointerReference.segment, es
	mov	ss:[bp].VTRP_pointerReference.offset, offset RWGD_data
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock
	;
	; set the selection point to the end of the text that we just
	; entered 
	;
	lea	bp, ss:[bp].VTRP_range
	;
	; if start and end are the same, then the character was
	; inserted after end, and we need to inc the selection point
	; by one
	;
	cmpdw	ss:[bp].VTR_start, ss:[bp].VTR_end, ax
	jne	doNotInc
	incdw	ss:[bp].VTR_end
doNotInc:
	movdw	ss:[bp].VTR_start, ss:[bp].VTR_end, ax
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock

	add	sp, size VisTextReplaceParameters

	call	TU_EndChainIfUndoable		

	.leave
	ret
GestureReplaceChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureReplaceReplaceLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Backspace one and then replace the character with the
		passed character

CALLED BY:	(PRIVATE)DoGestureReplace
PASS:		es:0	- prt to ReplaceWithGestureData
		*ds:si	VisTextObject
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureReplaceReplaceLastChar	proc	near
	.enter
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_DELETE_BACKWARD_CHAR
	call	ObjCallInstanceNoLock

	mov	di, offset RWGD_data
	;
	; if there is no character then the HWR library just wanted to
	; clean up the mode character it returned earlier.
	;
	tst	{word}es:[di]
	jz	exit

	mov	cx, TRUE		; filter this character
	call	InsertChar
exit:
	.leave
	ret
GestureReplaceReplaceLastChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calls the appropriate gesture function to deal with
		the gesture recieved

CALLED BY:	VistTextNotifyWithDataBlock
PASS:		*ds:si	VisTextObject
		bx	handle to gesture data block
		dx	notification type, should be GWNT_INK_GESTURE
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertGesture	proc	near
	uses	ax,bx,cx,dx,es,bp,di
	.enter
	cmp	dx, GWNT_INK_GESTURE
	jne	exit

	call	MemLock	
	jc	exit
	mov	es, ax
	mov	dx,es:[GH_gestureType]
	call	MemUnlock
	mov	ax, bx
	mov	bx, dx
	shl	bx, 1
EC <	cmp	bx, eGestureTab-gestureTab				>
EC <	ERROR_A	VIS_TEXT_INVALID_GESTURE				>
	call	cs:[gestureTab-2][bx]
exit:
	.leave
	ret
InsertGesture	endp

gestureTab	nptr	GestureDelete		;GT_DELETE_CHARS
		nptr	GestureNull		;GT_SELECT_CHARS
		nptr	GestureHCrossout	;GT_V_CROSSOUT
		nptr	GestureHCrossout	;GT_H_CROSSOUT
		nptr	GestureBackspace	;GT_BACKSPACE
		nptr	GestureChar		;GT_CHAR
		nptr	GestureStringMacro	;GT_STRING_MACRO
		nptr	GestureNull		;GT_IGNORE_GESTURE
		nptr	GestureCopy		;GT_COPY
		nptr	GesturePaste		;GT_PASTE
		nptr	GestureCut		;GT_CUT
		nptr	GestureModeChar		;GT_MODE_CHAR
		nptr	GestureReplaceLastChar	;GT_REPLACE_LAST_CHAR

EC <eGestureTab	label	nptr						>
EC <	.assert	(eGestureTab - gestureTab)/(size nptr) eq GestureType-1 >


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a placeholder routine until the various gesture
		handlers can be written.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureNull	proc	near
	ret
GestureNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureHCrossout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the text under the rectangle of this gesture.
		This gesture comes with the handle to the rectangle
		bounding it. We delete the range of characters across
		the middle of that rectangle.

CALLED BY:	InsertGesture
PASS:		*ds:si	VistTextObject
		ax	handle to gesture data (GestureHeader)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es, di

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureHCrossout	proc	near
class	VisTextClass
delPoint	local	PointDWFixed
delRange	local	VisTextRange
	.enter
	mov	bx, ax
	call	MemLock
	push	bx
	mov	es, ax

	call	TextGStateCreate
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate

	;		
	; es:GH_data = Rectangle data passed with gesture
	;
	mov	bx, ({Rectangle}es:[GH_data]).R_top	
	add	bx, ({Rectangle}es:[GH_data]).R_bottom
	shr	bx, 1			; bx = (top+bottom)/2;
	mov	ax, ({Rectangle}es:[GH_data]).R_left
	push	bx			; save y coord, since it is
					; the same for both ends
	call	GetRegionCoord

	jnc	noProb
	pop 	bx
popMemHandle:
	pop 	bx
	call	MemUnlock
	.leave
	ret

noProb:
	clr	cx
	clrdwf	ss:[delPoint].PDF_x, cx
	clrdwf	ss:[delPoint].PDF_y, cx
	mov	ss:[delPoint].PDF_x.DWF_int.low, ax
	mov	ss:[delPoint].PDF_y.DWF_int.low, bx
	;
	; get the text postition of the beggining of the range to delete
	;
	push	bp
	lea	bp, ss:[delPoint]
	mov	ax, MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD
	call	ObjCallInstanceNoLock
	pop	bp

	movdw	ss:[delRange].VTR_start, dxax
	;
	; put the point at the middle of the right hand side of the
	; rectangle 
	;
	mov	ax, ({Rectangle}es:[GH_data]).R_right
	pop	bx

	call	GetRegionCoord
	jnc	noProb2
	jmp	popMemHandle
	
noProb2:
	clr	cx
	clrdwf	ss:[delPoint].PDF_x, cx
	clrdwf	ss:[delPoint].PDF_y, cx
	mov	ss:[delPoint].PDF_x.DWF_int.low, ax
	mov	ss:[delPoint].PDF_y.DWF_int.low, bx
	
	push	bp
	lea	bp, ss:[delPoint]
	;
	; get the text postition at the end of the range to delete 
	;
	mov	ax, MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD
	call	ObjCallInstanceNoLock
	pop	bp

	movdw	ss:[delRange].VTR_end, dxax
	;
	; need to make sure the start is before or equal to the end
	;
	cmpdw	ss:[delRange].VTR_end, ss:[delRange].VTR_start, ax
	jge	ok
	movdw	ss:[delRange].VTR_start, ss:[delRange].VTR_end, ax
ok:
	;
	; Delete the range of chars
	;
	push	bp
	lea	bp, ss:[delRange]
	mov	ax, MSG_META_DELETE_RANGE_OF_CHARS
	call	ObjCallInstanceNoLock
	pop	bp
		
	call	TextGStateDestroy
	jmp	popMemHandle

GestureHCrossout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRegionCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the document coord given a screen coord and the
		gstate of the text object.

CALLED BY:	(PRIVATE)GestureHCrossout
PASS:		*ds:si	= VistTextObject
		es:0	= ptr to GestureHeader
		di 	= gstate of text object 
		ax	= x coord
		bx	= y coord
RETURN:		ax 	= x coord
		bx	= y coord
		carry	if the transformation will cause an overflow
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRegionCoord	proc	near
class	VisTextClass
	uses	di
	.enter
	
	call	GrUntransform
	jc	exit
	; 
	; Move the x coord to document coord
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	;
	; change x to document coord
	;
	add	ax, ds:[di].VI_bounds.R_left	; ax <- X translation
	add	al, ds:[di].VTI_lrMargin
	adc	ah, 0
	;
	; change y to document coord
	;
	add	bx, ds:[di].VI_bounds.R_top	; ax <- X translation
	add	bl, ds:[di].VTI_tbMargin
	adc	bh, 0
	
	;
	; change to position relative to this region
	;
exit:
	.leave
	ret
GetRegionCoord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert take the char located in the data portion of
		the GestureHeader and insert it into the VisTextObject

CALLED BY:	InsertGesture
PASS:		*ds:si	VistTextObject
		ax	handle to gesture data (GestureHeader)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureChar	proc	near
	.enter
	mov	bx, ax	
	call	MemLock
	jc	exit
	mov	es, ax
	mov	di, offset GH_data
	mov	cx, TRUE		; filter this char
	call	InsertChar
	call	MemUnlock
exit:
	.leave
	ret
GestureChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureReplaceLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the last character entered.  Backspace 1 and
		then insert the character.

CALLED BY:	InsertGesture
PASS:		*ds:si	VistTextObject
		ax	handle to gesture data (GestureHeader)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureReplaceLastChar	proc	near
	.enter
	push	ax, bp
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_DELETE_BACKWARD_CHAR
	call	ObjCallInstanceNoLock
	pop	ax, bp

	mov	bx, ax	
	call	MemLock
	jc	exit
	mov	es, ax
	mov	di, offset GH_data
	;
	; if there is no character, then we the hwr just wanted to
	; clean up the mode char that was inserted.
	;
	tst	{word}es:[di]
	jz	exit

	mov	cx, TRUE		; filter this character
	call	InsertChar
	call	MemUnlock
exit:
	.leave
	ret
GestureReplaceLastChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureModeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the char located in the data portion of
		the GestureHeader and insert it into the
		VisTextObject. This is a mode char and represents a
		change in mode indicated by the hwr, and should not be
		filtered.

CALLED BY:	InsertGesture
PASS:		*ds:si	VistTextObject
		ax	handle to gesture data (GestureHeader)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureModeChar	proc	near
	.enter
	mov	bx, ax	
	call	MemLock
	jc	exit
	mov	es, ax
	mov	di, offset GH_data
	mov	cx, FALSE		; do not filter this character
	call	InsertChar
	call	MemUnlock
exit:
	.leave
	ret
GestureModeChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the text object MSG_META_CLIPBOARD_CUT

CALLED BY:	
PASS		*ds:si - ptr to VisTextObject
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureCut	proc	near
	.enter
	mov	ax, MSG_META_CLIPBOARD_CUT
	call	ObjCallInstanceNoLock
	.leave
	ret
GestureCut	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the text object MSG_META_CLIPBOARD_COPY

CALLED BY:	
PASS		*ds:si - ptr to VisTextObject
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureCopy	proc	near
	.enter
	mov	ax, MSG_META_CLIPBOARD_COPY
	call	ObjCallInstanceNoLock
	.leave
	ret
GestureCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GesturePaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the text object MSG_META_CLIPBOARD_PASTE

CALLED BY:	
PASS		*ds:si - ptr to VisTextObject
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GesturePaste	proc	near
	.enter
	mov	ax, MSG_META_CLIPBOARD_PASTE
	call	ObjCallInstanceNoLock
	.leave
	ret
GesturePaste	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a char into the text object

CALLED BY:	PRIVATE
PASS:		es:di 	= ptr to character to insert
		*ds:si 	= ptr to VisTextObject
		cx	= 0 if should not filter this character.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertChar	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, bp, si, di
	.enter

	mov	ax, offset InkString
	call	TU_StartChainIfUndoable

	sub	sp, size VisTextReplaceParameters
	mov	bp, sp			; ss:bp <- frame

	mov	ss:[bp].VTRP_insCount.high,  0
	mov	ss:[bp].VTRP_insCount.low, 1
	mov	ss:[bp].VTRP_flags, mask VTRF_USER_MODIFICATION
	jcxz	noFilter
	or	ss:[bp].VTRP_flags, mask VTRF_FILTER 
noFilter:
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	mov	ss:[bp].VTRP_pointerReference.segment, es
	mov	ss:[bp].VTRP_pointerReference.offset, di
	;
	; Set the range...
	;
	; If we are *not* in overstrike mode then we use the selection
	; as the range to replace.
	;
	; Assume not in overstrike mode
	;
	mov	ss:[bp].VTRP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_state, mask VTS_OVERSTRIKE_MODE
	jz	doReplace
	;
	; We are in overstrike mode. If the selected range is a cursor, then
	; we want to delete the character following the cursor, unless of 
	; course we are at the end of the text.
	;
	call	TSL_SelectGetSelectionStart	; dx.ax <- start
						; carry set if range
	jc	doReplace			; Branch if selection is range
	;
	; The selection is a cursor, check for at the end of the text
	;
	movdw	cxbx, dxax			; Save start of selection
	call	TS_GetTextSize			; dx.ax <- end of text
	cmpdw	cxbx, dxax			; Check for cursor at end
	je	doReplace			; Branch if it is
	;
	; The selection is a cursor and is not at the end of the text.
	; Save a range of one character into the range to replace.
	;
	movdw	ss:[bp].VTRP_range.VTR_start, cxbx
	incdw	cxbx
	movdw	ss:[bp].VTRP_range.VTR_end, cxbx
doReplace:
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock
	add	sp, size VisTextReplaceParameters

	call	TU_EndChainIfUndoable
	.leave
	ret
InsertChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoVisTextFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	performs the VisTextKeyFunction pointed to by es:di

CALLED BY:	(PRIVATE) GestureStringMacro
PASS:		ax - VisTextKeyFunction
		*ds:si- ptr to VisTextObject
RETURN:		nothing
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoVisTextFunction	proc	near
	uses	si, di, es, bp, cx
	.enter
	mov	cx, ax
	clr	bp
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	call	ObjCallInstanceNoLock	
	
	.leave
	ret
DoVisTextFunction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureStringMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the data in the GestureHeader and treat it as a
		StringMacro.  How the data is processed is described
		below in the strategy field.

CALLED BY:	(PRIVATE) InsertGesture
PASS:		*ds:si-	VistTextObject
		ax -	handle to gesture data (GestureHeader)
RETURN:		
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	send of as many back spaces as are specified in the
	deleteCount field		

	loop through the array of elements
		if element = HWR_STRING_ESCAPE_VALUE
			send the next element off as a
			VisTextKeyFunction to the VisTextObject(*ds:si)
		else 
			insert the element as a character into the
			VisTextObject(*ds:si)
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureStringMacro	proc	near
	call	GestureStringMacroFar
	ret
GestureStringMacro	endp

GestureStringMacroFar	proc	far
	uses	si, es
	.enter
	mov	bx, ax	
	call	MemLock
	jc	exit
	mov	es, ax
	mov	di, offset GH_data
	mov	cx, es:[di][HWRSM_deleteCount]

	;
	; perform as many VTKF_DELETE_BACKWARD_CHAR as is neccessary
	; to delete HWRSM_deleteCount characters backwards in the text
	;
deleteLoop:
	jcxz 	endDeleteLoop
	mov	ax, VTKF_DELETE_BACKWARD_CHAR
	call	DoVisTextFunction
	loop	deleteLoop
endDeleteLoop:

	;
	; go through the array of elements and either insert them in
	; the text if they are characters or if there is a
	; HWR_STRING_ESCAPE_VALUE treat the next element as a
	; VisTextKeyFunction and perform that function
	;
	add	di, offset HWRSM_string	
elementLoop:
	mov	cx, es:[di]
	jcxz	endElementLoop
	
	cmp	cx, HWR_STRING_ESCAPE_VALUE
	jne	cont
	;
	; perform embeded vis text function
	;
	inc	di
	inc	di
	mov	ax, es:[di]
	call	DoVisTextFunction
	jmp	nextElement
	;
	; insert character
	;
cont:
	call	InsertChar
	
nextElement:
	inc	di
	inc	di
	jmp	elementLoop

endElementLoop:
exit:
	.leave
	ret
GestureStringMacroFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureBackspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the last character.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureBackspace	proc	near
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_DELETE_BACKWARD_CHAR
	call	ObjCallInstanceNoLock
	ret
GestureBackspace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the selection in the passed text object

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
		ax     - handle to gesture data block
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureDelete	proc	near
	mov	ax, MSG_META_DELETE		; (sets user-modified)
	call	ObjCallInstanceNoLock
	ret
GestureDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler returns whether or not presses in the
		text object should be ink or not. In this case, presses
		should be ink unless the user clicks and holds for a certain
		amount of time.

CALLED BY:	GLOBAL
PASS:		ds:di - ink object
RETURN:		ax - InkReturnValue
		bp - 0 or InkDestinationInfo
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextQueryIfPressIsInk	proc	far
	class	VisTextClass
	.enter

if _TEXT_NO_INK
;
; If we don't accept ink, then return IRV_NO_INK.
;
	mov	ax, IRV_NO_INK
	clr	bp			;No ink-destination info
	.leave
	ret

else

;
;	For non-editable object, no ink
;
;	For editable objects, set the destination to be the ink object
;
;	For selectable objects, set the ink type to ink w/standard override,
;		otherwise, just ink


	clr	bp
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	je	noInk		;If not editable, branch

	mov	ax, ATTR_VIS_TEXT_DOES_NOT_ACCEPT_INK
	call	ObjVarFindData
	jc	noInk

	
	clr	bp			;BP <- gstate to draw through
	clr	ax			;Default width/height
	mov	cx, ds:[LMBH_handle]	;^lCX:DX - object to send ink to
	mov	dx, si
	push	di
	mov	bx, vseg CheckIfTextGesture
	mov	di, offset CheckIfTextGesture
	call	UserCreateInkDestinationInfo
	pop	di

;	If error allocating block exit w/no ink

	tst	bp
	jnz	wantsInk
noInk:
	mov	ax, IRV_NO_INK
	clr	bp			;No ink-destination info
exit:
	.leave
	ret

wantsInk:
	mov	ax, IRV_DESIRES_INK	;
	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	jz	exit
	mov	ax, IRV_INK_WITH_STANDARD_OVERRIDE
	jmp	exit

endif  ; _TEXT_NO_INK

VisTextQueryIfPressIsInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrokeEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enumerate throught the strokes

CALLED BY:	CheckIfTextGesture
PASS:		es:di 	- ptr to buffer of points
		cx	- num points total
RETURN:		bx	- total number of points recognized as part of
			- a gesture
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
    while all strokes not checked
	while not the last point in a stroke 
		inc the number of points in this stroke
		goto the next point
	call routine to deal with this stroke and check to see if it
		is a gesture
	If it is not a gesture then quit
	If it is a gesture add the number of points in this stroke to
		the total of all points that are part of a stroke

    return the total of all points that were part of a stroke 		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StrokeEnum	proc	near
	uses	ax,cx,dx,si,di
	.enter
	
	mov	si, di			
	sub	si, size Point
	clr	bx

loopStrokes:
	clr	dx		

	jcxz	exit
loopPoints:
	inc	dx			; # of points in stroke
	add	si, size Point
	test	es:[si], mask IXC_TERMINATE_STROKE
	loopz	loopPoints
	
endLoopPoints::
	;
	; found end of stroke, call function
	;
	push	bx, cx, dx
	mov	cx, dx
	call	CheckIfGesture
	pop	bx, cx, dx
	;
	; if this stroke is not a gesture then leave
	;
	tst	ax
	jz	endLoopStrokes

	add	bx, dx			; bx += num points in this
					; stroke 
	mov	di, si
	add	di, size Point
	jmp 	loopStrokes

endLoopStrokes:
exit:
	.leave
	ret

StrokeEnum	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfTextGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed code is a gesture or not.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/18/93   	Initial version
	IP	5/15/94		changed for new HWR interface

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
CheckIfTextGesture	proc	far	points:fptr,
					numPoints:word,
					numStrokes:word
	.enter

;	If this is not the first call to the gesture callback routine, just
;	exit, because if it wasn't a gesture before, it sure won't be one
;	now...
	clr	ax

	test	numStrokes,  mask GCF_FIRST_CALL
	jnz	cont
	
	cmp	numStrokes, 1
	jne	exit

cont:
	les	di, points
	mov	cx, numPoints
	call	StrokeEnum
	mov	ax, bx

exit:
	.leave
	ret
CheckIfTextGesture	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed ink is any sort of
		gesture.  If it is a gesture calls the routine
		associated with that gesture.
		

CALLED BY:	GLOBAL
PASS:		es:di - ptr to strokes
		cx - # points
RETURN:		carry set if gesture (AX = GestureType)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	05/16/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfGesture	proc	near	uses	bx, cx, dx, bp, di, si, es
	numPoints	local	word	push	cx	
	libHandle	local	hptr		;Used by CallHWRLibrary macro
	points		local	fptr
	.enter

	movdw	points, esdi
	call	UserGetHWRLibraryHandle
	tst	ax				;Exit if no HWR library
	LONG jz	error
	mov	libHandle, ax

	CallHWRLibrary	HWRR_BEGIN_INTERACTION
	tst	ax
	jnz 	error				;If error, exit

	CallHWRLibrary	HWRR_RESET

;	Send the ink points to the HWR recognizer

	push	numPoints
	pushdw	points
	CallHWRLibrary	HWRR_ADD_POINTS

	CallHWRLibrary	HWRR_DO_GESTURE_RECOGNITION
	;Returns AX = GestureType
	;Returns dx = extra gesture info

	push	ax, dx
	CallHWRLibrary	HWRR_END_INTERACTION
	pop	ax, dx
	
	cmp	ax, GT_NO_GESTURE
	jnz	isGesture
error:
	clc
exit:
	.leave
	ret

isGesture:
	mov	bx, ax
	shl	bx, 1
EC <	cmp	bx, eHandleGestureTab-handleGestureTab			>
EC <	ERROR_A	VIS_TEXT_INVALID_GESTURE				>
	push	ax, bp
	call	cs:[handleGestureTab-2][bx]
	pop	ax, bp
	stc
	jmp	exit

CheckIfGesture	endp

handleGestureTab nptr	SendGestureToFlow		;GT_DELETE_CHARS
		nptr	HandleGestureNull		;GT_SELECT_CHARS
		nptr	HandleGestureHCrossout		;GT_V_CROSSOUT
		nptr	HandleGestureHCrossout		;GT_H_CROSSOUT
		nptr	SendGestureToFlow		;GT_BACKSPACE
		nptr	SendGestureToFlow		;GT_CHAR
		nptr	HandleGestureStringMacro	;GT_STRING_MACRO
		nptr	HandleGestureNull		;GT_IGNORE_GESTURE
		nptr	SendGestureToFlow		;GT_COPY
		nptr	SendGestureToFlow		;GT_PASTE
		nptr	SendGestureToFlow		;GT_CUT
		nptr	SendGestureToFlow		;GT_MODE_CHAR
		nptr	SendGestureToFlow		;GT_REPLACE_LAST_CHAR

EC <eHandleGestureTab	label	nptr					>
EC <.assert(eHandleGestureTab - handleGestureTab)/(size nptr) eq GestureType-1>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureHCrossout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends GT_H_CROSSOUT to the flow object along with
		the Rectangle bounds

CALLED BY:	CheckIfGesture
PASS:		dx - handle to Rectangle
RETURN:		nothing
DESTROYED:	bx, cx, dx, di, si, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureHCrossout	proc	near
	uses	ds
	.enter
	mov	bx, dx
	call	MemLock
	mov	ds, ax
	clr	si

	mov	ax, size GestureHeader
	add	ax, size Rectangle
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc
	push	bx
	mov	es, ax
	mov	es:[GH_gestureType], GT_H_CROSSOUT
	mov	di, offset GH_data
	

	CheckHack <((((size Rectangle)/2)*2) eq (size Rectangle))>

	mov	cx, (size Rectangle)/2
	rep	movsw				; copy the block
						; passed from the hwr
						; library
	mov	bx, dx
	call	MemFree				; free the block
						; passed from the hwr
						; library
	pop	bx
	call	MemUnlock

	call	SendGestureWithDataToFlow
	.leave
	ret
HandleGestureHCrossout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureStringMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends GT_STRING_MACRO to the flow object along with
		the string data	

CALLED BY:	CheckIfGesture
PASS:		dx - handle to HWRStringMacro
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureStringMacro	proc	near
	uses	ds
	.enter
	mov	bx, dx
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	mov	bp, ax			; save size of block
	add	ax, size GestureHeader
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc
	jc	exit

	mov	es, ax
	mov	es:[GH_gestureType], GT_STRING_MACRO
	mov	di, offset GH_data
	
	push	bx			; save handle to new block
	mov	bx, dx			; lock block from HWR library
	call	MemLock
	jc	lockError
	mov	ds, ax
	clr	si
	
	mov	cx, bp			; copy data returned by the
	rep 	movsb			; hwr library to a new block
					; to send to the flow

	call	MemFree			; free the block from the HWR
					; library 
	pop	bx
	call	MemUnlock		; unlock the block to send off
	
	call	SendGestureWithDataToFlow
exit:
	.leave
	ret

lockError:
	pop	bx
	call	MemFree
	jmp	exit

HandleGestureStringMacro	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendGestureToFlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the Gesture in ax, to the flow object.  Assumes
		that no data will be sent with the GestureType

CALLED BY:	(PRIVATE) HandleGestureDelete
			  HandleGestureCopy
			  HandleGesturePaste
			  HandleGestureCut
PASS:		ax	= GestureType
		dx 	= word of data to go with gesture
RETURN:		carry set if could not allocated GestureHeader
DESTROYED:	ax,bx,cx,dx,si,es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendGestureToFlow	proc	near
	.enter
	push	ax

	mov	ax, size GestureHeader
	add	ax, size word
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc
	mov	es, ax
	pop	ax
	jc	exit
	mov	es:[GH_gestureType], ax
	mov	es:[GH_data], dx
	call	MemUnlock

	GOTO	SendGestureWithDataToFlow
exit:
	.leave
	ret
SendGestureToFlow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendGestureWithDataToFlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the passed data along to the Flow, with
		notification type GWNT_INK_GESTURE

CALLED BY:	(PRIVATE)SendGestureToFlow, HandleGestureHCrossout, 
		HandleGestureStringMacro
PASS:		bx = handle to data
RETURN:		ax, cx, dx, bp, di
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	7/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendGestureWithDataToFlow	proc	near
	.enter

	mov	ax, 1
	call 	MemInitRefCount
	
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_INK_GESTURE
	mov	bp, bx
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	UserCallFlow

	.leave
	ret
SendGestureWithDataToFlow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Function place holder until the complete functions are
		implemented for a given gesture

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureNull	proc	near
	.enter
	.leave
	ret
HandleGestureNull	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextHandlesInkReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query if object handles ink.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextHandlesInkReply	proc	far
	class	VisTextClass	
	.enter
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	exit
	push	ax
	mov	ax, ATTR_VIS_TEXT_DOES_NOT_ACCEPT_INK
	call	ObjVarFindData
	pop	ax
	jc	exit
	call	VisObjectHandlesInkReply
exit:
	.leave
	ret
VisTextHandlesInkReply	endp

PenCode	ends
