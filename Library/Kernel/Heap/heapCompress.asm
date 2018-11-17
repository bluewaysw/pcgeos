COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Kernel/Heap
FILE:		heapCompress.asm

AUTHOR:		Joon Song, Feb 20, 1997

ROUTINES:
	Name			Description
	----			-----------
    EXT LZGAllocCompressStack	Allocate LZG compress stack
    EXT LZGCompress		LZG compress
    EXT LZGUncompress		LZG uncompress
    EXT LZGGetUncompressedSize	Get uncompressed size of compressed data

    EXT LZGALLOCCOMPRESSSTACK	LZGAllocCompressStack c-stub
    EXT LZGCOMPRESS		LZGCompress c-stub
    EXT LZGUNCOMPRESS		LZGUncompress c-stub
    EXT LZGGETUNCOMPRESSEDSIZE	LZGGetUncompressedSize c-stub

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	2/20/97   	Initial revision


DESCRIPTION:
		
	Fast! compress/uncompress

	$Id: heapCompress.asm,v 1.1 97/04/05 01:14:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;		 Constants for LZG Compression
;------------------------------------------------------------------------------

LZG_PAIR_POSITION_BITS		equ	10
LZG_PAIR_LENGTH_BITS		equ	(14-LZG_PAIR_POSITION_BITS)
LZG_MIN_MATCH_LENGTH		equ	3
LZG_MAX_MATCH_LENGTH		equ	((1 shl LZG_PAIR_LENGTH_BITS) - 1)
LZG_MAX_LONG_MATCH_LENGTH	equ	0xff
LZG_MAX_LITERAL_LENGTH		equ	0x07
LZG_MAX_LITERAL_STRING_LENGTH	equ	0x1f
LZG_MAX_LONG_LIT_STRING_LENGTH	equ	0xff
LZG_MAX_RUN_LENGTH		equ	0x1f
LZG_SMALL_PAIR_FLAG		equ	0x80
LZG_LITERALS_FLAG		equ	0x40
LZG_RUN_LENGTH_FLAG		equ	0x20
LZG_END_MARKER			equ	(LZG_LITERALS_FLAG+LZG_RUN_LENGTH_FLAG)

LZG_STRING_TABLE_SIZE		equ	256
LZG_DICTIONARY_SIZE		equ	(1 shl LZG_PAIR_POSITION_BITS)
LZG_CHAIN_MASK			equ	(LZG_DICTIONARY_SIZE - 1)
LZG_STACK_SIZE			equ	256

;------------------------------------------------------------------------------
;		Structures for LZG Compression
;------------------------------------------------------------------------------

LZGCompressStack	struct
    ThreadPrivateData	<>
    LZGCS_oldSS		word
    LZGCS_oldSP		word
    LZGCS_srcOffset	word
    LZGCS_dstOffset	word
    LZGCS_matchPos	word
    LZGCS_literalPos	word
    LZGCS_flagCount	word
    LZGCS_strings	word LZG_STRING_TABLE_SIZE dup (?)
    LZGCS_chains	word LZG_DICTIONARY_SIZE dup (?)
    LZGCS_stackBottom	byte LZG_STACK_SIZE dup (?)
    LZGCS_stackTop	label byte
LZGCompressStack	ends

;------------------------------------------------------------------------------
;		 Macros for LZG Compression
;------------------------------------------------------------------------------

.186


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MACRO:		CalcHashIndex

DESCRIPTION:	Calculate hash index

ARGUMENTS:	ds:si	= string

RETURN:		bx	= hash index

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcHashIndex	macro
	mov	bx, {word}ds:[si]
	rol	bl, 1
	ror	bh, 1
	xor	bl, bh
	xor	bl, {byte}ds:[si+2]
	clr	bh
	shl	bx, 1
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MACRO:		InsertString

DESCRIPTION:	Insert string into string hash table

ARGUMENTS:	ds:si	= string
		bx	= hash index

