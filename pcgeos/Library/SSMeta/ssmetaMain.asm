
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ssmetaMain.asm

AUTHOR:		Cheng, 8/92

ROUTINES:
	Name			Description
	----			-----------
	SSMetaSetScrapSize
	SSMetaDataArrayLocateOrAddEntry
	SSMetaDataArrayAddEntry
	InitEntry
	AddEntryLocatePosition
	AddEntryCheckInsertionPoint
	SSMetaGetScrapSize
	SSMetaDataArrayGetNumEntries
	SSMetaDataArrayResetEntryPointer
	SSMetaDataArrayGetFirstEntry
	SSMetaDataArrayGetNextEntry
	SSMetaDataArrayGetEntryByToken
	SSMetaDataArrayGetEntryByCoord
	SSMetaDataArrayGetNthEntry
	SSMetaDataArrayUnlock
	UnlockIfEntryNotFound
	SSMetaStrucInitEntryDataFields
	GetDataArrayEntryPtrOffset
	ECCheckDataArrayRecord
	ECCheckSSMetaEntry
	ECCheckSSMetaStruc
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial revision

DESCRIPTION:
	$Id: ssmetaMain.asm,v 1.2 98/07/03 07:31:58 joon Exp $

-------------------------------------------------------------------------------@


SSMetaCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaSetScrapSize

DESCRIPTION:	Stuff the size of the scrap into the header and stack frame.

CALLED BY:	GLOBAL ()

PASS:		dx:bp - SSMetaStruc
		ax - number of rows
		cx - number of columns

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaSetScrapSize	proc	far	uses	ax,bx,ds,es
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	mov	es:[bp].SSMDAS_scrapRows, ax
	mov	es:[bp].SSMDAS_scrapCols, cx

	call	LockHeaderBlk		; bx <- mem han, ds <- seg
	mov	ds:SSMHB_scrapRows, ax
	mov	ds:SSMHB_scrapCols, cx
	call	SSMetaVMDirty
	call	SSMetaVMUnlock

	.leave
	ret
SSMetaSetScrapSize	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayLocateOrAddEntry

DESCRIPTION:	Check to see if an entry exists for the token in the data
		array. If it does not, an entry will be added.
		(This routine only applies to data arrays that are maintained in
		token order. Also, there is not check made to ensure that the
		contents of the entry are the same).

CALLED BY:	GLOBAL ()

PASS:		ax - token
		cx - size of SSMetaEntry data
		ds:si - address of SSMetaEntry data
		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		carry clear if entry exists
		carry set if entry added

DESTROYED:	nothing

REGISTER/STACK USAGE:

es:[bp] CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayLocateOrAddEntry	proc	far	uses	ax,cx,si,ds,es
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	mov	es:[bp].SSMDAS_entryDataAddr.segment, ds
	mov	es:[bp].SSMDAS_entryDataAddr.offset, si
	mov	es:[bp].SSMDAS_entryDataSize, cx

	;
	; locate entry
	;
	call	SSMetaDataArrayGetEntryByToken		; changes cx,ds,si
	jnc	found				; done if found

	;
	; entry not found, add it
	;
	lds	si, es:[bp].SSMDAS_entryDataAddr
	mov	cx, es:[bp].SSMDAS_entryDataSize
	mov	al, SSMAEF_ADD_IN_TOKEN_ORDER
	call	SSMetaDataArrayAddEntry
	stc					; flag entry added

done:
	.leave
	ret

found:
	call	SSMetaDataArrayUnlock		; Unlock the block
	clc					; signal: found
	jmp	done
SSMetaDataArrayLocateOrAddEntry	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayAddEntry

DESCRIPTION:	Given a data array specifier and entry data, add a SSMetaEntry
		to the data array. The entry will be inserted in row order.

CALLED BY:	GLOBAL ()

PASS:		al - SSMetaAddEntryFlags
		    SSMAEF_ADD_IN_TOKEN_ORDER (ascending token order)
		    SSMAEF_ADD_IN_ROW_ORDER (row, then column order)
		    SSMAEF_ENTRY_POS_PASSED (entry position is passed)
		    SSMETA_ADD_TO_END (tack on to end of array)
		cx - size of SSMetaEntry data
		ds:si - address of SSMetaEntry data
		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    SSMDAS_row (if any) **
		    SSMDAS_col (if any) **
		    SSMDAS_token (if any) **
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayAddEntry	proc	far	uses	ax,bx,cx,dx,di,si,ds,es
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	mov	es:[bp].SSMDAS_flag, al
	mov	es:[bp].SSMDAS_entryDataAddr.segment, ds
	mov	es:[bp].SSMDAS_entryDataAddr.offset, si
	mov	es:[bp].SSMDAS_entryDataSize, cx

	call	GetDataArrayRecord		; ds:si <- SSMetaDataArrayRecord
						; bx <- mem han of locked blk
