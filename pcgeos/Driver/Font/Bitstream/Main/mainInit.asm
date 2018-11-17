COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainInit.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	BitstreamInit		Initialize the font driver.
EXT	BitstreamExit		Shut down the font driver.
EXT	BitstreamInitFonts	Invoked on FontManager startup.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/93		Initial version.

DESCRIPTION:
	Initialization & exit routines for the GEOS Bitstream font driver. 
	
	$Id: mainInit.asm,v 1.1 97/04/18 11:45:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the GEOS Bitstream font driver.

CALLED BY:	DR_INIT - BitstreamStrategy.

PASS:		none

RETURN:		carry clear if successful
		carry set otherwise

		bitmapHandle - handle of block to use for char bitmaps 
		bitmapSize - size of above block
		globalsHandle - handle of block containing BitstreamGlobals
		fontHeaderHandle - handle of block containing font file header
		charGenBufferHandle - handle of block containing Bitstream
					  character generation buffer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	BitstreamInit
BitstreamInit	proc	far	uses	ax, bx, cx, dx, si, di, ds, es
	.enter

	;
	; Make ds point to the dgroup
	;
	mov	ax, segment dgroup
	mov	ds, ax
	;
	; init vars
	;
	mov	ax, 0
	mov	ds:[fontFileHandle], ax
	mov	ds:[installFlag], al			; FALSE
	mov	ds:[installFontFileHandle], ax
	mov	ds:[installCharGenBufferHandle], ax
if PROC_TRUETYPE
	call	InitSaveMalloc
endif
	;
	; clear font file cache
	;
	mov	ds:[cachedFontDiskHandle], 0
	mov	{word} ds:[cachedFontFileName], 0	; SBCS and DBCS
	mov	{word} ds:[cachedFontFilePath], 0	; SBCS and DBCS
	mov	ds:[cachedFontFile], 0
	;
	; clear font cached file cache
	;
	mov	{word} ds:[cachedCacheFileName], 0	; SBCS and DBCS
	mov	ds:[cachedCacheFile], 0
	;
	; clear cached data buffer cache
	;
	mov	ds:[cachedCacheBufferHandle], 0
DBCS <	mov	ds:[cachedCacheFileOffset], -1				>
	;
	; clear lastFontInstID
	;
	mov	al, 0
	segmov	es, ds
	mov	di, offset lastFontInstID
	mov	cx, size lastFontInstID
	rep stosb
if FONT_HEADER_CACHE
	;
	; clear font header cache
	;
	mov	al, -1
	mov	di, offset fontHeaderCache
	mov	cx, size fontHeaderCache
	rep stosb
endif
	;
	; allocate discarded block for region generation
	;
	mov	ax, REGION_INITIAL_BLOCK_SIZE	; size of block
	mov	bx, handle 0			; driver owns block
	mov	cx, mask HF_DISCARDABLE or mask HF_SWAPABLE or \
			mask HF_SHARABLE or mask HF_DISCARDED
	call	MemAllocSetOwner		; bx = block handle
	jc	exit
	mov	ds:[outputInfo].OI_regionHandle, bx
	mov	ds:[outputInfo].OI_regionSeg, 0
if STATIC_GLOBALS
else
	;
	; now allocate the blocks for the Bitstream stuff
	; first, the block to hold the global data
	;
	mov	ax, size BitstreamGlobals
	mov	bx, handle 0			; driver owns block
	mov	cx, mask HF_DISCARDABLE	or mask HF_SWAPABLE or \
			mask HF_SHARABLE or mask HF_DISCARDED
	call	MemAllocSetOwner		; BX = block handle
	jc	exit
	mov	ds:[globalsHandle], bx
	mov	ds:[sp_global_ptr].segment, 0
endif
	;
	; allocate the font file header buffer
	;
if FIXED_FONT_HEADER
	mov	ds:[fontHeaderHandle], 0
else
	mov	ax, 1				; some non-zero size
	mov	bx, handle 0			; driver owns block
	mov	cx, mask HF_DISCARDABLE	or mask HF_SWAPABLE or \
			mask HF_SHARABLE or mask HF_DISCARDED
	call	MemAllocSetOwner		; bx = block handle
	jc	exit
	mov	ds:[fontHeaderHandle], bx