DESTROYED:	ax, bx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertString	macro
	mov	ax, ss:LZGCS_strings[bx]
	mov	ss:LZGCS_strings[bx], si
	mov	bx, si
	and	bx, LZG_CHAIN_MASK
	shl	bx, 1
	mov	ss:LZGCS_chains[bx], ax
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MACRO:		SetLiteralByteFlag

DESCRIPTION:	Set flag indicating literalByte

ARGUMENTS:	es:di	= dest buffer
		bp	= flag position

DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetLiteralByteFlag	macro
	local	setFlag

	dec	ss:[LZGCS_flagCount]
	jns	setFlag

	mov	ss:[LZGCS_flagCount], 7
	clr	{byte}es:[di]
	mov	bp, di
	inc	di
setFlag:
	stc
	rcl	{byte}es:[bp], 1
endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MACRO:		SetNonLiteralByteFlag

DESCRIPTION:	Set flag indicating non-literalByte

ARGUMENTS:	es:di	= dest buffer
		bp	= flag position

DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNonLiteralByteFlag	macro
	local	setFlag

	dec	ss:[LZGCS_flagCount]
	jns	setFlag

	mov	ss:[LZGCS_flagCount], 7
	clr	{byte}es:[di]
	mov	bp, di
	inc	di
setFlag:
	shl	{byte}es:[bp], 1
endm

;------------------------------------------------------------------------------
;		 Code for LZG Compression/Decompression
;------------------------------------------------------------------------------

CompressionCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LZGAllocCompressStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate LZG compress stack

CALLED BY:	EXTERNAL
PASS:		bx	= handle of geode to own compress stack
			  (0 = geode owning current running thread)
RETURN:		^hbx = compress stack
		carry set if allocation error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	2/19/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LZGAllocCompressStack	proc	far
	uses	ax,cx
	.enter

	tst	bx				; handle of geode to own block
	jnz	alloc
	mov	bx, ss:[TPD_processHandle]
alloc:
	mov	ax, size LZGCompressStack
	mov	cx, ALLOC_DYNAMIC_NO_ERR
	call	MemAllocSetOwnerFar

	.leave
	ret
LZGAllocCompressStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LZGCompress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LZG compress

CALLED BY:	EXTERNAL
PASS:		ds:si	= uncompressed data		(input buffer)
		es:di	= compressed data buffer	(output buffer)
		cx	= size of uncompressed data	(input size)
		^hbx	= LZG compress stack
RETURN:		cx	= size of compressed data	(output size)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	2/18/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LZGCompress	proc	far
	uses	ax,bx,dx,si,di,bp
	.enter

	; Switch to LZG compress stack

	push	ds, si, es, di, cx
	call	MemPLock
	mov	es, ax
	clr	di
	segmov	ds, ss
	clr	si
	mov	cx, (size ThreadPrivateData)/2
	rep	movsw
	mov	es:[TPD_blockHandle], bx
	mov	es:[TPD_stackBot], offset LZGCS_stackBottom
	pop	ds, si, es, di, cx

	movdw	dxbp, sssp
	mov	ss, ax				; MUST BE IN THIS ORDER!
	mov	sp, offset LZGCS_stackTop	; MUST BE IN THIS ORDER!
	mov	ss:[LZGCS_oldSS], dx
	mov	ss:[LZGCS_oldSP], bp
	mov	ss:[LZGCS_srcOffset], si
	mov	ss:[LZGCS_dstOffset], di
	clr	ss:[LZGCS_flagCount]

	; Initialize strings hash table

	push	es, di, cx
	segmov	es, ss
	mov	di, offset LZGCS_strings
	mov	cx, length LZGCS_strings
	mov	ax, -1
	rep	stosw
	pop	es, di, cx

	; Now compress data

newLiteral:
	mov	ss:[LZGCS_literalPos], si
compress:
	jcxz	doneCompress
	cmp	{word} ds:[si], 0
	je	runlength

	CalcHashIndex
	tst	ss:LZGCS_strings[bx]
	js	insert

	call	SearchDictionary
	cmp	dx, LZG_MIN_MATCH_LENGTH
	jge	pair
insert:
	InsertString
	inc	si
	dec	cx
	jmp	compress

	; Write pair