EC<	call	ECCheckDataArrayRecord >

	;-----------------------------------------------------------------------
	; initialize a SSMetaEntry

	call	InitEntry			; cx <- size

	;-----------------------------------------------------------------------
	; look for position

EC<	call	ECCheckSSMetaStruc >
EC<	call	ECCheckDataArrayRecord >

	mov	bx, es:[bp].SSMDAS_vmFileHan
	mov	ax, ds:[si].SSMDAR_numEntries
	mov	es:[bp].SSMDAS_numEntries, ax
	mov	di, ds:[si].SSMDAR_dataArrayLinkOffset	; di <- offset
	mov	di, ds:[di].high		; deref to get blk han

	push	bp,si
	cmp	ax, 0				; no entries?
	je	doAppend

	cmp	es:[bp].SSMDAS_flag, SSMETA_ADD_TO_END
	je	doAppend

	call	AddEntryLocatePosition		; dx:ax <- position
	jc	doAppend

EC<	call	ECCheckSSMetaStruc >
	clr	si
	mov	bp, es:[bp].SSMDAS_newEntrySeg	; bp:si <- entry ptr
EC<	push	ds >
EC<	mov	ds, bp >
EC<	cmp	ds:[si].SSME_signature, SSMETA_DATA_ENTRY_SIG >
EC<	ERROR_NE SSMETA_ASSERTION_FAILED >
EC<	pop	ds >
	call	HugeArrayInsert
	jmp	short doneAdding
doAppend:
EC<	call	ECCheckSSMetaStruc >
	clr	si
	mov	bp, es:[bp].SSMDAS_newEntrySeg	; bp:si <- entry ptr
EC<	push	ds >
EC<	mov	ds, bp >
EC<	cmp	ds:[si].SSME_signature, SSMETA_DATA_ENTRY_SIG >
EC<	ERROR_NE SSMETA_ASSERTION_FAILED >
EC<	pop	ds >
	call	HugeArrayAppend			; dx:ax <- element number
doneAdding:
	pop	bp,si

	;-----------------------------------------------------------------------
	; inc entry count
	; clean up

EC<	call	ECCheckSSMetaStruc >
EC<	call	ECCheckDataArrayRecord >

	inc	ds:[si].SSMDAR_numEntries

	mov	bx, es:[bp].SSMDAS_entryMemHan	; free entry
	call	MemFree

	mov	bx, es:[bp].SSMDAS_hdrBlkMemHan	; unlock header
	call	SSMetaVMUnlock

	.leave
	ret
SSMetaDataArrayAddEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitEntry

DESCRIPTION:	Allocate and initialize a SSMetaEntry

CALLED BY:	INTERNAL (SSMetaDataArrayAddEntry)

PASS:		es:bp - SSMetaStruc with:
		    SSMDAS_entryDataAddr
		    SSMDAS_entryDataSize

RETURN:		cx - entry size
		SSMDAS_entryMemHan
		SSMDAS_newEntrySeg
		SSMDAS_entrySize

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

InitEntry	proc	near	uses	ax,bx,ds,si,es,di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, es:[bp].SSMDAS_entryDataAddr		>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif

EC <	call	ECCheckSSMetaStruc 				>

	segmov	ds, es, si			; ds:si <- ssmeta struc
	mov	si, bp

	mov	ax, ds:[si].SSMDAS_entryDataSize
	add	ax, size SSMetaEntry		; include size of entry header
	push	ax

PrintMessage< this MemAlloc is passed HAF_NO_ERR and should be changed>
	mov	cx, mask HF_SWAPABLE or ((mask HAF_LOCK or mask HAF_NO_ERR) shl 8)
	call	MemAlloc			; bx <- handle

	mov	es, ax				; es:di <- entry to insert
	clr	di
	mov	ds:[si].SSMDAS_entryMemHan, bx
	mov	ds:[si].SSMDAS_newEntrySeg, es

	;
	; initialize SSMetaEntry
	;
	mov	es:[di].SSME_signature, SSMETA_DATA_ENTRY_SIG

	mov	ax, ds:[si].SSMDAS_entryDataSize	; copy entry data size
	mov	es:[di].SSME_entryDataSize, ax

	mov	ax, ds:[si].SSMDAS_token	; copy token
	mov	es:[di].SSME_token, ax

	mov	ax, ds:[si].SSMDAS_row		; copy row
	mov	es:[di].SSME_coordRow, ax

	mov	ax, ds:[si].SSMDAS_col		; copy col
	mov	es:[di].SSME_coordCol, ax

	;
	; copy SSMetaEntry data
	;
	mov	cx, ds:[si].SSMDAS_entryDataSize
	lds	si, ds:[si].SSMDAS_entryDataAddr	; ds:si <- entry data
	mov	di, offset SSME_dataPortion	; es:di <- data portion
	rep	movsb				; copy data over

	pop	cx
	.leave
	ret
InitEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AddEntryLocatePosition

DESCRIPTION:	Locate the position to perform the insertion of the data
		array entry.

CALLED BY:	INTERNAL (SSMetaDataArrayAddEntry)

PASS:		es:bp - SSMetaStruc
		bx - VM file handle
		di - VM block handle for data array

RETURN:		carry set to append
		carry clear to insert
		    dx:ax - element number to insert entry before

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

AddEntryLocatePosition	proc	near	uses	bx,cx,di,ds,si
	.enter 	inherit near
EC<	call	ECCheckSSMetaStruc >

	cmp     es:[bp].SSMDAS_flag, SSMAEF_ENTRY_POS_PASSED
	je	posPassed
	
	call	AddEntryBinarySearch		; nothing locked so we exit
	jmp	exit
	
posPassed:
	; OPTIMIZATION ted - 3/8/93
	; SSMDAS_entryPos is passed in by the caller

	mov	dx, es:[bp].SSMDAS_entryPos.high
	mov	ax, es:[bp].SSMDAS_entryPos.low
	call	HugeArrayLock			; ds:si <- ptr, changes ax,cx,dx
EC<	tst	ax >				; ds:si should not be invalid
EC<	ERROR_E SSMETA_ASSERTION_FAILED >	; fatal error if so

	;
	; loop to locate entry
	;
locateLoop:
	call	AddEntryCheckInsertionPoint	; destroys ax
	jnc	flagInsert

	call	HugeArrayNext			; ds:si <- ptr
	tst	ax				; next entry present?
	je	flagAppend			; branch if not

EC<	call	ECCheckSSMetaStruc >
	inc	es:[bp].SSMDAS_entryPos.low	; else update entry count
	jnc	locateLoop
	inc	es:[bp].SSMDAS_entryPos.high
	jmp	short locateLoop

flagAppend:
	stc
	jmp	short done

flagInsert:
EC<	call	ECCheckSSMetaStruc >
	mov	dx, es:[bp].SSMDAS_entryPos.high
	mov	ax, es:[bp].SSMDAS_entryPos.low
	clc

done:
	call	HugeArrayUnlock

exit:
	.leave
	ret
AddEntryLocatePosition	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AddEntryCheckInsertionPoint

DESCRIPTION:	Check to see if the current SSMetaEntry is where we should
		perform an insertion.

CALLED BY:	INTERNAL (AddEntryLocatePosition)

PASS:		es:bp - SSMetaStruc with:
		    SSMDAS_flag
		    SSMDAS_token if (SSMDAS_flag==SSMAEF_ADD_IN_TOKEN_ORDER)
		    SSMDAS_row, SSMDAS_col if
			(SSMDAS_flag==SSMAEF_ADD_IN_ROW_ORDER or 
				SSMAEF_ENTRY_POS_PASSED)
		ds:si - SSMetaEntry

RETURN:		carry clear if insertion point found
		carry set otherwise

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

AddEntryCheckInsertionPoint	proc	near
	.enter
EC<	call	ECCheckSSMetaStruc >
EC<	call	ECCheckSSMetaEntry >

EC<	cmp	es:[bp].SSMDAS_flag, SSMAEF_ADD_IN_TOKEN_ORDER >
EC<	je	flagOK >
EC<	cmp	es:[bp].SSMDAS_flag, SSMAEF_ENTRY_POS_PASSED >
EC<	je	flagOK >
EC<	cmp	es:[bp].SSMDAS_flag, SSMAEF_ADD_IN_ROW_ORDER >
EC<	ERROR_NE SSMETA_ASSERTION_FAILED >
EC< flagOK: >

	cmp	es:[bp].SSMDAS_flag, SSMAEF_ADD_IN_TOKEN_ORDER
	jne	checkRowOrder

	mov	ax, es:[bp].SSMDAS_token	; get new entry's token
	cmp	ax, ds:[si].SSME_token		; compare it with entry token
	clc
	jl	done				; branch if position found
	jmp	short notFound

