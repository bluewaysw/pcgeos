COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2021 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Init
FILE:		truetypeInit.asm

AUTHOR:		Falk Rehwagen, Jan 24, 2021

ROUTINES:
	Name			Description
	----			-----------
	TrueTypeInit		initialize the TrueType font driver
	TrueTypeExit		clean up after TrueType font driver
	TrueTypeInitFonts	initialize any non-PC/GEOS fonts

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	01/24/21	Initial revision

DESCRIPTION:
	Initialization & exit routines for TrueType font driver

	$Id: truetypeInit.asm,v 1.1 21/01/24 11:45:29 bluewaysw Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the TrueType font driver.
CALLED BY:	DR_INIT - TrueTypeStrategy

PASS:		none
RETURN:		bitmapHandle - handle of block to use for bitmaps
		bitmapSize - size of above block (0 at start)
		variableHandle - handle of block containing variables
		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	01/24/21	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	TrueTypeInit
TrueTypeInit	proc	far
	uses	ax, bx, cx, si, di, ds, es
	.enter

	mov	ax, segment udata
	mov	ds, ax				;ds <- seg addr of vars
	;
	; First, we need a block of memory to use as a bitmap
	; for generating characters. We don't need to actually
	; allocate memory for it yet.
	;
	mov	ax, TRUETYPE_BLOCK_SIZE		;ax <- size of block
	mov	bx, handle 0			;bx <- make TrueType owner
	mov	cx, mask HF_DISCARDABLE \
		 or mask HF_SWAPABLE \
		 or mask HF_SHARABLE \
		 or mask HF_DISCARDED \
		 or (mask HAF_NO_ERR shl 8) 	;cl, ch <- alloc flags
	call	MemAllocSetOwner
	mov	ds:bitmapHandle, bx		;save handle of block
	mov	ds:bitmapSize, 0		;no bytes yet
	;
	; We also need a block to use for variables. We don't
	; need it yet, either.
	;
	mov	ax, size TrueTypeVars		;ax <- size of block
	mov	bx, handle 0			;bx <- make TrueType owner
	mov	cx, mask HF_DISCARDABLE \
		 or mask HF_SWAPABLE \
		 or mask HF_SHARABLE \
		 or mask HF_DISCARDED \
		 or (mask HAF_NO_ERR shl 8) 	;cl, ch <- alloc flags
	call	MemAllocSetOwner
	mov	ds:variableHandle, bx		;save handle of block
	;
	; Initialize FreeType engine.
	;
	call	INIT_FREETYPE
	test	ax, 0
	jz	noerror
	stc					;indicate error
	jmp	done
noerror:
	clc					;indicate no error
done:
	.leave
	ret
TrueTypeInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up blocks used and exit the TrueType driver.
CALLED BY:	DR_EXIT - TrueTypeStrategy

PASS:		bitmapHandle - handle of bitmap block
		variableHandle - handle of variable block
RETURN:		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/24/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeExit	proc	far
	uses	ax, bx, ds
	.enter

	mov	ax, segment udata
	mov	ds, ax				;ds <- seg addr of vars
	mov	bx, ds:bitmapHandle
EC <	clr	ds:bitmapHandle			;>
	call	MemFree				;done with bitmap block
	mov	bx, ds:variableHandle
EC <	clr	ds:variableHandle		;>
	call	MemFree				;done with variable block
	;
	; Deinitialize FreeType engine.
	;
	call	EXIT_FREETYPE			;finish FreeType engine
	test	ax, 0				;check for errors
	jz	noerror
	stc					;indicate error
	jmp	done
noerror:	
	clc					;indicate no error
done:
	.leave
	ret
TrueTypeExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeInitFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize any non-GEOS fonts for the font driver.
CALLED BY:	DR_FONT_INIT_FONTS - TrueTypeStrategy

PASS:		ds - seg addr of font info block
RETURN:		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/24/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
initFontReturnAttr	FileExtAttrDesc \
	<FEA_NAME, 0, size FileLongName>,
	<FEA_END_OF_LIST>

TrueTypeInitFonts	proc	far	uses	ax,bx,cx,dx,si,di,es,bp

	.enter
ifndef USE_OLD_FONT_LOADER
	segmov	cx, ds
	call	MemSegmentToHandle
	jnc	err
	push	ds

	push	cx			; handle to font info block
	segmov	ds, dgroup, cx
	call 	TRUETYPE_INITFONTS

	pop	ds