endif
	mov	ds:[fontHeaderSeg], 0
	;
	; allocate the character generation buffer
	;
	mov	ax, 1				; some non-zero size
						;	for now
	mov	bx, handle 0			; driver owns block
	mov	cx, mask HF_DISCARDABLE or mask HF_SWAPABLE	or \
			mask HF_SHARABLE or mask HF_DISCARDED
	call	MemAllocSetOwner		; bx = block handle
	jc	exit
	mov	ds:[charGenBufferHandle], bx
	mov	ds:[charGenBufferSeg], 0

	clc

exit:
	.leave
	ret
BitstreamInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut down the Bitstream font driver.

CALLED BY:	DR_EXIT - BitstreamStrategy.

PASS:		bitmapHandle - handle of bitmap block
		globalsHandle - handle of block containing global data
		fontHeaderHandle - handle of block containing font file header 
		charGenBufferHandle - handle of block containing
					  character generation buffer
RETURN:		carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitstreamExit	proc	far	uses	bx, ds
	.enter
	;
	; make ds point to dgroup
	;
	mov	bx, segment udata
	mov	ds, bx
	;
	; free up the region generation block
	;
	mov	bx, ds:[outputInfo].OI_regionHandle
	tst	bx
	jz	afterRegion
	call	MemFree
afterRegion:
EC <	clr	ds:[outputInfo].OI_regionHandle	; invalidate variable	>
if STATIC_GLOBALS
else
	;
	; free the Bitstream blocks.
	; first, the global data buffer
	;
	mov	bx, ds:[globalsHandle]
	tst	bx
	jz	afterGlobals
	call	MemFree
afterGlobals:
EC <	clr	ds:[globalsHandle]		; invalidate variable	>
endif
	;
	; free the font data file header buffer block
	;
	mov	bx, ds:[fontHeaderHandle]
	tst	bx
	jz	afterFontHeader
	call	MemFree
afterFontHeader:
EC <	clr	ds:[fontHeaderHandle]		; invalidate variable	>
	;
	; free the character generation buffer block
	;
	mov	bx, ds:[charGenBufferHandle]
	tst	bx
	jz	afterCharGenBuf
	call	MemFree
afterCharGenBuf:
EC <	clr	ds:[charGenBufferHandle]	; invalidate variable	>

	clc

	.leave
	ret
BitstreamExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitstreamInitFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize any non-GEOS fonts for this font driver.

CALLED BY:	DR_FONT_INIT_FONTS - BitstreamStrategy.

PASS:		DS	= Segment of block containing FontsAvailEntry
			  table.

RETURN:		carry set if error
		carry clear otherwise

DESTROYED:	ALLOWED: ax, bx, cx, dx, si, di, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
initFontReturnAttr	FileExtAttrDesc \
	<FEA_NAME, 0, size FileLongName>,
	<FEA_END_OF_LIST>

BitstreamInitFonts	proc	far	uses	ax,bx,cx,dx,si,di,es,bp
	.enter

	;
	; Enumerate files in SP_PRIVATE_DATA/bitstreamDir
	;
	call	FilePushDir
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath
	push	ds
	segmov	ds, dgroup, ax
	mov	dx, offset bitstreamDir
	clr	bx			; relative to CWD
	call	FileSetCurrentPath
	pop	ds
	jc	done

	sub	sp, size FileEnumParams
	mov	bp, sp
					; GEOS datafiles
	mov	ss:[bp].FEP_searchFlags, mask FESF_GEOS_NON_EXECS
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
	clc				; signal no error

	.leave
	ret
BitstreamInitFonts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize each font found

CALLED BY:	BitstreamInitFonts

PASS:		ds:si - cached font file name
		dx - font block segment

RETURN:		dx - updated font block segment (may move)

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessFont	proc	far

	uses	ax, bx, cx, di, si, es, ds