pair:
	call	WritePair
	jmp	newLiteral

	; Write run length
runlength:
	call	WriteRunLength
	jmp	newLiteral

	; Finish compress
doneCompress:
	cmp	ss:[LZGCS_literalPos], si
	je	endMarker
	call	WriteLiteral
endMarker:
	SetNonLiteralByteFlag
	mov	al, LZG_END_MARKER
	stosb					; write out end marker

	mov	cx, ss:[LZGCS_flagCount]
	shl	{byte}es:[bp], cl		; left justify last flag byte

	sub	di, ss:[LZGCS_dstOffset]
	mov	cx, di				; cx = size of compressed data

	; Switch back to original stack

	mov	bx, ss:[TPD_blockHandle]
	mov	bp, ss:[LZGCS_oldSP]
	mov	ss, ss:[LZGCS_oldSS]		; MUST BE IN THIS ORDER!
	mov	sp, bp				; MUST BE IN THIS ORDER!

	call	MemUnlockV

	.leave
	ret


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for string in dictionary

CALLED BY:	LZGCompress
PASS:		ds:si	= src buffer
		es:di	= dst buffer
		bx	= hash index
		cx	= size of uncompressed data
RETURN:		dx	= match length
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchDictionary	label	near

	push	bx, cx, di, es			; save registers
	segmov	es, ds, ax			; es = src segment
	clr	dx				; initial match length
	mov	ax, si
	sub	ax, LZG_DICTIONARY_SIZE-1
	cmp	ax, ss:[LZGCS_srcOffset]
	jg	beginSearch
	mov	ax, ss:[LZGCS_srcOffset]

beginSearch:					; ax = start of dictionary
	mov	bx, ss:LZGCS_strings[bx]	; bx = potential match
	cmp	ax, bx				; match inside dictionary?
	jg	doneSearch

searchLoop:
	mov	di, bx				; es:di = dictionary string
	mov	bx, dx				; bx = match length
	mov	cl, ds:[si][bx]			; does the <matchLen+1>
	cmp	cl, es:[di][bx]			;  character match?
	mov	bx, di
	jne	nextString			; skip if mismatch

	push	si
	mov	cx, 0xff
	repe	cmpsb
	pop	si

	xor	cx, 0xff			; cx = matchLen+1
	dec	cx				; cx = matchLen
	cmp	dx, cx
	jge	nextString

	mov	dx, cx				; dx = new matchLen
	mov	ss:[LZGCS_matchPos], bx		; new matchPos

nextString:
	andnf	bx, LZG_CHAIN_MASK
	shl	bx, 1
	mov	bx, ss:LZGCS_chains[bx]		; bx = next potential match

	cmp	ax, bx				; match inside dictionary?
	jle	searchLoop

doneSearch:
	pop	bx, cx, di, es			; restore original reg values

	cmp	dx, cx				; if matchLen >= data size
	jl	done				;  then matchLen = data size
	mov	dx, cx
done:
	retn


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePair
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a <position,length> pair

CALLED BY:	LZGCompress
PASS:		ds:si	= src buffer
		es:di	= dst buffer
		cx	= size of uncompressed data
		dx	= <match length>
RETURN:		si, di, cx updated
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePair	label	near

	cmp	ss:[LZGCS_literalPos], si
	je	writePair
	call	WriteLiteral

writePair:
	SetNonLiteralByteFlag

	mov	ax, si
	sub	ax, ss:[LZGCS_matchPos]	; ax = match distance

	cmp	dx, LZG_MIN_MATCH_LENGTH
	jnz	notSmall
	cmp	ax, 0x007f
	jg	notSmall
	ornf	al, LZG_SMALL_PAIR_FLAG
	stosb
	jmp	insertPair

notSmall:
	cmp	dx, LZG_MAX_MATCH_LENGTH
	jg	notMedium

	xchg	al, ah			; convert to big-endian
	mov	bx, dx			; bx = match length
	CheckHack <(LZG_PAIR_POSITION_BITS-8) eq 2>
	shl	bx, 2
	ornf	al, bl
	stosw
	jmp	insertPair

