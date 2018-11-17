
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	DataChainGetNextEntry
	DataChainInitStackFrame
	DataChainLockBlock
	DataChainUnlockBlock
	ImpexVMAlloc
	ImpexVMLock
	ImpexVMUnlock
	DataChainAddEntry
	DataChainAllocDataBlock
	DataChainLinkNewDataBlock
	ECCheckDataBlockEntry
	ECCheckDataBlock
	ECCheckDataChainRecord
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
		
	$Id: sharedDataChain.asm,v 1.1 97/04/07 11:42:16 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DataChainGetNextEntry

DESCRIPTION:	Retrieve the next data block entry into the given buffer.
		The buffer should be of type DataBlockEntry and a buffer
		with sufficient space should follow this DataBlockEntry
		for the storage of the data.

CALLED BY:	EXTERNAL ()

PASS:		ss:bx - DataChainRecord with the following fields filled in:
		    DCR_vmFileHan
		    DCR_curEntryMagicNum (dword) - Pass 0:0 to get the first
			entry, leave it alone for all subsequent calls.
		    (Implementation note: hi word = VM blk handle, lo = offset)
		es:di - DataBlockEntry buffer that is of sufficient size

RETURN:		carry clear if next entry exists
		    cx -  size of the DataBlockEntry
		    buffer filled with the data block entry
		    DCR_curEntryMagicNum - magic number of the current entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	DCSF_flag will be used to indicate if the desired block is the first
	    0 if not first block, -1 if so

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

DataChainGetNextEntry	proc	far	uses	ax,ds,di,si
	DC_local	local	DataChainStackFrame
	.enter

	;-----------------------------------------------------------------------
	; initialize the stack frame and lock the data block

	call	DataChainInitStackFrame
	mov	DC_local.DCSF_flag, 0		; assume not first block

	mov	ax, ss:[bx].DCR_curEntryMagicNum.high
	tst	ax				; get first entry?
	jne	notFirstEntry

	;
	; caller wants the first entry in the data chain
	;
	dec	DC_local.DCSF_flag		; indicate first block desired
	mov	ss:[bx].DCR_curEntryMagicNum.low, size DataBlockHeader
	mov	ax, ss:[bx].DCR_chain.DCTR_firstBlkVMHan

	tst	ax				; anything?
	stc					; assume not
	je	exit				; exit if assumption correct

notFirstEntry:
	mov	DC_local.DCSF_curBlkVMHan, ax
	call	DataChainLockBlock

;EC<	push	es >
;EC<	mov	es, DC_local.DCSF_curBlkSegAddr >
;EC<	call	ECCheckDataBlock >
;EC<	pop	es >

	mov	ds, DC_local.DCSF_curBlkSegAddr	; ds:si <- entry
	mov	si, ss:[bx].DCR_curEntryMagicNum.low
EC<	call	ECCheckDataBlockEntry >		; check current entry

	cmp	DC_local.DCSF_flag, 0		; first block desired?
	jne	found				; branch if so

	;-----------------------------------------------------------------------
	; locate the next data block entry

	mov	ax, ds:[si].DBE_entrySize
	add	ax, size DataBlockEntry		; ax <- size of this entry
	add	si, ax				; si points past this entry

	cmp	si, ds:DBH_blockSize		; past last entry?
	jb	found				; branch if not

	;-----------------------------------------------------------------------
	; need to go to next data block

	mov	ax, ds:DBH_nextBlkVMHan + offset VMCL_next ; ax <- VM blk han of next blk
	tst	ax				; anything?
	stc					; assume not
	je	done				; exit if assumption correct

	call	DataChainUnlockBlock		; else unlock current data blk
	mov	DC_local.DCSF_curBlkVMHan, ax	; stuff VM blk han of next blk
	call	DataChainLockBlock
	mov	ds, DC_local.DCSF_curBlkSegAddr
	mov	si, size DataBlockHeader

found:
	;-----------------------------------------------------------------------
	; store the new magic numbers and copy the entry data

	mov	ax, DC_local.DCSF_curBlkVMHan
	mov	ss:[bx].DCR_curEntryMagicNum.high, ax
	mov	ss:[bx].DCR_curEntryMagicNum.low, si