err:

else
	;
	; Enumerate files in SP_FONT
	;
	call	FilePushDir
	mov	ax, SP_FONT
	call	FileSetStandardPath
	push	ds
	segmov	ds, dgroup, ax
	mov	dx, offset truetypeDir
	clr	bx			; relative to CWD
	call	FileSetCurrentPath
	pop	ds
	jc	done			; branch if error
	
	;
	; Lookup all .ttf files
	sub	sp, size FileEnumParams
	mov	bp, sp
				; GEOS datafiles
	mov	ss:[bp].FEP_searchFlags, mask FESF_NON_GEOS
				; return longname
	mov	ss:[bp].FEP_returnAttrs.segment, cs
	mov	ss:[bp].FEP_returnAttrs.offset, offset initFontReturnAttr
	mov	ss:[bp].FEP_returnSize, size FileLongName
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
				; callback sees all files
	mov	ss:[bp].FEP_matchAttrs.segment, 0

	mov	ss:[bp].FEP_skipCount, 0
	call	FileEnum		; cx = # found, bx = handle
	jc	done			; error
	jcxz	done			; no files found
	mov	dx, ds			; ax = segment of font block
	call	MemLock			; ds:0 = first entry
	mov	ds, ax
	mov	si, 0
fontLoop:
	call	ProcessFont
	add	si, size FileLongName
	loop	fontLoop
	call	MemFree			; free file block
done:
	call	FilePopDir
endif
	clc
	
	.leave
	ret

TrueTypeInitFonts	endp

ifdef USE_OLD_FONT_LOADER
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize each font found

CALLED BY:	TrueTypeInitFonts

PASS:		ds:si - font file name (TTF)
		dx - font block segment

RETURN:		dx - updated font block segment (may move)

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	2/17/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessFont	proc	far

	uses	ax, bx, cx, di, si, es, ds

fontNameSeg		local	sptr	push	ds
fontNameOff		local	word	push	si
fontBlockSeg		local	sptr	push	dx
subTableHeader 		local   TrueTypeSubTable
tableDirectory		local	TrueTypeTableDirectory
fontId			local	FontID
fontInfoChunk		local	word
tableCount		local	word
fontFile		local	hptr
fontName		local	FONT_NAME_LEN dup (char)
fontStyle		local	TextStyle
fontWeight		local	FontWeight
tablesProcessed		local	word

	.enter
	;
	; generate font id from file names first character for now
	;
	mov	fontWeight, FW_NORMAL
	
	clr	ah
	mov	al, ds:[si]
	add	ax, FM_TRUETYPE
	mov	fontId, ax

	;
	; open truetype file
	;
	mov	dx, si				; ds:dx = name
	mov	al, FILE_ACCESS_R or FILE_DENY_W
	call	FileOpen
	jc	done

	mov	bx, ax				; file handle to bx
	mov	fontFile, bx

	segmov  ds, ss
	lea     dx, subTableHeader

	mov	al, 0

	mov	cx, size subTableHeader		; size to read

	call	FileRead
	jc	doneClose

	;
	; scan all TTF file tables
	; keep structures and meta data needed to serve the font
	;
	mov	ah, subTableHeader.TTST_numTables.low
	mov	al, subTableHeader.TTST_numTables.high
	mov	tableCount, ax
	mov	tablesProcessed, 0
nextEntry:
	mov	bx, fontFile
	segmov  ds, ss
	lea     dx, tableDirectory
	mov	al, 0

	mov	cx, size tableDirectory		; size to read

	call	FileRead
	jc	doneClose

	; remember file position
	mov	cx, 0
	mov	dx, 0
	mov	bx, fontFile			; pass file handle in BX
	mov	al, FILE_POS_RELATIVE		; jump from start
	call	FilePos				; get current pos to dx:ax
	jc	doneClose
	mov	cx, dx
	mov	dx, ax

	mov	ax, 'na'
	cmp	ax, tableDirectory.TTTD_tag.low
	jne	tryOS_2
	mov	ax, 'me'
	cmp	ax, tableDirectory.TTTD_tag.high
	jne	tryOS_2

	lea	si, tableDirectory
	call	LoadTable

	cmp	bx, 0				; failed to load?
	je	doneClose
	
	; restore file position, cxdx hold position
	push	bx
	mov	bx, fontFile			; pass file handle in BX
	mov	al, FILE_POS_START		; jump from start
	call	FilePos
	pop	bx
	jnc	parseName

	; free the block we don't keep it, bx handle of block
	jmp	freeAndClose
	