notMedium:
	xchg	al, ah			; convert to big-endian
	stosw				; write match distance
	mov	al, dl
	stosb				; write match length

insertPair:
	sub	cx, dx			; update data size
insertLoop:
	CalcHashIndex
	InsertString
	inc	si
	dec	dx
	jnz	insertLoop
	retn


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteRunLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write run length

CALLED BY:	LZGCompress
PASS:		ds:si	= src buffer
		es:di	= dst buffer
		cx	= size of uncompressed data
RETURN:		si, di, cx updated
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteRunLength	label	near

	cmp	ss:[LZGCS_literalPos], si
	je	writeRun
	call	WriteLiteral

writeRun:
	SetNonLiteralByteFlag

	mov	dx, cx			; dx = size of uncompressed data
	push	es, di
	segmov	es, ds, di
	mov	di, si
	clr	ax
	CheckHack <LZG_MAX_RUN_LENGTH eq 0x1f>
	mov	cx, LZG_MAX_RUN_LENGTH
	repe	scasb
	xor	cx, LZG_MAX_RUN_LENGTH
	dec	cx
	pop	es, di

	cmp	cx, dx
	jl	10$
	mov	cx, dx
10$:
	mov	ax, cx
	or	al, LZG_LITERALS_FLAG or LZG_RUN_LENGTH_FLAG
	stosb

	add	si, cx
	sub	dx, cx
	mov	cx, dx			; cx = size of uncompressed data
	retn


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteLiteral
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write literal string

CALLED BY:	LZGCompress
PASS:		ds:si	= src buffer
		es:di	= dst buffer
		cx	= size of uncompressed data
RETURN:		si, di, cx updated
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteLiteral	label	near
	mov	ax, si
	mov	si, ss:[LZGCS_literalPos]	
	sub	ax, si

literalLength:
	cmp	ax, LZG_MAX_LITERAL_LENGTH
	jg	literalString

literalByteLoop:
	SetLiteralByteFlag

	movsb
	dec	ax
	jnz	literalByteLoop
	retn

literalString:
	SetNonLiteralByteFlag

	cmp	ax, LZG_MAX_LITERAL_STRING_LENGTH
	jg	longLiteralString

	push	cx
	mov	cx, ax
	ornf	al, LZG_LITERALS_FLAG
	stosb
	shr	cx, 1
	rep	movsw
	jnc	20$
	movsb
20$:	pop	cx
	retn

longLiteralString:
	cmp	ax, LZG_MAX_LONG_LIT_STRING_LENGTH
	jg	veryLongLiteralString

	push	cx
	mov	cx, ax
	mov	ah, al
	mov	al, LZG_LITERALS_FLAG
	stosw
	shr	cx, 1
	rep	movsw
	jnc	30$
	movsb
30$:	pop	cx
	retn

veryLongLiteralString:
	push	ax, cx
	mov	cx, LZG_MAX_LONG_LIT_STRING_LENGTH
	mov	ax, (LZG_MAX_LONG_LIT_STRING_LENGTH shl 8) or LZG_LITERALS_FLAG
	stosw
	shr	cx, 1
	rep	movsw
	jnc	40$
	movsb
40$:	pop	ax, cx
	sub	ax, LZG_MAX_LONG_LIT_STRING_LENGTH
	jmp	literalLength

LZGCompress	endp

kcode	segment		; LZGUncompress needs to be in a fixed segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LZGUncompress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LZG uncompress

CALLED BY:	EXTERNAL
PASS:		ds:si	= compressed data
		es:di	= uncompressed data buffer
RETURN:		cx	= size of uncompressed data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LZGUncompress	proc	far
	uses	ax,bx,dx,si
	.enter
	call	LZGUncompressLow
	.leave
	ret
LZGUncompress	endp

LZGUncompressSource	proc	far
	uses	bx,dx,si
	.enter
	push	si
	call	LZGUncompressLow
	pop	ax
	xchg	ax, si
	sub	ax, si			; ax = source bytes used
	.leave
	ret