checkRowOrder:
	mov	ax, es:[bp].SSMDAS_row		; get new entry's row
	cmp	ax, ds:[si].SSME_coordRow	; compare with cur entry's row
	clc
	jl	done				; branch if position found
	jg	notFound

	mov	ax, es:[bp].SSMDAS_col		; get new entry's col
	cmp	ax, ds:[si].SSME_coordCol	; compare with cur entry's col
	clc
	jl	done				; branch if position found

notFound:
	stc

done:
	.leave
	ret
AddEntryCheckInsertionPoint	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AddEntryBinarySearch

DESCRIPTION:	

CALLED BY:	INTERNAL (AddEntryLocatePosition)

PASS:		es:bp - SSMetaStruc
		bx - VM file handle
		di - VM block handle for data array

RETURN:		carry set to append
		carry clear to insert
		    dx:ax - element number to insert entry before

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

AddEntryBinarySearch	proc	near	uses	cx,ds,si
	.enter
EC<	call	ECCheckSSMetaStruc >

	;
	; init indices
	;
	clr	dx,ax
	mov	es:[bp].SSMDAS_entryPos.high, dx
	mov	es:[bp].SSMDAS_entryPos.low, ax

	mov	es:[bp].SSMDAS_startIndex, ax
	mov	es:[bp].SSMDAS_checkIndex, ax
	mov	es:[bp].SSMDAS_entryPos.high, ax
	mov	es:[bp].SSMDAS_entryPos.low, ax

	mov	ax, es:[bp].SSMDAS_numEntries
	tst	ax				; zero entries?
	stc					; assume so
	LONG je	exit				; append if assumption correct
	dec	ax				; else make zero based
	mov	es:[bp].SSMDAS_endIndex, ax	; and use as end index

EC<	cmp	ax, es:[bp].SSMDAS_startIndex >
EC<	ERROR_L	SSMETA_ASSERTION_FAILED >

	;
	; possible optimization is to check last entry in chain
	; insertion point found if search key is larger (=> do append)
	;

doSearch:
	;
	; do while startIndex <= endIndex
	;
	mov	ax, es:[bp].SSMDAS_endIndex	; ax <- endIndex
	cmp	ax, es:[bp].SSMDAS_startIndex
	jge	continueSearch			; done if endIndex < startIndex

	;
	; search failed
	;
	mov	ax, dx				; ax <- old check index
	jmp	short done

continueSearch:
	;
	; compute checkIndex
	;
	add	ax, es:[bp].SSMDAS_startIndex
	shr	ax, 1				; check <- (start + end) / 2
	mov	es:[bp].SSMDAS_checkIndex, ax
	mov	es:[bp].SSMDAS_entryPos.low, ax	; zero based offset

EC<	cmp	ax, es:[bp].SSMDAS_startIndex >
EC<	ERROR_B	SSMETA_ASSERTION_FAILED >
EC<	cmp	ax, es:[bp].SSMDAS_endIndex >
EC<	ERROR_A	SSMETA_ASSERTION_FAILED >

	;
	; lock entry at checkIndex
	;
	push	ax				; save checkIndex
	clr	dx
	call	HugeArrayLock			; ds:si <- item
EC<	tst	ax >				; ds:si should not be invalid
EC<	ERROR_E SSMETA_ASSERTION_FAILED >	; fatal error if so
	pop	ax				; retrieve checkIndex

	;
	; check checkIndex entry
	; MetaStruc is what we're searching for, MetaEntry is what's in
	; checkIndex's location
	;
	call	AddEntryBinarySearchCheckIndex	; SSMetaStruc - SSMetaEntry
	call	HugeArrayUnlock			; flags are unaffected
	jg	tooSmall
	jl	tooLarge

	;
	; found duplicate entry
	; return entry position
	;
	mov	es:[bp].SSMDAS_compFlag, CHECK_INDEX_EQUAL
	jmp	short done

tooSmall:
	;
	; checkIndex entry is too small
	; startIndex <- checkIndex + 1
	;
	mov	es:[bp].SSMDAS_compFlag, CHECK_INDEX_TOO_SMALL
	mov	dx, ax				; save old check index
	inc	ax				; inc checkIndex
	mov	es:[bp].SSMDAS_startIndex, ax
	jmp	short doSearch