parseName:
	; get relevant data from name table

	; first load sub family (and reuse the buffer fontName) and map
	; the value to TextStyle bits to describe the resulting
	; font entry
	lea	si, fontName			; ss:si point to buffer
	mov	cx, FONT_NAME_LEN		; buffer size
	mov	ax, 2				; sub family name of the font
	call	GetNameFromTable
	jc	freeAndClose			; jump if no name found
	
	lea	si, fontName			; ss:si point to buffer
	call 	MapFontStyle
	jc	freeAndClose			; fail if style mapping fails

	mov	fontStyle, al			; save fontStyle 
						; (type TextStyle)
	; ds is pointing to the name table here
	lea	si, fontName			; ss:si point to buffer
	mov	cx, FONT_NAME_LEN		; buffer size
	mov	ax, 1				; family name of the font
	call	GetNameFromTable
	jc	freeAndClose			; jump if no name found
	
	; free the block we don't keep it, bx handle of block
	inc	tablesProcessed
	call	MemFree
	jmp	cont

tryOS_2:
	mov	ax, 'OS'
	cmp	ax, tableDirectory.TTTD_tag.low
	jne	cont
	mov	ax, '/2'
	cmp	ax, tableDirectory.TTTD_tag.high
	jne	cont
loadOS_2:	
	lea	si, tableDirectory
	call	LoadTable

	cmp	bx, 0				; failed to load?
	je	doneClose

	; restore file position, cxdx hold position
	push	bx
	mov	bx, fontFile			; pass file handle in BX
	mov	al, FILE_POS_START		; jump from start
	call	FilePos
	pop	bx
	jnc	getWeight

	; free the block we don't keep it, bx handle of block
freeAndClose:
	call	MemFree
	jmp	doneClose

getWeight:
	mov	ah, ds:4
	mov	al, ds:5
	mov	dx, 0
	mov	si, 100
	div	si
	cmp	dx, 0
	jne	freeAndClose
	cmp	ax, 10
	jnc	freeAndClose

	mov	si, ax
	mov	al, cs:weightAdjustTable[si]
	mov	fontWeight, al
	inc	tablesProcessed
	
	call	MemFree
cont:
	dec	tableCount
	jnz	nextEntry

	mov	ax, tablesProcessed
	cmp	ax, 0
	je	doneClose

	; we have one font and collected required meta data
	; let compute/determ the fontid to be used for the font
	mov	ax, 0
	lea	si, fontName			; ss:si point to buffer
	mov	cx, 0
calcFontId:	

	xor	al, ss:0[si]
	
	xor	ah, ss:1[si]

	inc	cx
	cmp	cx, FONT_NAME_LEN
	je	doneFontId
	inc	si
	cmp	ss:0[si], 0
	jnz	calcFontId
	
	and	ah, 00000001b
	or	ax, FM_TRUETYPE
	or	ah, 00001110b
	mov	fontId, ax
doneFontId:
	
	; lookup if there is a FontsAvailEntry for the font already
	mov	cx, fontId
	mov	ds, fontBlockSeg
	mov	di, ds:[FONTS_AVAIL_HANDLE]	;di <- ptr to chunk
	ChunkSizePtr	ds, di, ax		;ax <- chunk size
	add	ax, di				;ax -> end of chunk
IFA_loop:
	cmp	di, ax				;are we thru the list?
	jae	noMatch				;yes, exit carry clear
	cmp	ds:[di].FAE_fontID, cx		;see if ID matches
	je	match				;we have a match, branch
	add	di, size FontsAvailEntry	;else move to next entry
	jmp	IFA_loop			;and loop

match:
	; font already registered, check if there is already equal outline
	; outline is equal if style and weight is equal
	mov	di, ds:[di].FAE_infoHandle	; ds:si = FontInfo chunk handle
	mov	si, ds:[di]			; ds:si = FontInfo ptr	
	
	mov	cx, ds:[si].FI_outlineEnd
	push	si
	mov	si, ds:[si].FI_outlineTab