EC<	call	ECCheckDataBlockEntry >		; check entry

	mov	cx, ds:[si].DBE_entrySize
	add	cx, size DataBlockEntry		; cx <- size of this entry

	push	cx
	rep	movsb
	pop	cx
	clc

done:
	call	DataChainUnlockBlock

exit:
	.leave
	ret
DataChainGetNextEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DataChainInitStackFrame

DESCRIPTION:	Initializes the DataChainStackFrame with the info given in
		the DataChainRecord.

CALLED BY:	INTERNAL ()

PASS:		ss:bx - DataChainRecord with the following filled:
			DCR_chain.DCTR_firstBlkVMHan
			DCR_vmFileHan
		DataChainStackFrame

RETURN:		DataChainStackFrame fields initialized

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

DataChainInitStackFrame	proc	near	uses	ax
	DC_local	local	DataChainStackFrame
	.enter	inherit near

	mov	ax, ss:[bx].DCR_vmFileHan
EC<	tst	ax >
EC<	ERROR_E	ROUTINE_USING_BAD_PARAMS >
	mov	DC_local.DCSF_vmFileHan, ax

	mov	ax, ss:[bx].DCR_chain.DCTR_firstBlkVMHan
	mov	DC_local.DCSF_curBlkVMHan, ax

EC<	mov	DC_local.DCSF_curBlkMemHan, 0 >
EC<	mov	DC_local.DCSF_curBlkSegAddr, 0 >

	.leave
	ret
DataChainInitStackFrame	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DataChainLockBlock

DESCRIPTION:	Lock the given VM block and store its particulars in the
		DataChainStackFrame.

CALLED BY:	INTERNAL ()

PASS:		DataChainStackFrame with the following filled in:
		    DCSF_vmFileHan
		    DCSF_curBlkVMHan

RETURN:		DataChainStackFrame with the following filled in:
		    DCSF_curBlkMemHan
		    DCSF_curBlkSegAddr

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

DataChainLockBlock	proc	near	uses	ax,bx,cx,es
	DC_local	local	DataChainStackFrame
	.enter	inherit	near

EC<	cmp	DC_local.DCSF_curBlkMemHan, 0 >
EC<	ERROR_NE IMPEX_ALREADY_HAVE_A_DATA_BLOCK_LOCKED >

	mov	bx, DC_local.DCSF_vmFileHan
	mov	ax, DC_local.DCSF_curBlkVMHan
	call	ImpexVMLock			; es <- seg addr, cx <- mem han
	mov	DC_local.DCSF_curBlkMemHan, cx
	mov	DC_local.DCSF_curBlkSegAddr, es

	.leave
	ret
DataChainLockBlock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DataChainUnlockBlock

DESCRIPTION:	Unlock the block in the DataChainStackFrame.

CALLED BY:	INTERNAL ()

PASS:		DataChainStackFrame with the following filled in:
		    DCSF_curBlkMemHan

RETURN:		nothing

DESTROYED:	nothing, flags remain intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

DataChainUnlockBlock	proc	near	uses	cx
	DC_local	local	DataChainStackFrame
	.enter	inherit	near
	pushf

EC<	cmp	DC_local.DCSF_curBlkMemHan, 0 >
EC<	ERROR_E IMPEX_NO_DATA_BLOCK_TO_UNLOCK >	

	mov	cx, DC_local.DCSF_curBlkMemHan
	call	ImpexVMUnlock

EC<	mov	DC_local.DCSF_curBlkMemHan, 0 >
EC<	mov	DC_local.DCSF_curBlkSegAddr, 0 >

	popf
	.leave
	ret
DataChainUnlockBlock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImpexVMAlloc

DESCRIPTION:	Don't use any override.

CALLED BY:	INTERNAL ()

PASS:		bx - vm file handle
		cx - size of block to allocate

RETURN:		ax - vm block handle

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

ImpexVMAlloc	proc	far
	.enter

	call	VMAlloc			; ax <- VM block handle

	.leave
	ret
ImpexVMAlloc	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImpexVMLock

DESCRIPTION:	Doesn't mess with the BP register.