tooLarge:
	;
	; checkIndex entry is too large
	; endIndex <- checkIndex - 1
	;
	mov	es:[bp].SSMDAS_compFlag, CHECK_INDEX_TOO_LARGE
	mov	dx, ax				; save old check index
	dec	ax				; dec checkIndex
	mov	es:[bp].SSMDAS_endIndex, ax
	jmp	short doSearch

done:
	;
	; ax == check index before failure was determined
	; if CHECK_INDEX_TOO_SMALL and checkIndex is last entry then append
	; else insert
	;
	cmp	es:[bp].SSMDAS_compFlag, CHECK_INDEX_TOO_SMALL
	clc					; flag insert
	jne	exit

	inc	ax				; make checkIndex 1 based
	cmp	ax, es:[bp].SSMDAS_numEntries
	stc					; assume append
	je	exit				; assumption correct?

	clc					; indicate insert

exit:
	mov	dx, 0

	.leave
	ret
AddEntryBinarySearch	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AddEntryBinarySearchCheckIndex

DESCRIPTION:	

CALLED BY:	INTERNAL (AddEntryBinarySearch)

PASS:		es:bp - SSMetaStruc with:
		    SSMDAS_flag
		    SSMDAS_token if (SSMDAS_flag==SSMAEF_ADD_IN_TOKEN_ORDER)
		    SSMDAS_row, SSMDAS_col if
			(SSMDAS_flag==SSMAEF_ADD_IN_ROW_ORDER or 
				SSMAEF_ENTRY_POS_PASSED)
		ds:si - SSMetaEntry

RETURN:		flags set according to where the entry at checkIndex stands
		in relation to desired item, ie. you can do a ja, jb, or je

		comparison done by subtracting MetaEntry's tokens from those
		in MetaStruc, ie.
		MetaStruc - MetaEntry

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

AddEntryBinarySearchCheckIndex	proc	near	uses	ax
	.enter
EC<	call	ECCheckSSMetaStruc >		; check es:bp
EC<	call	ECCheckSSMetaEntry >		; check ds:si

EC<	cmp	es:[bp].SSMDAS_flag, SSMAEF_ADD_IN_TOKEN_ORDER >
EC<	je	flagOK >
EC<	cmp	es:[bp].SSMDAS_flag, SSMAEF_ADD_IN_ROW_ORDER >
EC<	ERROR_NE SSMETA_ASSERTION_FAILED >
EC< flagOK: >

	cmp	es:[bp].SSMDAS_flag, SSMAEF_ADD_IN_TOKEN_ORDER
	jne	checkRowOrder

	;
	; SSMDAS_flag == SSMAEF_ADD_IN_TOKEN_ORDER
	;
	mov	ax, es:[bp].SSMDAS_token	; get new entry's token
	cmp	ax, ds:[si].SSME_token		; compare it with entry token
	jmp	short done			; flags are set, done

checkRowOrder:
	;
	; SSMDAS_flag == SSMAEF_ADD_IN_ROW_ORDER
	; we're sorting by column and then row
	;
	mov	ax, es:[bp].SSMDAS_row		; get new entry's row
	cmp	ax, ds:[si].SSME_coordRow	; compare with cur entry's row
	jne	done

	mov	ax, es:[bp].SSMDAS_col		; get new entry's col
	cmp	ax, ds:[si].SSME_coordCol	; compare with cur entry's col

done:
	.leave
	ret
AddEntryBinarySearchCheckIndex	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaGetScrapSize

DESCRIPTION:	Return the size of the scrap.

CALLED BY:	GLOBAL ()

PASS:		dx:bp - SSMetaStruc

RETURN:		ax - number of rows
		cx - number of columns

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaGetScrapSize	proc	far	uses	es
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	mov	ax, es:[bp].SSMDAS_scrapRows
	mov	cx, es:[bp].SSMDAS_scrapCols

	.leave
	ret
SSMetaGetScrapSize	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayGetNumEntries

DESCRIPTION:	Given a data array specifier, get the number of entries in the
		data array.

CALLED BY:	GLOBAL ()

PASS:		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		ax - number of entries in the data array

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayGetNumEntries	proc	far	uses	bx,si,ds,es
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	call	GetDataArrayRecord		; ds:si <- SSMetaDataArrayRecord
						; bx <- locked hdr blk mem han
EC<	call	ECCheckDataArrayRecord >
	mov	ax, ds:[si].SSMDAR_numEntries	; ax <- num entries

	call	SSMetaVMUnlock			; unlock data array header

	.leave
	ret
SSMetaDataArrayGetNumEntries	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayResetEntryPointer

DESCRIPTION:	Given a data array specifier, get the number of entries in the
		data array.

CALLED BY:	GLOBAL ()

PASS:		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		entry pointer reset

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayResetEntryPointer	proc	far	uses	ax,es,di
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	call	GetDataArrayEntryPtrOffset	; di <- table offset

	clr	ax
	mov	es:[bp][di].SSMED_ptr.segment, ax
	mov	es:[bp][di].SSMED_ptr.offset, ax
	mov	es:[bp][di].SSMED_size, ax

	.leave
	ret
SSMetaDataArrayResetEntryPointer	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayGetFirstEntry

DESCRIPTION:	Given a data array specifier, get the first data entry in the
		data array. Entries will be returned as a pointer into a locked
		block.

		IMPORTANT: Since an address to a locked block is returned,
		you will need to call SSMetaDataArrayUnlock when you're
		done with the data array.
		(ie. You may call any number of data array access routines;
		just remember to call SSMetaDataArrayUnlock once when you are
		done with the data array.)

CALLED BY:	GLOBAL ()

PASS:		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    SSMDAS_entry **
			ptr to SSMetaDataEntry, 0:0 to start (ie. to get first)
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		carry clear if entry exists
		    SSMDAS_entry - ptr to SSMetaDataEntry
		    SSMDAS_entryDataSize
		    ds:si - pointer to SSMetaDataEntry
		    cx - size of entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayGetFirstEntry	proc	far	uses	es
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	call	SSMetaDataArrayResetEntryPointer
	call	SSMetaDataArrayGetNextEntry

	.leave
	ret
SSMetaDataArrayGetFirstEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayGetNextEntry

DESCRIPTION:	Given a data array specifier, get the next (possibly the
		first) entry.

		IMPORTANT: Since an address to a locked block is returned,
		you will need to call SSMetaDataArrayUnlock when you're
		done with the data array.
		(ie. You may call any number of data array access routines;
		just remember to call SSMetaDataArrayUnlock once when you are
		done with the data array.)

CALLED BY:	GLOBAL ()

PASS:		dx:bp - SSMetaStruc
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    SSMDAS_entry **
			ptr to SSMetaDataEntry, 0:0 to start (ie. to get first)
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		carry clear if next entry exists
		    SSMDAS_entry - ptr to SSMetaDataEntry
		    SSMDAS_entryDataSize
		    ds:si - pointer to next SSMetaEntry
		    cx - size of entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayGetNextEntry	proc	far	uses	ax,bx,dx,es,di
	.enter

	mov	es, dx			; es:bp <- SSMetaStruc
EC<	call	ECCheckSSMetaStruc >

	call	GetDataArrayEntryPtrOffset	; di <- offset to ptr

	cmp	es:[bp][di].SSMED_ptr.segment, 0
	jne	notFirst

	;-----------------------------------------------------------------------
	; retrieving the first entry

	call	GetDataArrayRecord	; ds:si <- SSMetaDataArrayRecord
					; bx <- mem han of locked blk
EC<	call	ECCheckDataArrayRecord >

	clr	dx,ax			; specify first entry
	call	LockDataArrayEntry	; ds:si <- entry
					; cx <- entry size
	call	SSMetaVMUnlock		; unlock the header block
	jmp	short done

notFirst:
	;-----------------------------------------------------------------------
	; not retrieving the first entry

	lds	si, es:[bp][di].SSMED_ptr
	call	HugeArrayNext
	mov	cx, dx			; cx <- size

	tst	ax			; any next entry?
	clc				; assume so
	jne	done			; branch if assumption correct
	stc				; else flag no next entry

done:
	call	SSMetaStrucInitEntryDataFields

	.leave
	ret
SSMetaDataArrayGetNextEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayGetEntryByToken

DESCRIPTION:	Given a data array specifier and a token, locate the entry.

		IMPORTANT: You will need to call SSMetaDataArrayUnlock when
		you're done with the data array entry.

CALLED BY:	GLOBAL ()

PASS:		ax - token
		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		carry clear if found
		    ds:si - pointer to SSMetaEntry containing token
		    cx - size of entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayGetEntryByToken	proc	far	uses	es
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	call	SSMetaDataArrayGetFirstEntry	; ds:si <- entry
	jc	done				; exit if no entry present

locateLoop:
	cmp	ax, ds:[si].SSME_token
	jl	notPresent			; done if less than current
	clc
	je	done

	call	SSMetaDataArrayGetNextEntry
	jnc	locateLoop