LZGUncompressSource	endp
ForceRef LZGUncompress

LZGUncompressLow	proc	near
	.enter
		
	push	di			; save output offset
	clr	ax, cx			; start out with ah = 0, ch = 0

loadFlags:
	lodsb				; load flag byte
	mov	dx, ax			; dh = 0, dl = flags
	dec	dh			; dh = 11111111b, dl = flags

uncompress:
	shl	dh, 1			; if no flags left
	jnc	loadFlags		;   then load next flag byte
	shl	dl, 1			; if not literal byte
	jnc	notLiteralByte		;   then notLiteralByte

	movsb				; copy literal byte
	jmp	uncompress

notLiteralByte:
	lodsb				; load flag byte
	test	al, LZG_SMALL_PAIR_FLAG
	jnz	smallPair

	test	al, LZG_LITERALS_FLAG	; test for literals
	jz	pair			; else do pair

	test	al, LZG_RUN_LENGTH_FLAG
	jnz	runLength

literals::
	and	al, not LZG_LITERALS_FLAG
	jz	longLiterals

	mov	cl, al			; cx = size of literals(*)
	shr	cx, 1			; # of bytes -> # of words
	rep	movsw			; copy literal
	jnc	uncompress		; loop back for more
	movsb				; copy leftover byte
	jmp	uncompress		; loop back for more

longLiterals:
	lodsb				; get long literal length byte
	mov	cl, al			; cx = size of literals(*)
	shr	cx, 1			; # of bytes -> # of words
	rep	movsw			; copy literal
	jnc	uncompress		; loop back for more
	movsb				; copy leftover byte
	jmp	uncompress		; loop back for more

runLength:
	and	al, not (LZG_LITERALS_FLAG or LZG_RUN_LENGTH_FLAG)
	jz	done			; done if no runLength

	mov	cl, al			; cx = size of zeros
	clr	ax			; ax = NULL
	shr	cx, 1			; # of bytes -> # of words
	rep	stosw			; write NULL's
	jnc	uncompress		; loop back for more
	stosb				; write NULL
	jmp	uncompress		; loop back for more

pair:
	mov	cl, al			; cx=cl = 4 length bits, 2 offset bits
	lodsb				; load low 8 bits of dictionary offset
	mov	bl, al			; bl = low 8 bits of dictionary offset
	mov	bh, cl			; bh has high bits of offset
	and	bh, (1 shl (LZG_PAIR_POSITION_BITS-8)) - 1
					; bx = dictionary offset
	neg	bx
	add	bx, di			; bx = position in output buffer
	CheckHack <(LZG_PAIR_POSITION_BITS-8) eq 2>
	shr	cl, 2			; shift out offset bits
	jz	longPair
	xchg	si, bx			; ds:si = source string
	rep	movsb es:		; copy string from dictionary (warning)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more

longPair:
	lodsb				; load long match length
	mov	cl, al			; cx = match length
	xchg	si, bx			; ds:si = source string
	rep	movsb es:		; copy string from dictionary (warning)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more

smallPair:
	andnf	al, not LZG_SMALL_PAIR_FLAG
	mov	bx, di
	sub	bx, ax			; bx = position in output buffer
	xchg	si, bx			; ds:si = source string
	movsb	es:			; copy a byte (not a word)
	movsb	es:			; copy a byte (not a word)
	movsb	es:			; copy a byte (not a word)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more
done:
	mov	cx, di			; cx = end of output
	pop	di			; di = start of output
	sub	cx, di			; cx = size of uncompressed data

	.leave
	ret
LZGUncompressLow	endp

kcode	ends		; LZGUncompress needs to be in a fixed segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LZGGetUncompressedSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get uncompressed size of compressed data

CALLED BY:	EXTERNAL
PASS:		ds:si	= compressed data
RETURN:		cx	= uncompressed size
		carry set if error in compressed data
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	2/20/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LZGGetUncompressedSize	proc	far
	uses	ax,dx,si
	.enter

	clr	ax, cx			; start out with ah = 0