checkOutline:
	mov	al, ds:[si].ODE_style
	cmp	al, fontStyle
	jne	nextOutline
	
	mov	al, ds:[si].ODE_weight
	cmp	al, fontStyle
	jne	nextOutline
	
	; matching outline found
	pop	ax
	jmp	doneClose			; skip this font
	
nextOutline:
	add	si, size OutlineDataEntry
	cmp	si, cx
	jne	checkOutline

appendOutline:
	; not found, append new outline
	pop	si

	mov	bx, cx				; append at end
	
	push	cx
	add	cx, size OutlineDataEntry
	mov	ds:[si].FI_outlineEnd, cx
	
	mov	ax, di				; *ds:ax = chunk
	mov	cx, size OutlineDataEntry	; cx = sizeof outline entry
	call	LMemInsertAt			; ds updated
	mov	fontBlockSeg, ds		; store it

	pop	si
	jmp	initEntry
	
noMatch:
	;
	; create a new FontsAvailEntry
	;
	mov	ds, fontBlockSeg
	mov	ax, FONTS_AVAIL_HANDLE		; *ds:ax = chunk
	clr	bx				; insert at front
	mov	cx, size FontsAvailEntry	; cx = sizeof table entry
	call	LMemInsertAt			; ds updated
	mov	fontBlockSeg, ds		; store it
	;
	; fill in FontID
	;
	mov	si, ax
	push	si
	mov	si, ds:[si]			; ds:si = new FAE
	mov	ax, fontId
	mov	ds:[si].FAE_fontID, ax
	;
	; clear the name field because there is a font file for each font
	; rather than for each typeface (which this field is for)
	;
	mov	ds:[si].FAE_fileName, 0

	;
	; allocate a chunk for the FontInfo block
	;
	mov	cx, 1				; font count
	mov	ax, size OutlineDataEntry
	mul	cx				; dx:ax = size
EC <	tst	dx							>
EC <	ERROR_NZ	TRUETYPE_INTERNAL_ERROR			>
	mov	cx, ax
	add	cx, size FontInfo
	mov	dx, cx				; save size for later
	clr	ax
	call	LMemAlloc			; ds updated, ax = chunk
	mov	fontBlockSeg, ds		; store it
	mov	fontInfoChunk, ax

	;
	; finish filling the FontsAvailEntry
	;	dx = end of OutlineDataEntrys
	;
	pop	si				; *ds:si = FontsAvailEntry
	mov	si, ds:[si]			; ds:si = FontsAvailEntry
	mov	ds:[si].FAE_infoHandle, ax	; save FontInfo chunk handle

	;
	; now fill in the FontInfo struct
	;	dx = end of OutlineDataEntrys
	;
	mov	di, ax				; *ds:di = FontInfo
	mov	si, ds:[di]			; ds:si = FontInfo
	mov	ds:[si].FI_fileHandle, 0	; not used
	mov	ax, fontId
	mov	ds:[si].FI_fontID, ax
	mov	ds:[si].FI_maker, FM_TRUETYPE
	mov	al, FF_NON_PORTABLE
	mov	ds:[si].FI_family, al		; this is called family but it
						; actually is FontAttrs
	mov	ds:[si].FI_pointSizeTab, 0	; no bitmaps ??? (for now)
	mov	ds:[si].FI_pointSizeEnd, 0
	mov	ds:[si].FI_outlineTab, size FontInfo
	mov	ds:[si].FI_outlineEnd,	dx
	;
	; copy in the font face name
	;	ds:si = FontInfo
	;	es = FFLH
	;
	push	es, ds, si			; save FFLH, FontInfo
	segxchg	es, ds				; es:di = FI_faceName
	segmov	ds, ss
	mov	di, si
	add	di, FI_faceName
	lea	si,fontName			; ds:si = fontName
	mov	cx, length FI_faceName		; dest. size
	LocalCopyNString
	LocalPrevChar	esdi
	mov	ax, 0
	LocalPutChar	esdi, ax		; ensure null term
	pop	es, ds, si			; restore FFLH, FontInfo

	add	si, size FontInfo		; ds:si = first OutlineDataEntry
initEntry:
	call 	initOutlineEntry
	
doneClose:
	mov	bx, fontFile
	mov	al, FILE_NO_ERRORS
	call	FileClose
