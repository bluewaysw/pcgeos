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
	clc					;indicate no error

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
	clc					;indicate no error

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
	clc
	.leave
	ret
	
TrueTypeInitFonts	endp


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
fontId			local	FontID
fontInfoChunk		local	word
	
	.enter
	;
	; generate font id from file names first character for now
	;
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
	
	segmov  ds, ss
	lea     dx, subTableHeader
		
	mov	al, 0
	
	mov	cx, size subTableHeader		; size to read
	
	call	FileRead	
	jc	doneClose

if 0	

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
	mov	al, es:[FFLH_fontFamily]
	mov	ds:[si].FI_family, al
	mov	ds:[si].FI_pointSizeTab, 0	; no bitmaps ???
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

endif

doneClose:
	mov	al, FILE_NO_ERRORS
	call	FileClose
done:
	.leave
	
	ret

ProcessFont	endp