loadFlags:
	lodsb				; load litFlag byte
	mov	dx, ax			; dh = 0, dl = flags
	dec	dh			; dh = 11111111b, dl = flags

calcSize:
	shl	dh, 1			; if no flags left
	jnc	loadFlags		;   then load next flag byte
	shl	dl, 1			; if not literal byte
	jnc	notLiteralByte		;   then notLiteralByte

	inc	si			; skip past literal byte
	add	cx, 1			; update uncompressed size
	jnc	calcSize
	jmp	done			; exit with carry set

notLiteralByte:
	lodsb				; load flag byte
	test	al, LZG_SMALL_PAIR_FLAG
	jnz	smallPair

	test	al, LZG_LITERALS_FLAG	; test for literals
	jz	pair			; else do pair

	test	al, LZG_RUN_LENGTH_FLAG
	jnz	runLength

literals::
	and	al, not LZG_LITERALS_FLAG
	jz	longLiterals

	add	si, ax			; skip past literals in source
	add	cx, ax			; update uncompressed size
	jnc	calcSize
	jmp	done			; exit with carry set

longLiterals:
	lodsb				; get long literal length byte
	add	si, ax			; skip past literals in source
	add	cx, ax			; update uncompressed size
	jnc	calcSize
	jmp	done			; exit with carry set

runLength:
	and	al, not (LZG_LITERALS_FLAG or LZG_RUN_LENGTH_FLAG)
	jz	done			; done if no runLength
	add	cx, ax			; update uncompressed size
	jnc	calcSize
	jmp	done			; exit with carry set

pair:
	inc	si			; skip past low 8 bits of offset
	shr	al, 2			; shift out offset bits
	jz	longPair
	add	cx, ax			; update uncompressed size
	jnc	calcSize
	jmp	done			; exit with carry set

longPair:
	lodsb				; load long match length
	add	cx, ax
	jnc	calcSize
	jmp	done			; exit with carry set

smallPair:
	add	cx, 3
	jnc	calcSize
done:
	.leave
	ret
LZGGetUncompressedSize	endp

;
; pass: ds:si = LZG data
; return: cx = source size
; notes: copied from LZGUncompress, removing output code
;
LZGSourceSize	proc	far
	uses	ax, bx, dx
	.enter

	push	si			; save source offset
	clr	ax, cx			; start out with ah = 0, ch = 0

loadFlags:
	lodsb				; load flag byte
	mov	dx, ax			; dh = 0, dl = flags
	dec	dh			; dh = 11111111b, dl = flags

uncompress:
	shl	dh, 1			; if no flags left
	jnc	loadFlags		;   then load next flag byte
	shl	dl, 1			; if not literal byte
	jnc	notLiteralByte		;   then notLiteralByte

;	movsb				; copy literal byte
	inc	si
;
	jmp	uncompress

notLiteralByte:
	lodsb				; load flag byte
	test	al, LZG_SMALL_PAIR_FLAG
	jnz	smallPair

	test	al, LZG_LITERALS_FLAG	; test for literals
	jz	pair			; else do pair

	test	al, LZG_RUN_LENGTH_FLAG
	jnz	runLength

literals::
	and	al, not LZG_LITERALS_FLAG
	jz	longLiterals

	mov	cl, al			; cx = size of literals(*)
;	shr	cx, 1			; # of bytes -> # of words
;	rep	movsw			; copy literal
;	jnc	uncompress		; loop back for more
;	movsb				; copy leftover byte
	add	si, cx
;	
	jmp	uncompress		; loop back for more

longLiterals:
	lodsb				; get long literal length byte
	mov	cl, al			; cx = size of literals(*)
;	shr	cx, 1			; # of bytes -> # of words
;	rep	movsw			; copy literal
;	jnc	uncompress		; loop back for more
;	movsb				; copy leftover byte
	add	si, cx
;
	jmp	uncompress		; loop back for more

runLength:
	and	al, not (LZG_LITERALS_FLAG or LZG_RUN_LENGTH_FLAG)
	jz	done			; done if no runLength

	mov	cl, al			; cx = size of zeros
	clr	ax			; ax = NULL
	shr	cx, 1			; # of bytes -> # of words