notPresent:
	stc

done:
	call	UnlockIfEntryNotFound
	call	SSMetaStrucInitEntryDataFields

	.leave
	ret
SSMetaDataArrayGetEntryByToken	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayGetEntryByCoord

DESCRIPTION:	Given a data array specifier and a set of coordinates, locate
		the entry.

		IMPORTANT: You will need to call SSMetaDataArrayUnlock when
		you're done with the data array entry.

CALLED BY:	GLOBAL ()

PASS:		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    SSMDAS_row **
		    SSMDAS_col **
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		carry clear if found
		    ds:si - pointer to SSMetaEntry containing coord
		    cx - size of entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayGetEntryByCoord	proc	far	uses	ax,bx,es
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	call	SSMetaDataArrayGetFirstEntry	; ds:si <- entry
	jc	done				; exit if no entry present

	mov	ax, es:[bp].SSMDAS_row
	mov	bx, es:[bp].SSMDAS_col
locateLoop:
	cmp	ax, ds:[si].SSME_coordRow
	jl	notPresent
	jg	getNext

	cmp	bx, ds:[si].SSME_coordCol
	jl	notPresent
	clc
	je	done

getNext:
	call	SSMetaDataArrayGetNextEntry	; ds:si <- entry
	jnc	locateLoop			; loop if entry exists

notPresent:
	stc

done:
	call	UnlockIfEntryNotFound
	call	SSMetaStrucInitEntryDataFields

	.leave
	ret
SSMetaDataArrayGetEntryByCoord	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayGetNthEntry

DESCRIPTION:	Given a data array specifier and N, return the Nth entry.

		IMPORTANT: You will need to call SSMetaDataArrayUnlock when
		you're done with the data array entry.

CALLED BY:	GLOBAL ()

PASS:		ax - N
		dx:bp - SSMetaStruc with these fields initialized:
		    SSMDAS_vmFileHan *
		    SSMDAS_hdrBlkVMHan *
		    SSMDAS_dataArraySpecifier **
		    * = initilization done by SSMetaGetClipboardTransferItem
		    ** = caller initializes this

RETURN:		carry clear if found
		    ds:si - pointer to next SSMetaEntry
		    cx - size of entry
		carry set otherwise

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayGetNthEntry	proc	far	uses	ax,bx,dx,di,bp,es
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	call	GetDataArrayRecord	; ds:si <- SSMetaDataArrayRecord
					; bx <- mem han of locked blk
EC<	call	ECCheckDataArrayRecord >
	clr	dx
	call	LockDataArrayEntry	; ds:si <- entry
					; cx <- entry size
	call	SSMetaVMUnlock		; unlock SSMetaHeaderBlock

	call	SSMetaStrucInitEntryDataFields
	.leave
	ret
SSMetaDataArrayGetNthEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaDataArrayUnlock

DESCRIPTION:	Unlock the data array specified. Call this after you're done
		with any call to SSMetaDataArrayGetFirstEntry,
		SSMetaDataArrayGetNextEntry, SSMetaDataArrayGetEntryByToken,
		SSMetaDataArrayGetEntryByCoord, or SSMetaDataArrayGetNthEntry.

CALLED BY:	GLOBAL ()

PASS:		dx:bp - SSMetaStruc with this field initialized:
		    SSMDAS_dataArraySpecifier **
		    ** = caller initializes this

RETURN:		nothing

DESTROYED:	nothing, flags remain intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaDataArrayUnlock	proc	far	uses	ax, ds,es,di
	pushf
	.enter

	mov	es, dx
EC<	call	ECCheckSSMetaStruc >

	call	GetDataArrayEntryPtrOffset	; di <- offset
	mov	ax, es:[bp][di].SSMED_ptr.segment
	tst	ax
	jz	afterUnlock

	mov	ds, ax
	call	HugeArrayUnlock
	clr	ax
	mov	es:[bp][di].SSMED_ptr.segment, ax

afterUnlock:
	mov	es:[bp][di].SSMED_ptr.offset, ax
	mov	es:[bp][di].SSMED_size, ax

done::
	.leave
	popf
	ret
SSMetaDataArrayUnlock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UnlockIfEntryNotFound

DESCRIPTION:	Unlock the huge array if the end result of the Get... routine
		did not locate the desired entry.

CALLED BY:	INTERNAL
		(SSMetaDataArrayGetEntryByToken, SSMetaDataArrayGetEntryByCoord)

