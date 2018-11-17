COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		Engine
FILE:		cwordEngine.asm

AUTHOR:		Jennifer Lew, May 12, 1994

ROUTINES:
	Name			Description
	----			-----------
		INITIALIZATION ROUTINES		
	EngineCreateEngineToken
	EngineFreeBlocksFromError
	EngineBuildClueStructures
	EngineMakeClueHeaderBlock
	EngineMakeClueDataBlock
	EngineMemAllocLMem
	EngineSetSolutionLetters
	EngineSetAcrossClues
	EngineSetDownClues
	EngineNotificationCluesToFollow
	EngineSetNumbersOfAllCells
	EngineSetNumberCallback
	EngineSetCluesPassDirection
	EngineInitializeClueHeaders
	EnginePrepareToReadClues
	EngineConnectClueToCorrespCell
	EngineGetCellTokenWithNumberCallback
	EngineSetClueInClueData
	EngineMakeNewDataBlockIfNeeded
	EngineNotificationCluesDone
	EngineExtendClueTokenLinksToAllCells
	EngineExtendClueLinksAcrossCallback
	EngineExtendDownClueTokensInCellArray
	EngineSetDownClueTokenInCell

		BASIC ACCESS
	EngineGetFirstExistentNonHoleCell
	EngineSearchForFirstCellCallback
	EngineGetOffsetOfSelectedCellInSelectedWord
	EngineMapCellNumberToCellToken
	EngineSearchForCellGivenNumberCallback
	EngineMapClueNumberToClueToken
	EngineMapClueTokenToClueNumber

		VALIDATION
	EngineIsValidSolutionChar
	EngineIsEndOfLine
	
		SOLUTION DOCUMENT
	EngineWriteCellData
	EngineWriteSingleCellCallBack
	EngineReadCellData
	EngineReadSingleCellData


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/12/94   	Initial revision

DESCRIPTION:
		
	$Id: cwordEngineFile.asm,v 1.1 97/04/04 15:14:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CwordFileCode	segment	resource

;----------------------------------------------------------------------------
;	Start of EngineCreateEngineToken set up stuff ...
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineCreateEngineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the Engine Token and initializes the number of
		rows and columns in the puzzle.

CALLED BY:	GLOBAL	(FileReadSourceDocument)
PASS:		ah	- rows
		al	- columns