;	rep	stosw			; write NULL's
	jnc	uncompress		; loop back for more
;	stosb				; write NULL
	jmp	uncompress		; loop back for more

pair:
	mov	cl, al			; cx=cl = 4 length bits, 2 offset bits
	lodsb				; load low 8 bits of dictionary offset
	mov	bl, al			; bl = low 8 bits of dictionary offset
	mov	bh, cl			; bh has high bits of offset
	and	bh, (1 shl (LZG_PAIR_POSITION_BITS-8)) - 1
					; bx = dictionary offset
	neg	bx
	add	bx, di			; bx = position in output buffer
	CheckHack <(LZG_PAIR_POSITION_BITS-8) eq 2>
	shr	cl, 2			; shift out offset bits
	jz	longPair
	xchg	si, bx			; ds:si = source string
;	rep	movsb es:		; copy string from dictionary (warning)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more

longPair:
	lodsb				; load long match length
	mov	cl, al			; cx = match length
	xchg	si, bx			; ds:si = source string
;	rep	movsb es:		; copy string from dictionary (warning)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more

smallPair:
	andnf	al, not LZG_SMALL_PAIR_FLAG
	mov	bx, di
	sub	bx, ax			; bx = position in output buffer
	xchg	si, bx			; ds:si = source string
;	movsb	es:			; copy a byte (not a word)
;	movsb	es:			; copy a byte (not a word)
;	movsb	es:			; copy a byte (not a word)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more
done:
	mov	cx, si			; cx = ending source offset
	pop	si			; si = source offset
	sub	cx, si			; cx = source bytes used

	.leave
	ret
LZGSourceSize	endp

;==============================================================================
;			LZG Compress C-Stubs
;==============================================================================

	SetGeosConvention


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LZGAllocCompressStack

C DECLARATION:	

	extern MemHandle LZGAllocCompressStack(GeodeHandle stackOwner);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	2/20/97		Initial version

------------------------------------------------------------------------------@
LZGALLOCCOMPRESSSTACK	proc	far	; stackOwner:hptr
	C_GetOneWordArg		bx, ax,dx

	call	LZGAllocCompressStack
	mov	ax, bx			; ^hax = compress stack block handle
	ret
LZGALLOCCOMPRESSSTACK	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LZGCompress

C DECLARATION:	

	extern int LZGCompress(byte *compressBuffer, byte *data,
			       int dataSize, MemHandle compressStack);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	2/20/97		Initial version

------------------------------------------------------------------------------@
LZGCOMPRESS	proc	far		compressBuffer:fptr, data:fptr,
					dataSize:word, compressStack:hptr
	uses	ds,si,es,di
	.enter

	lds	si, data
	les	di, compressBuffer
	mov	cx, dataSize
	mov	bx, compressStack
	call	LZGCompress
	mov	ax, cx

	.leave
	ret
LZGCOMPRESS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LZGUncompress

C DECLARATION:	

	extern int LZGUncompress(byte *dataBuffer, byte *compressedData);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	2/20/97		Initial version

------------------------------------------------------------------------------@
LZGUNCOMPRESS	proc	far		dataBuffer:fptr, compressedData:fptr
	uses	ds,si,es,di
	.enter

	lds	si, compressedData
	les	di, dataBuffer
	call	LZGUncompress
	mov	ax, cx

	.leave
	ret
LZGUNCOMPRESS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LZGGetUncompressedSize

C DECLARATION:	

	extern int LZGGetUncompressedSize(byte *compressedData);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	2/20/97		Initial version

------------------------------------------------------------------------------@
LZGGETUNCOMPRESSEDSIZE	proc	far	compressedData:fptr
	uses	ds,si
	.enter

	lds	si, compressedData
	call	LZGGetUncompressedSize
	mov	ax, cx
	jnc	done

	mov	ax, -1
done:
	.leave
	ret
LZGGETUNCOMPRESSEDSIZE	endp

	SetDefaultConvention

CompressionCode ends