done:
	mov	dx, fontBlockSeg

	.leave
	ret

weightAdjustTable	byte \
	80,		;FWE_ULTRA_LIGHT
	85,		;FWE_EXTRA_LIGHT
	90,		;FWE_LIGHT
	95,		;FWE_BOOK
	100,		;FWE_NORMAL
	105,		;FWE_DEMI
	110,		;FWE_BOLD
	115,		;FWE_EXTRA_BOLD
	120,		;FWE_ULTRA_BOLD
	125		;FWE_BLACK
		
initOutlineEntry	label	near
	;
	; style and weight
	;	ds:si = OutlineDataEntry
	;
	mov	al, fontStyle			; font style
	mov	ds:[si].ODE_style, al
	mov	al, fontWeight			; font weight
	mov	ds:[si].ODE_weight, al
	;
	; now allocate and fill in a TrueTypeOutlineEntry
	;	ds:si = OutlineDataEntry
	;	fontNameSeg:fontNameOff = font file name
	;
	mov	bx, si
	mov	si, fontInfoChunk
	mov	si, ds:[si]
	sub	bx, si				; bx = offset to ODE
	mov	cx, size TrueTypeOutlineEntry	; fixed size
	clr	ax
	call	LMemAlloc			; ax = BOE chunk, ds updated
	mov	fontBlockSeg, ds		; store it
	mov	si, fontInfoChunk
	mov	si, ds:[si]			; ds:si = FontInfo
	add	si, bx				; ds:si = OutlineDataEntry
if DBCS_PCGEOS
	mov	ds:[si].ODE_extraData, ax
else
						; store chunk at OutlineEntrys
	mov	ds:[si][(size ODE_style + size ODE_weight)], ax
endif
	mov	si, ax
	mov	di, ds:[si]
	mov	bx, di				; es:bx = TrueTypeOutlineEntry
	segmov	es, ds				; es:di = TrueTypeOutlineEntry
.assert (offset TTOE_fontFileName) eq 0
	mov	ds, fontNameSeg			; ds:si = font filename
	mov	si, fontNameOff
	mov	cx, size TTOE_fontFileName		; dest. size
	rep movsb
	
	retn

ProcessFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load ttf table into memory block

CALLED BY:	ProcessFont

PASS:		ss:si - table directory entry
		bx - file handle

RETURN:		ds - segment of locked table (on success)
		bx - handle of table block (0 if FAILURE)

DESTROYED:	Current file position in the given file.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	8/30/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadTable	proc	near
	uses	ax, cx, dx, di

newBlock		local	hptr
	.enter

	mov	newBlock, handle 0

	tst	ss:[si].TTTD_length.low		; actually the high word
	jnz	err				; -> error if above 64K
	mov	al, ss:[si].TTTD_length.high.high
	mov	ah, ss:[si].TTTD_length.high.low
	mov	di, ax

	mov	dx, bx				; keep file handle
	mov	bx, handle 0			; bx <- make TrueType owner
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocSetOwner		; allocate blk for table
	jc	err

	mov	newBlock, bx
	segmov	ds, ax

	mov	bx, dx				; pass file handle in BX
	mov	al, FILE_POS_START		; jump from start
	mov	dl, ss:[si].TTTD_offset.high.high
	mov	dh, ss:[si].TTTD_offset.high.low
	mov	cl, ss:[si].TTTD_offset.low.high		
	mov	ch, ss:[si].TTTD_offset.low.low

	call	FilePos
	jc	err

	mov	dx, 0				; buffer offset in segment
	mov	cx, di				; size
	clr	al
	call	FileRead
	jc	err

	mov	bx, newBlock
done:
	.leave
	ret

err:
	mov	bx, 0
	mov	ax, newBlock
	jz	done
	call	MemFree
	jmp	done

LoadTable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameFromTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load ttf table into memory block

CALLED BY:	ProcessFont

PASS:		ss:si - buffer to hold the result
		cx - buffer size (to include \0 terminiation)
		ds - name table segment

RETURN:		carry set on not found
		Otherwise buffer filled, \0 terminated, if cx is not 0.
		if cx is 0 then the buffer is filled but without \n termination.

DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	8/30/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameFromTable	proc	near
	uses	bx, di, dx

