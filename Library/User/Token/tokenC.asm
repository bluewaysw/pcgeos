COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Token
FILE:		tokenC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

DESCRIPTION:
	This file contains C interface routines for the Token utility routines

	$Id: tokenC.asm,v 1.1 97/04/07 11:46:31 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Token	segment	resource

GetTokenCharAndManufID	macro
	mov	al, {byte} tokenChars+0
	mov	ah, {byte} tokenChars+1
	mov	bl, {byte} tokenChars+2
	mov	bh, {byte} tokenChars+3
	mov	si, manufacturerID
			endm

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenDefineToken

C DECLARATION:	extern word
			_far _pascal TokenDefineToken(
				dword tokenChars,
				ManufacturerID manufacturerID,
				optr monikerList,
				TokenFlags flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENDEFINETOKEN	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					monikerList:optr, flags:TokenFlags

	uses	si
	.enter

	GetTokenCharAndManufID		; ax:bx:si = token
	mov	cx, monikerList.handle
	mov	dx, monikerList.chunk
	push	bp
	mov	bp, flags
	call	TokenDefineToken	; if error, carry <- set and
					;  ax <- VMStatus
	pop	bp
	jc	done		
	clr	ax
done:
	.leave
	ret
TOKENDEFINETOKEN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenGetTokenInfo

C DECLARATION:	extern Boolean
			_far _pascal TokenGetTokenInfo(
				dword tokenChars,
				ManufacturerID manufacturerID,
				TokenFlags *flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENGETTOKENINFO	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					flags:fptr

	uses	ds, si
	.enter

	GetTokenCharAndManufID	; ax:bx:si = token
	push	bp
	call	TokenGetTokenInfo	; carry clear if found
	mov	ax, bp			; ax = flags, if any
	pop	bp
	mov	ds, flags.segment
	mov	si, flags.offset
	mov	{word} ds:[si], ax
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENGETTOKENINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenLookupMoniker

C DECLARATION:	extern Boolean
			_far _pascal TokenLookupMoniker(
				dword tokenChars,
				ManufacturerID manufacturerID,
				DisplayType displayType,
				VisMonikerSearchFlags searchFlags,
				TokenMonikerInfo *tokenMonikerInfo);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENLOOKUPMONIKER	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					displayType:word,
					searchFlags:VisMonikerSearchFlags,
					tokenMonikerInfo:dword

	uses	ds, si
	.enter

	GetTokenCharAndManufID		; ax:bx:si = token
	mov	dh, displayType.low
	push	bp
	mov	bp, searchFlags
	call	TokenLookupMoniker	; carry clear if found
	pop	bp
	mov	ds, tokenMonikerInfo.segment
	mov	si, tokenMonikerInfo.offset
	mov	ds:[si].TMI_moniker.TDBI_group, cx
	mov	ds:[si].TMI_moniker.TDBI_item, dx
	mov	ds:[si].TMI_fileFlag, ax
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENLOOKUPMONIKER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenLoadMonikerBlock

C DECLARATION:	extern Boolean
			_far _pascal TokenLoadMonikerBlock(
				dword tokenChars,
				ManufacturerID manufacturerID,
				DisplayType displayType,
				VisMonikerSearchFlags searchFlags,
				word *blockSize, MemHandle *blockHandle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENLOADMONIKERBLOCK	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					displayType:word,
					searchFlags:VisMonikerSearchFlags,
					blockSize:fptr, blockHandle:fptr

	uses	di, si, es
	.enter

	GetTokenCharAndManufID		; ax:bx:si = token
	mov	dh, displayType.low
	push	searchFlags
	clr	cx			; allocate global heap block
	push	cx			; unused buffer size
	call	TokenLoadMoniker	; cx = #bytes, di = block
					; carry clear if found
	jnc 	foundit
	mov	cx, 0			; return zero block and #bytes
	mov	di, 0			; preserve carry
foundit:	
	les	si, blockSize
	mov	es:[si], cx		; return #bytes
	les	si, blockHandle
	mov	es:[si], di		; return blockHandle
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENLOADMONIKERBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenLoadMonikerChunk

C DECLARATION:	extern Boolean
			_far _pascal TokenLoadMonikerChunk(
				dword tokenChars,
				ManufacturerID manufacturerID,
				DisplayType displayType,
				VisMonikerSearchFlags searchFlags,
				MemHandle lmemBlock,
				word *chunkSize, ChunkHandle *chunkHandle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENLOADMONIKERCHUNK	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					displayType:word,
					searchFlags:VisMonikerSearchFlags,
					lmemBlock:hptr,
					chunkSize:fptr, chunkHandle:fptr

	uses	di, si, es
	.enter

	GetTokenCharAndManufID		; ax:bx:si = token
	mov	cx, lmemBlock
	mov	dh, displayType.low
	push	searchFlags
	clr	di			; cx = lmemBlock
	push	di			; unused buffer size
	call	TokenLoadMoniker	; cx = #bytes, di = lmem chunk
					; carry clear if found
	jnc 	foundit
	mov	cx, 0			; return zero chunk handle and #bytes
	mov	di, 0			; preserve carry
foundit:	
	les	si, chunkSize
	mov	es:[si], cx		; return #bytes
	les	si, chunkHandle
	mov	es:[si], di		; return chunkHandle
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENLOADMONIKERCHUNK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenLoadMonikerBuffer

C DECLARATION:	extern Boolean
			_far _pascal TokenLoadMonikerBuffer(
				dword tokenChars,
				ManufacturerID manufacturerID,
				DisplayType displayType,
				VisMonikerSearchFlags searchFlags,
				void *buffer, word bufferSize,
				word *bytesReturned);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENLOADMONIKERBUFFER	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					displayType:word,
					searchFlags:VisMonikerSearchFlags,
					buffer:fptr, bufferSize:word,
					bytesReturned:fptr

	uses	di, si, es
	.enter

	GetTokenCharAndManufID		; ax:bx:si = token
	mov	dh, displayType.low
	mov	cx, buffer.segment
	mov	di, buffer.offset
	push	searchFlags
	push	bufferSize		; pass size on stack
	call	TokenLoadMoniker	; cx = #bytes
					; carry clear if found
	jnc 	foundit
	mov	cx, 0			; return #bytes = 0
					; preserve carry
foundit:	
	les	di, bytesReturned
	mov_tr	ax, cx
	stosw				; return #bytes
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENLOADMONIKERBUFFER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenRemoveToken

C DECLARATION:	extern Boolean
			_far _pascal TokenRemoveToken(
				dword tokenChars,
				ManufacturerID manufacturerID);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENREMOVETOKEN	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID

	uses	ds, si
	.enter

	GetTokenCharAndManufID	; ax:bx:si = token
	call	TokenRemoveToken	; carry clear if successful
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENREMOVETOKEN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenGetTokenStats

C DECLARATION:	extern void
			_far _pascal TokenGetTokenStats(
				dword tokenChars,
				ManufacturerID manufacturerID);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENGETTOKENSTATS	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID

	uses	ds, si
	.enter

	GetTokenCharAndManufID	; ax:bx:si = token
	call	TokenGetTokenStats
	.leave
	ret
TOKENGETTOKENSTATS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenLoadTokenBlock

C DECLARATION:	extern Boolean
			_far _pascal TokenLoadTokenBlock(
				dword tokenChars,
				ManufacturerID manufacturerID,
				word *blockSize, MemHandle *blockHandle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENLOADTOKENBLOCK	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					blockSize:fptr, blockHandle:fptr


	uses	di, si, es
	.enter

	GetTokenCharAndManufID	; ax:bx:si = token
	clr	cx			; allocate global heap block
	call	TokenLoadToken		; cx = #bytes, di = block
					; carry clear if found
	les	si, blockSize
	mov	es:[si], cx		; return #bytes
	les	si, blockHandle
	mov	es:[si], di		; return blockHandle
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENLOADTOKENBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenLoadTokenChunk

C DECLARATION:	extern Boolean
			_far _pascal TokenLoadTokenChunk(
				dword tokenChars,
				ManufacturerID manufacturerID,
				MemHandle lmemBlock,
				word *chunkSize, ChunkHandle *chunkHandle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENLOADTOKENCHUNK	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					lmemBlock:hptr,
					chunkSize:fptr, chunkHandle:fptr

	uses	di, si, es
	.enter

	GetTokenCharAndManufID	; ax:bx:si = token
	mov	cx, lmemBlock
	clr	di			; cx = lmemBlock
	call	TokenLoadToken		; cx = #bytes, di = lmem chunk
					; carry clear if found
	les	si, chunkSize
	mov	es:[si], cx		; return #bytes
	les	si, chunkHandle
	mov	es:[si], di		; return chunkHandle
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENLOADTOKENCHUNK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenLoadTokenBuffer

C DECLARATION:	extern Boolean
			_far _pascal TokenLoadTokenBuffer(
				dword tokenChars,
				ManufacturerID manufacturerID,
				TokenEntry *buffer);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENLOADTOKENBUFFER	proc	far	tokenChars:dword,
					manufacturerID:ManufacturerID,
					buffer:fptr

	uses	di, si
	.enter

	GetTokenCharAndManufID	; ax:bx:si = token
	mov	cx, buffer.segment
	mov	di, buffer.offset
	call	TokenLoadToken		; cx = #bytes
					; carry clear if found
	mov	ax, 0			; FALSE - not found (carry set)
	jc	done
	inc	ax			; TRUE - found (carry clear)
done:
	.leave
	ret
TOKENLOADTOKENBUFFER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenLockTokenMoniker

C DECLARATION:	extern void *
			_pascal TokenLockTokenMoniker(
				TokenMonikerInfo tokenMonikerInfo);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENLOCKTOKENMONIKER	proc	far
	C_GetThreeWordArgs	ax, dx, cx, bx	;cx = group, dx = item, ax = fl

	call	TokenLockTokenMoniker	; ds:bx = segment:chunk
	mov	dx, ds:[LMBH_handle]	; dx = lmem block (locked)
	mov	ax, bx			; ax = lmem chunk
	ret
TOKENLOCKTOKENMONIKER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenUnlockTokenMoniker

C DECLARATION:	extern void
			_pascal TokenUnlockTokenMoniker(void *moniker);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version

------------------------------------------------------------------------------@
TOKENUNLOCKTOKENMONIKER	proc	far
	C_GetTwoWordArgs	bx, ax, cx, dx	;bx = handle, ax = chunk

	uses	ds
	.enter

	call	MemDerefDS		; ds = lmem block
	call	TokenUnlockTokenMoniker
	.leave
	ret
TOKENUNLOCKTOKENMONIKER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TokenListTokens

C DECLARATION:	extern dword
		_pascal TokenListTokens
			(TokenRangeFlags tokenRangeFlags,
			 word headerSize,
			 ManufacturerID manufacturerID);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/92		Initial version
	JDM	93.04.16	Fixed.

------------------------------------------------------------------------------@
TOKENLISTTOKENS	proc	far	tokenRangeFlags:TokenRangeFlags,
				headerSize:word,
				manufacturerID:ManufacturerID
	.enter

	mov	ax, tokenRangeFlags	; AX = TokenRangeFlags.
	mov	bx, headerSize		; BX = Bytes to reserve.
	mov	cx, manufacturerID	; CX = ID for token list.
	call	TokenListTokens		; bx = handle, ax = #items
	mov	dx, ax			; dx = #items
	mov	ax, bx			; ax = handle

	.leave
	ret
TOKENLISTTOKENS	endp

C_Token	ends

	SetDefaultConvention