fontNameSeg		local	sptr	push	ds
fontNameOff		local	word	push	si
fontBlockSeg		local	sptr	push	dx
cacheFileHandle		local	hptr
cacheBlockHandle	local	hptr
fontInfoChunk		local	word

	.enter

	;
	; open cached data file
	;
	mov	dx, si				; ds:dx = name
	mov	al, FILE_ACCESS_R or FILE_DENY_W
	call	FileOpen
	LONG jc	done
	mov	cacheFileHandle, ax
	;
	; read cached data file
	;
	mov	bx, ax				; bx = cache file
	call	FileSize			; dx:ax = size
	tst	dx
	LONG jnz	done			; too big, ignore
	push	ax				; save size
	mov	cx, ALLOC_DYNAMIC_LOCK
	mov	bx, handle 0
	call	MemAllocSetOwner
	pop	cx				; cx = size
	LONG jc	doneClose
	mov	cacheBlockHandle, bx
	mov	bx, cacheFileHandle
	mov	ds, ax
	mov	es, ax
	mov	dx, 0
	mov	al, 0
	call	FileRead
	LONG jc	doneCloseFree
	;
	; verify is cached font file
	;
	cmp	{word} es:[FFLH_sig][0], BFCD_SIG_1 or (BFCD_SIG_2 shl 8)
	LONG jne	doneCloseFree
	cmp	{word} es:[FFLH_sig][2], BFCD_SIG_3 or (BFCD_SIG_4 shl 8)
	LONG jne	doneCloseFree
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
	mov	ax, es:[FFLH_fontID]
	mov	ds:[si].FAE_fontID, ax
	;
	; clear the name field because there is a font file for each font
	; rather than for each typeface (which this field is for)
	;
	mov	ds:[si].FAE_fileName, 0
	;
	; allocate a chunk for the FontInfo block
	;
	mov	cx, es:[FFLH_numFaces]
	mov	ax, size OutlineDataEntry
	mul	cx				; dx:ax = size
EC <	tst	dx							>
EC <	ERROR_NZ	BITSTREAM_INTERNAL_ERROR			>
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
	mov	ax, es:[FFLH_fontID]
	mov	ds:[si].FI_fontID, ax
	mov	ds:[si].FI_maker, FM_BITSTREAM
	mov	al, es:[FFLH_fontFamily]
	mov	ds:[si].FI_family, al
	mov	ds:[si].FI_pointSizeTab, 0	; no bitmaps
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
	mov	di, si
	add	di, FI_faceName
	mov	si, offset FFLH_faceName	; ds:si = FFLH_faceName
	mov	cx, length FI_faceName		; dest. size
	LocalCopyNString
	LocalPrevChar	esdi
	mov	ax, 0
	LocalPutChar	esdi, ax		; ensure null term
	pop	es, ds, si			; restore FFLH, FontInfo
	;
	; loop to fill out the OutlineDataEntrys
	;	ds:si = FontInfo
	;	es = FFLH
	;
	lea	di, es:[FFLH_faces][0]		; es:di = first FontFaceListItem
if DBCS_PCGEOS
	;
	; while we have ds:si = FontInfo and es:di = first FontFaceListItem,
	; initialize FI_firstChar and FI_lastChar from that first FFLI
	;
	push	di
	mov	di, es:[di].FFLI_offset
	mov	ax, es:[di].BFCD_firstUniChar	; use first Unicode char
	mov	ds:[si].FI_firstChar, ax
	mov	ax, es:[di].BFCD_lastUniChar	; use last Unicode char
	mov	ds:[si].FI_lastChar, ax
	pop	di
endif
	;
	; continue
	;
	add	si, size FontInfo		; ds:si = first OutlineDataEntry
	mov	cx, es:[FFLH_numFaces]		; cx = number of faces
entryLoop:
	push	si, di, cx
	;
	; setup OutlineDataEntry and BitstreamOutlineEntry
	;	ds:si = OutlineDataEntry
	;	es:di = FontFaceListItem
	;
	call	initOutlineEntry
	;
	; set up for looping
	;
	pop	si, di, cx
	segmov	es, ds				; es:di = next FontFaceListItem
	add	di, size FontFaceListItem
	mov	ds, fontBlockSeg		; ds:si = next OutlineDataEntry
	add	si, size OutlineDataEntry
	loop	entryLoop

doneCloseFree:
	mov	bx, cacheBlockHandle
	call	MemFree
doneClose:
	mov	bx, cacheFileHandle
	mov	al, FILE_NO_ERRORS
	call	FileClose
done:
	mov	dx, fontBlockSeg		; return updated segment
	.leave
	ret