dataOffset	local	word
encoding	local	byte
	.enter
	
	mov	bx, ax
	mov	di, si
	
	; check version
	mov	ax, ds:0
	cmp	ax, 0
	jne	err

	; scan the name record table
	mov	ah, ds:4
	mov	al, ds:5
	mov	dataOffset, ax
	
	mov	dx, ds:2
	mov	si, 6
recordLoop:
	mov	ax, ds:0[si]
	cmp	ax, 0100h
	je	macEncoding
	cmp	ax, 0				; unicode
	jne	next
	mov	ah, ds:2[si]
	mov	al, ds:3[si]
	cmp	ax, 3				; Unicode 2.0 BPM
	jne	next
	mov	ax, ds:4[si]
	cmp	ax, 0				; language should be 0 for
						; unicode
	jne	next
	mov	encoding, 0
	jmp	enterLoop

macEncoding:
	mov	ah, ds:2[si]
	mov	al, ds:3[si]
	cmp	ax, 0				; Roman?
	jne	next
	mov	ax, ds:4[si]
	cmp	ax, 0				; English?
	jne	next

	mov	encoding, 1			; 1 = non-unicode

enterLoop:
	; match the name id
	mov	ah, ds:6[si]
	mov	al, ds:7[si]
	cmp	ax, bx
	jne	next

	mov	dh, ds:8[si]
	mov	dl, ds:9[si]

	mov	ah, ds:10[si]
	mov	al, ds:11[si]
	add	ax, dataOffset
	mov	si, ax
copyLoop:
	cmp	encoding, 0
	jne	nextByte
	mov	ah, ds:0[si] 
	inc	si
	dec	dx
	jz	endOfBuffer
nextByte:
	mov	al, ds:0[si] 
	inc	si

	mov	ss:0[di], al
	inc 	di
	dec	cx
	jz	endOfBuffer
	dec	dx
	jnz	copyLoop
endOfBuffer:
	cmp	cx, 0
	jz	success
	mov	ss:0[di], 0
	jmp	success
next:
	mov	ax, si
	add	ax, 12				; size of name record
	mov	si, ax
	
	dec	dx
	jnz	recordLoop
	jz 	err

success:
	clc
done:
	.leave
	ret
	
err:	
	stc
	jc	done

GetNameFromTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapFontStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MapFontStyle 

CALLED BY:	ProcessFont

PASS:		ss:si - buffer to sub family name

RETURN:		carry set if mapping failed
		al - on success, mapped TextStyle

DESTROYED:	ah

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	9/9/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDefNLString StyleRegular, <"Regular", 0>
LocalDefNLString StyleBold, <"Bold", 0>
LocalDefNLString StyleItalic, <"Italic", 0>
LocalDefNLString StyleBoldItalic, <"Bold Italic", 0>
LocalDefNLString StyleOblique, <"Oblique", 0>
LocalDefNLString StyleBoldOblique, <"Bold Oblique", 0>

styleNames nptr \
	StyleRegular,
	StyleBold,
	StyleItalic,
	StyleBoldItalic,
	StyleOblique,
	StyleBoldOblique

styleFlags TextStyle \
	0,
	mask TS_BOLD,
	mask TS_ITALIC,
	mask TS_BOLD or mask TS_ITALIC,
	mask TS_ITALIC,
	mask TS_BOLD or mask TS_ITALIC

MapFontStyle	proc	near
	uses	es, ds, di, si, cx, bx
	
	.enter
;
; Find the style
;
	segmov	es, ss
	mov	di, si				;es:di <- string to look for
;
; Find the sub family name in the table
;
	mov	cx, length styleNames		;cx <- # of entries
	clr	bx				;bx <- table index
	segmov	ds, cs
styleLoop:
	push	cx
	mov	si, cs:styleNames[bx]		;ds:si <- extension
	clr	cx				;cx <- NULL-terminated
	call	LocalCmpStringsNoCase
	pop	cx
	je	foundStyle			;branch if match
	add	bx, (size nptr)			;bx <- next entry
	loop	styleLoop			;loop for more
	jmp	notFound

;
; Found the style -- return the flags
;
foundStyle:
	sar	bx, 1
	mov	al, cs:styleFlags[bx]		;ds:si <- library name
	clc					;carry <- no error
done:
	.leave
	ret

notFound:
	stc					;carry <- error
	jmp	done

MapFontStyle	endp
endif