PASS:		carry clear if entry was found (ie. don't unlock huge array)
		carry set if entry not located, unlock huge array
		es:bp - SSMetaStruc

RETURN:		nothing

DESTROYED:	nothing, including flags

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

UnlockIfEntryNotFound	proc	near
	.enter

EC<	call	ECCheckSSMetaStruc >
	jnc	exit			; done if entry found
	
	push	ds,di
	call	GetDataArrayEntryPtrOffset	; di <- offset into SSMetaStruc
	cmp	es:[bp][di].SSMED_ptr.segment, 0
	je	done

	mov	ds, es:[bp][di].SSMED_ptr.segment
	call	HugeArrayUnlock

done:
	pop	ds,di

	stc				; restore carry flag

exit:
	.leave
	ret
UnlockIfEntryNotFound	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSMetaStrucInitEntryDataFields

DESCRIPTION:	Initializes the SSMetaEntry fields in the
		SSMetaStruc.

CALLED BY:	INTERNAL
		(SSMetaDataArrayGetNextEntry,
		SSMetaDataArrayGetEntryByToken,
		SSMetaDataArrayGetEntryByCoord,
		SSMetaDataArrayGetNthEntry)

PASS:		carry clear to proceed with routine
		    es:bp - SSMetaStruc
		    ds:si - SSMetaDataArrayRecord
		    cx - SSMetaDataArrayRecord size

RETURN:		SSMetaStruc with these fields initialized:
		    SSMDAS_entry
		    SSMDAS_entrySize

DESTROYED:	nothing, flags remain intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SSMetaStrucInitEntryDataFields	proc	near
	.enter
EC<	call	ECCheckSSMetaStruc >
	jc	done

	push	di
	call	GetDataArrayEntryPtrOffset	; di <- offset into SSMetaStruc
	mov	es:[bp][di].SSMED_ptr.segment, ds
	mov	es:[bp][di].SSMED_ptr.offset, si
	mov	es:[bp][di].SSMED_size, cx
	pop	di

	clc					; restore carry flag

done:
	.leave
	ret
SSMetaStrucInitEntryDataFields	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetDataArrayEntryPtrOffset

DESCRIPTION:	Compute the offset into the SSMetaStruc to the ptr to
		the last accessed entry for the specified data array.
		(The SSMDAS_dataArrayEntryTable tracks the position
		of the last accessed entry in each of the data arrays).

CALLED BY:	INTERNAL ()

PASS:		es:bp - SSMetaStruc

RETURN:		di - offset into SSMetaStruc

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

GetDataArrayEntryPtrOffset	proc	near	uses	ax
	.enter

EC<	call	ECCheckSSMetaStruc >

	mov	al, es:[bp].SSMDAS_dataArraySpecifier
	clr	ah
	shl	ax, 1
	mov	di, ax				; di <- orig ax * 2
	shl	ax, 1				; ax <- ax * 4
	add	di, ax				; di <- orig ax * 6
	add	di, offset SSMDAS_dataArrayEntryTable

	.leave
	ret
GetDataArrayEntryPtrOffset	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ECCheckDataArrayRecord

DESCRIPTION:	Error checking routine.

CALLED BY:	INTERNAL ()

PASS:		ds:si - SSMetaDataArrayRecord

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing, flags remain intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckDataArrayRecord	proc	near
	pushf

	cmp	ds:[si].SSMDAR_signature, SSMETA_DATA_ARRAY_RECORD_SIG
	ERROR_NE SSMETA_BAD_DATA_ARRAY_RECORD

	popf
	ret
ECCheckDataArrayRecord	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ECCheckSSMetaEntry

DESCRIPTION:	Error checking routine.

CALLED BY:	INTERNAL ()

PASS:		ds:si - SSMetaEntry

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckSSMetaEntry	proc	near
	pushf

	cmp	ds:[si].SSME_signature, SSMETA_DATA_ENTRY_SIG
	ERROR_NE SSMETA_BAD_ENTRY

	popf
	ret
ECCheckSSMetaEntry	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ECCheckSSMetaStruc

DESCRIPTION:	Error checking routine.

CALLED BY:	INTERNAL ()

PASS:		es:bp - SSMetaStruc

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing, flags remain intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@


if	ERROR_CHECK

ECCheckSSMetaStruc	proc	near
	.enter
	pushf

	cmp	es:[bp].SSMDAS_signature, SSMETA_STRUC_SIG
	ERROR_NE SSMETA_BAD_SSMETA_STRUC

	popf
	.leave
	ret
ECCheckSSMetaStruc	endp

endif

SSMetaCode	ends
