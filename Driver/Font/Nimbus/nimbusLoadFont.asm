COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nimbusLoadFont.asm

AUTHOR:		Gene Anderson, Jun  6, 1990

ROUTINES:
	Name			Description
	----			-----------
	LoadOutlineData		Load outline font data.
	FindFontInfo		Find FontInfo header for given font.
	FindOutlineData		Find correct outline data for given styles.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 6/90		Initial revision

DESCRIPTION:
	Routines for loading outline font data.

	$Id: nimbusLoadFont.asm,v 1.1 97/04/18 11:45:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadOutlineData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load outline data for a font if necessary.
CALLED BY:	NimbusGenWidths, NimbusGenChar

PASS:		bx - flag: which data to load (OutlineDataFlag)
		cx - font ID (FontID)
		al - style (TextStyle)
		font info block - P'd
		ds - seg addr of font info block
RETURN:		es - seg addr of outline data (locked)
		cx - handle of outline data (locked)
		al - styles to implement (TextStyle)
		bx - size of outline data (bytes)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadOutlineData	proc	far
	uses	dx, bp, si, di, ds
	.enter

	call	FontDrEnsureFontFileOpen	;make sure the font file is
						;open

	call	FontDrFindFontInfo		;find font info for font
EC <	ERROR_NC	NIMBUS_PASSED_NON_EXISTENT_FONT >
	mov	dx, ds:[di].FI_fileHandle	;dx <- file handle
	call	FontDrFindOutlineData		;find correct outlines
DBCS <						;ds:di = entry.ODE_extraData>
DBCS <	mov	di, ds:[di]			;*ds:di = NimbusOutlineExtraData>
DBCS <	mov	di, ds:[di]			;ds:di = NimbusOutlineExtraData>
DBCS <	add	di, bx							>

	push	ax				;save styles
SBCS <	push	ds:[di].OE_size			;save size		>
DBCS <	push	ds:[di].NOE_size		;save size		>
SBCS <	mov	bx, ds:[di].OE_handle		;bx <- handle of data	>
DBCS <	mov	bx, ds:[di].NOE_handle		;bx <- handle of data	>
	tst	bx				;see if already a handle
	jz	noBlock				;branch if no block yet
	call	MemLock				;lock outline data
	jc	blockDiscarded			;branch if data discarded
	mov	es, ax				;es <- seg addr of font blk
	mov	cx, bx				;cx <- handle of font blk
afterLock:
	pop	bx				;bx <- size of block
	pop	ax				;al <- styles to implement

	.leave
	ret

	;
	; Data hasn't ever been loaded, so allocate a block for it.
	;
noBlock:
	mov_tr	ax, di
	mov	di, 800				;Make sure we have at least
	call	ThreadBorrowStackSpace		; 800 bytes of stack space
	xchg	di, ax
	push	ax

SBCS <	mov	ax, ds:[di].OE_size		;ax <- size of block	>
DBCS <	mov	ax, ds:[di].NOE_size		;ax <- size of block	>
	mov	bx, handle 0			;bx <- make Nimbus owner
	mov	cx, mask HF_DISCARDABLE \
		 or mask HF_SWAPABLE \
		 or mask HF_SHARABLE \
		 or mask HF_DISCARDED \
		 or (mask HAF_NO_ERR shl 8) 	;cl, ch <- alloc flags
	call	MemAllocSetOwner		;allocate blk for outline data
SBCS <	mov	ds:[di].OE_handle, bx		;save handle to outline data>
DBCS <	mov	ds:[di].NOE_handle, bx		;save handle to outline data>
	jmp	loadBlockCommon
	;
	; The block was discarded. Reallocate the block to
	; the correct size and read the appropriate data
	; from the file.
	;
blockDiscarded:
	mov_tr	ax, di
	mov	di, 800				;Make sure we have at least
	call	ThreadBorrowStackSpace		; 800 bytes of stack space
	xchg	di, ax
	push	ax

loadBlockCommon:
	push	bx				;save block handle
	segmov	es, ds
	mov	ch, mask HAF_LOCK or mask HAF_NO_ERR	;ch <- lock block
	clr	ax				;ax <- realloc same size
	call	MemReAlloc			;reallocate block
	mov	ds, ax				;ds <- seg addr of block
	mov	bx, dx				;bx <- file handle
SBCS <	mov	cx, es:[di].OE_offset.high	;cx <- offset (high)	>
SBCS <	mov	dx, es:[di].OE_offset.low	;dx <- offset (low)	>
DBCS <	mov	cx, es:[di].NOE_offset.high	;cx <- offset (high)	>
DBCS <	mov	dx, es:[di].NOE_offset.low	;dx <- offset (low)	>
	mov	al, FILE_POS_START		;al <- flag: absolute offset
	call	FilePos				;position the file ptr
	clr	dx				;ds:dx <- buffer to read into
SBCS <	mov	cx, es:[di].OE_size		;cx <- # bytes to read	>
DBCS <	mov	cx, es:[di].NOE_size		;cx <- # bytes to read	>
	mov	al, FILE_NO_ERRORS		;al <- flag: no errors
	call	FileRead 			;read the outline data
	pop	cx				;cx <- handle of font blk
	segmov	es, ds
	pop	di
	call	ThreadReturnStackSpace
	jmp	afterLock

LoadOutlineData	endp