CALLED BY:	INTERNAL ()

PASS:		bx - vm file handle
		ax - vm handle

RETURN:		es - seg addr of vm block
		cx - VM mem handle

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

ImpexVMLock	proc	far	uses	ax,bp
	.enter

	call	VMLock
	mov	cx, bp			; cx <- VM mem handle
	mov	es, ax			; es <- seg addr

	.leave
	ret
ImpexVMLock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImpexVMUnlock

DESCRIPTION:	Doesn't mess with the BP register.

CALLED BY:	INTERNAL ()

PASS:		cx - VM mem handle

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

ImpexVMUnlock	proc	far	uses	bp
	.enter

	mov	bp, cx
	call	VMUnlock

	.leave
	ret
ImpexVMUnlock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DataChainAddEntry

DESCRIPTION:	Add an entry to a data chain, creating a data block
		if necessary.

CALLED BY:	EXTERNAL ()

PASS:		ax - token (optional and for use with DataChainLocateEntry)
		cx - size of the entry data
		ds:si - address of data
		ss:bx - DataChainRecord

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	goto last block
	if there's no space {
	    create a new block
	    link this block as the next block and the last block
	}
	realloc last block
	add entry

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

DataChainAddEntry	proc	far	uses	ax,di,si
	DC_local	local	DataChainStackFrame
	.enter

EC<	call	ECCheckDataChainRecord >

	push	ax				; save token

	;-----------------------------------------------------------------------
	; initialize stack frame and lock the last block

	call	DataChainInitStackFrame

	mov	ax, ss:[bx].DCR_chain.DCTR_lastBlkVMHan
	tst	ax				; is there a last block?
	jne	lastBlkExists			; branch if so
	
	call	DataChainAllocDataBlock		; ax <- VM blk han

	mov	ss:[bx].DCR_chain.DCTR_firstBlkVMHan, ax
	mov	ss:[bx].DCR_chain.DCTR_lastBlkVMHan, ax

lastBlkExists:
	; ax = vm block handle of last block

	mov	DC_local.DCSF_curBlkVMHan, ax
	call	DataChainLockBlock

	mov	es, DC_local.DCSF_curBlkSegAddr	; es <- seg addr of block
checkSpace:
	;-----------------------------------------------------------------------
	; see if there's enough space for an entry in this block

EC<	call	ECCheckDataBlock >

	mov	ax, es:DBH_blockSize		; ax <- current size of block
	push	ax				; this will be address of entry
	add	ax, cx				; add size of entry data
	jo	sizeError			; need new block if overflow
	add	ax, size DataBlockEntry		; add size of entry header
	jno	doRealloc			; branch if no overflow

sizeError:
	;-----------------------------------------------------------------------
	; creation of a new block necessary

	pop	ax				; clear stack
	call	DataChainLinkNewDataBlock	; es <- seg addr of new block
	jmp	short checkSpace

doRealloc:
	push	ax				; save size of new block
	push	bx,cx				; save size of entry data
	mov	bx, DC_local.DCSF_curBlkMemHan	; bx <- data block handle
	mov	cx, mask HAF_LOCK or mask HAF_ZERO_INIT
	call	MemReAlloc
	mov	DC_local.DCSF_curBlkSegAddr, ax
	mov	es, ax				; es <- seg addr
	pop	bx,cx
	pop	es:DBH_blockSize		; store new block size

	;-----------------------------------------------------------------------
	; init entry header and copy data

	pop	di				; es:di <- new entry
	mov	es:[di].DBE_signature, DATA_BLOCK_ENTRY_SIG
	mov	es:[di].DBE_entrySize, cx
	pop	es:[di].DBE_token		; retrieve token
	mov	es:[di].DBE_newToken, 0
	add	di, offset DBE_data
	rep	movsb				; copy data

	;-----------------------------------------------------------------------
	; inc entry counts and unlock the block

	inc	es:DBH_numEntries		; inc count in data blk header
	inc	ss:[bx].DCR_chain.DCTR_numEntries ; inc count in chain record

	call	DataChainUnlockBlock

	.leave
	ret
DataChainAddEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DataChainAllocDataBlock