initOutlineEntry	label	near
	;
	; style and weight
	;	ds:si = OutlineDataEntry
	;	es:di = FontFaceListItem
	;
	push	es:[di].FFLI_length		; save cache data length
	mov	di, es:[di].FFLI_offset
	push	di				; save cache data offset
	mov	al, es:[di].BFCD_fontStyle
	mov	ds:[si].ODE_style, al
	mov	al, es:[di].BFCD_fontWeight
	mov	ds:[si].ODE_weight, al
	;
	; now allocate and fill in a BitstreamOutlineEntry
	;	ds:si = OutlineDataEntry
	;	es:di = BFCD
	;	fontNameSeg:fontNameOff = cached font file name
	;
	mov	bx, si
	mov	si, fontInfoChunk
	mov	si, ds:[si]
	sub	bx, si				; bx = offset to ODE
	push	es, di				; save BFCD
	mov	cx, es:[di].BFCD_fontDiskSize	; size for DiskSave
	add	cx, size BitstreamOutlineEntry	; fixed size
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
	mov	bx, di				; es:bx = BitstreamOutlineEntry
	segmov	es, ds				; es:di = BitstreamOutlineEntry
.assert (offset BOE_cachedFileName) eq 0
	mov	ds, fontNameSeg			; ds:si = cached data filename
	mov	si, fontNameOff
	mov	cx, size BOE_cachedFileName	; dest. size
	rep movsb
.assert (offset BOE_fontFileName) eq (offset BOE_cachedFileName)+(size BOE_cachedFileName)
	pop	ds, si				; ds:si = BFCD_fontName
	add	si, offset BFCD_fontName
	mov	cx, size BOE_fontFileName
	rep movsb
.assert (offset BOE_fontFilePath) eq (offset BOE_fontFileName)+(size BOE_fontFileName)
.assert (size BOE_fontFileName) eq (size BFCD_fontName)
.assert (offset BFCD_fontPath) eq (offset BFCD_fontName)+(size BOE_fontFileName)
	mov	cx, size BOE_fontFilePath
	rep movsb
.assert (offset BFCD_xlatTable) gt (offset BFCD_fontPath)
.assert (offset BOE_xlatTable) gt (offset BOE_fontFilePath)
						; ds:si = BFCD_xlatTable
	add	si, (offset BFCD_xlatTable)-\
				((offset BFCD_fontPath)+(size BFCD_fontPath))
						; es:di = BOE_xlatTable
	add	di, (offset BOE_xlatTable)-\
			((offset BOE_fontFilePath)+(size BOE_fontFilePath))
	mov	cx, length BOE_xlatTable
	rep movsw
.assert (offset BOE_fontFileDisk) gt (offset BOE_xlatTable)
						; ds:si = BFCD
	sub	si, (offset BFCD_xlatTable)+(size BOE_xlatTable)
	push	si
	mov	cx, ds:[si].BFCD_fontDiskSize	; cx = DiskSave size
	add	si, offset BFCD_fontDisk	; ds:si = BFCD_fontDisk
						; es:di = BOE_fontFileDisk
	add	di, (offset BOE_fontFileDisk)-\
				((offset BOE_xlatTable)+(size BOE_xlatTable))
	rep movsb

	pop	si				; ds:si = BFCD
	mov	ax, ds:[si].BFCD_ORUsPerEm	; copy over metrics info
	mov	es:[bx].BOE_metrics.BOEM_ORUsPerEm, ax
	mov	ax, ds:[si].BFCD_accent
	mov	es:[bx].BOE_metrics.BOEM_accent, ax
	mov	ax, ds:[si].BFCD_ascent
	mov	es:[bx].BOE_metrics.BOEM_ascent, ax
	mov	ax, ds:[si].BFCD_baseAdjust
	mov	es:[bx].BOE_metrics.BOEM_baseAdjust, ax
	mov	al, ds:[si].BFCD_fontWeight
	mov	es:[bx].BOE_metrics.BOEM_fontWeight, al
	mov	al, ds:[si].BFCD_fontWidth
	mov	es:[bx].BOE_metrics.BOEM_fontWidth, al
DBCS <	mov	al, ds:[si].BFCD_kanjiFont				>
DBCS <	mov	es:[bx].BOE_kanjiFont, al				>

	mov	ax, ds:[si].BFCD_minFontBufSize	; copy over buffer sizes
	mov	es:[bx].BOE_minFontBufSize, ax
	mov	ax, ds:[si].BFCD_minCharBufSize
	mov	es:[bx].BOE_minCharBufSize, ax

	pop	es:[bx].BOE_cacheData.FFLI_offset	; store data offset
	pop	es:[bx].BOE_cacheData.FFLI_length	; ...and length

	mov	ax, ds:[FFLH_processor]
	mov	es:[bx].BOE_processor, ax
	retn

ProcessFont	endp