RETURN:		dx	- Engine Token (EngineTokenType)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Build out the initial structure of the Engine data.
	See the Technical Specifications for the complete diagram.
	
	Structures will be built from bottom up: from the clue data
	blocks to the clue header blocks and finally to the cell blocks.

	Build out all engine data structures: CellArray,
		ClueHeaderArray, ClueDataArrays.
	The engine token is really the handle to the block in which
	CellArray will be stored.

	approximate size of Cell LMem block
		size MyCellBlockHeader + size ChunkArrayHeader
		+ (rows * columns * size CellData) 
		[did not account for LMem block's handle table]

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineCreateEngineToken	proc	near
	uses	ax,bx,cx,si,ds
	.enter

	; build out clue data structures
	call	EngineBuildClueStructures	; bx - across clue
						;   header block handle
						; dx - down clue
						;   header block handle

	jc	clueErr			; error occured

	push	bx, dx			; across clue header 
					;      block handle,
					; down clue header block
					;      handle

	push	ax			; rows stored in high and 
					; colums stored in low

	; approximate the size of the Cell LMem block
	mul	ah			; (rows * columns)
	mov	bl, size CellData
	mul	bl			; (rows * columns) * size CellData
	add	ax, size ChunkArrayHeader	
	push	ax			; save cell chunk array space

	; allocate and initialize block for CELL CHUNK ARRAY
	add	ax, size CellBlockHeader	; ax = approximate size
	mov	bx, size CellData
	pop	cx			; cell chunk array space
	mov	dx, size CellBlockHeader
	call	EngineMemAllocLMem	; bx = block handle
					; si = chunk array chunk  handle
	jc	popAndEnd		; memory allocation error

	call	MemLock			; ax = segment address

	mov	ds, ax			; block pointer

EC <	call	ECCheckChunkArray					>

	pop	ax			; rows stored in high and 
					; colums stored in low
	mov	ds:[CBH_rows], ah
	mov	ds:[CBH_columns], al
	mov	ds:[CBH_cellArrayChunkHandle], si
	pop	ax, cx			; clue header block handles
	mov	ds:[CBH_acrossClueHeaderBlockHandle], ax
	mov	ds:[CBH_downClueHeaderBlockHandle], cx

	call	MemUnlock
	mov	dx, bx			; engine token
	clc				; successful completion
finish:
	.leave
	ret
popAndEnd:
	pop	ax
	pop	bx, dx		; across and down clue header block handles
clueErr:
	call	EngineFreeBlocksFromError
	jmp	finish
EngineCreateEngineToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineFreeBlocksFromError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given 2 clue header block handles, free them and 
		any blocks below it because an error occured.

CALLED BY:	ENGINE INTERNAL	(EngineCreateEngineToken)
PASS:		bx	- across clue header block handle (0 if error
				with across clue header block)
		dx	- down clue header block handle (0 if error with
				down clue header block)
RETURN:		CF	- set
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	If the block handle passed is 0, then it does not need
	any freeing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineFreeBlocksFromError	proc	near
	uses	ax,bx,ds
	.enter

	tst	bx			; block need freeing?
	jz	fixDown

	; free any blocks below the across clue header block
	call	MemLock			; ax - segment
	mov	ds, ax			; segment
	push	bx			; clue header block
	mov	bx, ds:[CHBH_currentClueDataBlockHandle]
	call	MemFree
	pop	bx			; clue header block
	call	MemFree
	
fixDown:
	tst	dx			; block need freeing?
	jz	finish

	mov	bx, dx
	; free any blocks below the down clue header block
	call	MemLock			; ax - segment
	mov	ds, ax			; segment
	push	bx			; clue header block
	mov	bx, ds:[CHBH_currentClueDataBlockHandle]
	call	MemFree
	pop	bx			; clue header block
	call	MemFree
finish:
	stc
	.leave
	ret
EngineFreeBlocksFromError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineBuildClueStructures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build out all Clue data structures

CALLED BY:	ENGINE INTERNAL	(EngineCreateEngineToken)
PASS:		nothing

RETURN:		bx	- across clue header block handle (0 if error with
				across clue header block)
		dx	- down clue header block handle (0 if error with
				down clue header block)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Build out structures bottom up.  When a block is told
	to build itself out, it builds the block(s) it points 
	to first before it builds itself.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineBuildClueStructures	proc	near
	.enter

	clr	dx		; initial invalid down clue header 
				; block handle, in case the 2nd
				; EngineMakeClueHeaderBlock is not
				; reached.

	call	EngineMakeClueHeaderBlock	; bx - block handle to
						;    clue header block
	
	jc	finish			; error occured

	mov	dx, bx			; down clue header
					; block handle
	call	EngineMakeClueHeaderBlock	; bx - block handle to
						;    clue header block
finish:	
	.leave
	ret
EngineBuildClueStructures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMakeClueHeaderBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a clue header block with a uniform sized chunk
		array in it.  Also make the Clue data which a field
		in the Clue header block header points to.

CALLED BY:	ENGINE INTERNAL	(EngineBuildClueStructures)
PASS:		nothing

RETURN:		bx	- block handle to clue header block (0 if error)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Build out Clue Data Block before building out the Clue Header
	Block itself.  If any block below the clue header block or
	the clue header block run across any errors, it and the blocks
	below it are destroyed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMakeClueHeaderBlock	proc	near
	uses	ax,cx,dx,ds
	.enter

	; Make the Clue Data block
	call	EngineMakeClueDataBlock		; bx - block handle to
						; 	clue data block

	jc	finish			; error occured

	push	bx			; clue data block handle

	; allocate and initialize a block for the CLUE HEADER CHUNK ARRAY

	mov	ax, ENGINE_DEFAULT_ALLOC_SIZE
	mov	bx, size ClueHeader
	mov	cx, ENGINE_DEFAULT_HEAP_SIZE
	mov	dx, size ClueHeaderBlockHeader
	call	EngineMemAllocLMem	; bx = block handle
					; si = chunk array chunk handle
	jc	popAndEnd		; memory allocation error

	call	MemLock			; ax = address to block

	mov	ds, ax

EC <	call	ECCheckChunkArray					>

	mov	ds:[CHBH_clueHeaderChunkHandle], si
	pop	ds:[CHBH_currentClueDataBlockHandle]
	
	call	MemUnlock
	clc				; successful completion
finish:
	.leave
	ret

popAndEnd:
	pop	bx			; clue data block handle
	call	MemFree
	clr	bx			; zero block handle to return
	stc
	jmp	finish

EngineMakeClueHeaderBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMakeClueDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make clue data block, block is an LMem block with a
		variable sized chunk array in it.
		
CALLED BY:	ENGINE INTERNAL	(EngineMakeClueHeaderBlock)

PASS:		nothing

RETURN:		bx	- block handle to clue data block (0 if error)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMakeClueDataBlock	proc	near
	uses	ax,cx,dx,si,ds
	.enter

	mov	ax, ENGINE_DEFAULT_ALLOC_SIZE
	clr	bx			; variable size elements
	mov	cx, ENGINE_DEFAULT_HEAP_SIZE
	mov	dx, size ClueDataBlockHeader
	call	EngineMemAllocLMem	; bx = block handle
					; si = chunk array chunk handle

	jc	finish			; error occured

	call	MemLock			; ax = address to block

	mov	ds, ax

EC <	call	ECCheckChunkArray					>

	mov	ds:[CDBH_clueDataChunkHandle], si
	call	MemUnlock
	clc				; successful complete
finish:
	.leave
	ret
EngineMakeClueDataBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMemAllocLMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to allocate a block with a local
		memory heap and create a chunk array within it.
		Returns Block handle and Array chunk handle with
		block NOT locked.

CALLED BY:	ENGINE INTERNAL
PASS:		ax 	- approximate size of block to allocate
		bx	- element size to create in Chunk Array, 
		    		0 if variable sized
		cx	- initial heap size
		dx	- offset in segment to the start of the heap
			  (block header size)

RETURN:		bx	- block handle	(0 if error occurred)
		si	- array chunk handle
		CF	- set if error occured, clear otherwise
			  If error occurs, the allocated block
			  (if allocated already) is freed.
			  
DESTROYED:	bx used for return value
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMemAllocLMem	proc	near
bHandle	local	word
	uses	ax,cx,di,ds
	.enter

	push	bx			; element size
	push	cx			; initial heap size

	; Allocate and build out the entire LMem block
	;
	Assert	urange	ax, 1, 64000
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		; bx = block handle
					; ax = address to block
					; carry set if error
	jc	popMemErrorDialog

	mov	ss:[bHandle], bx

	mov	ds, ax			; address to block

	; Make the allocated block an LMem Heap
	;
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, 1			; one handle initially
	; dx should be from argument
	pop	si 			; heap space
	mov	di, mask LMF_RETURN_ERRORS
	call	LMemInitHeap

	; Make the chunk array withing the LMem Heap
	;
	pop	bx			; element size
	clr	cx, si
	clr	al
	call	ChunkArrayCreate	; *ds:si = array (block
					; 	possible moved)

	jc	chunkErrorDialog

EC <	call	ECCheckChunkArray					>

	mov	bx, ss:[bHandle]
	call	MemUnlock
	clc				; successful completion
finish:
	.leave
	ret

popMemErrorDialog:
	pop	cx
	pop	bx
	clr	bx			; zero block handle to return
	mov	di, MEM_ERR
	call	CwordHandleError
	jmp	finish

chunkErrorDialog:
	mov	bx, ss:[bHandle]
	call	MemFree
	clr	bx			; zero block handle to return
	mov	di, CHUNK_ARRAY_ERR
	call	CwordHandleError
	jmp	finish

EngineMemAllocLMem	endp

;----------------------------------------------------------------------------
;	... End of EngineCreateEngineToken set up stuff
;
;	Start of entering solution letters into data structures ...
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetSolutionLetters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append new elements to the cell data array, initialize
		the elements, and put solution letters and cell flags
		into it. 

CALLED BY:	FileReadSourceDocument
PASS:		ax	- number of bytes
		dx	- Engine Token
		es:bx	- Buffer to read from.
			  The solution letters are lined up row by
			  row, so 'enter' and 'linefeed' characters
			  are ignored during the initialization.

RETURN:		bx	- new buffer offset pointing to the byte after
			  the solution letters 
				(= original offset + number of bytes)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Read a character from the buffer provided.
	Append a new element to the Cell Data Array and
		place the character into it and initialize
		the flags.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetSolutionLetters	proc	near
	uses	ax,cx,dx,di,si,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; ds:si = array

	mov	cx, ax				; number of bytes
						;  also number of
						;  times to loop around

	push	dx				; save block handle

EC <	call	ECCheckChunkArray					>

readLetter:

	; Get a character from the buffer
	mov	al, {byte} es:[bx]		; buffer letter
	clr	ah				; single-byte version
	call	LocalUpcaseChar

	; If the character is an end of line character, do nothing
	call	EngineIsEndOfLine
	jc	loopIt

	; Verify if character is a valid solution character
	call	EngineIsValidSolutionChar				
	jc	badSoln				; not a valid character	

	; Everything is Ok, continue to add the element to the
	; Cell Data Chunk Array, put the solution letter into
	; the element and initialize the flag.

	call	ChunkArrayAppend		; ds:di - new element
	jc	memErr

	cmp	al, ENGINE_HOLE
	je	isHole
	cmp	al, ENGINE_NON_EXIST
	je	isNonExist
	
 	mov	{byte} ds:[di].CD_solutionLetter, al
	mov	ds:[di].CD_flags, mask CF_EMPTY
loopIt:
	mov	ds:[di].CD_userLetter, C_SPACE
	inc	bx				; inc buffer offset
EC <	call	ECCheckChunkArray					>
	loop	readLetter

	mov	dx, bx				; updated buffer offset
	pop	bx				; block handle
	call	MemUnlock

	mov	bx, dx				; buffer offset
	clc					; successful completion
finish:
	.leave
	ret

isHole:	
	mov	ds:[di].CD_flags, mask CF_HOLE
	jmp	loopIt
isNonExist:
	mov	ds:[di].CD_flags, mask CF_NON_EXISTENT
	jmp	loopIt
badSoln:
	mov	di, SOURCE_ERR
	jmp	handleErr
memErr:
	mov	di, MEM_ERR
handleErr:
	pop	bx
	call	MemUnlock
	call	CwordHandleError
	jmp	finish

EngineSetSolutionLetters	endp

;----------------------------------------------------------------------------
;	... End of entering solution letters into data structures 
;
;	Start of entering clues into data structures
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;	... End of EngineCreateEngineToken set up stuff
;
;	Start of entering solution letters into data structures ...
;----------------------------------------------------------------------------




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineNotificationCluesToFollow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure is just for the File Module to notify
		the Engine Module that it is about to hand over the 
		clue information.  Within the Engine Module, this is
		the time to enumerate the numbers for the cells.

CALLED BY:	GLOBAL	(FileReadSourceDocument)

PASS:		dx	- engine token

RETURN:		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineNotificationCluesToFollow	proc	near
	.enter

	Assert	EngineTokenType	dx
	call	EngineSetNumbersOfAllCells
	
	.leave
	ret
EngineNotificationCluesToFollow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetNumbersOfAllCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the numbers for all cells in the cell data
		chunk array.

CALLED BY:	ENGINE INTERNAL	(EngineNotificationCluesToFollow)

PASS:		dx	- engine token

RETURN:		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetNumbersOfAllCells	proc	near
	uses	bx,cx,dx,di,si,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; ds:si	= array

	push	dx				; engine token

	; Set up Arguments for the Callback routine which will
	; be called for each cell in the array.  The callback
	; routine will give the cell a number if it meets the
	; criteria.

	clr	ch
	mov	cl, ds:[CBH_columns]
	mov	dl, 1			; first number

	mov	bx, cs
	mov	di, offset EngineSetNumberCallback

	call	ChunkArrayEnum		; enumerate the numbers for 
					; each cell

	
	pop	bx			; engine token
	Assert	lmem	bx
	call	MemUnlock
	clc

	.leave
	ret
EngineSetNumbersOfAllCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetNumberCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the number field and flag of a cell if it gets 
		a number.

CALLED BY:	ENGINE INTERNAL 
			(ChunkArrayEnum from EngineSetNumbersOfAllCells)

PASS:		*ds:si 	- array
		ds:di 	- array element being enumerated
		cx	- number of columns in board
		dl	- number to assign the cell if it gets a number

RETURN:		carry	- set to end enumeration (if error occured)
			- clear to continue
			(always clear

DESTROYED:	bx, si, di (by ChunkArrayEnum)
SIDE EFFECTS:	
	Must be a far call because it's a callback routine.

PSEUDO CODE/STRATEGY:
	Numbers are given out in increasing order starting at 1.
	All cells will be given numbers so that I binary search can
	be performed for when connecting clues to cells. Only cells
	that need to display their number will have the CF_NUMBER
	bit set in their data. A cell is always given the current number.
	If the CF_NUMBER bit is also set then the current number is
	incremented.

	The CF_NUMBER bit will be set when
		1. the given cell is on the top edge or left edge of
		  	the puzzle
		2. the cell on top of or to the left of the given cell
			is a hole

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetNumberCallback	proc	far
	uses	ax,cx,di,bp
	.enter

	;    Always set number

	mov	ds:[di].CD_number, dl

	; if the cell is a hole or is non-existent, no number is assigned
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	done
	test	ds:[di].CD_flags, mask CF_NON_EXISTENT
	jnz	done

	Assert	e	ch, 0

	; see if cell is on the top edge
	call	ChunkArrayPtrToElement		; ax - element number
	cmp	ax, cx
	jl	getNumber

	; See if cell is on the left edge - 
	; 	true if (element mod columns) is 0.
	mov	bp, ax				; element number
	div	cl				; ah is remainder
	tst	ah
	jz	getNumber

	push	di				; given element

	; Check if cell on top is a hole
	mov	ax, bp				; element number
	sub	ax, cx				; ax = element on top
	call	ChunkArrayElementToPtr		; ds:di - top element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	getNumberPopDi

	; check if cell to left is a hole
	mov	ax, bp				; element number
	dec	ax				; ax = element to left
	call	ChunkArrayElementToPtr		; ds:di - top element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	getNumberPopDi
	
	pop	di				; given element
done:
	clc				; continue through all elements
	.leave
	ret

getNumberPopDi:
	pop	di				; given element
getNumber:
	inc	dl				; next number to assign
	BitSet	ds:[di].CD_flags, CF_NUMBER
	jmp	done
EngineSetNumberCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetAcrossClues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read across clues from the buffer and enter the data 
		into the appropriate data structures.  See Technical
		Specifications.

CALLED BY:	GLOBAL	(FileReadSourceDocument)
PASS:		dx	- Engine Token
		ax	- number of bytes of clues in buffer
		es:bx	- buffer to read from.
			  each clue is on its own line and
			  'enter' and 'linefeed' characters
			  are ignored during the initialization.

RETURN:		bx	- new buffer offset pointing to the byte after
			  the clues (= original offset + number of bytes)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetAcrossClues	proc	near
	uses	cx
	.enter

	Assert	EngineTokenType	dx
	mov	cx, ACROSS
	call	EngineSetCluesPassDirection	; bx - new buffer offset
						; CF set/not set
	.leave
	ret
EngineSetAcrossClues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetDownClues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read down clues from the buffer and enter into
		appropriate data structures.  See Technical
		Specifications.

CALLED BY:	GLOBAL	(FileReadSourceDocument)
PASS:		dx	- Engine Token
		ax	- number of bytes of clues in buffer
		es:bx	- buffer to read from.
			  each clue is on its own line and
			  'enter' and 'linefeed' characters
			  are ignored during the initialization.

RETURN:		bx	- new buffer offset pointing to the byte after
			  the clues (= original offset + number of bytes)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetDownClues	proc	near
	uses	cx
	.enter

	Assert	EngineTokenType	dx
	mov	cx, DOWN
	call	EngineSetCluesPassDirection	; bx - new buffer offset
						; CF set/not set
	.leave
	ret
EngineSetDownClues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetCluesPassDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read clues from the buffer and enter into appropriate 
		data structures.  See Technical Specifications.

CALLED BY:	ENGINE INTERNAL	
			(EngineSetDownClues and EngineSetAcrossClues)

PASS:		dx	- Engine Token
		ax	- number of bytes of clues in buffer
		cx	- direction (ACROSS or DOWN)
			  Also: it is the offset of the clue header block
			  handle within the cell data block header.
		es:bx	- buffer to read from.
			  each clue is on its own line and
			  'enter' and 'linefeed' characters
			  are ignored during the initialization.

RETURN:		bx	- new buffer offset pointing to the byte after 
			  the clues (= original offset + number of bytes)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetCluesPassDirection	proc	near
	uses	ax,dx,si,ds
	.enter

; USES CX, ES  ???

	Assert	EngineTokenType	dx
	EngineGetCellSegmentDS		; ds - cell segment

	push	bx				; initial buffer offset
	push	dx				; engine token

	; get the correct clue header block handle into dx
	mov	bx, cx			; clue header block handle offset
	mov	dx, ds:[bx]		; clue header block handle -
					;  used as argument for
					;  EngineInitializeClueHeaders

	pop	si			; engine token
	mov	bx, si			; engine token
	Assert	lmem	bx
	call	MemUnlock		; unlock cell block (where the
					; engine token points)

	pop	bx			; initial buffer offset
			
; AX == clue bytes ???

	call	EngineInitializeClueHeaders	; bx - new buffer offset
						; will set/not set CF
	.leave
	ret
EngineSetCluesPassDirection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineInitializeClueHeaders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loop and read in all clues in buffer into the clue
		header array and a clue data array.

CALLED BY:	ENGINE INTERNAL	(EngineSetCluesPassDirection)
PASS:		dx	- block handle to clue header block
		ax	- number of bytes of clues in buffer
		cx	- direction of clues (ACROSS or DOWN)
			  Also the offset of the clue header handle
			  in the cell header block
		si	- engine token
		es:bx	- buffer to read from.
			  each clue is on its own line and
			  'enter' and 'linefeed' characters
			  are ignored during the initialization.

RETURN:		bx	- new buffer offset pointing to the byte after 
			  the clues (= original offset + number of bytes)
		CF	- set if error occured, clear otherwise

DESTROYED:	nothing
SIDE EFFECTS:	

	WARNING:  This routine MAY resize the Clue Header LMem block
		  and the Clue Data LMem blocks, moving it on the heap
		  and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
	Read in clues one at a time and do all initialization for it.
	To do this and to be efficient, two blocks are always locked
	at one time: the clue header block and the current clue data
	block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineInitializeClueHeaders	proc	near
engToken		local	hptr	push	si
clueHeaderBlockHandle	local	hptr	push	dx
initBufferOffset	local	word	push	bx
direction		local	word	push	cx
clueDataBlockHandle	local	hptr
clueDataSegment		local	word
clueDataChunkHandle	local	lptr
	uses	ax,cx,dx,di,si,ds
	.enter

	ForceRef	engToken
	ForceRef	initBufferOffset
	ForceRef	direction
	ForceRef	clueDataSegment
	ForceRef	clueDataChunkHandle

	Assert	EngineTokenType	si
	call	EnginePrepareToReadClues
			; ax - current clue data chunk handle
			; dx - offset of end of clue bytes buffer
			; *ds:si - clue header chunk array

EC <	; check if clue data chunk array is valid			>
EC <	push	bx, ds, si		; check clue data array		>
EC <	mov	bx, ss:[clueDataSegment]				>
EC <	mov	ds, bx							>
EC <	mov	si, ax			; clue data chunk handle	>
EC <	call	ECCheckChunkArray					>
EC <	pop	bx, ds, si						>

	mov	cx, dx			; offset of end of clue bytes buffer

EC <	call	ECCheckChunkArray					>

	; READ IN CLUES ONE PER LOOP
readClue:
	
	; First number in the clue data should be of clue type CTF_TEXT
	; Each piece of information for a clue is separated by commas.

	; The first character in the buffer for a clue is the clue
	; type.  Since this is the original, rather than an alternate
	; clue, this must be of type CTF_TEXT which is specified by a 1.
	mov	dh, C_COMMA
	call	StringAsciiConvertToInteger		; ax = clue type
							; bx = new offset
	LONG jc	sourceErr

	cmp	ax, CTF_TEXT		; initial clue should always
					; be text
	LONG jne	sourceErr

	; The next character in the clue information is the clue
	; number.  This number is used to set up the links between the
	; clues and the cells.
	Assert	e	dh, C_COMMA
	call	StringAsciiConvertToInteger	; ax = clue number
						; bx = new offset
	LONG jc	sourceErr

	; All the previous information is valid so we go ahead and
	; make a new element in the clue header chunk array.
	call	ChunkArrayAppend	; ds:di - new element
	LONG jc	memErr

	Assert	e	ah, 0		; clue number should fit in a byte
	mov	ds:[di].CH_clueNumber, al
	call	EngineConnectClueToCorrespCell	; ax = corresponding
						; cell token
	
	mov	ds:[di].CH_cellToken, ax	; record the corresponding
						; cell token within
						; the new element
	
	; The next piece of information within the clue information is
	; the actual clue text.  This text is read into a clue data
	; chunk array and a reference to that array is kept in the
	; clue header element.
	Assert	e	dh, C_COMMA
	call	StringAsciiConvertToInteger	; ax = number of data bytes
	jc	sourceErr
	call	EngineSetClueInClueData		; ax = element number
	jc	unlockAndFinish			; error occured

	; init clue data token in header for where clue data is.
	mov	dx, ss:[clueDataBlockHandle]
	mov	ds:[di].CH_textClueDataToken.CDT_blockHandle, dx
	mov	ds:[di].CH_textClueDataToken.CDT_element, ax

EC <	call	ECCheckChunkArray					>
	; see if bx (buffer offset) has reached its end - cx
	; where cx = original buffer offset + number of bytes
	cmp	bx, cx
EC <	ERROR_G	ENGINE_READING_CLUES_PAST_BUFFER			>
	LONG jl	readClue

EC <	cmp	bx, cx							>
EC <	ERROR_NE	ENGINE_CLUES_NOT_READ_IN_PROPERLY		>

	; unlock all blocks that were just used
	mov	bx, ss:[clueHeaderBlockHandle]	; clue header block handle
	Assert	lmem	bx
	call	MemUnlock

	mov	bx, ss:[clueDataBlockHandle]
	Assert	lmem	bx
	call	MemUnlock

	mov	bx, cx			; new buffer offset
	clc				; successful completion
finish:
	.leave
	ret
sourceErr:
	mov	di, SOURCE_ERR
	call	CwordHandleError
	jmp	unlockAndFinish
memErr:
	mov	di, MEM_ERR
	call	CwordHandleError
unlockAndFinish:
	mov	bx, ss:[clueHeaderBlockHandle]
	call	MemUnlock
	mov	bx, ss:[clueDataBlockHandle]
	call	MemUnlock
	stc
	jmp	finish
EngineInitializeClueHeaders	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnginePrepareToReadClues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do all preparations before actually reading in the
		clues from the buffer passed from the File module.

CALLED BY:	ENGINE INTERNAL	(EngineInitializeClueHeaders)

PASS:		dx	- block handle to clue header block
		ax	- number of bytes of clues in buffer
		es:bx	- buffer to read from.
			  each clue is on its own line and
			  'enter' and 'linefeed' characters
			  are ignored during the initialization.

RETURN:		ax	- current clue data chunk handle
		dx	- offset of end of clue bytes buffer
			    Will be used to check when we are
			    done reading the clues.
		*ds:si	- clue header chunk array

DESTROYED:	nothing
SIDE EFFECTS:
	The clue header block is LOCKED
	The current clue data block is LOCKED.

PSEUDO CODE/STRATEGY:
	Initialize the unintialized local variables inherited from
		EngineInitializeClueHeaders.
	Lock the appropriate Clue Header block and Clue Data block
		according to the direction of the clues that are being
		read in.  Get the chunk array chunk handles ready for
		access.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnginePrepareToReadClues	proc	near
	uses	bx
	.enter	inherit	EngineInitializeClueHeaders

	push	ax			; number of clue bytes in buffer
	Assert	EngineTokenType	dx

	; Prepare ds:si to be the clue header array.  The block
	; containing this block must be locked first.

	mov	bx, dx			; clue header block handle
	call	MemLock			; ax = clue header block address

	mov	ds, ax			; clue header block address

	mov	si, ds:[CHBH_clueHeaderChunkHandle]	; *ds:si = array
	push	ds, si			; save clue header array

EC <	call	ECCheckChunkArray					>

	; Prepare the clue data chunk array for access in the future. 
	; The block containing this array must be locked.

	mov	bx, ds:[CHBH_currentClueDataBlockHandle]
	mov	ss:[clueDataBlockHandle], bx	; clue data block handle
	Assert	lmem	bx
	call	MemLock			; ax = clue data block address

	mov	ds, ax
	mov	ss:[clueDataSegment], ds
	mov	ax, ds:[CDBH_clueDataChunkHandle]
	mov	ss:[clueDataChunkHandle], ax

EC <	xchg	si, ax							>
EC <	call	ECCheckChunkArray					>
EC <	xchg	si, ax							>

	pop	ds, si			; clue header array

	; Prepare the ending condition for the reading in clues loop.
	; The loop is over when the end of the clues buffer is reached.

	pop	dx
	add	dx, ss:[initBufferOffset]	; offset of end of
						; clue bytes buffer
	.leave
	ret
EnginePrepareToReadClues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineConnectClueToCorrespCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the link between the clue and cell.

CALLED BY:	ENGINE INTERNAL	(EngineInitializeClueHeaders)
PASS:		ax	- clue number
		*ds:si	- clue header array
		ds:di	- clue header array element

RETURN:		ax	- corresponding cell token

DESTROYED:	ax used for return value
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		Perform a binary search
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineConnectClueToCorrespCell	proc	near
	uses	bx,cx,dx,si,di,ds
	.enter	inherit	EngineInitializeClueHeaders

EC <	call	ECCheckChunkArray					>

	Assert	e	ah, 0
	mov	cx, ax				; clue number
	call	ChunkArrayPtrToElement		; ax = element
						;    = clue token

	mov	dx, ss:[engToken]
	EngineGetCellArrayDSSI			; ds:si	= array

	; find the clue token offset in the CellData to see where to set
	; the corresponding clue/cell token link
	mov	dx, offset CD_acrossClueToken
	cmp	ss:[direction], ACROSS
	je	haveDir
	mov	dx, offset CD_downClueToken	
haveDir:

	call	EngineConnectClueToCorrespCellBinarySearch

	mov	bx, ss:[engToken]
	call	MemUnlock

	.leave
	ret
EngineConnectClueToCorrespCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineConnectClueToCorrespCellBinarySearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform binary search on cell array looking for 
		a cell number that matches the clue number.
		There are multiple cells with the same number. The last
		cell before the number changes is the one we are looking
		for. So after finding a cell with the correct number
		search further in the chunk array to find the last 
		cell with this number.
		Store ClueToken in that cell data and return the
		CellToken

CALLED BY:	EngineConnectClueToCorrespCell

PASS:		
		*ds:si - cell data array
		dx - direction of clue
		cl - clue number being searched for
		ax - ClueToken

RETURN:		
		ax - CellToken

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineConnectClueToCorrespCellBinarySearch		proc	near
	uses	bx,cx,dx,bp,di
	.enter

EC <	call	ECCheckChunkArray

	;   The minimum value of the cell token is the clue number - 1
	;   That would be the case of every cell having a number.
	;

	mov	bl,cl				;clue number
	dec	bl
	clr	bh				;high byte of min cell token

	;   The maximum value of the cell token is the # of cells -1

	push	cx				;clue number
	call	ChunkArrayGetCount		;
	dec	cx				;
	mov	bp,cx				;max cell token
	pop	cx				;clue number


	push	ax				;ClueToken

	;    Check for min or max being the correct value.
	;    This simplifies the termination condition in the
	;    the binary search
	;

	mov	ax,bx				;min cell token
	call	ChunkArrayElementToPtr
	cmp	cl,ds:[di].CD_number
	je	foundOne

	mov	ax,bp				;max cell token
	call	ChunkArrayElementToPtr
	je	foundOne

nextOne:
	mov	ax,bx				;min
	add	ax,bp				;+max
	shr	ax,1				;new medium
EC <	cmp	ax,bx				
EC <	ERROR_E CWORD_BINARY_SEARCH_FOR_CELL_WITH_NUMBER_FAILED
EC <	cmp	ax,bp				
EC <	ERROR_E CWORD_BINARY_SEARCH_FOR_CELL_WITH_NUMBER_FAILED
	call	ChunkArrayElementToPtr
	cmp	cl,ds:[di].CD_number
	je	foundOne
	ja	setMin
	mov	bp,ax				;change max
	jmp	nextOne
setMin:
	mov	bx,ax				;change min
	jmp	nextOne

foundOne:
	;    Do linear search to find last cell with this number
	;

	inc	ax				;next cell
	call	ChunkArrayElementToPtr
	jc	foundIt				;jmp of no more cells
	cmp	cl,ds:[di].CD_number
	je	foundOne

foundIt:
	dec	ax				;prev CellToken
	pop	bx				;ClueToken
	call	ChunkArrayElementToPtr
	add	di,dx				;offset for direction
	mov	ds:[di],bx			;store ClueToken in cell

	.leave
	ret
EngineConnectClueToCorrespCellBinarySearch		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetClueInClueData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write clue data from buffer into the clue data
		chunk array.

CALLED BY:	ENGINE INTERNAL	(EngineInitializeClueHeaders)

PASS:		ax	- number of data bytes
		es:bx	- buffer to read clue data from
		bp	- inherited stack frame

RETURN:		ax	- element number
		bx	- updated buffer offset pointing to byte
			  after the clue.
		CF	- set if error occured, clear otherwise

DESTROYED:	ax used for return value
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the Clue Data LMem block, 
		  moving it on the heap and invalidating stored
		  segment pointers and current register or stored 
		  offsets to it.

PSEUDO CODE/STRATEGY:
	First make sure there is enough room in the current clue data
	block.	Append a new element to the chunk array in the clue
	data block and copy the clue size and data/text to the new
	element. 
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetClueInClueData	proc	near
	uses	cx,di,si,ds,es
	.enter	inherit	EngineInitializeClueHeaders

	mov	ds, ss:[clueDataSegment]
	mov	si, ss:[clueDataChunkHandle]	; ds:si = clue data array
EC <	call	ECCheckChunkArray					>

	mov	cx, ax			; clue data bytes and loop
					; 	counter
	add	ax, size ClueData	; size of element = size of
					; ClueData + size of variable
					; clue data

	call	EngineMakeNewDataBlockIfNeeded	; *ds:si - clue data
						;	chunk array						

	call	ChunkArrayAppend	; ds:di - new element
	jc	memErr
	mov	ss:[clueDataSegment], ds	; the block may have
						; moved and the old
						; segment pointer may
						; be invalid
EC <	tst	cx							>
EC <	ERROR_Z	ENGINE_CLUE_DATA_BYTES_IS_ZERO				>

	push	di, si			; element pointer, 
					; clue data array chunk handle
	mov	ds:[di].CD_size, cx

	; Copy the clue data to the new element	
	; prepare arguments for movsb - bytes from ds:si -> es:di

	lea	di, ds:[di].CD_data
	segxchg	ds, es, ax
	mov	si, bx
	rep	movsb				; copy the data bytes

EC <	cmp	{byte}ds:[si-1], C_ENTER				>
EC <	ERROR_E	ENGINE_C_ENTER_IN_BUFFER_DATA				>

	; Set buffer offset to beginning of next line.
	; At the end of the line, there is always a C_ENTER folloed by
	; a C_LINEFEED character.  These characters will be overlooked.
notEnter:
	lodsb				; al = ds:si buffer character
	cmp	al, C_ENTER
	jne	notEnter

	; fix up the string pointers
	segmov	ds, es, ax
	mov	bx, si			; buffer offset
	inc	bx			; buffer adjustment for
					; C_LINEFEED at end of line

	pop	di, si			; element pointer, clue data array
	call	ChunkArrayPtrToElement		; ax - element number
						; 	(from 0)
	clc				; successful completion
finish:
	.leave
	ret
memErr:
	mov	di, MEM_ERR
	call	CwordHandleError
	jmp	finish

EngineSetClueInClueData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMakeNewDataBlockIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a new data block if the current one is 
		larger than ENGINE_DEFAULT_HEAP_SIZE.

CALLED BY:	ENGINE INTERNAL	(EngineSetClueInClueData)
PASS:		*ds:si 	- clue data chunk array handle
		bp	- inherited stack frame

RETURN:		*ds:si 	- possibly _new_ clue data chunk array handle

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Look at the size of the current clue data block, if it is
	more than was originally allocated, a new data block is
	needed.  Allocate the new block and update the local
	variables.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMakeNewDataBlockIfNeeded	proc	near
	uses	ax,bx,cx
	.enter	inherit EngineSetClueInClueData

; CHECK if ds and si trashed by macro

	; Get the size of the lmem chunk pointed to by ds:si
	ChunkSizeHandle	ds, si, ax		; ax - size of lmem chunk
	cmp	ax, ENGINE_DEFAULT_HEAP_SIZE
	jl	finish

	; unlock the current clue data block since it is full
	mov	bx, ss:[clueDataBlockHandle]
	call	MemUnlock

	; Allocate and Initialize the new data block
	call	EngineMakeClueDataBlock		; bx - block handle
	jc	finish

	mov	ss:[clueDataBlockHandle], bx
	call	MemLock				; ax - clue data segment
	
	; update the local vars in EngineSetClueInClueData
	mov	ds, ax				; clue data segment
	mov	ss:[clueDataSegment], ds
	mov	si, ds:[CDBH_clueDataChunkHandle]
	mov	ss:[clueDataChunkHandle], si

	; make the new data block the current clue data 
	; block in the clue header array
	push	ds				; clue data segment
	mov	cx, bx				; clue data block handle
	mov	bx, ss:[clueHeaderBlockHandle]
	call	MemLock				; ax - segment
	mov	ds, ax
	mov	ds:[CHBH_currentClueDataBlockHandle], cx
	call	MemUnlock
	pop	ds				; clue data segment
finish:
	.leave
	ret
EngineMakeNewDataBlockIfNeeded	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineNotificationCluesDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Basically, this is for the File Module to let the
		Engine module know that it is finished reading in the
		clues.  The Engine module takes this opportunity to
		extend the Cell/Clue links.

CALLED BY:	GLOBAL	(FileReadSourceDocument)
PASS:		dx	- engine token

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineNotificationCluesDone	proc	near
	.enter

	Assert	EngineTokenType	dx
	call	EngineExtendClueTokenLinksToAllCells

	.leave
	ret
EngineNotificationCluesDone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineExtendClueTokenLinksToAllCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend the Clue Token links to all cells that have not
		had their links set.

CALLED BY:	ENGINE INTERNAL	(EngineNotificationCluesDone)
PASS:		dx	- engine token
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	First extend the across clue tokens, then extend the 
	down clue tokens.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineExtendClueTokenLinksToAllCells	proc	near
	uses	bx,cx,dx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si = cell array

	push	dx				; engine token

	clr	dx
	mov	cl, ds:[CBH_columns]
	mov	bx, cs
	mov	di, offset EngineExtendClueLinksAcrossCallback
	call	ChunkArrayEnum	

	mov	ch, ds:[CBH_rows]
	call	EngineExtendDownClueTokensInCellArray

	pop	bx				; engine token	
	call	MemUnlock

	.leave
	ret
EngineExtendClueTokenLinksToAllCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineExtendClueLinksAcrossCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend the Across clue token links of all cells.

CALLED BY:	ENGINE INTERNAL	
		 (ChunkArrayEnum from EngineExtendClueTokenLinksToAllCells)

PASS:		cl	- number of columns
		dx	- current across clue token
		*ds:si 	- array
		ds:di 	- array element being enumerated

RETURN:		dx	- updated across clue token if necessary
		carry	- set to end enumeration
			- clear to continue
				(always clear)

DESTROYED:	nothing
SIDE EFFECTS:	
	Must be a far call because it's a callback routine.

PSEUDO CODE/STRATEGY:
	If a cell is on the left edge of the board or has a hole
	on its left side, this cell already has its across clue
	token set and resets the current across clue token.  If
	not, the across clue token is taken from the current across
	clue token that is passed into the procedure.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineExtendClueLinksAcrossCallback	proc	far
	uses	ax,bx,di,bp
	.enter
	
	; if cell is a hole, no clue token is necessary
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	done

	mov	bx, di				; given element pointer
	call	ChunkArrayPtrToElement		; ax = given element number
	mov	bp, ax				; given element number

	; see if cell is on left edge of board, if yes - reset clue token
	div	cl			; element/columns
	tst	ah			; 0 if on edge
	jz	resetToken
	
	; see if cell on left is a hole, if yes - reset clue token
	mov	ax, bp				; given element number
	dec	ax				; element on left
	call	ChunkArrayElementToPtr		; ds:di - left element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	resetToken

	mov	di, bx				; given element pointer
	mov	ds:[di].CD_acrossClueToken, dx
done:
	clc
	.leave
	ret

resetToken:
	mov	di, bx				; given element ptr
	mov	dx, ds:[di].CD_acrossClueToken
	jmp	done
EngineExtendClueLinksAcrossCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineExtendDownClueTokensInCellArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend the Down clue token links of all cells.

CALLED BY:	ENGINE INTERNAL	(EngineExtendClueTokenLinksToAllCells)
PASS:		ch	- number of rows
		cl	- number of columns
		*ds:si 	- cell array

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	If a cell is on the top edge of the board or has a hole
	on its top side, this cell already has its Down clue
	token set and resets the current Down clue token.  If
	not, the Down clue token is taken from the current Down
	clue token that is passed into the procedure.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineExtendDownClueTokensInCellArray	proc	near
	uses	ax,bx,cx,dx,bp
	.enter
	
	ForceRef	givenElementPtr
	ForceRef	givenElementNumber

	mov	bl, ch			; rows
	clr	bh, ch

	mov	di, bx			; rows
	mov	bp, cx			; columns

	clr	cx			; loop index for outer loop
	clr	dx			; current down clue token
					; won't really be used from
					; this initial setting

	; For each column, loop over every row
nextColumn:
	mov	ax, cx			; new cell element
	clr	bx			; inner loop counter
nextRow:
	call	EngineSetDownClueTokenInCell

; BP OK?

	inc	bx			; increment loop counter
	add	ax, bp			; element number + columns
	cmp	bx, bp
	jl	nextRow

	inc	cx			; outer loop counter
	cmp	cx, di
	jl	nextColumn

	.leave
	ret
EngineExtendDownClueTokensInCellArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSetDownClueTokenInCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend the Down clue.  This is used almost like a 
		callback routine.  The reason this is not a callback
		used by ChunkArrayEnum for setting extending down 
		clue token links is that traversing down each column
		in the crossword grid cannot be done by a linear
		enumeration.

CALLED BY:	ENGINE INTERNAL	(EngineExtendDownClueTokensInCellArray)
PASS:		ax	- element number
		dx	- current down clue token
		*ds:si	- cell array
		bp	- columns

RETURN:		dx	- updated down clue token if necessary.

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	If a cell is on the top edge of the board or has a hole
	on top of it, this cell already has its down clue
	token set and resets the current down clue token.  If
	not, the down clue token is taken from the current down
	clue token that is passed into the procedure.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSetDownClueTokenInCell	proc	near
	uses	ax,cx,di
	.enter

	call	ChunkArrayElementToPtr		; ds:di - element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>
	mov	cx, di				; given element ptr

	; if cell is a hole, no clue token is necessary
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	finish

	; see if cell is on top edge of board, if yes - reset clue token
	cmp	ax, bp
	jl	resetToken

; CHECK CX after ELEMENT TO PTR  ??

	; see if cell on top is a hole, if yes - reset clue token
	sub	ax, bp				; element on top
	call	ChunkArrayElementToPtr		; ds:di - left element
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	resetToken

	mov	di, cx				; given element ptr
	mov	ds:[di].CD_downClueToken, dx
finish:
	.leave
	ret
resetToken:
	mov	di, cx				; given element ptr
	mov	dx, ds:[di].CD_downClueToken
	jmp	finish
EngineSetDownClueTokenInCell	endp

;----------------------------------------------------------------------------
;	Routines for making the user solution document
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineWriteCellData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the user solution letter and cell flags of all
		cells to the buffer provided.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		es:bp	- buffer
RETURN:		bp	- new offset into buffer pointing to next
			  empty byte.
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineWriteCellData	proc	near
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si - cell array
	
	mov	bx, cs
	mov	di, offset EngineWriteSingleCellCallback
	call	ChunkArrayEnum			; bp - new offset

	EngineUnlockDX

	.leave
	ret
EngineWriteCellData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineWriteSingleCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the cell's user letter and flags to the buffer
		and increment the buffer offset.

CALLED BY:	ENGINE INTERNAL	(ChunkArrayEnum from EngineWriteCellData)
PASS:		es:bp	- buffer to write user letter and cell flags
		*ds:si	- array
		ds:di	- array element being enumerated

RETURN:		bp	- new buffer offset, set to be the next empty
			  space in buffer.
		carry	- set to end enumeration
			- clear to continue
			(always clear)

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	This procedure must be a far call since it is a callback.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineWriteSingleCellCallback	proc	far
	uses	ax
	.enter

	; write the user letter
	mov	al, ds:[di].CD_userLetter
	mov	es:[bp], al

	inc	bp

	; write the cell flags
	mov	al, ds:[di].CD_flags
	mov	es:[bp], al

	inc	bp

	clc
	.leave
	ret
EngineWriteSingleCellCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineReadCellData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the user solution letter and cell flags of all
		cells from the buffer provided.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		es:bp	- buffer

RETURN:		bp	- new buffer offset pointing to next byte
			 	to read
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineReadCellData	proc	near
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si - cell array
	
	mov	bx, cs
	mov	di, offset EngineReadSingleCellCallback
	call	ChunkArrayEnum			; bp - new buffer offset

	EngineUnlockDX

	.leave
	ret
EngineReadCellData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineReadSingleCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the cell's user letter and flags from the buffer
		and increment the buffer offset.

CALLED BY:	ChunkArrayEnum from EngineReadCellData
PASS:		es:bp	- buffer to read user letter and cell flags from
		*ds:si	- array
		ds:di	- array element being enumerated

RETURN:		bp	- new buffer offset, set to be the next empty
			  space in buffer.
		carry	- set to end enumeration
			- clear to continue
			(always clear)

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	This procedure must be a far call since it is a callback.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineReadSingleCellCallback	proc	far
	uses	ax
	.enter

	; read the user letter
	mov	al, es:[bp]
	mov	ds:[di].CD_userLetter, al

	inc	bp

	; read the cell flags
	mov	al, es:[bp]
	Assert	CellFlags	ax

	mov	ds:[di].CD_flags, al

	inc	bp

	clc

	.leave
	ret
EngineReadSingleCellCallback	endp

;----------------------------------------------------------------------------
;			BASIC	ACCESS
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineGetFirstExistentNonHoleCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the first existing non-hole cell.

CALLED BY:	GLOBAL
PASS:		dx	- engine token

RETURN:		bp	- CellTokenType

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineGetFirstExistentNonHoleCell	proc	near
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			: *ds:si = array
	
	mov	bx, cs
	mov	di, offset EngineSearchForFirstCellCallback
	call	ChunkArrayEnum			; bp - returned cell token 
		
	EngineUnlockDX

	.leave
	ret
EngineGetFirstExistentNonHoleCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSearchForFirstCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first cell that is a non-hole and is not
		non-existent.

CALLED BY:	ENGINE INTERNAL
		   (ChunkArrayEnum from EngineGetFirstExistentNonHoleCell)
PASS:		al	- clue number
		*ds:si	- array
		ds:di	- array element being enumberated

RETURN:		bp	- CellToken found  (CellTokenType)
		carry	- set to end enumeration
			- clear to continue
DESTROYED:	none
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	must be a far call because it is a callback procedure.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSearchForFirstCellCallback	proc	far
	uses	ax
	.enter

	; If the current cell element is a hole or is non-existent,
	; just exit out of the procedure
	test	ds:[di].CD_flags, mask CF_HOLE
	jnz	notFound
	test	ds:[di].CD_flags, mask CF_NON_EXISTENT
	jnz	notFound
	
	call	ChunkArrayPtrToElement		; ax - element
	mov	bp, ax				; element
	stc					; end enumeration
finish:
	.leave
	ret
notFound:
	clc
	jmp	finish
EngineSearchForFirstCellCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMapCellNumberToCellToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the cell token containing the given number.

CALLED BY:	GLOBAL
PASS:		al	- number
		dx	- engine token

RETURN:		ax	- cell token
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMapCellNumberToCellToken	proc	near
	uses	bx,si,di,ds
	.enter
	
	Assert	EngineTokenType	dx
	EngineGetCellArrayDSSI			; *ds:si - cell array

	mov	bx, cs
	mov	di, offset EngineSearchForCellGivenNumberCallback
	call	ChunkArrayEnum			; ax - cell token of cell
						;  containing clue number

	EngineUnlockDX

	.leave
	ret
EngineMapCellNumberToCellToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSearchForCellGivenNumberCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the cell token that contains the given number

CALLED BY:	ENGINE INTERNAL (ChunkArrayEnum from
				and EngineMapCellNumberToCellToken)

PASS:		al	- number
		*ds:si	- array
		ds:di	- array element being enumberated

RETURN:		ax	- cell token of cell containing number
		carry	- set to end enumeration
			- clear to continue
DESTROYED:	none
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	See if the given number equals the number in the cell,
	if one exists.  If yes, set cx to that cell token and
	set the carry flag.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSearchForCellGivenNumberCallback	proc	far
	.enter

	test	ds:[di].CD_flags, mask CF_NUMBER
	jz	notFound

	cmp	ds:[di].CD_number, al
	je	found
notFound:
	clc
done:
	.leave
	ret
found:
	call	ChunkArrayPtrToElement		; ax - element number
	stc
	jmp	done
EngineSearchForCellGivenNumberCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMapClueNumberToClueToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the clue token given the clue number and
		direction.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		al	- clue number
		cx	- direction (ACROSS or DOWN)

RETURN:		cx	- clue token of clue containing number

DESTROYED:	cx used for return value
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMapClueNumberToClueToken	proc	near
	uses	ax,bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx

	mov	bx, cx
	EngineGetClueHeaderArrayDSSI		; *ds:si - clue header array
	push	bx				; clue header handle

	mov	cx, ENGINE_NO_CLUE	
	mov	bx, cs
	mov	di, offset EngineSearchForClueGivenNumberCallback
	call	ChunkArrayEnum			; cx - clue token of clue
						;  containing given number
	Assert	ne	cx, ENGINE_NO_CLUE	

	pop	bx				; clue header handle
	Assert	lmem	bx	
	call	MemUnlock

	.leave
	ret
EngineMapClueNumberToClueToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineSearchForClueGivenNumberCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the clue token of the clue given the number of
		the clue.

CALLED BY:	ENGINE INTERNAL
			(ChunkArrayEnum from EngineMapClueNumberToClueToken)
PASS:		al	- clue number to look for
		ds:di	- enumerated element
		*ds:si	- clue header array

RETURN:		cx	- clue token of clue containing given number
		CF	- set to end enumeration, clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineSearchForClueGivenNumberCallback	proc	far
	uses	ax
	.enter

	cmp	al, ds:[di].CH_clueNumber
	je	found
	clc
done:
	.leave
	ret
found:
	call	ChunkArrayPtrToElement		; ax - element number
	mov	cx, ax
	stc
	jmp	done
EngineSearchForClueGivenNumberCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineMapClueTokenToClueNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the clue number of a given clue.

CALLED BY:	GLOBAL
PASS:		dx	- engine token
		ax	- clue token
		bx	- direction (ACROSS or DOWN)

RETURN:		al	- clue number

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineMapClueTokenToClueNumber	proc	near
	uses	bx,si,di,ds
	.enter

	Assert	EngineTokenType	dx
	Assert	ClueTokenType	ax, bx

	EngineGetClueHeaderArrayDSSI		; *ds:si - clue header array
						; bx - clue header
						;     block handle
	call	ChunkArrayElementToPtr		; ds:di - element
	mov	al, ds:[di].CH_clueNumber

	call	MemUnlock		; unlock the clue header block

	.leave
	ret
EngineMapClueTokenToClueNumber	endp

;----------------------------------------------------------------------------
;		ENGINE VALIDATION ROUTINES - stays in ENGINE
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineIsEndOfLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if character is an end of line character - 
		C_ENTER or C_LINEFEED.

CALLED BY:	EngineSetSolutionLetters
PASS:		al	- letter

RETURN:		CF	- set if IS an end of line character,
			  clear otherwise.

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineIsEndOfLine	proc	near
	.enter
	
	cmp	al, C_ENTER
	je	ok
	cmp	al, C_LINEFEED
	jne	notEOL
ok:
	stc
exit:
	.leave
	ret
notEOL:
	clc
	jmp	exit
EngineIsEndOfLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EngineIsValidSolutionChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	TRUE if a character is between A-Z, an ENGINE_NON_EXIST,
		or an ENGINE_HOLE.  FALSE otherwise.

CALLED BY:	EngineSetSolutionLetters

PASS:		al 	- letter

RETURN:		CF	- (carry flag) clear if valid char,
			  set if invalid char,

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Assume all capital letters.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EngineIsValidSolutionChar	proc	near
	.enter

	cmp	al, ENGINE_HOLE
	je	ok
	cmp	al, ENGINE_NON_EXIST
	je	ok
	cmp	al, C_CAP_A
	jl	outBounds
	cmp	al, C_CAP_Z
	jg	outBounds
ok:
	clc
exit:
	.leave
	ret
outBounds:
	stc
	jmp	exit

EngineIsValidSolutionChar	endp

CwordFileCode	ends