DESCRIPTION:	Allocate a new data block.

CALLED BY:	INTERNAL (DataChainLinkNewDataBlock)

PASS:		DataChainStackFrame with the following filled in:
		    DCSF_vmFileHan

RETURN:		ax - VM blk han of new block

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

DataChainAllocDataBlock	proc	near	uses	bx,cx,es
	DC_local	local	DataChainStackFrame
	.enter	inherit	near

	mov	bx, DC_local.DCSF_vmFileHan
	mov	cx, size DataBlockHeader
	push	cx
	call	ImpexVMAlloc			; ax <- VM blk han

	; initialize the DataBlockHeader

	call	ImpexVMLock			; es <- seg addr, cx <- mem han
	mov	es:DBH_signature, DATA_BLOCK_HEADER_SIG
	pop	es:DBH_blockSize
	mov	es:DBH_numEntries, 0
	mov	es:DBH_nextBlkVMHan + offset VMCL_next, 0

	call	ImpexVMUnlock

	.leave
	ret
DataChainAllocDataBlock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DataChainLinkNewDataBlock

DESCRIPTION:	Allocate and link a new block to the block listed in
		the DataChainStackFrame.  This original block will be unlocked,
		and the new block will be locked and made current.

CALLED BY:	INTERNAL ()

PASS:		es - seg addr of current block
		DataChainStackFrame with the following filled in:
		    DCSF_vmFileHan
		ss:bx - DataChainRecord

RETURN:		es - seg addr of the new block
		*NOTE*: new block is locked

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

DataChainLinkNewDataBlock	proc	near	uses	ax
	DC_local	local	DataChainStackFrame
	.enter	inherit	near

EC<	call	ECCheckDataBlock >
EC<	push	ax >
EC<	mov	ax, es >
EC<	cmp	ax, DC_local.DCSF_curBlkSegAddr >
EC<	ERROR_NE IMPEX_BAD_DATA_BLOCK_ENTRY >
EC<	pop	ax >
EC<	call	ECCheckDataChainRecord >

	call	DataChainAllocDataBlock		; ax <- VM blk han
	mov	es:DBH_nextBlkVMHan + offset VMCL_next, ax ; link new block
	call	DataChainUnlockBlock		; unlock original block

	mov	ss:[bx].DCR_chain.DCTR_lastBlkVMHan, ax	; note in chain record
	mov	DC_local.DCSF_curBlkVMHan, ax	; note in stack frame

	call	DataChainLockBlock
	mov	es, DC_local.DCSF_curBlkSegAddr

	.leave
	ret
DataChainLinkNewDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	ERROR CHECKING ROUTINES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ECCheckDataBlockEntry

DESCRIPTION:	Checks to see that the data block entry is valid.

CALLED BY:	INTERNAL ()

PASS:		ds:si - addr of data block entry

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

-------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckDataBlockEntry	proc	near
	.enter
	pushf

	cmp	ds:[si].DBE_signature, DATA_BLOCK_ENTRY_SIG
	ERROR_NE IMPEX_BAD_DATA_BLOCK_ENTRY

	popf
	.leave
	ret
ECCheckDataBlockEntry	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECCheckDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Checks to see that the data block is valid

CALLED BY:	INTERNAL ()

PASS:		es - seg addr of data block

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK

ECCheckDataBlock	proc	near	uses	ax
	.enter
	pushf

	cmp	es:DBH_signature, DATA_BLOCK_HEADER_SIG
	ERROR_NE IMPEX_BAD_DATA_BLOCK_ENTRY

	popf
	.leave
	ret
ECCheckDataBlock	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECCheckDataChainRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Checks to see that the data chain record is valid.

CALLED BY:	INTERNAL ()

PASS:		ss:bx - DataChainRecord

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK

ECCheckDataChainRecord	proc	near
	.enter
	pushf

	cmp	ss:[bx].DCR_chain.DCTR_signature, DATA_CHAIN_RECORD_SIG
	ERROR_NE IMPEX_BAD_DATA_CHAIN_RECORD

	popf
	.leave
	ret
ECCheckDataChainRecord	endp

endif

